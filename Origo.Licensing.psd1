@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Origo.Licensing.psm1'
    
    # Version number of this module.
    ModuleVersion = '0.0.5'
    
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
# SIG # Begin signature block
# MIIFqgYJKoZIhvcNAQcCoIIFmzCCBZcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAMNG8EO2qYAX3R
# nE4ePCCDxAEEk1XWHXrThH0Ix7cr7aCCAxgwggMUMIIB/KADAgECAhAeHMcshzIp
# sELzmDMFfp8iMA0GCSqGSIb3DQEBCwUAMCIxIDAeBgNVBAMMF1Bvd2VyU2hlbGwg
# Q29kZSBTaWduaW5nMB4XDTI1MDkxNzE2MTI1NVoXDTI4MDkxNzE2MjI1NVowIjEg
# MB4GA1UEAwwXUG93ZXJTaGVsbCBDb2RlIFNpZ25pbmcwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQC+PddqokE+InGoIkq47ieQAIa1W00Vcss9Crs3XKH0
# bWB5NklgAGjWQGsFmEjY+0+Cy1tco/ePfsFv1/4/E9r/Wqy/u/onBXhFDviVg0v5
# DsR2KcaiFniXjLRFx4Y6BDhFYp/hN45LKxWDencvDycd9KA4xc6e+nvV4uyBCrfz
# wmm6oRjSh7MkdorQ9lHehkcrbVRh1ESWcBOqoH1Jyj048SG1uzqbw54hAfO7UOxR
# UNYZLD8NMCeH3G/H/wgOUCAKoja/zErt1R+gpLUFuHyNR7O97jM04pDdlZg7KO5t
# lsxPwwTjesARZDrz5hj5DllNAqgPLo288T+wuuu4og5NAgMBAAGjRjBEMA4GA1Ud
# DwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU7sbjskcV
# LGsQWaAZtwqWAc4C9PswDQYJKoZIhvcNAQELBQADggEBACpKkxpqizfPbOEH6O70
# SC1WdCEpxJUP5VeyIaV7ayTgIa2P4PFQWLS7v8f4FzJC6tWVGDG6HlddveHNaZdQ
# jmSllNTrSkfFBs7KlmmWRhos+UhrqMzURXfG7cq3fdyMFbf80DsEsALh98LOcIK2
# z5kH8CY8a0JzTAcoPwbIKIGzc88j9zcjNLsLD1OdC439vRVY1vo2A5kVKBNVF6n4
# DfY/oEkOIAEkQ7+9CtrL1Pfno31XM+M8aKGOyDaH6PiUiMnmQ3iOkVCbTMrWyqZp
# SXnlX6gZdvnlzUBDs8Ca4r5nRB/GRAPWfVhOs4p72olAtQP8RSV9tIa1iJRb5nYw
# fpsxggHoMIIB5AIBATA2MCIxIDAeBgNVBAMMF1Bvd2VyU2hlbGwgQ29kZSBTaWdu
# aW5nAhAeHMcshzIpsELzmDMFfp8iMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQB
# gjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYK
# KwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIB9U3yhV
# 5nFZC0CuTrZ9a/CznB9ASl9+TK1lRjdOht0RMA0GCSqGSIb3DQEBAQUABIIBAHff
# wKAFaT3KMsagJirZdKScaR3GSJecV6sPLFAlUAeHx7cexwQY2q4yuHXpd5KP9CHz
# 5rVKfPVI20W+iPCSdFC1r1wijQFvs18I39GR11xcHji0v/5ZvnouYkknrlVDxCQ8
# jU1LSzjgmbEwk/msBg+9n1e6fXPBycQ/yhCzceMwFkCKa9YAiRWQ5ZqOg78ywn5o
# ZHS8sZC1q/xMiuf6hp4PblYf4tX37hSZmEfrZiYOtFPtGGlcfpm+CC/kRHfxOrI8
# DsE7w5uzARIcf3gxj5VdJZCexDODu9qbjyaUsqnQV5fscohpeHBVoNEP0dOpWBYr
# E3oA/pX3j+4u0wJ/AKw=
# SIG # End signature block
