#!/bin/bash

${JBOSS_HOME}/bin/jboss-cli.sh -c ":shutdown"
sleep 2

kill $OCSP_PID

echo "Exiting with status $OCSP_TEST_EXIT"

exit $OCSP_TEST_EXIT
