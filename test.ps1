$values = Get-Content .\value.json | ConvertFrom-Json

$tenant_id = $values.tenantid
$app_id = $values.app_id
$app_key = $values.app_key | ConvertTo-SecureString -AsPlainText -Force

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $app_id, $app_key
Connect-AzAccount -ServicePrincipal -TenantId $tenant_id -Credential $Credential

function Get-UnifiedGroups {
    $uri = "https://graph.microsoft.com/v1.0/groups"
    $response = Invoke-AzRestMethod -Uri $uri
    $groups = ($response.Content | ConvertFrom-Json).Value | Where-Object groupTypes -contains "Unified"
    return $groups
}

function Get-GroupOwner {
    Param($GroupId)

    $uri = "https://graph.microsoft.com/v1.0/groups/$GroupId/owners"
    $response = Invoke-AzRestMethod -Uri $uri
    $owners = ($response.Content | ConvertFrom-Json).Value | Select-Object -ExpandProperty id
    $ownerResponse = @()
    $owners | ForEach-Object {
        $ownerResponse += Get-UserDisplayName -UserId $_
    }
    return $ownerResponse
}

function Get-UserDisplayName {
    Param($UserId)

    $uri = "https://graph.microsoft.com/v1.0/users/$UserId"
    $response = Invoke-AzRestMethod -Uri $uri
    $userPrincipalName = ($response.Content | ConvertFrom-Json).userPrincipalName
    return $userPrincipalName
}

function Update-GroupExpiration {
    Param($GroupId)

    $uri = "https://graph.microsoft.com/beta/groupLifecyclePolicies/renewGroup"
    $body = @{
        groupId = $GroupId
    } | ConvertTo-Json
    $response = Invoke-AzRestMethod -Uri $uri -Method POST -Payload $body
    return $response.StatusCode
}

function Get-GroupLifeCyclePolicies {
    
    $uri = "https://graph.microsoft.com/beta/groupLifecyclePolicies"
    $response = Invoke-AzRestMethod -Uri $uri
    $policies = ($response.Content | ConvertFrom-Json).Value
    return $policies
}

function New-GroupLifeCyclePolicy {
    Param([string]$NotificationEmails,
        [int]$GroupLifetime,
        [ValidateSet("All", "Selected")]
        [string]$ManagedGroupTypes = "Selected"
    )

    $uri = "https://graph.microsoft.com/beta/groupLifecyclePolicies"
    $body = @{
        groupLifetimeInDays         = $GroupLifetime
        managedGroupTypes           = $ManagedGroupTypes
        alternateNotificationEmails = $NotificationEmails
    } | ConvertTo-Json

    $response = Invoke-AzRestMethod -Uri $uri -Method POST -Payload $body
}

$groups = Get-UnifiedGroups

foreach ($group in $groups) {
    $obj = [PSCustomObject]@{
        Id                 = $Group.id
        DisplayName        = $Group.DisplayName
        GroupTypes         = $Group.GroupTypes -join ""
        RenewedDateTime    = $Group.RenewedDateTime
        CreatedDateTime    = $Group.CreatedDateTime
        ExpirationDateTime = $Group.ExpirationDateTime
        GroupOwners        = Get-GroupOwner -GroupId $group.id
    }

    $obj
}

