# 111/0815 Rewrite w/ no compress 
# due to tired of handle files issues
# 111/0818 update for argument pass to process multiple path.
# 113/2/19 apply include parameter to check encapsulated file i.e. .dll, .exe only.
param (
	[string]$ext="*",
	[string]$sub="",
	[string[]]$incld,
	[Parameter(Mandatory=$true)]
	[string]$path_prot,
	[Parameter(Mandatory=$true)]
	[string]$path
)
# powershell.exe -c "D:\..\compFilehash.ps1" -sub "*Logs*" -path_prot "D:\..\cfh\PROTECT\DistAPP" -path "D:\..\APP\DistAPP" -incld "*.dll","*.exe"
$path_log="D:\..\cfh"
$logFile=$path_log+"\baklog."+$(Get-Date -f "yyyyMMdd")+".log"
Add-Content -Path $logFile -Value "$(Get-Date -f "yyyy-MM-dd HH:mm:ss.fff") Begin."
# $path=Read-Host "Existing Directory"
# $path_prot=Read-Host "Protect Directory"
# $ext="*"
# $sub="*subfolder"
$t=$(Get-Date)
# if protect folders empty
if(!(Test-Path $path_prot\*)) {
	Get-ChildItem -Path $path -Filter $ext -Include $incld -Recurse | Copy-Item -Destination $path_prot -Force
}
# all existing files need check
$exist=dir -Path $path -Filter $ext -Include $incld -Recurse | where {$_.Directory -notlike $sub} | Get-FileHash -Algorithm "SHA256"
# where protect backup to compare
$prot=dir -Path $path_prot -Filter $ext -Include $incld -Recurse | where {$_.Directory -notlike $sub} | Get-FileHash -Algorithm "SHA256"
# compare two string array
$c=Compare-Object -ReferenceObject $prot.Hash -DifferenceObject $exist.Hash
$abnormal=($c|where{$_.SideIndicator-eq"=>"}).InputObject
$path_abn=($exist | where {$abnormal -contains $_.hash}).Path
# $opt_abn=$("$path_abn".replace(" ","`n"))
# log write into backup directory
Add-Content -Path $logFile -Value "`tExisting Directory: $path`n`tProtect Directory: $path_prot"
if($c -eq $null) {
	Add-Content -Path $logFile -Value "`tfiles are EQUAL."
	# Rename-Item -Path $file -NewName ($file+".neq")
} else {
	Add-Content -Path $logFile -Value "`tProtect Backup files Hash Result Difference: $abnormal `n`tthe files are NOT EQUAL. `n`tPlease CHECK the files Below:`n`t$("$path_abn".replace(" ","`n"))"
	# Move-Item -Path $file -Destination $path_bak
}

Add-Content -Path $logFile -Value "$(($(Get-Date)-$t).totalseconds)secs Time elapsed."
Add-Content -Path $logFile -Value "$(Get-Date -f "yyyy-MM-dd HH:mm:ss.fff") Done."
# Write-Host "Done."
# pause
# version-1.3.0
# Author@CWayneH
