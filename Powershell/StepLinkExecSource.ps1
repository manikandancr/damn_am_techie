param ([Object[]]$step, [String]$Datasource)

$query = "select DISTINCT FileID from FileInfo where project_id = @projectID and Misc_Flag5 = 'Y'"

$fileID = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
  projectID = $step.project_id
}


Try {

  foreach ($id in $fileID) {


    $query = "select * From LatestSourceDet where project_id = @projectid and fileID  = @Fileid"

    $lastsourceinfo = Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
      projectid = $step.project_id
      Fileid    = $id.FileID
    }

    foreach ($file in $lastsourceinfo) {

    
    
      $query = "INSERT INTO FILE_EXECUTIONS (FileID, Execution_id, Exec_Filename, Exec_Lst_Mod_Dt) VALUES (@FileID, @Execution_id, @Exec_Filename, @Exec_Lst_Mod_Dt)"

      Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
        FileID          = $file.FileID
        Execution_id    = $step.Execution_id
        Exec_Filename   = $file.FileName
        Exec_Lst_Mod_Dt = $file.LastModDate
      }
    }
  }

}
catch { Write-host "Error Writing to the database please check" }


 .\DBuploadFTP.ps1

