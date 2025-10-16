#!/bin/bash

################################################################################
# Deployment Verification Script
# 
# This script verifies that all resources were created successfully and
# provides connection information.
################################################################################

set -e

# Variables - must match your deployment
RESOURCE_GROUP="${RESOURCE_GROUP:-sql-assessment-rg}"
VM_NAME="${VM_NAME:-sql-vm}"
PUBLIC_IP_NAME="${PUBLIC_IP_NAME:-sql-public-ip}"
NSG_NAME="${NSG_NAME:-sql-nsg}"
VNET_NAME="${VNET_NAME:-sql-vnet}"

echo "========================================"
echo "Deployment Verification Script"
echo "========================================"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed"
    echo "   Install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi
echo "✅ Azure CLI is installed"

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure"
    echo "   Run: az login"
    exit 1
fi
echo "✅ Logged in to Azure"

# Get current subscription
SUBSCRIPTION=$(az account show --query name --output tsv)
echo "✅ Using subscription: $SUBSCRIPTION"
echo ""

echo "Checking resources..."
echo ""

# Check Resource Group
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    LOCATION=$(az group show --name "$RESOURCE_GROUP" --query location --output tsv)
    echo "✅ Resource Group: $RESOURCE_GROUP (Location: $LOCATION)"
else
    echo "❌ Resource Group: $RESOURCE_GROUP not found"
    exit 1
fi

# Check Virtual Network
if az network vnet show --resource-group "$RESOURCE_GROUP" --name "$VNET_NAME" &> /dev/null; then
    ADDRESS_PREFIX=$(az network vnet show --resource-group "$RESOURCE_GROUP" --name "$VNET_NAME" --query addressSpace.addressPrefixes[0] --output tsv)
    echo "✅ Virtual Network: $VNET_NAME ($ADDRESS_PREFIX)"
else
    echo "❌ Virtual Network: $VNET_NAME not found"
fi

# Check NSG
if az network nsg show --resource-group "$RESOURCE_GROUP" --name "$NSG_NAME" &> /dev/null; then
    echo "✅ Network Security Group: $NSG_NAME"
    
    # Check RDP rule
    if az network nsg rule show --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" --name "AllowRDP" &> /dev/null; then
        echo "   ✅ RDP Rule (Port 3389) configured"
    else
        echo "   ⚠️  RDP Rule not found"
    fi
    
    # Check SQL rule
    if az network nsg rule show --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" --name "AllowSQL" &> /dev/null; then
        echo "   ✅ SQL Server Rule (Port 1433) configured"
    else
        echo "   ⚠️  SQL Server Rule not found"
    fi
else
    echo "❌ Network Security Group: $NSG_NAME not found"
fi

# Check Public IP
if az network public-ip show --resource-group "$RESOURCE_GROUP" --name "$PUBLIC_IP_NAME" &> /dev/null; then
    PUBLIC_IP=$(az network public-ip show --resource-group "$RESOURCE_GROUP" --name "$PUBLIC_IP_NAME" --query ipAddress --output tsv)
    ALLOCATION=$(az network public-ip show --resource-group "$RESOURCE_GROUP" --name "$PUBLIC_IP_NAME" --query publicIpAllocationMethod --output tsv)
    echo "✅ Public IP: $PUBLIC_IP_NAME ($PUBLIC_IP, $ALLOCATION)"
else
    echo "❌ Public IP: $PUBLIC_IP_NAME not found"
    PUBLIC_IP="NOT_FOUND"
fi

# Check VM
if az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" &> /dev/null; then
    VM_SIZE=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query hardwareProfile.vmSize --output tsv)
    POWER_STATE=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "powerState" --output tsv 2>/dev/null || echo "Unknown")
    PROVISIONING_STATE=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query provisioningState --output tsv)
    
    echo "✅ Virtual Machine: $VM_NAME"
    echo "   Size: $VM_SIZE"
    echo "   Provisioning State: $PROVISIONING_STATE"
    echo "   Power State: $POWER_STATE"
    
    # Get OS info
    OS=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "storageProfile.imageReference.offer" --output tsv)
    SKU=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query "storageProfile.imageReference.sku" --output tsv)
    echo "   OS/SQL: $OS ($SKU)"
else
    echo "❌ Virtual Machine: $VM_NAME not found"
    exit 1
fi

# Check SQL VM Extension
if az sql vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" &> /dev/null; then
    SQL_MGMT=$(az sql vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query sqlManagement --output tsv)
    LICENSE=$(az sql vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query sqlServerLicenseType --output tsv)
    echo "✅ SQL VM Extension configured"
    echo "   Management Type: $SQL_MGMT"
    echo "   License Type: $LICENSE"
else
    echo "⚠️  SQL VM Extension not configured"
fi

echo ""
echo "========================================"
echo "Summary"
echo "========================================"
echo ""

if [ "$PUBLIC_IP" != "NOT_FOUND" ]; then
    echo "🎉 Deployment is successful!"
    echo ""
    echo "Connection Information:"
    echo "─────────────────────────────────────"
    echo "Public IP Address: $PUBLIC_IP"
    echo ""
    echo "Remote Desktop (RDP):"
    echo "  Command: mstsc /v:$PUBLIC_IP"
    echo "  Port: 3389"
    echo ""
    echo "SQL Server Connection:"
    echo "  Server: $PUBLIC_IP,1433"
    echo "  Port: 1433"
    echo ""
    echo "Next Steps:"
    echo "1. Connect via RDP using the credentials you specified during deployment"
    echo "2. Open SQL Server Configuration Manager and ensure SQL Server is running"
    echo "3. Enable TCP/IP protocol if not already enabled"
    echo "4. Configure SQL Server authentication as needed"
    echo "5. Test SQL Server connectivity from your local machine"
    echo ""
    
    # Test connectivity
    echo "Testing connectivity..."
    echo ""
    
    # Test RDP port
    if command -v nc &> /dev/null; then
        if timeout 5 nc -z "$PUBLIC_IP" 3389 &> /dev/null; then
            echo "✅ RDP port (3389) is accessible"
        else
            echo "⚠️  RDP port (3389) is not accessible (might take a few minutes after VM creation)"
        fi
        
        if timeout 5 nc -z "$PUBLIC_IP" 1433 &> /dev/null; then
            echo "✅ SQL Server port (1433) is accessible"
        else
            echo "⚠️  SQL Server port (1433) is not accessible (might need configuration on the VM)"
        fi
    else
        echo "ℹ️  Install 'nc' (netcat) to test port connectivity"
    fi
else
    echo "⚠️  Deployment incomplete or Public IP not assigned"
fi

echo ""
echo "For troubleshooting, see TROUBLESHOOTING.md"
echo "========================================"
