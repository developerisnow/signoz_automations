#!/bin/bash

# Script configuration
SCRIPT_VERSION="1.0.0"
OTEL_VERSION="0.113.0"
DEFAULT_SIGNOZ_SERVER="192.168.11.11:4317"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print messages
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check system requirements
check_requirements() {
    print_message "Checking system requirements..." "${YELLOW}"
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        print_message "Please run as root or with sudo" "${RED}"
        exit 1
    }

    # Check for required commands
    local required_commands=("wget" "systemctl")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            print_message "Installing $cmd..." "${YELLOW}"
            apt-get install -y "$cmd" >/dev/null 2>&1
        fi
    done
}

# Function to install OpenTelemetry Collector
install_otel_collector() {
    print_message "Installing OpenTelemetry Collector..." "${YELLOW}"
    
    # Download collector
    wget -q "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_amd64.deb" -O /tmp/otelcol-contrib.deb
    
    # Install collector
    dpkg -i /tmp/otelcol-contrib.deb
    
    # Clean up
    rm /tmp/otelcol-contrib.deb
}

# Function to configure OpenTelemetry Collector
configure_otel_collector() {
    print_message "Configuring OpenTelemetry Collector..." "${YELLOW}"
    
    # Set environment variables
    export HOSTNAME=${HOSTNAME:-$(hostname)}
    export SIGNOZ_SERVER=${1:-$DEFAULT_SIGNOZ_SERVER}
    
    # Create config directory if it doesn't exist
    mkdir -p /etc/otelcol-contrib
    
    # Download and process template
    wget -q https://raw.githubusercontent.com/developerisnow/signoz_automations/main/configs/config_template.yaml -O /tmp/config_template.yaml
    
    # Replace variables in template
    envsubst < /tmp/config_template.yaml > /etc/otelcol-contrib/config.yaml
    
    # Clean up
    rm /tmp/config_template.yaml
}

# Function to start and enable service
start_service() {
    print_message "Starting OpenTelemetry Collector service..." "${YELLOW}"
    
    systemctl enable otelcol-contrib
    systemctl restart otelcol-contrib
    
    # Check service status
    if systemctl is-active --quiet otelcol-contrib; then
        print_message "Service started successfully!" "${GREEN}"
    else
        print_message "Service failed to start. Check logs with: journalctl -u otelcol-contrib" "${RED}"
        exit 1
    fi
}

# Main installation function
main() {
    print_message "Starting SigNoz OpenTelemetry Collector installation (v${SCRIPT_VERSION})..." "${GREEN}"
    
    # Require SigNoz server address as argument
    if [ -z "$1" ]; then
        print_message "Error: SigNoz server address is required" "${RED}"
        print_message "Usage: $0 <signoz-server:port>" "${YELLOW}"
        print_message "Example: $0 192.168.1.100:4317" "${YELLOW}"
        exit 1
    fi
    
    SIGNOZ_SERVER="$1"
    
    # Run installation steps
    check_requirements
    install_otel_collector
    configure_otel_collector "$SIGNOZ_SERVER"
    start_service
    
    print_message "Installation completed successfully!" "${GREEN}"
    print_message "Collector is sending metrics to: $SIGNOZ_SERVER" "${GREEN}"
    print_message "Check logs with: journalctl -u otelcol-contrib -f" "${YELLOW}"
}

# Run main function with command line arguments
main "$@"
