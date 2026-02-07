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
curl -fsSL https://raw.githubusercontent.com/wwwakcan/CoTurn-WebRTC-Installer/main/coturn-setup.sh | sudo bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/wwwakcan/CoTurn-WebRTC-Installer/main/coturn-setup.sh | sudo bash
```

Or manually:

```bash
git clone https://github.com/wwwakcan/CoTurn-WebRTC-Installer.git
cd CoTurn-WebRTC-Installer
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
| ⚡ **Pipe-Safe** | Works with `curl | bash` — reads input from `/dev/tty` |

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
  ℹ  Detected public IP: 203.0.113.50

  ▸ Server public IP address [203.0.113.50]:
  ▸ STUN/TURN port [3478]:
  ▸ TLS port (TURNS/DTLS) [5349]:
  ▸ Relay min port [30000]:
  ▸ Relay max port [65535]:
```

### Step 2 — Authentication

```
  ℹ  Credentials for clients connecting to the TURN server.
  ℹ  Default: admin / admin

  ▸ Set custom username/password? [n]: y
  ▸ TURN username: myuser
  ℹ  Auto-generated strong password: aB3$kL9m#Qx7pW2Z
  ▸ Use this password? [y]:
```

### Step 3 — SSL/TLS Certificate

```
  ℹ  An SSL certificate is required for TURNS (TLS) and DTLS.
  ℹ  If you don't have one, a self-signed certificate will be generated.

  ▸ Do you have an existing SSL certificate? [n]:
  ℹ  Self-signed certificate will be generated at: /etc/turnserver.pem
```

### Step 4 — Performance Tuning

```
  ℹ  Detected: 4 CPU cores, 8192 MB RAM

  ▸ Relay threads [4]:
  ▸ Max allocation lifetime (seconds) [3600]:
  ▸ Stale nonce duration (seconds) [600]:
```

### Step 5 — Review & Confirm

```
  ┌──────────────────────────────────────────────────┐
  │                                                  │
  │  Network                                         │
  │    Server IP       203.0.113.50                  │
  │    TURN Port       3478                          │
  │    TLS Port        5349                          │
  │    Relay Ports     30000 - 65535                 │
  │                                                  │
  │  Authentication                                  │
  │    Username        myuser                        │
  │    Password        aB3$kL9m#Qx7pW2Z             │
  │                                                  │
  │  SSL/TLS                                         │
  │    Certificate     /etc/turnserver.pem           │
  │    Private Key     /etc/turnserver.key           │
  │    Self-signed     yes                           │
  │                                                  │
  │  Performance                                     │
  │    Threads         4                             │
  │    Max Lifetime    3600s                         │
  │    Stale Nonce     600s                          │
  │                                                  │
  └──────────────────────────────────────────────────┘

  ▸ Proceed with installation? [y]:
```

---

## 🔧 What Gets Installed & Configured

| Component | Details |
|-----------|---------|
| **CoTURN** | Latest version from Ubuntu repositories |
| **SSL Certificate** | Self-signed (10-year validity) or custom |
| **UFW Firewall** | Auto-configured with all required ports |
| **Systemd Service** | Enabled and started automatically |
| **Logging** | Verbose logging to `/var/log/turnserver.log` |

### Ports Overview

| Port | Protocol | Purpose |
|------|----------|---------|
| `3478` | TCP / UDP | STUN + TURN |
| `5349` | TCP / UDP | TURNS (TLS) + DTLS |
| `30000–65535` | TCP / UDP | Media relay |

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
| `turn:IP:3478?transport=udp` | UDP relay — fastest |
| `turn:IP:3478?transport=tcp` | TCP relay — firewall-friendly |
| `turns:IP:5349?transport=tcp` | TLS relay — most secure, enterprise networks |

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

Test using [Trickle ICE](https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/):

1. Add server: `turn:YOUR_IP:3478`
2. Enter username and password
3. Click **Gather candidates**
4. Look for `relay` type candidates — if present, TURN is working ✅

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
2. **Use a real SSL certificate** — Consider [Let's Encrypt](https://letsencrypt.org/) for trusted TLS
3. **Restrict relay IP ranges** — Add `denied-peer-ip` rules for private networks
4. **Monitor logs** — Set up log rotation and alerting
5. **Keep updated** — `apt update && apt upgrade coturn`

### Let's Encrypt Integration

```bash
# Install certbot
apt install -y certbot

# Get certificate (replace with your domain)
certbot certonly --standalone -d turn.yourdomain.com

# Update config
sed -i 's|cert=.*|cert=/etc/letsencrypt/live/turn.yourdomain.com/fullchain.pem|' /etc/turnserver.conf
sed -i 's|pkey=.*|pkey=/etc/letsencrypt/live/turn.yourdomain.com/privkey.pem|' /etc/turnserver.conf

# Restart
systemctl restart coturn
```

---

## ❓ Troubleshooting

### CoTURN not starting

```bash
grep -i "error\|warning" /var/log/turnserver.log
ss -tulnp | grep -E "3478|5349"
```

### TLS/DTLS not working

```bash
# Fix certificate permissions
chown turnserver:turnserver /etc/turnserver.pem /etc/turnserver.key
chmod 644 /etc/turnserver.pem
chmod 600 /etc/turnserver.key
systemctl restart coturn
grep -i "tls\|dtls" /var/log/turnserver.log
```

### No relay candidates in browser

```bash
# Verify firewall
ufw status verbose
ufw allow 30000:65535/udp
ufw allow 30000:65535/tcp
```

### Audio/video not working

- Ensure both STUN and TURN URIs are in `iceServers`
- Include `transport=udp` (some networks block UDP — add TCP fallback)
- Add `turns:` URI for enterprise/restricted networks
- Check relay port range is open on firewall

---

## 🤝 Contributing

Contributions are welcome! Feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ for the WebRTC community<br>
  <a href="https://github.com/wwwakcan/CoTurn-WebRTC-Installer">⭐ Star this repo if it helped you!</a>
</p>
