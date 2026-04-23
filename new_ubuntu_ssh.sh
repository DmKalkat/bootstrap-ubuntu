#!/usr/bin/env bash
set -euo pipefail

GITHUB_USER="${GITHUB_USER:-DmKalkat}"
SSHD_DROPIN_DIR="/etc/ssh/sshd_config.d"
SSH_HARDENING_FILE="$SSHD_DROPIN_DIR/99-bootstrap-hardening.conf"
AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"
APT_LOCK_WAIT_SECONDS="${APT_LOCK_WAIT_SECONDS:-120}"
APT_RETRY_COUNT="${APT_RETRY_COUNT:-5}"
APT_RETRY_DELAY_SECONDS="${APT_RETRY_DELAY_SECONDS:-5}"
APT_ENV=(DEBIAN_FRONTEND=noninteractive)
APT_DPKG_OPTIONS=(
  -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold
)

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

wait_for_apt_lock() {
  local lock_file="$1"
  local waited=0

  while ! sudo flock -n "$lock_file" true 2>/dev/null; do
    if (( waited >= APT_LOCK_WAIT_SECONDS )); then
      log "Timed out waiting for apt lock: $lock_file"
      return 1
    fi

    log "Waiting for apt lock: $lock_file"
    sleep 3
    waited=$((waited + 3))
  done
}

wait_for_apt_locks() {
  wait_for_apt_lock /var/lib/dpkg/lock-frontend
  wait_for_apt_lock /var/lib/dpkg/lock
  wait_for_apt_lock /var/cache/apt/archives/lock
  wait_for_apt_lock /var/lib/apt/lists/lock
}

repair_apt_state() {
  log "Checking dpkg/apt state..."
  sudo "${APT_ENV[@]}" dpkg --configure -a || true
  sudo "${APT_ENV[@]}" apt-get "${APT_DPKG_OPTIONS[@]}" -f install -y || true
}

run_with_retry() {
  local attempt
  local exit_code

  for ((attempt = 1; attempt <= APT_RETRY_COUNT; attempt++)); do
    if "$@"; then
      return 0
    else
      exit_code=$?
    fi

    if (( attempt == APT_RETRY_COUNT )); then
      log "Command failed after $attempt attempts: $*"
      return "$exit_code"
    fi

    log "Command failed (attempt $attempt/$APT_RETRY_COUNT): $*"
    repair_apt_state
    wait_for_apt_locks
    sleep "$APT_RETRY_DELAY_SECONDS"
  done
}

log "Preparing apt/dpkg..."
wait_for_apt_locks
repair_apt_state

log "Installing OpenSSH server and curl..."
run_with_retry sudo "${APT_ENV[@]}" apt-get update
run_with_retry sudo "${APT_ENV[@]}" apt-get "${APT_DPKG_OPTIONS[@]}" install -y openssh-server curl

log "Enabling SSH..."
sudo systemctl enable --now ssh

log "Adding SSH keys from GitHub user: $GITHUB_USER"
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

log "Applying SSH hardening drop-in..."
sudo install -d -m 755 "$SSHD_DROPIN_DIR"
printf '%s\n' \
  'PasswordAuthentication no' \
  'PermitRootLogin prohibit-password' \
  | sudo tee "$SSH_HARDENING_FILE" > /dev/null

log "Validating SSH configuration..."
sudo sshd -t

log "Restarting SSH..."
sudo systemctl restart ssh

echo
echo "=================================="
echo "DONE"
echo "User: $(whoami)"
echo "IP: $(hostname -I | xargs)"
echo "GitHub keys: $GITHUB_USER"
echo "=================================="
