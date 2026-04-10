#!/usr/bin/env bash
set -euo pipefail

curl --fail --silent --show-error \
  https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/new_ubuntu_ssh.sh \
  | bash
