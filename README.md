# bootstrap-ubuntu

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
