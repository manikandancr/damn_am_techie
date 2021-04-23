$qvqlog = Get-Content -Path "C:\Users\mcr\Documents\QVC logs\App-data\App-QVD.qvw.log"


 $qvqlog | Select-String -Pattern "\[..\\Data-loaded\\[\s\\\*\.]*"

 $filter =  $qvqlog | Select-String -Pattern "[\s]*_[\*]+\.[\s]*\]*" | ForEach-Object { 

 [regex]::Match($_,'[A-Za-z]*_[\*]+\.[A-Za-z]*').value


 } 


  $filter | select -Unique

 $firstline =  $qvqlog | select -First 1 

 $value = [datetime]::ParseExact([regex]::Match($firstline,'[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}').value,'yyyy-MM-dd hh:mm:ss',$null)

 $value.ToString('yyyy-MM-dd HH:mm')


 
 $firstline =  $qvqlog | select -Last 1 

 $value = [datetime]::ParseExact([regex]::Match($firstline,'[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}').value,'yyyy-MM-dd hh:mm:ss',$null)

 $value.ToString('yyyy-MM-dd HH:mm')


$qvqlog | Select-String -Pattern ""

 $filter =  $qvqlog | Select-String -Pattern "Reload Executed By[\s]*" | ForEach-Object { 

 [regex]::Match($_,'[A-Za-z0-9-]*\\[A-Za-z0-9]+').value


 } 

 
 
 $filter =  $qvqlog | Select-String -Pattern "Process Executing[\s]*" | ForEach-Object { 

 [regex]::Match($_,'[A-Za-z0-9-]*\\[A-Za-z0-9]+').value


 } 



 $text  = get-content -Path "C:\Users\mcr\Documents\My Received Files\QlikAssignment1.qvw.log"

 [String]$ErrorSting = $null

 $text | Select-String -Pattern "Error:[\s]*" | ForEach-Object {
 
 $ErrorSting = $($ErrorSting + [regex]::Match($_,"Error:[A-Za-z0-9\\:,\.\' _]*").value + "`n")

 }
 
 $ErrorSting 


