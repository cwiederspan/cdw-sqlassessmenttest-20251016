# Azure SQL Server VM Deployment Guide

This guide provides Azure CLI commands to create an Azure Virtual Machine running an old version of SQL Server with full RDP access.

## Prerequisites

1. **Azure CLI installed**: Download from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
2. **Azure subscription**: Active Azure subscription
3. **Login to Azure**: Run `az login` before executing commands

## Quick Start

### Option 1: Run the Script (Recommended)

```bash
# Make the script executable
chmod +x create-sql-vm.sh

# Run the script
./create-sql-vm.sh
```

### Option 2: Manual Command Execution

Follow the commands below in sequence.

## Step-by-Step Commands

### 1. Set Variables

```bash
# Configure your deployment parameters
RESOURCE_GROUP="sql-assessment-rg"
LOCATION="eastus"
VNET_NAME="sql-vnet"
SUBNET_NAME="sql-subnet"
NSG_NAME="sql-nsg"
PUBLIC_IP_NAME="sql-public-ip"
NIC_NAME="sql-nic"
VM_NAME="sql-vm"
VM_SIZE="Standard_DS3_v2"
ADMIN_USERNAME="azureuser"
ADMIN_PASSWORD="YourSecureP@ssw0rd123!"  # Change this to a secure password
```

### 2. Create Resource Group

```bash
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION"
```

### 3. Create Virtual Network and Subnet

```bash
az network vnet create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VNET_NAME" \
    --address-prefix 10.0.0.0/16 \
    --subnet-name "$SUBNET_NAME" \
    --subnet-prefix 10.0.1.0/24
```

### 4. Create Network Security Group

```bash
az network nsg create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$NSG_NAME"
```

### 5. Add RDP Rule to NSG (Port 3389)

```bash
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "AllowRDP" \
    --priority 1000 \
    --protocol Tcp \
    --destination-port-ranges 3389 \
    --access Allow \
    --direction Inbound \
    --description "Allow RDP access"
```

### 6. Add SQL Server Rule to NSG (Port 1433)

```bash
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "AllowSQL" \
    --priority 1001 \
    --protocol Tcp \
    --destination-port-ranges 1433 \
    --access Allow \
    --direction Inbound \
    --description "Allow SQL Server access"
```

### 7. Create Public IP Address

```bash
az network public-ip create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$PUBLIC_IP_NAME" \
    --allocation-method Static \
    --sku Standard
```

### 8. Create Network Interface

```bash
az network nic create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$NIC_NAME" \
    --vnet-name "$VNET_NAME" \
    --subnet "$SUBNET_NAME" \
    --network-security-group "$NSG_NAME" \
    --public-ip-address "$PUBLIC_IP_NAME"
```

### 9. Create SQL Server VM

```bash
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --location "$LOCATION" \
    --nics "$NIC_NAME" \
    --size "$VM_SIZE" \
    --image "MicrosoftSQLServer:sql2012sp4-ws2012r2:standard:latest" \
    --admin-username "$ADMIN_USERNAME" \
    --admin-password "$ADMIN_PASSWORD"
```

### 10. Configure SQL Server VM Extension

```bash
az sql vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --license-type PAYG \
    --sql-mgmt-type Full
```

### 11. Get Public IP Address

```bash
az network public-ip show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$PUBLIC_IP_NAME" \
    --query ipAddress \
    --output tsv
```

## Available SQL Server Images

You can choose from various SQL Server versions. Here are some older versions available:

### SQL Server 2012 (Oldest Generally Available)
```bash
# SQL Server 2012 SP4 Standard on Windows Server 2012 R2
MicrosoftSQLServer:sql2012sp4-ws2012r2:standard:latest

# SQL Server 2012 SP4 Enterprise on Windows Server 2012 R2
MicrosoftSQLServer:sql2012sp4-ws2012r2:enterprise:latest
```

### SQL Server 2014
```bash
# SQL Server 2014 SP3 Standard on Windows Server 2012 R2
MicrosoftSQLServer:sql2014sp3-ws2012r2:standard:latest

# SQL Server 2014 SP3 Enterprise on Windows Server 2012 R2
MicrosoftSQLServer:sql2014sp3-ws2012r2:enterprise:latest
```

### SQL Server 2016
```bash
# SQL Server 2016 SP3 Standard on Windows Server 2016
MicrosoftSQLServer:sql2016sp3-ws2016:standard:latest

# SQL Server 2016 SP3 Enterprise on Windows Server 2016
MicrosoftSQLServer:sql2016sp3-ws2016:enterprise:latest
```

### Listing Available Images

To see all available SQL Server images:

```bash
# List all SQL Server offers
az vm image list-offers \
    --publisher MicrosoftSQLServer \
    --location eastus \
    --output table

# List all SKUs for a specific offer (e.g., SQL Server 2012 SP4)
az vm image list-skus \
    --publisher MicrosoftSQLServer \
    --offer sql2012sp4-ws2012r2 \
    --location eastus \
    --output table

# List all versions of a specific SKU
az vm image list \
    --publisher MicrosoftSQLServer \
    --offer sql2012sp4-ws2012r2 \
    --sku standard \
    --all \
    --output table
```

## Connecting to Your VM

### Via Remote Desktop (RDP)

1. Get the public IP address from the output or run:
   ```bash
   az network public-ip show \
       --resource-group "$RESOURCE_GROUP" \
       --name "$PUBLIC_IP_NAME" \
       --query ipAddress \
       --output tsv
   ```

2. Use Remote Desktop Client:
   - **Windows**: Run `mstsc /v:<PUBLIC_IP>`
   - **Mac**: Use Microsoft Remote Desktop app from the App Store
   - **Linux**: Use Remmina or another RDP client

3. Login credentials:
   - Username: The value of `$ADMIN_USERNAME` (default: `azureuser`)
   - Password: The password you set in `$ADMIN_PASSWORD`

### Via SQL Server Management Studio (SSMS)

1. Download SSMS from Microsoft's website if not already installed
2. Connect to: `<PUBLIC_IP>,1433`
3. Authentication: Windows Authentication (use VM credentials)
4. You may need to configure SQL Server to allow remote connections

## Post-Deployment Configuration

### Enable SQL Server Remote Connections

After connecting via RDP, you may need to:

1. Open SQL Server Configuration Manager
2. Enable TCP/IP protocol for SQL Server
3. Set SQL Server to listen on port 1433
4. Restart SQL Server service
5. Configure SQL Server Authentication if needed

### Windows Firewall

The Windows Firewall on the VM should allow SQL Server traffic. If not:

```powershell
# Run this on the VM via RDP
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
```

## VM Size Recommendations

| VM Size | vCPUs | RAM | Use Case |
|---------|-------|-----|----------|
| Standard_DS2_v2 | 2 | 7 GB | Testing/Dev |
| Standard_DS3_v2 | 4 | 14 GB | Light Production |
| Standard_DS4_v2 | 8 | 28 GB | Production |
| Standard_DS5_v2 | 16 | 56 GB | Heavy Production |

## Cost Considerations

- SQL Server VMs include SQL Server licensing costs
- Choose PAYG (Pay As You Go) or AHUB (Azure Hybrid Benefit) if you have existing licenses
- Remember to deallocate or delete resources when not in use to avoid charges

## Cleanup

To delete all resources:

```bash
az group delete \
    --name "$RESOURCE_GROUP" \
    --yes \
    --no-wait
```

## Troubleshooting

### Can't Connect via RDP

1. Verify NSG rule allows port 3389
2. Check if VM is running: `az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "powerState"`
3. Verify public IP: `az network public-ip show --resource-group "$RESOURCE_GROUP" --name "$PUBLIC_IP_NAME"`

### SQL Server Not Accessible

1. Ensure SQL Server service is running on the VM
2. Check Windows Firewall settings on the VM
3. Verify SQL Server is configured to allow remote connections
4. Confirm NSG allows port 1433

### VM Creation Fails

1. Check if the image is available in your region
2. Verify you have sufficient quota for the VM size
3. Ensure the subscription has the required permissions

## Additional Resources

- [Azure SQL VM Documentation](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/reference-index)
- [SQL Server on Azure VMs Best Practices](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/performance-guidelines-best-practices)
