#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="${GITHUB_USER:-DmKalkat}"
SSHD_DROPIN_DIR="/etc/ssh/sshd_config.d"
SSH_HARDENING_FILE="$SSHD_DROPIN_DIR/99-bootstrap-hardening.conf"
AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"
APT_INSTALL_OPTIONS=(
  -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold
)

echo "Installing OpenSSH server and curl..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get "${APT_INSTALL_OPTIONS[@]}" install -y openssh-server curl

echo "Adding SSH keys from GitHub user: $GITHUB_USER"
install -d -m 700 "$HOME/.ssh"

tmp_keys="$(mktemp)"
tmp_merged="$(mktemp)"
trap 'rm -f "$tmp_keys" "$tmp_merged"' EXIT

curl --fail --silent --show-error "https://github.com/$GITHUB_USER.keys" -o "$tmp_keys"

if [[ ! -s "$tmp_keys" ]]; then
  echo "No SSH keys were returned for GitHub user '$GITHUB_USER'." >&2
  exit 1
fi

touch "$AUTHORIZED_KEYS_FILE"
cat "$AUTHORIZED_KEYS_FILE" "$tmp_keys" | sort -u > "$tmp_merged"
mv "$tmp_merged" "$AUTHORIZED_KEYS_FILE"
chmod 600 "$AUTHORIZED_KEYS_FILE"

echo "Enabling SSH..."
sudo systemctl enable --now ssh

echo "Applying SSH hardening..."
sudo install -d -m 755 "$SSHD_DROPIN_DIR"
printf '%s\n' \
  'PasswordAuthentication no' \
  'PermitRootLogin prohibit-password' \
  | sudo tee "$SSH_HARDENING_FILE" > /dev/null

sudo sshd -t
sudo systemctl restart ssh

echo
echo "=================================="
echo "DONE"
echo "User: $(whoami)"
echo "IP: $(hostname -I | xargs)"
echo "GitHub keys: $GITHUB_USER"
echo "=================================="
