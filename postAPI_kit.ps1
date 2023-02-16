$output = '.\Logs\'
function base64Cvrt([string]$key,[int32]$ctrl){
	switch($ctrl){ 
		0 {return [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($key))}
		1 {return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($key))}
	}
}
function invoke4img([string]$key, [int32]$swCtrl){ #0:申請案,1:管制API,2:IMMI/EGATE
	if(!$key.Length){
		return $default = '{"rcode":"1003"}' | ConvertFrom-Json
	}else{
		switch($swCtrl){
			0 {	#申請案照片處理程序
				try {
					# ip mask
					$ip = "168.xx.xx.125:xx"
					$EndPoint = "http://$ip/wsc.asmx/IMGObtain?strType=2&strBarcode=$key"
					$res = Invoke-RestMethod $EndPoint -Method 'GET'
					#處理回傳base64decode
					$resRcode = $res.IMGObtain.RESPONSE
					$resRcode = $(base64Cvrt $resRcode 1)
					$resUrl = $res.IMGObtain.URL
					$resUrl = $(base64Cvrt $resUrl 1)
					#rcode為0再串imgB64code
					if(![uint32]$resRcode){
						$resRcode = '0000'
						#照片url取byte再base64encode
						$imgByte = (Invoke-WebRequest $resUrl).Content
						$imgB64 = [System.Convert]::ToBase64String($imgByte)
						$default = '{"rcode":"'+$resRcode+'","value":"'+$imgB64+'"}' | ConvertFrom-Json
					} 
					else {
						$default = '{"rcode":"1003"}' | ConvertFrom-Json
					}
					return $default
				}
				catch {
					Write-Output $Error[0]
					$err = $Error[0]
					Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[error]uniqueId:$key fail by ""$err"" " $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
				}
			}
			1 { #Cassandraws Security照片處理程序
				try {
					# ip mask
					$ip = "168.xx.xx.81:xx"
					$EndPoint = "http://$ip/cassandraws/ws/rs/lisImageService/queryImage"
					$Headers = @{ 'Content-Type' = 'application/json'; }
					$Body = (@{"uniqueId" = $key } | ConvertTo-Json)
					$res = Invoke-RestMethod $EndPoint -Method 'POST' -Headers $Headers -Body $Body
					$default = $res
					return $default
				}
				catch {
					Write-Output $Error[0]
					$err = $Error[0]
					Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[error]uniqueId:$key fail by ""$err"" " $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
				}
			}
			2 { #Cassandraws IMMI/EGATE照片處理程序
				try {
					# ip mask
					$ip = "168.xx.xx.81:xx"
					$EndPoint = "http://$ip/cassandraws/ws/rs/niaImageService/getImage"
					$Headers = @{ 'Content-Type' = 'application/json'; }
					$passid = $key.Substring(0,10)
					$cdate = $key.Substring(10,8)
					$cn = $key.Substring(18,5)
					$Body = (@{"passengerId" = $passid ; "capDate" = $cdate ; "capNo" = $cn ; "nosqlType" = "EgateApplyImage"} | ConvertTo-Json)
					$res = Invoke-RestMethod $EndPoint -Method 'POST' -Headers $Headers -Body $Body
					$default = $res
					return $default
				}
				catch {
					Write-Output $Error[0]
					$err = $Error[0]
					Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[error]uniqueId:$key fail by ""$err"" " $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
				}
			}
		}
	}
}

Out-File -Append -InputObject "START TIME:$(Get-Date)" $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
$postWay = Read-Host "Choose one POST Path (1:SECURITY, 2:IMMI/EGATE, 3:APPLYCASE):"
$dataArr = Get-Content D:\{path}\API\postAPI_target\*.csv -Encoding UTF8
$keyPos = Read-Host "?Where is Key Column offset(0-N)"
switch($postWay){
	1{
		$photoType = Read-Host "Choose getImage Level (0:Normal/1:Multi)"
		try{
			for($i=0;$i-lt$dataArr.Length;$i++){
				
				$key = $dataArr[$i].Split(",")[$keyPos].Trim()
				#OldKey:$key = $dataArr[$i].Split(",")[0].Trim()+$dataArr[$i].Split(",")[1].Trim()+$dataArr[$i].Split(",")[2].Trim()
				if(![uint32]$photoType){
					$payload = $(invoke4img $key 1)
				}elseif([uint32]$photoType) {
						
					$keyRcv = $dataArr[$i].Split(",")[5].Trim()
					$keyRsi = $dataArr[$i].Split(",")[8].Trim()
					
					$resRcv = $(invoke4img $keyRcv 0)
					$resRsi = $(invoke4img $keyRsi 0)
					if(![uint32]($resRcv.rcode)){
						$payload = $resRcv
						Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) Getpic of $key from ReceiveNo($keyRcv)" $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
						$key = $keyRcv + '@' + $key
					}elseif(![uint32]($resRsi.rcode)){
						$payload = $resRsi
						Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) Getpic of $key from ResidenceNo($keyRsi)" $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
						$key = $keyRsi + '@' + $key
					}else{
						$payload = '{"rcode":"1003"}' | ConvertFrom-Json
					}
					
				}else{
					$payload = '{"rcode":"9999","value":"Wrong getImage Type "}' | ConvertFrom-Json
				}
				
				$rcode = $payload.rcode
				$value = $payload.value
				#rcode為0時寫Bytes到照片檔
				if(![uint32]($payload.rcode)){
					$fn = '.\Export\'+$key+'.jpg'
					$bytes = [Convert]::FromBase64String($value)
					[IO.File]::WriteAllBytes($fn, $bytes)
				}
				
				Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) The $key Result is $rcode" $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
				Write-Progress -Activity "Image Processing" -Status "Progress(%):" -PercentComplete ((($i+1)/($dataArr.Length))*100)
			}

		}catch{
			Write-Output $Error[0]
			$err = $Error[0]
			Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[error]uniqueId:$key fail by ""$err"" " $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
		}
		
	}
	2{
		$photoType = Read-Host "Choose getImage Type (0:IMMI/1:EGATE)"
		try{
			for($i=0;$i-lt$dataArr.Length;$i++){
			
				$key = $dataArr[$i].Split(",")[$keyPos].Trim()
				if(![uint32]$photoType){
					$payload = $(invoke4img $key 2)
				}elseif([uint32]$phtotType){
					$payload = $(invoke4img $key 3)
				}else{
					$payload = '{"rcode":"9999","value":"Wrong getImage Type "}' | ConvertFrom-Json
				}
				
				$rcode = $payload.rcode
				$value = $payload.value
				if(![uint32]($payload.rcode)){
					$fn = '.\Export\'+$key+'.jpg'
					$bytes = [Convert]::FromBase64String($value)
					[IO.File]::WriteAllBytes($fn, $bytes)
				}
				
				Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) The $key Result is $rcode" $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
				Write-Progress -Activity "Image Processing" -Status "Progress(%):" -PercentComplete ((($i+1)/($dataArr.Length))*100)
			}

		}catch{
			Write-Output $Error[0]
			$err = $Error[0]
			Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[error]uniqueId:$key fail by ""$err"" " $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
		}
		
	
	}
	3{
		
		try{
			for($i=0;$i-lt$dataArr.Length;$i++){
			
				$key = $dataArr[$i].Split(",")[$keyPos].Trim()
				$payload = $(invoke4img $key 1)
				
				$rcode = $payload.rcode
				$value = $payload.value
				if(![uint32]($payload.rcode)){
					$fn = '.\Export\'+$key+'.jpg'
					$bytes = [Convert]::FromBase64String($value)
					[IO.File]::WriteAllBytes($fn, $bytes)
				}
				
				Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) The $key Result is $rcode" $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
				Write-Progress -Activity "Image Processing" -Status "Progress(%):" -PercentComplete ((($i+1)/($dataArr.Length))*100)
			}

		}catch{
			Write-Output $Error[0]
			$err = $Error[0]
			Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[error]uniqueId:$key fail by ""$err"" " $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'
		}
		
	
	}
}

Out-File -Append -InputObject "END TIME:$(Get-Date)" $output$(Get-Date -Format "yyyy-MM-dd")'_postlog.txt'

# 2021-07-28
# Author@CWayneH
