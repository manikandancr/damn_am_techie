$projects = Import-Csv -Path .\Executions.csv | Where-Object -FilterScript { $_.Status -ne "Done" }

if ($projects.count -eq 0) {
    write-host "No new entries found"
    exit
}
else 
{
    foreach ($proj in $projects) {

        $project = $proj.ProjectName
        $executionDatetime = $([datetime]::ParseExact($proj.ExecutedDate, 'M/d/yyyy HH:mm', $null)).AddHours(-3.5)
    
        .\ProjectExecEntry.ps1 -Project_Code $project -start_time $executionDatetime
    
    }
}

$allprojects = Import-Csv -Path .\Executions.csv 

$allprojects | ForEach-Object { if ($_.Status -ne 'Done') {$_.Status = "Done"} }

$allprojects | Export-Csv Executions.csv -NoTypeInformation

