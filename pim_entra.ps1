#!/usr/bin/env pwsh
param (
    [string]$Operation,
    [string]$RoleName,
    [string]$RoleDefinitionId,
    [string]$DirectoryScopeId,
    [string]$Justification,
    [string]$Duration
)

# Function to ensure Microsoft.Graph is ready
function Initialize-GraphModule {
    $requiredModules = @("Microsoft.Graph.Identity.Governance", "Microsoft.Graph.Users")
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module)) {
            Write-Host "Module $module not found. Installing..."
            try {
                Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                Write-Host "Installed $module."
            }
            catch {
                Write-Error "Failed to install module ${module}. Please run 'Install-Module $module -Scope CurrentUser' manually."
                exit 1
            }
        }
        
        # Import explicitly to try and handle loading issues
        try {
            Import-Module $module -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to load module ${module}: $_"
            exit 1
        }
    }
    
    try {
        # Connect with necessary scopes if not already connected (simplified check)
        $currentContext = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $currentContext) {
            Connect-MgGraph -Scopes "RoleManagement.Read.Directory", "RoleAssignmentSchedule.ReadWrite.Directory" -ErrorAction Stop | Out-Null
        }
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph: $_"
        exit 1
    }
}

Initialize-GraphModule

if ($Operation -eq "List") {
    try {
        $user = Get-MgUser -UserId (Get-MgContext).Account
        $roles = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "principalId eq '$($user.Id)'" -ExpandProperty roleDefinition
        
        if ($roles) {
            $roles | Select-Object -Property @{N = 'RoleName'; E = { $_.RoleDefinition.DisplayName } }, RoleDefinitionId, DirectoryScopeId | ConvertTo-Json -Compress
        }
        else {
            Write-Output "[]"
        }
    }
    catch {
        Write-Error "Failed to list eligible roles: $_"
        exit 1
    }
}
elseif ($Operation -eq "Activate") {
    if (-not $RoleDefinitionId -or -not $DirectoryScopeId -or -not $Duration -or -not $Justification) {
        Write-Error "Missing required parameters for activation."
        exit 1
    }

    try {
        $user = Get-MgUser -UserId (Get-MgContext).Account
        $params = @{
            RoleDefinitionId = $RoleDefinitionId
            PrincipalId      = $user.Id
            DirectoryScopeId = $DirectoryScopeId
            Action           = "SelfActivate"
            Justification    = $Justification
            ScheduleInfo     = @{
                StartDateTime = $null
                Expiration    = @{
                    Type     = "AfterDuration"
                    Duration = "PT${Duration}"
                }
            }
        }
        New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params -ErrorAction Stop | Out-Null
        Write-Output "Success"
    }
    catch {
        Write-Error "Failed to activate role: $_"
        exit 1
    }
}
else {
    Write-Error "Invalid operation specified."
    exit 1
}
