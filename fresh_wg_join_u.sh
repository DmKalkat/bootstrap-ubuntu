#!/usr/bin/env bash
set -euo pipefail

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl

curl --fail --silent --show-error \
  https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_wireguard_join.sh \
  | bash
