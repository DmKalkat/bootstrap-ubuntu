# bootstrap-ubuntu
## ussage for new_ubuntu_ssh.sh - this will add key to cur user
```bash
sudo apt install curl && curl -s https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/new_ubuntu_ssh.sh | bash
```
### from my locat connect to 
```bash
ssh -i $env:USERPROFILE\.ssh\DK_pub [user]@192.168.1[ip]
```
