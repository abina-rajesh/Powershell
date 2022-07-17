#Connect-AzAccount
# Variables for common values
$location = "Canada Central"
$resourceGroup = "lab"
$vmName = "demovm-0"
$vmName1 = "demovm-1"
$vmName2 = "demovm-2"
$ComputerName = "MyVM2022"
$publicIPAddress = "spublicip-1"
$webpublicIP = "spublicip-2"
$subnet = "private-subnet"
$bastionsubnetName = "AzureBastionSubnet"
$subnet1 ="public-subnet"
$vnet = "vnet-13"
$nsg = "nsg-1"
$nsgrdp = "nsgrdp-1"
$nsgrdp2 = "nsgrdp-2"
$nsgwww = "nsgwww-1"
$nsgweb = "nsgweb1"
$nic = "nic-1"
$virtualMachineSize = 'Standard_B1s'
$nsg2 ="nsg-2"
$databaseName = "SampleDatabase"
$serverName = "testserver-009"
$SQLSubnet ="privatesql-subnet"
$SubnetAddressPrefix = "10.1.2.0/24"  
$VNetRuleName = 'myFirstVNetRule-ForAcl'
$startIp = "20.106.129.157"
$endIp = "20.106.129.157"


# Create resource group
Get-AzResourceGroup -ResourceGroupName $resourceGroup -Location $location

# credentials
$AdminUser = "LocalAdminUser"
$AdminSecurePassword = ConvertTo-SecureString "P@ssw0rd@123" -AsPlainText -Force

# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name $subnet `
    -AddressPrefix 10.1.0.0/24
$subnetConfig1 = New-AzVirtualNetworkSubnetConfig `
    -Name $subnet1 `
    -AddressPrefix 10.1.1.0/24

$subnetConfig2 = New-AzVirtualNetworkSubnetConfig `
    -Name $SQLSubnet `
    -AddressPrefix 10.1.2.0/24

$bastionsubnet = New-AzVirtualNetworkSubnetConfig -Name $bastionsubnetName -AddressPrefix 10.1.3.0/26



# Create a virtual network
$vnet = New-AzVirtualNetwork `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name $vnet `
    -AddressPrefix 10.1.0.0/16 `
    -Subnet $subnetConfig,$subnetConfig1,$bastionsubnet,$subnetConfig2

$bastionpublicip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name "demo-Ip" -location $location -AllocationMethod Static -Sku Standard

New-AzBastion -ResourceGroupName $resourceGroup -Name "test-Bastion25" -PublicIpAddress $publicip -VirtualNetwork $vnet
    

# Create a public IP address and specify a DNS name
$publicIP = New-AzPublicIpAddress `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -AllocationMethod Static `
    -IdleTimeoutInMinutes 4 `
    -Name $publicIPAddress

$webpublicIP = New-AzPublicIpAddress `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -AllocationMethod Static `
    -IdleTimeoutInMinutes 4 `
    -Name $webpublicIP

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig `
    -Name $nsgrdp `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1000 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389 `
    -Access Allow

# Create a network security group
$nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name $nsg `
    -SecurityRules $nsgRuleRDP

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface `
    -Name $nic `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -SubnetId $vnet.Subnets[0].Id `
    -NetworkSecurityGroupId $nsg.Id

$nic2 = New-AzNetworkInterface `
    -Name nic-3 `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -SubnetId $vnet.Subnets[1].Id `
    -PublicIpAddressId $publicIP.Id `
    -NetworkSecurityGroupId $nsg.Id
    

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig `
    -Name $nsgweb `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1010 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 80 `
    -Access Allow

$nsgRuleApp = New-AzNetworkSecurityRuleConfig `
    -Name $nsgwww `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1020 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 443 `
    -Access Allow

# Create a network security group for 3rd VM
$nsg2 = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -Name $nsg2 `
    -SecurityRules $nsgRuleApp,$nsgRuleWeb

$nic3 = New-AzNetworkInterface `
    -Name nic-4 `
    -ResourceGroupName $resourceGroup `
    -Location $location `
    -SubnetId $vnet.Subnets[1].Id `
    -PublicIpAddressId $webpublicIP.Id `
    -NetworkSecurityGroupId $nsg2.Id


$Credential = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminSecurePassword);
$server = New-AzSqlServer -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $Credential
$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp
    #Get vnet
$vnet1 = Get-AzVirtualNetwork -Name "vnet-13" -ResourceGroupName "lab" | Set-AzVirtualNetworkSubnetConfig -Name $SQLSubnet -AddressPrefix $SubnetAddressPrefix -ServiceEndpoint $ServiceEndPoint | Set-AzVirtualNetwork
$vnetrule = @{
    ResourceGroupName      = $resourceGroup
    ServerName             = $serverName
    VirtualNetworkRuleName = $VNetRuleName
    VirtualNetworkSubnetId = $vnet1.Subnets[3].Id

    }
    New-AzSqlServerVirtualNetworkRule @vnetrule

$VirtualMachine = New-AzVMConfig -VMName $vmName -VMSize $virtualMachineSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $nic.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest

$VirtualMachine1 = New-AzVMConfig -VMName $vmName1 -VMSize $virtualMachineSize
$VirtualMachine1 = Set-AzVMOperatingSystem -VM $VirtualMachine1 -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine1 = Add-AzVMNetworkInterface -VM $VirtualMachine1 -Id $nic2.Id
$VirtualMachine1 = Set-AzVMSourceImage -VM $VirtualMachine1 -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest

$VirtualMachine2 = New-AzVMConfig -VMName $vmName2 -VMSize $virtualMachineSize
$VirtualMachine2 = Set-AzVMOperatingSystem -VM $VirtualMachine2 -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine2 = Add-AzVMNetworkInterface -VM $VirtualMachine2 -Id $nic3.Id
$VirtualMachine2 = Set-AzVMSourceImage -VM $VirtualMachine2 -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest

# Create a virtual machine using the configuration
New-AzVM -ResourceGroupName $resourceGroup -Location $location -vm $VirtualMachine -Verbose
New-AzVM -ResourceGroupName $resourceGroup -Location $location -vm $VirtualMachine1 -Verbose
New-AzVM -ResourceGroupName $resourceGroup -Location $location -vm $VirtualMachine2 -Verbose