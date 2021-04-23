# param ([String]$ProjectCode)

$ProjectCode =  "Cube PharmaTrend QUIES"

$DataSource = "C:\Users\mcr\Documents\frbidb\PICGRSREP02.db"


$LogFile = ".\PSLog.txt"

function LogMessage {
    param([string]$Message)
    
    ((Get-Date).ToString() + " - " + $Message) >> $LogFile;
}


#..\FunctionLip.ps1
write-host $ProjectCode
import-Module FunctionLib

# where FileNm_Regex = 'TSECGUGA.4505MG*'

#check if the logs have been generated comparing the previous dates


LogMessage -Message "Program started. Fetching the source files information from the DB."

$query = "select a.Project_ID, a.Execution_Path, b.Last_Success_Run as execution_id,strftime ('%Y-%m-%d %H:%M:%S',c.End_Date_time) as End_Date_time from Project_Executables a 
inner join Projects b on a.Project_ID =  b.Project_ID
left join Executable_Statistics c on a.Executable_ID = c.Executable_ID
and b.Last_Success_Run = c.Execution_id
where b.Project_code = @projectCode 
and a.Execution_Order = 1
and a.Active_flag = 'Y'
"

try {
  $lastruninfo = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{projectCode = $ProjectCode }
} 
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }


$queryExec = "select distinct Execution_Path from Project_Executables a inner join Projects b
on a.project_id  = b.project_id 
and b.Project_code = @projectcode
where b.Project_status = 'A'
and a.Active_flag = 'Y'"


try {
  $executionpath1 = Invoke-SqliteQuery -DataSource $DataSource -Query $queryExec -SqlParameters @{projectCode = $ProjectCode }
} 
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }

$split = $executionpath1.Execution_Path -split "@"

$PrjCode = $split[0]
$logpath = $split[1]


#comparing the previous run data with the date in the current logs 

LogMessage -Message "comparing the previous run data with the date in the current logs"

if ($lastruninfo.execution_id -eq $null -or $lastruninfo.execution_id -eq 0) { write-host "No previous run updated. The process will continue.." }
else {

  $lfile = get-childitem -File -Path $logpath | where-object { $_.name -like $($PrjCode + "*") } | sort-object Creationtime -Descending | select -First 1

  if ( $lfile -eq $null ) {
   
    write-host "No logs found in the location. Please see if the parameters are given correctly!"

    LogMessage -Message "No logs found for :"$ProjectCode

    Exit

  }

  else {

  $firstlinecheck = $lfile | foreach { get-content -path $_.Fullname | select -First 1 }
  $lastrundate = [regex]::Match($firstlinecheck, '[0-9]{8}T[0-9]{6}').value

  if ($lastrundate -eq "") {
    $lastrundate = [regex]::Match($firstlinecheck, '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}').value
    $lastrundate  = $lastrundate.Replace("-","").replace(" ","T").replace(":","")
  }

  $value = [datetime]::ParseExact($lastrundate.Replace("T"," ")   , 'yyyyMMdd HHmmss', $null)

  try {
    $previousDate = [datetime]::ParseExact($lastruninfo.End_Date_time, 'yyyy-MM-dd HH:mm:ss', $null) 
  }
  catch {
    "Previous run date not updated. The process will exit"
    exit
  }


  #program will exit if there are no changes in the logs detected
  if ($value -gt $previousDate) { Write-host "The process has updated logs. The program will continue" }
  else { 
    Write-host "No changes detected from the previous. The program will exit."
    Exit 
  }

}



}





#getting the list of files in the logpath
#if first time run : then all the files will be taken
#if not : then all the files which as createtime greater than last run is taken

if ($previousDate -eq $null) {
  $loglist = get-childitem -File -Path $logpath | where-object { $_.name -like $($PrjCode + "*") -and $_.Length -gt 0 } | sort-object lastwritetime 
}
else {
  $loglist = get-childitem -File -path $logpath | where-object { $_.name -like $($PrjCode + "*") -and $_.Length -gt 0 -and $_.CreationTime -gt $previousDate } | sort-object lastwritetime
}

if ($loglist.count -eq 0) {
  Write-host "No logs found in the path. Check if the path/Appid is mentioned correctly "
  exit
}



foreach ($file in $loglist) {

  #Each file is one execution so for each log file on execution ID will be created.

  #$ExectutionID = CreateExectionID -ProjectCode $ProjectCode -ManualStart "N" -Datasource $DataSource

  #$StepDetails = CreateStepStatus -projectcode $ProjectCode -executionID $ExectutionID  -Datasource $DataSource

  #reading the log file
  $readlogs = Get-Content -Path $file.FullName

  #getting the first line in the log
  $firstline = $readlogs | select -First 1 

  $firstlinevalue = [regex]::Match($firstline, '[0-9]{8}T[0-9]{6}').value

  #incase if the file come with the old format
  if ($firstlinevalue -eq "") {
    $firstlinevalue = [regex]::Match($firstline, '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}').value
    $firstlinevalue  = $firstlinevalue.Replace("-","").replace(" ","T").replace(":","")
  }


  $value = [datetime]::ParseExact($firstlinevalue.replace("T"," ") , 'yyyyMMdd HHmmss', $null)

  $starttime = $value.ToString('yyyy-MM-dd HH:mm:ss')
 
  #getting the last line in the log
  $lastline = $readlogs | select -Last 1 

  $lastlinevalue = [regex]::Match($lastline, '[0-9]{8}T[0-9]{6}').value

  #incase if the file come with the old format
  if ($lastlinevalue -eq "") {
    $lastlinevalue = [regex]::Match($lastline, '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}').value
    $lastlinevalue  = $lastlinevalue.Replace("-","").replace(" ","T").replace(":","")
  }
  
  #$lastlinevalue = $lastlinevalue -replace 'T',' '

  $value = [datetime]::ParseExact($lastlinevalue.replace("T"," "), 'yyyyMMdd HHmmss', $null)

  $endtime = $value.ToString('yyyy-MM-dd HH:mm:ss')

  break

  [String]$logstext = $null 

  $readlogs | foreach { $logstext = $($logstext + $_ + "`n") }

  #checking if there are any failures

  $errorinfo = $readlogs | Select-String -Pattern "Execution Failed"

  if ($errorinfo.Length -ne 0 ) {
    write-host "Error while executing the reload"

    [String]$ErrorSting = $null
    #gettting the error messages
    $readlogs | Select-String -Pattern "Error:[\s]*" | ForEach-Object {
 
      $ErrorSting = $($ErrorSting + [regex]::Match($_, "Error:[A-Za-z0-9\\:,\.\' _]*").value + "`n")

    }
    #end the current step
    EndCurrentStep -Datasource $DataSource -SuccessFlag "N" -stepdetails $stepDetails -ErrorDesc $ErrorSting -logs $logstext 

    #getting the user who has executed the step
    [string]$User = $readlogs | Select-String -Pattern "Reload Executed By[\s]*" | ForEach-Object { 

      $String = [regex]::Match($_, 'UserDirectory[a-z_A-Z;= ]*').value
      $Divide = $string -split ";"
      $Domain = $Divide[0].replace("UserDirectory=", "")
      $Username = $Divide[1].replace(" UserId=", "")
      $Domain + "\" + $Username
    } 



    #updating the start time and end time taken from the logs
    $query = "Update Executable_Statistics
set Start_Date_time = @starttime , End_Date_time = @endtime, Executed_as_user = @username 
where Executable_ID = @stepid
and Execution_id= @execution_id"

    try {
      Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{starttime = $starttime
        endtime                                                                           = $endtime
        username                                                                          = $User
        stepid                                                                            = $stepDetails.Executable_ID
        execution_id                                                                      = $stepDetails.Execution_id
      }
    } 
    catch { Write-host "Error in clearing the temp tables. Please check the connection details." }

    $runstatus = 'N'
    Break
    #discontinue if the logs has encountered an error

  } #end of if loop
  else {
 
    write-host "No execution errors found"

    EndCurrentStep -Datasource $DataSource -SuccessFlag "Y" -stepdetails $stepDetails -logs $logstext
  
 
    [string]$User = $readlogs | Select-String -Pattern "Reload Executed By[\s]*" | ForEach-Object { 

      $String = [regex]::Match($_, 'UserDirectory[a-z_A-Z;= ]*').value
      $Divide = $string -split ";"
      $Domain = $Divide[0].replace("UserDirectory=", "")
      $Username = $Divide[1].replace(" UserId=", "")
      $Domain + "\" + $Username
 
    } 

    #updating the starttime and end time for the step, sucess
 
    $query = "Update Executable_Statistics
set Start_Date_time = @starttime , End_Date_time = @endtime, Executed_as_user = @username 
where Executable_ID = @stepid
and Execution_id= @execution_id"

    try {
      Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{starttime = $starttime
        endtime                                                                           = $endtime
        username                                                                          = $User
        stepid                                                                            = $stepDetails.Executable_ID
        execution_id                                                                      = $stepDetails.Execution_id
      }
    } 
    catch { Write-host "Error in clearing the temp tables. Please check the connection details." }

    $runstatus = 'Y'

  }  #end of else


  if ($runstatus -eq 'Y' ) {

    $scriptstatus = EndExecutionID -ExecutionID $ExectutionID -Status 'Y'  -Datasource $Datasource 

    if ($scriptstatus -eq $true) { write-host "Execution ID ended" }
    #updating executions project table with current execution ID
    $query = "update projects
set Last_Success_Run = @execid
where Project_Code = @projectcode"

    try {
      Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
        execid      = $ExectutionID
        projectcode = $ProjectCode
      }
    } 
    catch { Write-host "Error in clearing the temp tables. Please check the connection details." }

  } 
  else {

    $scriptstatus = EndExecutionID -ExecutionID $ExectutionID -Status 'N'  -Datasource $Datasource 

    if ($scriptstatus -eq $true) { write-host "Execution ID ended" }

  }


  $query = 'select distinct Executed_as_user,  min(Start_Date_time) Exec_Start_Time, max(End_Date_time) as Exec_End_time from Executable_Statistics
where Execution_id = @execid'

  try {
    $updateexec = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
      execid = $ExectutionID
    }
  } 
  catch { Write-host "Error in database connection parameters" }
  #updating executions tables with starttime from the first log and end time from the last log

  $query = 'update Executions
set Executed_as_name = @username, Execution_Start_time = @starttm, Execution_End_time = @endtm
where Execution_id = @execid'

  try {
    Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
      execid   = $ExectutionID
      username = $updateexec.Executed_as_user
      starttm  = $updateexec.Exec_Start_Time
      endtm    = $updateexec.Exec_End_time
    }
  } 
  catch { Write-host "Error in clearing the temp tables. Please check the connection details." }


} #end of for loop


#adding the file_execution insertion part
LogMessage -Message "adding the file_execution insertion part"


$currSourceQry = "select * from currentsourcefileDet a inner join projects b on a.project_id = b.project_id
                    where b.project_code  = @projectcode"
 
try {
  $currentSouce = Invoke-SqliteQuery -DataSource $DataSource -Query $currSourceQry -SqlParameters @{
    projectcode = $ProjectCode
                        
  }
} 
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }  
  
if ($currentSouce.count -eq 0 ) {

  write-host "No source information to update. Program will continue"

}
else {
  foreach ($source in $currentSouce) {
    $getExeIDqry = "select max(execution_id) as execid from executions a inner join projects b on a.project_id = b.project_id where b.project_code  = @projcode and a.Success_Flag = 'Y'"

    
    try {

      $maxexecID  = Invoke-SqliteQuery -DataSource $DataSource -Query $getExeIDqry -SqlParameters @{
        projcode = $ProjectCode
              
      }
    } 
    catch { Write-host "Error in getting the max execution id. Please check!" }  



    $fileExequery = "INSERT INTO File_Executions (FileID, execution_id, Exec_Filename, Exec_Lst_Mod_Dt)
            values (@fileID, @ExecID, @filename, @filelastmoddate)"


    try {
      Invoke-SqliteQuery -DataSource $DataSource -Query $fileExequery -SqlParameters @{
        fileID          = $source.FileID
        ExecID          = $maxexecID.execid
        filename        = $source.filename
        filelastmoddate = $source.LastModDate              
      }
    } 
    catch { Write-host "Error in inserting file_executions tables. Please check!" }  


  }

}


LogMessage -Message "Program ended"