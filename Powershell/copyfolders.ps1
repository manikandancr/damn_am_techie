$source = "Z:\SYSTAGENIX\976529 BI Maintenance\20-Development"
$dest = "C:\Users\mcr\Documents\sys"
Copy-Item $source $dest -Filter {PSIsContainer} -Recurse -Force