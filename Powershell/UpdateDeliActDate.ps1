
$DataSource = "C:\Users\mcr\Documents\frbidb\Processlog.db"
$query = "SELECT a.Schedule_ID, b.date FROM ProjectSchedule a inner join dimdate b
on a.Sch_Date_Key = b.date_key"

try {
    $Shedules = Invoke-SqliteQuery -DataSource $DataSource -Query $query  
}
catch { write-host "Error occured in updating the table. Please see the connection details." }

$Shedules | select -First 1

Foreach ($sch in $Shedules) {

    $query = "update ProjectSchedule
    set Plan_Data_Avail_Dt = @dateval, Plan_Deli_Dt = @dateval 
    where Schedule_ID = @scheduleID"


    try {
    
         Invoke-SqliteQuery -DataSource $DataSource -Query $query -SqlParameters @{
            dateval = $(get-date $sch.date -Format "yyyy-MM-dd")
            scheduleID = $sch.Schedule_ID
        } 
    } 
    catch { write-host "Error occured in updating the table. Please see the connection details." }

}