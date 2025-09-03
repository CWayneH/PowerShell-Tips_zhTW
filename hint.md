# List a lot of hints should be checked

## A: Parameters
```cmd
powershell.exe -file yourshell.ps1 -a_param 5987 -b_param "D:\..\Logs\" -c_params 1,2,3
```

```powershell
param (
  $a_param=5997,
  $b_param,
  [String[]] $c_params
)
```
## B: Convert base64 coding
```powershell
function base64Cvrt([string]$payload,[int32]$ctrl){
	switch($ctrl){ 
		0 {return [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payload))}
		1 {return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($payload))}
	}
}
```

## C: HTTP Post
```powershell
$endpoint = "http://localhost:2379"
$path= "/v1/api/gateway"
$data_Key = "key"
$data_Value = "value" 
$payload = '{"key": "'+$data_Key+'", "value": "'+$data_Value+'"}'
Invoke-WebRequest -Uri "$endpoint$path" -Method POST -Body $payload # get web format.
Invoke-RestMethod -Uri "$endpoint$path" -Method POST -Body $payload # get response data.
```

## D: http+ssl for PowerShell WebServer(PSWS)
- ### self-certificate
```runas /user:administrator powershell``` or 
```Start-Process powershell -Verb runas```

```powershell
$ip_1st = (Get-NetIPAddress -AddressFamily IPv4 | Select -First 1).IPAddress # IP prepared.
$FQDN = ([System.Net.Dns]::GetHostByName(($ENV:COMPUTERNAME))).Hostname.ToLower() # FQDN prepared.
$name_dns = "localhost", $ip_1st, $($ENV:COMPUTERNAME.ToLower()), "$FQDN" # bining w/ hostname.
$CERTIFICATE = New-SelfSignedCertificate -DnsName $name_dns -CertStoreLocation CERT:\LocalMachine\My
```

- ### certificate binding
```powershell
$appid = ((Get-StartApps | Where-Object {$_.Name -like 'Windows PowerShell'}).AppID -split '\\' )[0] # find AppId what you use.
netsh http add sslcert ipport=0.0.0.0:8443 certhash=$($CERTIFICATE.Thumbprint) --% appid=$appid # bind in 8443 port for example
```

```cmd
netsh http show sslcert # check binding result.
```

- ### friewall inbound policy
```cmd
netsh advfirewall firewall add rule name="PS Webserver" dir=in action=allow protocol=TCP localport=8443
```

- ### remove firewall policy

```cmd
netsh advfirewall firewall delete rule name="PS Webserver"
```

- ### remove certificate binding
```cmd
netsh http delete sslcert ipport=0.0.0.0:8443
```

- ### revoke certificate
```powershell
Remove-Item CERT:\LocalMachine\My\$($CERTIFICATE.Thumbprint)
```

## E: try-catch
```powershell
try {
		$EndPoint = "http://localhost:2379"
		$res = Invoke-RestMethod -Uri $EndPoint -Method "GET"
		Write-Output $res | ConvertTo-Json
} catch {
		Write-Output $Error[0]
		$Error[0] = $(Get-Date -DisplayHint Time).ToString()+$_.Exception.toString().Replace("`r`n",";")
}
```
