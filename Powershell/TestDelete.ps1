
$logfile = "C:\Users\mcr\Documents\QVC logs\Chugai\App-published\Chugai-ACTIVITE.qvw.log"


$firstline = get-content -path $logfile | Select-Object -First 1 
$lastrundate = [regex]::Match($firstline, '[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}').value
$value = [datetime]::ParseExact($lastrundate, 'dd/MM/yyyy HH:mm:ss', $null)


$value = [datetime]::ParseExact([regex]::Match($firstline, '[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}').value, 'dd/MM/yyyy HH:mm:ss', $null)