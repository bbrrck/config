---
name: fix-az-cli-ssl
description: >
  Fix azure-cli SSL failures caused by corporate proxy missing Authority Key Identifier.
  Exports proxy cert chain via openssl, appends to certifi bundle, patches urllib3 to
  remove VERIFY_X509_STRICT. Must be reapplied after every `brew upgrade azure-cli`.
  Use when az CLI fails with "Missing Authority Key Identifier" or after upgrading azure-cli.
version: 1.0.0
author: Claude Code
tags: [azure-cli, ssl, proxy, corporate, fix]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
---

# Fix az CLI SSL (Corporate Proxy AKI Issue)

## Problem

`az` commands fail with:
```
SSLError: certificate verify failed: Missing Authority Key Identifier
```

## Root Cause

1. Corporate firewall performs SSL inspection, re-signing traffic with its own CA chain
2. The intermediate CA (`ssl.decrypt`) lacks the Authority Key Identifier (AKI) extension
3. `urllib3` (bundled with azure-cli) sets `VERIFY_X509_STRICT` on Python 3.13+, making AKI a hard failure
4. Patching `ssl.create_default_context()` alone doesn't help — urllib3 builds its own SSLContext

## Fix (Automated)

### Step 1 — Locate azure-cli installation

```bash
AZ_PREFIX=$(brew --prefix azure-cli)
AZ_VERSION=$(az version --query '"azure-cli"' -o tsv 2>/dev/null || basename "$AZ_PREFIX"/Cellar/azure-cli/*)
SITE_PACKAGES="$AZ_PREFIX/libexec/lib/python3.*/site-packages"
BUNDLE=$(ls $SITE_PACKAGES/certifi/cacert.pem)
URLLIB3_SSL=$(ls $SITE_PACKAGES/urllib3/util/ssl_.py)
```

Verify both paths exist before proceeding.

### Step 2 — Export proxy cert chain via openssl

Connect to an Azure endpoint through the corporate proxy and capture the full certificate chain:

```bash
openssl s_client -connect dev.azure.com:443 -showcerts </dev/null 2>/dev/null
```

Parse all certificates from the output. The proxy chain typically contains:
- Leaf cert (site cert re-signed by proxy) — skip this one
- Intermediate CA (`ssl.decrypt` or similar) — **keep**
- Root CA (`firewall_root` or similar) — **keep**

Extract non-leaf certs (2nd and beyond) and save them:

```bash
openssl s_client -connect dev.azure.com:443 -showcerts </dev/null 2>/dev/null \
  | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ print }' \
  | awk 'BEGIN{n=0} /BEGIN CERTIFICATE/{n++; file="/tmp/proxy_cert_"n".pem"} {print > file}'
```

This creates `/tmp/proxy_cert_1.pem` (leaf), `/tmp/proxy_cert_2.pem` (intermediate), `/tmp/proxy_cert_3.pem` (root).

Skip cert 1 (leaf). Append certs 2+ to the bundle:

```bash
for cert in /tmp/proxy_cert_2.pem /tmp/proxy_cert_3.pem; do
  if [ -f "$cert" ]; then
    SUBJECT=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null)
    echo "" >> "$BUNDLE"
    echo "# Corporate Proxy: $SUBJECT" >> "$BUNDLE"
    cat "$cert" >> "$BUNDLE"
  fi
done
```

### Step 3 — Set REQUESTS_CA_BUNDLE environment variable

Check if already set in shell config. If not, append:

```bash
# For zsh:
echo "export REQUESTS_CA_BUNDLE=\"$BUNDLE\"" >> ~/.zshrc
```

Only add if the line doesn't already exist (or update if it points to an old version path).

### Step 4 — Patch urllib3 to remove VERIFY_X509_STRICT

In the urllib3 ssl_.py file, find and remove the `VERIFY_X509_STRICT` line:

**Before:**
```python
if sys.version_info >= (3, 13):
    verify_flags |= VERIFY_X509_PARTIAL_CHAIN
    verify_flags |= VERIFY_X509_STRICT
```

**After:**
```python
if sys.version_info >= (3, 13):
    verify_flags |= VERIFY_X509_PARTIAL_CHAIN
```

This does NOT disable certificate verification. Hostname checks, expiry checks, and trust anchor checks all still run. It only falls back to name-based issuer matching instead of key-identifier matching.

### Step 5 — Verify the fix

```bash
az account show
```

If this succeeds without SSL errors, the fix is working.

## Complete Script

Run all steps as a single operation:

```bash
#!/bin/bash
set -euo pipefail

# 1. Locate paths
AZ_PREFIX=$(brew --prefix azure-cli)
SITE_PACKAGES=$(find "$AZ_PREFIX/libexec/lib" -maxdepth 1 -name "python3.*" | head -1)/site-packages
BUNDLE="$SITE_PACKAGES/certifi/cacert.pem"
URLLIB3_SSL="$SITE_PACKAGES/urllib3/util/ssl_.py"

if [ ! -f "$BUNDLE" ]; then echo "ERROR: certifi bundle not found at $BUNDLE"; exit 1; fi
if [ ! -f "$URLLIB3_SSL" ]; then echo "ERROR: urllib3 ssl_.py not found at $URLLIB3_SSL"; exit 1; fi

echo "Azure CLI prefix: $AZ_PREFIX"
echo "CA bundle: $BUNDLE"
echo "urllib3 ssl: $URLLIB3_SSL"

# 2. Export proxy certs
echo "Exporting proxy certificate chain..."
rm -f /tmp/proxy_cert_*.pem
openssl s_client -connect dev.azure.com:443 -showcerts </dev/null 2>/dev/null \
  | awk 'BEGIN{n=0} /BEGIN CERTIFICATE/{n++; file="/tmp/proxy_cert_"n".pem"} /BEGIN CERTIFICATE/,/END CERTIFICATE/{print > file}'

CERT_COUNT=$(ls /tmp/proxy_cert_*.pem 2>/dev/null | wc -l | tr -d ' ')
echo "Found $CERT_COUNT certificates in chain"

if [ "$CERT_COUNT" -lt 2 ]; then
  echo "ERROR: Expected at least 2 certs (leaf + CA). Got $CERT_COUNT. Not behind proxy?"
  exit 1
fi

# 3. Append non-leaf certs to bundle
echo "Appending proxy CA certs to bundle..."
for cert in $(ls /tmp/proxy_cert_*.pem | sort | tail -n +2); do
  SUBJECT=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//')
  # Check if already in bundle
  FINGERPRINT=$(openssl x509 -in "$cert" -noout -fingerprint -sha256 2>/dev/null)
  if grep -q "$(echo "$FINGERPRINT" | cut -d= -f2)" "$BUNDLE" 2>/dev/null; then
    echo "  SKIP (already in bundle): $SUBJECT"
  else
    echo "" >> "$BUNDLE"
    echo "# Corporate Proxy:$SUBJECT" >> "$BUNDLE"
    cat "$cert" >> "$BUNDLE"
    echo "  ADDED: $SUBJECT"
  fi
done

# 4. Set REQUESTS_CA_BUNDLE in shell config
SHELL_RC="$HOME/.zshrc"
if grep -q "REQUESTS_CA_BUNDLE" "$SHELL_RC" 2>/dev/null; then
  # Update existing line
  sed -i '' "s|export REQUESTS_CA_BUNDLE=.*|export REQUESTS_CA_BUNDLE=\"$BUNDLE\"|" "$SHELL_RC"
  echo "Updated REQUESTS_CA_BUNDLE in $SHELL_RC"
else
  echo "" >> "$SHELL_RC"
  echo "# Azure CLI CA bundle (corporate proxy fix)" >> "$SHELL_RC"
  echo "export REQUESTS_CA_BUNDLE=\"$BUNDLE\"" >> "$SHELL_RC"
  echo "Added REQUESTS_CA_BUNDLE to $SHELL_RC"
fi
export REQUESTS_CA_BUNDLE="$BUNDLE"

# 5. Patch urllib3
if grep -q "VERIFY_X509_STRICT" "$URLLIB3_SSL"; then
  sed -i '' '/verify_flags |= VERIFY_X509_STRICT/d' "$URLLIB3_SSL"
  echo "Patched urllib3: removed VERIFY_X509_STRICT"
else
  echo "urllib3 already patched (no VERIFY_X509_STRICT found)"
fi

# 6. Verify
echo ""
echo "Verifying fix..."
if az account show >/dev/null 2>&1; then
  echo "SUCCESS: az CLI is working"
else
  echo "WARNING: az account show failed — you may need to run 'az login' first"
  echo "If you get SSL errors still, run: source ~/.zshrc && az login"
fi

# Cleanup
rm -f /tmp/proxy_cert_*.pem
echo "Done."
```

## When to Run

- After `brew upgrade azure-cli`
- After a fresh install of azure-cli
- When `az` commands fail with SSL/certificate errors
- Proactively: if you notice azure-cli was upgraded (version changed)

## Safety Notes

- This does NOT disable certificate verification — only relaxes the strict AKI requirement
- The proxy CA certs are legitimate corporate certificates (the firewall is authorized infrastructure)
- The patch is version-specific — only touches the installed azure-cli's bundled urllib3
- No system-wide SSL changes are made
