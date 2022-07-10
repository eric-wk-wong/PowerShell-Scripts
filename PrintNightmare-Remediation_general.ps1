$creds = get-credential

$servers = get-adcomputer -filter * -properties description | ? {$_.description -notlike "*print*server*"

foreach ($erver in $Servers){

    Invoke-command -Computername $server.name -scriptblock {Stop-Service -Name Spooler -Force; Set-Service -Name Spooler -StartupType Disabled} -credential $creds
}

# Generate Artifact
$result = @()

foreach ($server in $servers){

    try{
        $output = Invoke-command -ComputerName $server.Name -scriptblock {Get-Service -name Spooler} -credential $creds
        $result += New-Object psobject -property @{
            computername = $server.Name
            printservice = $output.status
        }
    }catch{
        $result += New-Object psobject -property @{
            computername = $server.name
            printservice = "server is offline or unreachable"
        }
    }
}

$date = $((Get-Date).ToString('MM-dd-yyy'))
$result | export-csv c:\temp\printnightmare-remediated-$date.csv -NoTypeInformation
