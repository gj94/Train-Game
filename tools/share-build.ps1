param(
    [ValidateSet('Start','Stop','Status','Firewall')][string]$Action = 'Start',
    [string]$BindAddress,
    [ValidateRange(1024,65535)][int]$Port = 8765
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$serverScript = Join-Path $PSScriptRoot 'serve-build.mjs'
$stateFile = Join-Path $projectRoot '.local/lan-share.json'
$nodePath = (Get-Command node.exe -ErrorAction Stop).Source
$state = $null
if (Test-Path -LiteralPath $stateFile) { $state = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json }
$running = $null
if ($state) {
    $candidate = Get-CimInstance Win32_Process -Filter "ProcessId = $($state.pid)"
    if ($candidate -and $candidate.ExecutablePath -eq $nodePath -and $candidate.CommandLine.Contains($serverScript)) { $running = $candidate }
}
if ($Action -eq 'Stop') {
    if ($running) { Stop-Process -Id $running.ProcessId; 'Download server stopped.' }
    else { 'Download server is not running.' }
    if (Test-Path -LiteralPath $stateFile) { Remove-Item -LiteralPath $stateFile }
    return
}
if ($Action -eq 'Status' -or ($Action -eq 'Start' -and $running)) {
    if ($running) { $state | Format-List }
    else { 'Download server is not running.' }
    return
}
$interfaces = @(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.IPv4Address })
if ($BindAddress) { $interfaces = @($interfaces | Where-Object { $BindAddress -in $_.IPv4Address.IPAddress }) }
if ($interfaces.Count -ne 1) { throw 'Choose a connected LAN address with -BindAddress.' }
$network = $interfaces[0]
$ip = Get-NetIPAddress -InterfaceIndex $network.InterfaceIndex -AddressFamily IPv4 | Where-Object { $_.AddressState -eq 'Preferred' -and (!$BindAddress -or $_.IPAddress -eq $BindAddress) } | Select-Object -First 1
$BindAddress = $ip.IPAddress
$profile = Get-NetConnectionProfile -InterfaceIndex $network.InterfaceIndex
if ($profile.NetworkCategory -ne 'Private') { throw 'Use a trusted Private LAN connection for this download server.' }
if ($Action -eq 'Firewall') {
    $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$admin) { throw 'The Firewall action needs an administrator PowerShell.' }
    $ruleName = 'TrainGame-LAN-Download'
    $octets = ([System.Net.IPAddress]::Parse($BindAddress)).GetAddressBytes()
    $networkOctets = for ($i = 0; $i -lt 4; $i++) {
        $bits = [Math]::Min(8, [Math]::Max(0, $ip.PrefixLength - $i * 8))
        $octets[$i] -band [int](256 - [Math]::Pow(2, 8 - $bits))
    }
    $subnet = ($networkOctets -join '.') + "/$($ip.PrefixLength)"
    $parameters = @{ Direction='Inbound'; Action='Allow'; Enabled='True'; Profile='Private'; Protocol='TCP'; LocalPort=$Port; LocalAddress=$BindAddress; RemoteAddress=$subnet; InterfaceAlias=$network.InterfaceAlias; Program=$nodePath }
    if (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue) {
        Set-NetFirewallRule -Name $ruleName @parameters | Out-Null
    } else {
        New-NetFirewallRule -Name $ruleName -DisplayName 'Train Game LAN download (local subnet only)' @parameters | Out-Null
    }
    "Firewall ready: TCP $Port on $BindAddress, Private profile, local subnet only."
    return
}
$availableBuilds = @('R23', 'R18', 'R17', 'R16', 'R15', 'R14', 'R13', 'R12', 'R11', 'R10', 'R9', 'R8', 'R7', 'R6') | Where-Object {
    $archive = Join-Path $projectRoot "export/TrainGame-Kerala-Coast-$_-Windows.zip"
    (Test-Path -LiteralPath $archive) -and (Test-Path -LiteralPath "$archive.sha256")
}
if (!$availableBuilds -and !(Test-Path -LiteralPath (Join-Path $projectRoot 'export/updates/latest.json'))) { throw 'Publish an incremental update or build a supported Windows ZIP first.' }
$serverArgs = @('"' + $serverScript + '"', "--host=$BindAddress", "--port=$Port", "--prefix=$($ip.PrefixLength)")
$child = Start-Process -FilePath $nodePath -ArgumentList $serverArgs -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $projectRoot '.local/lan-share.out.log') -RedirectStandardError (Join-Path $projectRoot '.local/lan-share.err.log')
Start-Sleep -Milliseconds 800
if ($child.HasExited) { Get-Content (Join-Path $projectRoot '.local/lan-share.err.log'); throw 'Download server failed to start.' }
$state = @{ pid=$child.Id; address=$BindAddress; port=$Port; url="http://${BindAddress}:$Port/"; started=(Get-Date -Format o) }
$state | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding utf8
$state | Format-List
