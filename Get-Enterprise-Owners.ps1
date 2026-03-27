# Fetch owners of Enterprise Applications

# Connect to Microsoft Graph 
# Connect-MgGraph -Scopes Application.Read.All, Directory.Read.All

$outputCsv = "C:\temp\AppOwners_All.csv"
$results = @()

Write-Host "Fetching all applications..." -ForegroundColor Cyan

Get-MgApplication -All | ForEach-Object {
    $app = $_
    Write-Host "Processing App: $($app.DisplayName) [$($app.AppId)]" -ForegroundColor Yellow

    $owners = Get-MgApplicationOwner -ApplicationId $app.Id -ErrorAction SilentlyContinue

    if ($owners) {
        foreach ($owner in $owners) {
            $ownerType = ""
            $ownerName = ""
            $ownerPrincipal = ""
            $ownerOwner = ""

            # Try to resolve as User
            try {
                $user = Get-MgUser -UserId $owner.Id -ErrorAction Stop
                $ownerType = "User"
                $ownerName = $user.DisplayName
                $ownerPrincipal = $user.UserPrincipalName
            }
            catch {
                # Try Group
                try {
                    $group = Get-MgGroup -GroupId $owner.Id -ErrorAction Stop
                    $ownerType = "Group"
                    $ownerName = $group.DisplayName
                }
                catch {
                    # Try Application (nested owner)
                    try {
                        $nestedApp = Get-MgApplication -ApplicationId $owner.Id -ErrorAction Stop
                        $ownerType = "Application"
                        $ownerName = $nestedApp.DisplayName
                        
                        # Get all owners of the nested app
                        $nestedOwners = Get-MgApplicationOwner -ApplicationId $nestedApp.Id -ErrorAction SilentlyContinue
                        if ($nestedOwners) {
                            $nestedOwnerNames = @()
                            foreach ($nOwner in $nestedOwners) {
                                try {
                                    $u = Get-MgUser -UserId $nOwner.Id -ErrorAction Stop
                                    $nestedOwnerNames += $u.DisplayName
                                }
                                catch {
                                    try {
                                        $g = Get-MgGroup -GroupId $nOwner.Id -ErrorAction Stop
                                        $nestedOwnerNames += $g.DisplayName
                                    }
                                    catch {
                                        $nestedOwnerNames += $nOwner.Id
                                    }
                                }
                            }
                            # Join multiple nested owners with commas
                            $ownerOwner = ($nestedOwnerNames -join ", ")
                        }
                    }
                    catch {
                        $ownerType = "Unknown"
                        $ownerName = $owner.Id
                    }
                }
            }

            # Add one row per owner
            $results += [PSCustomObject]@{
                AppName        = $app.DisplayName
                AppId          = $app.AppId
                OwnerType      = $ownerType
                OwnerName      = $ownerName
                OwnerPrincipal = $ownerPrincipal
                OwnerOwner     = $ownerOwner
            }

            Write-Host "  Owner: $ownerName ($ownerType) | Nested Owners: $ownerOwner" -ForegroundColor Green
        }
    }
    else {
        Write-Host "  No owners found for this app." -ForegroundColor DarkYellow
        $results += [PSCustomObject]@{
            AppName        = $app.DisplayName
            AppId          = $app.AppId
            OwnerType      = "None"
            OwnerName      = ""
            OwnerPrincipal = ""
            OwnerOwner     = ""
        }
    }
}

Write-Host "Exporting results to CSV: $outputCsv" -ForegroundColor Cyan
$results | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8
Write-Host "Export complete" -ForegroundColor Green
