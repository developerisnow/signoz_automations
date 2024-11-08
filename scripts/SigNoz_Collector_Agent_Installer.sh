#!/bin/bash

# Script configuration
SCRIPT_VERSION="1.0.0"
OTEL_VERSION="0.113.0"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Check arguments
if [ -z "$1" ]; then
    echo -e "${RED}Error: SigNoz server address is required${NC}"
    echo -e "${YELLOW}Usage: $0 <signoz-server:port>${NC}"
    echo -e "${YELLOW}Example: $0 192.168.1.100:4317${NC}"
    exit 1
fi

SIGNOZ_SERVER="$1"

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
apt-get update
apt-get install -y wget systemctl screen dos2unix envsubst gettext-base

# Create screen session if not already in one
if [ -z "$STY" ]; then
    echo -e "${YELLOW}Starting screen session 'signoz'...${NC}"
    exec screen -S signoz -dm bash -c "$0 $1"
    echo -e "${GREEN}Installation running in screen session. To attach:${NC}"
    echo -e "${YELLOW}screen -r signoz${NC}"
    exit 0
fi

# Install OpenTelemetry Collector
echo -e "${YELLOW}Installing OpenTelemetry Collector...${NC}"
wget -q "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_amd64.deb" -O /tmp/otelcol-contrib.deb
dpkg -i /tmp/otelcol-contrib.deb
rm /tmp/otelcol-contrib.deb

# Configure OpenTelemetry Collector
echo -e "${YELLOW}Configuring OpenTelemetry Collector...${NC}"
export HOSTNAME=${HOSTNAME:-$(hostname)}
export SIGNOZ_SERVER=$SIGNOZ_SERVER

mkdir -p /etc/otelcol-contrib
wget -q https://raw.githubusercontent.com/developerisnow/signoz_automations/main/configs/config_template.yaml -O /tmp/config_template.yaml
envsubst < /tmp/config_template.yaml > /etc/otelcol-contrib/config.yaml
rm /tmp/config_template.yaml

# Start service
echo -e "${YELLOW}Starting OpenTelemetry Collector service...${NC}"
systemctl enable otelcol-contrib
systemctl restart otelcol-contrib

if systemctl is-active --quiet otelcol-contrib; then
    echo -e "${GREEN}Service started successfully!${NC}"
else
    echo -e "${RED}Service failed to start. Check logs with: journalctl -u otelcol-contrib${NC}"
    exit 1
fi

echo -e "${GREEN}Installation completed successfully!${NC}"
echo -e "${GREEN}Collector is sending metrics to: $SIGNOZ_SERVER${NC}"
echo -e "${YELLOW}Check logs with: journalctl -u otelcol-contrib -f${NC}"
echo -e "${YELLOW}\nTo detach from screen: Press Ctrl+A, then D${NC}"
echo -e "${YELLOW}To reattach later: screen -r signoz${NC}"

# Show logs
journalctl -u otelcol-contrib -f

# Check for newer versions
echo -e "${YELLOW}Checking for script updates...${NC}"
LATEST_VERSION=$(curl -s https://api.github.com/repos/developerisnow/signoz_automations/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ "$LATEST_VERSION" != "v$SCRIPT_VERSION" ]; then
    echo -e "${YELLOW}New version available: $LATEST_VERSION${NC}"
fi
