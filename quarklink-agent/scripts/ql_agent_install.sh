#!/bin/sh
# This is a script to install the Quarklink Agent on a Linux system

sudo sh -c '
#configs
arm64_agent="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent/quarklink-agent-arm64.bin"
arm32_agent="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent/quarklink-agent-arm.bin"
amd64_agent="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent/quarklink-agent-amd64.bin"
agent_service="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent/service/quarklink-agent.service"
agent_config="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent/service/config.yaml"
quarklink_config_dir="/etc/quarklink"
ssh_user="quarklink"
agent_path="/usr/bin/quarklink-agent"

# start_agent function will enable the agent to start on boot and start the agent
start_agent () {
  systemctl enable quarklink-agent
  systemctl start quarklink-agent
  if [ "$?" -ne 0 ]; then
    echo "Quarklink agent failed to start."
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
  if test -z "$instance"; then
    echo "instance name empty, using claiming"
    return
  fi
  echo $instance > $quarklink_config_dir/ql_endpoint

  #read root certificate
  echo "Enter the root certificate (you may have to press enter twice)"
  while read -r line
  do
    # break if the line is empty
    [ -z "$line" ] && break
    echo "$line" >> $quarklink_config_dir/ql_ca_cert.pem
  done
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
      curl -o $agent_path $amd64_agent
      ;;
    aarch64)
      echo "64 bit arm system aarch64"
      curl -o $agent_path $arm64_agent
      ;;
    armv7l)
      echo "32 bit arm system armv7l"
      curl -o $agent_path $arm32_agent
      ;;
    amd64)
      echo "64 bit amd system amd64"
      curl -o $agent_path $amd64_agent
      ;;
    *)
      echo "Unsupported system type"
      exit 1
      ;;
  esac

  #make it executable
  chmod +x $agent_path

  #copy configs and service descriptions.
  curl -o $quarklink_config_dir/agent/config.yaml $agent_config
  curl -o /etc/systemd/system/quarklink-agent.service $agent_service
}

# get_device_id prints the device ID
get_device_id () {
  #run the agent
  $agent_path -deviceID
  if [ "$?" -ne 0 ]; then
      echo "Failed to run quarklink agent"
      exit 1
  fi
}
# create ssh user
create_ssh_user() {
  if [ ! -d /home/$ssh_user ]; then
    useradd -m -s /bin/bash $ssh_user
    usermod -a -G sudo $ssh_user
  fi 
}

# Check if the binary already exists
if [ -e $agent_path ]; then
  echo "Quarklink agent is already installed."
  echo "What would you like to do?"
  echo "1. Reinstall"
  echo "2. Reconfigure"
  echo "3. Cancel"
  printf "> "
  read inputCommand 
  if [ "$inputCommand" = "1" ]; then
    echo
    echo "Reinstalling Quarklink-Agent"
    rm -r $quarklink_config_dir
    systemctl stop quarklink-agent
    install_agent
    start_agent
  elif [ "$inputCommand" = "2" ]; then
    echo
    echo "Reconfiguring QuarkLink details"
    read_provision_details
    start_agent
  elif [ "$inputCommand" = "3" ]; then
    echo
    echo "Cancelling, no action performed"
  fi
  exit
fi

# Full initial install
echo "Installing quarklink agent..."

# Check if root ca file exists
if [ -f $quarklink_config_dir/ql_ca_cert.pem ]; then
  echo "Looks like a configuration already exists, starting existing agent service."
  start_agent
fi

#create ssh user
create_ssh_user

# Install agent
install_agent

# Print the device ID
get_device_id
echo "Add this device ID to a batch to successfully run the agent"

# Start the agent service and enable it to start on boot
start_agent
'
