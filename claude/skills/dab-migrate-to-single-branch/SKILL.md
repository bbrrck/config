---
name: dab-migrate-to-single-branch
description: >
  Migrate a Databricks Asset Bundles (DAB) project from multi-branch environment
  deployment (dev/qa/prod branches) to a single-branch model where main is the only
  long-lived branch. Pushing to main auto-deploys to dev, manual runs deploy to qa,
  and tag pushes (v*) auto-deploy to prod. Git tags (vYYYY.MM.DD.N) become the single
  source of truth for versioning via setuptools-scm. Pass --plan-only to stop after
  presenting the plan without making changes.
version: 1.0.0
author: Claude Code
tags: [databricks, dab, azure-pipelines, migration, versioning, setuptools-scm]
argument-hint: "[--plan-only]"
allowed-tools:
  - AskUserQuestion
  - Bash
  - Edit
  - Glob
  - Grep
  - Read
  - Agent
  - Write
---

# DAB Migrate to Single Branch

Migrate a Databricks Asset Bundles (DAB) project from environment-based branching
(dev/qa/prod) to single-branch deployment with git tag versioning.

If the `--plan-only` flag is passed, stop after presenting the plan and do not make changes.

---

## Phase 1: Discovery

Read and analyze the following files to understand the current setup. Adapt to whatever
exists — not all projects will have every file.

1. **CI pipeline config** — look for `azure-pipelines.yaml`, `.azure-pipelines/`, or similar
   - Identify branch triggers (which branches trigger deployment)
   - Identify variable groups and how they map to environments
   - Identify stages/jobs structure

2. **DAB bundle config** — look for `databricks.yaml` or `databricks.yml`
   - Identify targets (dev, qa, prod, etc.)
   - Identify `git.branch` settings at bundle and target levels
   - Identify workspace hosts, variable overrides, permissions

3. **Version management** — look for `_version.py`, `__version__`, `pyproject.toml` version field
   - How is the version currently defined? (hardcoded file, dynamic, etc.)
   - Is there a bump script?
   - Where is `__version__` used in the codebase? (emails, logs, metrics, etc.)

4. **Documentation** — look for `README.md` branching/versioning sections

5. **Build system** — check `pyproject.toml` for `[build-system]` and `[tool.setuptools-scm]`

Present findings as a summary table before proceeding.

---

## Phase 2: Plan

Based on the discovery, create a migration plan covering:

### 2a. Azure Pipelines (`azure-pipelines.yaml`)

Transform the pipeline to support three trigger modes:

| Trigger        | Environment  | Mechanism                        |
| -------------- | ------------ | -------------------------------- |
| Push to `main` | dev          | Auto (default parameter)         |
| Manual run     | qa (or prod) | Pipeline parameter `environment` |
| Tag push `v*`  | prod         | Auto (tag detection)             |

**Variable group selection logic:**

```yaml
variables:
  # Tag trigger → always prod
  - ${{ if startsWith(variables['Build.SourceBranch'], 'refs/tags/v') }}:
      - group: <prod-variable-group>
  # Non-tag trigger → use parameter
  - ${{ if not(startsWith(variables['Build.SourceBranch'], 'refs/tags/v')) }}:
      - ${{ if eq(parameters.environment, 'prod') }}:
          - group: <prod-variable-group>
      - ${{ elseif eq(parameters.environment, 'qa') }}:
          - group: <qa-variable-group>
      - ${{ else }}:
          - group: <dev-variable-group>
```

**Version injection step** (add to deploy stage, before bundle validate/deploy):

```yaml
- script: |
    if [[ "$BUILD_SOURCEBRANCH" == refs/tags/v* ]]; then
      VERSION="${BUILD_SOURCEBRANCH#refs/tags/v}"
    else
      SHORT_SHA=$(git rev-parse --short HEAD)
      VERSION="dev.${SHORT_SHA}"
    fi
    echo "__version__ = \"${VERSION}\"" > src/_version.py
    echo "Version set to: ${VERSION}"
  displayName: "Set version from git"
```

Adapt the `src/_version.py` path to match the project's actual version file location.

### 2b. Databricks bundle config (`databricks.yaml`)

- Set bundle-level `git.branch` to `main`
- Remove per-target `git.branch` overrides (all targets deploy from `main`)
- Everything else (targets, workspace hosts, variables, permissions) stays unchanged

### 2c. Version management

- Add `[build-system]` with `setuptools-scm` to `pyproject.toml` (if not already present):

```toml
[build-system]
requires = ["setuptools>=64", "setuptools-scm>=8"]
build-backend = "setuptools.build_meta"

[tool.setuptools-scm]
version_file = "src/_version.py"
fallback_version = "0.0.0.dev0"
```

- Replace hardcoded version in `_version.py` with setuptools-scm fallback:

```python
# This file is managed by setuptools-scm. Do not edit manually.
# It will be overwritten by `uv sync` (locally) or CI pipeline (in deployment).
__version__ = "0.0.0.dev0"
```

- Delete any version bump scripts (e.g., `scripts/bump_version.py`)
- Remove `toml` from dev dependencies if only used by the bump script

### 2d. Documentation

Update README.md branching strategy and versioning sections to describe:
- Single `main` branch workflow
- Feature branches → squash merge into `main`
- Deployment: dev (auto on push), qa (manual), prod (tag push)
- Version format: `vYYYY.MM.DD.N` tags as single source of truth

Present the full plan to the user. If `--plan-only` was passed, stop here.

---

## Phase 3: Execute

Apply all changes from the plan:

1. Edit `azure-pipelines.yaml` — rewrite triggers, add parameters section, update variable group selection, add version injection step
2. Edit `databricks.yaml` — update `git.branch` references
3. Edit `pyproject.toml` — add build-system section, remove obsolete dev dependencies
4. Edit `src/_version.py` — replace with setuptools-scm fallback
5. Delete version bump script if it exists
6. Edit `README.md` — rewrite versioning and branching sections

---

## Phase 4: Post-migration checklist

After all file changes are made, print this checklist of manual steps the user must
perform in Azure DevOps:

```
POST-MIGRATION CHECKLIST (manual steps):
[ ] Rename default branch from dev (or current) to main in Azure DevOps repo settings
    (or: create main from dev, set as default)
[ ] Update Azure Pipeline definition to point at main branch
[ ] Create initial version tag on current HEAD:
    git tag v<current_version> && git push origin v<current_version>
[ ] Verify: push to main triggers dev deployment
[ ] Verify: tag push triggers prod deployment
[ ] Verify: manual run with environment=qa deploys to QA
[ ] Delete old environment branches (dev, qa, prod) from remote
[ ] Rebase any in-flight feature branches onto main
```
