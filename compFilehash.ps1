# Author@CWayneH
# 111/0815 Rewrite w/ no compress 
# due to tired of handle files issues
$path=Read-Host "Existing Directory"
$path_prot=Read-Host "Protect Directory"
$ext=Read-Host "Monitor Filename Extension"
# if protect folders empty
if(!(Test-Path $path_prot\*)) {
	# this will encounter subflolder w/ duplicate files problem; if so, please copy in manual.
	Get-ChildItem -Path $path -Filter $ext -Recurse | Copy-Item -Destination $path_prot -Force
}
# all existing files need check
$exist=dir -Path $path -Filter $ext -Recurse | Get-FileHash -Algorithm "SHA256"
# where protect backup to compare
$prot=dir -Path $path_prot -Filter $ext -Recurse | Get-FileHash -Algorithm "SHA256"
# compare two string array
$c=Compare-Object -ReferenceObject $prot.Hash -DifferenceObject $exist.Hash
$abnormal=($c|where{$_.SideIndicator-eq"=>"}).InputObject
$path_abn=($exist | where {$abnormal -contains $_.hash}).Path
# $opt_abn=$("$path_abn".replace(" ","`n"))
# log write into backup directory
$path_log=Read-Host "LogFiles Directory"
$logFile=$path_log+"\baklog."+$(Get-Date -f "yyyyMMdd")+".log"
if($c -eq $null) {
	Add-Content -Path $logFile -Value "`t$(Get-Date -f "yyyy-MM-dd HH:mm:ss") `nfiles are EQUAL."
	# Rename-Item -Path $file -NewName ($file+".neq")
} else {
	Add-Content -Path $logFile -Value "`t$(Get-Date -f "yyyy-MM-dd HH:mm:ss")"
	Add-Content -Path $logFile -Value "Protect Backup files Hash Result Difference: $abnormal `nthe files are NOT EQUAL. `nPlease CHECK the files Below:`n$("$path_abn".replace(" ","`n"))"
	# Move-Item -Path $file -Destination $path_bak
}
Add-Content -Path $logFile -Value "`tDone."
Write-Host "Done."
pause
