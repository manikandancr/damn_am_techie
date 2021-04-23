set-location "\\frdatavisualization-fs.cegedim.clt\QlikSense\ArchivedLogs\bousapp01p.cegedim.clt\Script"

$files = get-childitem -File | where-object {$_.name -like "*eb8b78b7-9608-4426-a8f7-d340b59312ba*"} | sort-object lastwritetime


get-childitem -File | select-object @{name="ProjectCode"; e={$_.name.Substring(0,$_.name.IndexOf('.'))}} | sort-object | get-unique -AsString | out-file -FilePath "C:\Users\mcr\Documents\Qliksense\ProjectCode.txt"


get-childitem -File | Where-Object {$_.CreationTime -gt (get-date).Date} | select-object @{name="ProjectCode"; e={$_.name.Substring(0,$_.name.IndexOf('.'))}} |  sort-object | Get-Unique -AsString 

get-childitem -File | Where-Object {$_.CreationTime -gt (get-date).Date -and $_.name -like "6c64d3dd-f298-4f95-8a86-4d0a848a427f.*"}


get-childitem -File | Where-Object {$_.CreationTime -gt (get-date).Date} | Group {$_.name.Substring(0,$_.name.IndexOf('.'))} 


get-childitem -File | select @{name="ProjectCode"; Expression={$_.name.Substring(0,$_.name.IndexOf('.'))}}, @{name="createTime"; Expression={$_.CreationTime.Date}}  |group ProjectCode | sort 

get-childitem -File | select @{name="ProjectCode"; Expression={$_.name.Substring(0,$_.name.IndexOf('.'))}, @{name="createTime"; Expression={$_.CreationTime.Date}}  |group {$_.CreationTime.Date} | sort 





Get-ChildItem  -File | foreach {

$errorString = Get-Content $_.FullName -Tail 10  | Select-String "Execution Failed"

if ($errorString.count -gt 0)  {

add-content -Path "C:\Users\mcr\Documents\Qliksense\FileWithError.txt" -Value $_.name

} 
else { add-content -Path "C:\Users\mcr\Documents\Qliksense\FileWithoutError.txt" -Value $_.name }

Clear-Variable  errorString

}




"C:\Users\mcr\Documents\Qliksense\FileWithError.txt"
"C:\Users\mcr\Documents\Qliksense\FileWithoutError.txt"

$test = get-content -Path "\\BOUSAPP03P\Sense\Log\Script\eb8b78b7-9608-4426-a8f7-d340b59312ba.2020_06_08_10_30_33.D27A488D96C716E5FA4A.log" -Tail 50 | select-string "Execution Failed"


$test.count