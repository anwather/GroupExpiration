$groups = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')"

foreach ($group in $groups) {
    $obj = [PSCustomObject]@{
        Id                 = $group.id
        DisplayName        = $group.DisplayName
        GroupTypes         = $group.GroupTypes -join ""
        RenewedDateTime    = $group.RenewedDateTime
        CreatedDateTime    = $group.CreatedDateTime
        ExpirationDateTime = $group.ExpirationDateTime
        GroupOwners        = Get-MgGroupOwner -GroupId $group.id | ForEach-Object {
            Get-MGUser -UserId $_.id | Select-Object -ExpandProperty UserPrincipalName
        }
    }
    $obj
}