$projectname = 'CAF'
$newschedule = 6
$DataSource = "C:\Users\mcr\Documents\frbidb\Processlog.db"
$currentdate = get-date
$tempDB = New-SQLiteConnection -DataSource :MEMORY:

$query = "select * from projects where project_code = @ProjCode"


try {
    $ProjectsInfo = Invoke-SqliteQuery -DataSource $DataSource -Query $query  -SqlParameters @{
        ProjCode = $projectname
    }
}
catch { write-host "Error occured in updating the table. Please see the connection details." }



if ($ProjectsInfo.Run_type -eq "WEEKLY") {

    $currentscheduleqry = "select Schedule_ID, Sch_Date_Key, project_id, b.year, b.week, b.weekday  From ProjectSchedule a inner join dimdate b on a.Sch_Date_Key = b.date_key where project_id = @projectid and b.date > @currentdate"

    try {
        $currentschedule = Invoke-SqliteQuery -DataSource $DataSource -Query $currentscheduleqry  -SqlParameters @{
            projectid   = $ProjectsInfo.Project_ID
            currentdate = $currentdate
        }
    }
    catch { write-host "Error occured in updating the table. Please see the connection details." }
   

    $newschquery = 'select year, week, date, date_key from dimdate where date > @currentdate and weekday = @newweekday'
   

    try {
        $newschedule = Invoke-SqliteQuery -DataSource $DataSource -Query $newschquery  -SqlParameters @{
            newweekday  = $newschedule
            currentdate = $currentdate
        }
    }
    catch { write-host "Error occured in updating the table. Please see the connection details." }
   
    #create temp tables for storing

    Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "Drop table Temp_currentschedule;
                                                         drop table Temp_Newschedule; "
    Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "
                                                            CREATE TABLE Temp_currentschedule (
                                                            Schedule_ID INT,
                                                            Sch_Date_Key INT,
                                                            Project_ID INT,
                                                            year INT,
                                                            week INT,
                                                            weekday INT
                                                            );

                                                            CREATE TABLE Temp_Newschedule(
                                                                year INT,
                                                                week INT,
                                                                date TEXT,
                                                                date_key INT
                                                              );                                                            
                                                            "

    foreach ($i in $currentschedule) {
      
        Invoke-SqliteQuery -SQLiteConnection $tempDB -query "Insert into Temp_currentschedule values (@Schedule_ID, @Sch_Date_Key, @project_id, @year, @week, @weekday)" -SqlParameters @{
            Schedule_ID  = $i.Schedule_ID
            Sch_Date_Key = $i.Sch_Date_Key
            project_id   = $i.project_id
            year         = $i.year
            week         = $i.week
            weekday      = $i.weekday 
        }

    
    }    
        
    foreach ($j in $newschedule) {
      
        Invoke-SqliteQuery -SQLiteConnection $tempDB -query " insert into Temp_newschedule values (@year, @week, @date, @date_key)" -SqlParameters @{
            year     = $j.year
            week     = $j.week
            date     = $j.date
            date_key = $j.date_key
          
        }

    }   


    $newschupdate = Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "select a.Schedule_ID, b.date_key as Sch_Date_Key, b.date, a.project_id from Temp_currentschedule a inner join Temp_newschedule b on a.year = b.year and a.week = b.week"

    $newschdelate = Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "select a.Schedule_ID, b.date_key as Sch_Date_Key, b.date, a.project_id from Temp_currentschedule a left join Temp_newschedule b on a.year = b.year and a.week = b.week where b.week is null"

    foreach ($schid in $newschupdate) {
          
        $updateqry = "update ProjectSchedule
                    SET Sch_Date_Key = @Sch_Date_Key, Plan_Data_Avail_Dt = @date, Plan_Deli_Dt = @date
                    where Schedule_ID = @Schedule_ID
                    and project_id =  @project_id"
        try {
            Invoke-SqliteQuery -DataSource $DataSource -Query $updateqry -SqlParameters @{
                Sch_Date_Key = $schid.Sch_Date_Key
                date         = $schid.date
                Schedule_ID = $schid.Schedule_ID
                project_id   = $schid.project_id
            }             
        }
        catch { write-host "Error in updating schedule" }
 
    }


    foreach ($schid in  $newschdelate) {
          
        $delqry = "delete from projectschedule where project_id  = @project_id and Schedule_ID = @schid"
        try {
            Invoke-SqliteQuery -DataSource $DataSource -Query $delqry -SqlParameters @{
                project_id = $schid.Project_ID
                schid         = $schid.Schedule_ID
               
            }             
        }
        catch { write-host "Error in updating schedule" }
 
    }

     #update the previous and next run dates 
    .\PreviousNextParam.ps1 -DataSource $Datasource -projectid $ProjectsInfo.Project_id
    
}
elseif ($projectsInfo.Run_type -eq "MONTHLY") {
    #Monthly projects code goes here..    
}