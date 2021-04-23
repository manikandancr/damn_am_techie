$DataSource = "C:\Users\mcr\Downloads\sqlite-tools-win32-x86-3310100\Processlog.db"
$ProjectCode = "LRP"

Function EndRun {
param([String]$Datasource, [String]$SuccessFlag, [Object[]]$stepDetails, [String]$ErrorDesc, [String]$Logs )


EndCurrentStep -Datasource $DataSource -SuccessFlag $SuccessFlag -stepdetails $stepDetails -ErrorDesc $ErrorDesc -logs $Logs 
$status = EndExecutionID -ExecutionID $stepDetails.Execution_id -Status $SuccessFlag  -Datasource $Datasource 

if ($status -eq $true) {
Write-Host "Error occured in the step :" $stepDetails.Execution_Step_name ". Please see the error description" 
Exit}

}

#..\FunctionLip.ps1

import-Module FunctionLib


$ExectutionID = CreateExectionID -ProjectCode $ProjectCode -ManualStart "Y" -Datasource $DataSource

write-host "Starting the first step in the process"

$StepDetails =  CreateStepStatus -projectcode $ProjectCode -executionID $ExectutionID  -Datasource $DataSource

  #coding done here for step 1

#if Successfull End step
EndCurrentStep -Datasource $DataSource -SuccessFlag "Y" -stepdetails $stepDetails -ErrorDesc ""
 
 #start the next step

 $StepDetails =  CreateStepStatus -projectcode $ProjectCode -executionID $ExectutionID  -Datasource $DataSource 

 
 #finally
 EndExecutionID -ExecutionID $stepDetails.Execution_id -Status $SuccessFlag  -Datasource $Datasource 

