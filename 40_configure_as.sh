#!/bin/bash
WORKSPACE=`pwd`
PASS=1234test
BUILD_DIR=${WORKSPACE}/build
HOSTNAME=localhost
OCSP_PORT=16975
EAP_INST=~/test/630DR5/jboss-eap-6.3.0.DR5.zip
EAP_FOLDER=jboss-eap-6.3
JBOSS_HOME=${BUILD_DIR}/${EAP_FOLDER}

pushd ${BUILD_DIR}

unzip -q "${EAP_INST}"
# deploy test app

echo "Hello Work!" >test.txt
zip "${JBOSS_HOME}/standalone/deployments/test.war" test.txt

# Start server
${JBOSS_HOME}/bin/standalone.sh &
sleep 15

# add HTTPS connector
${JBOSS_HOME}/bin/jboss-cli.sh -c "/subsystem=web/connector=https:add(protocol=HTTP/1.1, scheme=https, socket-binding=https, secure=true)"
${JBOSS_HOME}/bin/jboss-cli.sh -c "/subsystem=web/connector=https/ssl=configuration:add(name=https, password=${PASS}, keystore-type=PKCS12, certificate-key-file=${BUILD_DIR}/localhost.p12,ca-certificate-file=${BUILD_DIR}/ca.jks,truststore-type=JKS)"
${JBOSS_HOME}/bin/jboss-cli.sh -c ":reload"
sleep 5

popd
