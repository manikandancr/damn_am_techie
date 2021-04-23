
$DataSource = "C:\Users\mcr\Documents\frbidb\Processlog.db"
$projectCode = 'Cube PharmaTrend QUIES'

$projdet = Invoke-SqliteQuery -Datasource $Datasource -query 'select * From projects where project_code = @projectcode' -SqlParameters @{
    projectcode = $projectCode
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


$calender = Invoke-SqliteQuery -DataSource $DataSource -Query "Select * from Dimdate" 

if ( $projdet.Run_type -eq 'MONTHLY') {
    
    $fullshedule = @()

    $filteredcalender = $calender | Where-Object -FilterScript { $_.year -ge '2020' -and $_.day_of_month -eq '1' }

    foreach ($days in $filteredcalender) {

        $scheduleDate = $(get-date $(dayextendweekend -dayoftheweek $calender  -currentday $((get-date -year $days.year -Month $days.month -day $days.day_of_month).AddDays($projdet.Run_Schedule).AddDays(-1))) -Format "yyyy-MM-dd")
   

        $Newobject = [PSCustomObject]@{

            scheduleD    = $scheduleDate
            project_id   = $projdet.project_id
            project_code = $projdet.Project_Code
            date_key     = $($calender | Where-Object -FilterScript { $_.date -eq $scheduleDate } | Select-Object date_key ).date_key 
           
        }

        $fullshedule += $Newobject

        write-host "Year month :" $days.year "-" $days.month

    }
  

    $insertstat = "INSERT INTO 'main'.'ProjectSchedule' ('Project_ID', 'Sch_Date_Key', 'Source_Flag', 'Executed_Flag', 'QA_Flag', 'MISC_Flag1', 'MISC_Flag2', 'Plan_Data_Avail_Dt', 'Act_Data_Avail_Dt', 'Act_Run_Dt', 'Plan_Deli_Dt', 'Act_Deli_Dt', 'Prev_Run_Key', 'Next_Run_Key') 
    VALUES (@projectID, @datekey, 'N', 'N', 'N', NULL, NULL, @schdate, NULL, NULL, @schdate, NULL, NULL, NULL)"

    foreach ($sch in $fullshedule) {
     
        Invoke-SqliteQuery -DataSource $DataSource -Query $insertstat -SqlParameters @{

            projectID = $sch.project_id
            datekey   = $sch.date_key
            schdate   = $sch.scheduleD

        }


    }
    

    .\PreviousNextParam.ps1 -DataSource $Datasource -projectid $projdet.Project_id
    write-host "Shedule generated for :"$projdet.Project_Code 

}
elseif ( $projdet.Run_type -eq 'WEEKLY') {

   
    $weeksch = @()
 
    $weekvalue = $calender | where-object -FilterScript { $_.weekday -eq $projdet.Run_Schedule }

   
    $weekvalue | ForEach-Object {
      
        $scheduleDate = $(get-date $(get-date -Year $_.year -Month $_.month -Day $_.day_of_month).AddDays(1)-Format "yyyy-MM-dd")

        $Newobject = [PSCustomObject]@{

            scheduleD    = $scheduleDate
            project_id   = $projdet.project_id
            project_code = $projdet.Project_Code
            date_key     = $($calender | Where-Object -FilterScript { $_.date -eq $scheduleDate } | Select-Object date_key ).date_key  

        }

        $weeksch += $Newobject }

    $insertstat = "INSERT INTO 'main'.'ProjectSchedule' ('Project_ID', 'Sch_Date_Key', 'Source_Flag', 'Executed_Flag', 'QA_Flag', 'MISC_Flag1', 'MISC_Flag2', 'Plan_Data_Avail_Dt', 'Act_Data_Avail_Dt', 'Act_Run_Dt', 'Plan_Deli_Dt', 'Act_Deli_Dt', 'Prev_Run_Key', 'Next_Run_Key') 
        VALUES (@projectID, @datekey, 'N', 'N', 'N', NULL, NULL, @schdate, NULL, NULL, @schdate, NULL, NULL, NULL)"

    foreach ($sch in $weeksch) {
         
        Invoke-SqliteQuery -DataSource $DataSource -Query $insertstat -SqlParameters @{

            projectID = $sch.project_id
            datekey   = $sch.date_key
            schdate   = $sch.scheduleD

        }

    
    
        .\PreviousNextParam.ps1 -DataSource $Datasource -projectid $projdet.Project_id
        write-host "Shedule generated for :"$projdet.Project_Code 


    }


    elseif ($projdet.Run_type -eq 'Trisemestriel') {

        $fullshedule = @()

        $filteredcalender = $calender | Where-Object -FilterScript { $_.year -ge '2020' -and $_.day_of_month -eq '1' -and $_.month -in 3, 6, 9, 12 }

        foreach ($days in $filteredcalender) {

            $scheduleDate = $(get-date $(dayextendweekend -dayoftheweek $calender  -currentday $((get-date -year $days.year -Month $days.month -day $days.day_of_month).AddDays($projdet.Run_Schedule).AddDays(-1))) -Format "yyyy-MM-dd")
   

            $Newobject = [PSCustomObject]@{

                scheduleD    = $scheduleDate
                project_id   = $projdet.project_id
                project_code = $projdet.Project_Code
                date_key     = $($calender | Where-Object -FilterScript { $_.date -eq $scheduleDate } | Select-Object date_key ).date_key 
           
            }

            $fullshedule += $Newobject

            write-host "Year month :" $days.year "-" $days.month

        }
  

        $insertstat = "INSERT INTO 'main'.'ProjectSchedule' ('Project_ID', 'Sch_Date_Key', 'Source_Flag', 'Executed_Flag', 'QA_Flag', 'MISC_Flag1', 'MISC_Flag2', 'Plan_Data_Avail_Dt', 'Act_Data_Avail_Dt', 'Act_Run_Dt', 'Plan_Deli_Dt', 'Act_Deli_Dt', 'Prev_Run_Key', 'Next_Run_Key') 
        VALUES (@projectID, @datekey, 'N', 'N', 'N', NULL, NULL, @schdate, NULL, NULL, @schdate, NULL, NULL, NULL)"

        foreach ($sch in $fullshedule) {
     
            Invoke-SqliteQuery -DataSource $DataSource -Query $insertstat -SqlParameters @{

                projectID = $sch.project_id
                datekey   = $sch.date_key
                schdate   = $sch.scheduleD

            }


        }
    

        .\PreviousNextParam.ps1 -DataSource $Datasource -projectid $projdet.Project_id
        write-host "Shedule generated for :"$projdet.Project_Code 

    }



    
}
   



