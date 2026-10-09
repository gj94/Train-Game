param([string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (!$OutputDirectory) { $OutputDirectory = Join-Path $projectRoot 'export/updater' }
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
if (!(Test-Path -LiteralPath $compiler)) { throw 'The Windows .NET Framework C# compiler is required on the build PC.' }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
& $compiler /nologo /target:winexe /optimize+ /r:System.Web.Extensions.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /r:System.Core.dll "/resource:$(Join-Path $PSScriptRoot 'public-key.xml'),public-key.xml" "/out:$(Join-Path $OutputDirectory 'Update and Play.exe')" (Join-Path $PSScriptRoot 'UpdateCore.cs') (Join-Path $PSScriptRoot 'Launcher.cs')
if ($LASTEXITCODE -ne 0) { throw 'Launcher compilation failed.' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'README.txt') -Destination (Join-Path $OutputDirectory 'UPDATER-README.txt') -Force
$archive = Join-Path $projectRoot 'export/TrainGame-Updater.zip'
Compress-Archive -LiteralPath (Join-Path $OutputDirectory 'Update and Play.exe'),(Join-Path $OutputDirectory 'UPDATER-README.txt') -DestinationPath $archive -Force
"$((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLower())  TrainGame-Updater.zip" | Set-Content -LiteralPath ($archive + '.sha256') -Encoding ascii
Get-Item -LiteralPath $archive | Select-Object Name,Length
