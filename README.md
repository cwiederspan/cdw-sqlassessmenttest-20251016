# Azure SQL Server VM Deployment

A repo for testing the Azure Assessment and Migration tool with scripts to deploy an Azure VM running SQL Server with RDP access.

## Quick Start

```bash
# Make script executable and run
chmod +x create-sql-vm.sh
./create-sql-vm.sh
```

## What Gets Created

The deployment script creates all necessary Azure resources:

1. **Resource Group** - Container for all resources
2. **Virtual Network** (10.0.0.0/16) with Subnet (10.0.1.0/24)
3. **Network Security Group** with rules for:
   - RDP access (port 3389)
   - SQL Server access (port 1433)
4. **Static Public IP** - For consistent external access
5. **Network Interface** - Connects VM to network
6. **Azure VM** - SQL Server 2012 SP4 on Windows Server 2012 R2 (Standard_DS3_v2)
7. **SQL VM Extension** - For SQL management features

## Manual Commands

If you prefer to run commands manually instead of using the script:

```bash
# Set your variables
RESOURCE_GROUP="sql-assessment-rg"
LOCATION="eastus"
ADMIN_PASSWORD="YourSecureP@ssw0rd123!"  # Change this!

# 1. Create Resource Group
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# 2. Create Virtual Network and Subnet
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-vnet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name sql-subnet \
  --subnet-prefix 10.0.1.0/24

# 3. Create Network Security Group
az network nsg create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-nsg

# 4. Allow RDP (port 3389)
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name sql-nsg \
  --name AllowRDP \
  --priority 1000 \
  --protocol Tcp \
  --destination-port-ranges 3389 \
  --access Allow

# 5. Allow SQL Server (port 1433)
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name sql-nsg \
  --name AllowSQL \
  --priority 1001 \
  --protocol Tcp \
  --destination-port-ranges 1433 \
  --access Allow

# 6. Create Public IP
az network public-ip create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-public-ip \
  --allocation-method Static \
  --sku Standard

# 7. Create Network Interface
az network nic create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-nic \
  --vnet-name sql-vnet \
  --subnet sql-subnet \
  --network-security-group sql-nsg \
  --public-ip-address sql-public-ip

# 8. Create SQL Server VM
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-vm \
  --nics sql-nic \
  --size Standard_DS3_v2 \
  --image MicrosoftSQLServer:sql2012sp4-ws2012r2:standard:latest \
  --admin-username azureuser \
  --admin-password "$ADMIN_PASSWORD"

# 9. Configure SQL VM Extension
az sql vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-vm \
  --license-type PAYG \
  --sql-mgmt-type Full

# 10. Get Public IP
az network public-ip show \
  --resource-group "$RESOURCE_GROUP" \
  --name sql-public-ip \
  --query ipAddress \
  --output tsv
```

## Connecting via RDP

After deployment, connect to your VM:

```bash
# Get the public IP
PUBLIC_IP=$(az network public-ip show \
  --resource-group sql-assessment-rg \
  --name sql-public-ip \
  --query ipAddress \
  --output tsv)

# Connect via RDP (Windows)
mstsc /v:$PUBLIC_IP

# Connect via RDP (Mac/Linux)
# Use Microsoft Remote Desktop or remmina with the IP address
```

Login with:
- Username: `azureuser`
- Password: The password you specified during deployment

## Cleanup

To delete all resources:

```bash
az group delete --name sql-assessment-rg --yes --no-wait
```

## Prerequisites

- Azure CLI installed and configured
- Active Azure subscription  
- Logged in to Azure (`az login`)
