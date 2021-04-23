$projects = import-csv -Path .\Projects.csv 

foreach ($project in $projects) {
    .\QliksenseCapture.ps1 $project.Project_Code
}

#  .\DBuploadFTP.ps1