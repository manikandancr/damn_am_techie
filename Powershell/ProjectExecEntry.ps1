# param (
# [String]$Project_Code,
# [Datetime]$start_time
# )

$DataSource = "C:\Users\mcr\Documents\frbidb\Processlog.db"
$Project_Code = 'Uriage HQ - Portugal'
[datetime]$start_time = "2020-12-23 10:15:28"
$timeIncre = New-TimeSpan -Minutes 2 -Seconds 30
$stmtTable = ".\DemoEntries.db"

$Projdet = "select * from projects where project_code = @projeccode"

try {
    $Projects = Invoke-SqliteQuery -DataSource $DataSource -Query $Projdet -SqlParameters @{
        projeccode = $Project_Code
    }
} 
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }


$projstepQry = 'select * from project_executables where project_id = @projectID order by Execution_Order'

try {
    $Projectsdet = Invoke-SqliteQuery -DataSource $DataSource -Query $projstepQry -SqlParameters @{
        projectID = $Projects.Project_ID
    }
} 
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }



if ($Projectsdet.count -eq 0) {
   
    #insert the details
  
    try {
        $InsertSteps = Invoke-SqliteQuery -DataSource $stmtTable -Query "select * from Project_Executables" 
    } 
    catch { Write-host "Error in clearing the temp tables. Please check the connection details." }
   
    $insrtQry = "Insert into Project_Executables 
                    (Project_ID,
                    Execution_Order,
                    Execution_Step_name,
                    Execution_Desc,
                    Execution_Path,
                    Active_flag,
                    Stop_on_Failure,
                    Create_Logs) 
                    values 
                        (@Projectid, 
                        @order, 
                        @step_name,
                        @step_desc, 
                        @path , 
                        @active,
                        @stop, 
                        @createlogs)"

    foreach ($InsertStep in $InsertSteps) {                   

        try {
            Invoke-SqliteQuery -DataSource $DataSource -Query $insrtQry -SqlParameters @{
                Projectid  = $Projects.Project_ID
                order      = $InsertStep.Execution_Order
                step_name  = $InsertStep.Execution_Step_name
                step_desc  = $InsertStep.Execution_Desc
                path       = $InsertStep.Execution_Path
                active     = $InsertStep.Active_flag
                stop       = $InsertStep.Stop_on_Failure
                createlogs = $InsertStep.Create_Logs
            } 
        }
        catch { Write-host "Error in clearing the temp tables. Please check the connection details." }
       
    }
 
    try {
        $Projectsdet = Invoke-SqliteQuery -DataSource $DataSource -Query $projstepQry -SqlParameters @{
            projectID = $Projects.Project_ID
        }
    } 
    catch { Write-host "Error in clearing the temp tables. Please check the connection details." }
}

#inserting executions

$ExecQuery = "Insert into Executions (
    Executed_as_name,
    Manual_Start,
    Execution_Start_time,
    Project_ID )
    values (@username, @manual, @starttime, @ProjectID)"


try {
    Invoke-SqliteQuery -DataSource $DataSource -Query $ExecQuery -SqlParameters @{
        username  = $($env:UserDomain + '\' + $env:UserName)
        manual    = 'Y'
        starttime = $start_time 
        ProjectID = $Projects.Project_ID
    }
}
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }

$execIDqry = 'select max(execution_id) as execID from executions where project_id = @projectID'


try {
    $execid = Invoke-SqliteQuery -DataSource $DataSource -Query $execIDqry -SqlParameters @{
        projectID = $Projects.Project_ID
    }
}
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }


foreach ($step in $Projectsdet) {

    $stepqry = " insert into Executable_Statistics (
                    Executable_ID,
                    Execution_id,
                    Start_Date_time,
                    End_Date_time,
                    Success_Flag,
                    Executed_as_user )
                    values (@stepid, @excecid, @startime, @endtime, @sflag, @username)"


    try {
        Invoke-SqliteQuery -DataSource $DataSource -Query $stepqry -SqlParameters @{
            stepid   = $step.Executable_ID
            excecid  = $execid.execID
            startime = $start_time
            endtime  = $($start_time + $timeIncre)
            sflag    = 'Y'
            username = $($env:UserDomain + '\' + $env:UserName)
        }
    }
    catch { Write-host "Error in clearing the temp tables. Please check the connection details." }

    $start_time = $start_time + $timeIncre

}


$updateqry = "update executions
set  Execution_End_time = @endtime, Success_Flag = 'Y'
where execution_id = @execid"

try {
    Invoke-SqliteQuery -DataSource $DataSource -Query $updateqry -SqlParameters @{
        execid  = $execid.execID
        endtime = $start_time
    }
}
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }


$sourequery = "Select distinct project_id from tobeprocessedSource where project_id = @project_id"

try {
    $unprosource = Invoke-SqliteQuery -DataSource $DataSource -Query $sourequery -SqlParameters @{
        project_id = $projects.Project_ID
    }
}
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }


if ($unprosource.count -ne 0) {

    $lsourceqry = "Select * from currentsourcefiledet where project_id = @project_id"

    try {
        $lsource = Invoke-SqliteQuery -DataSource $DataSource -Query $lsourceqry -SqlParameters @{
            project_id = $projects.Project_ID
        }
    }
    catch { Write-host "Error in clearing the temp tables. Please check the connection details." }

    $filexequery = "INSERT INTO File_Executions (
                    FileID,
                    Execution_id,
                    Exec_Filename,
                    Exec_File_Size_Mb,
                    Exec_Lst_Mod_Dt,
                    Exec_File_Dt
                    )
                    values (@fileid, @execid, @filename, @sizemb, @latmodDate, @filedate)"  

    foreach ($source in $lsource) {


        try {
            Invoke-SqliteQuery -DataSource $DataSource -Query $filexequery -SqlParameters @{
                fileid     = $source.FileID
                execid     = $execid.execID
                filename   = $source.filename
                sizemb     = 0
                latmodDate = $source.LastModDate
                filedate   = ""
            }
        }
        catch { Write-host "Error in clearing the temp tables. Please check the connection details." }

      
    }
 

}


$sourceUpdatequery = "select a.project_id, b. project_code, min (a.Schedule_ID) as Schedule_ID from ProjectSchedule a inner join 
(select * from projects a 
where project_id not in (select DISTINCT project_id from FileInfo where Misc_Flag5 = 'Y')
and a.Project_status = 'A' ) b on a.project_id = b.project_id
left join dimdate c on a.Prev_Run_Key = c.date_key 
left join dimdate d on a.Next_Run_Key = d.date_key
where date('now') < d.date
and date('now')>  c.date
and a.project_id = @project_id
and a.Executed_Flag = 'N'
Group by a.project_id, b. project_code"


try {
    $souravail = Invoke-SqliteQuery -DataSource $DataSource -Query $sourceUpdatequery -SqlParameters @{
        project_id = $projects.Project_ID
    }
}
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }


if ($souravail.Count -ne 0) {

 $sourceAvailUpd = 'Update ProjectSchedule set Act_Data_Avail_Dt = @sourcetime where Schedule_ID = @scheduleID and project_id = @project_ID'
 $sourceupddate  = $Start_time.AddMinutes(-10)



try {
      Invoke-SqliteQuery -DataSource $DataSource -Query $sourceAvailUpd -SqlParameters @{
        project_ID = $projects.Project_ID
        sourcetime = $sourceupddate
        scheduleID = $souravail.Schedule_ID
    }
}
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }



}