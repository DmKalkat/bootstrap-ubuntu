#!/bin/bash
set -e

echo "Installing SSH and curl..."
sudo apt update && sudo apt install -y openssh-server curl

echo "Enabling SSH..."
sudo systemctl enable ssh
sudo systemctl start ssh

echo "Adding SSH keys from GitHub..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
curl -s https://github.com/DmKalkat.keys >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "Hardening SSH config..."
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

sudo systemctl restart ssh

echo ""
echo "=================================="
echo "DONE"
echo "User: $(whoami)"
echo "IP: $(hostname -I)"
echo "=================================="
