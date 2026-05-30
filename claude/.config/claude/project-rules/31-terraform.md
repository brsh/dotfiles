---
trigger: glob
glob: "**/*.{tf,tfvars}"
description: "Terraform and OpenTofu IaC best practices"
---

# Terraform / OpenTofu Rules

These rules apply to both Terraform (HashiCorp) and OpenTofu (open-source fork).

---

## Project Structure

```
infra/
├── main.tf              # primary resources
├── variables.tf         # all input variable declarations
├── outputs.tf           # all output declarations
├── versions.tf          # terraform block + provider version constraints
├── data.tf              # data sources (keep separate for clarity)
├── locals.tf            # local values (optional, for complex expressions)
├── terraform.tfvars     # variable values — DO NOT COMMIT if it contains secrets
├── terraform.tfvars.example  # safe template showing expected variable names
└── modules/
    └── web-server/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

For larger projects, split by resource type or concern:
```
├── networking.tf
├── compute.tf
├── storage.tf
├── iam.tf
```

---

## versions.tf — Always Pin Providers

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"    # ~> allows patch updates, not major
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "mytfstate"
    container_name       = "tfstate"
    key                  = "prod/terraform.tfstate"
  }
}
```

**Always use remote state.** Local state is only acceptable for personal experiments.
For Azure: Azure Storage. For AWS: S3 + DynamoDB (state locking). For multi-team:
Terraform Cloud / HCP Terraform.

---

## variables.tf — Always Include description and type

```hcl
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod"
  }
}

variable "vm_count" {
  description = "Number of VM instances to deploy"
  type        = number
  default     = 2

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 20
    error_message = "vm_count must be between 1 and 20"
  }
}

variable "allowed_ip_ranges" {
  description = "List of CIDR ranges allowed to access the management interface"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

Every variable must have `description`. Never use `type = any` unless absolutely required.
Add `validation` blocks for values with known constraints.

---

## Secrets — Never in State or Code

```hcl
# Bad — password stored in tfvars and state file (state is not encrypted by default)
resource "azurerm_sql_server" "main" {
  administrator_login_password = var.admin_password   # appears in state!
}

# Better — reference Key Vault
data "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_mssql_server" "main" {
  administrator_login_password = data.azurerm_key_vault_secret.sql_password.value
}

# Also consider: use managed identities to avoid passwords entirely
```

Never put secrets in:
- `terraform.tfvars` (check into git by mistake)
- `locals {}` blocks (ends up in plan output)
- Resource arguments that Terraform stores in state

Use environment variables for sensitive values:
```bash
export TF_VAR_admin_password="$(az keyvault secret show --name sql-pass --vault-name myvault --query value -o tsv)"
```

---

## outputs.tf — Mark Sensitive Outputs

```hcl
output "vm_public_ips" {
  description = "Public IP addresses of deployed VMs"
  value       = azurerm_public_ip.main[*].ip_address
}

output "connection_string" {
  description = "Database connection string"
  value       = azurerm_mssql_database.main.connection_string
  sensitive   = true    # hides value in plan/apply output, still in state
}
```

---

## Resource Naming and Tagging

```hcl
locals {
  name_prefix = "${var.environment}-${var.project}"

  common_tags = merge(var.tags, {
    environment = var.environment
    project     = var.project
    managed_by  = "terraform"
    repo        = "github.com/org/infra"
  })
}

resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}
```

Use `locals` to avoid repeating naming logic across resources.
Always tag resources with at minimum: environment, project, managed_by.

---

## Lifecycle Rules

```hcl
resource "azurerm_mssql_server" "main" {
  # ...

  lifecycle {
    prevent_destroy = true      # require explicit removal from code before destroy
    ignore_changes  = [tags]    # don't drift-detect tags (managed externally)
  }
}
```

Use `prevent_destroy = true` on:
- Database servers and instances
- Key vaults
- Storage accounts with data
- Production VMs

---

## Modules

```hcl
# Calling a module
module "web_servers" {
  source = "./modules/web-server"

  # or from registry:
  # source  = "Azure/compute/azurerm"
  # version = "~> 5.0"

  name           = "${local.name_prefix}-web"
  vm_count       = var.web_vm_count
  subnet_id      = module.networking.web_subnet_id
  tags           = local.common_tags
}

# Reference module outputs
output "web_server_ips" {
  value = module.web_servers.public_ips
}
```

Modules should:
- Have `variables.tf` and `outputs.tf`
- Not hardcode environment-specific values
- Be versioned if shared across teams (use tags in git or registry versions)

---

## Workflow Commands

```bash
# Standard workflow — always in this order
terraform init                  # initialize providers and backend
terraform fmt -recursive        # format all .tf files
terraform validate              # syntax and config validation
terraform plan -out=tfplan      # create and save plan
terraform apply tfplan          # apply the saved plan (no re-plan prompt)

# Review what's in state
terraform state list
terraform state show azurerm_resource_group.main

# Import existing resources
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/my-rg

# Target a specific resource (use sparingly — breaks state consistency)
terraform apply -target=azurerm_virtual_machine.web[0]
```

**Never run `terraform apply` without first reviewing `terraform plan` output.**
Always save the plan file (`-out=tfplan`) and apply that exact plan.

---

## Linting and Security Scanning

```bash
# tflint — catches provider-specific issues (install per provider plugin)
tflint --init
tflint

# checkov — security and compliance scanning
pip install checkov
checkov -d .
checkov -f main.tf

# terrascan — alternative security scanner
terrascan scan -t terraform

# infracost — cost estimation
infracost breakdown --path .
```

Add these to CI/CD pipelines before `plan` and `apply`.

---

## Common Pitfalls to Flag

- No `versions.tf` or unpinned providers (`version = "*"`) → always pin
- Using local state in a shared project → suggest remote backend
- Secrets in `terraform.tfvars` or as variable defaults → flag, suggest Key Vault / env vars
- `sensitive = true` missing on outputs containing secrets → add it
- No `prevent_destroy` on critical resources → suggest adding lifecycle rule
- Missing `description` on variables → always require descriptions
- `terraform apply` without `-out=planfile` → suggest saving plan first
- No `terraform validate` or `tflint` in CI → suggest adding
- Hardcoded resource names without using `locals` → suggest naming convention
- No tagging strategy → suggest `common_tags` locals pattern
