#!/bin/bash
function usage ()
{
cat <<EOF
Usage:  start-p4-container.sh [OPTIONS]

Example start script for ProNA p4-container.

Options:
  -h         print this help message

  Mandatory:
  -c <cmd>   run the container in shell mode, executing the command <cmd>.

  or

  -s         start SSH and LSP service, e.g., to use p4-container as a host instance for learn-sdn-hub backend.
EOF
}
 
unset SHELL_CMD_MODE
unset SERVICE_MODE
unset SHELL_CMD

while getopts ":hcs" opt; do
  case $opt in
        h)
            usage; exit 0 ;;
        c)
            export SHELL_CMD_MODE="true" ;;
        s)
            export SERVICE_MODE="true" ;;
        :)
            echo "bad option arg $OPTARG."
            usage
            exit 1
            ;;
        \?)
            echo "bad option $1"
            usage
            exit 1
            ;;
  esac
done

if [[ "$SHELL_CMD_MODE" == "true" ]] && [[ "$SERVICE_MODE" == "true" ]] ; then
  echo "-s and -i are mutually exclusive. Either start the services when running the container using -s OR use -i to drop into the shell of the container."
  usage
  exit 1
elif [[ -z ${SHELL_CMD_MODE} ]] && [[ -z ${SERVICE_MODE} ]] ; then
  echo "Start the container using -s to start the services OR use -i to run a command inside the container."
  usage
  exit 1
fi

shift $((OPTIND-1))

while [ $# -gt 0 ]; do
        if [[ -z "$SHELL_CMD" ]]; then
                SHELL_CMD=$1
                shift
        else
                echo "bad shell cmd $1"
                # exit 1
                shift
        fi
done

if [ "$SERVICE_MODE" == "true" ] ; then
  echo "Starting ProNA p4-container services..."
  echo
  echo "Starting SSH..."
  sudo service ssh start
  echo "You should be able to connect to the container using SSH (default exposed port is 3022, default username: p4, default password: p4)"
  echo 
  echo "Strating LanguageServer Proxy... "
  cd /home/p4/jsonrpc-ws-proxy
  node dist/server.js --port 3005 --languageServers servers.yml
else
  bash -c "$SHELL_CMD"
fi

