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
  echo "-s and -i are mutually exclusive. Either start the services when running the container using -s OR use -c to drop into the shell of the container."
  usage
  exit 1
elif [[ -z ${SHELL_CMD_MODE} ]] && [[ -z ${SERVICE_MODE} ]] ; then
  echo "Start the container using -s to start the services OR use -c to run a command inside the container."
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

LIGHTBLUE='\033[1;34m'
LIGHTRED='\033[1;31m'
NOCOLOR='\033[0m'

echo -e "##################################################################" | sudo tee -a /etc/issue.net
echo -e "# ${LIGHTBLUE}Welcome to ProNA p4-container!${NOCOLOR}                                 #" | sudo tee -a /etc/issue.net
echo -e "# ${LIGHTBLUE}==============================${NOCOLOR}                                 #" | sudo tee -a /etc/issue.net
echo -e "# You should only use this container image for dev/test setup    #" | sudo tee -a /etc/issue.net
echo -e "# and not in production. See also:                               #" | sudo tee -a /etc/issue.net
echo -e "# * ${LIGHTBLUE}https://github.com/prona-p4-learning-platform/p4-container${NOCOLOR}   #" | sudo tee -a /etc/issue.net
echo -e "# * ${LIGHTBLUE}https://github.com/prona-p4-learning-platform/p4-boilerplate${NOCOLOR} #" | sudo tee -a /etc/issue.net
echo -e "# for information on using this container for P4 exercises       #" | sudo tee -a /etc/issue.net
echo -e "##################################################################" | sudo tee -a /etc/issue.net
echo -e "${NOCOLOR}" | sudo tee -a /etc/issue.net

if [[ $(grep -i Microsoft /proc/version) ]]; then
  echo -e "${LIGHTRED}##############################################" | sudo tee -a /etc/issue.net
  echo -e "# CAUTION: Container seems to be running in  #" | sudo tee -a /etc/issue.net
  echo -e "#          WSL on Windows. Some tools, will  #" | sudo tee -a /etc/issue.net
  echo -e "#          not be usable due to lack of      #" | sudo tee -a /etc/issue.net
  echo -e "#          support, e.g., for netem in WSL2  #" | sudo tee -a /etc/issue.net
  echo -e "##############################################" | sudo tee -a /etc/issue.net
  echo -e "${NOCOLOR}" | sudo tee -a /etc/issue.net
fi

sudo bash -c "echo '#!/bin/bash' >/etc/update-motd.d/60-prona"
sudo bash -c "echo 'cat /etc/issue.net' >>/etc/update-motd.d/60-prona"
sudo chmod +x /etc/update-motd.d/60-prona

if [ "$SERVICE_MODE" == "true" ] ; then
  echo "Starting ProNA p4-container services..."
  echo
  echo "Starting SSH..."
  sudo service ssh start
  echo "You should be able to connect to the container using SSH (default exposed port is 3022, default username: p4, default password: p4)"
  echo 
  echo "Starting openvswitch-switch (needed by p4environment)"
  sudo service openvswitch-switch start
  echo
  echo "Starting LanguageServer Proxy... "
  cd /home/p4/jsonrpc-ws-proxy
  node dist/server.js --port 3005 --languageServers servers.yml
else
  echo "Starting openvswitch-switch (needed by p4environment)"
  sudo service openvswitch-switch start
  echo
  bash -c "$SHELL_CMD"
fi

