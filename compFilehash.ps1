# Author@CWayneH
$path=Read-Host "Existing Directory"
$path_bak=Read-Host "Backup Directory"
$file=$path+"\backup."+$(Get-Date -f "yyyyMMddHHmmss")+".zip"
# all existing files need check
dir -Exclude *.zip,*.neq $path | Compress-Archive -DestinationPath $file -Force
$recent=Get-FileHash $file -Algorithm "SHA256"
# where last backup to compare
$last_bak_file=$path_bak+"\"+(Get-ChildItem -Path $path_bak -Exclude *.log| sort LastWriteTime | select -Last 1).Name
$last=Get-FileHash $last_bak_file -Algorithm "SHA256"
# log write into backup directory
$logFile=$path_bak+"\baklog."+$(Get-Date -f "yyyyMMdd")+".log"
if($recent.Hash -ne $last.Hash) {
	Add-Content -Path $logFile -Value $(Get-Date -f "yyyy-MM-dd HH:mm:ss")
	Add-Content -Path $logFile -Value "Last Backup file Hash Result : $last `ndoes not euqal Existing Destination File Hash Result : $recent `nthe files are NOT EQUAL."
	Rename-Item -Path $file -NewName ($file+".neq")
} else {
	Add-Content -Path $logFile -Value " $(Get-Date -f "yyyy-MM-dd HH:mm:ss") `nfiles are EQUAL. Movement done."
	Move-Item -Path $file -Destination $path_bak
}
Write-Host "Done."
pause