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
RESOURCE_GROUP="sql-assessment-rg"
LOCATION="eastus"
VNET_NAME="sql-vnet"
SUBNET_NAME="sql-subnet"
NSG_NAME="sql-nsg"
PUBLIC_IP_NAME="sql-public-ip"
NIC_NAME="sql-nic"
VM_NAME="sql-vm"
VM_SIZE="Standard_DS3_v2"  # 4 cores, 14GB RAM - good for SQL Server
ADMIN_USERNAME="azureuser"
ADMIN_PASSWORD=""  # Will be prompted or set below

# SQL Server Image details (SQL Server 2012 SP4 on Windows Server 2012 R2)
# This is one of the older SQL Server versions available in Azure
IMAGE_URN="MicrosoftSQLServer:sql2012sp4-ws2012r2:standard:latest"

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
echo "Step 3: Creating Network Security Group..."
az network nsg create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$NSG_NAME" \
    --output table

echo ""
echo "Step 4: Creating NSG rule to allow RDP (port 3389)..."
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "AllowRDP" \
    --priority 1000 \
    --protocol Tcp \
    --destination-port-ranges 3389 \
    --access Allow \
    --direction Inbound \
    --description "Allow RDP access" \
    --output table

echo ""
echo "Step 5: Creating NSG rule to allow SQL Server (port 1433)..."
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "AllowSQL" \
    --priority 1001 \
    --protocol Tcp \
    --destination-port-ranges 1433 \
    --access Allow \
    --direction Inbound \
    --description "Allow SQL Server access" \
    --output table

echo ""
echo "Step 6: Creating Public IP Address..."
az network public-ip create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$PUBLIC_IP_NAME" \
    --allocation-method Static \
    --sku Standard \
    --output table

echo ""
echo "Step 7: Creating Network Interface..."
az network nic create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$NIC_NAME" \
    --vnet-name "$VNET_NAME" \
    --subnet "$SUBNET_NAME" \
    --network-security-group "$NSG_NAME" \
    --public-ip-address "$PUBLIC_IP_NAME" \
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

# Get the public IP address
PUBLIC_IP=$(az network public-ip show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$PUBLIC_IP_NAME" \
    --query ipAddress \
    --output tsv)

echo "VM Details:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  VM Name: $VM_NAME"
echo "  Admin Username: $ADMIN_USERNAME"
echo "  Public IP: $PUBLIC_IP"
echo ""
echo "To connect via RDP:"
echo "  mstsc /v:$PUBLIC_IP"
echo ""
echo "To SSH to the VM (if configured):"
echo "  ssh $ADMIN_USERNAME@$PUBLIC_IP"
echo ""
echo "SQL Server Connection:"
echo "  Server: $PUBLIC_IP,1433"
echo "  Authentication: SQL Server or Windows Authentication"
echo ""
echo "Note: SQL Server configuration may need to be completed after logging in."
echo ""
