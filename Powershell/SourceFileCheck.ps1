$DataSource = "C:\Users\mcr\Downloads\sqlite-tools-win32-x86-3310100\Processlog_FC.db"
#..\FunctionLip.ps1
#creating an in-memory database to do file ordering
$tempDB = New-SQLiteConnection -DataSource :MEMORY:
 
import-Module FunctionLib

# where FileNm_Regex = 'TSECGUGA.4505MG*'

$batch = [guid]::NewGuid().ToString()
$Rundatetime = Get-Date -Format "yyyy-MM-dd hh:mm:ss"
$SourceDet = @()


Function getFTPfilelist {
  param([string]$FTPpath)

$FTPUser = "Ceg_CegersRead"  #username
$password = ConvertTo-SecureString "0r12N0LF" -AsPlainText -Force  #password needs to changed 
$FTPserver = "80.94.177.246"

$credentials = New-Object System.Management.Automation.PSCredential($FTPUser, $password)
Set-FTPConnection -Credential $credentials -Server $FTPserver -Session FTP -ignoreCert -UseBinary -KeepAlive

Start-Sleep -Seconds 20

$Session = Get-FTPConnection -Session FTP

Start-Sleep -Seconds 10

$filelist = Get-FTPChildItem -Session $Session -Path $FTPpath -filter *.* 

return $filelist
}


#check if the logs have been generated comparing the previous dates

$query = "select * from FileInfo where Misc_Flag5 = 'Y'"

try {
  $Souredetails = Invoke-SqliteQuery -DataSource $DataSource -Query $query 
} 
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }


#comparing the previous run data with the date in the current logs 

foreach ($source in $($Souredetails | Where-Object -FilterScript {$_.mod_nm -ne "FTP"})) {

   $filelist =  Get-ChildItem -Path $source.File_Pth -File -Recurse | Where-Object -FilterScript {$_.name -Match $source.FileNm_Regex } |  Sort-Object LastWriteTime -Descending | Select-Object -first 1

   foreach ($file in $filelist) {
      
      $filedet = [PSCustomObject]@{
      batch = $batch
      RunDatetime = $Rundatetime
      ProjectID = $source.Project_ID
      FileID = $source.FileID
      Filename = $file.Name
      LastModDate = $($file.LastWriteTime.ToString("yyyy-MM-dd hh:mm:ss"))
      CurrentPath = $file.Directory
      }
     
      $SourceDet +=  $filedet
   }
}


foreach ($path in $($Souredetails | Where-Object -FilterScript {$_.mod_nm -eq "FTP"} | select-object File_Pth | sort-object File_Pth -Unique) ) {

  $filelistFTP = getFTPfilelist -FTPpath $path.File_Pth

  $filelistfull=@()

  $filelistFTP | ForEach-Object { 
    
    $filetest = [PSCustomObject]@{
        LastModDate =  $_.modifiedDate
        Filename = $_.name
        CurrentPath = $_.Parent
        }

        $filelistFull += $filetest
  } 

  Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "CREATE TABLE TEMP_FTP_FILES (FILENAME TEXT, LASTMODIFIED DATETIME, FTPPATH TEXT)"

  foreach ($file in $filelistfull) {

   

    Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "INSERT INTO TEMP_FTP_FILES (FILENAME, LASTMODIFIED, FTPPATH) VALUES (@filename,@moddate,@path);" -SqlParameters @{filename = $file.FileName 
      moddate = $file.LastModDate
      path = $file.CurrentPath } 
  }

 foreach ($sources in $($Souredetails | Where-Object -FilterScript {$_.File_Pth -eq $path.File_Pth})) {

  $results = Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "select filename, LASTMODIFIED, ftppath from TEMP_FTP_FILES
  where filename like @filter
  order by LASTMODIFIED desc limit 1" -SqlParameters @{filter = $sources.FileNm_Regex.replace("*","%")} 

  foreach($result in $results) {

    $filedet = [PSCustomObject]@{
      batch = $batch
      RunDatetime = $Rundatetime
      ProjectID = $sources.Project_ID
      FileID = $sources.FileID
      Filename = $result.filename
      LastModDate = $($result.LASTMODIFIED.ToString("yyyy-MM-dd hh:mm:ss"))
      CurrentPath = $result.ftppath
      }
     
      $SourceDet +=  $filedet

  }

  
   
 }
  
 Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "DROP TABLE TEMP_FTP_FILES"

}
 
$insertquery = "INSERT INTO SourceInfo ( Batch, RunDateTime, Project_ID, FileName, LastModDate, CurrentPath, FileID) VALUES (@batch, @runtime, @project_id, @filename, @lastmoddate, @currentpath, @FileID)"




foreach ($sources in $SourceDet) { 

  $query = 'Select LastModDate from LatestSourceDet where project_id = @projectid and fileid = @fileid'

  $lastModateDB = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
    projectid = $sources.projectID
    fileid    = $sources.FileID
  }

  write-host $lastModateDB.count -eq 0

  if ($lastModateDB.count -eq 0) {


    $sources.batch
    $query

      Invoke-SqliteQuery -DataSource $DataSource -Query $insertquery -SqlParameters @{
        batch       = $sources.batch
        runtime     = $sources.RunDatetime
        project_id  = $sources.projectID
        FileID      = $sources.FileID
        filename    = $sources.filename
        lastmoddate = $sources.lastmoddate
        currentpath = $sources.currentpath
      }

  } else {
   
    if ($([datetime]::parseexact($lastModateDB.LastModDate, 'yyyy-MM-dd HH:mm:ss', $null)) -lt $sources.lastmoddate -and $null -ne $lastModateDB.LastModDate ) {

      Invoke-SqliteQuery -DataSource $DataSource -Query $insertquery -SqlParameters @{
        batch       = $sources.batch
        runtime     = $sources.RunDatetime
        project_id  = $sources.projectID
        FileID      = $sources.FileID
        filename    = $sources.filename
        lastmoddate = $sources.lastmoddate
        currentpath = $sources.currentpath
      }
    }
    else {
      continue
    }

  }

  

}




