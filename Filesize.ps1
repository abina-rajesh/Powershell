Function File_details([string]$path){

$results = @()
$value =@()
Set-Location -Path $path
$colItems = Get-ChildItem $startFolder | Where-Object {$_.PSIsContainer -eq $true} | Sort-Object



foreach ($i in $colItems)
{
$subFolderItems = Get-ChildItem $i.FullName -recurse -force | Where-Object {$_.PSIsContainer -eq $false} | Measure-Object -property Length -sum | Select-Object Sum
$value += $i.FullName + " - " + "{0:N2}" -f ($subFolderItems.sum / 1GB) + " GB"

}
foreach($j in $value){
if($j -ne $null )
{

$z=$j.Split("-")

$filepath= $z[0]
$filesize=$z[1]
$results += New-Object PSObject -Property @{
filepath= $filepath
filesize= $filesize
}

}
}

$results | Select-Object filepath,filesize | Export-Csv -Path 'D:\Abina.csv' -NoTypeInformation
}
File_details("C:\")