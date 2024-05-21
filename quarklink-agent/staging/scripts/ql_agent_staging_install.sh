#!/bin/sh
# This is a script to install the Quarklink Agent on a Linux system

sudo sh -c '
# start_agent function will enable the agent to start on boot and start the agent
start_agent () {
  systemctl enable quarklink-agent-go
  systemctl start quarklink-agent-go
  if [ "$?" -ne 0 ]; then
    echo "Quarklink agent failed to start, check whether device id added to batch etc."
    exit 1
  fi
  exit 0
}


#configs
arm64_agent="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent/staging/quarklink-agent-arm64.bin"
arm32_agent="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent/staging/quarklink-agent-arm.bin"
amd64_agent="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent/staging/quarklink-agent-amd64.bin"
agent_service="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent/staging/service/quarklink-agent-go.service"
agent_config="https://raw.githubusercontent.com/cryptoquantique/quarklink-labs/main/quarklink-agent/staging/service/config.yaml"
quarklink_config_dir="/etc/quarklink"

echo "...Installing quarklink agent..."
#Check if the user is root
if [ `id -u` -ne 0 ]; then
  echo "You must be root to run this script"
  exit 1
fi

# Check if root ca file exists
if [ -f $quarklink_config_dir/ql_ca_cert.pem ]; then
  echo "Root certificate already exists, seems like already provisioned, trying to start agent"
  start_agent
fi

# Create the Quarklink directory
mkdir -p $quarklink_config_dir
mkdir -p $quarklink_config_dir/agent

# read quarklink instance 
echo "Enter the Quarklink instance name"
read instance
echo $instance > $quarklink_config_dir/ql_endpoint

#read root certificate
echo "Enter the root certificate (you may have to press enter twice)"
while read line
do
  # break if the line is empty
  [ -z "$line" ] && break
  echo "$line" >> $quarklink_config_dir/ql_ca_cert.pem
done

#get system type
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

#run the agent
chmod +x /usr/local/bin/quarklink-agent
/usr/local/bin/quarklink-agent -crypto=local -deviceID
if [ "$?" -ne 0 ]; then
    echo "Quarklink agent failed to start, check whether device id added to batch etc."
    exit 1
fi

# Start the agent and enable it to start on boot
start_agent
'

