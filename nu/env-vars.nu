let os_name = ($nu.os-info | get name);
match $os_name {
    "windows" => {
        $env.PIP_CONFIG_FILE = 'C:\\Users\\tibor.stanko\\Projects\\config\\pip\\pip.ini'
        $env.STARSHIP_CONFIG = 'C:\\Users\\tibor.stanko\\Projects\\config\\starship\\starship.toml'
        # $env.SSL_CERT_FILE = 'C:\\Users\\tibor.stanko\\Projects\\config\\certificates\\zurich-cert.pem'
        # $env.REQUESTS_CA_BUNDLE = 'C:\\Users\\tibor.stanko\\Projects\\config\\certificates\\zurich-cert.pem'
        $env.SSL_CERT_FILE = "C:\\Users\\TIBOR.STANKO\\scoop\\apps\\git\\current\\mingw64\\etc\\ssl\\certs\\ca-bundle.crt"
        $env.REQUESTS_CA_BUNDLE = "C:\\Users\\TIBOR.STANKO\\scoop\\apps\\git\\current\\mingw64\\etc\\ssl\\certs\\ca-bundle.crt"
    },
    "macos" => {
        $env.USERNAME = (whoami)
        $env.PIP_CONFIG_FILE = $env.HOME + "/Projects/config/pip/pip.toml"  
        $env.STARSHIP_CONFIG = $env.HOME + "/Projects/config/starship/starship.toml"
        $env.SSL_CERT_FILE = $env.HOME + "/Projects/config/certificates/certs.pem"  
        $env.REQUESTS_CA_BUNDLE = $env.HOME + "/Projects/config/certificates/certs.pem"
    },
    "linux" => {
        $env.USERNAME = (whoami)
        $env.PIP_CONFIG_FILE = "~/Projects/config/pip/pip.toml"  
        $env.STARSHIP_CONFIG = "~/Projects/config/starship/starship.toml"
        $env.SSL_CERT_FILE = "~/Projects/config/certificates/certs.pem"  
        $env.REQUESTS_CA_BUNDLE = "~/Projects/config/certificates/certs.pem"
    },
    _ => {
        print $"Running on an unknown OS: ($os_name)"
    }
}

# --- my technical account ---
$env.ADM_USERNAME = 'adm-TISTANKO'

# --- pybrickz ---
$env.DNA_METASTORE_DEV_MODE = 'TRUE'
$env.DNA_METASTORE_USE_QA_DATABASE = 'FALSE'
$env.DBX_ENV = 'dev'
$env.KEY_VAULT = 'dnacommonkeyvault01n1d02'

# --- uv ---
$env.UV_INDEX_DNA_PACKAGES_USERNAME = 'VssSessionToken'
$env.UV_KEYRING_PROVIDER = "subprocess"

# --- azure cli ---
$env.ADAL_PYTHON_SSL_NO_VERIFY = 1
$env.AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = 1

# --- claude code ---
# $env.CLAUDE_CODE_USE_BEDROCK = '1'
# $env.CLAUDE_CODE_SKIP_BEDROCK_AUTH = '1'
