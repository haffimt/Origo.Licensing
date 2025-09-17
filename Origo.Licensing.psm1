#requires -Version 5.1

<#
.SYNOPSIS
    Origo.Licensing PowerShell Module
.DESCRIPTION
    Provides functions for Microsoft licensing data management and service plan queries.
    Functions convert the standalone scripts into reusable module functions with output parameters.
.NOTES
    Version: 0.0.1
    Author: Origo
#>

#region Helper Functions

function Resolve-ScriptDirectory {
    <#
    .SYNOPSIS
        Robust script directory resolution helper.
    #>
    param(
        [string]$BasePath,
        [string]$FallbackPath = (Get-Location).Path
    )
    
    if (-not $BasePath -or [string]::IsNullOrWhiteSpace($BasePath)) { 
        $resolvedPath = $MyInvocation.MyCommand.Path 
    } else { 
        $resolvedPath = $BasePath 
    }
    
    if (-not $resolvedPath) { $resolvedPath = (Get-Item .).FullName }
    
    try { 
        $ScriptDir = Split-Path -Parent $resolvedPath -ErrorAction Stop 
    } catch { 
        $ScriptDir = $FallbackPath 
    }
    
    return $ScriptDir
}

function Normalize-CsvHeader {
    <#
    .SYNOPSIS
        Normalizes CSV header names for consistent property access.
    #>
    param([string]$Name)
    
    if (-not $Name) { return $Name }
    $n = $Name.Trim()
    $n = $n -replace '\uFEFF',''            # Remove BOM if present
    $n = $n -replace ' +',' '                # Collapse spaces
    $n = $n -replace '[^A-Za-z0-9 ]',''      # Remove special chars
    $n = $n -replace ' ','_'                 # Spaces to underscore
    return $n
}

function Convert-CsvRow {
    <#
    .SYNOPSIS
        Converts a CSV row with normalized headers.
    #>
    param($Row)
    
    $ht = [ordered]@{}
    foreach ($prop in $Row.PSObject.Properties) {
        $key = Normalize-CsvHeader $prop.Name
        $value = $prop.Value
        if ($value -is [string]) { $value = $value.Trim() }
        $ht[$key] = $value
    }
    [PSCustomObject]$ht
}

function Write-JsonAtomic {
    <#
    .SYNOPSIS
        Writes JSON to file atomically using temp file and move operation.
    #>
    param(
        [Parameter(Mandatory)]
        [PSObject]$InputObject,
        
        [Parameter(Mandatory)]
        [string]$Path,
        
        [int]$Depth = 8,
        
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8
    )
    
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        $json = $InputObject | ConvertTo-Json -Depth $Depth
        [System.IO.File]::WriteAllText($tmp, $json, $Encoding)
        Move-Item -LiteralPath $tmp -Destination $Path -Force
        return $true
    }
    catch {
        if (Test-Path $tmp) { Remove-Item $tmp -Force }
        Write-Error "Failed to write JSON to '$Path': $($_.Exception.Message)"
        return $false
    }
}

#endregion

#region Public Functions

function Get-LicenseInformation {
    <#
    .SYNOPSIS
        Downloads Microsoft licensing CSV and converts to JSON format.
    .DESCRIPTION
        Fetches the latest Microsoft licensing catalog CSV from the official download URL,
        normalizes the data, and converts it to JSON format for further processing.
    .PARAMETER SourceUrl
        URL to the Microsoft licensing CSV. Defaults to the official Microsoft download URL.
    .PARAMETER OutputPath
        Directory where files will be saved. Defaults to current directory.
    .PARAMETER Force
        Force re-download even if cached CSV exists.
    .PARAMETER PassThru
        Return the parsed data object to the pipeline.
    .PARAMETER Output
        Reference variable to capture the output object.
    .EXAMPLE
        Get-LicenseInformation -OutputPath "C:\Temp" -Force
    .EXAMPLE
        $result = @{}
        Get-LicenseInformation -Output ([ref]$result) -PassThru
    #>
    [CmdletBinding()]
    param(
        [string]$SourceUrl = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv',
        
        [string]$OutputPath,
        
        [switch]$Force,
        
        [switch]$PassThru,
        
        [ref]$Output
    )
    
    # Resolve output directory - default to Data subfolder
    if (-not $OutputPath) {
        $scriptDir = Resolve-ScriptDirectory -BasePath $PSCommandPath
        $OutputPath = Join-Path $scriptDir 'Data'
    }
    
    if (-not (Test-Path $OutputPath)) { 
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null 
    }
    
    $JsonOut = Join-Path $OutputPath 'ProductLicensingCatalog.json'
    $CsvCache = Join-Path $OutputPath 'ProductLicensingCatalog.csv'
    
    Write-Verbose "[INFO] Working directory: $OutputPath"
    Write-Verbose "[INFO] Target JSON: $JsonOut"
    
    # Download or use cached CSV
    if (-not $Force -and (Test-Path $CsvCache)) {
        Write-Verbose '[INFO] Using cached CSV file.'
        $csvFile = Get-Item -LiteralPath $CsvCache
    } else {
        Write-Verbose "[INFO] Downloading CSV from: $SourceUrl"
        try {
            Invoke-WebRequest -Uri $SourceUrl -OutFile $CsvCache -UseBasicParsing -ErrorAction Stop
            Write-Verbose '[INFO] Download complete.'
            $csvFile = Get-Item -LiteralPath $CsvCache
        }
        catch {
            Write-Error "Failed to download CSV: $($_.Exception.Message)"
            return
        }
    }
    
    # Import and parse CSV
    try {
        $raw = Get-Content -LiteralPath $csvFile.FullName -Encoding UTF8
        $data = $raw | ConvertFrom-Csv
    }
    catch {
        Write-Error "Failed to parse CSV: $($_.Exception.Message)"
        return
    }
    
    if (-not $data) {
        Write-Warning 'No rows parsed from CSV.'
        return
    }
    
    # Normalize data
    $objects = foreach ($row in $data) { Convert-CsvRow -Row $row }
    
    # Create SKU index if available
    if ($objects[0].PSObject.Properties.Name -contains 'SKUPartNumber') {
        $skuIndex = $objects | Group-Object -Property SKUPartNumber | ForEach-Object {
            [PSCustomObject]@{ SKUPartNumber = $_.Name; Count = $_.Count }
        }
    } else { 
        $skuIndex = @() 
    }
    
    # Build result object
    $result = [ordered]@{
        SourceUrl        = $SourceUrl
        RetrievedUtc     = (Get-Date).ToUniversalTime().ToString('o')
        RowCount         = $objects.Count
        DistinctSkuCount = ($skuIndex.Count)
        Items            = $objects
    }
    
    # Write JSON
    $success = Write-JsonAtomic -InputObject $result -Path $JsonOut -Depth 6
    if ($success) {
        Write-Verbose "[INFO] JSON written: $JsonOut (Rows: $($objects.Count))"
    }
    
    # Set output parameter
    if ($Output) {
        $Output.Value = $result
    }
    
    # Return to pipeline if requested
    if ($PassThru) {
        return $result
    }
}

function Get-ServicePlanMapping {
    <#
    .SYNOPSIS
        Maps ServicePlanId values to products that include them.
    .DESCRIPTION
        Processes the ProductLicensingCatalog.json file to create a mapping of ServicePlanIds
        to the list of products (SKUs) that include each service plan.
    .PARAMETER InputPath
        Path to ProductLicensingCatalog.json. Defaults to same directory as module.
    .PARAMETER OutputPath
        Directory where ServicePlanIdToProducts.json will be saved. Defaults to InputPath directory.
    .PARAMETER PassThru
        Return the mapping object to the pipeline.
    .PARAMETER Output
        Reference variable to capture the output mapping object.
    .EXAMPLE
        Get-ServicePlanMapping -InputPath "C:\Temp\ProductLicensingCatalog.json"
    .EXAMPLE
        $mapping = @{}
        Get-ServicePlanMapping -Output ([ref]$mapping) -PassThru
    #>
    [CmdletBinding()]
    param(
        [string]$InputPath,
        
        [string]$OutputPath,
        
        [switch]$PassThru,
        
        [ref]$Output
    )
    
    # Resolve paths - default to Data subfolder
    if (-not $InputPath) {
        $ScriptDir = Resolve-ScriptDirectory -BasePath $PSCommandPath
        $DataDir = Join-Path $ScriptDir 'Data'
        $InputPath = Join-Path $DataDir 'ProductLicensingCatalog.json'
    }
    
    if (-not $OutputPath) {
        if ($InputPath -like "*\Data\*") {
            # If input is in Data folder, use same folder for output
            $OutputPath = Split-Path -Parent $InputPath
        } else {
            # Default to Data folder
            $ScriptDir = Resolve-ScriptDirectory -BasePath $PSCommandPath
            $OutputPath = Join-Path $ScriptDir 'Data'
        }
    }
    
    $jsonOutputPath = Join-Path $OutputPath 'ServicePlanIdToProducts.json'
    
    if (-not (Test-Path $InputPath)) {
        Write-Error "Input file not found: $InputPath (Run Get-LicenseInformation first)"
        return
    }
    
    Write-Verbose "[INFO] Loading catalog: $InputPath"
    
    # Load catalog
    try {
        $catalog = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Error "Failed to parse JSON: $($_.Exception.Message)"
        return
    }
    
    if (-not $catalog.Items) {
        Write-Warning 'Catalog has no Items array.'
        return
    }
    
    # Build mapping
    $mapping = @{}
    [int]$rowIndex = 0
    
    foreach ($item in $catalog.Items) {
        $rowIndex++
        $spId = $item.ServicePlanId
        if (-not $spId -or [string]::IsNullOrWhiteSpace($spId)) { continue }
        
        $spName = $item.ServicePlanName
        $productName = $item.ProductDisplayName
        if (-not $productName) { $productName = $item.StringId }
        if (-not $productName) { $productName = 'UnknownProduct' }
        
        if (-not $mapping.ContainsKey($spId)) {
            $mapping[$spId] = [ordered]@{
                ServicePlanId   = $spId
                ServicePlanNames= @()
                Products        = @()
            }
        }
        $entry = $mapping[$spId]
        
        if ($spName -and $entry.ServicePlanNames -notcontains $spName) {
            $entry.ServicePlanNames += $spName
        }
        
        # Prevent duplicate product entries (case-insensitive by ProductDisplayName)
        $already = $false
        foreach ($p in $entry.Products) {
            if ($p.ProductDisplayName -and $p.ProductDisplayName.ToLower() -eq $productName.ToLower()) { 
                $already = $true; break 
            }
        }
        if (-not $already) {
            $entry.Products += [PSCustomObject]@{
                ProductDisplayName                 = $productName
                StringId                           = $item.StringId
                SkuGuid                            = $item.GUID
                ServicePlansIncludedFriendlyNames  = $item.ServicePlansIncludedFriendlyNames
            }
        }
    }
    
    # Finalize and enrich
    $final = foreach ($value in $mapping.Values) {
        [PSCustomObject]@{
            ServicePlanId    = $value.ServicePlanId
            ServicePlanNames = $value.ServicePlanNames | Sort-Object -Unique
            ProductCount     = $value.Products.Count
            Products         = $value.Products | Sort-Object -Property ProductDisplayName
        }
    }
    
    $summary = [PSCustomObject]@{
        GeneratedUtc          = (Get-Date).ToUniversalTime().ToString('o')
        SourceFile            = (Split-Path -Leaf $InputPath)
        TotalServicePlans     = $final.Count
        TotalRowsProcessed    = $rowIndex
        TopServicePlansByProducts = ($final | Sort-Object -Property ProductCount -Descending | Select-Object -First 10 ServicePlanId,ProductCount)
    }
    
    # Build output structure
    $result = [ordered]@{
        Summary = $summary
        Items   = $final | Sort-Object -Property @{Expression='ProductCount';Descending=$true}, ServicePlanId
    }
    
    # Write JSON
    $success = Write-JsonAtomic -InputObject $result -Path $jsonOutputPath -Depth 8
    if ($success) {
        Write-Verbose "[INFO] Mapping JSON written: $jsonOutputPath"
        Write-Verbose "[INFO] ServicePlan entries: $($final.Count)"
    }
    
    # Set output parameter
    if ($Output) {
        $Output.Value = $result
    }
    
    # Return to pipeline if requested
    if ($PassThru) {
        return $result
    }
}

function Find-ServicePlans {
    <#
    .SYNOPSIS
        Query products that include specified Service Plans.
    .DESCRIPTION
        Loads ServicePlanIdToProducts.json and provides flexible lookup by ServicePlanId, 
        by partial/regex ServicePlanName match, or by list of IDs. Produces structured output 
        with intersection grouping to identify products satisfying ALL specified plans.
    .PARAMETER ServicePlanId
        One or more exact ServicePlanId GUIDs to match.
    .PARAMETER NameLike
        Wildcard pattern(s) (* supported) matched against ServicePlanNames array.
    .PARAMETER NameRegex
        Regex pattern(s) applied to ServicePlanNames.
    .PARAMETER Top
        Limit results (after filtering) to first N products.
    .PARAMETER ShowPlanSummary
        Switch that outputs a summary table of matched service plans.
    .PARAMETER JsonPath
        Optional path to ServicePlanIdToProducts.json; defaults to same directory.
    .PARAMETER PassThru
        Return the result object to the pipeline.
    .PARAMETER Output
        Reference variable to capture the output result object.
    .EXAMPLE
        Find-ServicePlans -ServicePlanId 'eec0eb4f-6444-4f95-aba0-50c24d67f998'
    .EXAMPLE
        Find-ServicePlans -NameLike '*INTUNE*' -ShowPlanSummary
    .EXAMPLE
        $results = @{}
        Find-ServicePlans -NameRegex 'AAD_PREMIUM_P[12]' -Output ([ref]$results) -PassThru
    #>
    [CmdletBinding()]
    param(
        [string[]]$ServicePlanId,
        
        [string[]]$NameLike,
        
        [string[]]$NameRegex,
        
        [int]$Top,
        
        [switch]$ShowPlanSummary,
        
        [string]$JsonPath,
        
        [switch]$PassThru,
        
        [ref]$Output
    )
    
    # Resolve default JSON path - use Data subfolder
    if (-not $JsonPath) {
        $ScriptDir = Resolve-ScriptDirectory -BasePath $PSCommandPath
        $DataDir = Join-Path $ScriptDir 'Data'
        $JsonPath = Join-Path $DataDir 'ServicePlanIdToProducts.json'
    }
    
    if (-not (Test-Path $JsonPath)) { 
        Write-Error "Mapping JSON not found: $JsonPath (run Get-ServicePlanMapping first)" 
        return
    }
    
    Write-Verbose "Loading mapping file: $JsonPath"
    $mapping = Get-Content -LiteralPath $JsonPath -Raw | ConvertFrom-Json
    $plans = $mapping.Items
    
    if (-not $plans) { 
        Write-Error 'No plans found in mapping JSON.' 
        return
    }
    
    # Build target ServicePlanId set from inputs
    $targetPlanIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    
    if ($ServicePlanId) { 
        foreach ($id in $ServicePlanId) { 
            if ($id) { [void]$targetPlanIds.Add($id) } 
        } 
    }
    
    if ($NameLike) {
        foreach ($pattern in $NameLike) {
            if (-not $pattern) { continue }
            $wild = [WildcardPattern]::new($pattern, 'IgnoreCase')
            foreach ($p in $plans) {
                foreach ($n in $p.ServicePlanNames) {
                    if ($wild.IsMatch($n)) { 
                        [void]$targetPlanIds.Add($p.ServicePlanId); break 
                    }
                }
            }
        }
    }
    
    if ($NameRegex) {
        foreach ($pattern in $NameRegex) {
            if (-not $pattern) { continue }
            foreach ($p in $plans) {
                if ($p.ServicePlanNames -match $pattern) { 
                    [void]$targetPlanIds.Add($p.ServicePlanId) 
                }
            }
        }
    }
    
    if ($targetPlanIds.Count -eq 0) {
        Write-Warning 'No ServicePlan criteria provided; returning empty result.'
        return
    }
    
    # Fetch plan objects for target IDs
    $matchedPlans = $plans | Where-Object { $targetPlanIds.Contains($_.ServicePlanId) }
    
    if ($ShowPlanSummary) {
        $matchedPlans | Select-Object ServicePlanId, ProductCount, @{n='ServicePlanNames';e={($_.ServicePlanNames -join ';')}} | Sort-Object ProductCount -Descending | Format-Table -AutoSize | Out-Host
    }
    
    # Intersection logic: find products that include ALL targeted plan IDs
    $prodMap = @{}
    foreach ($plan in $matchedPlans) {
        foreach ($prod in $plan.Products) {
            $key = $prod.ProductDisplayName
            if (-not $key) { continue }
            if (-not $prodMap.ContainsKey($key)) {
                $prodMap[$key] = [ordered]@{ 
                    Product=$prod; 
                    PlanIds=[System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase) 
                }
            }
            [void]$prodMap[$key].PlanIds.Add($plan.ServicePlanId)
        }
    }
    
    $requiredCount = $targetPlanIds.Count
    $productsAllPlans = foreach ($kv in $prodMap.GetEnumerator()) {
        if ($kv.Value.PlanIds.Count -eq $requiredCount) {
            $matchedPlanDetails = $matchedPlans | Where-Object { $kv.Value.PlanIds.Contains($_.ServicePlanId) }
            [PSCustomObject]@{
                ProductDisplayName = $kv.Key
                StringIds          = ($matchedPlanDetails.Products.StringId | Where-Object { $_ } | Sort-Object -Unique)
                SkuGuids           = ($matchedPlanDetails.Products.SkuGuid | Where-Object { $_ } | Sort-Object -Unique)
                MatchedPlanIds     = @($kv.Value.PlanIds) | Sort-Object
                MatchedPlanCount   = $kv.Value.PlanIds.Count
                RequiredPlanCount  = $requiredCount
            }
        }
    }
    
    if ($Top -gt 0) { $productsAllPlans = $productsAllPlans | Select-Object -First $Top }
    
    # Also provide a per-plan product aggregation
    $perPlanProducts = foreach ($plan in $matchedPlans) {
        [PSCustomObject]@{
            ServicePlanId    = $plan.ServicePlanId
            ServicePlanNames = $plan.ServicePlanNames
            ProductCount     = $plan.ProductCount
            Products         = ($plan.Products.ProductDisplayName | Sort-Object -Unique)
        }
    }
    
    $result = [PSCustomObject]@{
        CriteriaPlanIds           = ([string[]]@($targetPlanIds)) | Sort-Object
        CriteriaPlanCount         = $targetPlanIds.Count
        ProductsWithAllPlans      = $productsAllPlans | Sort-Object ProductDisplayName
        ProductsWithAllPlansCount = ($productsAllPlans | Measure-Object).Count
        PerPlanProducts           = $perPlanProducts
    }
    
    # Set output parameter
    if ($Output) {
        $Output.Value = $result
    }
    
    # Return to pipeline if requested
    if ($PassThru) {
        return $result
    } else {
        # Default behavior - output to pipeline
        return $result
    }
}

#endregion

#region Get-TenantLicenseAssignments Function

<#
.SYNOPSIS
    Retrieves license assignments from a Microsoft 365 tenant using Microsoft Graph and filters by service plan criteria.

.DESCRIPTION
    This function connects to Microsoft Graph to retrieve actual license assignments from users in a tenant.
    It can filter results to show only licenses that contain specific service plans (like AAD_PREMIUM).
    Requires appropriate Microsoft Graph permissions (User.Read.All, Directory.Read.All).

.PARAMETER ServicePlanName
    Service plan name(s) to filter by (e.g., 'AAD_PREMIUM', 'AAD_PREMIUM_P2').

.PARAMETER ServicePlanId
    Service plan GUID(s) to filter by.

.PARAMETER NameLike
    Wildcard pattern(s) for service plan names (e.g., '*AAD_PREMIUM*').

.PARAMETER NameRegex
    Regex pattern(s) for service plan names (e.g., 'AAD_PREMIUM_P[12]').

.PARAMETER IncludeDisabledPlans
    Include service plans that are disabled in the license assignment.

.PARAMETER Top
    Limit the number of users to process (for testing/performance).

.PARAMETER Output
    Output parameter to capture the results as a structured object.

.PARAMETER PassThru
    Return results to the pipeline in addition to setting the Output parameter.

.EXAMPLE
    Get-TenantLicenseAssignments -ServicePlanName 'AAD_PREMIUM_P2'

.EXAMPLE
    Get-TenantLicenseAssignments -NameLike '*AAD_PREMIUM*' -Top 10

.EXAMPLE
    $results = @{}
    Get-TenantLicenseAssignments -NameRegex 'AAD_PREMIUM_P[12]' -Output ([ref]$results)

.NOTES
    Requires Microsoft.Graph PowerShell module and appropriate permissions.
    Use Connect-MgGraph before running this function.
#>
function Get-TenantLicenseAssignments {
    [CmdletBinding()]
    param(
        [string[]]$ServicePlanName,
        [string[]]$ServicePlanId,
        [string[]]$NameLike,
        [string[]]$NameRegex,
        [switch]$IncludeDisabledPlans,
        [int]$Top = 0,
        [ref]$Output,
        [switch]$PassThru,
        [string]$OutFile
    )
    
    # Check if Microsoft Graph module is available
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
        throw "Microsoft.Graph.Users module is required. Install with: Install-Module Microsoft.Graph.Users"
    }
    
    # Check if connected to Graph
    try {
        $context = Get-MgContext
        if (-not $context) {
            throw "Not connected to Microsoft Graph. Use Connect-MgGraph first."
        }
        Write-Host "[INFO] Connected to tenant: $($context.TenantId)" -ForegroundColor Green
    }
    catch {
        throw "Microsoft Graph connection error: $($_.Exception.Message)"
    }
    
    # Import required Graph modules
    Import-Module Microsoft.Graph.Users -ErrorAction SilentlyContinue
    
    # Build service plan filter criteria
    $targetServicePlanIds = @()
    
    # Direct service plan IDs
    if ($ServicePlanId) {
        $targetServicePlanIds += $ServicePlanId
    }
    
    # Need to resolve names/patterns to IDs using our existing catalog
    if ($ServicePlanName -or $NameLike -or $NameRegex) {
        # Use Data subfolder for service plan mapping
        $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        $dataDir = Join-Path $scriptDir 'Data'
        $mappingPath = Join-Path $dataDir 'ServicePlanIdToProducts.json'
        $catalogPath = Join-Path $dataDir 'ProductLicensingCatalog.json'
        
        # Check if mapping file exists, if not, try to create it
        if (-not (Test-Path $mappingPath)) {
            Write-Warning "Service plan mapping not found at: $mappingPath"
            Write-Host "[INFO] Attempting to create required data files..." -ForegroundColor Yellow
            
            # Check if catalog exists, if not download it first
            if (-not (Test-Path $catalogPath)) {
                Write-Host "[INFO] Downloading Microsoft licensing catalog..." -ForegroundColor Cyan
                try {
                    Get-LicenseInformation -OutputPath $dataDir -ErrorAction Stop | Out-Null
                    Write-Host "[SUCCESS] Licensing catalog downloaded successfully" -ForegroundColor Green
                }
                catch {
                    Write-Error "Failed to download licensing catalog: $($_.Exception.Message)"
                    Write-Error "Please run 'Get-LicenseInformation' first or provide ServicePlanId directly."
                    return
                }
            }
            
            # Now create the service plan mapping
            Write-Host "[INFO] Creating service plan mapping..." -ForegroundColor Cyan
            try {
                Get-ServicePlanMapping -InputPath $catalogPath -OutputPath $dataDir -ErrorAction Stop | Out-Null
                Write-Host "[SUCCESS] Service plan mapping created successfully" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to create service plan mapping: $($_.Exception.Message)"
                Write-Error "Please run 'Get-ServicePlanMapping' manually first."
                return
            }
        }
        
        if (Test-Path $mappingPath) {
            Write-Host "[INFO] Loading service plan mapping from: $mappingPath" -ForegroundColor Cyan
            $mappingData = Get-Content $mappingPath -Raw | ConvertFrom-Json
            
            foreach ($item in $mappingData.Items) {
                $planNames = $item.ServicePlanNames -split ', '
                $shouldInclude = $false
                
                # Check direct name matches
                if ($ServicePlanName) {
                    foreach ($name in $ServicePlanName) {
                        if ($planNames -contains $name) {
                            $shouldInclude = $true
                            break
                        }
                    }
                }
                
                # Check wildcard patterns
                if (-not $shouldInclude -and $NameLike) {
                    foreach ($pattern in $NameLike) {
                        foreach ($planName in $planNames) {
                            if ($planName -like $pattern) {
                                $shouldInclude = $true
                                break
                            }
                        }
                        if ($shouldInclude) { break }
                    }
                }
                
                # Check regex patterns
                if (-not $shouldInclude -and $NameRegex) {
                    foreach ($pattern in $NameRegex) {
                        foreach ($planName in $planNames) {
                            if ($planName -match $pattern) {
                                $shouldInclude = $true
                                break
                            }
                        }
                        if ($shouldInclude) { break }
                    }
                }
                
                if ($shouldInclude) {
                    $targetServicePlanIds += $item.ServicePlanId
                }
            }
        }
        else {
            Write-Error "Failed to load or create service plan mapping. Please check permissions and try again."
            return
        }
    }
    
    if ($targetServicePlanIds.Count -eq 0) {
        Write-Warning "No service plans match the specified criteria."
        return
    }
    
    $uniqueServicePlanIds = $targetServicePlanIds | Sort-Object -Unique
    Write-Host "[INFO] Searching for $($uniqueServicePlanIds.Count) service plan(s): $($uniqueServicePlanIds -join ', ')" -ForegroundColor Cyan
    
    # Retrieve users with license assignments
    Write-Host "[INFO] Retrieving users from tenant..." -ForegroundColor Cyan
    
    $users = if ($Top -gt 0) {
        Get-MgUser -Top $Top -Property Id,DisplayName,UserPrincipalName,AssignedLicenses -ErrorAction Stop
    } else {
        Get-MgUser -All -Property Id,DisplayName,UserPrincipalName,AssignedLicenses -ErrorAction Stop
    }
    
    Write-Host "[INFO] Processing $($users.Count) users..." -ForegroundColor Cyan
    
    # Get all available SKUs from tenant
    $subscribedSkus = Get-MgSubscribedSku -ErrorAction Stop
    
    # Build SKU lookup table
    $skuLookup = @{}
    foreach ($sku in $subscribedSkus) {
        $skuLookup[$sku.SkuId] = $sku
    }
    
    # Process users and find matching licenses
    $matchingAssignments = @()
    $processedUsers = 0
    
    foreach ($user in $users) {
        $processedUsers++
        if ($processedUsers % 100 -eq 0) {
            Write-Host "[INFO] Processed $processedUsers users..." -ForegroundColor Yellow
        }
        
        if (-not $user.AssignedLicenses -or $user.AssignedLicenses.Count -eq 0) {
            continue
        }
        
        foreach ($license in $user.AssignedLicenses) {
            $sku = $skuLookup[$license.SkuId]
            if (-not $sku) { continue }
            
            # Check if this SKU contains any of our target service plans
            $matchingPlans = @()
            foreach ($servicePlan in $sku.ServicePlans) {
                if ($uniqueServicePlanIds -contains $servicePlan.ServicePlanId) {
                    # Check if plan is enabled (not in disabled plans list)
                    $isDisabled = $license.DisabledPlans -contains $servicePlan.ServicePlanId
                    
                    if ($IncludeDisabledPlans -or -not $isDisabled) {
                        $matchingPlans += [PSCustomObject]@{
                            ServicePlanId = $servicePlan.ServicePlanId
                            ServicePlanName = $servicePlan.ServicePlanName
                            IsEnabled = -not $isDisabled
                        }
                    }
                }
            }
            
            if ($matchingPlans.Count -gt 0) {
                $matchingAssignments += [PSCustomObject]@{
                    UserId = $user.Id
                    UserDisplayName = $user.DisplayName
                    UserPrincipalName = $user.UserPrincipalName
                    SkuId = $license.SkuId
                    SkuPartNumber = $sku.SkuPartNumber
                    ProductDisplayName = $sku.SkuPartNumber  # Could be enhanced with product name mapping
                    MatchingServicePlans = $matchingPlans
                    TotalMatchingPlans = $matchingPlans.Count
                    EnabledMatchingPlans = ($matchingPlans | Where-Object { $_.IsEnabled }).Count
                }
            }
        }
    }
    
    # Prepare results
    $result = [PSCustomObject]@{
        SearchCriteria = [PSCustomObject]@{
            ServicePlanNames = $ServicePlanName
            ServicePlanIds = $ServicePlanId
            NameLikePatterns = $NameLike
            NameRegexPatterns = $NameRegex
            TargetServicePlanIds = $uniqueServicePlanIds
        }
        Summary = [PSCustomObject]@{
            TotalUsersProcessed = $processedUsers
            UsersWithMatchingLicenses = ($matchingAssignments | Group-Object UserId).Count
            TotalMatchingAssignments = $matchingAssignments.Count
            UniqueSkusFound = ($matchingAssignments | Group-Object SkuId).Count
            IncludeDisabledPlans = $IncludeDisabledPlans.IsPresent
        }
        LicenseAssignments = $matchingAssignments
        TenantInfo = [PSCustomObject]@{
            TenantId = $context.TenantId
            ConnectedAs = $context.Account
            RetrievedAt = Get-Date
        }
    }
    
    Write-Host "[SUCCESS] Found $($matchingAssignments.Count) license assignments matching criteria" -ForegroundColor Green
    
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
    
    # Set output parameter
    if ($Output) {
        $Output.Value = $result
    }
    
    # Return to pipeline if requested
    if ($PassThru) {
        return $result
    } else {
        return $result
    }
}

function Get-ServicePlan {
    <#
    .SYNOPSIS
        Gets a comprehensive list of all Microsoft service plans from the licensing catalog.
    
    .DESCRIPTION
        This function extracts and returns all service plans from the Microsoft licensing catalog,
        providing ServicePlanName, ServicePlanId, and ServicePlansIncludedFriendlyNames for each plan.
        The data is automatically loaded from the Data/ subfolder or from a custom path.
    
    .PARAMETER InputPath
        Path to the ProductLicensingCatalog.json file. If not specified, uses Data/ProductLicensingCatalog.json
    
    .PARAMETER NameFilter
        Optional filter to include only service plans with names matching this pattern (supports wildcards)
    
    .PARAMETER IdFilter
        Optional filter to include only service plans with IDs matching this pattern (supports wildcards)
    
    .PARAMETER SortBy
        Sort results by 'Name', 'Id', or 'FriendlyName'. Default is 'Name'
    
    .PARAMETER UniqueOnly
        Return only unique service plans (removes duplicates based on ServicePlanId)
    
    .PARAMETER Output
        Reference variable to receive the complete results
    
    .PARAMETER PassThru
        Return results to pipeline for further processing
    
    .EXAMPLE
        Get-ServicePlan
        # Gets all service plans from Data/ProductLicensingCatalog.json
    
    .EXAMPLE  
        Get-ServicePlan -NameFilter "*AAD*"
        # Gets all service plans with "AAD" in the name
    
    .EXAMPLE
        Get-ServicePlan -SortBy FriendlyName -UniqueOnly
        # Gets unique service plans sorted by friendly name
    
    .EXAMPLE
        $servicePlans = @{}
        Get-ServicePlan -Output ([ref]$servicePlans) -PassThru | Format-Table
        # Gets service plans with output parameter and pipeline output
    
    .NOTES
        This function uses the Microsoft Product Licensing Catalog data.
        Data files are automatically managed in the Data/ subfolder.
    #>
    
    [CmdletBinding()]
    param(
        [string]$InputPath,
        [string]$NameFilter,
        [string]$IdFilter,
        [ValidateSet('Name', 'Id', 'FriendlyName')]
        [string]$SortBy = 'Name',
        [switch]$UniqueOnly,
        [ref]$Output,
        [switch]$PassThru
    )
    
    # Determine input path
    if (-not $InputPath) {
        $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
        $dataDir = Join-Path $scriptDir 'Data'
        $InputPath = Join-Path $dataDir 'ProductLicensingCatalog.json'
    }
    
    # Check if input file exists
    if (-not (Test-Path $InputPath)) {
        Write-Warning "Product licensing catalog not found at: $InputPath"
        Write-Host "[INFO] Attempting to download licensing catalog..." -ForegroundColor Yellow
        
        try {
            $catalogDir = Split-Path $InputPath -Parent
            Get-LicenseInformation -OutputPath $catalogDir -ErrorAction Stop | Out-Null
            Write-Host "[SUCCESS] Licensing catalog downloaded successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to download licensing catalog: $($_.Exception.Message)"
            Write-Error "Please run 'Get-LicenseInformation' first to download the required data."
            return
        }
    }
    
    Write-Host "[INFO] Loading service plans from: $InputPath" -ForegroundColor Cyan
    
    try {
        # Load the catalog data
        $catalogData = Get-Content $InputPath -Raw -Encoding UTF8 | ConvertFrom-Json
        
        Write-Host "[INFO] Processing $($catalogData.Count) products for service plans..." -ForegroundColor Cyan
        
        # Extract all service plans
        $allServicePlans = @()
        $processedCount = 0
        
        foreach ($product in $catalogData) {
            $processedCount++
            if ($processedCount % 1000 -eq 0) {
                Write-Progress -Activity "Processing Products" -Status "Processed $processedCount of $($catalogData.Count)" -PercentComplete (($processedCount / $catalogData.Count) * 100)
            }
            
            if ($product.ServicePlans -and $product.ServicePlans.Count -gt 0) {
                foreach ($servicePlan in $product.ServicePlans) {
                    # Create service plan object
                    $servicePlanObj = [PSCustomObject]@{
                        ServicePlanName = $servicePlan.ServicePlanName
                        ServicePlanId = $servicePlan.ServicePlanId
                        ServicePlansIncludedFriendlyNames = $servicePlan.ServicePlansIncludedFriendlyNames
                        ProductDisplayName = $product.ProductDisplayName
                        ProductStringIds = $product.StringIds -join ', '
                        ProductSkuIds = $product.SkuIds -join ', '
                    }
                    
                    # Apply filters if specified
                    $includeItem = $true
                    
                    if ($NameFilter -and $servicePlanObj.ServicePlanName -notlike $NameFilter) {
                        $includeItem = $false
                    }
                    
                    if ($IdFilter -and $servicePlanObj.ServicePlanId -notlike $IdFilter) {
                        $includeItem = $false
                    }
                    
                    if ($includeItem) {
                        $allServicePlans += $servicePlanObj
                    }
                }
            }
        }
        
        Write-Progress -Activity "Processing Products" -Completed
        
        # Remove duplicates if requested
        if ($UniqueOnly) {
            Write-Host "[INFO] Removing duplicate service plans..." -ForegroundColor Cyan
            $allServicePlans = $allServicePlans | Group-Object ServicePlanId | ForEach-Object { $_.Group | Select-Object -First 1 }
        }
        
        # Sort results
        switch ($SortBy) {
            'Name' { $allServicePlans = $allServicePlans | Sort-Object ServicePlanName }
            'Id' { $allServicePlans = $allServicePlans | Sort-Object ServicePlanId }
            'FriendlyName' { $allServicePlans = $allServicePlans | Sort-Object ServicePlansIncludedFriendlyNames }
        }
        
        # Create result object
        $result = [PSCustomObject]@{
            ServicePlans = $allServicePlans
            TotalServicePlans = $allServicePlans.Count
            UniqueServicePlans = ($allServicePlans | Group-Object ServicePlanId).Count
            InputPath = $InputPath
            ProcessedProducts = $catalogData.Count
            Filters = @{
                NameFilter = $NameFilter
                IdFilter = $IdFilter
                UniqueOnly = $UniqueOnly.IsPresent
                SortBy = $SortBy
            }
            ProcessedAt = Get-Date
        }
        
        Write-Host "[SUCCESS] Found $($result.TotalServicePlans) service plans ($($result.UniqueServicePlans) unique)" -ForegroundColor Green
        
        # Set output parameter
        if ($Output) {
            $Output.Value = $result
        }
        
        # Return to pipeline if requested
        if ($PassThru) {
            return $result.ServicePlans
        } else {
            return $result.ServicePlans
        }
    }
    catch {
        Write-Error "Failed to process service plans: $($_.Exception.Message)"
        return
    }
}

#endregion

# Export module members
Export-ModuleMember -Function 'Get-LicenseInformation', 'Get-ServicePlanMapping', 'Find-ServicePlans', 'Get-TenantLicenseAssignments', 'Get-ServicePlan'