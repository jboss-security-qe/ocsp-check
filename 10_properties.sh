#!/bin/bash

if [ -z "${EAP_VERSION}" ]; then
  export EAP_VERSION=6.3.0.DR5
fi

if [ -z "${WORKSPACE}" ]; then
  export WORKSPACE=`pwd`
fi

if [ -f ~/static_build_env/eap/${EAP_VERSION}/jboss-eap-${EAP_VERSION}.zip ]; then
  # Jenkins
  export EAP_INST=~/static_build_env/eap/${EAP_VERSION}/jboss-eap-${EAP_VERSION}.zip
elif [ -f ~/test/${EAP_VERSION//./}/jboss-eap-${EAP_VERSION}.zip ]; then
  # local
  export EAP_INST=~/test/${EAP_VERSION//./}/jboss-eap-${EAP_VERSION}.zip
fi

# keystores password
export PASS=1234test

export BUILD_DIR=${WORKSPACE}/build
export EAP_FOLDER=jboss-eap-${EAP_VERSION:0:3}
export JBOSS_HOME=${BUILD_DIR}/${EAP_FOLDER}

# hostname and port are used in openssl.cfg, if you change it here, you have to allign it in the CFG file too
export HOSTNAME=localhost
export OCSP_PORT=16975
export OPENSSL_CONF=${WORKSPACE}/openssl.cfg
