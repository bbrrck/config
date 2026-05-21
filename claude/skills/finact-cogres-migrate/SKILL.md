---
name: finact-cogres-migrate
description: >
  Autonomously migrate a FinAct Cognitive Reserving LOB project from old workspace
  (anadbfinactd01, pybrickz v2, ADLS parquet) to new workspace (actuarialdbwsp01n1d08,
  pybrickz v3, Unity Catalog Delta). Creates full project scaffold, migrates all
  notebooks, sets up DABs bundle + Azure Pipelines CI/CD, and generates validation
  notebooks. Use when asked to migrate any scoring/modeling project (GL, WC, AL, PL,
  XS, Prop, etc.).
version: 1.0.0
author: Claude Code
tags: [databricks, pybrickz, unity-catalog, finact, migration, azure, dabs]
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
---

# FinAct Cognitive Reserving → UC Migration Skill

You are an autonomous migration agent. Your job is to transform a legacy pybrickz v2
Databricks project into a fully modernized pybrickz v3 + Unity Catalog project,
following the patterns established in the **reference implementation** described below.

---

## 1. Reference Implementation

The canonical migrated project is:
```
/Users/TIBOR.STANKO/Projects/finact-uc/gl_gen_1/scoring/
```

Study this project before migrating any other. It defines the target state. Key
structural elements:

```
{project_root}/
├── config/
│   ├── config.yaml           # catalog, schema, owner
│   ├── io/io.yaml            # all I/O declarations
│   ├── job_params/job_params.yaml  # parameters + derived values
│   └── bundle/bundle.yaml    # pybrickz bundle settings (workspaces, libs)
├── src/
│   ├── __init__.py
│   ├── project.py            # pybrickz wrapper with custom resolvers
│   ├── utils.py              # shared utilities (read_partition, write_partition, etc.)
│   └── *.py                  # domain modules (copied/adapted from Common Repos)
├── notebooks/
│   ├── *.py                  # Databricks Python notebooks (# COMMAND ----------)
│   ├── migration/            # data + model migration notebooks
│   └── validation/           # zmatch-based comparison notebooks
├── resources/
│   └── jobs/
│       └── *.yml             # Databricks job definitions (DABs format)
├── deployment/
│   └── create_bundle.py      # pybrickz bundle creation helper notebook
├── databricks.yml            # DABs bundle entry point
├── azure-pipelines.yaml      # CI/CD pipeline
└── requirements.txt          # pybrickz>=3.0
```

---

## 2. Infrastructure Constants

These values are fixed for ALL finact-uc projects. Never prompt the user for them.

| Constant | Value |
|---|---|
| New workspace (dev/target) | `https://adb-5205854623186810.10.azuredatabricks.net` |
| New workspace name | `actuarialdbwsp01n1d08` |
| Old workspace URL | `https://adb-4730560418510872.12.azuredatabricks.net` |
| Old workspace name | `anadbfinactd01` |
| Prod workspace | `https://adb-6461475676310004.4.azuredatabricks.net` |
| Dev catalog | `finact_cognit_dev` |
| Prod catalog | `finact_cognit_prod` |
| Models catalog | `models.cognitive_reserving` |
| ADO organization | `zna-predictive-analytics` |
| ADO project | `finact-uc` |
| Git root | `zna-predictive-analytics/finact-uc` |
| pybrickz version | `3.11.0` |
| mlflow-skinny version | `3.12.0` |
| Spark version | `14.3.x-cpu-ml-scala2.12` |
| Default cluster type | `Standard_D64s_v3` (autoscale 2-8) |
| Data security mode | `SINGLE_USER` |
| Old ADLS root | `abfss://finact@storadlsfinact02.dfs.core.windows.net/anadbfinactd01/dev/finact/finact_cogres_sandbox/v1/` |
| New ADLS root | `abfss://cognit@actuarialstoradls01n1d08.dfs.core.windows.net/` |

---

## 3. LOB Inventory

| LOB | Repo | Dev schema(s) | Coverages | Complexity |
|-----|------|---------------|-----------|------------|
| AL1 | al_gen_1 | al_gen_1_modeling, al_gen_1_scoring | bi, pd | Medium |
| AL2 | al_gen_2 | al_gen_2_modeling, al_gen_2_scoring | bi, pd (×4 horizons) | High |
| GL | gl_gen_1 | gl_gen_1_modeling, gl_gen_1_scoring | comp, oper, prem, prod | High |
| PL | pl_gen_1 | pl_gen_1_modeling, pl_gen_1_scoring | doeo, hc | High |
| WC | wc_gen_1 | wc_gen_1_modeling, wc_gen_1_scoring | ind, mlt, mo | Medium |
| XS | xs_gen_1 | xs_gen_1_modeling, xs_gen_1_scoring | single | Medium |
| Prop | prop_gen_1 | prop_gen_1_modeling, prop_gen_1_scoring | single | Low |

**Schema naming:** In prod, `{lob}_{gen}_scoring`. In dev (personal), append `_{username}`.
Example: `gl_gen_1_scoring_tibor` (Tibor's dev), `gl_gen_1_scoring` (prod).

---

## 4. Old vs New: Core Differences

| Aspect | Old (v2) | New (v3) |
|--------|----------|----------|
| pybrickz init | `pb.set_project("finact_cogres_sandbox", "v1")` | `config = set_project(parametrize_by_coverage=...)` |
| Parameters | `dbutils.widgets.get('eval_year')` | `config.job_params.eval_year` |
| Data storage | Parquet files on ADLS (`GL/Data/{eval_time}/`) | UC Delta tables (`finact_cognit_dev.{schema}.{table}`) |
| Data I/O | `pb.read_dataset("path/to/file.parquet")` | `pb.read("key")` (key defined in io.yaml) |
| Partitioning | Directory per run (`f"GL/Data/{eval_time}/"`) | Single Delta table, partitioned by `proc_yq` column |
| Shared utilities | `sys.path.insert(0, '/Repos/finact/.../Common/')` | `from src.module import function` |
| Notebook format | `.ipynb` (Jupyter) | `.py` with `# COMMAND ----------` delimiters |
| Models | JSON files in ADLS | MLflow UC Registry (`models.cognitive_reserving.*`) |
| Deployment | Manual / old cluster jobs | DABs bundle (`databricks.yml`) + Azure Pipelines |
| Config | Hardcoded values in notebooks | YAML config (`config/` directory, Hydra/OmegaConf) |
| Pandas | `import pandas as pd` (common) | Native PySpark or Polars (pandas forbidden) |
| Data lineage | None | `FLOW` dict + `pb.flow.show(FLOW)` in each notebook |

---

## 5. Migration Workflow

### Phase 0: Gather Inputs

Ask the user for (if not already known):
1. **LOB / repo name** — e.g., `wc_gen_1`, `pl_gen_1`
2. **Scope** — `scoring`, `modeling`, or both
3. **Source path** — path to the old project in cognitive-reserving repo
4. **Target path** — path for the new project (or create it)
5. **Owner email** — for config.yaml
6. **Job definitions** — check `artifacts/` in the migration repo for pre-exported JSONs

Check `MIGRATION_TIMELINE.md` for current migration status of the project.

---

### Phase 1: Discovery

Explore the source project thoroughly. Identify:

1. **Notebook inventory**: list all `.ipynb` and `.py` notebooks, their purpose, and sequence
2. **Data reads**: every `pb.read_dataset(...)` call → reconstruct the full path → map to io.yaml key
3. **Data writes**: every `pb.write_dataset(...)` call → map to io.yaml key
4. **SQL connections**: Yellowbrick (`YB-ZEADIM-Prod-Pada`, `YB-EDW-Prod-Pada`) → declare in io.yaml
5. **Shared imports**: `sys.path.insert(...)` → identify which modules → copy to `src/`
6. **Widget parameters**: `dbutils.widgets.get(...)` → map to `job_params.yaml` fields
7. **Hardcoded values**: find all hardcoded eval_time, first_year, fit_period, etc.
8. **Coverage parameterization**: which notebooks use `coverage` widget → `parametrize_by_coverage=True`
9. **Model dependencies**: any `.json` model files or MLflow model loads
10. **Existing pybrickz v3 work**: check if the target repo already has partial migration

Check the job JSON in `artifacts/job_Q_{LOB}_Scoring_*.json` for the task graph structure.

Produce a **discovery summary** with:
- Notebook inventory table
- I/O mapping table (old path → new io.yaml key)
- Module migration plan

---

### Phase 2: Project Scaffold

Create all skeleton files. Start with the ones that everything else depends on.

#### `requirements.txt`
```
pybrickz>=3.0
```

#### `config/config.yaml`
```yaml
project:
  catalog: finact_cognit_dev
  schema: {lob}_{gen}_{scope}_{username}   # TODO: set correct schema
  owner: {owner_email}
  created: {today_date}
  description: "{LOB} {scope} pipeline"

defaults:
  - io: io
  - job_params: job_params
```

#### `config/job_params/job_params.yaml`
```yaml
eval_year: ???        # set via widget or job parameter
eval_month: ???       # set via widget or job parameter

# --- Static values (adjust per LOB) ---
coverages: [comp, oper, prem, prod]   # GL example — adjust for other LOBs
time_model: all
first_year: 2001
trend_base_year: 2017
fit_period: 201702

# --- Derived values (resolved at runtime by custom resolvers in src/project.py) ---
eval_time: "${finact.eval_time:${job_params.eval_year},${job_params.eval_month}}"
max_dev_qtr: "${finact.max_dev_qtr:${job_params.eval_year},${job_params.first_year},${job_params.eval_month}}"
next_year: "${finact.next_year:${job_params.eval_year},${job_params.eval_month}}"
next_month: "${finact.next_month:${job_params.eval_month}}"
date_cutoff: "${finact.date_cutoff:${job_params.eval_year},${job_params.eval_month}}"
```

**Per-LOB coverage adjustments:**
- GL: `coverages: [comp, oper, prem, prod]`
- WC: `coverages: [ind, mlt, mo]`
- AL1/AL2: `coverages: [bi, pd]`
- PL: `coverages: [doeo, hc]`
- XS/Prop: `coverages: [single]`  (or omit if not coverage-parameterized)

#### `config/io/io.yaml`

Start with the standard SQL connections and common UC tables. Add project-specific tables.

```yaml
# ==================== SQL CONNECTIONS ====================
zeadim:
  type: sql
  name: YB-ZEADIM-Prod-Pada

edw:
  type: sql
  name: YB-EDW-Prod-Pada

# ==================== COMMON UC TABLES ====================
superfamily:
  type: uc_table
  uri: ${project.catalog}.common.superfamily

corp_rsv_ln_map:
  type: uc_table
  uri: ${project.catalog}.common.corp_rsv_ln_map

sic2_table:
  type: uc_table
  uri: ${project.catalog}.common.sic2_table

state_table:
  type: uc_table
  uri: ${project.catalog}.common.state_table

matching_ded_pol:
  type: uc_table
  uri: ${project.catalog}.common.matching_ded_pol

# ==================== MODELS (UC Registry) ====================
trend:
  type: uc_model
  uri: models.cognitive_reserving.{lob}_trend_{fit_period}   # TODO: adjust

# ==================== PROJECT TABLES ====================
# Pattern: all project tables use mode: append + optimize: true
# They are partitioned by proc_yq (processing quarter YYYYQ)
# 00_ prefix = raw input/output, sequentially numbered

# Example entries (fill in per-project):
clm_mart:
  type: project_table
  name: 00_clm_mart
  format: delta
  mode: append
  optimize: true
```

**io.yaml key naming rules:**
- Short, snake_case, descriptive
- Remove numeric prefixes for the key name (but keep them in `name:`)
- Coverage-specific tables: use `{table}_{coverage}` pattern
  - e.g., `data_to_score_comp`, `data_to_score_oper`
  - Or use a single key with coverage interpolation if pybrickz supports it

#### `config/bundle/bundle.yaml`
```yaml
# pybrickz bundle configuration (used by deployment/create_bundle.py)
project:
  git: zna-predictive-analytics/finact-uc/{repo_name}
  workflows: ["{lob}_{gen}"]   # TODO: adjust workflow names

workspaces:
  dev:
    workspace: https://adb-5205854623186810.10.azuredatabricks.net/
  prod:
    workspace: https://adb-6461475676310004.4.azuredatabricks.net/

libraries:
  mlflow-skinny: "3.12.0"
  protobuf: "7.34.1"
  pybrickz: "3.11.0"
  # Add spark-nlp only if the project uses SparkNLP text processing:
  # sparknlp: "5.1.2"
```

#### `src/__init__.py`
```python
```
(empty file)

#### `src/project.py`
```python
from __future__ import annotations

from datetime import datetime

from omegaconf import DictConfig
from pybrickz import set_project as _set_project
from pybrickz.config import register_resolvers
from pybrickz.core.logging import logger


def _register_finact_resolvers() -> None:
    register_resolvers({
        # eval_time: YYYYQ format (e.g. 202601 = Q1 2026)
        "finact.eval_time": lambda eval_year, eval_month: (
            int(eval_year) * 100 + int(eval_month) // 3
        ),
        # max development quarter for triangle (depends on first_year)
        "finact.max_dev_qtr": lambda eval_year, first_year, eval_month: (
            (int(eval_year) - int(first_year) + 1) * 4 + (int(eval_month) // 3 - 2)
        ),
        # next eval period
        "finact.next_year": lambda eval_year, eval_month: (
            int(eval_year) + 1 if int(eval_month) > 9 else int(eval_year)
        ),
        "finact.next_month": lambda eval_month: (
            int(eval_month) % 12 + 3 if int(eval_month) <= 9 else 3
        ),
        # date string for SQL cutoff filters
        "finact.date_cutoff": lambda eval_year, eval_month: (
            f"{eval_year}-{int(eval_month) + 1:02d}-01"
        ),
    })


def set_project(parametrize_by_coverage: bool = False) -> DictConfig:
    """Initialize pybrickz project with finact cognitive reserving configuration."""
    _register_finact_resolvers()

    # Add eval parameter widgets
    now = datetime.now()
    dbutils.widgets.text("eval_year", str(now.year))  # noqa: F821
    dbutils.widgets.text("eval_month", str(now.month))  # noqa: F821

    if parametrize_by_coverage:
        coverages = ["comp", "oper", "prem", "prod"]  # TODO: adjust per LOB
        dbutils.widgets.dropdown("coverage", coverages[0], coverages)  # noqa: F821

    config = _set_project(resolve=True)

    # Log all resolved parameters
    for key, val in config.job_params.items():
        logger.info(f"  {key}: {val}")

    return config
```

#### `src/utils.py`
```python
from __future__ import annotations

import pybrickz as pb
from pyspark.sql import DataFrame
from pybrickz.core.logging import logger


def get_proc_yq(config) -> int:
    """Return the current processing quarter as YYYYQ integer."""
    return config.job_params.eval_time


def read_partition(name: str, config) -> DataFrame:
    """Read a project table filtered to the current proc_yq partition."""
    proc_yq = get_proc_yq(config)
    return pb.read(name).filter(f"proc_yq = {proc_yq}")


def write_partition(df: DataFrame, name: str, config) -> None:
    """Write a DataFrame to a project table, replacing only the current proc_yq partition."""
    proc_yq = get_proc_yq(config)
    from pyspark.sql import functions as F
    df = df.withColumn("proc_yq", F.lit(proc_yq))
    pb.write(df, name, replace_where=f"proc_yq = {proc_yq}", mode="overwrite")
    logger.info(f"Written to {name} (proc_yq={proc_yq})")
```

---

### Phase 3: Notebook Migration

Convert each notebook from old format to new. Follow this checklist for every notebook:

#### 3.1 Format Conversion (.ipynb → .py)

Old notebooks are `.ipynb` (Jupyter). New notebooks are `.py` Databricks Python notebooks.

**Target format:**
```python
# Databricks notebook source

# COMMAND ----------

# Imports and project init
from src.project import set_project
import pybrickz as pb
from pybrickz.core.logging import logger

config = set_project(parametrize_by_coverage=False)  # True for coverage-parameterized notebooks

eval_year = config.job_params.eval_year
eval_month = config.job_params.eval_month
eval_time = config.job_params.eval_time

# COMMAND ----------

# MAGIC %md
# MAGIC ## Step Name

# COMMAND ----------

FLOW = {
    "step_name": {
        "in": ["input_table"],
        "out": ["output_table"],
    },
}
pb.flow.show(FLOW)

# COMMAND ----------

# Business logic here
df = pb.read("input_table")
# ... transformations ...
write_partition(df, "output_table", config)
```

#### 3.2 API Mapping

| Old pattern | New pattern |
|-------------|-------------|
| `pb.set_project("finact_cogres_sandbox", "v1")` | `config = set_project(parametrize_by_coverage=False)` |
| `dbutils.widgets.get('eval_year')` | `config.job_params.eval_year` |
| `dbutils.widgets.get('coverage')` | `config.job_params.coverage` |
| `eval_time = eval_year * 100 + eval_month // 3` | `eval_time = config.job_params.eval_time` (resolved by custom resolver) |
| `pb.read_dataset(f"GL/Data/{eval_time}/00_clm_mart.parquet")` | `pb.read("clm_mart")` |
| `pb.write_dataset(df, f"GL/Scoring/{eval_time}/file.parquet", replace_if_exists=True)` | `write_partition(df, "file_key", config)` |
| `pb.read_pandas(f"GL/Tables/ref_table.parquet")` | `pb.to_pandas(pb.read("ref_table"))` |
| `pb.read_spark(...)` | `pb.read("key")` |
| `pb.sql_connection("YB-ZEADIM-Prod-Pada")` | `pb.sql_connection("zeadim")` (key from io.yaml) |
| `import sys; sys.path.insert(0, '/Repos/.../Common/...')` | `from src.module import function` |
| `import pandas as pd` | Remove. Use native PySpark or `pb.to_polars(pb.read(...))` |

#### 3.3 FLOW Documentation

Every notebook must have a `FLOW` dict documenting its data lineage:

```python
FLOW = {
    "notebook_step_name": {
        "in": ["input_table_1", "sql_conn_key"],
        "out": ["output_table_1", "output_table_2"],
    },
    "optional_second_step": {
        "in": ["input_table_2"],
        "out": ["output_table_3"],
    },
}
pb.flow.show(FLOW)
```

Use the same key names as in `io.yaml`.

#### 3.4 Coverage Parameterization

Notebooks that run per-coverage (e.g., scoring notebooks with `coverage` widget) use:
```python
config = set_project(parametrize_by_coverage=True)
coverage = config.job_params.coverage
```

Notebooks that run once for all coverages (e.g., data prep, ultimate calculations) use:
```python
config = set_project(parametrize_by_coverage=False)
```

#### 3.5 Partitioned Tables Pattern

Old pattern (directory per run):
```python
dir_data = f"GL/Data/{eval_time}"
df = pb.read_dataset(f"{dir_data}/00_clm_mart.parquet")
pb.write_dataset(result_df, f"GL/Scoring/{eval_time}/scored.parquet", replace_if_exists=True)
```

New pattern (single Delta table, partitioned by `proc_yq`):
```python
df = read_partition("clm_mart", config)          # filtered to current proc_yq
write_partition(result_df, "scored", config)      # writes proc_yq column, replaces partition
```

`io.yaml` entry for partitioned tables:
```yaml
scored:
  type: project_table
  name: 00_scored                 # prefix reflects pipeline stage
  format: delta
  mode: append                    # append + replace_where = partition replace
  optimize: true
```

#### 3.6 Notebook Naming Convention

Preserve the original numbering scheme. Examples:
- `GL_Q_01_Pull_Data.py`
- `GL_Q_02_Data_Prep.py`
- `GL_Q_03a_Text_Cleaning.py`
- `GL_Q_05a_IBNER_Scoring.py`

---

### Phase 4: Shared Module Migration

#### 4.1 Identify Shared Imports

Old notebooks import from Databricks Repos:
```python
import sys
sys.path.insert(0, '/Repos/finact/cognitive-reserving/Common/Quarterly_Scoring/utils/')
from ibner_scoring_pyspark import score_model, adjust_predictions
```

New projects carry these as `src/` modules.

#### 4.2 Migration Steps

1. Identify each unique module path referenced across all notebooks
2. Read the source file from the old cognitive-reserving Common utilities
3. Copy to `src/{module_name}.py`
4. Update imports in all notebooks: `from src.module import function`
5. Remove all `sys.path.insert(...)` calls

#### 4.3 Common Modules to Migrate

| Old path (in Common/) | New location |
|---|---|
| `utils/generic_func.py` | `src/generic_func.py` |
| `utils/ibner_scoring_pyspark.py` | `src/ibner_scoring_pyspark.py` |
| `utils/pure_scoring.py` | `src/pure_scoring.py` |
| `utils/alertz_pyspark.py` | `src/alertz_pyspark.py` |
| `utils/rvt_pyspark.py` | `src/rvt_pyspark.py` |
| `utils/triangle_data.py` | `src/triangle_data.py` |
| `utils/ciid_remap.py` | `src/ciid_remap.py` |
| `utils/partial_year_adj.py` | `src/partial_year_adj.py` |
| `utils/imputed_triangle.py` | `src/imputed_triangle.py` |

#### 4.4 Pandas Removal

If any module uses pandas, replace with native PySpark:
- `pd.DataFrame` → `pyspark.sql.DataFrame`
- `df.merge(...)` → `df.join(...)`
- `df.groupby(...).agg(...)` → `df.groupBy(...).agg(...)`
- `df[col]` → `df.select(col)` or `df.withColumn(...)`
- `df.apply(...)` → `df.withColumn(F.udf(...))`

If Polars is genuinely better for a module (small reference tables, not Spark), use:
```python
import polars as pl
df = pb.to_polars(pb.read("reference_table"))
```

---

### Phase 5: Bundle & CI/CD Configuration

#### 5.1 `databricks.yml`

```yaml
bundle:
  name: finact_cognit_{lob}_{gen}

variables:
  default_eval_year:
    description: Default evaluation year for job parameters
    default: "2026"
  default_eval_month:
    description: Default evaluation month for job parameters
    default: "3"
  # Library versions (single source of truth)
  pybrickz_version:
    default: "3.11.0"
  mlflow_skinny_version:
    default: "3.12.0"

include:
  - resources/jobs/*.yml

targets:
  dev:
    mode: development
    default: true
    workspace:
      host: https://adb-5205854623186810.10.azuredatabricks.net
      root_path: /Deployment/.bundle/${bundle.name}/${bundle.target}

  prod:
    mode: production
    workspace:
      host: https://adb-6461475676310004.4.azuredatabricks.net
      root_path: /Deployment/.bundle/${bundle.name}/${bundle.target}
```

#### 5.2 Job YAML Template (`resources/jobs/q_{lob}_scoring.yml`)

Model after the GL scoring job. Key patterns:
- Main job: sequential + parallel tasks
- Coverage job (if needed): per-coverage tasks that run in parallel
- Use `job_cluster_key` references, not `existing_cluster_id`
- All notebook paths relative (no absolute `/Workspace/Repos/...` paths)

```yaml
resources:
  jobs:
    q_{lob}_scoring:
      name: "[${bundle.target}] Q_{LOB}_Scoring"
      max_concurrent_runs: 1
      queue:
        enabled: true
      parameters:
        - name: eval_year
          default: ${var.default_eval_year}
        - name: eval_month
          default: ${var.default_eval_month}

      job_clusters:
        - job_cluster_key: default_cluster
          new_cluster:
            spark_version: 14.3.x-cpu-ml-scala2.12
            node_type_id: Standard_D64s_v3
            autoscale:
              min_workers: 2
              max_workers: 8
            azure_attributes:
              first_on_demand: 1
              availability: ON_DEMAND_AZURE
            enable_elastic_disk: true
            data_security_mode: SINGLE_USER
            spark_env_vars:
              DBX_ENV: ${bundle.target}
            cluster_log_conf:
              dbfs:
                destination: dbfs:/logs/${bundle.name}/${bundle.target}

      tasks:
        - task_key: Data_Prep
          job_cluster_key: default_cluster
          libraries:
            - pypi:
                package: pybrickz==${var.pybrickz_version}
            - pypi:
                package: mlflow-skinny==${var.mlflow_skinny_version}
          notebook_task:
            notebook_path: notebooks/{LOB}_Q_02_Data_Prep
            base_parameters:
              eval_year: ${job.parameters.eval_year}
              eval_month: ${job.parameters.eval_month}
            source: GIT

        # Add subsequent tasks with depends_on
```

**Converting old job JSON to YAML:**
- Strip: `job_id`, `creator_user_name`, `created_time`, `run_as`, `settings.format`
- Replace `existing_cluster_id` with `job_cluster_key` (define cluster in `job_clusters`)
- Strip absolute notebook paths: `/Repos/finact/cognitive-reserving/{LOB} Scoring/notebook` → `notebooks/{LOB}_notebook`
- Wrap job name: `"Q_GL_Scoring"` → `"[${bundle.target}] Q_GL_Scoring"`

#### 5.3 `azure-pipelines.yaml`

```yaml
trigger:
  branches:
    include:
      - main
  tags:
    include:
      - "v*"

parameters:
  - name: environment
    type: string
    default: dev
    values: [dev, qa, prod]

variables:
  SHORT_SHA: $[substring(variables['Build.SourceVersion'], 0, 8)]
  IS_TAG: $[startsWith(variables['Build.SourceBranch'], 'refs/tags/')]

stages:
  - stage: Deploy
    jobs:
      - job: DeployBundle
        pool:
          vmImage: ubuntu-latest
        variables:
          - ${{ if eq(variables.IS_TAG, 'true') }}:
            - name: TARGET_ENV
              value: prod
          - ${{ if ne(variables.IS_TAG, 'true') }}:
            - name: TARGET_ENV
              value: ${{ parameters.environment }}
        steps:
          - task: UsePythonVersion@0
            inputs:
              versionSpec: "3.10"

          - script: |
              curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh
              databricks --version
            displayName: Install Databricks CLI

          - script: databricks bundle validate --target $(TARGET_ENV)
            displayName: Validate Bundle
            env:
              DATABRICKS_HOST: $(DATABRICKS_HOST)
              DATABRICKS_TOKEN: $(DATABRICKS_TOKEN)

          - script: databricks bundle deploy --target $(TARGET_ENV)
            displayName: Deploy Bundle
            env:
              DATABRICKS_HOST: $(DATABRICKS_HOST)
              DATABRICKS_TOKEN: $(DATABRICKS_TOKEN)
```

#### 5.4 `deployment/create_bundle.py`

```python
# Databricks notebook source

# COMMAND ----------
# Install Databricks SDK
%pip install databricks-sdk --quiet
dbutils.library.restartPython()

# COMMAND ----------
import pybrickz as pb
from src.project import set_project

set_project()
pb.create_bundle(export_dir="../")
```

---

### Phase 6: Migration Utilities

Create `notebooks/migration/` notebooks for one-time data and model migration.

#### 6.1 Historical Data Migration (`load_historical_partitions_to_uc_delta.py`)

```python
# Databricks notebook source

# COMMAND ----------

# Set up Azure authentication for old storage
spark.conf.set(
    "fs.azure.account.auth.type.storadlsfinact02.dfs.core.windows.net",
    "OAuth"
)
spark.conf.set(
    "fs.azure.account.oauth.provider.type.storadlsfinact02.dfs.core.windows.net",
    "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
)
spark.conf.set(
    "fs.azure.account.oauth2.client.id.storadlsfinact02.dfs.core.windows.net",
    dbutils.secrets.get(scope="u_tibor.stanko", key="anadbfinactd01-client-id")
)
spark.conf.set(
    "fs.azure.account.oauth2.client.secret.storadlsfinact02.dfs.core.windows.net",
    dbutils.secrets.get(scope="u_tibor.stanko", key="anadbfinactd01-client-secret")
)
spark.conf.set(
    "fs.azure.account.oauth2.client.endpoint.storadlsfinact02.dfs.core.windows.net",
    dbutils.secrets.get(scope="u_tibor.stanko", key="anadbfinactd01-client-endpoint")
)

OLD_ADLS_ROOT = "abfss://finact@storadlsfinact02.dfs.core.windows.net/anadbfinactd01/dev/finact/finact_cogres_sandbox/v1"
LOB_DIR = "{LOB}"  # e.g. "GL"

# COMMAND ----------

def write_historical_partition(table_name: str, proc_yq: int, file_name: str | None = None) -> None:
    """Copy a historical parquet partition from old ADLS to UC Delta."""
    if file_name is None:
        file_name = f"{table_name}_{proc_yq}"
    old_path = f"{OLD_ADLS_ROOT}/{LOB_DIR}/Scoring/{proc_yq}/{file_name}.parquet"
    try:
        df = spark.read.parquet(old_path)
        df = df.withColumn("proc_yq", F.lit(proc_yq))
        pb.write(df, table_name, replace_where=f"proc_yq = {proc_yq}", mode="overwrite")
        print(f"  Loaded {table_name} proc_yq={proc_yq}: {df.count()} rows")
    except Exception as e:
        print(f"  SKIP {table_name} proc_yq={proc_yq}: {e}")

# COMMAND ----------

# Load historical quarters
HISTORICAL_QUARTERS = [202101, 202102, 202103, 202104, 202201, 202202, 202203, 202204,
                       202301, 202302, 202303, 202304, 202401, 202402, 202403, 202404]

TABLE_NAMES = [
    "00_clm_mart",
    # TODO: add all tables that need historical data
]

for table in TABLE_NAMES:
    for proc_yq in HISTORICAL_QUARTERS:
        write_historical_partition(table, proc_yq)
```

#### 6.2 Model Migration (`copy_models_from_old_wsp.py`)

```python
# Databricks notebook source

# COMMAND ----------

import mlflow
from mlflow.tracking import MlflowClient

# Configure remote (old) workspace registry
OLD_WORKSPACE_URL = "https://adb-4730560418510872.12.azuredatabricks.net"
old_client = MlflowClient(
    registry_uri=f"databricks://{dbutils.secrets.get('u_tibor.stanko', 'anadbfinactd01')}"
)

# Configure new (UC) registry
mlflow.set_registry_uri("databricks-uc")
new_client = MlflowClient()

# COMMAND ----------

def copy_model(old_name: str, new_name: str) -> None:
    """Copy a model from old workspace registry to UC registry."""
    versions = old_client.search_model_versions(f"name='{old_name}'")
    for v in versions:
        run_id = v.run_id
        artifact_uri = v.source
        print(f"Copying {old_name} v{v.version} → {new_name}")
        mlflow.register_model(artifact_uri, new_name)

# COMMAND ----------

# Define models to copy
MODELS_TO_COPY = {
    # "old_name": "models.cognitive_reserving.new_name"
    # TODO: fill in
}

for old, new in MODELS_TO_COPY.items():
    copy_model(old, new)
```

---

### Phase 7: Validation Notebooks

Create `notebooks/validation/` notebooks for comparing old vs new outputs.

#### Template: `validate_{notebook_name}.py`

```python
# Databricks notebook source

# COMMAND ----------

from src.project import set_project
import pybrickz as pb

config = set_project(parametrize_by_coverage=False)
eval_time = config.job_params.eval_time

# COMMAND ----------
# Load old output from legacy ADLS
OLD_PATH = f"abfss://finact@storadlsfinact02.dfs.core.windows.net/anadbfinactd01/dev/finact/finact_cogres_sandbox/v1/{LOB}/Scoring/{eval_time}/{TABLE_NAME}_{eval_time}.parquet"
df_old = spark.read.parquet(OLD_PATH)

# Load new output from UC
df_new = pb.read("{table_key}").filter(f"proc_yq = {eval_time}")

# COMMAND ----------
# Compare using zmatch
import zmatch

dataset = zmatch.JoinedDataset(
    left=df_old,
    right=df_new,
    keys=["unique_id", "devqtr"],  # TODO: adjust key columns
    name_left="old_workspace",
    name_right="new_workspace",
)
zmatch.compare(dataset)
```

---

### Phase 8: Post-Migration Checklist

After completing all phases, verify:

**Project Structure**
- [ ] `config/config.yaml` with correct catalog and schema
- [ ] `config/io/io.yaml` with all tables, SQL connections, and models declared
- [ ] `config/job_params/job_params.yaml` with correct coverages for this LOB
- [ ] `config/bundle/bundle.yaml` with correct repo path and library versions
- [ ] `src/project.py` with correct coverage list for `parametrize_by_coverage=True`
- [ ] All notebooks converted from `.ipynb` to Databricks `.py` format
- [ ] All shared module imports replaced with `from src.module import ...`
- [ ] No pandas imports anywhere (except in comments/dead code to remove)
- [ ] Every notebook has a `FLOW` dict + `pb.flow.show(FLOW)` call
- [ ] `requirements.txt` present with `pybrickz>=3.0`

**Notebooks**
- [ ] `set_project(parametrize_by_coverage=False)` in non-coverage notebooks
- [ ] `set_project(parametrize_by_coverage=True)` in coverage-parameterized notebooks
- [ ] All `dbutils.widgets.get()` calls replaced with `config.job_params.*`
- [ ] All `pb.read_dataset(...)` replaced with `pb.read("key")`
- [ ] All `pb.write_dataset(...)` replaced with `write_partition(df, "key", config)`
- [ ] No path construction variables (`dir_data = f"LOB/Data/{eval_time}"`)
- [ ] No hardcoded catalog/schema paths

**Bundle & Deployment**
- [ ] `databricks.yml` validates with `databricks bundle validate`
- [ ] All job tasks use `job_cluster_key`, not `existing_cluster_id`
- [ ] No absolute notebook paths in job YAMLs
- [ ] `azure-pipelines.yaml` references correct variable groups
- [ ] `deployment/create_bundle.py` present

**Unity Catalog**
- [ ] Catalog `finact_cognit_dev` accessible from new workspace
- [ ] Schema `{lob}_{gen}_{scope}` exists (or will be created by pybrickz on first run)
- [ ] All `uc_table` URIs in io.yaml are valid
- [ ] All models registered under `models.cognitive_reserving.*`

**Data Migration**
- [ ] Historical parquet data loaded into UC Delta tables (if historical data needed)
- [ ] Models copied from old workspace to UC registry
- [ ] Validation notebooks created and ready to run

**Known Manual Steps**
- SQL connections must be registered in new workspace (Yellowbrick, EDW)
- Service principal credentials must be set up for ADLS access
- Azure Pipelines variable groups must be configured
- Schema ownership should be transferred to `zna_db_user_finact_cognit` in prod

---

## 6. Best Practices Enforcement

Apply these to every file you create or modify:

1. **No pandas**: Every notebook must be pandas-free. Use PySpark or Polars.
2. **FLOW docs**: Every processing notebook must document its lineage with a `FLOW` dict.
3. **Partitioned tables**: All tables with historical data use `proc_yq` partitioning.
4. **Config, not code**: No hardcoded catalog names, workspace URLs, or eval parameters in notebooks.
5. **src/ modules**: All reusable logic lives in `src/`, not duplicated across notebooks.
6. **UC model registry**: No JSON model files on ADLS. All models in `models.cognitive_reserving.*`.
7. **DABs bundles**: No manual workspace job creation. Everything deployable via `databricks bundle deploy`.
8. **mlflow-skinny**: Use `mlflow-skinny`, not full `mlflow` (lighter weight, same registry API).
9. **SINGLE_USER mode**: All cluster configurations must use `data_security_mode: SINGLE_USER`.
10. **No `existing_cluster_id`**: Job YAMLs must define job clusters, not reference all-purpose clusters.
11. **Databricks .py format**: Notebooks use `# COMMAND ----------` cell separators, not `.ipynb` JSON.
12. **Type hints**: All `src/` module functions should have type annotations.
13. **`write_partition()` helper**: Always use this for proc_yq-partitioned writes, never raw `pb.write()`.
14. **Coverage list in src/project.py**: The `coverages` list in `set_project()` must match the LOB.

---

## 7. Quick Reference: Standard Table Numbering

Following the GL reference pattern, project tables are numbered by pipeline stage:

| Range | Stage | Example |
|-------|-------|---------|
| 00_ | Raw extracts / primary inputs | `00_clm_mart`, `00_dice_zaltpull` |
| 01-04_ | Data prep, cleaning, triangles | `01_clm_step0`, `04_clm_detail` |
| 05-07_ | Feature engineering, triangles | `05_tri_step1`, `07_tri_step3` |
| 08-09_ | Text processing, scoring inputs | `08_notes_clean`, `09_{cov}_to_score` |
| 01_ | Imputed (per coverage) | `01_{cov}_imputed` |
| 02-06_ | Scored outputs (per coverage) | `02_{cov}_ibner_scored`, `06_{cov}_pure_scored` |
| 07-09_ | Aggregations | `07_all_pure_scored`, `09_pol_level_expo` |
| 10-11, 99_ | Final summaries | `10_pol_level_summary_v1`, `99_pol_level_summary` |
| 20-26_ | AlertZ | `20_{cov}_alertz`, `26_expected_square` |
| 30-32_ | RVT | `30_{cov}_expected_agg`, `32_summary` |

---

## 8. Decision Guide: When to Do What

**Should the notebook use `parametrize_by_coverage=True`?**
→ Yes, if and only if the notebook produces separate outputs per coverage (e.g., `09_gl_comp_data_to_score`).

**Should a table be partitioned by `proc_yq`?**
→ Yes, if the pipeline runs multiple times per year and history must be preserved.
→ No (use `mode: overwrite`), if the table is always fully recomputed (lookup tables, reference tables).

**Should a module go in `src/` or stay inline in a notebook?**
→ `src/` if it's shared across 2+ notebooks, > 50 lines, or contains complex logic.
→ Inline if it's truly notebook-specific and small.

**Should I copy the model from old workspace or re-register?**
→ Copy if the model was trained in the old workspace and you need its exact weights.
→ Re-register if the model can be re-trained or if the old version is outdated.

**How do I handle a v2 `current_dir=` parameter?**
→ Reconstruct the full logical path: `current_dir + "/" + filename`.
→ Map that to an io.yaml entry.

**What about `pyspark.pandas` (deprecated)?**
→ Remove it. Replace with native PySpark or Polars.
