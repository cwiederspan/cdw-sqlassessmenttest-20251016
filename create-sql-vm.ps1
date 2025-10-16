################################################################################
# Azure SQL Server VM Deployment Script (PowerShell)
# 
# This script creates an Azure VM running SQL Server with all necessary 
# networking components including RDP access.
#
# Prerequisites:
# - Azure CLI installed and logged in (az login)
# - Sufficient permissions to create resources
################################################################################

# Variables - Customize these as needed
$RESOURCE_GROUP = "sql-assessment-rg"
$LOCATION = "eastus"
$VNET_NAME = "sql-vnet"
$SUBNET_NAME = "sql-subnet"
$NSG_NAME = "sql-nsg"
$PUBLIC_IP_NAME = "sql-public-ip"
$NIC_NAME = "sql-nic"
$VM_NAME = "sql-vm"
$VM_SIZE = "Standard_DS3_v2"  # 4 cores, 14GB RAM - good for SQL Server
$ADMIN_USERNAME = "azureuser"

# SQL Server Image details (SQL Server 2012 SP4 on Windows Server 2012 R2)
# This is one of the older SQL Server versions available in Azure
$IMAGE_URN = "MicrosoftSQLServer:sql2012sp4-ws2012r2:standard:latest"

Write-Host "========================================"
Write-Host "Azure SQL Server VM Deployment Script"
Write-Host "========================================"
Write-Host ""

# Prompt for admin password
$SecurePassword = Read-Host "Enter password for VM admin user ($ADMIN_USERNAME)" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
$ADMIN_PASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host ""
Write-Host "Step 1: Creating Resource Group..." -ForegroundColor Green
az group create `
    --name $RESOURCE_GROUP `
    --location $LOCATION `
    --output table

Write-Host ""
Write-Host "Step 2: Creating Virtual Network and Subnet..." -ForegroundColor Green
az network vnet create `
    --resource-group $RESOURCE_GROUP `
    --name $VNET_NAME `
    --address-prefix 10.0.0.0/16 `
    --subnet-name $SUBNET_NAME `
    --subnet-prefix 10.0.1.0/24 `
    --output table

Write-Host ""
Write-Host "Step 3: Creating Network Security Group..." -ForegroundColor Green
az network nsg create `
    --resource-group $RESOURCE_GROUP `
    --name $NSG_NAME `
    --output table

Write-Host ""
Write-Host "Step 4: Creating NSG rule to allow RDP (port 3389)..." -ForegroundColor Green
az network nsg rule create `
    --resource-group $RESOURCE_GROUP `
    --nsg-name $NSG_NAME `
    --name "AllowRDP" `
    --priority 1000 `
    --protocol Tcp `
    --destination-port-ranges 3389 `
    --access Allow `
    --direction Inbound `
    --description "Allow RDP access" `
    --output table

Write-Host ""
Write-Host "Step 5: Creating NSG rule to allow SQL Server (port 1433)..." -ForegroundColor Green
az network nsg rule create `
    --resource-group $RESOURCE_GROUP `
    --nsg-name $NSG_NAME `
    --name "AllowSQL" `
    --priority 1001 `
    --protocol Tcp `
    --destination-port-ranges 1433 `
    --access Allow `
    --direction Inbound `
    --description "Allow SQL Server access" `
    --output table

Write-Host ""
Write-Host "Step 6: Creating Public IP Address..." -ForegroundColor Green
az network public-ip create `
    --resource-group $RESOURCE_GROUP `
    --name $PUBLIC_IP_NAME `
    --allocation-method Static `
    --sku Standard `
    --output table

Write-Host ""
Write-Host "Step 7: Creating Network Interface..." -ForegroundColor Green
az network nic create `
    --resource-group $RESOURCE_GROUP `
    --name $NIC_NAME `
    --vnet-name $VNET_NAME `
    --subnet $SUBNET_NAME `
    --network-security-group $NSG_NAME `
    --public-ip-address $PUBLIC_IP_NAME `
    --output table

Write-Host ""
Write-Host "Step 8: Creating SQL Server VM..." -ForegroundColor Green
Write-Host "This may take several minutes..." -ForegroundColor Yellow
az vm create `
    --resource-group $RESOURCE_GROUP `
    --name $VM_NAME `
    --location $LOCATION `
    --nics $NIC_NAME `
    --size $VM_SIZE `
    --image $IMAGE_URN `
    --admin-username $ADMIN_USERNAME `
    --admin-password $ADMIN_PASSWORD `
    --output table

Write-Host ""
Write-Host "Step 9: Configuring SQL Server VM extension..." -ForegroundColor Green
az sql vm create `
    --resource-group $RESOURCE_GROUP `
    --name $VM_NAME `
    --license-type PAYG `
    --sql-mgmt-type Full `
    --output table

Write-Host ""
Write-Host "========================================"
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================"
Write-Host ""

# Get the public IP address
$PUBLIC_IP = az network public-ip show `
    --resource-group $RESOURCE_GROUP `
    --name $PUBLIC_IP_NAME `
    --query ipAddress `
    --output tsv

Write-Host "VM Details:" -ForegroundColor Cyan
Write-Host "  Resource Group: $RESOURCE_GROUP"
Write-Host "  VM Name: $VM_NAME"
Write-Host "  Admin Username: $ADMIN_USERNAME"
Write-Host "  Public IP: $PUBLIC_IP"
Write-Host ""
Write-Host "To connect via RDP:" -ForegroundColor Yellow
Write-Host "  mstsc /v:$PUBLIC_IP"
Write-Host ""
Write-Host "SQL Server Connection:" -ForegroundColor Yellow
Write-Host "  Server: $PUBLIC_IP,1433"
Write-Host "  Authentication: SQL Server or Windows Authentication"
Write-Host ""
Write-Host "Note: SQL Server configuration may need to be completed after logging in." -ForegroundColor Yellow
Write-Host ""
