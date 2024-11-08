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
HOSTNAME=$(hostname)

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
apt-get update
apt-get install -y wget

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

# Create service file
echo -e "${YELLOW}Creating service file...${NC}"
cat > /lib/systemd/system/otelcol-contrib.service <<EOF
[Unit]
Description=OpenTelemetry Collector Contrib
After=network.target

[Service]
ExecStart=/usr/bin/otelcol-contrib --config /etc/otelcol-contrib/config.yaml
Restart=always
RestartSec=1
User=root

[Install]
WantedBy=multi-user.target
EOF

# Configure OpenTelemetry Collector
echo -e "${YELLOW}Configuring OpenTelemetry Collector...${NC}"
mkdir -p /etc/otelcol-contrib

# Create config with hardcoded values
cat > /etc/otelcol-contrib/config.yaml <<EOF
extensions:
  health_check:
  pprof:
    endpoint: 0.0.0.0:1777
  zpages:
    endpoint: 0.0.0.0:55679

receivers:
  otlp:
    protocols:
      grpc:
      http:
   
  hostmetrics/system:
    collection_interval: 30s
    scrapers:
      cpu:
      load:
      memory:
      disk:
      filesystem:
      network:
      processes:

processors:
  batch:
  resourcedetection:
    detectors: [system]
    system:
      hostname_sources: [os]
  attributes:
    actions:
      - key: "host.name"
        value: "$HOSTNAME"
        action: "insert"
      - key: "service.name"
        value: "vps-monitoring"
        action: "insert"

exporters:
  debug:
    verbosity: detailed
  otlp:
    endpoint: "$SIGNOZ_SERVER"
    tls:
      insecure: true

service:
  pipelines:
    metrics:
      receivers: [hostmetrics/system]
      processors: [batch, resourcedetection, attributes]
      exporters: [debug, otlp]

  extensions: [health_check, pprof, zpages]
EOF

# Set permissions
chmod 644 /etc/otelcol-contrib/config.yaml
chown -R root:root /etc/otelcol-contrib

# Start service
echo -e "${YELLOW}Starting OpenTelemetry Collector service...${NC}"
systemctl daemon-reload
systemctl enable otelcol-contrib
systemctl restart otelcol-contrib

# Wait for service to start
sleep 2

# Check service status
if ! systemctl is-active --quiet otelcol-contrib; then
    echo -e "${RED}Service failed to start. Checking logs...${NC}"
    echo -e "${YELLOW}Config file contents:${NC}"
    cat /etc/otelcol-contrib/config.yaml
    echo -e "${YELLOW}Service logs:${NC}"
    journalctl -u otelcol-contrib -n 50
    exit 1
fi

echo -e "${GREEN}Service started successfully!${NC}"
echo -e "${GREEN}Collector is sending metrics to: $SIGNOZ_SERVER${NC}"
echo -e "${YELLOW}Check logs with: journalctl -u otelcol-contrib -f${NC}"
journalctl -u otelcol-contrib -f
