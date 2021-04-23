$projectname = 'Lifescan Pharmanalyser Pharmatrend'    #projectCode
$newschedule = 26                                   #new schedule value need Day of the month for Monthly projects, 2-6 monday to Friday for weekly projects
$DataSource = "C:\Users\mcr\Documents\frbidb\Processlog.db"  #db file path

$ScriptOutFile = ".\scripts.sql"

#[datetime]$currentdate  = [datetime]::ParseExact('05-oct-2020','dd-MMM-yyyy',$null)
$currentdate = get-date  #edit here to correct the schedule from a particular day otherwise current date is taken by default


if ($false -eq $(Test-Path -path $ScriptOutFile)) {
    New-Item -ItemType file -Path  $ScriptOutFile | out-null
   
 
}
else {
    Remove-Item $ScriptOutFile
    New-Item -ItemType file -Path  $ScriptOutFile | Out-Null    
}

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



$query = "select * from projects where project_code = @ProjCode"


try {
    $ProjectsInfo = Invoke-SqliteQuery -DataSource $DataSource -Query $query  -SqlParameters @{
        ProjCode = $projectname
    }
}
catch { write-host "Error occured in updating the table. Please see the connection details." }



if ($ProjectsInfo.Run_type -eq "WEEKLY") {


    #Getting the new schedule information from DimDate
    #Current scenario to change the weekday 4 execution to 6 Wed changed to Friday 
    $newschquery = "select date, date_key from dimdate where date > @currentdate and weekday = @newweekday and week > strftime('%W', 'now')"
   
    try {
        $newschedules = Invoke-SqliteQuery -DataSource $DataSource -Query $newschquery  -SqlParameters @{
            newweekday  = $newschedule
            currentdate = $currentdate
        }
    }
    catch { write-host "Error occured in updating the table. Please see the connection details." }

    #Getting the current shedules
    $currentscheduleqry = "select Schedule_ID, project_id From ProjectSchedule a inner join dimdate b on a.Sch_Date_Key = b.date_key where project_id = @projectid and b.date > @currentdate"

    try {
        $currentschedule = Invoke-SqliteQuery -DataSource $DataSource -Query $currentscheduleqry  -SqlParameters @{
            projectid   = $ProjectsInfo.Project_ID
            currentdate = $currentdate
        }
    }
    catch { write-host "Error occured in updating the table. Please see the connection details." }

    $deleteqry = "delete From ProjectSchedule where project_id  = @projectid and Schedule_ID = @ScheduleID"
    #deleting the current schedules
    foreach ($sch in  $currentschedule) {
       
        Invoke-SqliteQuery -DataSource $DataSource -Query  $deleteqry -SqlParameters @{
            projectid  = $sch.Project_ID
            ScheduleID = $sch.Schedule_ID
        }
 
    }
    
    $newschinserqry = "INSERT INTO ProjectSchedule ('Project_ID', 'Sch_Date_Key', 'Source_Flag', 'Executed_Flag', 'QA_Flag', 'MISC_Flag1', 'MISC_Flag2', 'Plan_Data_Avail_Dt', 'Act_Data_Avail_Dt', 'Act_Run_Dt', 'Plan_Deli_Dt', 'Act_Deli_Dt', 'Prev_Run_Key', 'Next_Run_Key') 
    VALUES (@projectid, @schdatekey, 'N', 'N', 'N', '', '', @schdate, '', '', @schdate, '', '', '');"

   
    #inserting new shedules
    foreach ($new in $newschedules) {

      

        Invoke-SqliteQuery -DataSource $DataSource -Query $newschinserqry -SqlParameters @{
       
            projectid  = $ProjectsInfo.Project_ID
            schdatekey = $new.date_key
            schdate    = $new.date.ToString("yyyy-MM-dd")
        }

    }
    
    #update the previous and next run dates 
    .\PreviousNextParam.ps1 -DataSource $Datasource -projectid $ProjectsInfo.Project_id
    
}
elseif ($projectsInfo.Run_type -eq "MONTHLY") {

    #get the each month start date
    $Monthstartqry = "select * from dimdate where date >  @currentdate and day_of_month = 1"

    $Monthstart = Invoke-SqliteQuery -DataSource $DataSource -Query $Monthstartqry -SqlParameters @{
        currentdate = $currentdate

    }

    #getting the full calender
    $fullcalenderqry = 'select * from Dimdate'

    $fullcalender = Invoke-SqliteQuery -DataSource $DataSource -Query $fullcalenderqry 
    
    #null array 
    $fullshedule = @()
    
    #creating the new schedule
    foreach ($day in $Monthstart) {
   
        $scheduleDate = $(get-date $(dayextendweekend -dayoftheweek $fullcalender  -currentday $((get-date -year $day.year -Month $day.month -day $day.day_of_month).AddDays($newschedule ).AddDays(-1))) -Format "yyyy-MM-dd")
    
        $Newobject = [PSCustomObject]@{

            scheduleD    = $scheduleDate 
            project_id   = $projectsInfo.Project_ID
            project_code = $projectsInfo.Project_Code
            date_key     = $($fullcalender | Where-Object -FilterScript { $_.date -eq $scheduleDate } | Select-Object date_key ).date_key    
        }

        $fullshedule += $Newobject

    }

    #get the currrent schedule details
    $currentscheduleqry = "select Schedule_ID, project_id From ProjectSchedule a inner join dimdate b on a.Sch_Date_Key = b.date_key where project_id = @projectid and b.date > @currentdate"


    try {
        $currentschedule = Invoke-SqliteQuery -DataSource $DataSource -Query $currentscheduleqry  -SqlParameters @{
            projectid   = $ProjectsInfo.Project_ID
            currentdate = $currentdate
        }
    }
    catch { write-host "Error occured in updating the table. Please see the connection details." }
  
    #deleting the current schedule
    # $deleteqry = "delete From ProjectSchedule where project_id  = @projectid and Schedule_ID = @ScheduleID"

    $deleteqry = "delete From ProjectSchedule where project_id  = {0} and Schedule_ID = {1};"
    
    foreach ($sch in  $currentschedule) {
       
        $deleteqry -f $sch.Project_ID , $sch.Schedule_ID | Out-File -Append -FilePath $ScriptOutFile
 
    }

    #inserting the new schedule
    $newschinserqry = "INSERT INTO ProjectSchedule ('Project_ID', 'Sch_Date_Key', 'Source_Flag', 'Executed_Flag', 'QA_Flag', 'MISC_Flag1', 'MISC_Flag2', 'Plan_Data_Avail_Dt', 'Act_Data_Avail_Dt', 'Act_Run_Dt', 'Plan_Deli_Dt', 'Act_Deli_Dt', 'Prev_Run_Key', 'Next_Run_Key') 
    VALUES ({0}, {1}, 'N', 'N', 'N', NULL,NULL, '{2}', NULL, NULL,'{3}', NULL, NULL, NULL);"

    foreach ($sch in $fullshedule) {
       
        if ($null -ne $sch.date_key) {


            $newschinserqry -f $sch.Project_ID, $sch.date_key, $sch.scheduleD, $sch.scheduleD | Out-File -Append -FilePath $ScriptOutFile

        }

    }

    #correcting the previous and next load dates\
    #.\PreviousNextParamScript.ps1 -DataSource $Datasource -projectid $ProjectsInfo.Project_id -scriptFilePath $ScriptOutFile


}
