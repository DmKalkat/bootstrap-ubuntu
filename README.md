# bootstrap-ubuntu

Small bootstrap scripts for a fresh Ubuntu machine.

This repository is meant for the first manual setup step on a new host when you only have a keyboard and want SSH access as quickly as possible.
The simple bootstrap is intended for Ubuntu Server 24.04 LTS and Ubuntu Server 25.10.

## Simple path for a fresh machine

For a clean Ubuntu host, use the new simple bootstrap:

```bash
sudo apt-get update && sudo apt-get install -y curl && curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_u.sh | bash
```

This will:
- install `curl`
- install `openssh-server`
- import public keys from `https://github.com/$GITHUB_USER.keys`
- enable SSH
- keep password auth disabled and root login restricted

Test target:
- Ubuntu Server 24.04 LTS
- Ubuntu Server 25.10

If you want a different GitHub account:

```bash
curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_ubuntu_ssh.sh | GITHUB_USER=your-github bash
```

Connect from your Windows machine:

```bash
ssh -i $env:USERPROFILE\.ssh\DK_pub [user]@[ip]
```

## Files

- `fresh_u.sh`: the shortest entrypoint for a new machine
- `fresh_ubuntu_ssh.sh`: the simple main SSH bootstrap
- `u.sh`: old entrypoint kept for compatibility
- `new_ubuntu_ssh.sh`: more defensive version with extra apt/dpkg recovery logic

## If apt/dpkg is already broken

If the host package manager is already in a bad state, the simple bootstrap may fail even though the script is fine. In that case either use `new_ubuntu_ssh.sh` or repair the machine first:

```bash
sudo dpkg --configure -a
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -f install -y
```
