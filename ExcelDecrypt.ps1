$ExcelFileDir=Read-Host "FileDir"
$ExcelPWd=Read-Host "Password" -AsSecureString
$ExcelPWd=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ExcelPWd)
$ExcelPWd=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ExcelPWd)
$ExcelSaveDir=$ExcelFileDir+'\saveDir\'
$temp=dir $ExcelFileDir -Name -Include *.xlsx -Exclude NN*.xlsx,MM*.xlsx
$ExcelObj = $null
$ExcelObj = New-Object -ComObject Excel.Application
for($i=0;$i-lt$temp.Length;$i++){
$ExcelWorkBook = $ExcelObj.Workbooks.Open($ExcelFileDir+'\'+$temp[$i],0,0,5,$ExcelPWd)
Write-Host $temp[$i]
$ExcelWorkBook.Password = $null
$ExcelWorkBook.SaveAs($ExcelSaveDir+$temp[$i])
#$ExcelWorkBook = $null
$ExcelObj.Workbooks.Close()
}
$ExcelObj.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ExcelObj)
Remove-Variable $ExcelObj
pause
