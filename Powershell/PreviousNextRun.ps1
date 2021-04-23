
$DataSource = "C:\Users\mcr\Documents\frbidb\Processlog.db"
$projQry = "select distinct project_id from ProjectSchedule"

try {

    $projlist = Invoke-SqliteQuery -DataSource $DataSource -Query $projQry 
} 
catch { Write-host "Error in getting the max execution id. Please check!" }  

$updstat = @()

foreach ($proj in $projlist) {

    $query = "select a.Schedule_ID, a.project_id,  a.Sch_Date_Key, lag(Sch_Date_Key, 1) over (PARTITION by project_id order by b.date) as previous, 
    lead(Sch_Date_Key, 1) over (PARTITION by project_id order by b.date) as next 
    from ProjectSchedule a inner join dimdate b on a.Sch_Date_Key = b.date_key where a.project_id = @proj"


    try {

        $schdata = Invoke-SqliteQuery -DataSource $DataSource -Query $query  -SqlParameters @{

            proj = $proj.project_id
        }
    } 
    catch { Write-host "Error in getting the max execution id. Please check!" } 
      
    foreach ($sch in $schdata) {

        if ($null -eq $sch.previous) {

            $updateQyy = $("update ProjectSchedule set Next_Run_Key = " + $sch.next + " where Schedule_ID = " + $sch.Schedule_ID + " and project_id = "+ $sch.project_id   + " ;")
        }
        elseif ($null -eq $sch.next) {

            $updateQyy = $("update ProjectSchedule set Prev_Run_Key = " + $sch.previous + " where Schedule_ID = " + $sch.Schedule_ID + " and project_id = "+ $sch.project_id   + ";")
        }
        else {
            $updateQyy   = $("update ProjectSchedule set Prev_Run_Key = '" +  $sch.previous + "' , Next_Run_Key = '" + $sch.next + "' where Schedule_ID = " + $sch.Schedule_ID + " and project_id = "+ $sch.project_id   + " ;")
        }

        $Newobject = [PSCustomObject]@{

            updateQyy = $updateQyy 
            project_id = $sch.project_id
        }


        $updstat += $Newobject
    }


    write-host $proj.project_id  " Done"
}


$updstat | Where-Object -FilterScript {$_.project_id -eq 17}

foreach ($stat in $updstat) {

    $stat.project_id
    $stat.updateQyy

    try {

        Invoke-SqliteQuery -DataSource $DataSource -Query $stat.updateQyy
    } 
    catch { Write-host "Error in getting the max execution id. Please check!" } 

}