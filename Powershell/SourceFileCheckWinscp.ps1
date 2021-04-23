$DataSource = "D:\Automation\DatabaseFile\PICGRSREP02.db"
#..\FunctionLip.ps1
#creating an in-memory database to do file ordering
$tempDB = New-SQLiteConnection -DataSource :MEMORY:


$LogFile = ".\PSLog.txt"

function LogMessage {
    param([string]$Message)
    
    ((Get-Date).ToString() + " - " + $Message) >> $LogFile;
}
 
import-Module FunctionLib

# where FileNm_Regex = 'TSECGUGA.4505MG*'

$batch = [guid]::NewGuid().ToString()
$Rundatetime = Get-Date -Format "yyyy-MM-dd hh:mm:ss"
$SourceDet = @()

if (Test-Path $LogFile) {
    Remove-Item $LogFile
}

function getFTPfilelistWin {

    param ([string]$Ftppath)

    try {
        # Load WinSCP .NET assembly
        Add-Type -Path "WinSCPnet.dll"
     
        # Setup session options
        $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
            Protocol              = [WinSCP.Protocol]::Sftp
            HostName              = "80.94.177.246"
            UserName              = "Ceg_CegersRead"
            Password              = "0r12N0LF"
            SshHostKeyFingerprint = "ssh-rsa 2048 6djv1DIAvzeAw7/25FYB5p8FCJyTof82/C5VKl2juTU="
        }
    }
    catch { Write-Verbose "Error creating a FTP session"
                exit 0 }
        
    $sessionOptions.AddRawSettings("FSProtocol", "2")
    
    $session = New-Object WinSCP.Session

    try {

         
        $session.Open($sessionOptions)
    
        $directory = $session.ListDirectory($Ftppath)
    
        # foreach ($file in $directory.Files) {
    
        #     $file.Name
        #     $file.LastWriteTime
        # }

        Return $directory
    
        $session.Dispose()

    }
    catch { write-host "Error in opening the FTP session. Please check" }
           

}


#check if the logs have been generated comparing the previous dates


LogMessage -Message "Program started. Fetching the source files information from the DB."

$query = "select * from FileInfo where Misc_Flag5 = 'Y'"

try {
    $Souredetails = Invoke-SqliteQuery -DataSource $DataSource -Query $query 
} 
catch { Write-host "Error in clearing the temp tables. Please check the connection details."
        exit 0 }


#comparing the previous run data with the date in the current logs 

LogMessage -Message "Getting the share folder source information"

foreach ($source in $($Souredetails | Where-Object -FilterScript { $_.mod_nm -ne "FTP" })) {

    $filelist = Get-ChildItem -Path $source.File_Pth -File -Recurse | Where-Object -FilterScript { $_.name -Match $source.FileNm_Regex } | Sort-Object LastWriteTime -Descending | Select-Object -first 1

    foreach ($file in $filelist) {
      
        $filedet = [PSCustomObject]@{
            batch       = $batch
            RunDatetime = $Rundatetime
            ProjectID   = $source.Project_ID
            FileID      = $source.FileID
            Filename    = $file.Name
            LastModDate = $($file.LastWriteTime.ToString("yyyy-MM-dd hh:mm:ss"))
            CurrentPath = $file.Directory
        }
     
        $SourceDet += $filedet
    }
}

LogMessage -Message "Getting the FTP folder sources information."

foreach ($path in $($Souredetails | Where-Object -FilterScript { $_.mod_nm -eq "FTP" } | select-object File_Pth | sort-object File_Pth -Unique) ) {

    $filelistFTP = getFTPfilelistWin -FTPpath $path.File_Pth

    $filelistfull = @()

    foreach ($file in $filelistFTP.Files) {

        
        $filetest = [PSCustomObject]@{
            LastModDate = $file.LastWriteTime
            Filename    = $file.name
            CurrentPath = $(Split-Path $file.FullName -Parent)
        }

        $filelistFull += $filetest
     
    }

    Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "CREATE TABLE TEMP_FTP_FILES (FILENAME TEXT, LASTMODIFIED DATETIME, FTPPATH TEXT)"

    foreach ($file in $filelistfull) {

   
        Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "INSERT INTO TEMP_FTP_FILES (FILENAME, LASTMODIFIED, FTPPATH) VALUES (@filename,@moddate,@path);" -SqlParameters @{
            filename = $file.FileName 
            moddate  = $file.LastModDate
            path     = $file.CurrentPath 
        } 
    }

    foreach ($sources in $($Souredetails | Where-Object -FilterScript { $_.File_Pth -eq $path.File_Pth })) {

        $results = Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "select filename, LASTMODIFIED, ftppath from TEMP_FTP_FILES
  where filename like @filter
  order by LASTMODIFIED desc limit 1" -SqlParameters @{filter = $sources.FileNm_Regex.replace("*", "%") } 

        foreach ($result in $results) {

            $filedet = [PSCustomObject]@{
                batch       = $batch
                RunDatetime = $Rundatetime
                ProjectID   = $sources.Project_ID
                FileID      = $sources.FileID
                Filename    = $result.filename
                LastModDate = $($result.LASTMODIFIED.ToString("yyyy-MM-dd hh:mm:ss"))
                CurrentPath = $result.ftppath
            }
     
            $SourceDet += $filedet

        }

  
   
    }
  
    Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "DROP TABLE TEMP_FTP_FILES"

}

 
$insertquery = "INSERT INTO SourceInfo ( Batch, RunDateTime, Project_ID, FileName, LastModDate, CurrentPath, FileID) VALUES (@batch, @runtime, @project_id, @filename, @lastmoddate, @currentpath, @FileID)"

LogMessage -Message "Updating the source information"

$newsource = 0

foreach ($sources in $SourceDet) { 

    $query = 'Select LastModDate from currentsourcefileDet where project_id = @projectid and fileid = @fileid'
  
    $lastModateDB = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
        projectid = $sources.projectID
        fileid    = $sources.FileID
    }
  
 
    if ($lastModateDB.count -eq 0) {
  
        Invoke-SqliteQuery -DataSource $DataSource -Query $insertquery -SqlParameters @{
            batch       = $sources.batch
            runtime     = $sources.RunDatetime
            project_id  = $sources.projectID
            FileID      = $sources.FileID
            filename    = $sources.filename
            lastmoddate = $sources.lastmoddate
            currentpath = $sources.currentpath
        }
        $newsource = $newsource + 1
  
    }
    else {

    
        if ($lastModateDB.LastModDate -lt $([datetime]::parseexact($sources.lastmoddate, 'yyyy-MM-dd HH:mm:ss', $null)) -and $null -ne $lastModateDB.LastModDate ) {
  
            Invoke-SqliteQuery -DataSource $DataSource -Query $insertquery -SqlParameters @{
                batch       = $sources.batch
                runtime     = $sources.RunDatetime
                project_id  = $sources.projectID
                FileID      = $sources.FileID
                filename    = $sources.filename
                lastmoddate = $sources.lastmoddate
                currentpath = $sources.currentpath
            }

            $newsource = $newsource + 1
        }
        else {

            continue
        }
  
    }
  
    
  
}

LogMessage -Message "Getting the Current SourceFileDetails table."

$deleteCurrent = "Delete from currentsourcefileDet"

try {
    $pflist = Invoke-SqliteQuery -DataSource $DataSource -Query $deleteCurrent
} 
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }


$detailsQuery = 'Select distinct project_id, FileID from SourceInfo'

try {
    $pflist = Invoke-SqliteQuery -DataSource $DataSource -Query $detailsQuery
} 
catch { Write-host "Error in clearing the temp tables. Please check the connection details." }

foreach ($pf in $pflist) {
  
    $batchQuery = 'Select batch from SourceInfo where project_id = @projectid and FileID = @FileID order by RunDatetime desc limit 1'

    try {
        $batchlist = Invoke-SqliteQuery -DataSource $DataSource -Query $batchQuery -SqlParameters @{
            projectid = $pf.project_id
            FileID    = $pf.FileID
        }
    } 
    catch { Write-host "Error in clearing the temp tables. Please check the connection details." }

 
    foreach ($batch in $batchlist) {
         
        $insertCurrentQry = "insert into currentsourcefileDet (Project_ID, FileName, LastModDate, CurrentPath, FileID) 
                            select Project_id, Filename, LastModDate, CurrentPath, FileID  from 
                            sourceinfo where project_ID  = @projectID and fileID = @fileID and batch = @batchid;  
                           "
       
        try {
            $batchlist = Invoke-SqliteQuery -DataSource $DataSource -Query $insertCurrentQry -SqlParameters @{
                projectid = $pf.project_id
                FileID    = $pf.FileID
                batchid   = $batch.batch
            }
        } 
        catch { Write-host "Error in clearing the temp tables. Please check the connection details." }            


    }

}



if ( $newsource -gt 0) {

    .\DBuploadFTP.ps1

    LogMessage -Message "Source changes found. DB file uploaded to FTP"

}


LogMessage -Message "Program ended"




