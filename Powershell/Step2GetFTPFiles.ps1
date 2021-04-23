param ([Object[]]$step, [String]$Datasource)

[hashtable]$Return = @{}


#update the below parameters if needed
$FTPUser = "Ceg_CegersRead"  #username
$password = ConvertTo-SecureString "0r12N0LF" -AsPlainText -Force  #password needs to changed 
$ServerPath = "/Production/2230"   #FTP path where the files are updated
$LocalPath = $step.Execution_Path  #Local Path to which the files gets downloaded
$FTPserver = 'ftp://80.94.177.246'  #FTP server

try {

$credentials = New-Object System.Management.Automation.PSCredential($FTPUser, $password)

Set-FTPConnection -Credential $credentials -Server $FTPserver -Session FTP -ignoreCert 

$Session = Get-FTPConnection -Session FTP

$filelist = Get-FTPChildItem -Session $Session -Path $ServerPath -filter *.* 


$RealFileName = @()

$filelist | where-object {$_.size -ne ""}| ForEach-Object {

if ($_.name -match "^P[\s\S]*" ) {$realFileName += "Périmètre.xls"}
elseif ($_.name -match "GSK_Base_Mixte_[\s\S]*_Groupes[\s\S]*") {$realFileName += "GSK_Base_Mixte_Déf_Groupes.xls"}
elseif ($_.name -match "GSK_Base_Mixte_[\s\S]*_Classes_[\s\S]*_[/d]*[\s\S]*") { $realFilename += $("GSK_Base_Mixte_Déf_Classes_Gé_"+ $($_.name -replace '\D+(\d+)','$1'))  }
else {$realfileName += $_.name}
}


foreach ($file in $RealFileName ) {
$filename  = $ServerPath + "/"+ $file
do {

try{
Get-FTPItem -Path $filename -Session $Session -LocalPath $LocalPath -Overwrite $true 
$status = "Y"
}
catch {Write-host "Error in downloading file "$filename
$status = "N"
}
} until ($status -eq "Y")

}



$Return.Status = $true 
Return $Return

} catch {write-host "Error in accessing the FTP.  Please check the connection parameters are given correctly."

$Return.status =  $false
$Return.Errtext = "Error occured in the FTP transfer"
Return $Return
}