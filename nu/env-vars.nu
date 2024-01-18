#### pip
# This *does not* work
# $env.PIP_CONFIG_FILE = '~/Projects/config/pip/pip.ini'
# This *does* work
$env.PIP_CONFIG_FILE = 'C:\\Users\\tibor.stanko\\Projects\\config\\pip\\pip.ini'

#### pybrickz
$env.DNA_METASTORE_DEV_MODE = 'TRUE'
$env.DNA_METASTORE_USE_QA_DATABASE = 'FALSE'
$env.DBX_ENV = 'dev'

#### starship
# This *does not* work
# $env.STARSHIP_CONFIG = '~\Projects\config\starship\starship.toml'
# This *does* work
$env.STARSHIP_CONFIG = 'C:\\Users\\tibor.stanko\\Projects\\config\\starship\\starship.toml'
