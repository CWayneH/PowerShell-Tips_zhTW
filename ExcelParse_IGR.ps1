$ExcelFileDir=Read-Host "FileDir"
$ExcelPWd=Read-Host "Password" -AsSecureString
$ExcelPWd=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ExcelPWd)
$ExcelPWd=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ExcelPWd)
$temp=dir $ExcelFileDir -Name -Include IGR*.xlsx
$ExcelObj = $null
$ExcelObj = New-Object -ComObject Excel.Application
for($i=0;$i-lt$temp.Length;$i++){
$ExcelWorkBook = $ExcelObj.Workbooks.Open($ExcelFileDir+'\'+$temp[$i],0,0,5,$ExcelPWd)
$ftype=$temp[$i].Split("-")[0]
#當sheet僅1row時row1c組字串A1雖match為False仍會被count:1故硬加1
$rowc="D"+($ExcelWorkBook.sheets.item(1).UsedRange.Rows.Count+1)
$rowa=$ExcelWorkBook.sheets.item(1).Range("D1",$rowc).Value2
$rowcount=($rowa-match'\d{8}').Count
Write-Host $temp[$i] : $rowcount
switch($ftype){
	'IGR0000003'{$rc1=$rowcount ;break}
	'IGR0000004'{$rc2=$rowcount ;break}
	'IGR0000005'{$rc3=$rowcount ;break}
	'IGR0000006'{$rc4=$rowcount ;break}
	'IGR0000001'{
		if($temp[$i].Split("-")[2]-match'\d{7}091.xlsx.xlsx'){$rc5=$rowcount}
		if($temp[$i].Split("-")[2]-match'\d{7}092.xlsx.xlsx'){$rc6=$rowcount}
		if($temp[$i].Split("-")[2]-match'\d{7}151.xlsx.xlsx'){$rc9=$rowcount}
		if($temp[$i].Split("-")[2]-match'\d{7}152.xlsx.xlsx'){$rc10=$rowcount}
		if($temp[$i].Split("-")[2]-match'\d{7}201.xlsx.xlsx'){$rc13=$rowcount}
		if($temp[$i].Split("-")[2]-match'\d{7}202.xlsx.xlsx'){$rc14=$rowcount}
		break
	}
	'IGR0000002'{
		if($temp[$i].Split("-")[2]-match'\d{7}091.xlsx.xlsx'){$rc7=$rowcount}
		if($temp[$i].Split("-")[2]-match'\d{7}092.xlsx.xlsx'){$rc8=$rowcount}
		if($temp[$i].Split("-")[2]-match'\d{7}151.xlsx.xlsx'){$rc11=$rowcount}
		if($temp[$i].Split("-")[2]-match'\d{7}152.xlsx.xlsx'){$rc12=$rowcount}
		if($temp[$i].Split("-")[2]-match'\d{7}201.xlsx.xlsx'){$rc15=$rowcount}
		if($temp[$i].Split("-")[2]-match'\d{7}202.xlsx.xlsx'){$rc16=$rowcount}
		break
	}
}
$ExcelObj.Workbooks.Close()
}
$ExcelObj.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ExcelObj)
Remove-Variable $ExcelObj
Write-Host 入境之〔本國人〕每日異動名單名冊:入境異動 $rc1 筆
Write-Host 入境之〔非本國人〕每日異動名單名冊:入境異動 $rc2 筆
Write-Host 入境之〔本國人〕每日異動名單名冊:入境刪除 $rc3 筆
Write-Host 入境之〔非本國人〕每日異動名單名冊:入境刪除 $rc4 筆
Write-Host 入境之〔本國人〕名冊（早09）:入境 $rc5 筆
Write-Host 出境之〔本國人〕名冊（早09）:出境 $rc6 筆
Write-Host 入境之〔非本國人〕名冊（早09）:入境 $rc7 筆
Write-Host 出境之〔非本國人〕名冊（早09）:出境 $rc8 筆
Write-Host 入境之〔本國人〕名冊（午15）:入境 $rc9 筆
Write-Host 出境之〔本國人〕名冊（午15）:出境 $rc10 筆
Write-Host 入境之〔非本國人〕名冊（午15）:入境 $rc11 筆
Write-Host 出境之〔非本國人〕名冊（午15）:出境 $rc12 筆
Write-Host 入境之〔本國人〕名冊（晚20）:入境 $rc13 筆
Write-Host 出境之〔本國人〕名冊（晚20）:出境 $rc14 筆
Write-Host 入境之〔非本國人〕名冊（晚20）:入境 $rc15 筆
Write-Host 出境之〔非本國人〕名冊（晚20）:出境 $rc16 筆
pause

