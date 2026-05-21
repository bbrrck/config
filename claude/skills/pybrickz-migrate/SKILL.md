---
name: pybrickz-migrate
description: Migrate Python code from pybrickz v2 to v3. Use when a user asks to migrate, upgrade, or convert pybrickz v2 notebooks or scripts.
version: 1.1.0
author: Claude Code
tags: [pybrickz, databricks, migration, azure, zurich]
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

# pybrickz v2 → v3 Migration Skill

You are helping a data engineer migrate pybrickz v2 notebooks and scripts to v3. Follow the 5-phase workflow below. Read each phase before proceeding.

---

## Architecture: v2 vs v3

| Aspect | v2 | v3 |
|--------|----|----|
| Project init | `pb.set_project("name", "version")` | `config = pb.set_project()` + YAML config files |
| Storage | SQL Server metastore + ADLS file paths | Unity Catalog tables + volumes |
| Config | Hardcoded strings in code | `config/config.yaml` + `config/io/io.yaml` (Hydra) |
| I/O | Path-based: `pb.read_dataset("dir/file.parquet")` | Key-based: `pb.read("key")` |
| Write mode | `replace_if_exists=True` param | `mode: overwrite` in io.yaml |
| Logging | `pb.utils.get_logger()` | `from pybrickz.core.logging import logger` (module-level) |

---

## Complete API Mapping

| v2 call | v3 equivalent |
|---------|---------------|
| `pb.set_project("name", "v1")` | `config = pb.set_project()` + create config files |
| `pb.read_dataset("dir/file.parquet")` | `pb.read("key")` |
| `pb.read_dataset("file.parquet", current_dir=some_dir)` | `pb.read("key")` — reconstruct full path, map to io.yaml entry |
| `pb.write_dataset(df, "file.parquet", replace_if_exists=True)` | `pb.write(df, "key")` with `mode: overwrite` in io.yaml |
| `pb.write_dataset(df, "file.parquet", current_dir=some_dir, replace_if_exists=True)` | `pb.write(df, "key")` — reconstruct path, map to io.yaml entry |
| `pb.read_pandas("file.parquet")` | `pb.to_pandas(pb.read("key"))` |
| `pb.read_pandas("file.xlsx")` | **See CSV/Excel edge case below** |
| `pb.read_spark("file.parquet")` | `pb.read("key")` (Spark is the default return type) |
| `pb.read_polars("file.parquet")` | `pb.to_polars(pb.read("key"))` |
| `pb.sql_connection("MSSQL-PC-REP-Prod")` | `pb.sql_connection("key")` where key is defined in io.yaml |
| `pb.read_from_prod_lake("database", "table", snapshot="active")` | `pb.read("key")` with `type: prod_lake` in io.yaml |
| `pb.read_from_dataiku("PROJECT_KEY", "dataset_key")` | `pb.read("key")` with `type: dataiku` in io.yaml |
| `pb.utils.get_logger()` | `from pybrickz.core.logging import logger` (top of file) |
| `replace_if_exists=True` parameter | `mode: overwrite` in io.yaml |
| `.parquet` / `.csv` / `.delta` file extensions in paths | Removed — format inferred from `format:` field in io.yaml |
| `current_dir=` parameter | Removed — reconstruct the logical path, map to correct io.yaml entry |
| `pb.info()` | `pb.info()` (unchanged, but now prints from config) |
| `pb.success("msg")` | `pb.success("msg")` (unchanged) |

**Unchanged:** `pb.to_spark()`, `pb.to_pandas()`, `pb.to_polars()`, `pb.glimpse()`, `pb.clean_column_names()`, SQL connector object interface (`.sql()`, `.execute()`, etc.)

**Removed (no v3 equivalent):** `pybrickz.metastore`, `pybrickz.notebook`, `pybrickz.project` (old), `pybrickz.sql` (old), `pybrickz.admin`

**New in v3:** `pb.list_tables()`, `pb.show_tables()`, `pb.create_volume()`, `pb.create_bundle()`, `pb.connect()`, time travel (`version_as_of=`, `timestamp_as_of=` kwargs to `pb.read()`), CDF (`read_change_data=True` kwarg), `lazy=True` for Polars reads, volume-based logging

---

## v3 Config File Templates

### `config/config.yaml`

```yaml
# Main project configuration
project:
  catalog: my_catalog        # TODO: Unity Catalog catalog name (e.g. finact_cognit_dev)
  schema: my_schema          # TODO: Unity Catalog schema name (e.g. wc_scoring)
  name: my_project           # Optional — defaults to schema name if omitted
  logs_volume_name: logs     # Volume used for log files

defaults:
  - io: io                   # Points to config/io/io.yaml

session: {}
```

### `config/io/io.yaml`

One entry per unique data source or sink. Assign short, descriptive snake_case keys.

```yaml
# --- PROD LAKE (read-only) ---
clm_nbr:
  type: prod_lake
  database: access           # Prod Lake database name
  table: tncc011_clm_nbr     # Prod Lake table name
  snapshot: latest           # "latest", "active", "all", or a specific date string

# --- PROJECT TABLE (read + write) ---
# type: project_table — SIMPLE (replaces whole table on each run)
# Note: mode: overwrite REPLACES THE ENTIRE TABLE every write.
output_data:
  type: project_table
  name: output_data          # Table name in project's catalog.schema
  format: delta              # Default and recommended
  mode: overwrite            # "overwrite" replaces the whole table; use append+partition_by to keep history
  optimize: true             # Optional: run OPTIMIZE after write

# type: project_table — PARTITIONED (accumulates history across runs)
# Use this when: each pipeline run produces a separate slice of data
# that must be kept alongside previous runs.
# Note: mode: append + replace_where (via write_partition helper) replaces ONLY the current partition.
quarterly_output:
  type: project_table
  name: quarterly_output
  format: delta
  mode: append                            # Required for partitioned tables
  optimize: true
  partition_by: [eval_year, eval_quarter] # Partition columns — one row per combo

# --- UC TABLE (read-only: table in another project's schema) ---
reference_table:
  type: uc_table
  uri: catalog.schema.table  # TODO: full 3-part Unity Catalog path

# --- SQL CONNECTION ---
policy_center:
  type: sql
  name: MSSQL-PC-REP-Prod    # Registered SQL connection name (unchanged from v2)
  tables: [claims, policies] # Optional: tables to preload

# --- DATAIKU TABLE (read-only) ---
dataiku_source:
  type: dataiku
  project_key: MY_PROJECT    # Dataiku project key (uppercase)
  dataset_key: my_dataset    # Dataiku dataset key
  env: cloud01               # Dataiku environment

# --- PROJECT VOLUME (for unstructured files) ---
document_images:
  type: project_volume
  name: document_images

# --- PROJECT VOLUME FILE ---
config_file:
  type: project_volume_file
  volume: document_images
  file_path: 2024/config.json

# --- UC VOLUME (read-only: volume in another project's schema) ---
shared_volume:
  type: uc_volume
  uri: catalog.schema.volume_name
```

---

## Before / After Code Examples

### Basic read + write

**v2:**
```python
import pybrickz as pb
pb.set_project("wc_scoring", "v1")

dir_data = f"WC/Data/{eval_time}"
file_claims = f"{dir_data}/00_clm_mart_detail_{eval_time}"

df = pb.read_dataset(f"{file_claims}.parquet")
# ... processing ...
pb.write_dataset(df, f"{file_claims}_clean.parquet", replace_if_exists=True)
```

**v3:**
```python
import pybrickz as pb
config = pb.set_project()

df = pb.read("clm_mart_detail")
# ... processing ...
pb.write(df, "clm_mart_detail_clean")
```

**io.yaml entries:**
```yaml
clm_mart_detail:
  type: uc_table                             # TODO: confirm source type
  uri: catalog.schema.00_clm_mart_detail    # TODO: confirm URI

clm_mart_detail_clean:
  type: project_table
  name: 00_clm_mart_detail_clean
  format: delta
  mode: overwrite
```

---

### Partitioned tables (history accumulation)

**v2 — directory-per-run pattern:**
```python
dir_data = f"WC/Data/{eval_time}"
file_output = f"{dir_data}/scored_output"
pb.write_dataset(df, f"{file_output}.parquet", replace_if_exists=True)

# Reading a specific run:
df = pb.read_dataset(f"WC/Data/{eval_time}/scored_output.parquet")
```

**v3 — single Delta table with partition:**
```python
# Write — adds partition values as columns, then replaces only this run's partition
write_partition(
    df=df,
    name="scored_output",
    partitions={"eval_time": str(eval_time)},
)

# Read — full table returned; filter down to the run you want
df = pb.read("scored_output").filter(f"eval_time = '{eval_time}'")
```

**io.yaml entry:**
```yaml
scored_output:
  type: project_table
  name: scored_output
  format: delta
  mode: append
  optimize: true
  partition_by: [eval_time]
```

**`write_partition()` helper** (lives in `src/project.py` — copy into your own project):
- Adds partition columns as literal values to the dataframe before writing
- Calls `pybrickz.write(df, name, replace_where="eval_time='202401'", mode="overwrite")` under the hood — replaces **only the current partition**, not the whole table
- Validates that the dict keys match the `partition_by` list in io.yaml; raises `ValueError` if they don't match
- This is a **project utility, not a pybrickz built-in** — users must copy it into their own `src/` or utils module

---

### Pandas / Polars conversion

**v2:**
```python
df_pd = pb.read_pandas(f"{file_path}.parquet")
df_pl = pb.read_polars(f"{file_path}.parquet")
```

**v3:**
```python
df_pd = pb.to_pandas(pb.read("my_table"))
df_pl = pb.to_polars(pb.read("my_table"))
# Or read lazily:
df_lazy = pb.to_polars(pb.read("my_table", lazy=True))
```

---

### SQL connection

**v2:**
```python
conn = pb.sql_connection("MSSQL-PC-REP-Prod")
df = conn.sql("SELECT * FROM claims WHERE year = 2024")
```

**v3:**
```python
conn = pb.sql_connection("policy_center")
df = conn.sql("SELECT * FROM claims WHERE year = 2024")
```

**io.yaml:**
```yaml
policy_center:
  type: sql
  name: MSSQL-PC-REP-Prod
```

---

### Prod Lake read

**v2:**
```python
df = pb.read_from_prod_lake("access", "tncc011_clm_nbr", snapshot="active")
```

**v3:**
```python
df = pb.read("clm_nbr")
```

**io.yaml:**
```yaml
clm_nbr:
  type: prod_lake
  database: access
  table: tncc011_clm_nbr
  snapshot: active
```

---

### Dataiku read

**v2:**
```python
df = pb.read_from_dataiku("LITIGATIONREPORTING", "final")
```

**v3:**
```python
df = pb.read("litigation_final")
```

**io.yaml:**
```yaml
litigation_final:
  type: dataiku
  project_key: LITIGATIONREPORTING
  dataset_key: final
  env: cloud01
```

---

### Logging

**v2:**
```python
logger = pb.utils.get_logger()
logger.info("Starting processing")
```

**v3:**
```python
# At the top of the file, module-level import:
from pybrickz.core.logging import logger

# Use anywhere:
logger.info("Starting processing")
```

---

## Edge Cases

### CSV / Excel reads (no direct v3 io.yaml equivalent)
`pb.read_pandas("file.xlsx")` and `pb.read_spark("file.csv")` read raw files from ADLS.

Options:
1. **Upload to a volume first**, then use `type: project_volume_file` or `type: uc_volume_file` in io.yaml and read with standard Spark/Polars from the volume path
2. **Register as a UC table** if the data is stable, then use `type: uc_table`
3. **Use native Spark/Polars read** directly from the volume path — this is acceptable if the file is a one-time static input

> **Flag as manual step** — ask the engineer where the file lives in the new UC environment.

### Dynamic snapshots (`snapshot` is a variable)
In v2, snapshot is often a runtime variable (e.g., `snapshot=eval_time`). In v3, `snapshot` is static in io.yaml.

Options:
1. Pass it as a runtime override: `pb.read("my_key", snapshot=eval_time)` — kwargs are forwarded to the underlying reader
2. Parameterize io.yaml with Hydra variables: `snapshot: ${params.eval_time}`

> **Flag as manual step** if the approach is not clear from context.

### Conditional `replace_if_exists`
Some v2 code conditionally sets `replace_if_exists`. In v3, `mode` is static in io.yaml.

> **Flag as manual step** — engineer must decide if `mode: overwrite` is always appropriate or if logic needs to be restructured.

### `current_dir=` parameter
v2's `current_dir=` modifies where a relative path is rooted within the project ADLS directory. To migrate:
1. Reconstruct the full logical path: `current_dir + "/" + filename` (without extension)
2. Map that path to the appropriate io.yaml type and entry
3. The v3 key becomes the logical name for that dataset

### Multiple format reads from the same logical table
If v2 reads the same dataset in different formats (Spark, Pandas, Polars), create one io.yaml key and use conversion utils (`pb.to_pandas()`, `pb.to_polars()`, `pb.to_spark()`).

### Logging is module-level in v3
Do NOT assign `logger` as a local variable inside functions or notebook cells. Import it at the top of the file, outside any function or class.

### Directory-per-run v2 pattern (partitioned data)
In v2, pipelines that need to keep history across runs (quarterly scoring, monthly pulls, etc.) often write to a different directory for each run:

```python
dir_data = f"WC/Data/{eval_time}"         # time variable used as directory segment
pb.write_dataset(df, f"{dir_data}/scored_output.parquet", replace_if_exists=True)
```

**How to detect:** look for f-string paths that embed a date/time/run-identifier variable as a directory segment (e.g., `f"WC/Data/{eval_time}/..."`, `f"Output/{year}/{quarter}/..."`).

**Migration rule:** one logical output type = one Delta table; partition by the run-identifier column(s) that v2 used as directory segments.

**Steps:**
1. Identify the run-identifier variable (e.g., `eval_time`, `year`, `quarter`)
2. Create a single `project_table` io.yaml entry with `mode: append` and `partition_by: [eval_time]`
3. Replace the write with `write_partition(df=df, name="key", partitions={"eval_time": str(eval_time)})`
4. Replace the read with `pb.read("key").filter(f"eval_time = '{eval_time}'")`
5. Remove the path construction variables (`dir_data = f"WC/Data/{eval_time}"`) — no longer needed

> **Reminder:** `write_partition()` is a project utility in `src/project.py`, not a pybrickz built-in. Copy it into the target project's `src/` module.

---

## Databricks Asset Bundles (DAB) Reference

### `databricks.yml` Full Template

```yaml
bundle:
  name: my_project  # TODO: snake_case of repo name (e.g. wc_scoring_pipeline)

variables:
  repo_path:
    description: Absolute workspace path to the repo root
    default: /Workspace/Repos/YOUR_EMAIL/YOUR_REPO  # TODO: update

targets:
  dev:
    mode: development
    default: true
    workspace:
      host: https://YOUR_WORKSPACE.azuredatabricks.net  # TODO: update

  prod:
    mode: production
    workspace:
      host: https://YOUR_WORKSPACE.azuredatabricks.net  # TODO: update

resources:
  jobs:
    my_job:  # TODO: snake_case job key (e.g. wc_scoring_job)
      name: "[${bundle.target}] My Job Name"  # TODO: replace with actual job name
      tags:
        team: YOUR_TEAM  # TODO: update
      job_clusters:
        - job_cluster_key: default_cluster
          new_cluster:
            spark_version: 14.3.x-scala2.12  # TODO: confirm version
            node_type_id: Standard_DS3_v2    # TODO: confirm node type
            num_workers: 2                   # TODO: confirm worker count
            spark_conf: {}
            azure_attributes: {}
      tasks:
        - task_key: main_task  # TODO: replace with descriptive key
          job_cluster_key: default_cluster
          notebook_task:
            notebook_path: ${var.repo_path}/notebooks/your_notebook  # TODO: update path
            base_parameters: {}
      schedule:
        quartz_cron_expression: "0 0 8 * * ?"  # TODO: confirm schedule
        timezone_id: Europe/Zurich
        pause_status: PAUSED  # Change to UNPAUSED in prod after validation
```

### Field Notes

- **`bundle.name`** — use snake_case of the repo name (e.g., `wc_scoring_pipeline`). This appears in workspace paths during `bundle deploy`.
- **`[${bundle.target}]` prefix** — prepend to every job name so dev and prod jobs are visually distinct in the Databricks UI. Without this, deploying to dev overwrites the prod job name.
- **Cluster key matching** — every task's `job_cluster_key` must exactly match a key in the `job_clusters` list at the same job level.
- **Relative notebook paths** — use `${var.repo_path}/notebooks/...` rather than absolute `/Workspace/Repos/...` paths so the bundle works across users and environments.

### Task Type Mapping Table

| UI Task Type | DAB YAML field |
|---|---|
| Notebook | `notebook_task.notebook_path` |
| Python script | `spark_python_task.python_file` |
| Python wheel | `python_wheel_task.package_name` + `entry_point` |
| SQL | `sql_task.query.query_id` (or `warehouse_id` + inline SQL) |
| Delta Live Tables pipeline | `pipeline_task.pipeline_id` |

### DAB JSON → YAML Transformation Rules (Fallback Path)

Use this section when `databricks bundle generate` is unavailable (CLI < 0.205.0).

#### Field Mapping

| JSON path (from `jobs get`) | DAB YAML path | Transformation notes |
|---|---|---|
| `settings.name` | `resources.jobs.<key>.name` | Wrap in `"[${bundle.target}] <name>"` |
| `settings.job_clusters` | `resources.jobs.<key>.job_clusters` | See cluster handling below |
| `settings.tasks` | `resources.jobs.<key>.tasks` | See per-task rules below |
| `settings.schedule` | `resources.jobs.<key>.schedule` | Copy directly; set `pause_status: PAUSED` |
| `settings.tags` | `resources.jobs.<key>.tags` | Copy directly |
| `settings.max_concurrent_runs` | `resources.jobs.<key>.max_concurrent_runs` | Copy directly |
| `settings.timeout_seconds` | `resources.jobs.<key>.timeout_seconds` | Copy directly |
| `settings.email_notifications` | `resources.jobs.<key>.email_notifications` | Copy directly |

#### Fields to DROP

Drop these fields — they cause `bundle validate` failures or are environment-specific:

- `job_id` — assigned by Databricks; must not be in bundle definition
- `creator_user_name` — not a valid DAB field
- `created_time` — not a valid DAB field
- `run_as` — managed by deployment identity; remove entirely
- `settings.format` — internal metadata; not a valid DAB field
- `cluster_id` inside `new_cluster` — cluster ID is assigned at runtime; remove from cluster spec

#### Per-Task Transformation Rules

- **Notebook path stripping**: remove the absolute workspace prefix, then replace with `${var.repo_path}/...`:
  - Strip `/Workspace/Repos/<email>/<repo>/` prefix
  - Strip legacy `/Repos/<email>/<repo>/` prefix
  - Result: `${var.repo_path}/notebooks/your_notebook`
- **`task_key`**: copy directly (already a string key)
- **`depends_on`**: copy directly
- **`job_cluster_key`**: normalize to match the key defined in `job_clusters`

**Examples:**
```
/Workspace/Repos/jane.doe@example.com/wc-scoring/notebooks/01_score
  → ${var.repo_path}/notebooks/01_score

/Repos/jane.doe@example.com/wc-scoring/notebooks/01_score
  → ${var.repo_path}/notebooks/01_score
```

#### Cluster Handling

| JSON cluster type | Action |
|---|---|
| `new_cluster` (job cluster) | Convert to `job_clusters` entry; drop `cluster_id` field |
| `existing_cluster_id` (all-purpose cluster) | **Flag as manual step** — all-purpose clusters are environment-specific and cannot be bundled directly; replace with a `job_cluster` definition |

---

## Migration Workflow (5 Phases)

### Phase 0 — Bundle Creation from Workspace Jobs

> **Skip this phase entirely if all jobs already have a bundle definition in the repo.** Only proceed if jobs exist only in the Databricks workspace UI.

---

#### Step 0.1 — Gather inputs

Ask the user for:
1. **Job IDs or names** — one or more Databricks job IDs (preferred) or display names visible in the workspace UI
2. **Bundle name** — suggest `snake_case` of the repo name (e.g., `wc_scoring_pipeline`)
3. **Workspace URL** — e.g., `https://adb-1234567890.12.azuredatabricks.net`

Do not proceed until all three are provided.

---

#### Step 0.2 — Check CLI version

```bash
databricks --version
```

- If version is **≥ 0.205.0**: use the **modern path** (Step 0.3a)
- If version is **< 0.205.0**: use the **fallback path** (Step 0.3b)

---

#### Step 0.3a — Modern path (CLI ≥ 0.205.0)

Run for each job ID:

```bash
databricks bundle generate job --existing-job-id <job_id>
```

Then apply corrections to the generated YAML:
1. Add `[${bundle.target}]` prefix to the job `name` field
2. Strip absolute notebook paths; replace with `${var.repo_path}/...`
3. Add `targets:` and `variables:` blocks from the full template above
4. Mark any unresolved paths with `# TODO: verify after notebook migration`

---

#### Step 0.3b — Fallback path (CLI < 0.205.0)

**Resolve names → IDs** (if names were provided instead of IDs):

```bash
databricks jobs list --output json
```

**Fetch each job definition:**

```bash
databricks jobs get --job-id <job_id> --output json
```

**Transform JSON → DAB YAML** using the transformation rules in the DAB Reference section above:
1. Apply the field mapping table
2. Drop all fields in the "Fields to DROP" list
3. Apply per-task transformation rules (path stripping, cluster key normalization)
4. Flag any `existing_cluster_id` references as manual steps
5. Wrap the job name in `"[${bundle.target}] <name>"`

**Construct `databricks.yml`** at project root using the full template structure, with one entry per job under `resources.jobs`.

---

#### Step 0.4 — Validate

**Modern path** (CLI ≥ 0.205.0):

```bash
databricks bundle validate
```

Fix any reported errors before proceeding.

**Fallback path** (CLI < 0.205.0): the `bundle` subcommand is unavailable — skip `databricks bundle validate`. Instead, manually review the generated `databricks.yml` against the full template structure to confirm:
- All required top-level keys are present (`bundle`, `variables`, `targets`, `resources`)
- No dropped fields remain (check the "Fields to DROP" list)
- All `job_cluster_key` references match a defined cluster key in the same job
- No absolute notebook paths remain (all should use `${var.repo_path}/...`)

---

#### Step 0.5 — Job inventory table

Produce a table mapping all captured jobs:

| Job key | Original job name | Job ID | Notebooks / scripts referenced | Migration status |
|---------|-------------------|--------|-------------------------------|-----------------|
| `wc_scoring_job` | WC Scoring - Monthly Run | 123456 | `notebooks/01_score`, `notebooks/02_output` | Pending Phase 1 |

---

#### Handoff to Phase 1

After completing Phase 0:
- Explicitly list all notebooks and scripts from the inventory table as the scope for Phases 1–5
- After Phase 5 (post-migration checklist), return to `databricks.yml` and resolve any `# TODO: verify after notebook migration` path comments with the final migrated notebook paths

---

### Phase 1 — Gather inputs

If the user has not provided v2 code, ask:
1. "Please share the v2 notebook(s) or Python script(s) to migrate."
2. "What is the target Unity Catalog **catalog name**?" (e.g., `finact_cognit_dev`, `secured_dev`)
3. "What is the target Unity Catalog **schema name**?" (e.g., `wc_scoring`, `my_project`)

Do not proceed to Phase 2 until you have all three.

---

### Phase 2 — Analyze

Scan the provided code and identify every v2 pattern. Present a summary table **before generating any output files**:

| # | v2 pattern found | Proposed io.yaml key | Proposed type | Notes |
|---|-----------------|----------------------|---------------|-------|
| 1 | `pb.set_project("wc_scoring", "v1")` | — | — | Replace with `config = pb.set_project()` |
| 2 | `pb.read_dataset(f"{file_claims}.parquet")` | `clm_mart_detail` | `project_table` or `uc_table` | TODO: confirm source |
| ... | ... | ... | ... | ... |

**Detection rule — directory-per-run (partitioned) pattern:**
Look for f-string paths where a date/time/run-identifier variable appears as a directory segment, e.g.:
- `f"WC/Data/{eval_time}/scored_output.parquet"` → partitioned by `eval_time`
- `f"Output/{year}/{quarter}/results.parquet"` → partitioned by `year`, `quarter`

Flag these in the analysis table with type `project_table (partitioned)` and list the partition columns in the Notes column.

Ask for confirmation: "Does this analysis look correct before I generate the config files?"

---

### Phase 3 — Generate `config/io/io.yaml`

Create one io.yaml entry per unique logical source/sink identified in Phase 2.

Rules:
- Keys must be snake_case, descriptive, and unique
- Mark unknowns with `# TODO: confirm` inline comments
- Do not include file extensions in names or URIs
- For `project_table` writes that replaced `replace_if_exists=True`, always set `mode: overwrite`
- For prod lake tables, include `database:`, `table:`, and `snapshot:` fields
- For SQL connections, use the exact connection name string from v2

Also generate `config/config.yaml` using the catalog/schema from Phase 1.

---

### Phase 4 — Generate migrated code

Rewrite the full notebook/script with all v2 calls replaced by v3 equivalents.

Rules:
- Remove `pb.set_project(...)` two-arg call; replace with `config = pb.set_project()`
- Replace every `pb.read_dataset(...)` with `pb.read("key")`
- Replace every `pb.write_dataset(...)` with `pb.write(df, "key")`
- Replace every `pb.read_pandas(...)` with `pb.to_pandas(pb.read("key"))`
- Replace every `pb.read_polars(...)` with `pb.to_polars(pb.read("key"))`
- Replace every `pb.read_spark(...)` with `pb.read("key")`
- Replace every `pb.sql_connection("raw_name")` with `pb.sql_connection("yaml_key")`
- Replace every `pb.read_from_prod_lake(...)` with `pb.read("key")`
- Replace every `pb.read_from_dataiku(...)` with `pb.read("key")`
- Move logger to module level: `from pybrickz.core.logging import logger`
- Remove all path construction variables (`dir_data = f"WC/Data/{eval_time}"`) if they were only used for I/O — keep them only if used in business logic
- **Preserve all business logic exactly** — do not rewrite algorithms, SQL queries, or data transformations
- Add a `# MIGRATED FROM v2` comment on the `config = pb.set_project()` line

---

### Phase 5 — Post-migration checklist

Always output this checklist after the migrated code, annotated with project-specific notes:

```
## Post-Migration Checklist

### Config
[ ] config/config.yaml created with correct catalog and schema
[ ] config/io/io.yaml created — review all # TODO: confirm entries
[ ] All io.yaml keys match the keys used in pb.read() / pb.write() calls

### Unity Catalog
[ ] Confirm catalog '{catalog}' exists and you have access
[ ] Confirm schema '{schema}' exists (or will be created)
[ ] For each uc_table entry: verify the 3-part URI is correct
[ ] For each prod_lake entry: verify snapshot value is still valid

### SQL Connections
[ ] For each sql entry: verify connection name is still registered in v3 environment
[ ] Test with pb.sql_connection("key") before running full pipeline

### Data Validation
[ ] Run pb.show_tables() after set_project() to verify schema is accessible
[ ] Compare row counts of first read between v2 and v3 outputs

### Partitioned Tables
[ ] For each v2 directory-per-run pattern found: create a partitioned `project_table` entry with `mode: append` and `partition_by: [run_identifier_column]`
[ ] Replace v2 writes with `write_partition(df=df, name="key", partitions={...})`
[ ] Replace v2 reads with `pb.read("key").filter(f"col = '{val}'")`
[ ] Copy `write_partition()` helper from `src/project.py` into the target project's `src/` module (it is NOT a pybrickz built-in)

### Manual Steps Required
<List any flagged edge cases from the analysis — dynamic snapshots, CSV reads,
conditional replace_if_exists, current_dir usage, directory-per-run patterns, etc.>

### Removed v2 modules (no action needed unless you used them directly)
[ ] pybrickz.metastore — removed
[ ] pybrickz.notebook — removed
[ ] pybrickz.project (old) — removed
[ ] pybrickz.sql (old) — removed
```

---

## Quick Reference: All io.yaml Types

| Type | Access | Required fields | Optional fields |
|------|--------|-----------------|-----------------|
| `prod_lake` | read | `database`, `table` | `snapshot`, `folder`, `relative_path`, `absolute_path` |
| `project_table` | read+write | `name` | `directory`, `format`, `mode`, `optimize`, `repartition`, `description`, `partition_by` |
| `project_volume` | read+write | `name` | — |
| `project_volume_file` | read+write | `volume`, `file_path` | — |
| `project_model` | read+write | `name` | `prod_version_alias`, `staging_version_alias` |
| `uc_table` | read | `uri` | — |
| `uc_volume` | read | `uri` | — |
| `uc_volume_file` | read | `volume_uri`, `file_path` | — |
| `uc_model` | read | `uri` | `prod_version_alias`, `staging_version_alias` |
| `sql` | connection | `name` | `tables` |
| `dataiku` | read | `project_key`, `dataset_key` | `env`, `partitions` |
| `azure_cosmos` | read+write | `endpoint`, `database`, `container` | `use_ssl`, `master_key` |
