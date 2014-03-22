#!/bin/bash

pushd ${BUILD_DIR}

wget https://localhost:8443/test/test.txt --ca-certificate=${BUILD_DIR}/ca-cert.pem -O test-downloaded.txt --certificate=${BUILD_DIR}/revoked-client-cert.pem --private-key=${BUILD_DIR}/revoked-client-key.pem

if ! (diff -s test.txt test-downloaded.txt); then
  echo "File differs"
  #exit 10
fi

popd
