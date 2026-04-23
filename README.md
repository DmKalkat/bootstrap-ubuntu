# bootstrap-ubuntu

Small bootstrap scripts for a fresh Ubuntu machine.

This repository is meant for the first manual setup step on a new host when you only have a keyboard and want remote access as quickly as possible.
The simple bootstrap is intended for Ubuntu Server 24.04 LTS and Ubuntu Server 25.10.

## Simple path for a fresh machine

For a clean Ubuntu host, use the main bootstrap:

```bash
sudo apt-get update && sudo apt-get install -y curl && curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_u.sh | bash
```

This creates a new WireGuard keypair on the client automatically, uses `10.216.0.100/32` by default, and prints the client `PublicKey` that you need to add on the server.

If you want to reuse an existing private key instead:

```bash
sudo install -d -m 700 /etc/wireguard
printf '%s\n' 'YOUR_PRIVATE_KEY' | sudo tee /etc/wireguard/bootstrap-private.key > /dev/null
sudo chmod 600 /etc/wireguard/bootstrap-private.key
sudo apt-get update && sudo apt-get install -y curl && curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_u.sh | bash
```

This will:
- install `curl`
- install `wireguard`
- generate a client keypair if needed
- write `/etc/wireguard/wg0.conf`
- enable `wg-quick@wg0`
- show the client `PublicKey` for adding to your cloud WireGuard server
- keep the tunnel alive behind NAT with `PersistentKeepalive = 25`

Test target:
- Ubuntu Server 24.04 LTS
- Ubuntu Server 25.10

If you want SSH setup separately:

```bash
curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_ubuntu_ssh.sh | GITHUB_USER=your-github bash
```

Connect from your Windows machine:

```bash
ssh -i $env:USERPROFILE\.ssh\DK_pub [user]@[ip]
```

## Files

- `fresh_u.sh`: the main entrypoint for joining your WireGuard server
- `fresh_ubuntu_ssh.sh`: simple SSH bootstrap, run separately when needed
- `fresh_wg_u.sh`: short entrypoint for WireGuard
- `fresh_wireguard.sh`: simple WireGuard bootstrap from a ready config
- `fresh_wg_join_u.sh`: short entrypoint for joining your WireGuard server
- `fresh_wireguard_join.sh`: builds `wg0.conf` from env vars and connects immediately
- `u.sh`: old entrypoint kept for compatibility
- `new_ubuntu_ssh.sh`: more defensive version with extra apt/dpkg recovery logic

## WireGuard

If the machine is at home behind Wi-Fi/NAT, WireGuard is a good option when this Ubuntu host connects to an existing WireGuard server or VPS.

The shortest WireGuard install command is:

```bash
sudo apt-get update && sudo apt-get install -y curl && curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_wg_u.sh | WG_CONFIG_B64='BASE64_OF_WG0_CONF' bash
```

Or fetch the config from a URL:

```bash
curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_wireguard.sh | WG_CONFIG_URL='https://example.com/wg0.conf' bash
```

This will:
- install `wireguard`
- write `/etc/wireguard/wg0.conf`
- enable `wg-quick@wg0`
- bring the tunnel up immediately

Important:
- this script expects that you already have a ready WireGuard config for this machine
- WireGuard alone does not remove the need for a second peer with a reachable public IP or domain

## WireGuard Join

If you already have your own WireGuard server in the cloud and only need to join a new Ubuntu machine to it, the main entrypoint is:

```bash
sudo apt-get update && sudo apt-get install -y curl && curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_u.sh | bash
```

Call with IP only:

```bash
curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_u.sh | bash -s -- 101
```

This uses `10.216.0.101/32` and generates a new client key automatically.

Call with IP and private key:

```bash
curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_u.sh | bash -s -- 101 YOUR_PRIVATE_KEY
```

This uses `10.216.0.101/32` and reuses the provided private key.

Defaults in this join script:
- `WG_PRIVATE_KEY_FILE=/etc/wireguard/bootstrap-private.key`
- `WG_IP_LAST=100`
- `WG_ADDRESS_PREFIX=10.216.0.`
- `WG_ADDRESS_MASK=/32`
- `WG_DNS=1.1.1.1, 1.0.0.1`
- `WG_SERVER_PUBLIC_KEY=uFgQoQsx0K/Vw57BkT1llr1DbURwVJZSqVDzjT3cijo=`
- `WG_ALLOWED_IPS=10.216.0.0/24`
- `WG_ENDPOINT=45.32.154.75:51820`
- `WG_PERSISTENT_KEEPALIVE=25`

You can still pass the full address if needed:

```bash
curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_wireguard_join.sh | WG_ADDRESS='10.216.0.100/32' bash
```

Override any of them if needed:

```bash
curl -fsSL https://raw.githubusercontent.com/DmKalkat/bootstrap-ubuntu/main/fresh_wireguard_join.sh | WG_IP_LAST='101' WG_ENDPOINT='45.32.154.75:51820' bash
```

## If apt/dpkg is already broken

If the host package manager is already in a bad state, the simple bootstrap may fail even though the script is fine. In that case either use `new_ubuntu_ssh.sh` or repair the machine first:

```bash
sudo dpkg --configure -a
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -f install -y
```
