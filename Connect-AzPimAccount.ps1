
function QuickPIM {
    param(
          [Parameter(Mandatory=$true)]
		  [ValidateSet("Exchange Administrator", "User Administrator", "Global Administrator", "Password Administrator")]
          [string] $Role,
		  [string] $Ticket
         )
		Connect-PimService
		$assignPIM = Get-PrivilegedRoleAssignment | Where {$_.RoleName -eq $Role} | Select-Object RoleId
		Enable-PrivilegedRoleAssignment -RoleAssignment $assignPIM -Duration 0.5 -TicketNumber $Ticket -Reason 'Platform Services' -TicketSystem 'JIRA'
}

$Selection = [ordered]@{
1 = 'Activate Privileged Role Assignment'
2 = 'Authenticate Azure Powershell Session'
}

	$Result = $Selection | Out-GridView -PassThru  -Title 'Login'

	Switch ($Result)  {

{	$Result.Name -eq 1} 
{
	iex (show-command QuickPIM -passthru)
	$Result = $Menu | Out-GridView -PassThru  -Title 'Privileged Roles Active'
}

{	$Result.Name -eq 2} 
{
	Connect-AzAccount
	$subscription = Get-AzSubscription | Out-GridView -PassThru -Title "Select Subscription"
	Select-AzSubscription $subscription
	#Launch a cli session
}


} 

