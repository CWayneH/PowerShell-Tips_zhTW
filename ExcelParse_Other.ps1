Write-Host '我是用〔往返各國, 管制, 入境架次, 事由統計, 大陸返台, 入境移工, DailyImmigPosAll, 防疫需求,入境旅客分類〕等關鍵字找檔案....'
$ExcelFileDir=Read-Host "FileDir"
$ExcelPWd=Read-Host "Password" -AsSecureString
$ExcelPWd=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ExcelPWd)
$ExcelPWd=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ExcelPWd)
$temp=@(dir $ExcelFileDir -Name -Include *.xlsx,*.xls -Exclude IGR*.xlsx,CDC*.xlsx)
$ExcelObj = $null
$ExcelObj = New-Object -ComObject Excel.Application
for($i=0;$i-lt$temp.Length;$i++){
	Write-Host "`t`t`t+`n`t`t`t-`n`t`t--`n`t---`n----Begin of "$temp[$i]
	# Write-Host Processing at : $i
	Write-Host "-------------------------`n-Processing at : "$i"`n-Matching filetype : "$ftype"`n-------------------------"
	$ExcelWorkBook = $ExcelObj.Workbooks.Open($ExcelFileDir+'\'+$temp[$i],0,0,5,$ExcelPWd)
	if($temp[$i]-match'往返各國'){$ftype='RT'}
	if($temp[$i]-match'管制'){$ftype='SNS'}
	if($temp[$i]-match'入境架次'){$ftype='FEE'}
	if($temp[$i]-match'事由統計'){$ftype='RS'}
	if($temp[$i]-match'大陸返台'){$ftype='CR'}
	if($temp[$i]-match'入境移工'){$ftype='EI'}
	if($temp[$i]-match'DailyImmigPosAll'){$ftype='DIPA'} # 20220128增
	if($temp[$i]-match'防疫需求'){$ftype='PDFP'} # 20220322增
	if($temp[$i]-match'入境旅客分類'){$ftype='IPC'} # 20220627增
	#當sheet僅1row時row1c組字串A1雖match為False仍會被count:1故硬加1
	# Write-Host Matching filetype : $ftype

		switch($ftype){
			'RT'{
				# # Write-Host -------- $temp[$i] --------
				$sheetc = $ExcelWorkBook.Sheets.Count
				for($j=1;$j-lt$sheetc+1;$j++){$sheetl+=$ExcelWorkBook.Sheets.Item($j).Name+','}
				Write-Host $temp[$i] : $sheetc sheets of $sheetl
				Write-Host "`n********"$temp[$i]"'s Result : 共"$sheetc"份統計資料 ********`n"
				break
				}
			'SNS'{
				# Write-Host -------- $temp[$i] --------
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
				Write-Host "`n********"$temp[$i]"'s Result : ********`n新增國人由疫區入境"$rowv[1]"筆。`n新增國人出境管制"$rowv[2]"筆(含CDC列管)。`n逾管制效期自動失效"$rowv[3]"筆。`n累計本國人出境管制"$rowv[4]"筆。`n新增外人由疫區入境"$rowv[5]"筆。`n新增外人出境管制"$rowv[6]"筆(含CDC列管)。`n逾管制效期自動失效"$rowv[7]"筆。`n累計外人出境管制"$rowv[8]"筆。"
				break
				}
			'FEE'{
				# Write-Host -------- $temp[$i] --------
				# 尋找excel表特定欄位的作法
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
				"`tif(" + $chksum2.Sum/2 + '=' + $fee_rowv2[$endidx2-1] + '):'
				if($chksum2.Sum/2 -eq $fee_rowv2[$endidx2-1]){"`r`n`t--> 架次Check <--"}else{"`r`n`t--> 架次Not Check <--"}
				$chksum3=$fee_rowv3[($endidx3-$j)..($endidx3-1)] | Measure-Object -Sum
				"`tif(" + $chksum3.Sum/2 + '=' + $fee_rowv3[$endidx3-1] + '):'
				if($chksum3.Sum/2 -eq $fee_rowv3[$endidx3-1]){"`r`n`t--> 人數Check <--"}else{"`r`n`t--> 人數Not Check <--"}
				Write-Host "`n********"$temp[$i]"'s Result : ********`n"
				Write-Host $fee_rowv2[$endidx2-1]'架次'
				Write-Host $fee_rowv3[$endidx3-1]'人'
				break
				}
			'RS'{
				# Write-Host -------- $temp[$i] --------
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
				"`tif(" + $chksum2.Sum/2 + '=' + $rs_col2[1] + '):'
				if($chksum2.Sum/2 -eq $rs_col2[1]){"`t--> 入境Check <--`r`n"}else{"`r`n`t--> 入境Not Check <--`r`n"}
				$chksum4=$rs_col4[1..($endidx4-1)] | Measure-Object -Sum
				"`tif(" + $chksum4.Sum/2 + '=' + $rs_col4[1] + '):'
				if($chksum4.Sum/2 -eq $rs_col4[1]){"`t--> 出境Check <--`r`n"}else{"`r`n`t--> 出境Not Check <--`r`n"}
				Write-Host "`n********"$temp[$i]"'s Result : ********`n"
				Write-Host '入境'$rs_col2[1]'人'
				Write-Host '出境'$rs_col4[1]'人'
				break
				}
			'CR'{
				# Write-Host -------- $temp[$i] --------
				$cr_col = $ExcelWorkBook.Sheets.Item(1).usedrange.columns("A").value2
				$cr_cnt = ($cr_col-match'\d{12}').count
				Write-Host $temp[$i] : $cr_cnt
				Write-Host "`n********"$temp[$i]"'s Result :共"$cr_cnt"筆 ********`n"
				break
			}
			'EI'{
				# Write-Host -------- $temp[$i] --------
				# 搜尋特定列or欄名的資料
				$col_find = [char]($ExcelWorkBook.Sheets.Item(1).cells.find('合計').column+64)
				$row_find = $ExcelWorkBook.Sheets.Item(1).cells.find('總計').row
				$cal_val = $ExcelWorkBook.Sheets.Item(1).range($col_find+$row_find).value2
				# 找第2:7列的資料用來檢核總計值
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
				"`tif(" + $col_find + $row_find + '之合計值' + $cal_val + '=' + $chk_val + '第2:7列檢核值):'
				if($cal_val -eq $chk_val){"`r`n`t--> 人數Check <--`r`n"}else{"`r`n`t--> 人數Not Check <--`r`n"}
				Write-Host "`n********"$temp[$i]"'s Result :共"$cal_val"筆 ********`n"
				# Write-Host -------- $temp[$i] --------
				break
			}
			'DIPA'{
				# Write-Host -------- $temp[$i] --------
				# 利用日期特徵搜尋該資料列
				$tgt_date = $temp[$i].Split('.')[0].Split('_')[-1]
				$row_find_dipa = $ExcelWorkBook.Sheets.Item(1).cells.find($tgt_date).row
				$val_dipa = @($ExcelWorkBook.Sheets.Item(1).usedrange.rows($row_find_dipa).value2)
				if($val_pdfp-ne$null){
					Write-Host Confirm :
					"`tif(本報表之入境：外人合計" + $val_dipa[6] + '=' + $val_pdfp[7] + '防疫需求外來人口入境目的統計表總計):'
					if($val_dipa[6] -eq $val_pdfp[7]){"`r`n`t--> 人數Check <--`r`n"}else{"`r`n`t--> 人數Not Check <--`r`n"}
				}
				if($val_ipc-ne$null){
					Write-Host Confirm :
					"`tif(本報表之入境：合計" + $val_dipa[7] + '=' + $val_ipc[4] + '入境旅客分類統計(陳政次指示)當日小計):'
					if($val_dipa[7] -eq $val_ipc[4]){"`r`n`t--> 人數Check <--`r`n"}else{"`r`n`t--> 人數 Not Check，請檢查是否為查驗補傳送資料誤差 <--`r`n"}
				}
				Write-Host $temp[$i] : $val_dipa[0] of $val_dipa
				Write-Host "`n********"$temp[$i]"'s Result : ********`n"
				Write-Host "1、入境總人次："$val_dipa[7]"人；含國人"$val_dipa[1]"人、大陸地區人民"$val_dipa[2]"人、港澳居民"$val_dipa[3]"人、無戶籍國民"$val_dipa[4]"人及外國人"$val_dipa[5]"人。"
				Write-Host "2、出境總人次："$val_dipa[14]"人；含國人"$val_dipa[8]"人、大陸地區人民"$val_dipa[9]"人、港澳居民"$val_dipa[10]"人、無戶籍國民"$val_dipa[11]"人及外國人"$val_dipa[12]"人。"		
				break
			}
			'PDFP'{
				# Write-Host -------- $temp[$i] --------
				$tgt_date2 = $temp[$i].Split('.')[0].Split('-')[-1]
				$row_find_pdfp = $ExcelWorkBook.Sheets.Item(1).cells.find($tgt_date2).row
				$val_pdfp = @($ExcelWorkBook.Sheets.Item(1).usedrange.rows($row_find_pdfp).value2)
				if($val_dipa-ne$null){
					Write-Host Confirm :
					"`tif(中外人士入出境統計表之入境：外人合計" + $val_dipa[6] + '=' + $val_pdfp[7] + '本報表之總計):'
					if($val_dipa[6] -eq $val_pdfp[7]){"`r`n`t--> 人數Check <--`r`n"}else{"`r`n`t--> 人數Not Check <--`r`n"}
				}
				Write-Host $temp[$i] : $val_pdfp[0] of $val_pdfp
				Write-Host "`n********"$temp[$i]"'s Result : ********`n"
				Write-Host '商務：'$val_pdfp[1]'人；求學'$val_pdfp[2]'人；探親'$val_pdfp[3]'人；居留'$val_pdfp[4]'人；移工'$val_pdfp[5]'人；其他'$val_pdfp[6]'人。'
				break
			}
			'IPC'{
				# Write-Host -------- $temp[$i] --------
				# 分隔檔名之日期是用')'較不普遍
				$tgt_date3 = $temp[$i].Split('.')[0].Split(')')[-1]
				$row_find_ipc = $ExcelWorkBook.Sheets.Item(1).cells.find($tgt_date3).row
				$val_ipc = @($ExcelWorkBook.Sheets.Item(1).usedrange.rows($row_find_ipc).value2)
				if($val_dipa-ne$null){
					Write-Host Confirm :
					"`tif(中外人士入出境統計表之入境：合計" + $val_dipa[7] + '=' + $val_ipc[4] + '本報表之總計):'
					if($val_dipa[7] -eq $val_ipc[4]){"`r`n`t--> 人數Check <-- `r`n"}else{"`r`n`t--> 人數 Not Check，請檢查是否為查驗補傳送資料誤差 <--`r`n"}
				}
				Write-Host $temp[$i] : $val_ipc[0] of $val_ipc
				Write-Host "`n********"$temp[$i]"'s Result : ********`n"
				Write-Host '國人：'$val_ipc[1]"人；`r`n無戶籍國人、陸港澳及外國人：`n`t1)居留證(含居留與永居)"$val_ipc[2]"人、`n`t2)入境許可證(含各種入出境許可及免簽)"$val_ipc[3]'人。'
				Write-Host				
				break
			}
		}
	$ExcelObj.Workbooks.Close()
	Write-Host "----End of "$temp[$i]"`n`t---`n`t`t--`n`t`t`t-"
}
Write-Host "-----------------------`n-End of Result printed-`n-----------------------"
$ExcelObj.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ExcelObj)
Remove-Variable $ExcelObj

pause
