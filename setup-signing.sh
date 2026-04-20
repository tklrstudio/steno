#!/bin/bash
set -e

CERT_NAME="Steno Code Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

# Check if cert already exists
if security find-certificate -c "$CERT_NAME" "$KEYCHAIN" &>/dev/null; then
    echo "Certificate '$CERT_NAME' already exists — skipping."
    exit 0
fi

echo "Creating self-signed code signing certificate..."

# Config with code signing EKU
cat > "$TMP/ext.cnf" <<EOF
[req]
distinguished_name = req_dn
x509_extensions = v3_cs
prompt = no

[req_dn]
CN = $CERT_NAME

[v3_cs]
keyUsage = critical,digitalSignature
extendedKeyUsage = codeSigning
basicConstraints = critical,CA:FALSE
subjectKeyIdentifier = hash
EOF

openssl req -x509 -newkey rsa:2048 \
    -keyout "$TMP/key.pem" \
    -out "$TMP/cert.pem" \
    -days 3650 -nodes \
    -config "$TMP/ext.cnf" 2>/dev/null

openssl pkcs12 -export \
    -out "$TMP/steno.p12" \
    -inkey "$TMP/key.pem" \
    -in "$TMP/cert.pem" \
    -passout pass:steno 2>/dev/null

# Import — -A allows all apps to use the key
security import "$TMP/steno.p12" \
    -k "$KEYCHAIN" \
    -P steno \
    -A 2>/dev/null

echo "Done. When macOS asks to allow 'codesign' access to the key — click 'Always Allow'."
echo "Run ./build.sh now."
