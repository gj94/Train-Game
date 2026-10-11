$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$source=Join-Path $PSScriptRoot 'diagnostics'
$output=Join-Path $repo 'export/diagnostics'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$name='TrainGame-Crash-Capture-v3.zip'
$destination=Join-Path $output $name
if (Test-Path -LiteralPath $destination) { throw 'Capture archive already exists. Use a new version for a changed published kit.' }
$temporary=$destination+'.tmp'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive=[IO.Compression.ZipFile]::Open($temporary,[IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($name in @('Capture Crash.cmd','Attach Crash Capture.cmd','Capture-Crash.ps1','CRASH-CAPTURE-README.txt')) {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,(Join-Path $source $name),$name,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $archive.Dispose() }
Move-Item -LiteralPath $temporary -Destination $destination
$hash=(Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
($hash+'  '+[IO.Path]::GetFileName($destination)) | Set-Content -LiteralPath ($destination+'.sha256') -Encoding ascii
Get-Item -LiteralPath $destination | Select-Object Name,Length
