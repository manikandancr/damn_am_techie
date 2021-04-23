$DataSource = "C:\Users\mcr\Downloads\sqlite-tools-win32-x86-3310100\Processlog.db"
$ProjectCode = "LRP"



Function EndExecutionID {

param ([String]$ExecutionID,[String]$Status, [String]$Datasource)

$query =  "Update Executions set Execution_End_time =  @endtime, Success_Flag = @Status, where Execution_id = @ExecutionID"

$Endtime = get-date -Format "yyyy-MM-dd HH:mm"

Try {
Invoke-SqliteQuery -DataSource $DataSource -Query $query  -SqlParameters  @{endtime = $Endtime
Status = $Status
ExecutionID =$ExecutionID 
}
Return ($true)
}
catch { write-host "Error occured in closing execution ID. Please check if the connection parameter are correct"}
Return ($false)
}





Function EndCurrentStep {

param ([String]$Datasource, [String]$SuccessFlag, [object[]]$stepdetails, [String]$ErrorDesc, [String]$logs )

$Endtime = get-date -Format "yyyy-MM-dd HH:mm"

$query = "Update Executable_Statistics set End_Date_time = @endtime, Success_Flag= @sflag, if_Error_Desc = @ErrorDesc, logs = @logs
where Executable_ID = @stepname
and Execution_id = @execid "

try {
Invoke-SqliteQuery -DataSource $DataSource -Query $Query -SqlParameters @{endtime = $Endtime
  sflag = $SuccessFlag
  stepname = $StepDetails.Executable_ID
  execid = $StepDetails.Execution_id
  if_Error_Desc = $ErrorDesc
  logs = $logs
  } }
catch {write-host "Error occured in updating the table. Please see the connection details."}

write-host "Ended step :"$stepdetails.Execution_Step_name
}


$StepDetails =  CreateStepStatus -projectcode $ProjectCode -executionID $ExectutionID  -Datasource $DataSource

EndCurrentStep -Datasource $DataSource -SuccessFlag "N" -stepdetails $stepDetails -ErrorDesc "these are user comments" -logs "This is logs"