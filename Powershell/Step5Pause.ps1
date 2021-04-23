param ([Object[]]$step, [String]$Datasource)

[hashtable]$Return = @{}

write-host "Reportive run is paused. Please complete the manual tasks of correcting the charts." -ForegroundColor Red -BackgroundColor Yellow

do {
$value = Read-host "Enter [Y] to continue and [N] to stop the process"  
} until ($value -in ("Y", "N"))

if ($value -eq "Y") {

$Return.Status = $true 
Return $Return

}

else {$Return.status =  $false
$Return.Errtext = "The user has stopped the process"
Return $Return}

