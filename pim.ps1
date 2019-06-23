function LaunchPad {
    param(
          [Parameter(Mandatory=$true)]
		  [ValidateSet("Production", "Health DEV")]
          [string] $Tenant,
         )
		Connect-AzAccount
}

function QuickPIM {
    param(
          [Parameter(Mandatory=$true)]
		  [ValidateSet("Exchange Administrator", "User Administrator", "Global Administrator", "Password Administrator")]
          [string] $Function,
		  [string] $Ticket
         )
		Connect-PimService
		$assignPIM = Get-PrivilegedRoleAssignment | Where {$_.RoleName -eq $Function} | Select-Object RoleId
		Enable-PrivilegedRoleAssignment -RoleAssignment $assignPIM -Duration 0.5 -TicketNumber $Ticket -Reason $Ticket -TicketSystem 'JIRA'
}

$Menu = [ordered]@{

  1 = 'Activate Privileged Role Assignment'

  2 = 'Authenticate Azure Powershell Session'
  }

  $Result = $Menu | Out-GridView -PassThru  -Title 'Logged out'

  Switch ($Result)  {

  {$Result.Name -eq 1} 
 {
iex (show-command QuickPIM -passthru)
$Result = $Menu | Out-GridView -PassThru  -Title 'Privileged Roles Active'
}

  {$Result.Name -eq 2} 
  {
iex (show-command LaunchPad -passthru)
$Result = $Menu | Out-GridView -PassThru  -Title 'Powershell Session Logged in'
  }


} 
