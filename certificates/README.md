
# How to get Zurich certificates

## Windows

0. Install openssl: `scoop install openssl`.
1. Create a certificate file, name it `zurich-cert.pem`.
2. Run `openssl s_client -connect azure.com:443 -showcerts`.
3. Copy each certificate from the output into `zurich-cert.pem`. You only need the sections that start with `-----BEGIN CERTIFICATE-----` and end with `-----END CERTIFICATE-----`. You can also save the certificates to a file using `openssl s_client -connect google.com:443 -showcerts | save zurich-cert.pem`, just make sure to delete the parts that are not needed.
4. Set the environment variable `SSL_CERT_FILE` to be the absolute path of `zurich-cert.pem`. Example for nushell: `$env.SSL_CERT_FILE = 'C:\\Users\\TIBOR.STANKO\\Projects\\config\\certificates\\zurich-cert.pem'`.

## MacOS

```shell
$env.CERT_DIR = $"($env.HOME)/Projects/config/certificates"
$env.CERT_ROOT = $"($env.CERT_DIR)/bundleCA.pem"
$env.CERT_SELF = $"($env.CERT_DIR)/selfSignedCAbundle.pem"
$env.CERT_BOTH = $"($env.CERT_DIR)/certs.pem"
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain | save $"(env.CERT_ROOT)"
security find-certificate -a -p /Library/Keychains/System.keychain -o $env.CERT_SELF
cat $CERT_ROOT $CERT_SELF >> $CERT_BOTH
export SSL_CERT_FILE=$CERT_BOTH
export REQUESTS_CA_BUNDLE=$CERT_BOTH
```
