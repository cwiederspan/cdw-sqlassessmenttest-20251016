# Getting Started

This guide walks you through deploying your first Azure SQL Server VM from scratch.

## Prerequisites Check

Before starting, ensure you have:

1. **Azure Subscription**: Active Azure subscription
2. **Azure CLI**: Installed and working
3. **Permissions**: Ability to create resources in your subscription

## Quick Validation

Run these commands to verify your setup:

```bash
# Check Azure CLI is installed
az --version

# Login to Azure
az login

# Verify you're logged in and see your subscription
az account show

# Set subscription if you have multiple (optional)
az account list --output table
az account set --subscription "Your-Subscription-Name"
```

## Deployment Options

Choose one of three methods:

### Method 1: Automated Script (Easiest)

**For Linux/Mac (Bash):**

```bash
# Download or clone the repository
git clone https://github.com/cwiederspan/cdw-sqlassessmenttest-20251016.git
cd cdw-sqlassessmenttest-20251016

# Make script executable
chmod +x create-sql-vm.sh

# Run the script
./create-sql-vm.sh
```

**For Windows (PowerShell):**

```powershell
# Download or clone the repository
git clone https://github.com/cwiederspan/cdw-sqlassessmenttest-20251016.git
cd cdw-sqlassessmenttest-20251016

# Run the script
.\create-sql-vm.ps1
```

The script will:
1. Prompt you for an admin password
2. Create all necessary resources (takes ~5-10 minutes)
3. Display connection information when complete

### Method 2: Quick Commands (Copy-Paste)

If you prefer to run commands manually, see [QUICK-COMMANDS.md](QUICK-COMMANDS.md) for a copy-paste ready sequence.

Example:
```bash
# 1. Create Resource Group
az group create --name sql-assessment-rg --location eastus

# 2. Create VM (with auto networking)
az vm create \
  --resource-group sql-assessment-rg \
  --name sql-vm \
  --image MicrosoftSQLServer:sql2012sp4-ws2012r2:standard:latest \
  --size Standard_DS3_v2 \
  --admin-username azureuser \
  --admin-password 'YourSecureP@ssw0rd123!' \
  --public-ip-sku Standard

# ... (see QUICK-COMMANDS.md for complete sequence)
```

### Method 3: Step-by-Step with Explanations

For a detailed understanding of each resource and command, follow [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md).

## After Deployment

### Step 1: Verify Deployment

Run the verification script to check all resources:

```bash
chmod +x verify-deployment.sh
./verify-deployment.sh
```

Expected output:
```
✅ Azure CLI is installed
✅ Logged in to Azure
✅ Using subscription: Your-Subscription-Name

✅ Resource Group: sql-assessment-rg (Location: eastus)
✅ Virtual Network: sql-vnet (10.0.0.0/16)
✅ Network Security Group: sql-nsg
   ✅ RDP Rule (Port 3389) configured
   ✅ SQL Server Rule (Port 1433) configured
✅ Public IP: sql-public-ip (x.x.x.x, Static)
✅ Virtual Machine: sql-vm
   Size: Standard_DS3_v2
   Power State: VM running
✅ SQL VM Extension configured

🎉 Deployment is successful!

Connection Information:
─────────────────────────────────────
Public IP Address: 52.xxx.xxx.xxx
```

### Step 2: Connect via RDP

1. **Get the public IP** from the verification output above, or run:
   ```bash
   az network public-ip show \
       --resource-group sql-assessment-rg \
       --name sql-public-ip \
       --query ipAddress \
       --output tsv
   ```

2. **Open Remote Desktop:**
   - **Windows**: Press `Win+R`, type `mstsc`, enter the IP address
   - **Mac**: Open Microsoft Remote Desktop app, add PC with the IP
   - **Linux**: Use Remmina or another RDP client

3. **Login with your credentials:**
   - Username: `azureuser` (or what you specified)
   - Password: The password you set during deployment

### Step 3: Verify SQL Server

Once connected via RDP:

1. **Check SQL Server Service:**
   - Press `Win+R`, type `services.msc`, press Enter
   - Find "SQL Server (MSSQLSERVER)"
   - Verify it's running (if not, start it)

2. **Open SQL Server Configuration Manager:**
   - Start Menu → Microsoft SQL Server 2012 → Configuration Tools → SQL Server Configuration Manager
   - Navigate to: SQL Server Network Configuration → Protocols for MSSQLSERVER
   - Ensure TCP/IP is "Enabled"
   - If you made changes, restart SQL Server service

3. **Test Local Connection:**
   - Open SQL Server Management Studio (SSMS)
   - Server name: `localhost` or `(local)`
   - Authentication: Windows Authentication
   - Click Connect

### Step 4: Configure Remote SQL Access (Optional)

If you want to connect to SQL Server from your local machine:

1. **Enable SQL Authentication** (if needed):
   - In SSMS, right-click server → Properties
   - Security → Select "SQL Server and Windows Authentication mode"
   - Restart SQL Server

2. **Create SQL Login:**
   ```sql
   CREATE LOGIN sqladmin WITH PASSWORD = 'YourStrongP@ssw0rd!';
   ALTER SERVER ROLE sysadmin ADD MEMBER sqladmin;
   ```

3. **Configure Windows Firewall** (on the VM):
   ```powershell
   New-NetFirewallRule -DisplayName "SQL Server" `
       -Direction Inbound `
       -Protocol TCP `
       -LocalPort 1433 `
       -Action Allow
   ```

4. **Test from Your Local Machine:**
   - Open SSMS on your local machine
   - Server: `<PUBLIC_IP>,1433`
   - Authentication: SQL Server Authentication
   - Login: sqladmin
   - Password: The password you created

## Common Next Steps

### For SQL Server Assessment

If you're using this for Azure SQL Migration assessment:

1. **Install Azure Data Studio** on the VM
2. **Install SQL Server Assessment extension**
3. **Run assessments** against your SQL Server instance
4. **Export results** for migration planning

### For Testing and Development

1. **Create test databases:**
   ```sql
   CREATE DATABASE TestDB;
   USE TestDB;
   -- Create tables, insert data, etc.
   ```

2. **Restore existing databases** from backups
3. **Configure SQL Server Agent** for scheduled jobs
4. **Set up maintenance plans** for backups

### For Production Preparation

1. **Configure automated backups**
2. **Set up monitoring and alerts**
3. **Implement security best practices** (see ARCHITECTURE.md)
4. **Review and restrict NSG rules** to specific IPs
5. **Enable Azure Disk Encryption**
6. **Configure Azure Backup**

## Cost Management

Your VM incurs charges while running. To minimize costs:

### Stop VM When Not in Use

```bash
# Stop (deallocate) the VM
az vm deallocate \
    --resource-group sql-assessment-rg \
    --name sql-vm

# Start VM when needed
az vm start \
    --resource-group sql-assessment-rg \
    --name sql-vm
```

**Note**: Stopping via Azure (deallocate) stops billing for compute. Shutting down from within Windows does NOT stop billing.

### Set Up Auto-Shutdown

```bash
# Schedule automatic shutdown at 7 PM
az vm auto-shutdown \
    --resource-group sql-assessment-rg \
    --name sql-vm \
    --time 1900 \
    --email "your-email@example.com"
```

### Monitor Costs

```bash
# View cost analysis
az consumption usage list \
    --start-date "2024-01-01" \
    --end-date "2024-01-31" \
    --query "[?contains(instanceName, 'sql-vm')]" \
    --output table
```

Or check in Azure Portal: Cost Management + Billing → Cost Analysis

## Troubleshooting

If you encounter issues:

1. **Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for common problems and solutions
2. **Run the verification script** to identify what's missing
3. **Check Azure Portal** for any error messages or failed deployments
4. **Review activity logs:**
   ```bash
   az monitor activity-log list \
       --resource-group sql-assessment-rg \
       --output table
   ```

## Cleanup

When you're done and want to delete everything:

```bash
# WARNING: This deletes ALL resources in the resource group
az group delete \
    --name sql-assessment-rg \
    --yes \
    --no-wait
```

This will:
- Delete the VM
- Delete all networking components
- Delete the resource group
- Stop all charges
- **Cannot be undone**

Verify deletion:
```bash
az group show --name sql-assessment-rg
# Should return: ResourceGroupNotFound
```

## Need Help?

- **Deployment Issues**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Architecture Questions**: See [ARCHITECTURE.md](ARCHITECTURE.md)
- **Quick Commands**: See [QUICK-COMMANDS.md](QUICK-COMMANDS.md)
- **Detailed Guide**: See [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md)
- **Azure Support**: https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade

## Summary

You should now have:
- ✅ A running Azure VM with SQL Server 2012 SP4
- ✅ RDP access configured and working
- ✅ SQL Server running and accessible
- ✅ Understanding of how to manage and use the VM

Happy SQL Server testing! 🎉
