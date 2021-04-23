$DataSource = "C:\Users\mcr\Downloads\sqlite-tools-win32-x86-3310100\Processlog_F.db"
$ProjectCode = "Chugai"


#..\FunctionLip.ps1

import-Module FunctionLib

# where FileNm_Regex = 'TSECGUGA.4505MG*'


#check if the logs have been generated comparing the previous dates

$query = "select a.Project_ID, a.Execution_Path, b.Last_Success_Run as execution_id,strftime ('%Y-%m-%d %H:%M',c.End_Date_time) as End_Date_time from Project_Executables a 
inner join Projects b on a.Project_ID =  b.Project_ID
left join Executable_Statistics c on a.Executable_ID = c.Executable_ID
and b.Last_Success_Run = c.Execution_id
where b.Project_Code = @projectCode 
and a.Execution_Order = 1
and a.Active_flag = 'Y'
"

try {
  $lastruninfo = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{projectCode = $ProjectCode }
} 
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }


#comparing the previous run data with the date in the current logs 

if ($null -eq $lastruninfo.execution_id ) { write-host "No previous run updated. The process will continue.." }
else {

  $firstline = get-content -path $lastruninfo.Execution_Path | Select-Object -First 1 
  $lastrundate = [regex]::Match($firstline, '[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}').value

  $value = [datetime]::ParseExact($lastrundate, 'dd/MM/yyyy HH:mm:ss', $null)

  $previousDate = [datetime]::ParseExact($lastruninfo.End_Date_time, 'yyyy-MM-dd HH:mm', $null)

  #program will exit if there are no changes in the logs detected
  if ($value -gt $previousDate) { Write-host "The process has updated logs. The program will continue" }
  else { 
    Write-host "No changes detected from the previous. The program will exit."
    Exit 
  }
}



#getting the step count
$query = "select count(*) as Stepcount from Project_Executables a 
inner join Projects b on a.Project_ID = b.Project_ID
where b.Project_Code = @projectcode
and a.Active_flag = 'Y'"


try {
  $stepcount = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{projectcode = $ProjectCode }
} 
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }

[int]$step = $stepcount.Stepcount

Write-host "Start process. Inserting execution ID"

$ExectutionID = CreateExectionID -ProjectCode $ProjectCode -ManualStart "N" -Datasource $DataSource


#starting a loop based on the step count

for ($i = 1 ; $i -le $step; $i++) {

  $StepDetails = CreateStepStatus -projectcode $ProjectCode -executionID $ExectutionID  -Datasource $DataSource

  #reading the log file
  $readlogs = Get-Content -Path $StepDetails.Execution_Path

  #getting the first line in the log
  $firstline = $readlogs | Select-Object -First 1 

  $value = [datetime]::ParseExact([regex]::Match($firstline, '[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}').value, 'dd/MM/yyyy HH:mm:ss', $null)

  $starttime = $value.ToString('yyyy-MM-dd HH:mm')

  write-host "Start time :"  $starttime
 
  #getting the last line in the log
  $lastline = $readlogs | Select-Object -Last 1 

  $value = [datetime]::ParseExact([regex]::Match($lastline, '[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}').value, 'dd/MM/yyyy HH:mm:ss', $null)

  $endtime = $value.ToString('yyyy-MM-dd HH:mm')

  write-host "end time :" $endtime

  [String]$logstext = $null 

  $readlogs | ForEach-Object { $logstext = $($logstext + $_ + "`n") }

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

      [regex]::Match($_, '[A-Za-z0-9-]*\\[A-Za-z0-9]+').value
 
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

      [regex]::Match($_, '[A-Za-z0-9-]*\\[A-Za-z0-9]+').value
 
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

} #end of for loop


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
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }
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


