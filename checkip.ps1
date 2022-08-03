# Author@CWayneH
$dir = Read-Host "Directory"
$nul_idx = Read-Host "Index of null"
$ip_idx = Read-Host "Index of IP"
$dir = $dir -replace '"',""
$tmp = Get-Content $dir -Encoding UTF8
$check = $tmp | ForEach-Object {$chk=$_.Split(" ");if($chk[$nul_idx]-match'null'){$chk[$ip_idx]}}
($check | select -Unique).Count
$new_path = $dir.Split(".")[0]+".output"
($check | select -Unique) | Out-File $new_path -Encoding utf8
pause