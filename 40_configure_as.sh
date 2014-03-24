#!/bin/bash

pushd ${BUILD_DIR}

unzip -q "${EAP_INST}"

# Start server
echo "Starting JBoss AS"
${JBOSS_HOME}/bin/standalone.sh >jboss_console.log 2>&1 &
sleep 15

# prepare configuration script

cat >cofigure_https.cli << EOT
/subsystem=logging/logger=org.jboss.security:add(level=TRACE)
/subsystem=logging/logger=org.jboss.as.security:add(level=TRACE)
/subsystem=logging/logger=org.picketbox:add(level=TRACE)
/subsystem=logging/logger=org.apache.catalina.authenticator:add(level=TRACE)
/subsystem=logging/logger=org.jboss.as.web.security:add(level=TRACE)
/subsystem=logging/logger=org.jboss.as.domain.management.security:add(level=TRACE)
/subsystem=logging/console-handler=CONSOLE:write-attribute(name=level)

/subsystem=web/connector=https:add(protocol=HTTP/1.1, scheme=https, socket-binding=https, secure=true)
/subsystem=web/connector=https/ssl=configuration:add(name=https, password=${PASS}, keystore-type=PKCS12, certificate-key-file=${BUILD_DIR}/localhost.p12,ca-certificate-file=${BUILD_DIR}/ca.jks,truststore-type=JKS)

/subsystem=security/security-domain=trust-domain:add
/subsystem=security/security-domain=trust-domain/jsse=classic:add(truststore={password=>${PASS},url=>${BUILD_DIR}/trusted-clients.jks})

/subsystem=security/security-domain=web-tests:add
/subsystem=security/security-domain=web-tests/authentication=classic:add
/subsystem=security/security-domain=web-tests/authentication=classic/login-module=CertificateRoles:add(code=CertificateRoles, flag=required, module-options=[("securityDomain"=>"trust-domain"), ("verifier"=>"org.jboss.security.auth.certs.AnyCertVerifier")])

/core-service=management/security-realm=ManagementRealmWeb:add
/core-service=management/security-realm=ManagementRealmWeb/server-identity=ssl:add(alias=localhost, keystore-password=${PASS}, keystore-path=${BUILD_DIR}/localhost.jks)
/core-service=management/security-realm=ManagementRealmWeb/authentication=truststore:add(keystore-password=${PASS}, keystore-path=${BUILD_DIR}/trusted-clients.jks)

reload

/core-service=management/management-interface=http-interface:write-attribute(name=secure-socket-binding, value=management-https)
/core-service=management/management-interface=http-interface:write-attribute(name=security-realm, value=ManagementRealmWeb)

reload

EOT

# configure the AS
echo "Configuring JBoss AS"
${JBOSS_HOME}/bin/jboss-cli.sh -c --file=cofigure_https.cli

popd # $BUILD_DIR

# prepare and deploy test app
echo "Building and deploying test application"
pushd testapp
mvn clean package
${JBOSS_HOME}/bin/jboss-cli.sh -c "deploy target/testapp.war"
popd #testapp
