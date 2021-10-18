$ExcelFileDir=Read-Host "FileDir"
$ExcelPWd=Read-Host "Password" -AsSecureString
$ExcelPWd=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ExcelPWd)
$ExcelPWd=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ExcelPWd)
$temp=dir $ExcelFileDir -Name -Include *.xlsx -Exclude IGR*.xlsx,CDC*.xlsx
$ExcelObj = $null
$ExcelObj = New-Object -ComObject Excel.Application
for($i=0;$i-lt$temp.Length;$i++){
	$ExcelWorkBook = $ExcelObj.Workbooks.Open($ExcelFileDir+'\'+$temp[$i],0,0,5,$ExcelPWd)
	if($temp[$i]-match'往返各國'){$ftype='RT'}
	if($temp[$i]-match'管制'){$ftype='SNS'}
	if($temp[$i]-match'入境架次'){$ftype='FEE'}
	if($temp[$i]-match'事由統計'){$ftype='RS'}
	if($temp[$i]-match'大陸返台'){$ftype='CR'}
	if($temp[$i]-match'入境移工'){$ftype='EI'}
	#當sheet僅1row時row1c組字串A1雖match為False仍會被count:1故硬加1


		switch($ftype){
			'RT'{
				Write-Host -------- $temp[$i] --------
				$sheetc = $ExcelWorkBook.Sheets.Count
				for($j=1;$j-lt$sheetc+1;$j++){$sheetl+=$ExcelWorkBook.Sheets.Item($j).Name+','}
				Write-Host $temp[$i] : $sheetc sheets of $sheetl
				Write-Host '******** Result : 共'$sheetc'份統計資料 ********'
				break
				}
			'SNS'{
				Write-Host -------- $temp[$i] --------
				$rowmd=@($ExcelWorkBook.sheets.item(2).rows(3).value2)
				$rowmd2=@($ExcelWorkBook.sheets.item(2).rows(2).value2)
				$rowmd = $rowmd | Where-Object { $_ -ne $null }
				$rowc="A"+($ExcelWorkBook.sheets.item(2).UsedRange.Rows.Count)
				$rowa=$ExcelWorkBook.sheets.item(2).Range("A1",$rowc).Value2
				$rowcount=($rowa-match'\d{8}').Count+3
				$rowv=@($ExcelWorkBook.sheets.item(2).rows($rowcount).value2)
				for($j=0;$j-lt$rowmd.Length;$j++){$vall+='|---'+$rowmd2[$j+1]+'---|'+$rowmd[$j]+':'+$rowv[$j+1]}
				$vall = $vall.Replace('|------|',', ')
				Write-Host $temp[$i] : $rowv[0] of $vall
				
				Write-Host '******** Result : ********'
				Write-Host '新增國人由疫區入境'$rowv[1]'筆。'
				Write-Host '新增國人出境管制'$rowv[2]'筆(含CDC列管)。'
				Write-Host '逾管制效期自動失效'$rowv[3]'筆。'
				Write-Host '累計本國人出境管制'$rowv[4]'筆。'
				Write-Host '新增外人由疫區入境'$rowv[5]'筆。'
				Write-Host '新增外人出境管制'$rowv[6]'筆(含CDC列管)。'
				Write-Host '逾管制效期自動失效'$rowv[7]'筆。'
				Write-Host '累計外人出境管制'$rowv[8]'筆。'
				break
				}
			'FEE'{
				Write-Host -------- $temp[$i] --------
				$fee_rowv=@($ExcelWorkBook.Sheets.Item(1).usedrange.columns("C").value2) | Where-Object { $_ -ne $null }
				$fee_rowv2=@($ExcelWorkBook.Sheets.Item(1).usedrange.columns("D:E").value2) | Where-Object { $_ -ne $null }
				$fee_rowv3=@($ExcelWorkBook.Sheets.Item(1).usedrange.columns("Q:R").value2) | Where-Object { $_ -ne $null }
				for($j=0;$j-lt$fee_rowv.Length-2;$j++){
					if($fee_rowv[$j+2] -eq ''){$fee_rowv[$j+2]='總共'}
					$fee_rowv[$j+2]+'來'+$fee_rowv2[$j+3]+'架有'+$fee_rowv3[$j+1]+'人'
					}
				$endidx2 = $j+3
				$endidx3 = $j+1
				$chksum2=$fee_rowv2[($endidx2-$j)..($endidx2-1)] | Measure-Object -Sum
				'if(' + $chksum2.Sum/2 + '=' + $fee_rowv2[$endidx2-1] + '):'
				if($chksum2.Sum/2 -eq $fee_rowv2[$endidx2-1]){'架次Check'}else{'架次 Not Check'}
				$chksum3=$fee_rowv3[($endidx3-$j)..($endidx3-1)] | Measure-Object -Sum
				'if(' + $chksum3.Sum/2 + '=' + $fee_rowv3[$endidx3-1] + '):'
				if($chksum3.Sum/2 -eq $fee_rowv3[$endidx3-1]){'人數Check'}else{'人數 Not Check'}
				Write-Host '******** Result : ********'
				Write-Host $fee_rowv2[$endidx2-1]'架次'
				Write-Host $fee_rowv3[$endidx3-1]'人'
				break
				}
			'RS'{
				Write-Host -------- $temp[$i] --------
				$rs_col1=@($ExcelWorkBook.Sheets.Item(1).usedrange.columns("A").value2) | Where-Object { $_ -ne $null }
				$rs_col2=@($ExcelWorkBook.Sheets.Item(1).usedrange.columns("B").value2) | Where-Object { $_ -ne $null }
				$rs_col3=@($ExcelWorkBook.Sheets.Item(1).usedrange.columns("E:F").value2) | Where-Object { $_ -ne $null }
				$rs_col4=@($ExcelWorkBook.Sheets.Item(1).usedrange.columns("G").value2) | Where-Object { $_ -ne $null }
				$rs_cnt_entry=($rs_col1.Count, $rs_col2.Count | measure -Maximum).Maximum
				$rs_cnt_exit=($rs_col3.Count, $rs_col4.Count | measure -Maximum).Maximum
				Write-Host $rs_col1[0]
				for($j=3;$j-lt$rs_cnt_entry;$j++){
					$rs_col1[$j]+$rs_col2[0]+$rs_col2[$j-1]+'人'
					}
				$endidx2 = $j	
				for($j=2;$j-lt$rs_cnt_exit;$j++){
					$rs_col3[$j]+$rs_col4[0]+$rs_col4[$j]+'人'
					}	
				$endidx4 = $j
				$chksum2=$rs_col2[1..($endidx2-1)] | Measure-Object -Sum
				'if(' + $chksum2.Sum/2 + '=' + $rs_col2[1] + '):'
				if($chksum2.Sum/2 -eq $rs_col2[1]){'入境Check'}else{'入境 Not Check'}
				$chksum4=$rs_col4[1..($endidx4-1)] | Measure-Object -Sum
				'if(' + $chksum4.Sum/2 + '=' + $rs_col4[1] + '):'
				if($chksum4.Sum/2 -eq $rs_col4[1]){'出境Check'}else{'出境 Not Check'}
				Write-Host '******** Result : ********'
				Write-Host '入境'$rs_col2[1]'人'
				Write-Host '出境'$rs_col4[1]'人'
				break
				}
			'CR'{
				Write-Host -------- $temp[$i] --------
				$cr_col = $ExcelWorkBook.Sheets.Item(1).usedrange.columns("A").value2
				$cr_cnt = ($cr_col-match'\d{12}').count
				Write-Host $temp[$i] : $cr_cnt
				Write-Host '******** Result :共'$cr_cnt'筆 ********'
				break
			}
			'EI'{
				Write-Host -------- $temp[$i] --------
				$col_find = [char]($ExcelWorkBook.Sheets.Item(1).cells.find('合計').column+64)
				$row_find = $ExcelWorkBook.Sheets.Item(1).cells.find('總計').row
				$cal_val = $ExcelWorkBook.Sheets.Item(1).range($col_find+$row_find).value2
				$ei_rowv = @($ExcelWorkBook.Sheets.Item(1).usedrange.rows("2:7").value2) | Where-Object { $_ -ne $null }
				for($j=0;$j-lt$ei_rowv.Length;$j++){
					if($j%5-ne0-and$j%5-ne4){$arr += $ei_rowv[$j].tostring() + ', '}				
					if($ei_rowv[$j].GetType().name-eq[double]){
						if($j%5-eq2-or$j%5-eq3){$chk_val+=$ei_rowv[$j]}
					}
				}
				Write-Host $temp[$i] of Calculate Location : $col_find + $row_find
				Write-Host Result : $cal_val
				Write-Host Confirm :
				'if(' + $cal_val + '=' + $chk_val + '):'
				if($cal_val -eq $chk_val){'人數Check'}else{'人數 Not Check'}
				Write-Host '******** Result :共'$cal_val'筆 ********'
				break
			}
		}
	$ExcelObj.Workbooks.Close()
}
$ExcelObj.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ExcelObj)
Remove-Variable $ExcelObj

pause
