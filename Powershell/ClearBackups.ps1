#clearing the backup folders

$backuppath = "C:\Users\mcr\Documents\DataSync\backup"

$lat_backup = Get-ChildItem -Path $backuppath -Directory | Sort-Object LastWriteTime -Descending | select $_.name -First 1

Get-ChildItem -Path $backuppath -Directory | Where-Object -FilterScript {$_.Name -ne $lat_backup.Name} | Remove-Item -Force -Recurse
#clearing backup folder ends here..

#updating the file information

$Datasource = "C:\Users\mcr\Documents\frbidb\Processlog.db"

$query  = "select s.project_code, fileid, execution_id, filename, '',LastModDate, '','' from
(select * from 
(select a.project_id, max(execution_id) as execution_id from projects a
inner join executions b on a.project_id  = b.project_id 
where a.project_id <> 0 
and a.Project_status = 'A'
and a.project_id in (select * from tobeprocessedSource)
group by a.project_id ) a
where execution_id not in (select distinct execution_id from File_Executions) ) a left join currentsourcefileDet b
on a.project_id  = b.project_id
left join projects s on a.project_id  = s.project_id"

try {

$results = Invoke-SqliteQuery -DataSource $Datasource -Query $query 

 } catch { write-host "Error in database connection!"}


 if ($results.Count -gt 0 ) {

 $insertquery  = "INSERT INTO main.File_Executions
 (FileID, Execution_id, Exec_Filename, Exec_File_Size_Mb, Exec_Lst_Mod_Dt, Exec_File_Dt, Exec_FileRenamed) 
 select  fileid, execution_id, filename, '',LastModDate, '','' from
 (select * from 
 (select a.project_id, max(execution_id) as execution_id from projects a
 inner join executions b on a.project_id  = b.project_id 
 where a.project_id <> 0 
 and a.Project_status = 'A'
 and a.project_id in (select * from tobeprocessedSource)
 group by a.project_id ) a
 where execution_id not in (select distinct execution_id from File_Executions) ) a left join currentsourcefileDet b
 on a.project_id  = b.project_id
 left join projects s on a.project_id  = s.project_id"


 Invoke-SqliteQuery -DataSource $Datasource -Query  $insertquery


 }
 else {

    exit
 }

 #updating file information ends here..