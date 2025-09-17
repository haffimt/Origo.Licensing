# Origo.Licensing PowerShell Module

A comprehensive PowerShell module for Microsoft licensing data management and service plan queries. This module provides tools to download Microsoft's licensing catalog, create service plan mappings, search for products, and query actual tenant license assignments via Microsoft Graph.

## 🚀 Features

- **📥 License Data Download**: Fetch Microsoft's official licensing catalog
- **🗺️ Service Plan Mapping**: Create mappings between service plans and products
- **🔍 Product Search**: Find products by service plan criteria with flexible search options
- **☁️ Tenant Integration**: Query actual license assignments from Microsoft 365 tenants
- **📊 Rich Output**: Structured data with output parameters and pipeline support
- **🗂️ Organized Data Storage**: All data files stored in dedicated `Data/` subfolder
- **🔄 Auto-Provisioning**: Automatically creates missing data files when needed

## 📦 Installation

### Prerequisites
- PowerShell 5.1 or later (Windows PowerShell or PowerShell Core)
- For tenant queries: Microsoft Graph PowerShell module

```powershell
# Install Microsoft Graph module (required for tenant queries)
Install-Module Microsoft.Graph.Users -Scope CurrentUser
```

### Module Installation
1. Download or clone the module files
2. Import the module:

```powershell
Import-Module .\Origo.Licensing.psd1
```

## 📁 Module Structure

The module uses a structured approach to organize data files:

```
Origo.Licensing/
├── Origo.Licensing.psd1         # Module manifest
├── Origo.Licensing.psm1         # Core functions
├── README.md                    # This documentation
├── Examples.ps1                 # Usage examples
└── Data/                        # Data files directory (auto-created)
    ├── ProductLicensingCatalog.csv
    ├── ProductLicensingCatalog.json
    └── ServicePlanIdToProducts.json
```

**Important Notes:**
- The `Data/` folder is automatically created when needed
- All functions default to using the `Data/` subfolder for file operations
- Missing data files are automatically downloaded/created when required
- You can still specify custom paths if needed for advanced scenarios

## 🛠️ Functions

### 1. `Get-LicenseInformation`
Downloads Microsoft's licensing CSV and converts it to JSON format. Files are stored in the `Data/` subfolder by default.

**Syntax:**
```powershell
Get-LicenseInformation [-Force] [-OutputPath <string>] [-Output <ref>] [-PassThru]
```

**Examples:**
```powershell
# Basic usage - downloads to Data/ folder automatically
Get-LicenseInformation

# Force re-download to Data/ folder
Get-LicenseInformation -Force

# Custom output path (advanced usage)
Get-LicenseInformation -OutputPath "C:\CustomPath"

# With output parameter
$catalogResult = @{}
Get-LicenseInformation -Output ([ref]$catalogResult)
Write-Host "Downloaded $($catalogResult.Value.TotalRecords) records"
```

### 2. `Get-ServicePlanMapping`
Creates a mapping of ServicePlanIds to products from the licensing catalog. Uses and outputs to the `Data/` subfolder by default.

**Syntax:**
```powershell
Get-ServicePlanMapping [-InputPath <string>] [-OutputPath <string>] [-Output <ref>] [-PassThru]
```

**Examples:**
```powershell
# Basic usage - reads from and writes to Data/ folder automatically
Get-ServicePlanMapping

# Will use Data/ProductLicensingCatalog.json as input and create Data/ServicePlanIdToProducts.json
Get-ServicePlanMapping

# Custom paths (advanced usage)
Get-ServicePlanMapping -InputPath "C:\Custom\ProductLicensingCatalog.json" -OutputPath "C:\Custom"

# With output parameter
$mappingResult = @{}
Get-ServicePlanMapping -Output ([ref]$mappingResult)
```

### 3. `Find-ServicePlans`
Searches for products that contain specific service plans. Automatically uses `Data/ServicePlanIdToProducts.json`.

**Syntax:**
```powershell
Find-ServicePlans [-ServicePlanId <string[]>] [-NameLike <string[]>] [-NameRegex <string[]>] 
                  [-Top <int>] [-ShowPlanSummary] [-JsonPath <string>] [-Output <ref>] [-PassThru]
```

**Examples:**
```powershell
# Find products with AAD Premium service plans (uses Data/ServicePlanIdToProducts.json automatically)
Find-ServicePlans -NameLike "*AAD_PREMIUM*"

# Find Entra ID P2 specifically
Find-ServicePlans -ServicePlanName "AAD_PREMIUM_P2"

# Use regex for P1 and P2
Find-ServicePlans -NameRegex "AAD_PREMIUM_P[12]"

# Custom data file path (advanced usage)
Find-ServicePlans -NameLike "*INTUNE*" -JsonPath "C:\Custom\ServicePlanIdToProducts.json"

# With output parameter and summary
$searchResult = @{}
Find-ServicePlans -NameLike "*INTUNE*" -ShowPlanSummary -Output ([ref]$searchResult)
```

### 4. `Get-TenantLicenseAssignments` 🆕
Retrieves actual license assignments from Microsoft 365 tenant via Microsoft Graph. **Features intelligent auto-provisioning** - automatically creates missing data files when needed.

**Syntax:**
```powershell
Get-TenantLicenseAssignments [-ServicePlanName <string[]>] [-ServicePlanId <string[]>] 
                             [-NameLike <string[]>] [-NameRegex <string[]>] 
                             [-IncludeDisabledPlans] [-Top <int>] [-Output <ref>] [-PassThru] 
                             [-OutFile <string>]
```

**Prerequisites:**
```powershell
# Connect to Microsoft Graph with required permissions
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"
```

**Auto-Provisioning Feature:**
This function automatically detects and creates missing data files:
- If `Data/ServicePlanIdToProducts.json` is missing, it automatically downloads the catalog and creates the mapping
- If `Data/ProductLicensingCatalog.json` is missing, it downloads it first
- No manual file management required - everything happens automatically!

**Examples:**
```powershell
# Find all users with AAD Premium licenses
Get-TenantLicenseAssignments -NameLike "*AAD_PREMIUM*"

# Find specific Entra ID P2 assignments
Get-TenantLicenseAssignments -ServicePlanName "AAD_PREMIUM_P2"

# Search with multiple criteria
Get-TenantLicenseAssignments -NameRegex "AAD_PREMIUM_P[12]" -ServicePlanId "eec0eb4f-6444-4f95-aba0-50c24d67f998"

# Include disabled service plans
Get-TenantLicenseAssignments -NameLike "*INTUNE*" -IncludeDisabledPlans

# Limit results for testing
Get-TenantLicenseAssignments -NameLike "*AAD_PREMIUM*" -Top 10

# Save results to JSON file
Get-TenantLicenseAssignments -NameLike "*AAD_PREMIUM*" -OutFile "AAD_Premium_Licenses.json"

# Save to custom location with timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
Get-TenantLicenseAssignments -NameLike "*INTUNE*" -OutFile "Reports\Intune_Licenses_$timestamp.json"

# With output parameter
$tenantResult = @{}
Get-TenantLicenseAssignments -NameLike "*AAD_PREMIUM*" -Output ([ref]$tenantResult)
Write-Host "Found $($tenantResult.Value.Summary.UsersWithMatchingLicenses) users"
```

### 5. `Get-ServicePlan` 🆕
Gets a comprehensive list of all Microsoft service plans from the licensing catalog, providing ServicePlanName, ServicePlanId, and ServicePlansIncludedFriendlyNames.

**Syntax:**
```powershell
Get-ServicePlan [-InputPath <string>] [-NameFilter <string>] [-IdFilter <string>] 
                [-SortBy <string>] [-UniqueOnly] [-Output <ref>] [-PassThru]
```

**Examples:**
```powershell
# Get all service plans (uses Data/ProductLicensingCatalog.json automatically)
Get-ServicePlan

# Filter by name pattern
Get-ServicePlan -NameFilter "*AAD*"

# Get unique service plans only, sorted by friendly name
Get-ServicePlan -SortBy FriendlyName -UniqueOnly

# Filter by service plan ID pattern
Get-ServicePlan -IdFilter "*premium*"

# Save results and show in pipeline
$servicePlans = @{}
Get-ServicePlan -Output ([ref]$servicePlans) -PassThru | Format-Table ServicePlanName, ServicePlanId, ServicePlansIncludedFriendlyNames

# Custom input path
Get-ServicePlan -InputPath "C:\Custom\ProductLicensingCatalog.json" -SortBy Name
```

## 📋 Common Service Plan Names

Here are some common service plan names you can search for:

| Service Plan Name | Description |
|-------------------|-------------|
| `AAD_PREMIUM` | Azure Active Directory Premium P1 |
| `AAD_PREMIUM_P2` | Azure Active Directory Premium P2 |
| `INTUNE_A` | Microsoft Intune |
| `EXCHANGE_S_ENTERPRISE` | Exchange Online (Plan 2) |
| `SHAREPOINTENTERPRISE` | SharePoint Online (Plan 2) |
| `OFFICESUBSCRIPTION` | Microsoft 365 Apps |
| `MCOSTANDARD` | Microsoft Teams |
| `POWER_BI_PRO` | Power BI Pro |

## 🔧 Usage Workflows

### Workflow 1: Complete Licensing Analysis
```powershell
# 1. Import module
Import-Module .\Origo.Licensing.psd1 -Force

# 2. Download licensing catalog (saves to Data/ folder automatically)
$catalog = @{}
Get-LicenseInformation -Output ([ref]$catalog)

# 3. Create service plan mapping (reads from Data/, saves to Data/)
$mapping = @{}
Get-ServicePlanMapping -Output ([ref]$mapping)

# 4. Find products with AAD Premium (uses Data/ServicePlanIdToProducts.json)
$products = @{}
Find-ServicePlans -NameLike "*AAD_PREMIUM*" -Output ([ref]$products)

# 5. Get actual tenant assignments (auto-creates missing files if needed!)
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"
$assignments = @{}
Get-TenantLicenseAssignments -NameLike "*AAD_PREMIUM*" -Output ([ref]$assignments)

# 6. Display results
Write-Host "Catalog: $($catalog.Value.TotalRecords) records"
Write-Host "Mapping: $($mapping.Value.TotalServicePlans) service plans"
Write-Host "Products: $($products.Value.ProductsWithAllPlansCount) AAD Premium products"
Write-Host "Assignments: $($assignments.Value.Summary.UsersWithMatchingLicenses) users with AAD Premium"
```

### Workflow 2: Quick Start with Auto-Provisioning 🚀
```powershell
# The easiest way - everything happens automatically!
Import-Module .\Origo.Licensing.psd1 -Force
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"

# This single command will:
# - Check for Data/ServicePlanIdToProducts.json
# - If missing, automatically download catalog and create mapping
# - Then query tenant for license assignments
$result = @{}
Get-TenantLicenseAssignments -NameLike "*AAD_PREMIUM*" -Output ([ref]$result)
Write-Host "Found $($result.Value.Summary.UsersWithMatchingLicenses) users with AAD Premium"
```

### Workflow 3: Tenant License Audit
```powershell
# Connect to tenant
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"

# Check different license types (all with auto-provisioning)
$aadPremium = @{}
Get-TenantLicenseAssignments -NameLike "*AAD_PREMIUM*" -Output ([ref]$aadPremium)

$intune = @{}
Get-TenantLicenseAssignments -NameLike "*INTUNE*" -Output ([ref]$intune)

$exchange = @{}
Get-TenantLicenseAssignments -NameLike "*EXCHANGE*" -Output ([ref]$exchange)

# Generate summary report
Write-Host "=== License Assignment Summary ===" -ForegroundColor Green
Write-Host "AAD Premium: $($aadPremium.Value.Summary.UsersWithMatchingLicenses) users"
Write-Host "Intune: $($intune.Value.Summary.UsersWithMatchingLicenses) users"
Write-Host "Exchange: $($exchange.Value.Summary.UsersWithMatchingLicenses) users"
```

## 📊 Output Structure

### Get-LicenseInformation Output
```powershell
@{
    SourceUrl = "https://download.microsoft.com/..."
    OutputPath = "C:\Path\To\Origo.Licensing\Data\ProductLicensingCatalog.json"
    TotalRecords = 5785
    ProcessedAt = "2025-09-16T10:30:00Z"
    Success = $true
}
```

### Get-TenantLicenseAssignments Output
```powershell
@{
    SearchCriteria = @{
        ServicePlanNames = @("AAD_PREMIUM")
        TargetServicePlanIds = @("41781fb2-bc02-4b7c-bd55-b576c07bb09d")
    }
    Summary = @{
        TotalUsersProcessed = 150
        UsersWithMatchingLicenses = 45
        TotalMatchingAssignments = 52
        UniqueSkusFound = 3
    }
    LicenseAssignments = @(
        @{
            UserId = "user-guid"
            UserDisplayName = "John Doe"
            UserPrincipalName = "john@contoso.com"
            SkuId = "sku-guid"
            SkuPartNumber = "ENTERPRISEPACK"
            ProductDisplayName = "Office 365 E3"
            MatchingServicePlans = @(...)
            TotalMatchingPlans = 1
            EnabledMatchingPlans = 1
        }
    )
    TenantInfo = @{
        TenantId = "tenant-guid"
        ConnectedAs = "admin@contoso.com"
        RetrievedAt = "2025-09-16T10:35:00Z"
    }
}
```

## 🔒 Permissions Required

For tenant license queries, the following Microsoft Graph permissions are required:

- **User.Read.All**: Read user profiles and license assignments
- **Directory.Read.All**: Read directory data including SKU information

## 🐛 Troubleshooting

### Common Issues

1. **"Not connected to Microsoft Graph"**
   ```powershell
   Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"
   ```

2. **"Microsoft.Graph.Users module is required"**
   ```powershell
   Install-Module Microsoft.Graph.Users -Scope CurrentUser
   ```

3. **"Service plan mapping not found"**
   - This should no longer happen! The `Get-TenantLicenseAssignments` function now automatically creates missing files
   - For manual creation: Run `Get-ServicePlanMapping` 
   - The mapping file will be created in the `Data/` folder automatically

4. **Permission errors**
   - Ensure your account has appropriate admin permissions in the tenant
   - Check that consent has been granted for the required Graph scopes

## 📄 License

Copyright (c) 2025 Origo. All rights reserved.

## 🤝 Contributing

This module is part of the Origo toolkit for Microsoft 365 and Azure management.

## 📞 Support

For issues and questions, please refer to your organization's internal support channels.

---

**Version:** 0.0.1  
**Compatible with:** PowerShell 5.1+, PowerShell Core  
**Dependencies:** Microsoft.Graph.Users (for tenant queries)