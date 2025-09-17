function Get-ConditionalAccessP2Requirements {
    <#
    .SYNOPSIS
        Detects Conditional Access policies that require Entra ID P2 licenses
        
    .DESCRIPTION
        Analyzes Conditional Access policies in a tenant to identify features that require
        Entra ID P2 licensing. This helps with license planning and compliance assessment.
        
    .PARAMETER TenantId
        Tenant ID to analyze (optional, uses current context if not specified)
        
    .PARAMETER OutputFormat
        Output format: Object (default), JSON, CSV, or Summary
        
    .EXAMPLE
        Get-ConditionalAccessP2Requirements
        # Analyze current tenant and return detailed objects
        
    .EXAMPLE
        Get-ConditionalAccessP2Requirements -OutputFormat Summary
        # Get summary report of P2 requirements
        
    .EXAMPLE
        Get-ConditionalAccessP2Requirements -OutputFormat CSV | Export-Csv -Path "CA-P2-Requirements.csv"
        # Export detailed analysis to CSV
        
    .NOTES
        Requires Microsoft.Graph.Identity.SignIns module
        Requires appropriate permissions: Policy.Read.All
        
        P2-Required Features Detected:
        - Sign-in Risk conditions
        - User Risk conditions  
        - Named Locations (non-IP)
        - Terms of Use
        - Authentication Strength
        - Custom Security Attributes
        - Authentication Context
        - Workload Identity conditions
    #>
    
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$TenantId,
        
        [Parameter()]
        [ValidateSet("Object", "JSON", "CSV", "Summary")]
        [string]$OutputFormat = "Object"
    )
    
    # Check required module
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
        Write-Error "Microsoft.Graph.Identity.SignIns module is required. Install with: Install-Module Microsoft.Graph.Identity.SignIns"
        return
    }
    
    # Import required modules
    Import-Module Microsoft.Graph.Identity.SignIns -Force
    
    # Connect if needed
    try {
        $context = Get-MgContext
        if (-not $context) {
            Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
            Connect-MgGraph -Scopes "Policy.Read.All" -NoWelcome
        }
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        return
    }
    
    Write-Host "🔍 Analyzing Conditional Access policies for P2 requirements..." -ForegroundColor Cyan
    
    # Get all CA policies
    try {
        $policies = Get-MgIdentityConditionalAccessPolicy -All
        Write-Host "Found $($policies.Count) Conditional Access policies" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to retrieve CA policies: $($_.Exception.Message)"
        return
    }
    
    # Get additional data for analysis
    $namedLocations = @{}
    $termsOfUse = @{}
    $authStrengths = @{}
    
    try {
        # Get Named Locations
        $locations = Get-MgIdentityConditionalAccessNamedLocation -All
        foreach ($loc in $locations) {
            $namedLocations[$loc.Id] = @{
                Name = $loc.DisplayName
                Type = if ($loc.AdditionalProperties.ContainsKey('@odata.type')) { 
                    $loc.AdditionalProperties['@odata.type'] 
                } else { 
                    'Unknown' 
                }
            }
        }
        
        # Get Terms of Use (if available)
        try {
            $terms = Get-MgAgreement -All -ErrorAction SilentlyContinue
            foreach ($term in $terms) {
                $termsOfUse[$term.Id] = $term.DisplayName
            }
        }
        catch {
            Write-Verbose "Terms of Use not accessible or not available"
        }
        
        # Get Authentication Strengths (if available)  
        try {
            $strengths = Get-MgPolicyAuthenticationStrengthPolicy -All -ErrorAction SilentlyContinue
            foreach ($strength in $strengths) {
                $authStrengths[$strength.Id] = $strength.DisplayName
            }
        }
        catch {
            Write-Verbose "Authentication Strengths not accessible or not available"
        }
    }
    catch {
        Write-Warning "Some reference data could not be retrieved: $($_.Exception.Message)"
    }
    
    # Analyze each policy
    $results = @()
    $p2RequiredCount = 0
    
    foreach ($policy in $policies) {
        $p2Features = @()
        $hasP2Requirement = $false
        
        # Check conditions that require P2
        $conditions = $policy.Conditions
        
        # 1. Sign-in Risk
        if ($conditions.SignInRiskLevels -and $conditions.SignInRiskLevels.Count -gt 0) {
            $p2Features += "Sign-in Risk Detection"
            $hasP2Requirement = $true
        }
        
        # 2. User Risk  
        if ($conditions.UserRiskLevels -and $conditions.UserRiskLevels.Count -gt 0) {
            $p2Features += "User Risk Detection"
            $hasP2Requirement = $true
        }
        
        # 3. Named Locations (non-IP based require P2)
        if ($conditions.Locations -and ($conditions.Locations.IncludeLocations -or $conditions.Locations.ExcludeLocations)) {
            $locationIds = @()
            if ($conditions.Locations.IncludeLocations) {
                $locationIds += $conditions.Locations.IncludeLocations | Where-Object { $_ }
            }
            if ($conditions.Locations.ExcludeLocations) {
                $locationIds += $conditions.Locations.ExcludeLocations | Where-Object { $_ }
            }
            
            foreach ($locId in $locationIds) {
                if ($locId -and $namedLocations.ContainsKey($locId)) {
                    $locType = $namedLocations[$locId].Type
                    # Country/GPS locations require P2, IP ranges don't
                    if ($locType -eq '#microsoft.graph.countryNamedLocation' -or 
                        $locType -eq '#microsoft.graph.compliantNetworkNamedLocation') {
                        $p2Features += "Named Locations (Country/Compliant Network)"
                        $hasP2Requirement = $true
                    }
                }
            }
        }
        
        # 4. Authentication Context
        if ($conditions.AuthenticationContextClassReferences -and $conditions.AuthenticationContextClassReferences.Count -gt 0) {
            $p2Features += "Authentication Context"
            $hasP2Requirement = $true
        }
        
        # 5. Custom Security Attributes (in user conditions)
        if ($conditions.Users -and $conditions.Users.AdditionalProperties) {
            $userProps = $conditions.Users.AdditionalProperties
            if ($userProps.ContainsKey('customSecurityAttributes') -and $userProps['customSecurityAttributes']) {
                $p2Features += "Custom Security Attributes"
                $hasP2Requirement = $true
            }
        }
        
        # 6. Terms of Use (in grant controls)
        if ($policy.GrantControls -and $policy.GrantControls.TermsOfUse) {
            foreach ($touId in $policy.GrantControls.TermsOfUse) {
                if ($touId -and $termsOfUse.ContainsKey($touId)) {
                    $p2Features += "Terms of Use"
                    $hasP2Requirement = $true
                    break
                }
            }
        }
        
        # 7. Authentication Strength
        if ($policy.GrantControls -and $policy.GrantControls.AuthenticationStrength) {
            $strengthId = $policy.GrantControls.AuthenticationStrength.Id
            if ($strengthId -and $authStrengths.ContainsKey($strengthId)) {
                $p2Features += "Authentication Strength"
                $hasP2Requirement = $true
            }
        }
        
        # 8. Workload Identities (service principals in users condition)
        if ($conditions.Users -and $conditions.Users.IncludeUsers) {
            if ($conditions.Users.IncludeUsers -contains 'ServicePrincipals' -or
                $conditions.Users.IncludeUsers -contains 'WorkloadIdentities') {
                $p2Features += "Workload Identities"
                $hasP2Requirement = $true
            }
        }
        
        if ($hasP2Requirement) {
            $p2RequiredCount++
        }
        
        # Create result object
        $result = [PSCustomObject]@{
            PolicyName = $policy.DisplayName
            PolicyId = $policy.Id
            State = $policy.State
            RequiresP2 = $hasP2Requirement
            P2Features = $p2Features -join "; "
            P2FeatureCount = $p2Features.Count
            CreatedDateTime = $policy.CreatedDateTime
            ModifiedDateTime = $policy.ModifiedDateTime
        }
        
        $results += $result
    }
    
    # Generate summary
    $summary = [PSCustomObject]@{
        TotalPolicies = $policies.Count
        P2RequiredPolicies = $p2RequiredCount
        P2FreePoliciies = $policies.Count - $p2RequiredCount
        PercentageRequiringP2 = if ($policies.Count -gt 0) { 
            [math]::Round(($p2RequiredCount / $policies.Count) * 100, 2) 
        } else { 
            0 
        }
        AnalysisDate = Get-Date
        TenantId = (Get-MgContext).TenantId
    }
    
    Write-Host ""
    Write-Host "📊 Analysis Summary:" -ForegroundColor Green
    Write-Host "Total Policies: $($summary.TotalPolicies)" -ForegroundColor White
    Write-Host "Requiring P2: $($summary.P2RequiredPolicies) ($($summary.PercentageRequiringP2)%)" -ForegroundColor Yellow
    Write-Host "P2-Free: $($summary.P2FreePoliciies)" -ForegroundColor Green
    
    # Return based on output format
    switch ($OutputFormat) {
        "Summary" {
            return $summary
        }
        "JSON" {
            return @{
                Summary = $summary
                Policies = $results
            } | ConvertTo-Json -Depth 3
        }
        "CSV" {
            return $results | Select-Object PolicyName, State, RequiresP2, P2Features, CreatedDateTime
        }
        default {
            # Object format
            return [PSCustomObject]@{
                Summary = $summary
                Policies = $results
                P2RequiredPolicies = $results | Where-Object RequiresP2 -eq $true
                P2FreePolicies = $results | Where-Object RequiresP2 -eq $false
            }
        }
    }
}