#Script name: Powerpoint_Combine.ps1
#Purpose : Reportive generated .pptx  will be updated with missing slides from the template
#Project : Grunenthal
#Author : Iqvia
#Prerequistes : Make sure the path and the variables set are valid at the the time of implementaion



Add-type -AssemblyName office
$SourceFolder = "C:\Users\mcr\Documents\Grunenthal\Grunenthal\Grunenthal\output\PowerPoint Reports Collection"
$RegionFiles =  '^[R][1-5].pptx$'
$TerritoryFiles = '^[R][1-5][S][0|1][0-9].pptx$'
$RegionTmp = "C:\Users\mcr\Documents\Grunenthal\Trame PAR pour 2020 V4.pptx"
$TerriTmp = "C:\Users\mcr\Documents\Grunenthal\Trame PAS pour 2020 V3bis.pptx"

if (test-path $SourceFolder )
{

write-host "We are the in the correct folder!"

Set-Location -Path $SourceFolder

$ppo = New-Object -ComObject powerpoint.application
#$ppo.Visible = $False

$RegionFilelist = Get-ChildItem -recurse | Where-Object {$_.Name -match $RegionFiles} | Select-Object -ExpandProperty FullName

foreach ($filename in $RegionFilelist)
{
   write-host $filename

   $pp2 = $ppo.Presentations.open($filename, [Microsoft.Office.Core.MsoTriState]::msoFalse,[Microsoft.Office.Core.MsoTriState]::msoFalse,[Microsoft.Office.Core.MsoTriState]::msoFalse)
   $pp2.Slides.InsertFromFile($RegionTmp,28,29,37)

   
   $pp2.save()
   $pp2.close()
}

$ppo.quit()

#Renaming the files
Get-ChildItem -recurse | Where-Object {$_.Name -match $RegionFiles} | Rename-Item -NewName { "PAR "+$_.Name.Substring(0,2)+" 2020.pptx" }

} 
else
{

write-host "The file folder path given is not valid!"
Exit

}


