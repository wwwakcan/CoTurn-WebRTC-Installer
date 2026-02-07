#!/bin/bash
# ============================================================
# Fast CoTURN Server Install Script for Ubuntu
# https://github.com/wwwakcan/CoTurn-Install-Script
#
# Supports: Ubuntu 20.04 / 22.04 / 24.04
# License: MIT
# ============================================================

set -e

VERSION="1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Defaults
DEFAULT_TURN_PORT=3478
DEFAULT_TLS_PORT=5349
DEFAULT_MIN_PORT=30000
DEFAULT_MAX_PORT=65535
DEFAULT_USER="admin"
DEFAULT_PASS="admin"
DEFAULT_CLI_PASS="coturn_cli_$(date +%s | tail -c 8)"

# ──────────────────────────────────────────────
# Helper Functions
# ──────────────────────────────────────────────

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║                                                  ║"
    echo "  ║       🌐  CoTURN Server Setup Wizard  🌐        ║"
    echo "  ║                                                  ║"
    echo "  ║    STUN/TURN Server for WebRTC Applications      ║"
    echo "  ║                                                  ║"
    echo -e "  ║    ${DIM}v${VERSION}${CYAN}                                          ║"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${GREEN}  ✦ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

info()  { echo -e "  ${CYAN}ℹ${NC}  $1"; }
ok()    { echo -e "  ${GREEN}✔${NC}  $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC}  $1"; }
fail()  { echo -e "  ${RED}✖${NC}  $1"; }

ask() {
    local prompt="$1" default="$2" result=""
    if [ -n "$default" ]; then
        echo -ne "  ${MAGENTA}▸${NC} ${prompt} ${YELLOW}[${default}]${NC}: "
        read -r result
        echo "${result:-$default}"
    else
        echo -ne "  ${MAGENTA}▸${NC} ${prompt}: "
        read -r result
        echo "$result"
    fi
}

ask_secret() {
    local prompt="$1" default="$2" result=""
    echo -ne "  ${MAGENTA}▸${NC} ${prompt} ${YELLOW}[${default}]${NC}: "
    read -rs result
    echo ""
    echo "${result:-$default}"
}

ask_yn() {
    local prompt="$1" default="$2" result=""
    while true; do
        echo -ne "  ${MAGENTA}▸${NC} ${prompt} ${YELLOW}[${default}]${NC}: "
        read -r result
        result="${result:-$default}"
        case "${result,,}" in
            y|yes) echo "yes"; return ;;
            n|no)  echo "no";  return ;;
            *) warn "Please enter y or n" ;;
        esac
    done
}

detect_ip() {
    local ip=""
    ip=$(curl -s -4 --max-time 5 https://ifconfig.me 2>/dev/null || true)
    [ -z "$ip" ] && ip=$(curl -s -4 --max-time 5 https://api.ipify.org 2>/dev/null || true)
    [ -z "$ip" ] && ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null || true)
    [ -z "$ip" ] && ip=$(hostname -I | awk '{print $1}' 2>/dev/null || true)
    echo "$ip"
}

generate_password() {
    local len="${1:-16}"
    tr -dc 'A-Za-z0-9@#%&' < /dev/urandom | head -c "$len" 2>/dev/null || openssl rand -base64 "$len" | head -c "$len"
}

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "ubuntu" ]; then
            warn "This script is designed for Ubuntu. Detected: $ID $VERSION_ID"
            CONFIRM_OS=$(ask_yn "Continue anyway?" "n")
            [ "$CONFIRM_OS" != "yes" ] && exit 1
        else
            ok "Detected: Ubuntu $VERSION_ID"
        fi
    fi
}

# ──────────────────────────────────────────────
# Pre-flight
# ──────────────────────────────────────────────

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root!${NC}"
    echo "Usage: sudo bash $0"
    exit 1
fi

# ──────────────────────────────────────────────
# Wizard Start
# ──────────────────────────────────────────────

print_banner

echo -e "  This wizard will install and configure a CoTURN"
echo -e "  STUN/TURN server for your WebRTC applications."
echo -e "  All settings can be customized interactively.\n"

check_os

DETECTED_IP=$(detect_ip)
if [ -n "$DETECTED_IP" ]; then
    info "Detected public IP: ${BOLD}${DETECTED_IP}${NC}"
else
    warn "Could not auto-detect public IP"
fi
echo ""

# ══════════════════════════════════════════════
# STEP 1: Network
# ══════════════════════════════════════════════

print_step "STEP 1/5 — Network Configuration"

SERVER_IP=$(ask "Server public IP address" "$DETECTED_IP")
[ -z "$SERVER_IP" ] && { fail "IP address cannot be empty!"; exit 1; }

TURN_PORT=$(ask "STUN/TURN port" "$DEFAULT_TURN_PORT")
TLS_PORT=$(ask "TLS port (TURNS/DTLS)" "$DEFAULT_TLS_PORT")
MIN_PORT=$(ask "Relay min port" "$DEFAULT_MIN_PORT")
MAX_PORT=$(ask "Relay max port" "$DEFAULT_MAX_PORT")

# ══════════════════════════════════════════════
# STEP 2: Authentication
# ══════════════════════════════════════════════

print_step "STEP 2/5 — Authentication"

info "Credentials for clients connecting to the TURN server."
info "Default: ${BOLD}admin / admin${NC}\n"

USE_CUSTOM_AUTH=$(ask_yn "Set custom username/password?" "n")

if [ "$USE_CUSTOM_AUTH" = "yes" ]; then
    TURN_USER=$(ask "TURN username" "")
    [ -z "$TURN_USER" ] && { warn "Empty — using default: admin"; TURN_USER="$DEFAULT_USER"; }

    echo ""
    GEN_PASS=$(generate_password 16)
    info "Auto-generated strong password: ${BOLD}${GEN_PASS}${NC}"
    USE_GEN=$(ask_yn "Use this password?" "y")

    if [ "$USE_GEN" = "yes" ]; then
        TURN_PASS="$GEN_PASS"
    else
        TURN_PASS=$(ask_secret "TURN password" "")
        [ -z "$TURN_PASS" ] && { warn "Empty — using default: admin"; TURN_PASS="$DEFAULT_PASS"; }
    fi
else
    TURN_USER="$DEFAULT_USER"
    TURN_PASS="$DEFAULT_PASS"
    info "Using default credentials: ${BOLD}admin / admin${NC}"
fi

# ══════════════════════════════════════════════
# STEP 3: SSL/TLS
# ══════════════════════════════════════════════

print_step "STEP 3/5 — SSL/TLS Certificate"

info "An SSL certificate is required for TURNS (TLS) and DTLS."
info "If you don't have one, a self-signed certificate will be generated.\n"

GENERATE_CERT=""
USE_EXISTING=$(ask_yn "Do you have an existing SSL certificate?" "n")

if [ "$USE_EXISTING" = "yes" ]; then
    CERT_FILE=$(ask "Certificate file path (.pem)" "/etc/turnserver.pem")
    KEY_FILE=$(ask "Private key file path (.key)" "/etc/turnserver.key")

    if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
        fail "Certificate or key file not found!"
        warn "A self-signed certificate will be generated instead."
        USE_EXISTING="no"
    fi
fi

if [ "$USE_EXISTING" = "no" ]; then
    CERT_FILE="/etc/turnserver.pem"
    KEY_FILE="/etc/turnserver.key"
    GENERATE_CERT="yes"
    info "Self-signed certificate will be generated at: ${BOLD}${CERT_FILE}${NC}"
fi

# ══════════════════════════════════════════════
# STEP 4: Performance
# ══════════════════════════════════════════════

print_step "STEP 4/5 — Performance Tuning"

CPU_CORES=$(nproc 2>/dev/null || echo "4")
TOTAL_RAM=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo "unknown")
info "Detected: ${BOLD}${CPU_CORES} CPU cores${NC}, ${BOLD}${TOTAL_RAM} MB RAM${NC}\n"

RELAY_THREADS=$(ask "Relay threads" "$CPU_CORES")
MAX_ALLOC_LIFETIME=$(ask "Max allocation lifetime (seconds)" "3600")
STALE_NONCE=$(ask "Stale nonce duration (seconds)" "600")

# ══════════════════════════════════════════════
# STEP 5: Confirmation
# ══════════════════════════════════════════════

print_step "STEP 5/5 — Review & Confirm"

echo -e "  ${BOLD}Configuration Summary:${NC}\n"
echo -e "  ┌──────────────────────────────────────────────────┐"
echo -e "  │                                                  │"
echo -e "  │  ${BOLD}Network${NC}                                          │"
echo -e "  │    Server IP       ${GREEN}${SERVER_IP}${NC}"
echo -e "  │    TURN Port       ${GREEN}${TURN_PORT}${NC}"
echo -e "  │    TLS Port        ${GREEN}${TLS_PORT}${NC}"
echo -e "  │    Relay Ports     ${GREEN}${MIN_PORT} - ${MAX_PORT}${NC}"
echo -e "  │                                                  │"
echo -e "  │  ${BOLD}Authentication${NC}                                    │"
echo -e "  │    Username        ${GREEN}${TURN_USER}${NC}"
echo -e "  │    Password        ${GREEN}${TURN_PASS}${NC}"
echo -e "  │                                                  │"
echo -e "  │  ${BOLD}SSL/TLS${NC}                                           │"
echo -e "  │    Certificate     ${GREEN}${CERT_FILE}${NC}"
echo -e "  │    Private Key     ${GREEN}${KEY_FILE}${NC}"
echo -e "  │    Self-signed     ${GREEN}${GENERATE_CERT:-no}${NC}"
echo -e "  │                                                  │"
echo -e "  │  ${BOLD}Performance${NC}                                       │"
echo -e "  │    Threads         ${GREEN}${RELAY_THREADS}${NC}"
echo -e "  │    Max Lifetime    ${GREEN}${MAX_ALLOC_LIFETIME}s${NC}"
echo -e "  │    Stale Nonce     ${GREEN}${STALE_NONCE}s${NC}"
echo -e "  │                                                  │"
echo -e "  └──────────────────────────────────────────────────┘"
echo ""

CONFIRM=$(ask_yn "Proceed with installation?" "y")
[ "$CONFIRM" != "yes" ] && { warn "Installation cancelled."; exit 0; }

# ══════════════════════════════════════════════
# INSTALLATION
# ══════════════════════════════════════════════

echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Starting Installation...${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"

# 1. Update
print_step "[1/8] Updating system packages..."
apt update -y >/dev/null 2>&1 && apt upgrade -y >/dev/null 2>&1
ok "System updated"

# 2. Install
print_step "[2/8] Installing CoTURN..."
apt install -y coturn >/dev/null 2>&1
ok "CoTURN installed"

# 3. Enable
print_step "[3/8] Enabling CoTURN service..."
sed -i 's/#TURNSERVER_ENABLED=1/TURNSERVER_ENABLED=1/' /etc/default/coturn 2>/dev/null || true
ok "CoTURN service enabled"

# 4. SSL
print_step "[4/8] Configuring SSL certificate..."
if [ "$GENERATE_CERT" = "yes" ]; then
    openssl req -x509 -nodes -days 3650 \
        -newkey rsa:2048 \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/CN=$SERVER_IP" 2>/dev/null
    ok "Self-signed certificate generated (valid 10 years)"
else
    ok "Using existing certificate"
fi

chown turnserver:turnserver "$CERT_FILE" "$KEY_FILE" 2>/dev/null || true
chmod 644 "$CERT_FILE"
chmod 600 "$KEY_FILE"
ok "Certificate permissions configured"

# 5. Config
print_step "[5/8] Writing configuration..."
[ -f /etc/turnserver.conf ] && cp /etc/turnserver.conf "/etc/turnserver.conf.bak.$(date +%s)"

cat > /etc/turnserver.conf << EOF
# ============================================
# CoTURN Configuration
# Server: $SERVER_IP
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# ============================================

# ── Network ──
listening-port=$TURN_PORT
tls-listening-port=$TLS_PORT
listening-ip=0.0.0.0
relay-ip=$SERVER_IP
external-ip=$SERVER_IP

# ── Authentication ──
lt-cred-mech
user=$TURN_USER:$TURN_PASS
realm=$SERVER_IP
fingerprint

# ── Relay Ports ──
min-port=$MIN_PORT
max-port=$MAX_PORT

# ── Performance ──
relay-threads=$RELAY_THREADS
stale-nonce=$STALE_NONCE
max-allocate-lifetime=$MAX_ALLOC_LIFETIME
channel-lifetime=600

# ── Security ──
no-multicast-peers
no-loopback-peers
no-ipv6

# ── SSL/TLS ──
cert=$CERT_FILE
pkey=$KEY_FILE

# ── CLI ──
cli-password=$DEFAULT_CLI_PASS

# ── Logging ──
log-file=/var/log/turnserver.log
simple-log
verbose

# ── Misc ──
pidfile=/var/run/turnserver.pid
mobility
log-binding
EOF

ok "Configuration written to /etc/turnserver.conf"

# 6. Log
print_step "[6/8] Setting up logging..."
touch /var/log/turnserver.log
chown turnserver:turnserver /var/log/turnserver.log
ok "Log file ready at /var/log/turnserver.log"

# 7. Firewall
print_step "[7/8] Configuring firewall (UFW)..."
apt install -y ufw >/dev/null 2>&1

ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1

ufw allow 22/tcp >/dev/null 2>&1
ufw allow "$TURN_PORT/tcp" >/dev/null 2>&1
ufw allow "$TURN_PORT/udp" >/dev/null 2>&1
ufw allow "$TLS_PORT/tcp" >/dev/null 2>&1
ufw allow "$TLS_PORT/udp" >/dev/null 2>&1
ufw allow "${MIN_PORT}:${MAX_PORT}/udp" >/dev/null 2>&1
ufw allow "${MIN_PORT}:${MAX_PORT}/tcp" >/dev/null 2>&1

echo "y" | ufw enable >/dev/null 2>&1
ok "Firewall rules applied"

# 8. Start
print_step "[8/8] Starting CoTURN..."
systemctl enable coturn >/dev/null 2>&1
systemctl restart coturn
sleep 3
ok "CoTURN started"

# ══════════════════════════════════════════════
# VERIFICATION
# ══════════════════════════════════════════════

print_step "Running verification checks..."

# Service
if systemctl is-active --quiet coturn; then
    ok "Service:  ${GREEN}RUNNING${NC}"
else
    fail "Service:  ${RED}NOT RUNNING${NC}"
fi

# TLS
TLS_OK=$(grep -c "TLS/TCP listener opened on" /var/log/turnserver.log 2>/dev/null || echo "0")
[ "$TLS_OK" -gt 0 ] && ok "TLS:      ${GREEN}ACTIVE${NC}" || warn "TLS:      ${YELLOW}INACTIVE${NC}"

# DTLS
DTLS_OK=$(grep -c "DTLS/UDP listener opened on" /var/log/turnserver.log 2>/dev/null || echo "0")
[ "$DTLS_OK" -gt 0 ] && ok "DTLS:     ${GREEN}ACTIVE${NC}" || warn "DTLS:     ${YELLOW}INACTIVE${NC}"

# Ports
for port in "$TURN_PORT" "$TLS_PORT"; do
    if ss -tulnp | grep -q ":${port} "; then
        ok "Port $port: ${GREEN}LISTENING${NC}"
    else
        warn "Port $port: ${YELLOW}NOT LISTENING${NC}"
    fi
done

# Errors
ERRORS=$(grep -ci "error" /var/log/turnserver.log 2>/dev/null || echo "0")
[ "$ERRORS" -eq 0 ] && ok "Errors:   ${GREEN}NONE${NC}" || warn "Errors:   ${YELLOW}${ERRORS} found — check logs${NC}"

# ══════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════

echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  ✅  Installation Complete!${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Connection Details:${NC}"
echo ""
echo -e "  ┌────────────────────────────────────────────────────────┐"
echo -e "  │                                                        │"
echo -e "  │  Server      ${GREEN}${SERVER_IP}${NC}"
echo -e "  │  Username    ${GREEN}${TURN_USER}${NC}"
echo -e "  │  Password    ${GREEN}${TURN_PASS}${NC}"
echo -e "  │                                                        │"
echo -e "  │  ${BOLD}TURN URIs:${NC}                                            │"
echo -e "  │                                                        │"
echo -e "  │  ${YELLOW}stun:${SERVER_IP}:${TURN_PORT}${NC}"
echo -e "  │  ${YELLOW}turn:${SERVER_IP}:${TURN_PORT}?transport=udp${NC}"
echo -e "  │  ${YELLOW}turn:${SERVER_IP}:${TURN_PORT}?transport=tcp${NC}"
echo -e "  │  ${YELLOW}turns:${SERVER_IP}:${TLS_PORT}?transport=tcp${NC}"
echo -e "  │                                                        │"
echo -e "  └────────────────────────────────────────────────────────┘"
echo ""
echo -e "  ${BOLD}WebRTC iceServers (JavaScript):${NC}"
echo ""
echo -e "  ${DIM}const pcConfig = {${NC}"
echo -e "  ${DIM}  iceServers: [${NC}"
echo -e "  ${DIM}    { urls: 'stun:${SERVER_IP}:${TURN_PORT}' },${NC}"
echo -e "  ${DIM}    {${NC}"
echo -e "  ${DIM}      urls: [${NC}"
echo -e "  ${DIM}        'turn:${SERVER_IP}:${TURN_PORT}?transport=udp',${NC}"
echo -e "  ${DIM}        'turn:${SERVER_IP}:${TURN_PORT}?transport=tcp',${NC}"
echo -e "  ${DIM}        'turns:${SERVER_IP}:${TLS_PORT}?transport=tcp'${NC}"
echo -e "  ${DIM}      ],${NC}"
echo -e "  ${DIM}      username: '${TURN_USER}',${NC}"
echo -e "  ${DIM}      credential: '${TURN_PASS}'${NC}"
echo -e "  ${DIM}    }${NC}"
echo -e "  ${DIM}  ]${NC}"
echo -e "  ${DIM}};${NC}"
echo ""
echo -e "  ${BOLD}Test Commands:${NC}"
echo -e "  ${MAGENTA}turnutils_stunclient ${SERVER_IP}${NC}"
echo -e "  ${MAGENTA}turnutils_uclient -u ${TURN_USER} -w ${TURN_PASS} -p ${TURN_PORT} -T ${SERVER_IP}${NC}"
echo ""
echo -e "  ${BOLD}Management:${NC}"
echo -e "  ${MAGENTA}systemctl status coturn${NC}          # Check status"
echo -e "  ${MAGENTA}systemctl restart coturn${NC}         # Restart"
echo -e "  ${MAGENTA}tail -f /var/log/turnserver.log${NC}  # Live logs"
echo -e "  ${MAGENTA}nano /etc/turnserver.conf${NC}        # Edit config"
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
