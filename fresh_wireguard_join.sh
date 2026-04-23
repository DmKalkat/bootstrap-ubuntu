#!/usr/bin/env bash
set -euo pipefail

ARG_ADDRESS_OR_SUFFIX="${1:-}"
ARG_PRIVATE_KEY="${2:-}"
WG_INTERFACE="${WG_INTERFACE:-wg0}"
WG_CONFIG_PATH="/etc/wireguard/${WG_INTERFACE}.conf"
WG_PRIVATE_KEY="${WG_PRIVATE_KEY:-$ARG_PRIVATE_KEY}"
WG_PRIVATE_KEY_FILE="${WG_PRIVATE_KEY_FILE:-/etc/wireguard/bootstrap-private.key}"
WG_PUBLIC_KEY=""
WG_ADDRESS="${WG_ADDRESS:-}"
WG_IP_LAST="${WG_IP_LAST:-100}"
WG_ADDRESS_PREFIX="${WG_ADDRESS_PREFIX:-10.216.0.}"
WG_ADDRESS_MASK="${WG_ADDRESS_MASK:-/32}"
WG_DNS="${WG_DNS:-1.1.1.1, 1.0.0.1}"
WG_SERVER_PUBLIC_KEY="${WG_SERVER_PUBLIC_KEY:-uFgQoQsx0K/Vw57BkT1llr1DbURwVJZSqVDzjT3cijo=}"
WG_ALLOWED_IPS="${WG_ALLOWED_IPS:-10.216.0.0/24}"
WG_ENDPOINT="${WG_ENDPOINT:-45.32.154.75:51820}"
APT_INSTALL_OPTIONS=(
  -o Dpkg::Options::=--force-confdef
  -o Dpkg::Options::=--force-confold
)

resolve_address() {
  if [[ -z "$WG_ADDRESS" && -n "$ARG_ADDRESS_OR_SUFFIX" ]]; then
    if [[ "$ARG_ADDRESS_OR_SUFFIX" == *.* ]]; then
      WG_ADDRESS="$ARG_ADDRESS_OR_SUFFIX"
      if [[ "$WG_ADDRESS" != */* ]]; then
        WG_ADDRESS="${WG_ADDRESS}${WG_ADDRESS_MASK}"
      fi
    else
      WG_IP_LAST="$ARG_ADDRESS_OR_SUFFIX"
    fi
  fi

  if [[ -z "$WG_ADDRESS" && -n "$WG_IP_LAST" ]]; then
    WG_ADDRESS="${WG_ADDRESS_PREFIX}${WG_IP_LAST}${WG_ADDRESS_MASK}"
  fi

  if [[ -z "$WG_ADDRESS" ]]; then
    echo "Set WG_ADDRESS or WG_IP_LAST before running this script." >&2
    exit 1
  fi
}

install_wireguard() {
  echo "Installing WireGuard..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get "${APT_INSTALL_OPTIONS[@]}" install -y wireguard
}

prepare_keys() {
  sudo install -d -m 700 /etc/wireguard

  if [[ -z "$WG_PRIVATE_KEY" && -r "$WG_PRIVATE_KEY_FILE" ]]; then
    WG_PRIVATE_KEY="$(tr -d '\r\n' < "$WG_PRIVATE_KEY_FILE")"
  fi

  if [[ -z "$WG_PRIVATE_KEY" ]]; then
    echo "Generating new WireGuard keypair on this machine..."
    WG_PRIVATE_KEY="$(wg genkey)"
    printf '%s\n' "$WG_PRIVATE_KEY" | sudo tee "$WG_PRIVATE_KEY_FILE" > /dev/null
    sudo chmod 600 "$WG_PRIVATE_KEY_FILE"
  fi

  WG_PUBLIC_KEY="$(printf '%s' "$WG_PRIVATE_KEY" | wg pubkey)"
}

write_config() {
  echo "Writing WireGuard config to ${WG_CONFIG_PATH}..."

  sudo tee "$WG_CONFIG_PATH" > /dev/null <<EOF
[Interface]
PrivateKey = ${WG_PRIVATE_KEY}
Address = ${WG_ADDRESS}
DNS = ${WG_DNS}

[Peer]
PublicKey = ${WG_SERVER_PUBLIC_KEY}
AllowedIPs = ${WG_ALLOWED_IPS}
Endpoint = ${WG_ENDPOINT}
EOF

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
  echo "Address: ${WG_ADDRESS}"
  echo "Endpoint: ${WG_ENDPOINT}"
  echo "PublicKey: ${WG_PUBLIC_KEY}"
  echo "Add this public key to your WireGuard server peer list."
  sudo wg show "${WG_INTERFACE}" || true
  echo "=================================="
}

resolve_address
install_wireguard
prepare_keys
write_config
enable_wireguard
show_status
