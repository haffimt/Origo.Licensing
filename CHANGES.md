# Origo.Licensing Module - Change Log

All notable changes to the Origo.Licensing PowerShell module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New `Get-ServicePlan` function for comprehensive service plan analysis
- `-OutFile` parameter to `Get-TenantLicenseAssignments` for JSON export
- Help directory with packaging script for NuGet publishing
- Auto-provisioning logic for missing data files
- Data subfolder organization for better file management

### Changed
- All functions now default to using `Data/` subfolder for data files
- Enhanced documentation with new features and examples
- Updated Examples.ps1 with comprehensive usage demonstrations

### Fixed
- Module structure now organized with proper data file management
- Auto-creation of missing data dependencies

## [0.0.1] - 2025-09-16

### Added
- Initial module creation with core functionality
- `Get-LicenseInformation` function for downloading Microsoft licensing catalog
- `Get-ServicePlanMapping` function for creating service plan to product mappings
- `Find-ServicePlans` function for searching products by service plan criteria
- `Get-TenantLicenseAssignments` function for querying tenant license assignments via Microsoft Graph
- Module manifest with proper PowerShell 5.1+ compatibility
- Comprehensive README.md with usage documentation
- Examples.ps1 with practical usage scenarios

### Features
- **Microsoft Graph Integration**: Connect to Microsoft 365 tenants to query actual license assignments
- **Service Plan Analysis**: Search and analyze Microsoft service plans across products
- **Flexible Search Options**: Support for name patterns, regex, and ID-based searches
- **Output Parameters**: Structured output with `[ref]` parameters for advanced scripting
- **Pipeline Support**: Full PowerShell pipeline integration with `-PassThru` parameter
- **Rich Data**: Comprehensive licensing information from official Microsoft catalog

---

## Detailed Change History

### Version 0.0.1 (September 16, 2025)

#### Core Module Development
- **Module Structure**: Created PowerShell module with .psd1 manifest and .psm1 implementation
- **Function Architecture**: Implemented 4 core functions with consistent parameter patterns
- **Error Handling**: Comprehensive error handling and user feedback throughout all functions
- **Documentation**: Complete inline help documentation for all functions

#### Data Management System
- **Catalog Download**: Automatic download of Microsoft's official licensing catalog
- **JSON Processing**: Efficient processing of large JSON datasets with progress indicators
- **File Management**: Smart file handling with UTF-8 encoding and atomic operations
- **Path Resolution**: Intelligent path resolution for cross-platform compatibility

#### Microsoft Graph Integration
- **Authentication**: Integration with Microsoft Graph PowerShell SDK
- **Tenant Queries**: Live querying of Microsoft 365 tenant license assignments
- **User Data**: Comprehensive user license assignment information
- **Permission Handling**: Proper Graph API permission requirements and validation

### Major Enhancements (September 16-17, 2025)

#### Data Organization Improvements
**Context**: User requested better data file organization
- **Data Subfolder**: Created `Data/` subfolder for all data files
- **Path Updates**: Updated all functions to default to Data/ folder usage
- **File Migration**: Moved existing data files to organized structure
- **Backward Compatibility**: Maintained custom path options for advanced users

**Impact**: 
- Cleaner module directory structure
- Easier data file management
- Professional module organization

#### Auto-Provisioning System
**Context**: User wanted automatic dependency management
- **Smart Detection**: Functions now detect missing data files automatically
- **Auto-Download**: Automatic catalog download when files are missing
- **Dependency Chain**: Intelligent dependency resolution (catalog → mapping → queries)
- **User Experience**: Zero-setup experience for new users

**Impact**:
- Eliminated manual data file management
- Improved user onboarding experience
- Reduced support overhead

#### Enhanced Documentation
**Context**: Updated documentation to reflect new capabilities
- **README Updates**: Comprehensive documentation refresh with new features
- **Examples Enhancement**: Updated Examples.ps1 with auto-provisioning demos
- **Visual Improvements**: Added emojis, color coding, and clear sections
- **Usage Workflows**: Added quick-start and advanced workflow examples

#### JSON Export Capability
**Context**: User requested ability to export results to JSON files
- **OutFile Parameter**: Added `-OutFile` parameter to `Get-TenantLicenseAssignments`
- **JSON Formatting**: Proper depth and encoding for JSON export
- **Error Handling**: Robust file operation error handling
- **Timestamping**: Support for timestamped report generation

**Technical Implementation**:
```powershell
# Save to JSON file if OutFile specified
if ($OutFile) {
    try {
        Write-Host "[INFO] Saving results to JSON file: $OutFile" -ForegroundColor Cyan
        $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutFile -Encoding UTF8
        Write-Host "[SUCCESS] Results saved to: $OutFile" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to save to file '$OutFile': $($_.Exception.Message)"
    }
}
```

#### New Service Plan Analysis Function
**Context**: User requested comprehensive service plan extraction functionality
- **Get-ServicePlan Function**: New function for extracting all service plans from catalog
- **Filtering Options**: Support for name and ID pattern filtering
- **Sorting Capabilities**: Multiple sorting options (Name, Id, FriendlyName)
- **Deduplication**: Option to return unique service plans only
- **Performance**: Progress indicators for large dataset processing

**Function Features**:
- ServicePlanName extraction
- ServicePlanId extraction  
- ServicePlansIncludedFriendlyNames extraction
- Product context information
- Advanced filtering and sorting options

#### Packaging and Distribution
**Context**: User requested NuGet packaging capabilities
- **Help Directory**: Created Help/ directory for documentation and tools
- **Package Script**: Comprehensive package.ps1 script for NuGet publishing
- **Build Process**: Automated validation, help generation, and packaging
- **Repository Support**: Configurable repository targeting (Local, PSGallery, etc.)

**Packaging Features**:
- Prerequisites validation
- Module testing and validation
- Automatic help file generation
- NuGet package creation
- Optional automated publishing
- Comprehensive build reporting

### Technical Architecture

#### Module Structure Evolution
```
Initial Structure (v0.0.1):
Origo.Licensing/
├── Origo.Licensing.psd1
├── Origo.Licensing.psm1
├── README.md
├── Examples.ps1
├── ProductLicensingCatalog.csv
├── ProductLicensingCatalog.json
└── ServicePlanIdToProducts.json

Enhanced Structure (Current):
Origo.Licensing/
├── Origo.Licensing.psd1         # Module manifest (5 functions)
├── Origo.Licensing.psm1         # Core implementation
├── README.md                    # Comprehensive documentation
├── Examples.ps1                 # Enhanced usage examples
├── Data/                        # Organized data storage
│   ├── ProductLicensingCatalog.csv
│   ├── ProductLicensingCatalog.json
│   └── ServicePlanIdToProducts.json
└── Help/                        # Documentation and tools
    ├── package.ps1              # NuGet packaging script
    └── [auto-generated help files]
```

#### Function Evolution
1. **v0.0.1**: 4 core functions with basic functionality
2. **Current**: 5 functions with enhanced capabilities:
   - `Get-LicenseInformation` - Enhanced with Data/ folder support
   - `Get-ServicePlanMapping` - Auto-path resolution
   - `Find-ServicePlans` - Data/ folder integration
   - `Get-TenantLicenseAssignments` - Auto-provisioning + JSON export
   - `Get-ServicePlan` - **NEW** comprehensive service plan analysis

### Performance and Reliability Improvements

#### Error Handling Enhancements
- Comprehensive try-catch blocks throughout all functions
- Informative error messages with actionable guidance
- Graceful degradation when optional features fail
- Progress indicators for long-running operations

#### Memory and Performance Optimizations
- Efficient JSON processing for large datasets
- Progress reporting for user feedback during long operations
- Atomic file operations to prevent corruption
- Smart caching and file reuse strategies

### User Experience Improvements

#### Onboarding Experience
- **Before**: Manual data file management required
- **After**: Zero-setup experience with auto-provisioning

#### Documentation Quality
- **Before**: Basic function documentation
- **After**: Comprehensive examples, workflows, and troubleshooting

#### Workflow Efficiency
- **Before**: Multi-step manual process for tenant queries
- **After**: Single-command operation with automatic dependencies

### Future Roadmap

#### Planned Enhancements
- Additional filtering options for service plan analysis
- Enhanced reporting and export capabilities
- Performance optimizations for large tenant queries
- Integration with additional Microsoft Graph endpoints
- Advanced analytics and trend analysis features

#### Potential Features Under Consideration
- PowerBI integration for advanced reporting
- Scheduled report generation capabilities
- Multi-tenant comparison features
- Historical license tracking and analysis
- Integration with other Origo modules

---

## Contributing

This module is part of the Origo toolkit for Microsoft 365 and Azure management. Changes are tracked to ensure transparency and facilitate troubleshooting.

## Support

For questions about specific changes or features, refer to the comprehensive README.md and Examples.ps1 files included with the module.

---

*Last Updated: September 17, 2025*
*Module Version: 0.0.1 (Enhanced)*