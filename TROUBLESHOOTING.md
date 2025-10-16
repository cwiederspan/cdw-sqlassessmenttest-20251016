# Troubleshooting Guide

This guide helps you resolve common issues when deploying and connecting to your Azure SQL Server VM.

## Deployment Issues

### Issue: Azure CLI Not Found

**Symptom**: `az: command not found`

**Solution**:
```bash
# Install Azure CLI on Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install on macOS
brew update && brew install azure-cli

# Install on Windows (PowerShell as Administrator)
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
```

### Issue: Not Logged In to Azure

**Symptom**: `Please run 'az login' to access your accounts`

**Solution**:
```bash
# Login with interactive browser
az login

# Login with device code (for headless systems)
az login --use-device-code

# Login with service principal
az login --service-principal --username APP_ID --password PASSWORD --tenant TENANT_ID
```

### Issue: Wrong Subscription

**Symptom**: Resources appearing in wrong subscription or insufficient permissions

**Solution**:
```bash
# List all subscriptions
az account list --output table

# Set the correct subscription
az account set --subscription "Your-Subscription-Name"

# Verify current subscription
az account show --output table
```

### Issue: Resource Group Already Exists

**Symptom**: `The Resource Group 'sql-assessment-rg' already exists`

**Solution**:
```bash
# Option 1: Use a different resource group name
# Edit the variable in the script or commands:
RESOURCE_GROUP="sql-assessment-rg-2"

# Option 2: Delete existing resource group (WARNING: deletes all resources)
az group delete --name sql-assessment-rg --yes

# Option 3: Use existing resource group (skip the creation step)
```

### Issue: VM Name Already Exists

**Symptom**: `Virtual machine name 'sql-vm' is already taken`

**Solution**:
```bash
# Use a unique VM name
VM_NAME="sql-vm-$(date +%Y%m%d%H%M%S)"

# Or choose a custom name
VM_NAME="my-sql-server-vm"
```

### Issue: Quota Exceeded

**Symptom**: `Operation could not be completed as it results in exceeding approved cores quota`

**Solution**:
1. Request quota increase in Azure Portal:
   - Go to Subscriptions → Usage + quotas
   - Select the appropriate region and VM family
   - Request quota increase

2. Or use a smaller VM size:
   ```bash
   # Use Standard_D2s_v3 instead (2 vCPUs, 8GB RAM)
   VM_SIZE="Standard_D2s_v3"
   ```

### Issue: Image Not Available in Region

**Symptom**: `The image is not available in region`

**Solution**:
```bash
# Check available images in your region
az vm image list \
    --publisher MicrosoftSQLServer \
    --location eastus \
    --output table

# Or change to a different region
LOCATION="westus2"
```

### Issue: Invalid Password

**Symptom**: `The supplied password does not meet complexity requirements`

**Solution**:
Password must meet these requirements:
- 12-72 characters long
- Contains at least 3 of the following:
  - Uppercase letter (A-Z)
  - Lowercase letter (a-z)
  - Number (0-9)
  - Special character (!@#$%^&*()_+-=[]{}|;:,.<>?)

Example strong password: `MyP@ssw0rd2024!`

## Connection Issues

### Issue: Cannot RDP to VM

**Symptom**: RDP connection times out or refuses

**Checklist**:

1. **Verify VM is running**:
   ```bash
   az vm show \
       --resource-group sql-assessment-rg \
       --name sql-vm \
       --query "powerState" \
       --output tsv
   ```
   Should return: `VM running`

2. **Start VM if stopped**:
   ```bash
   az vm start \
       --resource-group sql-assessment-rg \
       --name sql-vm
   ```

3. **Verify public IP**:
   ```bash
   az network public-ip show \
       --resource-group sql-assessment-rg \
       --name sql-public-ip \
       --query ipAddress \
       --output tsv
   ```

4. **Check NSG rules**:
   ```bash
   az network nsg rule list \
       --resource-group sql-assessment-rg \
       --nsg-name sql-nsg \
       --output table
   ```
   Verify AllowRDP rule exists with port 3389

5. **Test port connectivity**:
   ```bash
   # Linux/Mac
   nc -zv <PUBLIC_IP> 3389
   
   # Windows PowerShell
   Test-NetConnection -ComputerName <PUBLIC_IP> -Port 3389
   ```

6. **Add RDP rule if missing**:
   ```bash
   az network nsg rule create \
       --resource-group sql-assessment-rg \
       --nsg-name sql-nsg \
       --name AllowRDP \
       --priority 1000 \
       --protocol Tcp \
       --destination-port-ranges 3389 \
       --access Allow
   ```

7. **Check your local firewall**: Ensure outbound connections on port 3389 are allowed

8. **Try JIT Access** (if configured):
   ```bash
   az security jit-policy create \
       --location eastus \
       --name sql-vm-jit \
       --resource-group sql-assessment-rg \
       --virtual-machines sql-vm
   ```

### Issue: Wrong RDP Credentials

**Symptom**: `Your credentials did not work` or `Login failed`

**Solution**:
- Username is what you specified (default: `azureuser`)
- Password is what you set during VM creation
- Try prepending VM name: `sql-vm\azureuser`
- Reset password if needed:
  ```bash
  az vm user update \
      --resource-group sql-assessment-rg \
      --name sql-vm \
      --username azureuser \
      --password 'NewSecureP@ssw0rd123!'
  ```

### Issue: Cannot Connect to SQL Server

**Symptom**: SQL Server connection fails from external client

**Common Causes and Solutions**:

1. **SQL Server not started**:
   - RDP into the VM
   - Open Services (services.msc)
   - Find "SQL Server (MSSQLSERVER)"
   - Start the service if stopped
   - Set startup type to "Automatic"

2. **SQL Server not listening on TCP/IP**:
   - RDP into the VM
   - Open "SQL Server Configuration Manager"
   - Go to "SQL Server Network Configuration" → "Protocols for MSSQLSERVER"
   - Enable "TCP/IP" protocol
   - Restart SQL Server service

3. **Firewall blocking connection**:
   - RDP into the VM
   - Run PowerShell as Administrator:
     ```powershell
     New-NetFirewallRule -DisplayName "SQL Server" `
         -Direction Inbound `
         -Protocol TCP `
         -LocalPort 1433 `
         -Action Allow
     ```

4. **SQL Authentication not enabled**:
   - RDP into the VM
   - Open SQL Server Management Studio (SSMS)
   - Connect to local instance
   - Right-click server → Properties → Security
   - Select "SQL Server and Windows Authentication mode"
   - Restart SQL Server service

5. **No SQL login created**:
   ```sql
   -- Run in SSMS on the VM
   CREATE LOGIN [sqladmin] WITH PASSWORD = 'YourP@ssw0rd123!';
   ALTER SERVER ROLE sysadmin ADD MEMBER [sqladmin];
   ```

6. **NSG not allowing SQL port**:
   ```bash
   az network nsg rule create \
       --resource-group sql-assessment-rg \
       --nsg-name sql-nsg \
       --name AllowSQL \
       --priority 1001 \
       --protocol Tcp \
       --destination-port-ranges 1433 \
       --access Allow
   ```

## Performance Issues

### Issue: VM Running Slowly

**Solutions**:

1. **Check VM size is appropriate**:
   ```bash
   az vm show \
       --resource-group sql-assessment-rg \
       --name sql-vm \
       --query "hardwareProfile.vmSize" \
       --output tsv
   ```

2. **Resize VM if needed** (VM must be stopped):
   ```bash
   # Stop VM
   az vm deallocate \
       --resource-group sql-assessment-rg \
       --name sql-vm
   
   # Resize
   az vm resize \
       --resource-group sql-assessment-rg \
       --name sql-vm \
       --size Standard_DS4_v2
   
   # Start VM
   az vm start \
       --resource-group sql-assessment-rg \
       --name sql-vm
   ```

3. **Check available sizes in your region**:
   ```bash
   az vm list-sizes --location eastus --output table
   ```

### Issue: Disk Performance Issues

**Solution**:
Consider upgrading to Premium SSD or Ultra Disk:

```bash
# List current disks
az vm show \
    --resource-group sql-assessment-rg \
    --name sql-vm \
    --query "storageProfile.osDisk" \
    --output json

# Create and attach a new Premium SSD data disk
az vm disk attach \
    --resource-group sql-assessment-rg \
    --vm-name sql-vm \
    --name sql-data-disk \
    --size-gb 128 \
    --sku Premium_LRS \
    --new
```

## Monitoring and Diagnostics

### Enable Boot Diagnostics

```bash
# Create storage account for diagnostics
az storage account create \
    --name sqlvmdiag$(date +%s) \
    --resource-group sql-assessment-rg \
    --location eastus \
    --sku Standard_LRS

# Enable boot diagnostics
az vm boot-diagnostics enable \
    --resource-group sql-assessment-rg \
    --name sql-vm \
    --storage https://<storage-account-name>.blob.core.windows.net/
```

### View VM Logs

```bash
# Get boot diagnostics
az vm boot-diagnostics get-boot-log \
    --resource-group sql-assessment-rg \
    --name sql-vm

# Get serial console output
az vm get-instance-view \
    --resource-group sql-assessment-rg \
    --name sql-vm
```

### Check VM Metrics

```bash
# Install Azure Monitor extension
az vm extension set \
    --resource-group sql-assessment-rg \
    --vm-name sql-vm \
    --name AzureMonitorWindowsAgent \
    --publisher Microsoft.Azure.Monitor

# View CPU usage (requires monitoring configured)
az monitor metrics list \
    --resource "/subscriptions/<subscription-id>/resourceGroups/sql-assessment-rg/providers/Microsoft.Compute/virtualMachines/sql-vm" \
    --metric "Percentage CPU" \
    --output table
```

## Cost Management Issues

### Issue: Unexpected High Costs

**Investigation**:

1. **Check current costs**:
   - Go to Azure Portal → Cost Management + Billing
   - View cost analysis for the resource group

2. **Stop VM when not in use**:
   ```bash
   # Stop (deallocate) VM
   az vm deallocate \
       --resource-group sql-assessment-rg \
       --name sql-vm
   
   # Start VM when needed
   az vm start \
       --resource-group sql-assessment-rg \
       --name sql-vm
   ```

3. **Set up auto-shutdown**:
   ```bash
   az vm auto-shutdown \
       --resource-group sql-assessment-rg \
       --name sql-vm \
       --time 1900 \
       --email "your-email@example.com"
   ```

4. **Use Azure Hybrid Benefit** (if you have existing licenses):
   ```bash
   az vm update \
       --resource-group sql-assessment-rg \
       --name sql-vm \
       --license-type Windows_Server
   
   az sql vm update \
       --resource-group sql-assessment-rg \
       --name sql-vm \
       --license-type AHUB
   ```

## Cleanup Issues

### Issue: Cannot Delete Resource Group

**Symptom**: Resource group deletion fails or hangs

**Solution**:

1. **Check for locks**:
   ```bash
   az lock list \
       --resource-group sql-assessment-rg \
       --output table
   
   # Delete lock if found
   az lock delete \
       --name <lock-name> \
       --resource-group sql-assessment-rg
   ```

2. **Force delete**:
   ```bash
   # Stop all VMs first
   az vm stop \
       --resource-group sql-assessment-rg \
       --name sql-vm
   
   # Then delete with force
   az group delete \
       --name sql-assessment-rg \
       --yes \
       --no-wait
   ```

3. **Delete individual resources**:
   ```bash
   # If resource group won't delete, remove resources one by one
   az vm delete --resource-group sql-assessment-rg --name sql-vm --yes
   az network nic delete --resource-group sql-assessment-rg --name sql-nic
   az network public-ip delete --resource-group sql-assessment-rg --name sql-public-ip
   # ... etc
   ```

## Getting Help

### Azure Support Resources

1. **Azure Documentation**: https://docs.microsoft.com/azure/
2. **Azure CLI Reference**: https://docs.microsoft.com/cli/azure/
3. **Azure Support Portal**: https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade
4. **Azure Community**: https://techcommunity.microsoft.com/t5/azure/ct-p/Azure
5. **Stack Overflow**: https://stackoverflow.com/questions/tagged/azure

### Useful Commands for Diagnostics

```bash
# Get all resources in resource group
az resource list \
    --resource-group sql-assessment-rg \
    --output table

# Get VM details
az vm show \
    --resource-group sql-assessment-rg \
    --name sql-vm \
    --output json

# Get network configuration
az network nic show \
    --resource-group sql-assessment-rg \
    --name sql-nic \
    --output json

# Get NSG rules
az network nsg rule list \
    --resource-group sql-assessment-rg \
    --nsg-name sql-nsg \
    --output table

# Get activity logs
az monitor activity-log list \
    --resource-group sql-assessment-rg \
    --output table
```

### Contact Information

For issues specific to this repository:
- Open an issue on GitHub
- Contact repository maintainers

For Azure-specific issues:
- Use Azure Support Portal
- Check Azure Service Health: https://status.azure.com/
