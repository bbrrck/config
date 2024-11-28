#### pip
# This *does not* work
# $env.PIP_CONFIG_FILE = '~/Projects/config/pip/pip.ini'
# This *does* work
$env.PIP_CONFIG_FILE = 'C:\\Users\\tibor.stanko\\Projects\\config\\pip\\pip.ini'

#### pybrickz
$env.DNA_METASTORE_DEV_MODE = 'TRUE'
$env.DNA_METASTORE_USE_QA_DATABASE = 'FALSE'
$env.DBX_ENV = 'dev'
$env.KEY_VAULT = 'dnacommonkeyvault01n1d02'

#### starship
# This *does not* work
# $env.STARSHIP_CONFIG = '~\Projects\config\starship\starship.toml'
# This *does* work
$env.STARSHIP_CONFIG = 'C:\\Users\\tibor.stanko\\Projects\\config\\starship\\starship.toml'

#### zurich certificates
$env.SSL_CERT_FILE = 'C:\\Users\\tibor.stanko\\Projects\\config\\certificates\\zurich-cert.pem'

#### custom azure artifact feeds
# $env.UV_EXTRA_INDEX_URL = $'https://($env.AZURE_ARTIFACTS_TOKEN)@pkgs.dev.azure.com/zna-predictive-analytics/dna-packages/_packaging/dna-packages/pypi/upload/'
