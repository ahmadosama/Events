[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $privateendpointname,
    [Parameter()]
    [String]
    $vnetname,
    [Parameter()]
    [String]
    $resourcegroup,
    [Parameter()]
    [String]
    $subnetname,
    [Parameter()]
    [String]
    $sqlserver,
	[Parameter()]
    [String]
	$AzureProfileFilePath
)

# log the execution of the script
Start-Transcript -Path .\log\PrivateEndpoint-SQLDB.txt -Append
$scriptpath  = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Codedir = Split-Path -Parent -Path $scriptpath

# Set AzureProfileFilePath relative to the script directory if it's not provided as parameter
if([string]::IsNullOrEmpty($AzureProfileFilePath))
{
    $AzureProfileFilePath="$Codedir\MyAzureProfile.json"
}

#Login to Azure Account
if((Test-Path -Path $AzureProfileFilePath))
{
	#If Azure profile file is available get the profile information from the file
    $azprofile = Import-AzContext -Path $AzureProfileFilePath
	#retrieve the subscription id from the profile.
    $SubscriptionID = $azprofile.Context.Subscription.SubscriptionId
}
else
{
    Write-Host "File Not Found $AzureProfileFilePath" -ForegroundColor Red
	
	# If the Azure Profile file isn't available, login using the dialog box.
    # Provide your Azure Credentials in the login dialog box
    $azprofile = Connect-AzAccount
    $SubscriptionID =  $azprofile.Context.Subscription.SubscriptionId
}

#Set the Azure Context
Set-AzContext -SubscriptionId $SubscriptionID | Out-Null



$peconname = $privateendpointname + "_connection";

$azsqlserver = Get-AzSqlServer -ResourceGroupName $resourcegroup -ServerName $sqlserver


$pecon = New-AzPrivateLinkServiceConnection -Name $peconname `
  -PrivateLinkServiceId $azsqlserver.ResourceId `
  -GroupId "sqlServer" 
 
$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourcegroup -Name $vnetname
 
$subnet = $vnet `
  | Select -ExpandProperty subnets `
  | Where-Object  {$_.Name -eq $subnetname}  
 
New-AzPrivateEndpoint -ResourceGroupName $resourcegroup `
  -Name $privateendpointname `
  -Location $vnet.Location `
  -Subnet  $subnet `
  -PrivateLinkServiceConnection $pecon `
  -Force
  

$dnszone = New-AzPrivateDnsZone -ResourceGroupName $resourcegroup `
  -Name "privatelink.database.windows.net"`
  
 
New-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $resourcegroup `
  -ZoneName "privatelink.database.windows.net"`
  -Name "vnetdnszonelink" `
  -VirtualNetworkId $vnet.Id
 

$config = New-AzPrivateDnsZoneConfig -Name "privatelink.database.windows.net" -PrivateDnsZoneId $dnszone.ResourceId

New-AzPrivateDnsZoneGroup -ResourceGroupName $resourcegroup -PrivateEndpointName $privateendpointname -name "dnszonegroup" -PrivateDnsZoneConfig $config -Force


Set-AzSqlServer -ServerName $sqlserver -ResourceGroupName $resourcegroup -PublicNetworkAccess Disabled    

    
    

