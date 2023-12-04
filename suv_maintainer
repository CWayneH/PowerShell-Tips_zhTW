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
	$badStatus = "R"
	$IPs = "168.**.32.202","168.**.32.203"
	$ports = 12001,12002,12003
	$frame = "http:///checksts"
	# IP list composed.
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
			"/testing" {
				if ($request.HttpMethod -eq 'GET') {
					try {
						# http request by sequence
						$res = $EndPoints | ForEach-Object {Invoke-RestMethod $_}
						Write-Output $res | ConvertTo-Json
					}
					catch {
							Write-Output $Error[0]
					}
					# to do : set the if-state to diff good/bad payload
					if(![uint32]$res.code){$state = $goodStatus} else {$state = $badStatus;$badPayload = $res | ?{$_.code-notmatch 0} | ConvertTo-Json -Depth 10}
					$meta = $EndPoint.split("/")[2]+$badPayload
					
					$default = '{"status":"'+$state+'","desc":"'+$meta+'"}' | ConvertFrom-Json
					$message = $default | ConvertTo-Json -Depth 10
					$response.ContentType = 'application/json'
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
                        try {		
							$EndPoint = "http://168.**.32.202:10001/check_all"
							$res = Invoke-RestMethod -Uri $EndPoint -Method "GET"
							Write-Output $res | ConvertTo-Json
						}	
						catch {
							Write-Output $Error[0]
						}
						if(![uint32]$res.code){$state = $goodStatus} else {$state = $badStatus}
						# description composed
						$info = $res.status | ConvertTo-Json -Depth 10
						$meta = '{"IP":"'+$EndPoint.split("/")[2]+'","info":'+$info+'}' | ConvertTo-Json -Depth 10
						$default = '{"status":"'+$state+'","desc":'+$meta+'}' | ConvertFrom-Json
						$message = $default | ConvertTo-Json -Depth 10
						$response.ContentType = 'application/json'
						Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) From $RemoteAddr POST Prepared response:$message" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
                    }
                }
				$counter++
				Write-Output $counter
				Out-File -Append -InputObject $counter $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
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

# 2023-12-04
# Author@CWayneH
