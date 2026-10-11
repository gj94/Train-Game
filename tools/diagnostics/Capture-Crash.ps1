param(
    [string]$Executable = (Join-Path $PSScriptRoot 'TrainGame.exe'),
    [switch]$AcceptLicense
)
$ErrorActionPreference = 'Stop'

function Assert-MicrosoftSignature([string]$Path) {
    $signature = Get-AuthenticodeSignature -LiteralPath $Path
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation(?:,|$)') {
        throw 'ProcDump signature verification failed. Nothing was launched. Delete diagnostics/tools and retry.'
    }
}

try {
    # Use this PowerShell's bundled module even if launched from PowerShell 7.
    foreach ($module in @('Microsoft.PowerShell.Security','Microsoft.PowerShell.Utility','Microsoft.PowerShell.Management','Microsoft.PowerShell.Diagnostics')) {
        Import-Module (Join-Path $PSHOME ('Modules/' + $module + '/' + $module + '.psd1')) -ErrorAction Stop
    }
    if (!(Test-Path -LiteralPath $Executable -PathType Leaf)) {
        throw 'Extract the capture files beside TrainGame.exe first, then open Capture Crash.cmd.'
    }
    $Executable = (Resolve-Path -LiteralPath $Executable).Path
    $gameFolder = Split-Path -Parent $Executable
    if (!(Test-Path -LiteralPath (Join-Path $gameFolder 'TrainGame.pck') -PathType Leaf)) {
        throw 'TrainGame.pck is missing beside the executable. Use the extracted game folder.'
    }
    $diagnostics = Join-Path $gameFolder 'diagnostics'
    $toolFolder = Join-Path $diagnostics 'tools'
    New-Item -ItemType Directory -Force -Path $toolFolder | Out-Null
    $procdump = Join-Path $toolFolder 'procdump64.exe'
    if (!(Test-Path -LiteralPath $procdump -PathType Leaf)) {
        Write-Host 'Downloading Microsoft ProcDump from download.sysinternals.com...'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $download = Join-Path $toolFolder 'Procdump.zip'
        Invoke-WebRequest 'https://download.sysinternals.com/files/Procdump.zip' -UseBasicParsing -TimeoutSec 90 -OutFile $download
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($download)
        try {
            # Extract only these exact members, never arbitrary archive paths.
            foreach ($name in @('procdump64.exe','Eula.txt')) {
                $entry = $archive.GetEntry($name)
                if (!$entry) { throw "Microsoft download is missing $name." }
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,(Join-Path $toolFolder $name),$true)
            }
        } finally { $archive.Dispose() }
    }
    Assert-MicrosoftSignature $procdump
    $session = Join-Path $diagnostics ('capture-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,6))
    New-Item -ItemType Directory -Path $session | Out-Null
    $started = Get-Date
    $metadata = [ordered]@{
        started_utc = $started.ToUniversalTime().ToString('o')
        game_exe_sha256 = (Get-FileHash -LiteralPath $Executable -Algorithm SHA256).Hash
        game_file_version = [Diagnostics.FileVersionInfo]::GetVersionInfo($Executable).FileVersion
        procdump_version = [Diagnostics.FileVersionInfo]::GetVersionInfo($procdump).FileVersion
        windows_version = [Environment]::OSVersion.VersionString
        powershell_version = $PSVersionTable.PSVersion.ToString()
        capture = 'One unhandled-exception minidump; verbose engine log; no persistent crash-debugger registration'
    }
    $metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $session 'session.json') -Encoding UTF8
    foreach ($name in @('BUILD.txt','README.txt')) {
        $source = Join-Path $gameFolder $name
        if (Test-Path -LiteralPath $source -PathType Leaf) { Copy-Item -LiteralPath $source -Destination $session }
    }
    Write-Host ''
    Write-Host 'Launching your existing game with crash capture. Play normally.'
    Write-Host 'On first use, Microsoft may show its ProcDump license agreement.'
    Write-Host 'Keep this window open until the game exits. Capture does not change your saves or graphics settings.'
    Write-Host ('Results: ' + $session)
    $arguments = @('-mm','-e','-n','1','-x',$session,$Executable,'--verbose','--log-file',(Join-Path $session 'godot.log'))
    if ($AcceptLicense) { $arguments = @('-accepteula') + $arguments }
    Push-Location -LiteralPath $gameFolder
    try {
        # Remain attached only to this newly launched process. No -i, -k or registry changes.
        # Native stderr can be normal diagnostic output on Windows PowerShell.
        $ErrorActionPreference = 'Continue'
        & $procdump @arguments 2>&1 | ForEach-Object {
            # ProcDump can emit UTF-16 while the child writes UTF-8 on the same pipe.
            # Preserve readable diagnostic text; Godot also has its own log file.
            $_.ToString().Replace([string][char]0,'')
        } | Tee-Object -FilePath (Join-Path $session 'console.txt')
        $captureExit = $LASTEXITCODE
    } finally { $ErrorActionPreference = 'Stop'; Pop-Location }
    $metadata.procdump_exit_code = $captureExit
    $metadata.finished_utc = [DateTime]::UtcNow.ToString('o')
    $metadata | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $session 'session.json') -Encoding UTF8
    # Best-effort, only this executable's recent application crash events.
    try {
        $events = @(Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000,1001;StartTime=$started.AddSeconds(-5)} -MaxEvents 80 -ErrorAction Stop |
            Where-Object { $_.ToXml().Contains([IO.Path]::GetFileName($Executable)) } |
            ForEach-Object { $_.ToXml() })
        ('<Events>' + ($events -join [Environment]::NewLine) + '</Events>') | Set-Content -LiteralPath (Join-Path $session 'crash-events.xml') -Encoding UTF8
    } catch { 'No matching Windows crash event available: ' + $_.Exception.Message | Set-Content -LiteralPath (Join-Path $session 'events-status.txt') }
    $dumps = @(Get-ChildItem -LiteralPath $session -Filter '*.dmp' -File)
    if ($dumps.Count -eq 0) {
        Write-Host 'No crash dump was captured. A normal exit does not create a dump.'
    } else { Write-Host ('Captured ' + $dumps.Count + ' crash dump. It contains memory from this game process.') }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $bundle = $session + '.zip'
    [IO.Compression.ZipFile]::CreateFromDirectory($session,$bundle,[IO.Compression.CompressionLevel]::Fastest,$false)
    Write-Host ''
    Write-Host ('Diagnostic ZIP: ' + $bundle)
    Write-Host 'Nothing is uploaded automatically. Share this ZIP with the developer after a crash.'
    exit 0
} catch {
    Write-Host ('Capture failed: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'Your game files and saves have not been replaced. Any captured files remain in diagnostics.'
    exit 1
}
