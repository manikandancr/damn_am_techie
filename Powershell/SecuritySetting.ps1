Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force


[Net.ServicePointManager]::SecurityProtocol


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


Get-PackageProvider -ListAvailable
$env:PSModulePath -split  ";"

Install-Package -Force 7Zip4PowerShell

Install-Package -Force PSFTP

Install-Module -Name PSSQLite -Force

Install-Module PSSQLite

Import-Module PSSQLite

Get-Command -Module PSSQLite


  $DataTable = 1..10 | %{
        [pscustomobject]@{
            fullname = "Name $_"
            surname = "Name"
            givenname = "$_"
            BirthDate = (Get-Date).Adddays(-$_)
        }
    } | Out-DataTable



    Install-Package -Force 7Zip4PowerShell

Install-package -Name PSSQLite -Force

install-package -name ImportExcel

get-command -Module PSSQLite

$env:PSModulePath -split ";"

Install-Module -Name PSSQLite -Force

[Net.ServicePointManager]::SecurityProtocol


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Install-Module PackageManagement -Force -Repository PSGallery -AllowPrerelease

Get-PSRepository

Register-PSRepository -Default

Import-Module functionlib

get-command -Module functionlib

$env:PSModulePath -split ";"

$PSVersionTable


