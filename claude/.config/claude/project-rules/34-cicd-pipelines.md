---
trigger: glob
glob: "**/{.github/workflows,azure-pipelines,pipelines}/*.{yml,yaml}"
description: "CI/CD pipeline best practices — GitHub Actions and Azure DevOps for sysadmin script automation"
---

# CI/CD Pipeline Rules

These rules apply to GitHub Actions workflows and Azure DevOps YAML pipelines.
The primary use cases are: running Pester tests, linting PowerShell/Python,
publishing scripts, and automating infrastructure change pipelines.

---

## Secrets in Pipelines — Never Hardcode

All credentials, tokens, and API keys must come from the platform's secret store:

```yaml
# GitHub Actions — store in Settings > Secrets and variables > Actions
env:
  AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  SERVICE_ACCOUNT_PASS: ${{ secrets.SERVICE_ACCOUNT_PASS }}

# Azure DevOps — store in Pipelines > Library > Variable Groups
# Link Key Vault for secrets that already live there
variables:
  - group: production-secrets    # variable group linked to Azure Key Vault
  - name: ServiceAccountUser
    value: svc-deploy
```

- Never echo or print secrets, even for debugging (`Write-Host $env:SECRET` shows up in logs)
- Use `[string]::IsNullOrEmpty($env:SECRET)` to check presence without exposing value
- Rotate secrets on a schedule; use short-lived tokens where possible (OIDC over static secrets)

---

## GitHub Actions

### Recommended Workflow Structure

```
.github/
└── workflows/
    ├── ci.yml           # run on every PR — lint + test
    ├── release.yml      # run on merge to main — publish/deploy
    └── scheduled.yml    # cron jobs (cleanup tasks, reports)
```

### PowerShell Lint + Test Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  lint-and-test:
    runs-on: windows-latest    # use windows-latest for AD module access;
                               # ubuntu-latest for cross-platform PS scripts

    steps:
      - uses: actions/checkout@v4

      - name: Install PSScriptAnalyzer
        shell: pwsh
        run: Install-Module PSScriptAnalyzer -Force -Scope CurrentUser

      - name: Lint PowerShell
        shell: pwsh
        run: |
          $results = Invoke-ScriptAnalyzer -Path ./src -Recurse -Severity Error,Warning
          if ($results) {
            $results | Format-Table -AutoSize
            exit 1
          }

      - name: Install Pester
        shell: pwsh
        run: Install-Module Pester -Force -Scope CurrentUser -MinimumVersion 5.0

      - name: Run Tests
        shell: pwsh
        run: |
          $config = New-PesterConfiguration
          $config.Run.Path = './tests'
          $config.Output.Verbosity = 'Detailed'
          $config.TestResult.Enabled = $true
          $config.TestResult.OutputPath = 'TestResults.xml'
          $config.TestResult.OutputFormat = 'JUnitXml'
          Invoke-Pester -Configuration $config

      - name: Publish Test Results
        uses: dorny/test-reporter@v1
        if: always()
        with:
          name: Pester Tests
          path: TestResults.xml
          reporter: java-junit
```

### Python Lint + Test Workflow

```yaml
name: Python CI

on:
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'

      - name: Install dependencies
        run: pip install -r requirements.txt -r requirements-dev.txt

      - name: Lint with ruff
        run: ruff check .

      - name: Type check with mypy
        run: mypy src/

      - name: Run tests
        run: pytest tests/ -v --tb=short --junitxml=pytest-results.xml

      - name: Publish Test Results
        uses: dorny/test-reporter@v1
        if: always()
        with:
          name: pytest
          path: pytest-results.xml
          reporter: java-junit
```

### OIDC Authentication (preferred over static secrets for Azure)

```yaml
# Use OIDC instead of service principal client secrets
# Set up once: Azure AD > App Registrations > Federated Credentials

permissions:
  id-token: write    # required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          # No client secret needed — token is short-lived and auto-rotated

      - name: Run Azure PowerShell
        uses: azure/powershell@v2
        with:
          inlineScript: Get-AzResourceGroup | Select-Object ResourceGroupName
          azPSVersion: latest
```

### Self-Hosted Runners (for AD/internal network access)

When a workflow needs access to on-premises AD, internal servers, or resources
not reachable from GitHub's hosted runners:

```yaml
jobs:
  ad-operations:
    runs-on: [self-hosted, windows, domain-joined]
    # Labels match what you configured on the runner

    steps:
      - uses: actions/checkout@v4

      - name: Run AD Script
        shell: pwsh
        run: ./src/Invoke-UserCleanup.ps1 -WhatIf
        env:
          TARGET_OU: ${{ vars.TARGET_OU }}
```

Self-hosted runner security notes:
- Run the runner service as a dedicated low-privilege domain service account
- Never use Domain Admin for the runner service account
- Scope the service account's permissions to exactly what the pipeline needs
- Use runner groups to restrict which repos can use sensitive runners

### Caching Dependencies

```yaml
# PowerShell modules — cache to avoid re-downloading on every run
- name: Cache PowerShell modules
  uses: actions/cache@v4
  with:
    path: ~/Documents/PowerShell/Modules   # Windows PS 7
    key: ${{ runner.os }}-psmodules-${{ hashFiles('**/requirements.psd1') }}

# Python venv
- name: Cache pip
  uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
```

---

## Azure DevOps Pipelines

### Recommended Structure

```yaml
# azure-pipelines.yml — root of repo
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - src/**
      - tests/**

pr:
  branches:
    include:
      - main

pool:
  vmImage: windows-latest    # or ubuntu-latest, macOS-latest

variables:
  - group: my-variable-group  # links to Key Vault or manually-defined secrets
  - name: PSAnalyzerSeverity
    value: Error

stages:
  - stage: Validate
    jobs:
      - job: LintAndTest
        steps:
          - task: PowerShell@2
            displayName: 'Lint - PSScriptAnalyzer'
            inputs:
              targetType: inline
              script: |
                Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
                $results = Invoke-ScriptAnalyzer -Path ./src -Recurse `
                    -Severity $(PSAnalyzerSeverity)
                if ($results) { $results | Format-Table; exit 1 }

          - task: PowerShell@2
            displayName: 'Test - Pester'
            inputs:
              targetType: inline
              script: |
                Install-Module Pester -Force -Scope CurrentUser -MinimumVersion 5.0
                Invoke-Pester ./tests -OutputFile TestResults.xml `
                    -OutputFormat JUnitXml -CI

          - task: PublishTestResults@2
            displayName: 'Publish Test Results'
            condition: always()
            inputs:
              testResultsFormat: JUnit
              testResultsFiles: TestResults.xml

  - stage: Deploy
    dependsOn: Validate
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: DeployScripts
        environment: production     # creates an approval gate in ADO
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzurePowerShell@5
                  displayName: 'Deploy to Azure'
                  inputs:
                    azureSubscription: 'MyServiceConnection'
                    ScriptType: InlineScript
                    Inline: ./src/Deploy-Scripts.ps1
                    azurePowerShellVersion: LatestVersion
```

### Key Vault Integration in ADO

```yaml
# Link Key Vault to a variable group in ADO Library
# Then reference variables as if they were pipeline variables
variables:
  - group: keyvault-secrets    # maps to Azure Key Vault via service connection

steps:
  - task: AzureKeyVault@2
    inputs:
      azureSubscription: 'MyServiceConnection'
      KeyVaultName: 'my-keyvault'
      SecretsFilter: 'ServiceAccountPassword,ApiToken'
      RunAsPreJob: true

  - task: PowerShell@2
    inputs:
      targetType: inline
      script: |
        # Variables are now available as env vars with the same name
        $pass = ConvertTo-SecureString $env:ServiceAccountPassword -AsPlainText -Force
```

---

## Pipeline Security Best Practices

- **Pin action versions to a commit SHA** in GitHub Actions (not `@main` or `@latest`):
  ```yaml
  # Bad — can be hijacked if the tag is moved
  uses: actions/checkout@v4

  # Better for high-security repos — pin to exact commit
  uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
  ```

- **Minimal permissions** — declare only what the job needs:
  ```yaml
  permissions:
    contents: read        # default read
    id-token: write       # only if using OIDC
  ```

- **No `pull_request_target`** with untrusted code execution — it runs with elevated
  permissions and is a common attack vector in public repos.

- **Environment protection rules** in GitHub / ADO for production deployments:
  - Require manual approval before deploy jobs run
  - Restrict to specific branches (`main` only)

- **Audit pipeline changes** — treat `.github/workflows/` and `azure-pipelines.yml`
  with the same scrutiny as infrastructure code. A malicious pipeline change can
  exfiltrate all secrets.

---

## Common Pitfalls to Flag

- Hardcoded secrets or credentials anywhere in pipeline YAML → immediate flag
- `continue-on-error: true` masking test failures → remove or scope narrowly
- No test step before a deploy step → gate deployments on tests passing
- `pull_request_target` trigger running code from the PR branch → security risk
- Running the self-hosted runner as a domain admin or local admin → least privilege
- No caching on module installs → slow pipelines; add cache steps
- `Set-ExecutionPolicy Bypass` in pipeline steps → use `-ExecutionPolicy Bypass` on
  the `pwsh` invocation instead, or sign scripts
- Not pinning `actions/checkout` or other third-party actions → supply chain risk
