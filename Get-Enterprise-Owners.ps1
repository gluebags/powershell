# Fetch owners of Enterprise Applications

# Connect to Microsoft Graph 
# Connect-MgGraph -Scopes Application.Read.All, Directory.Read.All

$outputCsv = "C:\temp\AppOwners_Recursive.csv"
$results = @()

Get-MgApplication -All | ForEach-Object {
    $app = $_
    Write-Host "Processing App: $($app.DisplayName) [$($app.AppId)]"

    $owners = Get-MgApplicationOwner -ApplicationId $app.Id -ErrorAction SilentlyContinue

    if ($owners) {
        foreach ($owner in $owners) {

            $ownerType = ""
            $ownerName = ""
            $ownerPrincipal = ""
            $ownerOwner = ""

            # Check if owner is user
            $user = Get-MgUser -UserId $owner.Id -ErrorAction SilentlyContinue
            if ($user) {
                $ownerType = "User"
                $ownerName = $user.DisplayName
                $ownerPrincipal = $user.UserPrincipalName
            }
            else {
                # Check if owner is group
                $group = Get-MgGroup -GroupId $owner.Id -ErrorAction SilentlyContinue
                if ($group) {
                    $ownerType = "Group"
                    $ownerName = $group.DisplayName
                }
                else {
                    # Check if owner is a service principal (app registration)
                    $sp = Get-MgServicePrincipal -ServicePrincipalId $owner.Id -ErrorAction SilentlyContinue
                    if ($sp) {
                        $ownerType = "Application"
                        $ownerName = $sp.DisplayName

                        # Get the app object
                        $nestedApp = Get-MgApplication -Filter "appId eq '$($sp.AppId)'" -ErrorAction SilentlyContinue
                        if ($nestedApp) {
                            $nestedOwners = Get-MgApplicationOwner -ApplicationId $nestedApp.Id -ErrorAction SilentlyContinue
                            if ($nestedOwners) {
                                $nestedOwnerNames = @()
                                foreach ($nOwner in $nestedOwners) {
                                    $u = Get-MgUser -UserId $nOwner.Id -ErrorAction SilentlyContinue
                                    if ($u) { $nestedOwnerNames += $u.DisplayName; continue }

                                    $g = Get-MgGroup -GroupId $nOwner.Id -ErrorAction SilentlyContinue
                                    if ($g) { $nestedOwnerNames += $g.DisplayName; continue }

                                    $spNested = Get-MgServicePrincipal -ServicePrincipalId $nOwner.Id -ErrorAction SilentlyContinue
                                    if ($spNested) { $nestedOwnerNames += $spNested.DisplayName; continue }

                                    $nestedOwnerNames += $nOwner.Id
                                }
                                $ownerOwner = ($nestedOwnerNames -join ", ")
                            }
                        }
                    }
                    else {
                        $ownerType = "Unknown"
                        $ownerName = $owner.Id
                    }
                }
            }

            $results += [PSCustomObject]@{
                AppName        = $app.DisplayName
                AppId          = $app.AppId
                OwnerType      = $ownerType
                OwnerName      = $ownerName
                OwnerPrincipal = $ownerPrincipal
                OwnerOwner     = $ownerOwner
            }

            Write-Host "  Owner: $ownerName ($ownerType) | Nested Owners: $ownerOwner"
        }
    }
    else {
        $results += [PSCustomObject]@{
            AppName        = $app.DisplayName
            AppId          = $app.AppId
            OwnerType      = "None"
            OwnerName      = ""
            OwnerPrincipal = ""
            OwnerOwner     = ""
        }
        Write-Host "  No owners found."
    }
}

$results | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8
Write-Host "Export complete: $outputCsv"
}

Write-Host "Exporting results to CSV: $outputCsv" -ForegroundColor Cyan
$results | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8
Write-Host "Export complete" -ForegroundColor Green
