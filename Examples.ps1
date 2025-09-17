# Origo.Licensing Module Examples
# Examples showing how to use the module functions with Data folder structure and auto-provisioning

# Import the module
Import-Module .\Origo.Licensing.psd1 -Force

Write-Host "=== Origo.Licensing Module Examples ===" -ForegroundColor Cyan
Write-Host "Note: All data files are automatically stored in the Data/ subfolder" -ForegroundColor Green
Write-Host ""

# Example 1: Get Microsoft licensing catalog (saves to Data/ folder automatically)
Write-Host "=== Example 1: Get License Information (Auto Data Folder) ===" -ForegroundColor Yellow
$catalogResult = @{}
Get-LicenseInformation -Output ([ref]$catalogResult)
Write-Host "Downloaded $($catalogResult.Value.TotalRecords) licensing records to: $($catalogResult.Value.OutputPath)"

# Example 2: Create service plan mapping (reads from Data/, saves to Data/)
Write-Host "`n=== Example 2: Create Service Plan Mapping (Auto Data Paths) ===" -ForegroundColor Yellow
$mappingResult = @{}
Get-ServicePlanMapping -Output ([ref]$mappingResult)
Write-Host "Mapped $($mappingResult.Value.TotalServicePlans) unique service plans"
Write-Host "Service plan mapping saved to Data/ folder"

# Example 3: Find products with AAD Premium (uses Data/ServicePlanIdToProducts.json automatically)
Write-Host "`n=== Example 3: Find AAD Premium Products (Auto Data Access) ===" -ForegroundColor Yellow
$searchResult = @{}
Find-ServicePlans -NameLike "*AAD_PREMIUM*" -Output ([ref]$searchResult)
Write-Host "Found $($searchResult.Value.ProductsWithAllPlansCount) products with AAD Premium service plans"
Write-Host "Data automatically loaded from Data/ServicePlanIdToProducts.json"

# Example 3.5: Get comprehensive service plan list 🆕
Write-Host "`n=== Example 3.5: Get All Service Plans (New Function) ===" -ForegroundColor Yellow
$servicePlanResult = @{}
Get-ServicePlan -SortBy Name -UniqueOnly -Output ([ref]$servicePlanResult)
Write-Host "Found $($servicePlanResult.Value.TotalServicePlans) total service plans ($($servicePlanResult.Value.UniqueServicePlans) unique)"
Write-Host "Sample service plans:"
$servicePlanResult.Value.ServicePlans | Select-Object -First 5 ServicePlanName, ServicePlanId, ServicePlansIncludedFriendlyNames | Format-Table

# Example 4: Get tenant license assignments with AUTO-PROVISIONING! 🚀
Write-Host "`n=== Example 4: Tenant License Assignments with Auto-Provisioning ===" -ForegroundColor Yellow
Write-Host "✨ MAGIC FEATURE: This function automatically creates missing data files!" -ForegroundColor Magenta
Write-Host "Note: Requires 'Connect-MgGraph' first with appropriate permissions" -ForegroundColor Cyan

# Uncomment the following lines after connecting to Microsoft Graph:
<#
# Connect to Microsoft Graph first
Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"

# 🎯 This single command will:
# ✅ Check for Data/ServicePlanIdToProducts.json
# ✅ If missing, automatically download catalog to Data/
# ✅ If missing, automatically create service plan mapping in Data/
# ✅ Then query tenant for license assignments
Write-Host "Running auto-provisioning tenant query..." -ForegroundColor Green

$tenantResult = @{}
Get-TenantLicenseAssignments -NameLike "*AAD_PREMIUM*" -Top 10 -Output ([ref]$tenantResult)

Write-Host "Found $($tenantResult.Value.Summary.UsersWithMatchingLicenses) users with AAD Premium licenses"
Write-Host "Total license assignments: $($tenantResult.Value.Summary.TotalMatchingAssignments)"

# Show sample results
$tenantResult.Value.LicenseAssignments | Select-Object UserDisplayName, UserPrincipalName, ProductDisplayName, TotalMatchingPlans | Format-Table
#>

# Example 5: Quick Start Demo - Everything Automatic!
Write-Host "`n=== Example 5: Quick Start with Zero Setup Required ===" -ForegroundColor Yellow
Write-Host "🚀 The easiest way to get started - just connect and query!" -ForegroundColor Green

Write-Host @"
# Quick start example (uncomment to run):
# Connect-MgGraph -Scopes "User.Read.All", "Directory.Read.All"
# Get-TenantLicenseAssignments -NameLike '*AAD_PREMIUM*' | Format-Table
# That's it! Everything else happens automatically.
"@ -ForegroundColor Cyan

# Example 6: Advanced Search Examples
Write-Host "`n=== Example 6: Advanced Search Examples ===" -ForegroundColor Yellow
Write-Host "Examples of specific searches you can perform (all with auto-provisioning):" -ForegroundColor Cyan

Write-Host @"
# Find Entra ID P2 assignments (auto-creates data files if needed)
Get-TenantLicenseAssignments -ServicePlanName 'AAD_PREMIUM_P2'

# Find all AAD Premium assignments (P1 and P2) - most common use case
Get-TenantLicenseAssignments -NameLike '*AAD_PREMIUM*'

# Find Intune assignments
Get-TenantLicenseAssignments -NameLike '*INTUNE*'

# Find specific service plan by ID
Get-TenantLicenseAssignments -ServicePlanId 'eec0eb4f-6444-4f95-aba0-50c24d67f998'

# Include disabled service plans in results
Get-TenantLicenseAssignments -NameLike '*AAD_PREMIUM*' -IncludeDisabledPlans

# Use regex for complex patterns
Get-TenantLicenseAssignments -NameRegex 'AAD_PREMIUM_P[12]'

# Save results to JSON file
Get-TenantLicenseAssignments -NameLike '*AAD_PREMIUM*' -OutFile 'AAD_Premium_Report.json'

# Save with timestamp for historical tracking
\$timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
Get-TenantLicenseAssignments -NameLike '*INTUNE*' -OutFile "Intune_Licenses_\$timestamp.json"

# Advanced service plan exploration examples
Get-ServicePlan -NameFilter '*AAD*' -SortBy FriendlyName
Get-ServicePlan -IdFilter '*premium*' -UniqueOnly
Get-ServicePlan | Where-Object ServicePlansIncludedFriendlyNames -like '*Identity*'
"@ -ForegroundColor Green

# Example 6.5: Service Plan Analysis Examples 🆕
Write-Host "`n=== Example 6.5: Service Plan Analysis (New Function) ===" -ForegroundColor Yellow
Write-Host "Examples of service plan analysis you can perform:" -ForegroundColor Cyan

Write-Host @"
# Get all AAD-related service plans
Get-ServicePlan -NameFilter '*AAD*' | Format-Table ServicePlanName, ServicePlansIncludedFriendlyNames

# Find all premium service plans
Get-ServicePlan -IdFilter '*premium*' -SortBy FriendlyName

# Get unique service plans and export to CSV
Get-ServicePlan -UniqueOnly | Export-Csv 'AllServicePlans.csv' -NoTypeInformation

# Filter service plans by friendly name content
Get-ServicePlan | Where-Object ServicePlansIncludedFriendlyNames -like '*Identity*'

# Count service plans by name pattern
(Get-ServicePlan -NameFilter '*INTUNE*').Count
"@ -ForegroundColor Green

# Example 7: File Structure Information
Write-Host "`n=== Example 7: Data Folder Structure ===" -ForegroundColor Yellow
Write-Host "After running the examples, your Data folder contains:" -ForegroundColor Cyan
if (Test-Path ".\Data") {
    Write-Host "📁 Data folder contents:" -ForegroundColor Green
    Get-ChildItem .\Data | Format-Table Name, Length, LastWriteTime -AutoSize
} else {
    Write-Host "📁 Data folder will be created automatically when functions run" -ForegroundColor Green
}

Write-Host "`n=== Module Structure Overview ===" -ForegroundColor Yellow
Write-Host @"
Origo.Licensing/
├── Origo.Licensing.psd1         # Module manifest
├── Origo.Licensing.psm1         # Core functions
├── README.md                    # Documentation
├── Examples.ps1                 # This file
└── Data/                        # Auto-created data directory
    ├── ProductLicensingCatalog.csv
    ├── ProductLicensingCatalog.json
    └── ServicePlanIdToProducts.json
"@ -ForegroundColor Cyan

Write-Host "`n=== Module Functions Summary ===" -ForegroundColor Yellow
Get-Command -Module Origo.Licensing | Format-Table Name, Synopsis