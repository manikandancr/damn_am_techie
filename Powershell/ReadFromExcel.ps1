$path = "\\frdatavisualization-fs.cegedim.clt\QlikSense\IQVIZ\00.QDF\00.APP\03.Audit_CH"

$filelist = Get-ChildItem -path $path -Recurse -File | Where-Object -FilterScript {$_.name -eq "Param_Appli.xlsx"}

$a = @()

foreach ($file in $filelist) {

$Filepath = split-path -path $File.Fullname



$excel =  New-Object -ComObject Excel.Application

$workbook = $excel.Workbooks.Open($File.Fullname)
 # uncomment next line to make Excel visible
#$excel.Visible = $true
 
$sheet = $workbook.ActiveSheet
$column = 7
$row = 3
$info = $sheet.cells.Item($column, $row).Text
$excel.Quit()

$Newobject = [PSCustomObject]@{

    filepath        = $Filepath
    value               = $info
  }


  $a += $Newobject

}


$a | export-csv -path ".\all.csv" -NoTypeInformation


$excel =  New-Object -ComObject Excel.Application

$workbook = $excel.Workbooks.Open("C:\Users\mcr\Documents\Powershell\Param_Appli.xlsx")
 
# uncomment next line to make Excel visible
#$excel.Visible = $true
 
$sheet = $workbook.ActiveSheet
$column = 7
$row = 3
$info = $sheet.cells.Item($column, $row).Text
$excel.Quit()

write-host "value :"$info

$Fileinfo = import-csv -Path .\all.csv 



$path  = "Z:\1. Data\1.STAR SCHEME"

$b = @()

foreach ($file in $fileInfo) {

    $file.value
    $filedet = get-childitem -path $path -Recurse -File  | where-object -FilterScript {$_.name -eq $file.value} 
    
    
    $filedet  | ForEach-Object {

        $Newobject = [PSCustomObject]@{

            filepath        = $_.Directory
            value           = $_.name
            supplied        = $file.value
          }

    }

    $b += $Newobject


}

$b | export-csv -path ".\allpath.csv" -NoTypeInformation