# Find Resources marked with DeleteDate today and delete them
$today = Get-Date -UFormat "%d%m%20%y"
$graceperiod = (Get-date).AddDays(7)
$deletionvalue = Get-Date $graceperiod -UFormat "%d%m%20%y" 
$deletions = Get-AzResource -TagName "DeleteDate" -TagValue "$today"
# Deletes the resources tagged with today's date
foreach ($deletion in $deletions){Remove-AzResource -ResourceId $deletion.ResourceId -Force -AsJob}
# Identifies completely untagged resources, labels them with future deletion date, last user and created date
$resources=Get-AzResource | Where-Object { $_.tags.count -eq 0 }
# Tagging Date Conventions -UFormat "%d%m%20%y"
$today = Get-Date -UFormat "%d%m%20%y"
# Prepare DeleteDate in 90 days
$graceperiod = (Get-date).AddDays(90)
$deletionvalue = Get-Date $graceperiod -UFormat "%d%m%20%y" 
# Loop through resources
foreach ($resource in $resources) {
# Identify Creation date, last user, deletion date (cause it's untagged)
$today = Get-Date -UFormat "%d%m%20%y"
# Prepare DeleteDate in 90 days
$graceperiod = (Get-date).AddDays(90)
$deletionvalue = Get-Date $graceperiod -UFormat "%d%m%20%y" 
$createdTime = Get-AzResource -ResourceId $resource.ResourceId -ExpandProperties | Select-Object @creationTime
$tagDate =  Get-Date $createdTime.Properties.creationTime -UFormat "%d%m20%y"
$LastUser = Get-AzLog -ResourceId $resource.ResourceId -StartTime (Get-Date).AddDays(-14) -EndTime (Get-Date)| Select Caller | Where { $_.Caller } | Sort-Object -Property Caller -Unique
$lastTouch = [long] (Get-Date -Date ((Get-Date).ToUniversalTime()) -UFormat %s)
# Write attributes to the resource
Set-AzResource -Tag @{CreatedDate=$tagDate;Contact=$LastUser.Caller;Notice="This resource is missing an Owner Tag, please amend";CheckDateTime=$LastTouch;DeleteDate=$deletionvalue} -ResourceId $resource.ResourceId -AsJob -Force   
}
