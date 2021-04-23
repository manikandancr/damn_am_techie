# Load WinSCP .NET assembly
Add-Type -Path "WinSCPnet.dll"

$DBpath = "C:\Users\mcr\Documents\mainDB\Processlog.db"
$FTPpath = "/PICGRSREP02/"

# Set up session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Ftp
    HostName = "10.85.148.28"
    UserName = "anonymous"
    Password = "anonymous@example.com"
}

$session = New-Object WinSCP.Session

try {
    # Connect
    $session.Open($sessionOptions)
 
    # Upload files
    $transferOptions = New-Object WinSCP.TransferOptions
    $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
 
    $transferResult =
    $session.PutFiles($DBpath, $FTPpath, $False, $transferOptions)
 
    # Throw on any error
    $transferResult.Check()
 
    # Print results
    foreach ($transfer in $transferResult.Transfers) {
        Write-Host "Upload of $($transfer.FileName) succeeded"
    }
}
finally {
    # Disconnect, clean up
    $session.Dispose()
}
 
exit 0

catch
{
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
}
