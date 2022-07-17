


$location = "Canada Central"
$resourceGroup = "lab"
$adminSqlLogin = "SqlAdmin"
$password = "admin@123"
$databaseName = "SampleDatabase"
$serverName = "testserver-009"
$vnet = "vnet-13"
$Subnet ="private-subnet"
$ServiceEndPoint = "Microsoft.Sql"
$SubnetAddressPrefix = "10.1.0.0/24"
$VNetRuleName = 'myFirstVNetRule-ForAcl'
$startIp = "20.106.129.157"
$endIp = "20.106.129.157"

$server = New-AzSqlServer -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
$startIp = "20.106.129.157"
$endIp = "20.106.129.157"
$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
    #Get vnet
$vnet1 = Get-AzVirtualNetwork -Name $vnet -ResourceGroupName $resourceGroup | Set-AzVirtualNetworkSubnetConfig -Name $Subnet -AddressPrefix $SubnetAddressPrefix -ServiceEndpoint $ServiceEndPoint | Set-AzVirtualNetwork
$vnetrule = @{
    ResourceGroupName      = $resourceGroup
    ServerName             = $serverName
    VirtualNetworkRuleName = $VNetRuleName
    VirtualNetworkSubnetId = $vnet1.Subnets[0].Id

    }
    New-AzSqlServerVirtualNetworkRule @vnetrule