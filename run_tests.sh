#!/bin/bash
WORK_PATH="/tmp/varnish"
CONF_FILE="./default.vcl"
VARNISH_DAEMON="/usr/local/sbin/varnishd"

echo "Starting varnish..."
mkdir -p $WORK_PATH
pkill -9 -f $VARNISH_DAEMON

#Cambio los hosts para que apunten local en los tests.
sed 's/.host = .*;/.host = "127.0.0.1";/g' $CONF_FILE > ${CONF_FILE}.final

$VARNISH_DAEMON \
  -f ${CONF_FILE}.final \
  -n $WORK_PATH -a :8081 -T :6082 -s malloc,25M \
  -p cli_timeout=25 \
  -p connect_timeout=0.5 \
  -p default_ttl=0 \
  -p listen_depth=4096 \
  -p pipe_timeout=30 \
  -p send_timeout=30 \
  -p sess_timeout=5 \
  -p session_linger=100 \
  -p thread_pool_min=150 \
  -p thread_pool_max=2000 \
  -p thread_pool_timeout=300 \
  -p thread_pool_add_delay=2 \
  -p sess_workspace=131072 \
  -p thread_pools=4 \
  -p auto_restart=on

EXIT_CODE=$?
if [ "$EXIT_CODE" != "0" ]; then
	echo "Error starting varnish. Exit code= $EXIT_CODE"
	exit $EXIT_CODE
fi


./node_modules/mocha/bin/_mocha --globals myThis,myHolder,myCallee,State_myThis --reporter spec -t 5000 -s 3000 ${TESTFILE}
RESULT=$?

exit $RESULT
