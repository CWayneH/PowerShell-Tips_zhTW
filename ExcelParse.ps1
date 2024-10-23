# Gather shell what you need.
<#
match result between asset list and state property
#>
$sheet_list = Get-ChildItem -Name *.xls
$ExcelObj = New-Object -ComObject Excel.Application
$ExcelWorkBook = $ExcelObj.Workbooks.Open('D:\\..\\..\\ASSET.xls')
$ExcelWorkBook.Sheets.Item(1).range("A:A")
