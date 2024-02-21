#!/bin/sh

#stop agent
systemctl disable quarklink-agent-go
systemctl stop quarklink-agent-go

#remove agent and configs
rm -rf /usr/local/bin/quarklink-agent
rm -rf /etc/quarklink

echo "remove device from batch"