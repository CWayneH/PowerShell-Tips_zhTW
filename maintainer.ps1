# Reference: http://hkeylocalmachine.com/?p=518
# Reference: https://tech.zsoldier.com/2018/08/powershell-making-restful-api-endpoint.html
<#
powershell.exe -file maintain.ps1 -func_port 5201 -op_rec "D:\..\Logs\" -IPs host1,host2,host3 -ports 2345,3456,5678
#>
param (
#	[String[]] $IPs, 
# 	[String[]] $ports,
 	$func_port=5200,
	$op_rec = 'D:\..\Logs\'
)
Out-File -Append -InputObject "--------------------Begin(PID:$PID, port:$func_port)--------------------" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) START" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
# Create a listener on port 80
try {
	$listener = New-Object System.Net.HttpListener
	$listener.Prefixes.Add('http://+:'+$func_port+'/') 
	$listener.Start()
} catch { 
	Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) HttpListener Fault; End Process itself." $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt' 
	Stop-Process $PID -Force
}
'Listening ...'
$counter = 0
$func_port_ini = $func_port
$func_port = $null
# Run until you send a GET request to /end
while ($true) {
    $context = $listener.GetContext()
    # Capture the details about the request
    $request = $context.Request
    $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $request.InputStream, $request.ContentEncoding
    # Setup a place to deliver a response
    $response = $context.Response
	
	# initial setup
	$goodStatus = "Good"
	$badStatus = "Bad"
	$IPs = "168.XX.OO.1","168.OO.XX.2"
	$ports = 5201,5202,5203
	$frame = "http:///check"
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
							$Error[0] = $(Get-Date -DisplayHint Time).ToString()+$_.Exception.toString().Replace("`r`n",";")
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
						# 24-02-07 apply service-url while invoke-restmethod
						$res = $EndPoints | ForEach-Object {
							$tmp = try { Invoke-RestMethod $_ } catch { 
								[PSCustomObject] @{code='99';message=$_.Exception.toString().Replace("`r`n",";");status='-'}
								$Error[0] = $(Get-Date -DisplayHint Time).ToString()+$_.Exception.toString().Replace("`r`n",";")
							};
							Add-Member -InputObject $tmp -Name 'service' -MemberType NoteProperty -Value $_;
							return $tmp;
						}
						$len = $res.Length
						# apply service url in array of status / end of mapping problem on 24-02-07
						# $res.status | Add-Member -Name 'service' -MemberType NoteProperty -Value $null
						# 0..($len-1) | ForEach-Object {$res[$PSItem].status.service = $EndPoints[$PSItem]}
						Write-Output $res | ConvertTo-Json
						$norm = $res | ?{$_.code -eq 0}
						$refinfo = [String]$norm.Count+' node(s) in good status:(list below) '+$norm.service
						# sum approach to determine if good / bad.
						$rcodeSwitch = ($res.code | Measure-Object -Sum).Sum
						if(![uint32]$rcodeSwitch){
							$state = $goodStatus
							# $refinfo = [String]($res | ?{$_.code -eq 0}).Count+' node(s) in good status:(list below)'+($res | ?{$_.code -eq 0}).service
						} else {
							$state = $badStatus
							$tmp = $res | ?{$_.code -ne 0}
							$badinfo=0..($tmp.Length-1) | ForEach-Object {'[WARN]WHILE CALLING '+$tmp[$_].service+' ENCOUNTER WITH A PROBLEM:'+$tmp[$_].message}
							# $refinfo = [String]::Join("===split line===",($res | ?{$_.code -ne 0}))
							# $refinfo_rep=$refinfo.replace('{','\{').replace('}','\}')
							$refinfo+= ';;;;; BUT YOU SHOULD PAY ATTENTION TO '+$badinfo
						}
						
						$default = '{"status":"'+$state+'","desc":"'+$refinfo+'"}' | ConvertFrom-Json
						$message = $default | ConvertTo-Json -Depth 10
						$response.ContentType = 'application/json'
						Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) From $RemoteAddr POST Prepared response:$message" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
						# 23-12-19 apply error log, 24-02-27 sealed due to vague logic for error appending.
						# if($Error) {
						#	$Error[0] = $(Get-Date -DisplayHint Time).ToString()+$_.Exception.toString().Replace("`r`n",";")
						#	$err_msg = $Error[0]
						#	Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) From $RemoteAddr POST response Error:$err_msg" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
						#}
                    }
                }
				Write-Output ProcessID:$PID
				$counter++
				Write-Output $counter
				Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) /maintainer within Current Process($PID) is counting $counter usage at present." $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
			}
			# 23-12-19 apply error log method
			"/maintainer/error" {
				if ($request.HttpMethod -eq 'GET') {
					if(!$Error) { $err_out = "No error log list here." } else { $err_out = $Error -join ";;;;;;" }
					$ecSwitch = $Error.Count
					Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) From /maintainer/error $ecSwitch usage:$err_out" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
					$Error.Clear()
				}
				$message = $err_out
				Remove-Variable -Name "err_out" -ErrorAction Ignore
			}
			# 23-12-25 apply quorum choosing approach to handle plural echo API.
			"/maintainer/quorum" {
				# SUV agent use POST method.
				if ($request.HttpMethod -eq 'POST') {
					# 24-02-29 set micro-service port in hard code.
					$prgm_path = "D:\..\maintain.ps1"
					$func_port = 5300
					$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
					$headers.Add("Content-Type", "application/json")
					$param1 = @{Uri='http://127.0.0.1:5400/../Loading';Method='POST';Headers=$headers}
					$param2 = @{Uri='http://127.0.0.1:'+$func_port+'/maintainer';Method='POST'}
					$params = @($param1, $param2)
					# 24-02-26 apply micro-service on another function port to call /maintainer service self.
					$t=$(Get-Date)
					try {
						try {
							$job = Start-Job -FilePath $prgm_path -ArgumentList $func_port
							$job_pid = ((Get-Process -Name powershell | Select-Object Id, StartTime | Sort-Object StartTime).Id -ne $PID)[-1]
						} catch { $Error[0] = $(Get-Date -DisplayHint Time).ToString()+' initial fail of micro-service(PID:'+ $job_pid +') occurred.'  }
						# 24-02-27 set check point to watch service status until listening.
						do {
							$job_sta = Receive-Job -Job $job
							$dw_ctrl = ( $job_sta -eq $null ) -and ($(Get-Date)-$t).TotalMilliseconds -lt 15000
							# Write-Output $dw_ctrl, ($(Get-Date)-$t).TotalMilliseconds
						} while ($dw_ctrl)
						# Write-Output $job_sta
						Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) $(($(Get-Date)-$t).totalseconds)secs micro-service Job Listening Time elapsed." $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
						# 24-02-23 use array to process each echo api response; so that each response need same schema:{status,desc}
						$res = @()
						foreach ($param in $params) {
							$res += try { Invoke-RestMethod -Uri $param.Uri -Method $param.Method -Headers $param.Headers } catch {
								[PSCustomObject] @{status='Y';desc=$_.Exception.toString().Replace("`r`n",";")}
								$Error[0] = $(Get-Date -DisplayHint Time).ToString()+$_.Exception.toString().Replace("`r`n",";")
							}
						}
						Write-Output $res | ConvertTo-Json
						# trace micro-service pid after /maintainer post request. sealed on 24-03-01 due to split parse error
						# $job_pid = ((Receive-Job -Job $job) -match 'ProcessID').split(":")[-1]
						# kill switch for micro-service; 24-02-29 trial for -ErrorAction Ignore for without writting record to $Error BUT it's unuseful.
						$param_job = @{Uri='http://127.0.0.1:'+$func_port+'/end';Method='GET'}
						try { Invoke-RestMethod -Uri $param_job.Uri -Method $param_job.Method } catch {
							$Error[0] = $(Get-Date -DisplayHint Time).ToString()+' /end$ call of micro-service(PID:'+ $job_pid +') occurred.' 
						}
						# 24-02-29 make sure micro-service down; Ignore instead of SilentlyContinue of ErrorAction
						if( Get-Process -Id $job_pid -ErrorAction Ignore ){ Stop-Process -Id $job_pid -Force}
						Stop-Job -Job $job
						Remove-Job -Job $job -Force
					} catch {
						$Error[0] = $(Get-Date -DisplayHint Time).ToString()+$_.Exception.toString().Replace("`r`n",";")
						$err_res = $Error[0]
						Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) Apply micro-service Job Error:$err_res" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
						Remove-Variable -Name "err_res" -ErrorAction Ignore
					}
					Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) $(($(Get-Date)-$t).totalseconds)secs Job Control Time elapsed." $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
					# Quorum uses length comparison to determine if good / bad.
					$staSwitch = $res.Length - ($res.status -match 'Good').Length
					if(![uint32]$staSwitch){
						$state = $goodStatus
						$refinfo = $res.desc
					} else {
						$state = $badStatus
						$refinfo = ($res | ?{$_.status -ne $goodStatus}).desc
					}
					$default = '{"status":"'+$state+'","desc":"'+$refinfo+'"}' | ConvertFrom-Json
					$message = $default | ConvertTo-Json -Depth 10
					$response.ContentType = 'application/json'
					Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) /maintainer/quorum Result:$message" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
					#if($Error) {
					#	$Error[0] = $(Get-Date -DisplayHint Time).ToString()+$Error[0].Exception.toString().Replace("`r`n",";")
					#	$err_msg = $Error[0]
					#	Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) Quorum From $RemoteAddr POST response Error:$err_msg" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
					#}
				}
				Write-Output ProcessID:$PID
				$counter++
				Write-Output $counter
				Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) /maintainer/quorum within Current Process($PID) is counting $counter usage at present." $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
				# 24-02-27 apply Error message clear; little gc here.
				if ($Error.Count -gt 10) {
					$err_out = $Error -join ";;;;;;"
					$ecSwitch = $Error.Count
					Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) From /maintainer/quorum error clear $ecSwitch usage:$err_out" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
					Remove-Variable -Name "err_out" -ErrorAction Ignore
					$Error.Clear()
					[System.GC]::Collect()
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
Out-File -Append -InputObject "$(Get-Date -DisplayHint Time) END" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'
Out-File -Append -InputObject "--------------------Finish(PID:$PID, port:$func_port_ini)--------------------" $op_rec'_'$(Get-Date -Format "yyyy-MM-dd")'_apilog.txt'

# version-1.0.0
# Author@CWayneH
