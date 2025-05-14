#!/bin/sh

sudo sh -c '
#stop agent
systemctl disable quarklink-agent
systemctl stop quarklink-agent

#remove agent and configs
rm -rf /usr/bin/quarklink-agent
rm -rf /etc/quarklink
rm -rf /etc/systemd/system/quarklink-agent.service

echo "remove device from batch"
'
