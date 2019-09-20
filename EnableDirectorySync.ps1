# PowerShell.EnableDirectorySync.ps1

<#
.SYNOPSIS
    Import users in Prod AAD which are not in Dev AAD
.DESCRIPTION
    Import users in Prod AAD which are not in Dev AAD
    Obtain all users in both environments and import those which are not in dev
	Exports to CSV if -export switch is present e.g. ./import_prod_to_dev.ps1 -export
#>

## Create null arrays and Initialise Variables
## Note 1: 'customizedMessageBody' Cannot be null. Email delivery is stopped by setting SendInvitationMessage to false.
## Note 2: This needs to be run with a user/SPN with GuestInviter permissions - user needs PIM elevation

param([switch]$export)

cls

Find-Module AzureAD
Install-Module AzureAD -Force
Import-Module AzureAD
Get-Module

$userstoimport = @()
$excludedusers = @()
$usersttodelete = @()
$exclude = "AAA"
$prodtenant = 'xxx'
$devtenant = 'xxx'
$messageInfo = New-Object Microsoft.Open.MSGraph.Model.InvitedUserMessageInfo
$messageInfo.customizedMessageBody = "Hello, your Development AAD account has been created."
$RedirectUrl = 'https://app.vssps.visualstudio.com'

## Populate vars with user data from both prod and dev tenants
Connect-AzureAD -TenantId $prodtenant #-Credential $Credential
$produsers = Get-AzureADUser -All $true #| Select-Object DisplayName,UserPrincipalName,AccountEnabled,Mail
Connect-AzureAD -TenantId $devtenant #-Credential $Credential
$devusers = Get-AzureADUser -All $true

## loop through each user in prod tenant and compare with dev users
## Excludes prod users that:
##  	- Have exactly the same Mail or DisplayName 
## 		- UPN matches the regex in $exclude var. This filters out shared accounts, resources and other non-personal AAD accounts
##		- Users that have their accounts disabled
##		- Have '*EXT*' in their UPN, which means they are guest users. For some reason there are also AAD 'Members' that have '*EXT*' so just filtering out UserType=Guest misses these users
##
## 	Note that all filters are case insensitive

foreach ($i in $produsers)
{
	if ($devusers.Mail -notcontains $i.Mail -And $devusers.DisplayName -notcontains $i.DisplayName -And @($i).Where({$_.DisplayName -notmatch $exclude}) -And @($i).Where({$_.UserPrincipalName -notlike '*#EXT#*'}) -And @($i).Where({$_.AccountEnabled -eq 'TRUE'}))
	{$userstoimport += @($i)}
	else 
	{$excludedusers += $i}
}

$userstoremove = @()
$disabledusers = @()
$disableduserstoremove = @()

foreach ($i in $devusers)
{
	if ($produsers.Mail -notcontains $i.Mail -And $produsers.DisplayName -notcontains $i.DisplayName -And @($i).Where({$_.UserPrincipalName -like '*TelstraHealthProjectsteamte*'})) {
		$userstoremove += @($i)
	}	
}

write-output ""
write-output ""
write-output "Missing DEV users"
write-output ""
$userstoremove


foreach ($i in $produsers)
{
     if($i.AccountEnabled -ne 'TRUE') {
		 $disabledusers += @($i)
	 }
}
write-output ""
write-output ""
write-output "Disabled PROD users"
write-output ""
$disabledusers

foreach ($i in $devusers)
{  
      if($userstoremove.Mail -contains $i.Mail -And $userstoremove.DisplayName -contains $i.DisplayName){
		  $disableduserstoremove += @($i) 
	  }
}

write-output ""
write-output ""
write-output "Disabled users in DEV"
write-output ""

$disableduserstoremove

## adds each user in $userstoimport to the Dev AAD
#foreach ($email in $userstoimport)
#{
#	try {
#			New-AzureADMSInvitation -InvitedUserEmailAddress $email.UserPrincipalName -InvitedUserDisplayName $email.DisplayName -InvitedUserMessageInfo $messageInfo -SendInvitationMessage $false -InviteRedirectUrl $RedirectUrl
#		}
#	catch
#		{
#			Write-host 'Failed to add' $email.UserPrincipalName 'to Dev AAD'
#			$failedusers += @($email)
#		}
#}

## If script is called with the -export switch then the following CSV files are created in the path in which the script was run
if ($export) { 
	$excludedusers | Export-CSV excludedusers.csv
	$userstoimport | Export-CSV attempted-to-import-users.csv
	$devusers | Export-CSV devusers.csv
	$failedusers | Export-CSV failedusers.csv
}
