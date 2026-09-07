$status = $datasource.hidefromaddresslist.HiddenFromAddressListsEnabled
$result = $false
if($status -eq 'true'){
    $result = $true
}
$returnObject = @{Result=$result}
Write-Output $returnObject
