#!/bin/sh
# This is a script to install the Quarklink Agent on a Linux system

sudo sh -c '
#configs
arm64_agent="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent-staging/quarklink-agent-arm64.bin"
arm32_agent="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent-staging/quarklink-agent-arm.bin"
amd64_agent="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent-staging/quarklink-agent-amd64.bin"
agent_service="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent-staging/service/quarklink-agent-go.service"
agent_config="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent-staging/service/config.yaml"
quarklink_config_dir="/etc/quarklink"

# start_agent function will enable the agent to start on boot and start the agent
start_agent () {
  systemctl enable quarklink-agent-go
  systemctl start quarklink-agent-go
  if [ "$?" -ne 0 ]; then
    echo "Quarklink agent failed to start, check whether device id added to batch etc."
    exit 1
  fi
  echo "Quarklink agent successfully started."
  exit 0
}

read_provision_details () {
  # Create the Quarklink directory
  mkdir -p $quarklink_config_dir
  mkdir -p $quarklink_config_dir/agent

  # read quarklink instance 
  echo "Enter the Quarklink instance name"
  read instance
  echo $instance > $quarklink_config_dir/ql_endpoint

  # #read root certificate
  echo "Enter the root certificate (you may have to press enter twice)"
  [ -f "$quarklink_config_dir/ql_ca_cert.pem" ]; then rm "$quarklink_config_dir/ql_ca_cert.pem"
  while read -r line
  do
    # break if the line is empty
    [ -z "$line" ] && break
    echo "$line" >> $quarklink_config_dir/ql_ca_cert.pem
  done

  # #read signing key
  # echo "Enter the signing key (you may have to press enter twice)"
  # [ -z "$line" ] && break
  #   echo "" > $quarklink_config_dir/ql_sign_key.pem
  #   while read -r line
  #   do
  #     # continue if the line is empty
  #     if [ -z "$line" ]; then break
  #     fi 
  #     echo "$line" >> $quarklink_config_dir/ql_sign_key.pem
  #   done
}

# install_agent function will install the agent onto the machine
install_agent () {
  read_provision_details

  # get system type
  sys_type=$(uname -m)
  echo $sys_type

  case $sys_type in
    x86_64)
      echo "64-bit system x86_64"
      curl -o /usr/local/bin/quarklink-agent $amd64_agent
      ;;
    aarch64)
      echo "64 bit arm system aarch64"
      curl -o /usr/local/bin/quarklink-agent $arm64_agent
      ;;
    armv7l)
      echo "32 bit arm system armv7l"
      curl -o /usr/local/bin/quarklink-agent $arm32_agent
      ;;
    amd64)
      echo "64 bit amd system amd64"
      curl -o /usr/local/bin/quarklink-agent $amd64_agent
      ;;
    *)
      echo "Unsupported system type"
      exit 1
      ;;
  esac

  #copy configs and service descriptions.
  curl -o $quarklink_config_dir/agent/config.yaml $agent_config
  curl -o /etc/systemd/system/quarklink-agent-go.service $agent_service
}

# run_agent will start running the agent
run_agent () {
  #run the agent
  chmod +x /usr/local/bin/quarklink-agent
  /usr/local/bin/quarklink-agent -crypto=local -deviceID
  if [ "$?" -ne 0 ]; then
      echo "Quarklink agent failed to start, check whether device id added to batch etc."
      exit 1
  fi
}

# Check if the binary already exists
if [ -e /usr/local/bin/quarklink-agent ]; then
  echo "Quarklink agent has already been installed, Would you like to reinstall or reprovision?"
  echo "reinstall/reprovision"
  printf "> "
  read inputCommand 
  if [ "$inputCommand" = "reinstall" ]; then
    echo
    echo "Reinstalling Quarklink-Agent"
    rm -r $quarklink_config_dir
    systemctl stop quarklink-agent-go
    install_agent
    start_agent
  elif [ "$inputCommand" = "reprovision" ]; then
    echo
    echo "Reprovisioning with quarklink"
    read_provision_details
    start_agent
  fi
  echo "Cancelling, no action performed."
  exit
fi

# Full initial install
echo "...Installing quarklink agent..."

# Check if root ca file exists
if [ -f $quarklink_config_dir/ql_ca_cert.pem ]; then
  echo "Root certificate already exists, seems like already provisioned, trying to start agent"
  start_agent
fi

# Install agent
install_agent

# Start the agent and enable it to start on boot
start_agent
'

