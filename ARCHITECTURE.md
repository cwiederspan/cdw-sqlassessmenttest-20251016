# Azure SQL Server VM Architecture

This document describes the architecture and resources created by the deployment scripts.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Subscription                         │
│                                                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │         Resource Group: sql-assessment-rg                  │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  Virtual Network: sql-vnet (10.0.0.0/16)            │ │ │
│  │  │                                                      │ │ │
│  │  │  ┌────────────────────────────────────────────────┐ │ │ │
│  │  │  │  Subnet: sql-subnet (10.0.1.0/24)             │ │ │ │
│  │  │  │                                                │ │ │ │
│  │  │  │  ┌──────────────────────────────────────────┐ │ │ │ │
│  │  │  │  │  Network Interface: sql-nic              │ │ │ │ │
│  │  │  │  │  Private IP: 10.0.1.x                    │ │ │ │ │
│  │  │  │  │                                          │ │ │ │ │
│  │  │  │  │  ┌────────────────────────────────────┐ │ │ │ │ │
│  │  │  │  │  │  Virtual Machine: sql-vm           │ │ │ │ │ │
│  │  │  │  │  │  Size: Standard_DS3_v2             │ │ │ │ │ │
│  │  │  │  │  │  OS: Windows Server 2012 R2        │ │ │ │ │ │
│  │  │  │  │  │  SQL: SQL Server 2012 SP4 Standard │ │ │ │ │ │
│  │  │  │  │  └────────────────────────────────────┘ │ │ │ │ │
│  │  │  │  └──────────────────────────────────────────┘ │ │ │ │
│  │  │  └────────────────────────────────────────────────┘ │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  Network Security Group: sql-nsg                     │ │ │
│  │  │                                                      │ │ │
│  │  │  Inbound Rules:                                      │ │ │
│  │  │  • AllowRDP (Priority 1000)                          │ │ │
│  │  │    - Port: 3389 (TCP)                                │ │ │
│  │  │    - Source: Any                                     │ │ │
│  │  │    - Destination: Any                                │ │ │
│  │  │                                                      │ │ │
│  │  │  • AllowSQL (Priority 1001)                          │ │ │
│  │  │    - Port: 1433 (TCP)                                │ │ │
│  │  │    - Source: Any                                     │ │ │
│  │  │    - Destination: Any                                │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                            │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │  Public IP: sql-public-ip                            │ │ │
│  │  │  Type: Static                                        │ │ │
│  │  │  SKU: Standard                                       │ │ │
│  │  │  IP Address: x.x.x.x (assigned by Azure)            │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                               │
                               │ Internet
                               │
                    ┌──────────▼───────────┐
                    │   External Access    │
                    │                      │
                    │  RDP: x.x.x.x:3389   │
                    │  SQL: x.x.x.x:1433   │
                    └──────────────────────┘
```

## Resource Details

### 1. Resource Group
- **Name**: `sql-assessment-rg`
- **Location**: `eastus` (configurable)
- **Purpose**: Logical container for all resources

### 2. Virtual Network
- **Name**: `sql-vnet`
- **Address Space**: `10.0.0.0/16`
- **Purpose**: Provides network isolation and segmentation

### 3. Subnet
- **Name**: `sql-subnet`
- **Address Range**: `10.0.1.0/24`
- **Available IPs**: ~251 addresses
- **Purpose**: Hosts the VM and its network interface

### 4. Network Security Group (NSG)
- **Name**: `sql-nsg`
- **Rules**:
  - **AllowRDP**: Permits Remote Desktop Protocol connections (port 3389)
  - **AllowSQL**: Permits SQL Server connections (port 1433)
- **Purpose**: Acts as a firewall for the VM

### 5. Public IP Address
- **Name**: `sql-public-ip`
- **Type**: Static
- **SKU**: Standard
- **Purpose**: Provides internet-accessible IP for RDP and SQL connections

### 6. Network Interface (NIC)
- **Name**: `sql-nic`
- **Private IP**: Dynamically assigned from subnet range
- **Public IP**: Associated with `sql-public-ip`
- **NSG**: Attached to `sql-nsg`
- **Purpose**: Connects the VM to the virtual network

### 7. Virtual Machine
- **Name**: `sql-vm`
- **Size**: `Standard_DS3_v2`
  - vCPUs: 4
  - Memory: 14 GB RAM
  - Temp Storage: 28 GB
  - Premium Storage: Supported
- **Operating System**: Windows Server 2012 R2
- **SQL Server**: SQL Server 2012 SP4 Standard Edition
- **Admin Account**: `azureuser` (configurable)

### 8. SQL VM Extension
- **License Type**: Pay-As-You-Go (PAYG)
- **Management Type**: Full
- **Purpose**: Enables Azure SQL VM management features

## Network Flow

### Inbound Traffic (from Internet to VM)

```
Internet → Public IP → NSG (Check Rules) → NIC → VM
```

1. **RDP Connection** (Port 3389):
   - User initiates RDP connection to public IP
   - NSG checks AllowRDP rule (Priority 1000)
   - If allowed, traffic reaches VM's RDP service
   - User authenticates with VM credentials

2. **SQL Server Connection** (Port 1433):
   - Client initiates SQL connection to public IP
   - NSG checks AllowSQL rule (Priority 1001)
   - If allowed, traffic reaches SQL Server
   - Client authenticates with SQL credentials

### Outbound Traffic (from VM to Internet)

```
VM → NIC → VNet → Internet
```

- All outbound traffic is allowed by default
- VM can download updates, patches, etc.

## Security Considerations

### Current Configuration
- ✅ NSG rules restrict access to specific ports (3389, 1433)
- ✅ Static public IP for consistent access
- ✅ Password-based authentication for VM

### Recommended Enhancements (Not Implemented)

For production environments, consider:

1. **Network Security**:
   - Restrict NSG rules to specific source IP addresses
   - Use Azure Bastion for RDP access (no public IP needed)
   - Implement Just-In-Time (JIT) VM access

2. **Authentication**:
   - Use Azure AD authentication
   - Enable multi-factor authentication (MFA)
   - Implement key-based authentication

3. **Data Protection**:
   - Enable Azure Disk Encryption
   - Configure automated backups
   - Implement Azure Site Recovery

4. **Monitoring**:
   - Enable Azure Monitor
   - Configure Log Analytics workspace
   - Set up alerts for security events

5. **Compliance**:
   - Enable Azure Security Center
   - Implement Azure Policy
   - Regular security assessments

## Resource Dependencies

```
Resource Group
    └── Virtual Network
           └── Subnet
    └── Network Security Group
    └── Public IP Address
    └── Network Interface ─┬── Requires: VNet, Subnet, NSG, Public IP
    └── Virtual Machine ───┴── Requires: Network Interface
    └── SQL VM Extension ───── Requires: Virtual Machine
```

## Deployment Order

The scripts create resources in the following order to satisfy dependencies:

1. Resource Group (no dependencies)
2. Virtual Network with Subnet (requires Resource Group)
3. Network Security Group (requires Resource Group)
4. NSG Rules (requires NSG)
5. Public IP Address (requires Resource Group)
6. Network Interface (requires VNet, Subnet, NSG, Public IP)
7. Virtual Machine (requires Network Interface)
8. SQL VM Extension (requires Virtual Machine)

## Cost Breakdown (Approximate)

Based on East US pricing (as of 2024, subject to change):

| Resource | Monthly Cost (USD) |
|----------|-------------------|
| VM (Standard_DS3_v2) | ~$150-200 |
| SQL Server License (PAYG) | ~$50-100 |
| Storage (127 GB Premium SSD) | ~$20 |
| Public IP (Static) | ~$3 |
| Bandwidth (varies) | ~$5-20 |
| **Total** | **~$230-350/month** |

**Notes**:
- Costs vary by region
- Stop (deallocate) VM when not in use to reduce costs
- Consider Azure Hybrid Benefit if you have existing SQL licenses
- Dev/Test pricing available for non-production workloads

## Cleanup Process

To delete all resources and stop incurring charges:

```bash
az group delete --name sql-assessment-rg --yes --no-wait
```

This command:
1. Deletes the Resource Group
2. Automatically deletes all resources within it
3. Cannot be undone
4. Takes 5-10 minutes to complete

## Support and References

- [Azure Virtual Machines Documentation](https://docs.microsoft.com/azure/virtual-machines/)
- [SQL Server on Azure VMs](https://docs.microsoft.com/azure/azure-sql/virtual-machines/)
- [Azure Networking Documentation](https://docs.microsoft.com/azure/virtual-network/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
