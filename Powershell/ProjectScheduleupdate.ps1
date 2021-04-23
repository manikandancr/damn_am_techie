$DataSource = "D:\FranceBI\UIDashboard\Processlog.db"

$udpvalQry = "select * From WeeklyTasks_Updateview"



function LogMessage {
    param([string]$Message)
    
    ((Get-Date).ToString() + " - " + $Message) >> $LogFile;
}

LogMessage -Message "Program started. Checking for changes in source DB"

try {

    $projlist = Invoke-SqliteQuery -DataSource $DataSource -Query $udpvalQry
} 
catch { Write-host "Error in getting the max execution id. Please check!" }  

LogMessage -Message "Update process started"

foreach ($proj in $projlist) {

    $updatequery = "update ProjectSchedule 
                    set Act_Data_Avail_Dt = @actdataavaildt,
                        Act_Run_Dt = @acutalRundate,
                        Act_Deli_Dt = @acutalRundate,
                        Source_Flag = @SourceAvailable,
                        Executed_Flag = @Executed,
                        QA_Flag =@QA
                    where project_id = @project_id
                    and Schedule_ID = @schedule	"

    try {

        Invoke-SqliteQuery -DataSource $DataSource -Query $updatequery -SqlParameters @{

            actdataavaildt  = $proj.actdataavaildt
            acutalRundate   = $proj.acutalRundate
            SourceAvailable = $proj.SourceAvailable
            Executed        = $proj.Executed
            QA              = $proj.QA
            project_id      = $proj.project_id
            schedule        = $proj.Schedule_ID
            
        }
    } 
    catch { Write-host "Error in getting the max execution id. Please check!" }  
                    

}

LogMessage -Message "Update complete. The program will exit"

