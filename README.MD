# SigNoz Automations

This repository contains automation scripts and templates for setting up SigNoz monitoring across multiple servers.

## OpenTelemetry Collector Agent Installation

### Prerequisites
- Debian/Ubuntu-based Linux system
- systemd (Ubuntu 18.04 or newer)
- Root or sudo access
- Basic system utilities (will be installed automatically):
  - wget
  - screen
  - gettext-base (for envsubst)

### Quick Installation

```bash
# Single command installation (Recommended)
curl -fsSL https://raw.githubusercontent.com/developerisnow/signoz_automations/main/scripts/SigNoz_Collector_Agent_Installer.sh -o install.sh && \
chmod +x install.sh && \
sudo bash install.sh "your-signoz-server:4317"

# After running the command:
# 1. Wait 5 seconds for the screen session to start
# 2. Attach to the installation screen:
screen -r signoz

# If you see "There is a screen on: XXXX.signoz (Attached)"
# It means the installation is running. Wait a few minutes and try again.
```

# Alternative installation for systems without curl
```bash
wget -q https://raw.githubusercontent.com/developerisnow/signoz_automations/main/scripts/SigNoz_Collector_Agent_Installer.sh -O install.sh && \
chmod +x install.sh && \
sudo bash install.sh "your-signoz-server:4317"
```

### Troubleshooting

If you encounter any errors:

1. Check system requirements:
```bash
# Check Ubuntu version
lsb_release -a

# Check systemd
systemctl --version

# Check if required packages are installed
dpkg -l | grep -E "wget|screen|gettext-base"
```

2. Manual package installation if needed:
```bash
sudo apt-get update
sudo apt-get install -y wget screen gettext-base
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

The installation will automatically:
1. Create a screen session named 'signoz'
2. Install and configure the collector
3. Show real-time logs after installation

You can safely detach from the screen session (Ctrl+A, then D) and reattach later with:
```bash
screen -r signoz
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

### Managing Installation

```bash
# List all screen sessions
screen -ls

# Attach to installation screen
screen -r signoz

# Detach from screen (when attached)
# Press Ctrl+A, then D

# Kill stuck installation (if needed)
screen -ls | grep signoz | cut -d. -f1 | xargs -I{} screen -X -S {} quit
```
