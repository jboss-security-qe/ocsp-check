#!/bin/bash

${JBOSS_HOME}/bin/jboss-cli.sh -c ":shutdown"
sleep 2

kill $OCSP_PID
