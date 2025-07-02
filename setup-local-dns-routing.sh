#!/usr/bin/env bash

set -e

# === CONFIGURABLE DOMAINS ===
DOMAINS=(test example.com dev)

# === Create systemd-resolved override ===
CONF_DIR="/etc/systemd/resolved.conf.d"
CONF_FILE="${CONF_DIR}/dnsmasq-routing.conf"

echo "🛠  Creating systemd-resolved override at ${CONF_FILE}..."

# Join domains with '~' prefix
DOMAINS_STRING=$(printf " ~%s" "${DOMAINS[@]}")

# Create directory if needed
sudo mkdir -p "$CONF_DIR"

# Write the config file
sudo tee "$CONF_FILE" > /dev/null <<EOF
[Resolve]
DNS=127.0.0.1
Domains=${DOMAINS_STRING}
EOF

# === Restart systemd-resolved ===
echo "🔁 Restarting systemd-resolved..."
sudo systemctl restart systemd-resolved

# === Show result ===
echo -e "\n✅ Configuration applied. Current DNS setup:"
resolvectl status | grep -E 'DNS Servers|DNS Domain'

echo -e "\n🔍 Test a domain like:\n    dig testdomain.${DOMAINS[0]} @127.0.0.1"
