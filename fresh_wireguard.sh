#!/usr/bin/env bash
set -euo pipefail

WG_INTERFACE="${WG_INTERFACE:-wg0}"
WG_CONFIG_PATH="/etc/wireguard/${WG_INTERFACE}.conf"
APT_INSTALL_OPTIONS=(
  -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold
)

require_config() {
  if [[ -z "${WG_CONFIG_B64:-}" && -z "${WG_CONFIG_URL:-}" ]]; then
    echo "Set WG_CONFIG_B64 or WG_CONFIG_URL before running this script." >&2
    exit 1
  fi
}

install_wireguard() {
  echo "Installing WireGuard..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get "${APT_INSTALL_OPTIONS[@]}" install -y wireguard
}

write_config() {
  echo "Writing WireGuard config to ${WG_CONFIG_PATH}..."
  sudo install -d -m 700 /etc/wireguard

  if [[ -n "${WG_CONFIG_B64:-}" ]]; then
    printf '%s' "$WG_CONFIG_B64" | base64 -d | sudo tee "$WG_CONFIG_PATH" > /dev/null
  else
    curl --fail --silent --show-error "$WG_CONFIG_URL" | sudo tee "$WG_CONFIG_PATH" > /dev/null
  fi

  sudo chmod 600 "$WG_CONFIG_PATH"
}

enable_wireguard() {
  echo "Enabling WireGuard interface: ${WG_INTERFACE}"
  sudo systemctl enable --now "wg-quick@${WG_INTERFACE}"
}

show_status() {
  echo
  echo "=================================="
  echo "DONE"
  echo "Interface: ${WG_INTERFACE}"
  sudo wg show "${WG_INTERFACE}" || true
  echo "=================================="
}

require_config
install_wireguard
write_config
enable_wireguard
show_status
