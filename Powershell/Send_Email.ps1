$parmfile = "C:\Users\mcr\Documents\Powershell\Params.xlsx"
$projectCode = "Nutricia"

$Excel = New-Object -ComObject Excel.Application 
$wb = $excel.workbooks.open($parmfile)
$sheet = $wb.Worksheets.Item(1)

$Found = $sheet.Cells.Find("Nutricia")
$Row = $Found.row

$i=2

$EmailData = New-Object -Typename psobject -Property @{
    toAddr = $sheet.Cells.Item($Row,$i).Text
    ccAddr = $sheet.Cells.Item($Row,$i+1).Text
    FromAddr = $sheet.Cells.Item($Row,$i+2).Text
    AttachmentFolder = $sheet.Cells.Item($Row,$i+3).Text
    Subject = $sheet.Cells.Item($Row,$i+4).Text
    Zip = $sheet.Cells.Item($Row,$i+5).Text
    ZipfilePrefix = $sheet.Cells.Item($Row,$i+6).Text
    SMTPServer = $sheet.Cells.Item($Row,$i+7).Text
    SMTPPort = $sheet.Cells.Item($Row,$i+8).Text

}

$Excel.Quit()
Stop-Process -Name EXCEL -Force

  
foreach( $x in $EmailData)
{


$Body  =  "This is a test" 

$x.toAddr.ToString()

Send-MailMessage -From ($x.FromAddr.ToString())  -to ($x.toAddr.ToString())  -Subject ($x.Subject.ToString()) -Body $Body -SmtpServer ($x.SMTPServer.ToString()) -port ($x.SMTPPort.ToString()) 



}




