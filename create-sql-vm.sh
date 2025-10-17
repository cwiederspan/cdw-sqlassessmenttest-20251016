#!/bin/bash

################################################################################
# Azure SQL Server VM Deployment Script
# 
# This script creates an Azure VM running SQL Server with all necessary 
# networking components including RDP access.
#
# Prerequisites:
# - Azure CLI installed and logged in (az login)
# - Sufficient permissions to create resources
################################################################################

set -e  # Exit on any error

# Variables - Customize these as needed
RESOURCE_GROUP="cdw-sqlassessment-20251017"
LOCATION="westus3"
VNET_NAME="sql-vnet"
SUBNET_NAME="sql-subnet"
BASTION_SUBNET_NAME="AzureBastionSubnet"  # Must be exactly this name
NSG_NAME="sql-nsg"
BASTION_NAME="sql-bastion"
BASTION_PUBLIC_IP_NAME="bastion-public-ip"
NIC_NAME="sql-nic"
VM_NAME="sql-vm"
VM_SIZE="Standard_DS3_v2"  # 4 cores, 14GB RAM - good for SQL Server
ADMIN_USERNAME="azureuser"
ADMIN_PASSWORD=""  # Will be prompted or set below

# SQL Server Image details (SQL Server 2019 on Windows Server 2019)
IMAGE_URN="MicrosoftSQLServer:sql2019-ws2019:standard:latest"

echo "========================================"
echo "Azure SQL Server VM Deployment Script"
echo "========================================"
echo ""

# Prompt for admin password if not set
if [ -z "$ADMIN_PASSWORD" ]; then
    echo "Please enter a password for the VM admin user ($ADMIN_USERNAME):"
    echo "Password must be 12-72 characters and meet complexity requirements"
    echo "(uppercase, lowercase, number, and special character)"
    read -s ADMIN_PASSWORD
    echo ""
fi

echo "Step 1: Creating Resource Group..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output table

echo ""
echo "Step 2: Creating Virtual Network and Subnet..."
az network vnet create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VNET_NAME" \
    --address-prefix 10.0.0.0/16 \
    --subnet-name "$SUBNET_NAME" \
    --subnet-prefix 10.0.1.0/24 \
    --output table

echo ""
echo "Step 2b: Creating Azure Bastion Subnet..."
az network vnet subnet create \
    --resource-group "$RESOURCE_GROUP" \
    --vnet-name "$VNET_NAME" \
    --name "$BASTION_SUBNET_NAME" \
    --address-prefix 10.0.2.0/27 \
    --output table

echo ""
echo "Step 3: Creating Network Security Group..."
az network nsg create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$NSG_NAME" \
    --output table

echo ""
echo "Step 4: Creating NSG rule to allow SQL Server (port 1433) from VNet..."
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "AllowSQL" \
    --priority 1001 \
    --protocol Tcp \
    --destination-port-ranges 1433 \
    --source-address-prefixes "10.0.0.0/16" \
    --access Allow \
    --direction Inbound \
    --description "Allow SQL Server access from VNet" \
    --output table

echo ""
echo "Step 5: Creating Public IP Address for Bastion..."
az network public-ip create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BASTION_PUBLIC_IP_NAME" \
    --allocation-method Static \
    --sku Standard \
    --output table

echo ""
echo "Step 6: Creating Azure Bastion Host..."
echo "This may take several minutes..."
az network bastion create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BASTION_NAME" \
    --public-ip-address "$BASTION_PUBLIC_IP_NAME" \
    --vnet-name "$VNET_NAME" \
    --location "$LOCATION" \
    --output table

echo ""
echo "Step 7: Creating Network Interface (without public IP)..."
az network nic create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$NIC_NAME" \
    --vnet-name "$VNET_NAME" \
    --subnet "$SUBNET_NAME" \
    --network-security-group "$NSG_NAME" \
    --output table

echo ""
echo "Step 8: Creating SQL Server VM..."
echo "This may take several minutes..."
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --location "$LOCATION" \
    --nics "$NIC_NAME" \
    --size "$VM_SIZE" \
    --image "$IMAGE_URN" \
    --admin-username "$ADMIN_USERNAME" \
    --admin-password "$ADMIN_PASSWORD" \
    --output table

echo ""
echo "Step 9: Configuring SQL Server VM extension..."
az sql vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --license-type PAYG \
    --sql-mgmt-type Full \
    --output table

echo ""
echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""

# Get the VM's private IP address
PRIVATE_IP=$(az vm show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --show-details \
    --query privateIps \
    --output tsv)

# Get the Bastion public IP address
BASTION_PUBLIC_IP=$(az network public-ip show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$BASTION_PUBLIC_IP_NAME" \
    --query ipAddress \
    --output tsv)

echo "VM Details:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  VM Name: $VM_NAME"
echo "  Admin Username: $ADMIN_USERNAME"
echo "  Private IP: $PRIVATE_IP"
echo "  Bastion Public IP: $BASTION_PUBLIC_IP"
echo ""
echo "To connect via Azure Bastion:"
echo "  1. Go to Azure Portal (https://portal.azure.com)"
echo "  2. Navigate to your VM: $VM_NAME"
echo "  3. Click 'Connect' → 'Bastion'"
echo "  4. Enter credentials:"
echo "     Username: $ADMIN_USERNAME"
echo "     Password: [your password]"
echo ""
echo "Or use Azure CLI:"
echo "  az network bastion rdp --name $BASTION_NAME --resource-group $RESOURCE_GROUP --target-resource-id /subscriptions/[subscription-id]/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/$VM_NAME"
echo ""
echo "SQL Server Connection (from within VNet or via VPN):"
echo "  Server: $PRIVATE_IP,1433"
echo "  Authentication: SQL Server or Windows Authentication"
echo ""
echo "Note: SQL Server is only accessible from within the VNet for security."
echo "Note: SQL Server configuration may need to be completed after logging in."
echo ""
