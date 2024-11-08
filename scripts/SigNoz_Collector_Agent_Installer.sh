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
apt-get install -y wget screen gettext-base

# Install OpenTelemetry Collector
echo -e "${YELLOW}Installing OpenTelemetry Collector...${NC}"
wget -q "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_amd64.deb" -O /tmp/otelcol-contrib.deb

if ! dpkg -i /tmp/otelcol-contrib.deb; then
    echo -e "${RED}Failed to install OpenTelemetry Collector${NC}"
    echo -e "${YELLOW}Attempting to fix dependencies...${NC}"
    apt-get install -f -y
    if ! dpkg -i /tmp/otelcol-contrib.deb; then
        echo -e "${RED}Installation failed${NC}"
        exit 1
    fi
fi

rm /tmp/otelcol-contrib.deb

# Configure OpenTelemetry Collector
echo -e "${YELLOW}Configuring OpenTelemetry Collector...${NC}"
export HOSTNAME=${HOSTNAME:-$(hostname)}
export SIGNOZ_SERVER=$SIGNOZ_SERVER

mkdir -p /etc/otelcol-contrib
wget -q https://raw.githubusercontent.com/developerisnow/signoz_automations/main/configs/config_template.yaml -O /etc/otelcol-contrib/config.yaml

# Start service
echo -e "${YELLOW}Starting OpenTelemetry Collector service...${NC}"
systemctl enable otelcol-contrib
systemctl restart otelcol-contrib

if systemctl is-active --quiet otelcol-contrib; then
    echo -e "${GREEN}Service started successfully!${NC}"
    echo -e "${GREEN}Collector is sending metrics to: $SIGNOZ_SERVER${NC}"
    echo -e "${YELLOW}Check logs with: journalctl -u otelcol-contrib -f${NC}"
    journalctl -u otelcol-contrib -f
else
    echo -e "${RED}Service failed to start. Checking logs...${NC}"
    journalctl -u otelcol-contrib -n 50
    exit 1
fi
