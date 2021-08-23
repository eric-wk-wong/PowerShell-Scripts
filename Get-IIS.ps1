# Note: Used to query for IIS servers potentially affected by PetitPotam vulnerability 

$creds = Get-Credential
$IIS = @()

$servers = get-adcomputer -Filter * | select name

foreach($server in $servers){
    $service = Invoke-Command -ComputerName $server.name -credential $creds -ScriptBlock { get-service W3SVC }

    if($service){
        Write-Host "IIS installed on $($server.name)"
        $IIS += new-object psobject -property @{
            name = $server.name
        }
    }
    else {
        Write-Host "IIS is not installed on $($server.name)"
    }
}

$IIS | select name | sort name | export-csv c:\temp\IIS-servers.csv -NoTypeInformation
