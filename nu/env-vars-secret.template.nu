# --- pybrickz ---
$env.DNA_METASTORE_PASSWORD = 'REDACTED'

# --- azure devops ---
$env.AZURE_DEV_OPS_TOKEN_TIBORSTANKO = 'REDACTED'
$env.AZURE_DEV_OPS_TOKEN_ZNA_PREDICTIVE_ANALYTICS = 'REDACTED'
$env.AZURE_ARTIFACTS_TOKEN = 'REDACTED'
$env.AZURE_DEV_OPS_TOKEN = $env.AZURE_DEV_OPS_TOKEN_ZNA_PREDICTIVE_ANALYTICS

# --- zurich llm lounge ---
$env.ZURICHAT_CLIENT_ID = "REDACTED"
$env.ZURICHAT_CLIENT_SECRET = "REDACTED"

# --- claude code (using zurich llms) ---
# $env.ANTHROPIC_BEDROCK_BASE_URL = 'REDACTED'
$env.ANTHROPIC_BASE_URL = 'REDACTED'
$env.ANTHROPIC_AUTH_TOKEN = 'REDACTED'
$env.ANTHROPIC_MODEL = 'global.anthropic.claude-sonnet-4-5-20250929-v1:0'
$env.ANTHROPIC_DEFAULT_OPUS_MODEL = 'global.anthropic.claude-opus-4-5-20251101-v1:0'
$env.ANTHROPIC_DEFAULT_SONNET_MODEL = 'global.anthropic.claude-sonnet-4-5-20250929-v1:0'
$env.ANTHROPIC_DEFAULT_HAIKU_MODEL = 'global.anthropic.claude-haiku-4-5-20251001-v1:0'

# --- github (zna) ---
$env.GITHUB_TOKEN = 'REDACTED'
