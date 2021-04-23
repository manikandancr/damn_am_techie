
$DataSource = "C:\Users\mcr\Documents\frbidb\Processlog.db"
$query = "select * from projects where Run_type = 'MONTHLY'"
function dayextendweekend {

    param ([datetime]$currentday, [object[]]$dayoftheweek)

    $dayofWeek = $dayoftheweek | Where-Object -FilterScript { $_.year -eq $currentday.Year -and $_.month -eq $currentday.Month -and $_.day_of_month -eq $currentday.Day } | select day_of_week
 
 
    if ($dayofWeek.day_of_week -eq 'Sat' -or $dayofWeek.day_of_week -eq 'Sun') {

        if ($dayofWeek.day_of_week -eq 'Sat') {
            Return ($currentday.AddDays(2))
        }
        elseif ($dayofWeek.day_of_week -eq 'Sun') {
            Return ($currentday.AddDays(1))
        }


    }
    else {
        Return $currentday
    }
} #function Ends here

try {
    $monthlyProjects = Invoke-SqliteQuery -DataSource $DataSource -Query $query  
}
catch { write-host "Error occured in updating the table. Please see the connection details." }


$calender = Import-Csv -Path "C:\Users\mcr\Downloads\calendar.csv" 

$calender = $calender | where-object -FilterScript { $_.year -ge '2020' }
 
$filteredcalender = $calender | Where-Object -FilterScript { $_.year -ge '2020' -and $_.day_of_month -eq '1' }

$fullshedule = @()

$getproject = $monthlyProjects.count
[int]$i = 0

foreach ($project in $monthlyProjects) {

    foreach ($days in $filteredcalender) {
   

        $Newobject = [PSCustomObject]@{

            scheduleD    = $(get-date $(dayextendweekend -dayoftheweek $calender  -currentday $((get-date -year $days.year -Month $days.month -day $days.day_of_month).AddDays($project.Run_Schedule).AddDays(-1))) -Format "yyyy-MM-dd")
            project_id   = $project.project_id
            project_code = $project.Project_Code
           
        }

        $fullshedule += $Newobject

        write-host "Year month :" $days.year "-" $days.month

    }

    $i += 1
    write-host "Shedule generated for :"$project.Project_Code " (" $i "/" $getproject ")"
   
}

$fullshedule | export-csv -path ".\MonthlyShedules.csv" -NoTypeInformation

$query = "select * from projects where Run_type = 'WEEKLY' and Run_Schedule != 'On demand'"

try {
    $WeeklyProjects = Invoke-SqliteQuery -DataSource $DataSource -Query $query  
}
catch { write-host "Error occured in updating the table. Please see the connection details." }

$weeksch = @()

foreach ($project in $WeeklyProjects) {
 
    $weekvalue = $calender | where-object -FilterScript {$_.weekday -eq $project.Run_Schedule}

   
    $weekvalue | ForEach-Object {
        $Newobject = [PSCustomObject]@{

            scheduleD    = $(get-date $(get-date -Year $_.year -Month $_.month -Day $_.day_of_month).AddDays(1)-Format "yyyy-MM-dd")
            project_id   = $project.project_id
            project_code = $project.Project_Code

        }

        $weeksch += $Newobject }

    write-host "Weekly project " $project.Project_Code " completed"


}

$weeksch | export-csv -path ".\WeeklySchedules.csv" -NoTypeInformation