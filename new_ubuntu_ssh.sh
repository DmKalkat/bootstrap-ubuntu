#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="${GITHUB_USER:-DmKalkat}"
SSHD_DROPIN_DIR="/etc/ssh/sshd_config.d"
SSH_HARDENING_FILE="$SSHD_DROPIN_DIR/99-bootstrap-hardening.conf"
AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"

echo "Installing OpenSSH server and curl..."
sudo apt-get update
sudo apt-get install -y openssh-server curl

echo "Enabling SSH..."
sudo systemctl enable --now ssh

echo "Adding SSH keys from GitHub user: $GITHUB_USER"
install -d -m 700 "$HOME/.ssh"

tmp_keys="$(mktemp)"
trap 'rm -f "$tmp_keys"' EXIT

curl --fail --silent --show-error "https://github.com/$GITHUB_USER.keys" -o "$tmp_keys"

if [[ ! -s "$tmp_keys" ]]; then
  echo "No SSH keys were returned for GitHub user '$GITHUB_USER'." >&2
  exit 1
fi

touch "$AUTHORIZED_KEYS_FILE"
chmod 600 "$AUTHORIZED_KEYS_FILE"

while IFS= read -r key; do
  [[ -n "$key" ]] || continue

  if ! grep -Fqx "$key" "$AUTHORIZED_KEYS_FILE"; then
    echo "$key" >> "$AUTHORIZED_KEYS_FILE"
  fi
done < "$tmp_keys"

echo "Applying SSH hardening drop-in..."
sudo install -d -m 755 "$SSHD_DROPIN_DIR"
printf '%s\n' \
  'PasswordAuthentication no' \
  'PermitRootLogin prohibit-password' \
  | sudo tee "$SSH_HARDENING_FILE" > /dev/null

echo "Validating SSH configuration..."
sudo sshd -t

echo "Restarting SSH..."
sudo systemctl restart ssh

echo
echo "=================================="
echo "DONE"
echo "User: $(whoami)"
echo "IP: $(hostname -I | xargs)"
echo "GitHub keys: $GITHUB_USER"
echo "=================================="
