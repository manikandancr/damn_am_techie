add-type -path "C:\Users\mcr\Downloads\sqlite-netFx40-binary-bundle-Win32-2010-1.0.112.0\System.Data.SQLite.dll"

$con = New-Object -TypeName System.Data.SQLite.SQLiteConnection
$con.ConnectionString = "Data Source=C:\Users\mcr\Downloads\sqlite-tools-win32-x86-3310100\processlog.db"
$con.Open()


$sql = $con.CreateCommand()
$sql.CommandText = "select * from LRP_FileInfo where Mod_Nm = 'MG3'"
$adapter = New-Object -TypeName System.Data.SQLite.SQLiteDataAdapter $sql
$data = New-Object System.Data.DataSet
[void]$adapter.Fill($data)




#$sql = $con.CreateCommand()
#$sql.CommandText = "insert into table_name (txtcolumn) values (@textcol)"

#$sql.Parameters.AddWithValue("@textcol", "Some date value");

#$sql.ExecuteNonQuery()


$sql.Dispose()
$con.Close()