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

# where FileNm_Regex = 'TSECGUGA.4505MG*'

Write-host "Start process. Inserting execution ID"

$ExectutionID = CreateExectionID -ProjectCode $ProjectCode -ManualStart "Y" -Datasource $DataSource

write-host "Starting the first step in the process"

$StepDetails =  CreateStepStatus -projectcode $ProjectCode -executionID $ExectutionID  -Datasource $DataSource

try {
$data = Invoke-SqliteQuery -DataSource $DataSource -Query "select Project_ID, fileId, File_Pth,FileFormat, FileNm_Regex, Upd_typ, Cpy_Dest, substr_strt, Substr_end, dt_in_Digits, last_mod_date from FilesWithLastModDate where misc_flag2 is null"
}
Catch {write-host "Database not accessable"}
    
Write-host "Clearing the temp tables"

try {
Invoke-SqliteQuery -DataSource $DataSource -Query "Delete from FileInfo_Temp where ProjectID =  @Project" -SqlParameters @{project = $data.Project_ID[1]}
} 
catch {Write-host "Error in clearing the temp tables. Please check the connection details."}


foreach ($row in $data) {

try {

 $info = get-childitem -path $row.File_Pth | Where-Object -FilterScript {$_.name -match $row.FileNm_Regex } | Select-Object name, @{Name="LastWriteTime";
  Expression={$_.LastWriteTime.ToString("yyyy-MM-dd HH:mm")}}, @{Name="File_dt";
  Expression={ExtractNumbers -InStr $_.name -Substart $row.substr_strt -subend $row.Substr_end -dateindigit $row.dt_in_Digits }},  @{Name="File_size";
  Expression={[math]::round($_.length/(1024*1024),2)}}
  
  }
 catch { write-host "Error in accessing the folder " $row.File_Pth }

  
 foreach ($line in $info) {

 $query = 'Insert into FileInfo_Temp (ProjectID, FileID,Execution_ID, Filename, Lst_Mod_dt, File_size, File_dt ) values (@Project,  @File, @exec, @Filename, @lastmod, @filesize, @fileDt )'

 Try {
 Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
 Project = $row.Project_ID
 File = $row.FileID
 exec = $ExectutionID
 Filename = $line.Name
 lastmod = $line.LastWriteTime
 filesize = $line.File_size
 fileDt = $line.File_dt 
 }
}
catch {write-host "Error writing the database"}
  }
}

#Inserting fileexecutions tables after last modified check

$query = 'Insert into File_Executions (FileID,Execution_id,  Exec_Filename, Exec_File_Size_Mb, Exec_Lst_Mod_Dt, Exec_File_Dt)
select FileID, Execution_ID, Filename, File_size, Lst_Mod_dt, File_dt  from InsertFileExecutions where ProjectID  = @ProjectID'

 Try {
 Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
 ProjectID = $StepDetails.Project_ID 
 }
}
catch {write-host "Error writing the database"}

#Preparing the excel report

$DataQuery = "select a.Mod_Nm as `"Module Name`", a.FileFormat as `"File Format`", a.Exec_Filename as `"Previous Processed File`",a.Exec_File_Size_Mb as `"Previous File size`",a.Exec_Lst_Mod_Dt as `"Previous File date`", 
b.Exec_Filename as `"Current File name`", b.Exec_File_Size_Mb as `"File size`", b.Exec_Lst_Mod_Dt as `"File Date`",
case when  (b.Exec_Filename is null and a.Exec_Filename is not null) then 'NO FILE RECEIVED'
     when  (b.Exec_Filename is null and a.Exec_Filename is null) then 'NO FILE RECEIVED'
     when  (b.Exec_Filename = a.Exec_Filename and a.Exec_File_Size_Mb = b.Exec_File_Size_Mb and  a.Exec_Lst_Mod_Dt = b.Exec_Lst_Mod_Dt) then 'FILE HAS NO CHANGE'
     when  (b.Exec_Filename = a.Exec_Filename and (a.Exec_File_Size_Mb <> b.Exec_File_Size_Mb or  a.Exec_Lst_Mod_Dt <> b.Exec_Lst_Mod_Dt)) then 'FILE HAS CHANGES'
	 when  (b.Exec_Filename <> a.Exec_Filename and (a.Exec_File_Size_Mb <> b.Exec_File_Size_Mb or  a.Exec_Lst_Mod_Dt <> b.Exec_Lst_Mod_Dt)) then 'NEW FILE'
	 END as status
from FilesWithLastModDate a 
left join File_Executions b on a.FileID  = b.FileID
and b.Execution_id = @ExecID
where  a.Misc_Flag2 is NULL
order by a.FileID"


 Try {
 $ReportExcel =Invoke-SqliteQuery -DataSource $DataSource -Query $DataQuery -SqlParameters @{ ExecID = $ExectutionID }
 }
 catch {write-host "Error writing the database"}


 Write-host "Processing the File report..."

 Remove-Item -Path ".\processes.xlsx" -ErrorAction Ignore
 $Txt1  = New-ConditionalText "NO FILE RECEIVED"
 $Txt2  = New-ConditionalText "FILE HAS NO CHANGE" Brown yellow
 $Txt3  = New-ConditionalText "NEW FILE" Green yellow
 $Txt4  = New-ConditionalText "FILE HAS CHANGES" Green cyan

 $ReportExcel | export-excel -Path './processes.xlsx' -AutoSize -AutoFilter -Title "File Report" -WorksheetName FilesReport -Show -FreezePane 2,2 -ConditionalText $Txt1, $Txt2, $Txt3, $Txt4
 
 do {
        $Response = Read-Host -Prompt 'Please verify the Files. Do you want to continue (Y/N) ?'
   } until ($Response -in ('Y','N'))
 if ($Response -ne "Y") { 
 
  $UserComments = Read-host "User comments: "

  #closing the step
  
   EndRun -Datasource $Datasource  -SuccessFlag "N" -stepDetails $StepDetails -ErrorDesc $UserComments

   exit
 }

EndCurrentStep -Datasource $DataSource -SuccessFlag "Y" -stepdetails $stepDetails -ErrorDesc ""
 
$StepDetails =  CreateStepStatus -projectcode $ProjectCode -executionID $ExectutionID  -Datasource $DataSource 


Write-host "Copying the Zip files to the extraction location"

$query = "select distinct File_Pth, b.Exec_Filename, Cpy_Dest  from FileInfo  a   
inner join File_Executions b on a.FileID = b.FileID 
where a.Project_ID = @ProjectCode
and b.Execution_id = @execID
and a.Misc_Flag1 = 'Y'"


 Try {
 $ReportData =Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{ ProjectCode = $StepDetails[0].Project_ID 
 execID = $StepDetails[0].Execution_ID
 }   
 }
 catch {write-host "Error writing the database"}

 #copying the zip files and tar files to a temp folder
 
 foreach ($file in $ReportData ) {

  write-host "Copying file :"$file.Exec_Filename

  Get-ChildItem -path $file.File_Pth | Where-Object -FilterScript {$_.name -eq $file.Exec_Filename } | Copy-Item -Destination $file.Cpy_Dest
  
 }

 Write-host "Copy Complete"

 #Install-Package -Scope CurrentUser -Force 7Zip4PowerShell
 
 Write-host "Unzipping the files" 

 #Extracing .zip files
 get-childitem -path $ReportData.Cpy_Dest[1] | Where-Object -FilterScript {$_.name -like '*.zip*'} | foreach {   Expand-7Zip -ArchiveFileName $_.FullName -TargetPath $($ReportData.Cpy_Dest[1]+"\unzip") }
 #Extracting .tar files
 get-childitem -path $ReportData.Cpy_Dest[1] | Where-Object -FilterScript {$_.name -like '*.tar*'} | foreach {   Expand-7Zip -ArchiveFileName $_.FullName -TargetPath $ReportData.Cpy_Dest[1] }
 #Extracting .7z files
 get-childitem -path $ReportData.Cpy_Dest[1] | Where-Object -FilterScript {$_.name -like '*.7z*'} | foreach {   Expand-7Zip -ArchiveFileName $_.FullName -TargetPath $($ReportData.Cpy_Dest[1]+"\unzip") }

 #inserting the zipped file information

 write-host "Unzip complete"

 Write-host "Updating database with the unzipped file information"

try {
$data = Invoke-SqliteQuery -DataSource $DataSource -Query "select Project_ID, fileId, File_Pth,FileFormat, FileNm_Regex, Upd_typ, Cpy_Dest, substr_strt, Substr_end, dt_in_Digits, last_mod_date from FilesWithLastModDate where misc_flag2 = 'Y'"
}
Catch {write-host "Database not accessable"}


    
Write-host "Clearing the temp tables"


try {
Invoke-SqliteQuery -DataSource $DataSource -Query "Delete from FileInfo_Temp where ProjectID =  @Project" -SqlParameters @{project = $StepDetails[0].Project_ID } #change
} 
catch {Write-host "Error in clearing the temp tables. Please check the connection details."}


foreach ($row in $data) {

try {

 $info = get-childitem -path $row.File_Pth | Where-Object -FilterScript {$_.name -match $row.FileNm_Regex } | Select-Object name, @{Name="LastWriteTime";
  Expression={$_.LastWriteTime.ToString("yyyy-MM-dd HH:mm")}}, @{Name="File_dt";
  Expression={ExtractNumbers -InStr $_.name -Substart $row.substr_strt -subend $row.Substr_end -dateindigit $row.dt_in_Digits }},  @{Name="File_size";
  Expression={[math]::round($_.length/(1024*1024),2)}}
  
  }
 catch { write-host "Error in accessing the folder " $row.File_Pth }

  
 foreach ($line in $info) {

 $query = 'Insert into FileInfo_Temp (ProjectID, FileID,Execution_ID, Filename, Lst_Mod_dt, File_size, File_dt ) values (@Project,  @File, @exec, @Filename, @lastmod, @filesize, @fileDt )'

 Try {
 Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
 Project = $row.Project_ID
 File = $row.FileID
 exec = $ExectutionID
 Filename = $line.Name
 lastmod = $line.LastWriteTime
 filesize = $line.File_size
 fileDt = $line.File_dt
 }
}
catch {write-host "Error writing the database"}
  }
}
 
$query = 'Insert into File_Executions (FileID,Execution_id,  Exec_Filename, Exec_File_Size_Mb, Exec_Lst_Mod_Dt, Exec_File_Dt)
select FileID, Execution_ID, Filename, File_size, Lst_Mod_dt, ifnull(File_dt,"") as File_dt  from InsertFileExecutions where ProjectID  = @ProjectID'

 Try {
 Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
 ProjectID = $StepDetails[0].Project_ID   #change
 }
}
catch {write-host "Error writing the database"}


#copy the files to the source load folder

Write-host "Copying the files to the source load folder"

$query =  "select a.Mod_Nm, a.FileNm_Regex, a.File_Pth, a.Cpy_Dest, a.Backup_Loc, a.Rename_format, b.Exec_Filename, b.Exec_File_Dt, Misc_Flag3 as renameExp from FileInfo a 
inner join File_Executions b on a.FileID = b.FileID and b.Execution_id = @execID
where a.Project_ID = @projectcode  and Misc_Flag1 is null "  #change


 Try {
 $filesData = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
 projectcode = $StepDetails[0].Project_ID   #change
 execID = $ExectutionID
 }
}
catch {write-host "Error writing the database"}

$BackupFolder = $("Back_"+ $ExectutionID +"_" + $(get-date -Format "yyyy_MM_dd_HH_mm"))

write-host "Backup folders will be created with the name :"$BackupFolder


for ($i=0;$i -lt $filesData.Length;$i++)  {

if ($filesData[$i].renameExp.length -ne 0) {

$path= Test-Path $($filesData[$i].backup_loc+"\"+$BackupFolder)

if ($path -eq $false)  {new-item -Path $($filesData[$i].backup_loc+"\"+$BackupFolder) -ItemType Directory | Out-Null} 

Get-ChildItem -Path $filesData[$i].Cpy_Dest -File | Where-Object -FilterScript { $_.name -match $filesData[$i].renameExp} | foreach {


Move-Item -Path $($filesData[$i].Cpy_Dest+"\"+$_.name) -Destination $($filesData[$i].backup_loc+"\"+$BackupFolder)

}

Copy-Item -Path $($filesData[$i].File_Pth+"\"+$filesData[$i].Exec_Filename)  -Destination $filesData[$i].Cpy_Dest 

} else {

$path= Test-Path $($filesData[$i].backup_loc+"\"+$BackupFolder)

if ($path -eq $false)  {new-item -Path $($filesData[$i].backup_loc+"\"+$BackupFolder) -ItemType Directory | Out-Null} 

Get-ChildItem -Path $filesData[$i].Cpy_Dest -File | Where-Object -FilterScript { $_.name -match $filesData[$i].FileNm_Regex} | foreach {

Move-Item -Path $($filesData[$i].Cpy_Dest+"\"+$_.name) -Destination $($filesData[$i].backup_loc+"\"+$BackupFolder)

}

Copy-Item -Path $($filesData[$i].File_Pth+"\"+$filesData[$i].Exec_Filename)  -Destination $filesData[$i].Cpy_Dest 

}

$rename = [string]::IsNullOrWhiteSpace($filesData[$i].Rename_format)

if ($rename -eq $false) {Rename-Item -Path $($filesData[$i].Cpy_Dest+"\"+ $filesData[$i].Exec_Filename) -NewName $filesData[$i].Rename_format.replace('[\d]+',$filesData[$i].Exec_File_Dt)}
}

EndCurrentStep -Datasource $DataSource -SuccessFlag "Y" -stepdetails $stepDetails -ErrorDesc ""
 
$StepDetails =  CreateStepStatus -projectcode $ProjectCode -executionID $ExectutionID  -Datasource $DataSource 

$query = "select Output_ID, Output_Format, Output_Regex, Backup_loc, Output_path
from OutputInfo
where Active = @active
and Project_ID = @ProjectID"


 Try {
 $fileData = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
 ProjectID = $StepDetails[0].Project_ID   #change
 active = 'A'
 }
}
catch {write-host "Error writing the database"}


#backup the output files


foreach ($file in $fileData) {

Get-ChildItem -Path $file.Output_path -File | Where-Object -FilterScript {$_.name -match $file.Output_Regex } | ForEach-Object {

$testpath = test-path -Path $($file.backup_loc+"\"+ $BackupFolder)
if ($testpath -eq $false) {New-Item -Path $($file.backup_loc+"\"+ $BackupFolder) -ItemType Directory}

Copy-Item -Path $_.FullName -Destination $($file.backup_loc+"\"+ $BackupFolder) -Force #change to Move-item
}

}

EndCurrentStep -Datasource $DataSource -SuccessFlag "Y" -stepdetails $stepDetails -ErrorDesc ""
 
$StepDetails =  CreateStepStatus -projectcode $ProjectCode -executionID $ExectutionID  -Datasource $DataSource 


chcp 1252
$EXECMANAGER_PATH="C:\Program Files (x86)\Reportive\10.0\Studio\bin\ExecutionManager.exe"
$CACHES="C:\Users\mcr\TEMP\cache"
$TMPFILE= $($env:TEMP + "\Reportive\Exec.rpt")
$WORKSPACE_PATH="c:\users\mcr\documents\indiviour\indivior_liste_medecins\INDIVIOR"
$logDirectory = "C:\Users\mcr\AppData\Local\Temp\Reportive\wkg\file.log"

Set-Content -Path $TMPFILE -Value "EXECUTE:indivior|filegen|ENDPT-10gk0wz3zvobt1deyz2mq949ky" -Force

$cmdArgList = @(
	"-nojauge",
	"-rootpack",$WORKSPACE_PATH,
	"-instances",$TMPFILE
	"-config",$($WORKSPACE_PATH + "\resources\Production.config")
	"-mode","FULL"
    "-ClearCache"
    "-resetflows"
)

#$Status = & "$EXECMANAGER_PATH" -nojauge -rootpack $WORKSPACE_PATH -instances $TMPFILE -config  $($WORKSPACE_PATH + "\resources\Production.config") -mode FULL -resetflows

$status = & $EXECMANAGER_PATH $cmdArgList

$logInfo = Get-content -Path $logDirectory

if ($status -like '*execution failed*') {write-host "Error in execution"

for ($i=0;$i -lt $logInfo.Length;$i++) {
[String]$logText = $($logText + $logInfo[$i].Replace(";"," ") + "`r`n")
}

$logInfo | Select-String Err| foreach {
[String]$ErrText = $($ErrText + $_.line.Replace(";"," ") + "`r`n")
}

EndRun -Datasource $Datasource  -SuccessFlag "N" -stepDetails $StepDetails -ErrorDesc $ErrText  -Logs $logText 

}

for ($i=0;$i -lt $logInfo.Length;$i++) {
[String]$logText = $($logText + $logInfo[$i].Replace(";"," ") + "`r`n")
}

EndCurrentStep -Datasource $DataSource -SuccessFlag "Y" -stepdetails $stepDetails -logs $logText

$StepDetails =  CreateStepStatus -projectcode $ProjectCode -executionID $ExectutionID  -Datasource $DataSource 


$query = "select Output_ID, Output_Regex, Output_path 
from OutputInfo
where Active = @active
and Project_ID = @projectID"

$insertquery  = "insert into Output_Statistics (Output_ID, Execution_ID, Output_Filename, Output_Filesize, Last_Mod_date)
values (@Output_ID, @Execution_ID, @Output_Filename, @Output_Filesize, @Last_Mod_date)"


 Try {
 $fileData = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
 ProjectID = $StepDetails[0].Project_ID 
 active = 'A'
 }
}
catch {write-host "Error writing the database"}


foreach ($file in $fileData) {


Get-ChildItem -Path $file.Output_path | where-Object -FilterScript {$_.name -match $file.Output_Regex } | ForEach {

 Try {
 Invoke-SqliteQuery -DataSource $DataSource -Query $insertquery -SqlParameters @{
 Output_ID =  $file.Output_ID
 Execution_ID = $ExectutionID
 Output_Filename = $_.Name
 Output_Filesize = $([math]::round($_.Length/(1024*1024),2))
 Last_Mod_date = $($_.LastWriteTime.ToString("yyyy-MM-dd HH:mm"))
 }
}
catch {write-host "Error writing the database"}
}
}

$query = "select Output_Filename FileName,  Output_Filesize as Size, Last_Mod_date as CreatedTime
from Output_Statistics
where Execution_id = @execid"


 Try {
 $OutputData = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
 execid = $ExectutionID  #change
 }
}
catch {write-host "Error writing the database"}

write-host "The list of Cubes generated are as below, " 

 $OutputData | format-table -AutoSize

  do {
        $confirm = Read-Host -Prompt 'Please confirm to end the process as a Success (Y/N)'
   } until ($confirm -in ('Y','N'))


if ($confirm -eq 'Y') {
EndCurrentStep -Datasource $DataSource -SuccessFlag 'Y' -stepdetails $stepDetails 
EndExecutionID -ExecutionID $stepDetails.Execution_id -Status 'Y'  -Datasource $Datasource 
} else { 
$comments = Read-host -Prompt "Please enter comments on why the run is not a success"
EndCurrentStep -Datasource $DataSource -SuccessFlag 'N' -stepdetails $stepDetails -ErrorDesc $comments
EndExecutionID -ExecutionID $stepDetails.Execution_id -Status 'N'  -Datasource $Datasource 
}

