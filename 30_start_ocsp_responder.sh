#!/bin/bash

openssl ocsp -index ${BUILD_DIR}/demoCA/index.txt -port ${OCSP_PORT} -CA ${BUILD_DIR}/ca-cert.pem -rsigner ${BUILD_DIR}/ocsp-cert.pem -rkey ${BUILD_DIR}/ocsp-key.pem -text -out ${BUILD_DIR}/ocsp_responder.log 2>${BUILD_DIR}/ocsp_err.log 1>${BUILD_DIR}/ocsp_out.log &
export OCSP_PID=$!
sleep 2
