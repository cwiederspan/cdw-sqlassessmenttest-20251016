# cdw-sqlassessmenttest-20251016
A repo for testing the Azure Assessment and Migration tool.

## Azure SQL Server VM Deployment

This repository contains Azure CLI commands and scripts to deploy an Azure Virtual Machine running SQL Server for assessment and migration testing.

### Quick Start

1. **Automated Deployment**: Run the provided shell script
   ```bash
   chmod +x create-sql-vm.sh
   ./create-sql-vm.sh
   ```

2. **Manual Deployment**: Follow the step-by-step commands in [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)

3. **Verify Deployment**: After deployment, verify all resources
   ```bash
   chmod +x verify-deployment.sh
   ./verify-deployment.sh
   ```

### What Gets Created

The deployment creates:
- Azure Resource Group
- Virtual Network with Subnet
- Network Security Group (with RDP and SQL Server access rules)
- Public IP Address
- Network Interface
- Azure VM running SQL Server 2012 SP4 on Windows Server 2012 R2
- SQL VM extension for management

### Key Features

- ✅ **RDP Access**: Fully configured for Remote Desktop connections
- ✅ **SQL Server**: Old version (SQL Server 2012) pre-installed
- ✅ **Network Security**: Configured NSG with appropriate firewall rules
- ✅ **Public IP**: Static public IP for easy access
- ✅ **Production Ready**: Properly sized VM (Standard_DS3_v2)

### Documentation

- **[DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)**: Comprehensive guide with all Azure CLI commands, alternatives, and configuration
- **[QUICK-COMMANDS.md](QUICK-COMMANDS.md)**: Quick reference with copy-paste ready commands
- **[ARCHITECTURE.md](ARCHITECTURE.md)**: Architecture diagram and detailed resource descriptions
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**: Solutions for common deployment and connection issues
- **[create-sql-vm.sh](create-sql-vm.sh)**: Automated deployment script (Bash)
- **[create-sql-vm.ps1](create-sql-vm.ps1)**: Automated deployment script (PowerShell)
- **[verify-deployment.sh](verify-deployment.sh)**: Script to verify deployment and test connectivity

### Requirements

- Azure CLI installed and configured
- Active Azure subscription
- Logged in to Azure (`az login`)

For detailed instructions, see [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md).
