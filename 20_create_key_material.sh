#!/bin/bash

if [ -d "$BUILD_DIR" ]; then
  rm -rf "$BUILD_DIR"
fi
mkdir ${BUILD_DIR}

exportKeystores () {
  # En/Decode CRT/PEM
  if [ -f $1-cert.pem ]; then
    openssl x509 -inform PEM -in $1-cert.pem -outform DER -out $1-cert.crt
  else
    openssl x509 -inform DER -in $1-cert.crt -outform PEM -out $1-cert.pem
  fi
  # preparing PKCS12 keystore
  openssl pkcs12 -export -in $1-cert.pem -inkey $1-key.pem -out $1.p12 -name $1 -passout pass:${PASS}
  # converting PKCS12 to JKS
  keytool -importkeystore -noprompt -srckeystore $1.p12 -srcstoretype PKCS12 -srcstorepass ${PASS} -destkeystore $1.jks -deststoretype JKS -deststorepass ${PASS}
  # import CRT to truststore
  keytool -import -noprompt -alias $1 -keystore trusted-clients.jks -storepass ${PASS} -file $1-cert.crt
}

prepareClientKeyMaterial() {
  echo "Preparing client key material: $1"
  # Generate a key
  openssl genpkey -outform PEM -out $1-key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
  # Create a CSR request
  openssl req -new -config ${OPENSSL_CONF} -keyform PEM -key $1-key.pem -outform PEM -out $1-cert.csr -days 365 -subj "/C=CZ/O=Red Hat/OU=JBoss/OU=Security QE/CN=$1"
  # Issue a certificate
  # openssl x509 -req -extensions v3_req -extfile ${OPENSSL_CONF} -inform DER -in $1-cert.csr -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -outform DER -out $1-cert.crt
  openssl ca -config ${OPENSSL_CONF} -extensions v3_req -extfile ${OPENSSL_CONF} -batch -keyfile ca-key.pem -cert ca-cert.pem -out $1-cert.pem -infiles $1-cert.csr
  exportKeystores $1
}

pushd "${BUILD_DIR}"

mkdir -p demoCA/newcerts
echo 01 > demoCA/serial
touch demoCA/index.txt

echo ">>> Generate CA key material"
# Generate CA files
openssl genpkey -outform PEM -out ca-key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
openssl req -new -x509 -extensions v3_ca -config ${OPENSSL_CONF} -keyform PEM -key ca-key.pem -outform DER -out ca-cert.crt -days 365 -subj '/C=CZ/O=Red Hat/OU=JBoss/OU=Security QE/CN=EAP Certification Authority'
exportKeystores ca

echo ">>> Generate EAP key material"
prepareClientKeyMaterial ${HOSTNAME}

echo ">>> Generate Valid client key material"
prepareClientKeyMaterial valid-client

echo ">>> Generate Revoked client key material"
prepareClientKeyMaterial revoked-client
openssl ca -config ${OPENSSL_CONF} -keyfile ca-key.pem -cert ca-cert.pem -revoke revoked-client-cert.pem

echo ">>> Generate OCSP responder key material"
# Generate a key
openssl genpkey -outform PEM -out ocsp-key.pem -algorithm RSA -pkeyopt rsa_keygen_bits:2048
# Create a CSR request
openssl req -new -config ${OPENSSL_CONF} -keyform PEM -key ocsp-key.pem -outform PEM -out ocsp-cert.csr -days 365 -subj "/C=CZ/O=Red Hat/OU=JBoss/OU=OCSP Responder/CN=${HOSTNAME}"
# Issue a certificate
openssl ca -config ${OPENSSL_CONF} -extensions v3_OCSP -extfile ${OPENSSL_CONF} -batch -keyfile ca-key.pem -cert ca-cert.pem -out ocsp-cert.pem -infiles ocsp-cert.csr
exportKeystores ocsp

popd # $BUILD_DIR
