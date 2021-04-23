cd "C:\Users\mcr\Documents\GSK\Documents\My Documents\GSK_sources des données"


Get-ChildItem -File  | Where-Object -FilterScript {$_.LastWriteTime -gt '1/5/2020'} |  Format-Table  -Wrap -AutoSize

get-command -Module PSFTP

CHCP 1252
$FTPUser = "Ceg_CegersRead"
$password = ConvertTo-SecureString "0r12N0LF" -AsPlainText -Force 
$ServerPath = "/Production/2230"
$LocalPath = "C:\Users\mcr\Documents\GSK\Scripts\FTP"

$credentials = New-Object System.Management.Automation.PSCredential($FTPUser, $password)

Set-FTPConnection -Credential $credentials -Server 'ftp://80.94.177.246' -Session FTP -ignoreCert -UseBinary 

$Session = Get-FTPConnection -Session FTP

$filelist = Get-FTPChildItem -Session $Session -Path "/Production/2230/" 


$filelist | Where-Object {$_.size -ne "" -and $_.name -match "^P[\s\S]*"}

$filelist | Where-Object {$_.size -ne "" -and $_.name -match "GSK_Base_Mixte_[\s\S]*_Groupes[\s\S]*"}

$filelist | Where-Object {$_.size -ne "" -and $_.name -match "GSK_Base_Mixte_[\s\S]*_Classes_[\s\S]*_[/d]*[\s\S]*"}

$RealFileName = @()

$filelist | where-object {$_.size -ne ""}| ForEach-Object {

if ($_.name -match "^P[\s\S]*" ) {$realFileName += "Périmètre.xls"}
elseif ($_.name -match "GSK_Base_Mixte_[\s\S]*_Groupes[\s\S]*") {$realFileName += "GSK_Base_Mixte_Déf_Groupes.xls"}
elseif ($_.name -match "GSK_Base_Mixte_[\s\S]*_Classes_[\s\S]*_[/d]*[\s\S]*") { $realFilename += $("GSK_Base_Mixte_Déf_Classes_Gé_"+ $($_.name -replace '\D+(\d+)','$1' )+".xls")  }
else {$realfileName += $_.name}


}
GSK_Base_Mixte_Déf_Classes_Gé.xls
GSK_Base_Mixte_DÃ©f_Classes_GÃ©_202003.xls

$value = get-content -Path ".\filelist.txt" 
Set-Content -Path ".\filelist.txt" -Encoding Oem -Value $value -Force

get-content -Path ".\filelist.txt" 
 

$PSDefaultParameterValues
foreach ($file in $filelist ) {

$filename  = $ServerPath + "/"+ $file.name
 Get-FTPItem -Path $filename -Session $Session -LocalPath $LocalPath -Overwrite $true 

 

}

[Console]::OutputEncoding


$Marshmallows = @(("Pink","Yellow","Orange","Green","Blue"),("Hearts","Stars","Moons","Clovers","Diamonds"))

$Marshmallows[1][0]


so only the persons who are available in 


$filelistFTP = getFTPfilelist -FTPpath "/Production/1168"
$filterResult = $filelistFTP | Where-Object -FilterScript {$_.name -match $source.FileNm_Regex}|select-object Name, @{Name="ModifiedDate";Expression={$_.ModifiedDate}}



$filelistFTP = getFTPfilelist -FTPpath "/Production/1168" | Export-Csv -Path "outfile.csv" -NoTypeInformation
$filelistFTP | Export-Csv -Path "outfile.csv" -NoTypeInformation

$filelistFTP.GetType()


$filelistFTP | Select-Object $_.ModifiedDate, @{Name="ModifiedDate";Expression={[datetime]::parseexact($_.ModifiedDate,"M/d/yyyy hh:mm:ss TT", $null)}} -First 1

$filelistfull=@()

$filelistFTP | ForEach-Object { 
    
    $filetest = [PSCustomObject]@{
        LastModDate =  $_.modifiedDate
        Filename = $_.name
        CurrentPath = $_.Parent
        }

        $filelistFull += $filetest
 } 


 $filetest.GetType()
 $filetest | Select-Object $_.name

 $($filelistFull | ForEach-Object {$_.ModifiedDate} ) | sort -Descending | select -last 1

 Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "CREATE TABLE TEMP_FTP_FILES (FILENAME TEXT, LASTMODIFIED DATETIME, FTPPATH TEXT)"

 foreach ($file in $filelistfull) {

   Invoke-SqliteQuery -Datasource $DataSource -Query "INSERT INTO TEMP_FTP_FILES (FILENAME, LASTMODIFIED, FTPPATH) VALUES (@filename,@moddate,@path);" -SqlParameters @{filename = $file.FileName 
     moddate = $file.LastModDate
     path = $file.CurrentPath } 
 }


 $results = Invoke-SqliteQuery -SQLiteConnection $tempDB -Query "select filename, LASTMODIFIED, ftppath from TEMP_FTP_FILES
 where filename like @filter
 order by LASTMODIFIED desc limit 1" -SqlParameters @{filter = "CNV_PROTECTEURSCUTANES_REVENDEUR_%" } 

 


 $results.GetType()



$fromcsv.GetType()





 $filelistFTP | Where-Object -FilterScript {$_.name -match "CNV_PROTECTEURSCUTANES_SIG_*"} | Sort-Object -property  @{Expression={[datetime]::parseexact($_.ModifiedDate,'MM/dd/yyyy','hh:mm:ss')};Descending=$true} | Select-Object ModifiedDate

 $filelistFTP | Where-Object -FilterScript {$_.name -match "CNV_PROTECTEURSCUTANES_SIG_*"} | Sort-Object -Property  @{Expression={[datetime]::ParseExact($_.ModifiedDate,'MM/dd/yyyy','hh:mm:ss')};Descending=$true}

 $filelistFTP | Where-Object -FilterScript {$_.name -match "CNV_PROTECTEURSCUTANES_SIG_*"} | select-object @{Name="Test";Expression={[datetime]::ParseExact($_.ModifiedDate.ToString(),'M//yyyy h:mm:ss tt')}}

 $filelistFTP | select-object  Name,  @{Name="ModifiedDate";Expression={$_.ModifiedDate}} | Sort-Object Modified -Descending | select -Last 1


 $filelistFTP | Get-Member 

 $filelistFTP = getFTPfilelist -FTPpath "/Production/1168" | Select-Object $_.modifiedDate

 [datetime]$datevalue = '10/17/2019 12:00:00 AM'

 $datevalue.ToString("yyyy-MM-dd hh:mm:ss")