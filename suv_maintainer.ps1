# Reference: http://hkeylocalmachine.com/?p=518
# Reference: https://tech.zsoldier.com/2018/08/powershell-making-restful-api-endpoint.html

$op_rec = '.\Logs\'
Out-File -Append -InputObject "START TIME:$(Get-Date)" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
# Create a listener on port 80
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://+:5987/') 
$listener.Start()
'Listening ...'
$counter = 0
# Run until you send a GET request to /end
while ($true) {
    $context = $listener.GetContext()
    # Capture the details about the request
    $request = $context.Request
    $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $request.InputStream, $request.ContentEncoding
    # Setup a place to deliver a response
    $response = $context.Response
	
	# initial setup
	$goodStatus = "G"
	$badStatus = "Y"
	$IPs = "168.203.32.202","168.203.32.203"
	$ports = 8001,8002,8000
	$frame = "http:///check_all"
	$EndPoints = foreach ($i in $IPs){ foreach ($j in $ports) {$frame.Insert(7,$i+":"+$j)} }
    if ($request.url.PathAndQuery -match "/end$")
    {Break;}
	else {
		$RemoteAddr = $request.RemoteEndPoint.toString().split(":")[0]
		Write-Output origin:$RemoteAddr
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
			# 23-12-08 developed for practice
			"/maintainer/imgobtain" {
				if ($request.HttpMethod -eq 'POST') {
					
					$res = try {
						Invoke-RestMethod -Uri "http://168.203.20.125:8084/wsc.asmx/IMGObtain?strType=01234&strBarcode=56789" -Method "GET"
					} catch {
						$_.ErrorDetails.Message
					}
					
					$rcodeSwitch = $res.ChildNodes.Length
					if(!$rcodeSwitch){
						$state = $badStatus
						$refinfo = '=====Exception information=====\r\n'+$res
					} else {
						$state = $goodStatus
						$refinfo = 'HTTP GET IMGObtain(168.203.20.125) Response: '+[String]($res.IMGObtain | ConvertTo-Csv).Replace('"','\"')
						# $refinfo_rep=$refinfo.replace('{','\{').replace('}','\}')
					}
					
					$default = '{"status":"'+$state+'","desc":"'+$refinfo+'"}' | ConvertFrom-Json
					$message = $default | ConvertTo-Json -Depth 10
					$response.ContentType = 'application/json'
					Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) From $RemoteAddr POST Prepared response:$message" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
				}
			}
			"/maintainer" {
				Switch ($request.HttpMethod) {
					default {
                        $message = "<HTML><body>Unsupported Method</body></HTML>"
                        $response.ContentType = 'text/html'
                        $response.StatusCode = 400
                        }
                    GET {
						try {		
							$EndPoint = "http://"+$RemoteAddr+":8000/check_all"
							$res = Invoke-RestMethod -Uri $EndPoint -Method "GET"
							Write-Output $res | ConvertTo-Json
						}	
						catch {
							Write-Output $Error[0]
						}
						if(![uint32]$res.code){$state = $goodStatus} else {$state = $badStatus}
						$meta = $EndPoint.split("/")[2]
						$default = '{"status":"'+$state+'","desc":"'+$meta+'"}' | ConvertFrom-Json
						$message = $default | ConvertTo-Json -Depth 10
						$response.ContentType = 'application/json'
						Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) GET Prepared response:$message" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
                    }
					# SUV agent use POST method.
                    POST {
                        # http request by sequence
						# 23-12-07 try-catch for FRE bad http status
						$res = $EndPoints | ForEach-Object {
							try { Invoke-RestMethod $_ } catch { $_.ErrorDetails.Message | ConvertFrom-Json }
						}
						$len = $res.Length
						# apply service url in array.status
						$res.status | Add-Member -Name 'service' -MemberType NoteProperty -Value $null
						0..($len-1) | ForEach-Object {$res[$PSItem].status.service = $EndPoints[$PSItem]}
						Write-Output $res | ConvertTo-Json
						# sum approach to determine if good / bad.
						$rcodeSwitch = ($res.code | Measure-Object -Sum).Sum
						if(![uint32]$rcodeSwitch){
							$state = $goodStatus
							$refinfo = 'All '+$len+' nodes below are well; '+ [String]::Join(', ',$res.status.service)
						} else {
							$state = $badStatus
							$refinfo = [String]::Join(',',($res | ?{$_.code -ne 0}).status)
							# $refinfo_rep=$refinfo.replace('{','\{').replace('}','\}')
						}
						
						$default = '{"status":"'+$state+'","desc":"'+$refinfo+'"}' | ConvertFrom-Json
						$message = $default | ConvertTo-Json -Depth 10
						$response.ContentType = 'application/json'
						Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) From $RemoteAddr POST Prepared response:$message" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
                    }
                }
				Write-Output ProcessID:$PID
				$counter++
				Write-Output $counter
				Out-File -Append -InputObject "Current Process($PID) is counting $counter usage" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
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
Out-File -Append -InputObject "END TIME:$(Get-Date)" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
Out-File -Append -InputObject "--------------------Finished--------------------" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'

# version-0.1.0
# Author@CWayneH
