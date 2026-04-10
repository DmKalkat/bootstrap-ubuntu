# bootstrap-ubuntu

Small bootstrap scripts for a fresh Ubuntu machine.

This repository is meant for the first manual setup step on a new host when you only have a keyboard and want SSH access as quickly as possible.
The main script installs OpenSSH server and `curl`, enables the SSH service, imports public keys from a GitHub account into the current user's `authorized_keys`, and applies basic SSH hardening by disabling password authentication and restricting direct root login.

Shortest reliable command on a new Ubuntu machine:

```bash
sudo apt-get update && sudo apt-get install -y curl && curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/u.sh | bash
```

This will:
- install `curl`
- download and run the SSH bootstrap script
- add GitHub SSH keys for the current user

If you want a different GitHub account:

```bash
curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/new_ubuntu_ssh.sh | GITHUB_USER=your-github bash
```

Connect from your Windows machine:

```bash
ssh -i $env:USERPROFILE\.ssh\DK_pub [user]@[ip]
```
