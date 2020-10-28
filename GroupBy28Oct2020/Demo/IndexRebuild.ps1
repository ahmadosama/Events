$azsqlserver = "aoazsqlserver.database.windows.net" 
$azsqldb = "stackoverflowtest2010" 

$Cred = Get-AutomationPSCredential -Name "aoazsqlservercreds" 
$Output = $(Invoke-Sqlcmd -ServerInstance $azsqlserver -Username $Cred.UserName -Password $Cred.GetNetworkCredential().Password -Database $azsqldb -Query "Select 1" -Verbose) 4>&1 

Write-Output $SQLOutput​