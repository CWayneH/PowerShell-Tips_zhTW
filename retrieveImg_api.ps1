# Reference: http://hkeylocalmachine.com/?p=518
# Reference: https://tech.zsoldier.com/2018/08/powershell-making-restful-api-endpoint.html
$op_rec = '.\Logs\'
function base64Cvrt([string]$key,[int32]$ctrl){
	switch($ctrl){ 
		0 {return [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($key))}
		1 {return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($key))}
	}
}
function invoke4img([string]$key, [int32]$swCtrl){ #0:類別A,1:類別B的API
	if(!$key.Length){
		return $default = '{"rcode":"9993"}' | ConvertFrom-Json
	}else{
		switch($swCtrl){
			0 {	#類別A照片處理程序
				try {
					# ip mask
					$ip = "168.xx.xx.125:xx"
					$EndPoint = "http://$ip/wsc.asmx/IMGObtain?Type=2&Key=$key"
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
						$default = '{"rcode":"9993"}' | ConvertFrom-Json
					}
					return $default
				}
				catch {
					Write-Output $Error[0]
					$err = $Error[0]
					Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[error]uniqueId:$key fail by ""$err"" " $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
				}
			}
			1 { #類別B照片處理程序
				try {
					# ip mask
					$ip = "168.xx.xx.81:xx"
					$EndPoint = "http://$ip/cassandraws/ws/rs/BImageService/queryImage"
					$Headers = @{ 'Content-Type' = 'application/json'; }
					$Body = (@{"uniqueId" = $key } | ConvertTo-Json)
					$res = Invoke-RestMethod $EndPoint -Method 'POST' -Headers $Headers -Body $Body
					$default = $res
					return $default
				}
				catch {
					Write-Output $Error[0]
					$err = $Error[0]
					Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[error]uniqueId:$key fail by ""$err"" " $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
				}
			}
		}
	}
}

Out-File -Append -InputObject "START TIME:$(Get-Date)" $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
# Create a listener on port 59876
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://+:59876/') 
$listener.Start()
'Listening ...'
 
# Run until you send a GET request to /end
while ($true) {
    $context = $listener.GetContext()
    # Capture the details about the request
    $request = $context.Request
    $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $request.InputStream, $request.ContentEncoding
    # Setup a place to deliver a response
    $response = $context.Response

    if ($request.url.PathAndQuery -match "/end$")
    {Break;}
	#測試取網路圖片
	elseif($request.url.PathAndQuery.Split("/")[1] -match "images$")
	{
		Switch ($request.HttpMethod) {
                default {
                        $message = "<HTML><body>Unsupported Method</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                        }
                    GET {
                        $imgUrl = $request.url.PathAndQuery
						$imgUrl = 'https://www.google.com'+$imgUrl
						$imgUrl = (Invoke-WebRequest $imgUrl).Content
						$message = [System.Convert]::ToBase64String($imgUrl)
						#$imgUrl = [System.Text.Encoding]::UTF8.GetBytes($imgUrl)
						#$message = $(base64Cvrt $imgUrl 0)
						$response.ContentType = 'text/html'
                        $response.StatusCode = 200
                    }
                }
		[byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
        $response.ContentLength64 = $buffer.length
        $output = $response.OutputStream
        $output.Write($buffer, 0, $buffer.length)
        $output.Close()
	}
	elseif($request.url.PathAndQuery.Split("/")[1].Split("?")[0] -match "localimg$")
	{
		Switch ($request.HttpMethod) {
                default {
                        $message = "<HTML><body>Unsupported Method</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                        }
                    GET {
                        $key = $request.url.PathAndQuery.Split("/")[-1].Split("&")[-1].Split("=")[-1]
                        $filePath = 'D:\{path}\TestApi\Pics\'
						$key = Get-ChildItem -Path $filePath -Include $key*.jpg, $key*.png, $key*.tiff -Name
						if($key){
							$imgUrl = $filePath+$key
							$imgUrlb64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($imgUrl))
							$default = '<?xml version="1.0" encoding="utf-8"?><IMGObtain><RESPONSE>MHgwMA==</RESPONSE><URL>'+$imgUrlb64+'</URL></IMGObtain>'
						}else{
							$default = '<?xml version="1.0" encoding="utf-8"?><IMGObtain><RESPONSE>MHgwMg==</RESPONSE></IMGObtain>'
						}
						$message = $default
						$response.ContentType = 'text/xml; charset=utf-8'
						$response.StatusCode = 200
						Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) Prepare response:$message" $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
                    }
                }
		[byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
        $response.ContentLength64 = $buffer.length
        $output = $response.OutputStream
        $output.Write($buffer, 0, $buffer.length)
        $output.Close()
	}
    else {
        Switch ($request.Url.PathAndQuery) {
		
            default {
                $message = "<HTML><body>Unsupported</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
            }
            "/" {
                Switch ($request.HttpMethod) {
                    default {
                        $message = "<HTML><body>Unsupported Method</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                        }
                    GET {
                        $message = "<HTML><body>Unsupported</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                    }
                    POST {
                        $message = "<HTML><body>Unsupported</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                    }
                }
            }
			#取得local照片
            "/localimg/cassandraws/ws/rs/BImageService/queryImage" {
                Switch ($request.HttpMethod) {
                default {
                        $message = "<HTML><body>Unsupported Method</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                        }
                    GET {
						$message = "<HTML><body>Unsupported</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                    }
                    POST { 
                        $jsondata = $reader.readtoEnd()
            
                        # Convert from json to PSObject
                        IF (!($v = $jsondata | ConvertFrom-Json))
                        {
                            $message = '<HTML><body>Json validation failed.</body></HTML>'
                            $response.ContentType = 'text/html'
                            $response.StatusCode = 400
                        }
                        # If conversion fails, json format assumed incorrect.
                        
                        # Test Message, basically returns the json that was posted back to you.
                        $key = $v.uniqueId
						$filePath = '.\'
						$key = Get-ChildItem -Path $filePath -Include $key*.jpg, $key*.png, $key*.tiff -Name
						$key = Get-Content .\$key -Encoding Byte
						#$key = $(base64Cvrt $key 0)
						$key = [System.Convert]::ToBase64String($key)
						$default = '{"rcode":"0000","value":"'+$key+'"}' | ConvertFrom-Json
						$message = $default | ConvertTo-Json -Depth 10
                        $response.ContentType = 'application/json'
                    }
                }
            }
            #取得他地照片(需變key值)
			"/redirimg/cassandraws/ws/rs/BImageService/queryImage" {
                Switch ($request.HttpMethod) {
                default {
                        $message = "<HTML><body>Unsupported Method</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                        }
                    GET {
                        $message = "<HTML><body>Unsupported</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                    }
                    POST {
                        $jsondata = $reader.readtoEnd()
            
                        # Convert from json to PSObject
                        IF (!($v = $jsondata | ConvertFrom-Json))
                        {
                            $message = '<HTML><body>Json validation failed.</body></HTML>'
                            $response.ContentType = 'text/html'
                            $response.StatusCode = 400
                        }
                        # If conversion fails, json format assumed incorrect.
                        
                        # Test Message, basically returns the json that was posted back to you.
                        $key = $v.uniqueId
						try {
							# ip mask
							$ip = "168.xx.xx.125:xx"
							$EndPoint = "http://$ip/wsc.asmx/IMGObtain?Type=2&Key=$key"
							$res = Invoke-RestMethod $EndPoint -Method 'GET'
							Write-Output $res | ConvertTo-Json
							
						}
						catch {
							Write-Output $Error[0]
							$err = $Error[0]
							Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[error]uniqueId:$key fail by ""$err"" " $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
						}
						$resRcode = $res.IMGObtain.RESPONSE
						$resUrl = $res.IMGObtain.URL
						$resRcode = $(base64Cvrt $resRcode 1)
						$resUrl = $(base64Cvrt $resUrl 1)
						$resUrl = (Invoke-WebRequest $resUrl).Content
						$imgB64 = $(base64Cvrt $resUrl 0)
						if(![uint32]$resRcode){$resRcode = '0000'} else {$resRcode = '9993'}
						$default = '{"rcode":"'+$resRcode+'","value":"'+$imgB64+'"}' | ConvertFrom-Json
						$message = $default | ConvertTo-Json -Depth 10
                        $response.ContentType = 'application/json'
                    }
                }
            }	
			#取得他地照片(parse原始資料找取照片key值)
			"/parseimg/cassandraws/ws/rs/BImageService/queryImage" {
                Switch ($request.HttpMethod) {
				default {
                        $message = "<HTML><body>Unsupported Method</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                        }
                    GET {
                        $message = "<HTML><body>Unsupported</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                    }
                    POST {
                        $jsondata = $reader.readtoEnd()
						# Convert from json to PSObject
                        IF (!($v = $jsondata | ConvertFrom-Json))
                        {
                            $message = '<HTML><body>Json validation failed.</body></HTML>'
                            $response.ContentType = 'text/html'
                            $response.StatusCode = 400
                        }
                        # If conversion fails, json format assumed incorrect.
                        
                        # Test Message, basically returns the json that was posted back to you.
                        $key = $v.uniqueId
						Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) TARGET UniqueId:$key" $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
						$filePath = '.\retrieve_dataset\'
						#第一次呼叫類別B的API
						$default = $(invoke4img $key 1)
						$Error.Clear()
						#檢查ERR檔案有無相同uniqueId對應的基資
						try {
							$keyArr = Get-Content $filePath*.csv -Encoding UTF8 | Select-String -Pattern $key
						}catch {
							Write-Output $Error[0]
							$err = $Error[0]
							Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[error]uniqueId:$key fail by ""$err"" " $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
						}
						#如在檔案內有多筆相同Key以迴圈處理
						for($i=0;$i-lt$keyArr.Length;$i++){
							$temp = $keyArr[$i].ToString()
							if(![uint32]$default.rcode){	
								Write-Output $default' [get pic]uniqueId: '	$key
								Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[getpic]uniqueId:$key " $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
							}elseif(!$Error[0]) #檢查ERR檔案有相同uniqueId即True進行Parse並呼叫Esico API
							{
								$keyRcv = $temp.Split(",")[5].Trim() #證號A欄位
								$keyRsi = $temp.Split(",")[8].Trim() #證號B欄位
								if(![uint32]($(invoke4img $keyRcv 0).rcode)){ #檢查rcode為0即True
									$default = $(invoke4img $keyRcv 0)
									Write-Output $default' [get pic]receive no: '$keyRcv
									Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[getpic]receive no:$keyRcv " $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
								}elseif(![uint32]($(invoke4img $keyRsi 0).rcode)){
									$default = $(invoke4img $keyRsi 0)
									Write-Output $default' [get pic]residence no: '$keyRsi
									Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[getpic]residence no:$keyRsi " $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
								}else{ #uniqueId對應證號A或證號B查無照片逕以類別B的API結果回傳
									Write-Output $default' [nopics]ERR had mapping data: '$keyRcv, $keyRsi
									Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[nopics]ERR had mapping data:$keyRcv, $keyRsi ." $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
								}
							#ERR檔案內無對應可用基資逕以類別B的API結果回傳
							}else{	
								Write-Output $default' [nopics]ERR had no mapping data '	
								Out-File -Append -InputObject " $(Get-Date -DisplayHint Time)[nopics]ERR had no mapping data " $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
							}
						}
						$message = $default | ConvertTo-Json -Depth 10
                        $response.ContentType = 'application/json'
                    }
                }
            }				
		}
        [byte[]]$buffer = [System.Text.Encoding]::UTF8.GetBytes($message)
        $response.ContentLength64 = $buffer.length
        $output = $response.OutputStream
        $output.Write($buffer, 0, $buffer.length)
        $output.Close()
    }
}
$listener.stop()
$listener.dispose()
Out-File -Append -InputObject "END TIME:$(Get-Date)" $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'
Out-File -Append -InputObject "--------------------Finished--------------------" $op_rec$(Get-Date -Format "yyyy-MM-dd")'_API_Log.txt'

# 2021-06-18
# Author@CWayneH
