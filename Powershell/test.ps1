# Function to get directory listing 
Function Get-FTPFileList { 

  Param (
   [System.Uri]$server,
   [string]$username,
   [string]$password,
   [string]$directory
  
  )
  
  try 
   {
      #Create URI by joining server name and directory path
      $uri =  "$server$directory" 
  
      #Create an instance of FtpWebRequest
      $FTPRequest = [System.Net.FtpWebRequest]::Create($uri)
      
      #Set the username and password credentials for authentication
      $FTPRequest.Credentials = New-Object System.Net.NetworkCredential($username, $password)
     
      #Set method to ListDirectoryDetails to get full list
      #For short listing change ListDirectoryDetails to ListDirectory
      $FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
      
      #Get FTP response
      $FTPResponse = $FTPRequest.GetResponse() 
      
      #Get Reponse data stream
      $ResponseStream = $FTPResponse.GetResponseStream()
      
      #Read data Stream
      $StreamReader = New-Object System.IO.StreamReader $ResponseStream  
     
      #Read each line of the stream and add it to an array list
      $files = New-Object System.Collections.ArrayList
      While ($file = $StreamReader.ReadLine())
       {
         [void] $files.add("$file")
        
      }
  
  }
  catch {
      #Show error message if any
      write-host -message $_.Exception.InnerException.Message
  }
  
      #Close the stream and response
      $StreamReader.close()
      $ResponseStream.close()
      $FTPResponse.Close()
  
      Return $files
  
  
  }
  
  #Set server name, user, password and directory
  $server = 'ftp://80.94.177.246/'
  $username = 'Ceg_CegersRead'
  $password = '0r12N0LF'
  $directory ='/Production/1168'
  
  #Function call to get directory listing
  $filelist = Get-FTPFileList -server $server -username $username -password $password -directory $directory
  
  #Write output
  Write-Output $filelist.gettype()

  foreach ($file in $filelist) {
  
   $file.name
  }

  $filelist | ForEach-Object { $_.GetType() }



  $ftp = "{ftp site}"
$user = "{user}"
$pass = "{password}"
$folder = "{source folder}"
$target = "{destination folder}"

#Register get FTP Directory function
function Get-FtpDir ($url, $credentials) {
	$request = [Net.WebRequest]::Create($url)
	$request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory

	if ($credentials) { $request.Credentials = $credentials }
	
	$response = $request.GetResponse()
	$reader = New-Object IO.StreamReader $response.GetResponseStream() 
	
	while(-not $reader.EndOfStream) {
		$reader.ReadLine()
	}
	
	$reader.Close()
	$response.Close()
}

$credentials = new-object System.Net.NetworkCredential("Ceg_CegersRead", "0r12N0LF")

#set folder path
$folderPath= "ftp://80.94.177.246/Production/1168/"

$files = Get-FTPDir -url $folderPath -credentials $credentials



$tst = @{
  projectid   = $ProjectsInfo.Project_ID
  currentdate = $currentdate
}

$tst.projectid = '34'


$info = @{
  "name" = "bob";
  "age" = "3";
  "mail" = "you@me.com"
}

$fString = "test {0} test {1} test {2}"

$fString -f $info.Name, $info.age, $info.mail