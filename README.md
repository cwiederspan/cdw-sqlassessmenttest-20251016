# Azure SQL Server VM Deployment

A repo for testing the Azure Assessment and Migration tool with scripts to deploy an Azure VM running SQL Server with secure RDP access via Azure Bastion.

## Quick Start

```bash
# Make script executable and run
chmod +x create-sql-vm.sh
./create-sql-vm.sh
```

## What Gets Created

The deployment script creates all necessary Azure resources:

1. **Resource Group** - Container for all resources
2. **Virtual Network** (10.0.0.0/16) with two subnets:
   - VM Subnet (10.0.1.0/24) - For the SQL Server VM
   - AzureBastionSubnet (10.0.2.0/27) - Required for Bastion
3. **Network Security Group** with rules for:
   - SQL Server access (port 1433) from VNet only
4. **Azure Bastion** - Secure RDP access without public IP on VM
5. **Bastion Public IP** - Only Bastion needs internet access
6. **Network Interface** - Connects VM to network (no public IP)
7. **Azure VM** - SQL Server 2019 on Windows Server 2019 (Standard_DS3_v2)
8. **SQL VM Extension** - For SQL management features

## Manual Commands

If you prefer to run commands manually instead of using the script:

```bash
# Set your variables
RESOURCE_GROUP="cdw-sqlassessment-20251017"
LOCATION="westus3"
ADMIN_PASSWORD="YourSecureP@ssw0rd123!"  # Change this!

# 1. Create Resource Group
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# 2. Create Virtual Network and VM Subnet
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-vnet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name sql-subnet \
  --subnet-prefix 10.0.1.0/24

# 3. Create Bastion Subnet
az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name sql-vnet \
  --name AzureBastionSubnet \
  --address-prefix 10.0.2.0/27

# 4. Create Network Security Group
az network nsg create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-nsg

# 5. Allow SQL Server (port 1433) from VNet only
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name sql-nsg \
  --name AllowSQL \
  --priority 1001 \
  --protocol Tcp \
  --destination-port-ranges 1433 \
  --source-address-prefixes "10.0.0.0/16" \
  --access Allow

# 6. Create Public IP for Bastion
az network public-ip create \
  --resource-group "$RESOURCE_GROUP" \
  --name bastion-public-ip \
  --allocation-method Static \
  --sku Standard

# 7. Create Bastion Host
az network bastion create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-bastion \
  --public-ip-address bastion-public-ip \
  --vnet-name sql-vnet \
  --location "$LOCATION"

# 8. Create Network Interface (no public IP)
az network nic create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-nic \
  --vnet-name sql-vnet \
  --subnet sql-subnet \
  --network-security-group sql-nsg

# 9. Create SQL Server VM
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-vm \
  --nics sql-nic \
  --size Standard_DS3_v2 \
  --image MicrosoftSQLServer:sql2019-ws2019:standard:latest \
  --admin-username azureuser \
  --admin-password "$ADMIN_PASSWORD"

# 10. Configure SQL VM Extension
az sql vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-vm \
  --license-type PAYG \
  --sql-mgmt-type Full

# 11. Get VM Private IP
az vm show \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-vm \
  --show-details \
  --query privateIps \
  --output tsv
```

## Connecting via Azure Bastion

After deployment, connect to your VM securely through Azure Bastion:

### Option 1: Azure Portal
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your VM: `sql-vm`
3. Click **Connect** → **Bastion**
4. Enter credentials:
   - Username: `azureuser`
   - Password: The password you specified during deployment

### Option 2: Azure CLI
```bash
# Connect via Azure CLI (requires subscription ID)
az network bastion rdp \
  --name sql-bastion \
  --resource-group cdw-sqlassessment-20251017 \
  --target-resource-id /subscriptions/[your-subscription-id]/resourceGroups/cdw-sqlassessment-20251017/providers/Microsoft.Compute/virtualMachines/sql-vm
```

### Benefits of Bastion
- **No Public IP on VM**: Enhanced security
- **No RDP Port Exposure**: Port 3389 not exposed to internet
- **Centralized Access Control**: All access through Azure
- **Built-in Audit Trail**: Connection logging and monitoring

## Cleanup

To delete all resources:

```bash
az group delete --name cdw-sqlassessment-20251017 --yes
```

**Note**: Bastion resources may take longer to delete than standard resources.

## Prerequisites

- Azure CLI installed and configured
- Active Azure subscription  
- Logged in to Azure (`az login`)
