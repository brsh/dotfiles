---
trigger: model_decision
description: "AWS best practices — activate when working with AWS services, CLI, CloudFormation, CDK, or SDK"
---

# AWS Rules

> **Stub — expand as patterns emerge.** This file covers AWS CLI usage, IAM, CloudFormation, and general AWS service patterns.

---

## General Principles

- Always specify `--region` explicitly in scripts; never rely on environment defaults in automation.
- Use IAM roles and instance profiles over access keys wherever possible.
- Tag all resources with at minimum: `Name`, `Environment`, `Owner`, `Project`.
- Prefer managed policies over inline policies for IAM.

---

## CLI

- Use `--output json` and pipe through `jq` for scripting; `--output table` for interactive use.
- Use `--dry-run` where supported (e.g., `aws ec2 run-instances --dry-run`).
- Wrap AWS CLI calls in retry logic for transient failures (throttling, network).

---

## CloudFormation / IaC

- Prefer Terraform (see `31-terraform.md`) for most infrastructure-as-code work.
- If using CloudFormation: validate templates with `aws cloudformation validate-template` before deployment.
- Use change sets (`create-change-set`) to preview changes before execution.

---

## Secrets

- Use AWS Secrets Manager or SSM Parameter Store (SecureString) for secrets.
- Never pass secrets as CloudFormation parameters — use dynamic references.
