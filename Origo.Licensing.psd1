@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Origo.Licensing.psm1'
    
    # Version number of this module.
    ModuleVersion = '0.0.1'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'f47ac10b-58cc-4372-a567-0e02b2c3d479'
    
    # Author of this module
    Author = 'Origo'
    
    # Company or vendor of this module
    CompanyName = 'Origo'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Origo. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'PowerShell module for Microsoft licensing data management and service plan queries.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Get-LicenseInformation',
        'Get-ServicePlanMapping', 
        'Find-ServicePlans',
        'Get-TenantLicenseAssignments',
        'Get-ServicePlan'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()
    
    # DSC resources to export from this module
    # DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # List of all files packaged with this module
    # FileList = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Microsoft', 'Licensing', 'ServicePlans', 'M365', 'Azure', 'Origo')
            
            # A URL to the license for this module.
            # LicenseUri = ''
            
            # A URL to the main website for this project.
            # ProjectUri = ''
            
            # A URL to an icon representing this module.
            # IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
# Origo.Licensing 0.0.1

## New Features
- Get-LicenseInformation: Download and convert Microsoft licensing CSV to JSON
- Get-ServicePlanMapping: Map ServicePlanIds to products from licensing catalog  
- Find-ServicePlans: Query products by service plan criteria with flexible search options
- Get-TenantLicenseAssignments: Retrieve actual license assignments from Microsoft 365 tenant via Microsoft Graph

## Functions
- Support for output parameters to capture structured data
- Robust error handling and validation
- JSON-based caching for performance
- Wildcard, regex, and exact ID search capabilities
- Microsoft Graph integration for live tenant data
- Service plan filtering for real license assignments
'@
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}