Function ExtractNumbers {
  param([string]$InStr, [int]$Substart, [int]$subend, [string]$dateindigit)
    
   if ($dateindigit -eq 'Y') {

   if ($subend -eq 0 ) {
      $Out = $InStr.Substring($Substart) -replace ("[^\d{6,}]")
   }

   if ($subend -gt 0 ) {
      $Out = $InStr.Substring($Substart,$subend) -replace ("[^\d{6,}]")
   }

   try{return [int]$Out}
       catch{}
   try{return [uint64]$Out}
       catch{return 0}


   }else {
   
   
  if ($subend -eq 0 ) {
      $Out = $InStr.Substring($Substart).Trim()
   }

  if ($subend -gt 0 ) {
      $Out = $InStr.Substring($Substart,$subend).Trim()
   }

   try{return [String]$Out}
       catch{}
   try{return [String]$Out}
       catch{return 0}
   
   
   }    
   }
Function CreateExectionID {
param ([String]$ProjectCode,[String]$ManualStart, [String]$Datasource)

Try {
$ProjectID  = Invoke-SqliteQuery -DataSource $DataSource -Query "select Project_ID as ID from Projects where Project_code = @projectcode" -SqlParameters @{projectcode = $ProjectCode}
}
catch { write-host "ProjectID cannot be fetched. Make sure the datasource is correct."}


$ExecutionQry  = 'Insert into Executions (Executed_as_name, Manual_Start, Execution_Start_time, Project_ID) values (@User, @Manual, @StartDate, @ProjectID)' 
$Curr_User = "$env:userdomain\$env:username"
$Starttime = get-date -Format "yyyy-MM-dd HH:mm"

try {

Invoke-SqliteQuery -DataSource $DataSource -Query $ExecutionQry -SqlParameters @{User = $Curr_User 
 Manual = $ManualStart 
 StartDate = $Starttime 
 ProjectID = $ProjectID.ID }


$ExecutionID = Invoke-SqliteQuery -DataSource $DataSource -Query "Select max(Execution_id) as Exec from Executions where Project_ID = @Project and Success_Flag = 'I'" -SqlParameters @{Project = $ProjectID.ID}

}
Catch {write-host "Error in generating execution ID. Please see the connection are correct"}

   try{return [int]$ExecutionID.Exec}
       catch{}
   try{return [uint64]$ExecutionID.Exec}
       catch{return 0}
  

}


Function EndExecutionID {

param ([String]$ExecutionID,[String]$Status, [String]$Datasource)

$query =  "Update Executions set Execution_End_time =  @endtime, Success_Flag = @Status where Execution_id = @ExecutionID"

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
