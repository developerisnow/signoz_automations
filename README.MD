# SigNoz Automations

This repository contains automation scripts and templates for setting up SigNoz monitoring across multiple servers.

## OpenTelemetry Collector Agent Installation

### Prerequisites
- Debian/Ubuntu-based Linux system
- Root or sudo access
- `curl` or `wget` installed
- SigNoz server already running and accessible

### Quick Installation

```bash
# Install with your SigNoz server address (required)
curl -s https://raw.githubusercontent.com/developerisnow/signoz_automations/main/scripts/SigNoz_Collector_Agent_Installer.sh | sudo bash -s "your-signoz-server:4317"

# Example:
curl -s https://raw.githubusercontent.com/developerisnow/signoz_automations/main/scripts/SigNoz_Collector_Agent_Installer.sh | sudo bash -s "192.168.1.100:4317"
```

### Manual Installation

1. Clone the repository:
```bash
git clone https://github.com/developerisnow/signoz_automations.git
cd signoz_automations
```

2. Make the script executable:
```bash
chmod +x scripts/SigNoz_Collector_Agent_Installer.sh
```

3. Run the installer with your SigNoz server address:
```bash
sudo ./scripts/SigNoz_Collector_Agent_Installer.sh "your-signoz-server:4317"
```

### Configuration

The installation script:
- Installs the OpenTelemetry Collector Contrib package
- Configures the collector to send metrics to your SigNoz server
- Sets up system metrics collection (CPU, Memory, Disk, Network)
- Automatically starts and enables the collector service

### Verification

After installation, verify the collector is running:
```bash
# Check service status
sudo systemctl status otelcol-contrib

# View logs
sudo journalctl -u otelcol-contrib -f
```

### Files

- `scripts/SigNoz_Collector_Agent_Installer.sh`: Main installation script for collector agents
- `scripts/SigNoz_Server.sh`: Server installation script
- `configs/config_template.yaml`: OpenTelemetry Collector configuration template

### Repository Structure

```
signoz_automations/
├── LICENSE
├── README.MD
├── configs/
│   └── config_template.yaml    # OpenTelemetry configuration template
└── scripts/
    ├── SigNoz_Server.sh       # SigNoz server installation script
    └── SigNoz_Collector_Agent_Installer.sh  # Agent installation script
```

## Contributing

Feel free to submit issues and pull requests.

## License

MIT License - see LICENSE file for details