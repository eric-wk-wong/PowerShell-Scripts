<#
.SYNOPSIS
    This script includes functions which utilize Carbon Black's APIs for:
    1. Querying Devices
    2. Uninstalling/Deleting Sensors in CB Defense
    3. Getting alert information
#>

# Get organization information
$cbcHost = Read-Host "Enter CBC hostname"
$orgID = Read-Host "Enter organization ID"
$token = Read-Host "Enter a token"

<# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- #>
# v6 GET method (sample)
$uri = "https://$cbcHost.conferdeploy.net/appservices/v6/orgs/$orgID/devices/_search/download?status=active"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-Auth-Token", "$token")
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method GET
$query = $response
<# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- #>
# v6 POST method samples below
# Header - DEVICE SEARCH
$uri = "https://$cbcHost.conferdeploy.net/appservices/v6/orgs/$orgID/devices/_search/"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-Auth-Token", "$token")

# Body Schema - Find Registered Devices
$body = @{
    criteria = @{
        status = @('REGISTERED','INACTIVE','DEREGISTERED')
    };
    rows = 2000
}
# Convert to JSON
$body = $body | ConvertTo-Json
$content_type = 'application/json'

# POST Request
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -Body $body -ContentType $content_type

# RESPONSE Results
$query = $response.results

# Filters
$outdated = $query | ? {$_.sensor_version -lt "3.7"}
$inactive = $query | ? {$_.status -eq 'INACTIVE'}
$deregistered = $query | {$_.status eq 'DEREGISTERED'}
$deleted = @()

# Correlate with Active Directory
foreach ($host in $inactive){

    try{
     $ad = get-adcomputer $entry.hostname
    catch{
      $deleted += $host
    }
}
# Add deleted AD objects to inactive hosts
foreach ($device in $deleted){
    $inactive += $device
}

# New Header - Device Actions
$uri = "https://$cbcHost.conferdeploy.net/appservices/v6/orgs/$orgID/device_actions"

# Body Schema - Uninstall Sensor
$body = @{
    action_type = 'UNINSTALL_SENSOR';
    device_id = @($($inactive.id));
}
$body = $body | ConvertTo-Json
$content_type = 'application/json'

$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -Body $body -ContentType $content_type

# Body Schema - Delete Sensor
$body = @{
    action_type = 'DELETE_SENSOR';
    device_id = @($($deregistered));
}
$body = $body | ConvertTo-Json
$content_type = 'application/json'

$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -Body $body -ContentType $content_type

<# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- #>

# Change Header - Querying Alerts
$uri = "https://$cbcHost.conferdeploy.net/appservices/v6/orgs/$orgID/alerts/_search/"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-Auth-Token", "$token")
# Body Schema - Find Devices
$body = @{
    criteria = @{
        category = @("Threat");
    };
    rows = 10000
}
# Convert to JSON
$body = $body | ConvertTo-Json
$content_type = 'application/json'
# POST Request
$response = Invoke-RestMethod -Uri $uri -Headers $headers -Method POST -Body $body -ContentType $content_type
$query = $response.results

# Query Results (Sample for PUPs)
$alerts = $query | ? {( ($_.threat_cause_reputation -like "*PUP*"} | select device_name, legacy_alert_id, process_name, reason | sort device_name -Unique
$alerts | export-csv ".\PUP-alerts.csv" -notypeinformation


