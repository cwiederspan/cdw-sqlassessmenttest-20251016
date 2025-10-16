# Quick Command Reference

This file contains the minimal sequence of Azure CLI commands to create a SQL Server VM with RDP access. Copy and paste these commands into your terminal.

## Prerequisites

```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "Your-Subscription-Name-or-ID"
```

## Core Commands (Copy-Paste Ready)

```bash
# 1. Create Resource Group
az group create --name sql-assessment-rg --location eastus

# 2. Create Virtual Network
az network vnet create \
  --resource-group sql-assessment-rg \
  --name sql-vnet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name sql-subnet \
  --subnet-prefix 10.0.1.0/24

# 3. Create Network Security Group
az network nsg create \
  --resource-group sql-assessment-rg \
  --name sql-nsg

# 4. Allow RDP (Port 3389)
az network nsg rule create \
  --resource-group sql-assessment-rg \
  --nsg-name sql-nsg \
  --name AllowRDP \
  --priority 1000 \
  --protocol Tcp \
  --destination-port-ranges 3389 \
  --access Allow

# 5. Allow SQL Server (Port 1433)
az network nsg rule create \
  --resource-group sql-assessment-rg \
  --nsg-name sql-nsg \
  --name AllowSQL \
  --priority 1001 \
  --protocol Tcp \
  --destination-port-ranges 1433 \
  --access Allow

# 6. Create Public IP
az network public-ip create \
  --resource-group sql-assessment-rg \
  --name sql-public-ip \
  --allocation-method Static \
  --sku Standard

# 7. Create Network Interface
az network nic create \
  --resource-group sql-assessment-rg \
  --name sql-nic \
  --vnet-name sql-vnet \
  --subnet sql-subnet \
  --network-security-group sql-nsg \
  --public-ip-address sql-public-ip

# 8. Create SQL Server VM (Change the admin-password!)
az vm create \
  --resource-group sql-assessment-rg \
  --name sql-vm \
  --nics sql-nic \
  --size Standard_DS3_v2 \
  --image MicrosoftSQLServer:sql2012sp4-ws2012r2:standard:latest \
  --admin-username azureuser \
  --admin-password 'YourSecureP@ssw0rd123!'

# 9. Configure SQL VM Extension
az sql vm create \
  --resource-group sql-assessment-rg \
  --name sql-vm \
  --license-type PAYG \
  --sql-mgmt-type Full

# 10. Get the Public IP Address
az network public-ip show \
  --resource-group sql-assessment-rg \
  --name sql-public-ip \
  --query ipAddress \
  --output tsv
```

## Connect via RDP

After getting the public IP from step 10:

```bash
# Windows
mstsc /v:<PUBLIC_IP>

# Mac (if you have Microsoft Remote Desktop installed)
open -a "Microsoft Remote Desktop" rdp://full%20address=s:<PUBLIC_IP>

# Linux
remmina -c rdp://<PUBLIC_IP>
```

Login with:
- Username: `azureuser`
- Password: The password you set in step 8

## Alternative: Single-Line VM Creation

If you want to create everything in fewer commands:

```bash
# Create resource group
az group create --name sql-assessment-rg --location eastus

# Create VM with auto-generated networking
az vm create \
  --resource-group sql-assessment-rg \
  --name sql-vm \
  --image MicrosoftSQLServer:sql2012sp4-ws2012r2:standard:latest \
  --size Standard_DS3_v2 \
  --admin-username azureuser \
  --admin-password 'YourSecureP@ssw0rd123!' \
  --public-ip-sku Standard

# Open RDP port
az vm open-port \
  --resource-group sql-assessment-rg \
  --name sql-vm \
  --port 3389 \
  --priority 1000

# Open SQL Server port
az vm open-port \
  --resource-group sql-assessment-rg \
  --name sql-vm \
  --port 1433 \
  --priority 1001

# Configure SQL VM Extension
az sql vm create \
  --resource-group sql-assessment-rg \
  --name sql-vm \
  --license-type PAYG \
  --sql-mgmt-type Full

# Get public IP
az vm show \
  --resource-group sql-assessment-rg \
  --name sql-vm \
  --show-details \
  --query publicIps \
  --output tsv
```

## Cleanup

To delete everything:

```bash
az group delete --name sql-assessment-rg --yes --no-wait
```

## Notes

- Replace `YourSecureP@ssw0rd123!` with a strong password (12-72 chars, with uppercase, lowercase, number, and special character)
- The VM size `Standard_DS3_v2` provides 4 vCPUs and 14GB RAM
- SQL Server 2012 SP4 is one of the oldest versions available in Azure
- VM creation takes approximately 5-10 minutes
- Total cost: ~$200-300/month when running 24/7 (check current Azure pricing)

## Other Old SQL Server Versions

Replace the `--image` parameter in step 8 with:

```bash
# SQL Server 2014 SP3
--image MicrosoftSQLServer:sql2014sp3-ws2012r2:standard:latest

# SQL Server 2016 SP3
--image MicrosoftSQLServer:sql2016sp3-ws2016:standard:latest

# SQL Server 2017 (RHEL)
--image MicrosoftSQLServer:sql2017-rhel7:standard:latest

# SQL Server 2019 (Ubuntu)
--image MicrosoftSQLServer:sql2019-ubuntu2004:standard:latest
```
