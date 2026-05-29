---
name: aks-pipeline-migrate
description: Migrate an Azure DevOps pipeline from ubuntu-latest to the zna-devsecops-agents AKS pool. Apply known fixes, push, and babysit the run until it succeeds. Use when a user asks to migrate, convert, or move a pipeline to AKS.
version: 1.0.0
author: Claude Code
tags: [azure-devops, aks, pipelines, databricks, zna, ci-cd]
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

# AKS Pipeline Migration Skill

You are migrating an Azure DevOps pipeline from `vmImage: ubuntu-latest` to the AKS agent pool `zna-devsecops-agents`. You will apply all known fixes, commit directly to main, push, then babysit the pipeline run — diagnosing and fixing any new failures — until the run succeeds.

**Organization:** `https://dev.azure.com/zna-predictive-analytics`

---

## Phase 1 — Locate the pipeline file

1. Find the pipeline YAML in the current project directory:
   ```bash
   find . -name "azure-pipelines.yml" -o -name "azure-pipelines.yaml" | head -5
   ```
2. Read the file in full before making any changes.
3. Identify which tools the pipeline uses (uv, Databricks CLI, Terraform, etc.) so you know which fixes to apply.

---

## Phase 2 — Apply known AKS fixes

Apply **all applicable fixes** in one shot before pushing. Do not push fix-by-fix if you can avoid it.

### Fix 1 — Switch pool (ALWAYS required)

```yaml
# Before
pool:
  vmImage: ubuntu-latest

# After
pool:
  name: zna-devsecops-agents
```

### Fix 2 — uv PATH (required if pipeline installs uv)

The `astral.sh` installer puts `uv` at `$HOME/.local/bin`, not `$HOME/.cargo/bin`. The `prependpath` must point to the correct location.

```yaml
# Before
- task: Bash@3
  displayName: Install uv
  inputs:
    targetType: "inline"
    script: |
      curl -LsSf https://astral.sh/uv/install.sh | sh
      echo "##vso[task.prependpath]$HOME/.cargo/bin"

# After
- task: Bash@3
  displayName: Install uv
  inputs:
    targetType: "inline"
    script: |
      curl -LsSf https://astral.sh/uv/install.sh | sh
      echo "##vso[task.prependpath]$HOME/.local/bin"
```

### Fix 3 — Databricks CLI (required if pipeline uses Databricks CLI)

The AKS agent does NOT have write access to `/usr/local/bin`, so the Databricks `install.sh` script prints "not writable" (may exit 0 silently). The agent already has Databricks CLI pre-installed at `/usr/local/bin/databricks` (currently v0.287.0) — no install step is needed.

**Remove** the `Install Databricks CLI` step entirely, or replace with a simple verification:
```yaml
- script: databricks --version
  displayName: "Show Databricks CLI version"
```

**Remove** all hardcoded `/usr/local/bin/databricks` references — use plain `databricks` instead (it's already on PATH).

### Fix 4 — Terraform for Databricks bundle deploy (required if pipeline runs `bundle deploy`)

The pre-installed Databricks CLI (v0.287.0) tries to download Terraform at deploy time but its bundled OpenPGP signing key is expired. Fix: install Terraform yourself and point `DATABRICKS_TF_EXEC_PATH` at it.

The CLI also performs an exact version match, so set `DATABRICKS_TF_VERSION` to match the installed binary version to bypass the check.

```yaml
# Add this step BEFORE validate/deploy:
- script: |
    curl -fsSL "https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip" -o /tmp/terraform.zip
    unzip -o /tmp/terraform.zip terraform -d /tmp
    chmod +x /tmp/terraform
    /tmp/terraform version
  displayName: "Install Terraform"

# Add to env block of BOTH "Validate bundle" and "Deploy bundle" steps:
env:
  DATABRICKS_TF_EXEC_PATH: /tmp/terraform
  DATABRICKS_TF_VERSION: "1.5.7"
```

---

## Phase 3 — Commit and push

Commit all changes directly to `main` with a conventional commit message:

```bash
cd <project_dir>
git add azure-pipelines.yaml   # or azure-pipelines.yml
git commit -m "ci: migrate pipeline to zna-devsecops-agents AKS pool"
git push origin main
```

---

## Phase 4 — Find the Azure DevOps project for this repo

Determine the ADO project name from the git remote:
```bash
git remote -v
# e.g. git@ssh.dev.azure.com:v3/zna-predictive-analytics/<PROJECT>/<REPO>
```

---

## Phase 5 — Babysit the pipeline

After pushing, watch for the new run and check its result. Repeat the fix → push → watch loop until the run succeeds.

### Get the latest run ID

```bash
az pipelines runs list \
  --organization "https://dev.azure.com/zna-predictive-analytics" \
  --project "<PROJECT>" \
  --top 5 --output table
```

Note the highest numeric Run ID — that's the new run triggered by your push.

### Poll for completion

```bash
az pipelines runs show \
  --organization "https://dev.azure.com/zna-predictive-analytics" \
  --project "<PROJECT>" \
  --id <RUN_ID> --output table
```

Check `Status` and `Result` columns. Poll every ~20 seconds until `Status = completed`.

### If the run fails — read the logs

List logs:
```bash
az devops invoke \
  --organization "https://dev.azure.com/zna-predictive-analytics" \
  --area build --resource logs \
  --route-parameters project=<PROJECT> buildId=<RUN_ID> \
  --api-version "7.1" --output json
```

Fetch each log (start from the highest IDs — those are usually the failing steps):
```bash
az devops invoke \
  --organization "https://dev.azure.com/zna-predictive-analytics" \
  --area build --resource logs \
  --route-parameters project=<PROJECT> buildId=<RUN_ID> logId=<LOG_ID> \
  --api-version "7.1"
```

Look for `##[error]`, `command not found`, `not writable`, `exit code`, `Error:` in the log output.

### Monitor loop (use a background Monitor)

Use the Monitor tool to avoid busy-polling. Key caveat: `status` is a read-only variable in some shells — use `run_status` / `run_result` instead.

---

## Known failure patterns and fixes

| Symptom in logs | Root cause | Fix |
|-----------------|------------|-----|
| `uv: command not found` | `prependpath` points to `$HOME/.cargo/bin` | Change to `$HOME/.local/bin` (Fix 2) |
| `Target directory /usr/local/bin is not writable` | No root on AKS agent | Remove install step, use pre-installed CLI (Fix 3) |
| `error downloading Terraform: unable to verify checksums signature: openpgp: key expired` | CLI's bundled Terraform signing key expired | Install Terraform manually, set `DATABRICKS_TF_EXEC_PATH` (Fix 4) |
| `terraform binary is X.Y.Z but expected version is A.B.C. Set DATABRICKS_TF_VERSION to X.Y.Z to continue` | CLI version pincheck fails | Add `DATABRICKS_TF_VERSION: "X.Y.Z"` to env block (Fix 4) |
| `Bash exited with code '127'` | Binary not found / PATH issue | Check which tool is missing from PATH |

---

## AKS agent environment facts

- **Agent image:** Linux x86_64 (`/azp/_work/` workspace)
- **Home directory:** `$HOME` (typically `/home/agent`)
- **Pre-installed:** `databricks` v0.287.0 at `/usr/local/bin/databricks`
- **NOT writable without root:** `/usr/local/bin`, `/usr/bin`
- **Writable by agent:** `$HOME/.local/bin`, `/tmp`
- **uv installer path:** `$HOME/.local/bin/uv` (NOT `.cargo/bin`)
- **Shell used by ADO tasks:** `/usr/bin/bash --noprofile --norc`
- **`status` is a read-only variable** in some shells — use `run_status` in monitoring scripts

---

## Commit message convention

Use Conventional Commits, max 50 chars:
- Initial migration: `ci: migrate pipeline to zna-devsecops-agents AKS pool`
- Fix uv path: `fix(ci): fix uv PATH for AKS agent ($HOME/.local/bin)`
- Fix Terraform: `fix(ci): install Terraform directly, set DATABRICKS_TF_EXEC_PATH`
- Fix TF version: `fix(ci): set DATABRICKS_TF_VERSION to match installed Terraform`
