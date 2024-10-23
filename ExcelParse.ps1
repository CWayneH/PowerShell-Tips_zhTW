# Gather shell what you need.
<#
match result between asset ledger and state property
#>
$ExcelFileDir=Read-Host "FileDir"
DO
{
  # $temp=@(dir $ExcelFileDir -Name -Include *.xls)
  $ExcelObj = New-Object -ComObject Excel.Application
  # $ExcelWorkBook = $ExcelObj.Workbooks.Open($ExcelFileDir+'\'+$temp[0])
  $sp_file_name = Read-Host "State Property File Name"
  $ExcelWorkBook = $ExcelObj.Workbooks.Open($ExcelFileDir+'\'+$sp_file_name)
  $sp_list_uni = $ExcelWorkBook.Sheets.Item(1).columns(1).value2
  $al_file_name = Read-Host "Asset Ledger File Name"
  $ExcelWorkBook = $ExcelObj.Workbooks.Open($ExcelFileDir+'\'+$al_file_name)
  $al_list_uni = $ExcelWorkBook.Sheets.Item(1).columns(1).value2
  $res = (Compare-Object -ReferenceObject ($sp_list_uni) -DifferenceObject ($al_list_uni)).InputObject
  
  # output
  Get-Date -Format "yyyy-MM-dd hh:mm:ss" | Out-File -FilePath $ExcelFileDir'\res.log' -Append
  "compare between $sp_file_name and $al_file_name :" | Out-File -FilePath $ExcelFileDir'\res.log' -Append
  $res | Out-File -FilePath $ExcelFileDir'\res.log' -Append
  " ..." | Out-File -FilePath $ExcelFileDir'\res.log' -Append
  $ExcelObj.Workbooks.Close()
  $ctrl = Read-Host "Another round?"
} while ($ctrl -notmatch 'N')
# gc
$ExcelObj.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($ExcelObj)
Remove-Variable $ExcelObj

pause

# Author@CWayneH
