$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$source=Join-Path $PSScriptRoot 'benchmark-windows.ps1'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($source,[ref]$tokens,[ref]$errors)
if ($errors) { throw $errors }
# Load just the process-boundary helpers, without launching a game.
foreach ($name in @('Write-BenchmarkStatus','Stop-OwnedProcess','Invoke-BoundedProcess')) {
    $definition=$ast.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name},$true)
    . ([scriptblock]::Create($definition.Extent.Text))
}
$folder=Join-Path $root ('.local/benchmark-helper-tests-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $folder | Out-Null
$shell=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
$hang=Join-Path $folder 'hung.ps1'
@'
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'child.pid'),[string]$PID)
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'partial.json'),'{"cpu":"retained"}')
Write-Host 'Checking synthetic blocked provider...'
Start-Sleep -Seconds 60
'@ | Set-Content -LiteralPath $hang -Encoding utf8
$timed=Invoke-BoundedProcess $shell @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$hang+'"')) (Join-Path $folder 'hung.log') (Join-Path $folder 'hung.err') 2 -ShowProgress
if ($timed.completed -or $timed.elapsed_seconds -gt 8) { throw 'Blocked helper exceeded its deadline.' }
$childId=[int](Get-Content -LiteralPath (Join-Path $folder 'child.pid'))
if (Get-Process -Id $childId -ErrorAction SilentlyContinue) { throw 'Timed-out helper is still running.' }
if ((Get-Content -LiteralPath (Join-Path $folder 'partial.json') -Raw | ConvertFrom-Json).cpu -ne 'retained') { throw 'Partial diagnostics lost.' }
'PASS blocked helper killed within deadline; partial diagnostics retained'
$done=Join-Path $folder 'done.ps1'
"Write-Host 'completed fixture';exit 0" | Set-Content -LiteralPath $done -Encoding utf8
$result=Invoke-BoundedProcess $shell @('-NoProfile','-File',('"'+$done+'"')) (Join-Path $folder 'done.log') (Join-Path $folder 'done.err') 5
if (!$result.completed -or $result.exit_code -ne 0 -or (Get-Content (Join-Path $folder 'done.log') -Raw) -notmatch 'completed fixture') { throw 'Completed helper result lost.' }
'PASS successful helper preserves output and zero exit code'
"Write-Error 'fixture failure';exit 7" | Set-Content -LiteralPath $done -Encoding utf8
$result=Invoke-BoundedProcess $shell @('-NoProfile','-File',('"'+$done+'"')) (Join-Path $folder 'failed.log') (Join-Path $folder 'failed.err') 5
if (!$result.completed -or $result.exit_code -ne 7 -or !(Get-Item (Join-Path $folder 'failed.err')).Length) { throw 'Failure result or diagnostic lost.' }
'PASS failed optional helper returns its error without hanging the caller'
try {
    $null=Invoke-BoundedProcess (Join-Path $folder 'missing.exe') @() (Join-Path $folder 'missing.log') (Join-Path $folder 'missing.err') 2
    throw 'Missing program should fail'
} catch { if ($_.Exception.Message -eq 'Missing program should fail') { throw } }
'PASS unavailable helper raises a catchable error'
$metadata=Join-Path $folder 'metadata.ps1'
@'
param([string]$Source,[string]$Destination)
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$tree=[Management.Automation.Language.Parser]::ParseFile($Source,[ref]$tokens,[ref]$errors)
foreach ($name in @('Read-Inventory','Write-BenchmarkStatus')) {
    $definition=$tree.Find({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name},$true)
    . ([scriptblock]::Create($definition.Extent.Text))
}
$folder=$Destination
$Executable=Join-Path $folder 'unused.exe'
$SkipHardware=$true;$Quick=$true;$Passes=1;$RenderThread='safe';$resolutions=@('900p')
$warnings=[Collections.Generic.List[string]]::new()
[IO.File]::WriteAllLines((Join-Path $folder 'BUILD.txt'),[string[]]@('Source base: fixture','Built: fixture'))
[IO.File]::WriteAllLines((Join-Path $folder 'SHA256SUMS.txt'),[string[]]@('fixture  TrainGame.exe','fixture  TrainGame.pck'))
Read-Inventory
$raw=[IO.File]::ReadAllText((Join-Path $folder 'hardware.json'))
$report=$raw | ConvertFrom-Json
if ($raw.Length -gt 4096 -or $raw -match 'PSDrive|PSProvider|PSPath' -or $report.build[0] -ne 'Source base: fixture' -or $report.build_hashes.Count -ne 2) { throw 'Build metadata acquired filesystem object metadata' }
'PASS packaged build metadata stays plain text in JSON'
'@ | Set-Content -LiteralPath $metadata -Encoding utf8
$result=Invoke-BoundedProcess $shell @('-NoProfile','-File',('"'+$metadata+'"'),'-Source',('"'+$source+'"'),'-Destination',('"'+$folder+'"')) (Join-Path $folder 'metadata.log') (Join-Path $folder 'metadata.err') 5
if (!$result.completed -or $result.exit_code -ne 0) { throw ('Packaged metadata serialization stalled or failed: '+[IO.File]::ReadAllText((Join-Path $folder 'metadata.err'))) }
'PASS packaged BUILD.txt and SHA256SUMS.txt serialize without hanging (5-second deadline)'
