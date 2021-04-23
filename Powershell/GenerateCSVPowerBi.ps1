$DataSource =  "C:\Users\mcr\Documents\frbidb\Processlog.db"
$query = "select * from WeeklyTasks_PowerBI"


try {
    $WeeklyTasks = Invoke-SqliteQuery -DataSource $DataSource -Query $query  
    }

catch { write-host "Error occured in updating the table. Please see the connection details." }


$WeeklyTasks | Export-Csv -NoTypeInformation -Path '.\ProjectSchedule.csv'