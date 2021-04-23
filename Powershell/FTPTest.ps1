
function getFTPfilelistWin {

    param ([string]$Ftppath)

    try {
        # Load WinSCP .NET assembly
        Add-Type -Path "WinSCPnet.dll"
     
        # Setup session options
        $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
            Protocol              = [WinSCP.Protocol]::Sftp
            HostName              = "80.94.177.246"
            UserName              = "Ceg_CegersRead"
            Password              = "0r12N0LF"
            SshHostKeyFingerprint = "ssh-rsa 2048 6djv1DIAvzeAw7/25FYB5p8FCJyTof82/C5VKl2juTU="
        }
    }
    catch { Write-Verbose "Error creating a FTP session" }
        
    $sessionOptions.AddRawSettings("FSProtocol", "2")
    
    $session = New-Object WinSCP.Session

    try {

         
        $session.Open($sessionOptions)
    
        $directory = $session.ListDirectory($Ftppath)
    
        # foreach ($file in $directory.Files) {
    
        #     $file.Name
        #     $file.LastWriteTime
        # }

        Return $directory
    
        $session.Dispose()

    }
    catch { write-host "Error in opening the FTP session. Please check" }
           

}

 

$filelist  = getFTPfilelistWin -Ftppath "/Production/1168"

foreach ($file in $filelist.Files) {

$file.name
$file.LastWriteTime
Split-Path $file.FullName -Parent

 

 break

}
