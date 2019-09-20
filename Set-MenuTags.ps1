# Menu
$Menu = [ordered]@{

1 = 'Export Tags'
2 = 'Update Tags'
3 = 'Configure BootPolicy Tags'
4 = 'Copy Resource Group Tags onto Child Resources'

# Present Main Menu
$Choice = $Menu | Out-GridView -PassThru  -Title 'Telstra Health Azure Tagging Tools - Select Operation'

Switch ($Choice)  {
	
# Export the Tags to the $csv file
{$Choice.Name -eq 1} {$selectedSub = Get-AzSubscription | Out-GridView -PassThru -Title 'Select the targeted subscription'
Set-AzContext $selectedSub
.\Get-AzureRMResourceTag | Export-CSV -Append C:\temp\2Tags.csv -Force
}

# declare paths
$csv = C:\temp\2Tags.csv
#make a list
$xl = New-Object -comobject Excel.Application
# Show Excel
$xl.visible = $true
#$xl.DisplayAlerts = $False
# Create a workbook
$wb = $xl.Workbooks.open($csv) }
# Reopen the menu
#$Choice = $Menu | Out-GridView -PassThru  -Title 'Telstra Health Azure Tagging Tools - Select Operation' {}

# Set the tags from the $csv
{$Choice.Name -eq 2} {Import-CSV C:\temp\Tags.csv  | .\Set-AzResourceTag.ps1}

{$Choice.Name -eq 3} {'Do whatever you  want'}   

} 
