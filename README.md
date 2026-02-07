# 🌐 CoTurn WebRTC Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20|%2022.04%20|%2024.04-orange?logo=ubuntu)](https://ubuntu.com)
[![CoTURN](https://img.shields.io/badge/CoTURN-STUN%2FTURN-blue)](https://github.com/coturn/coturn)

A fast, interactive, and production-ready installation script for deploying a **CoTURN STUN/TURN server** on Ubuntu. Designed for WebRTC applications that need reliable NAT traversal.

<p align="center">
  <img src="https://img.shields.io/badge/Setup%20Time-~2%20minutes-brightgreen" alt="Setup Time">
  <img src="https://img.shields.io/badge/Interactive-Wizard%20UI-purple" alt="Interactive">
  <img src="https://img.shields.io/badge/TLS%2FDTLS-Supported-blue" alt="TLS Support">
</p>

---

## ⚡ One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/wwwakcan/CoTurn-Install-Script/main/coturn-setup.sh | sudo bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/wwwakcan/CoTurn-Install-Script/main/coturn-setup.sh | sudo bash
```

Or manually:

```bash
git clone https://github.com/wwwakcan/CoTurn-Install-Script.git
cd CoTurn-Install-Script
sudo bash coturn-setup.sh
```

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🧙 **Interactive Wizard** | Step-by-step guided setup with colored terminal UI |
| 🔍 **Auto-Detection** | Automatically detects public IP, CPU cores, and RAM |
| 🔐 **Flexible Auth** | Default `admin/admin` or custom credentials with auto-generated strong passwords |
| 🛡️ **TLS/DTLS Support** | Self-signed certificate generation or bring your own |
| 🔥 **Firewall Setup** | Automatic UFW configuration with all required ports |
| ✅ **Verification** | Post-install checks for service status, TLS, DTLS, and port availability |
| 📋 **Ready-to-Use Output** | Provides WebRTC `iceServers` JavaScript configuration |
| ⚡ **One Command** | Full installation in a single command |

---

## 📋 Requirements

- **OS:** Ubuntu 20.04, 22.04, or 24.04
- **Access:** Root or sudo privileges
- **Network:** Public IP address with open ports

---

## 🧙 Setup Wizard

The script guides you through 5 simple steps:

### Step 1 — Network Configuration
```
  ▸ Server public IP address [auto-detected]: 
  ▸ STUN/TURN port [3478]: 
  ▸ TLS port (TURNS/DTLS) [5349]: 
  ▸ Relay min port [30000]: 
  ▸ Relay max port [65535]: 
```

### Step 2 — Authentication
```
  ▸ Set custom username/password? [n]: y
  ▸ TURN username: myuser
  ℹ  Auto-generated strong password: aB3$kL9m#Qx7
  ▸ Use this password? [y]: 
```

### Step 3 — SSL/TLS Certificate
```
  ▸ Do you have an existing SSL certificate? [n]: 
  ℹ  Self-signed certificate will be generated
```

### Step 4 — Performance Tuning
```
  ℹ  Detected: 4 CPU cores, 8192 MB RAM
  ▸ Relay threads [4]: 
  ▸ Max allocation lifetime (seconds) [3600]: 
```

### Step 5 — Review & Confirm
```
  ┌──────────────────────────────────────────────────┐
  │  Network                                          │
  │    Server IP       203.0.113.50                   │
  │    TURN Port       3478                           │
  │    TLS Port        5349                           │
  │    Relay Ports     30000 - 65535                  │
  │                                                    │
  │  Authentication                                    │
  │    Username        myuser                          │
  │    Password        aB3$kL9m#Qx7                   │
  └──────────────────────────────────────────────────┘

  ▸ Proceed with installation? [y]: 
```

---

## 🔧 What Gets Installed & Configured

| Component | Details |
|-----------|---------|
| **CoTURN** | Latest version from Ubuntu repositories |
| **SSL Certificate** | Self-signed (10-year validity) or custom |
| **UFW Firewall** | Ports: 22/tcp, 3478/tcp+udp, 5349/tcp+udp, 30000-65535/tcp+udp |
| **Systemd Service** | Enabled and started automatically |
| **Logging** | Verbose logging to `/var/log/turnserver.log` |

### Ports Overview

| Port | Protocol | Purpose |
|------|----------|---------|
| `3478` | TCP/UDP | STUN + TURN |
| `5349` | TCP/UDP | TURNS (TLS) + DTLS |
| `30000-65535` | TCP/UDP | Media relay |

---

## 📡 WebRTC Integration

After installation, the script outputs a ready-to-use JavaScript configuration:

```javascript
const pcConfig = {
  iceServers: [
    { urls: 'stun:YOUR_SERVER_IP:3478' },
    {
      urls: [
        'turn:YOUR_SERVER_IP:3478?transport=udp',
        'turn:YOUR_SERVER_IP:3478?transport=tcp',
        'turns:YOUR_SERVER_IP:5349?transport=tcp'
      ],
      username: 'YOUR_USERNAME',
      credential: 'YOUR_PASSWORD'
    }
  ]
};

const pc = new RTCPeerConnection(pcConfig);
```

### TURN URI Formats

| URI | Use Case |
|-----|----------|
| `stun:IP:3478` | Basic NAT discovery |
| `turn:IP:3478?transport=udp` | UDP relay (fastest) |
| `turn:IP:3478?transport=tcp` | TCP relay (firewall-friendly) |
| `turns:IP:5349?transport=tcp` | TLS relay (most secure, enterprise networks) |

---

## 🧪 Testing

### STUN Test
```bash
turnutils_stunclient YOUR_SERVER_IP
```

Expected output:
```
INFO: IPv4. UDP reflexive addr: YOUR_CLIENT_IP:PORT
```

### TURN Relay Test
```bash
turnutils_uclient -u YOUR_USER -w YOUR_PASS -p 3478 -T YOUR_SERVER_IP
```

Expected output:
```
INFO: Total lost packets 0 (0.000000%), total send dropped 0 (0.000000%)
INFO: Average round trip delay XXX ms
```

### Browser Test

You can test your TURN server using [Trickle ICE](https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/):

1. Add your TURN server URI: `turn:YOUR_IP:3478`
2. Enter username and password
3. Click "Gather candidates"
4. Look for `relay` candidates — if present, TURN is working

---

## 🔧 Management

| Command | Description |
|---------|-------------|
| `systemctl status coturn` | Check service status |
| `systemctl restart coturn` | Restart the server |
| `systemctl stop coturn` | Stop the server |
| `tail -f /var/log/turnserver.log` | Watch live logs |
| `nano /etc/turnserver.conf` | Edit configuration |

---

## 📁 File Locations

| File | Purpose |
|------|---------|
| `/etc/turnserver.conf` | Main configuration |
| `/etc/turnserver.pem` | SSL certificate |
| `/etc/turnserver.key` | SSL private key |
| `/var/log/turnserver.log` | Server logs |
| `/etc/default/coturn` | Service enable flag |

---

## 🔒 Security Recommendations

For production deployments:

1. **Use strong credentials** — Select "yes" during setup to generate a secure password
2. **Use a real SSL certificate** — Consider [Let's Encrypt](https://letsencrypt.org/) for trusted certificates
3. **Restrict relay IP ranges** — Add `denied-peer-ip` rules in config for private networks
4. **Monitor logs** — Set up log rotation and monitoring
5. **Keep updated** — Regularly update CoTURN: `apt update && apt upgrade coturn`

### Let's Encrypt Integration

To use Let's Encrypt certificates instead of self-signed:

```bash
# Install certbot
apt install -y certbot

# Get certificate (replace with your domain)
certbot certonly --standalone -d turn.yourdomain.com

# Update turnserver.conf
sed -i 's|cert=.*|cert=/etc/letsencrypt/live/turn.yourdomain.com/fullchain.pem|' /etc/turnserver.conf
sed -i 's|pkey=.*|pkey=/etc/letsencrypt/live/turn.yourdomain.com/privkey.pem|' /etc/turnserver.conf

# Restart
systemctl restart coturn
```

---

## ❓ Troubleshooting

### TURN server not starting
```bash
# Check logs for errors
grep -i "error\|warning" /var/log/turnserver.log

# Check if ports are in use
ss -tulnp | grep -E "3478|5349"
```

### TLS/DTLS not working
```bash
# Verify certificate permissions
ls -la /etc/turnserver.pem /etc/turnserver.key

# Certificate must be readable by turnserver user
chown turnserver:turnserver /etc/turnserver.pem /etc/turnserver.key
chmod 644 /etc/turnserver.pem
chmod 600 /etc/turnserver.key

# Restart and check
systemctl restart coturn
grep -i "tls\|dtls" /var/log/turnserver.log
```

### No relay candidates in browser
```bash
# Check firewall
ufw status verbose

# Ensure relay ports are open
ufw allow 30000:65535/udp
ufw allow 30000:65535/tcp
```

### Connection works but no audio/video
- Verify both STUN and TURN URIs are in your `iceServers` config
- Check that `transport=udp` is included (some networks block UDP)
- Add `turns:` URI for enterprise/restricted networks

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## ⭐ Star History

If this project helped you, please consider giving it a ⭐!

---

<p align="center">
  Made with ❤️ for the WebRTC community
</p>
