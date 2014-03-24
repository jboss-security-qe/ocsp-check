#!/bin/bash

pushd ${BUILD_DIR}

wget https://localhost:8443/testapp/ --ca-certificate=${BUILD_DIR}/ca-cert.pem -O revoked-client-test.txt --certificate=${BUILD_DIR}/revoked-client-cert.pem --private-key=${BUILD_DIR}/revoked-client-key.pem

wget https://localhost:8443/testapp/ --ca-certificate=${BUILD_DIR}/ca-cert.pem -O valid-client-test.txt --certificate=${BUILD_DIR}/valid-client-cert.pem --private-key=${BUILD_DIR}/valid-client-key.pem

OCSP_TEST_EXIT=0

# check responses
if ! (grep -q "The testapp index" valid-client-test.txt); then
  echo "[FAILURE] Valid client didn't reach the test application"
  let OCSP_TEST_EXIT++
fi
let 'OCSP_TEST_EXIT<<=1'
if (grep -q "The testapp index" revoked-client-test.txt); then
  echo "[FAILURE] Revoked client reached the test application"
  let OCSP_TEST_EXIT++
fi
let 'OCSP_TEST_EXIT<<=1'
if ! (grep -q "Cert Status: good" ocsp_responder.log); then
  echo "[FAILURE] OCSP responder didn't check the valid client"
  let OCSP_TEST_EXIT++
fi
let 'OCSP_TEST_EXIT<<=1'
if ! (grep -q "Cert Status: revoked" ocsp_responder.log); then
  echo "[FAILURE] OCSP responder didn't check the revoked client"
  let OCSP_TEST_EXIT++
fi
let 'OCSP_TEST_EXIT<<=1'

# TODO wget https://localhost:9443/management/

export OCSP_TEST_EXIT

popd # ${BUILD_DIR}
