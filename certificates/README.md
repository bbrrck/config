
# How to get Zurich certificates

## Windows

0. Install openssl: `scoop install openssl`.
1. Create a certificate file, name it `zurich-cert.pem`.
2. Run `openssl s_client -connect azure.com:443 -showcerts`.
3. Copy each certificate from the output into `zurich-cert.pem`. You only need the sections that start with `-----BEGIN CERTIFICATE-----` and end with `-----END CERTIFICATE-----`. You can also save the certificates to a file using `openssl s_client -connect google.com:443 -showcerts | save zurich-cert.pem`, just make sure to delete the parts that are not needed.
4. Set the environment variable `SSL_CERT_FILE` to be the absolute path of `zurich-cert.pem`. Example for nushell: `$env.SSL_CERT_FILE = 'C:\\Users\\TIBOR.STANKO\\Projects\\config\\certificates\\zurich-cert.pem'`.

## MacOS

```shell
security export -t certs -f pemseq -k /System/Library/Keychains/SystemRootCertificates.keychain -o "$HOME/Projects/config/certificates/bundleCA.pem"  
security export -t certs -f pemseq -k /Library/Keychains/System.keychain -o "$HOME/Projects/config/certificates/selfSignedCAbundle.pem"
cat "$HOME/Projects/config/certificates//bundleCA.pem" "$HOME/Projects/config/certificates/selfSignedCAbundle.pem" >> "$HOME/Projects/config/certificates/certs.pem"
export SSL_CERT_FILE="$HOME/Projects/config/certificates/certs.pem"  
export REQUESTS_CA_BUNDLE="$HOME/Projects/config/certificates/certs.pem"
```
