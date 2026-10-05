param([switch]$SkipTests)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$engine = Join-Path $projectRoot '.local/godot/Godot_v4.7.2-stable_win64_console.exe'
$template = Join-Path $projectRoot '.local/export-templates/windows_release_x86_64.exe'
if (-not (Test-Path $engine) -or -not (Test-Path $template)) {
    throw 'Install the matching Godot engine and verified Windows templates. See docs/builds.md.'
}
$buildRoot = Join-Path $projectRoot 'export/TrainGame-Windows'
$archivePath = Join-Path $projectRoot 'export/TrainGame-Windows.zip'
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildRoot 'guides') -Force | Out-Null
$exportLog = Join-Path $projectRoot '.local/windows-export.log'
Push-Location $projectRoot
try {
    if (-not $SkipTests) {
        foreach ($script in @('tests/run_tests.gd', 'tools/check_track.gd', 'tools/check_fleet_finish.gd', 'tools/check_ported_assets.gd', 'tools/check_motion_playable.gd', 'tools/check_body_v2_audio.gd', 'tools/check_qol.gd', 'tools/check_corridor_playable.gd', 'tools/check_ported_playable.gd')) {
            & $engine --headless --path $projectRoot --script "res://$script"
            if ($LASTEXITCODE -ne 0) { throw "Verification failed: $script" }
        }
    }
    & $engine --headless --path $projectRoot --export-release 'Windows Portable' (Join-Path $buildRoot 'TrainGame.exe') *> $exportLog
    if ($LASTEXITCODE -ne 0 -or (Select-String -Path $exportLog -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet)) {
        Get-Content $exportLog -Tail 60
        throw "Export failed. See $exportLog"
    }
    & $engine --headless --path $projectRoot --script res://tools/write_export_notices.gd
    if ($LASTEXITCODE -ne 0) { throw 'Writing engine notices failed.' }
    Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/portable-readme.txt') -Destination (Join-Path $buildRoot 'README.txt')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/assets.md') -Destination (Join-Path $buildRoot 'ASSET-SOURCES.md')
    foreach ($guide in @('dispatching.md', 'timetables.md', 'lhb.md', 'wap7.md', 'stations.md', 'imported-fleet.md', 'track.md', 'body-v2-audio.md')) {
        Copy-Item -LiteralPath (Join-Path $projectRoot "docs/$guide") -Destination (Join-Path $buildRoot "guides/$guide")
    }
    $revision = & git -c safe.directory=D:/ClaudeWS/train-game rev-parse --short HEAD
    $dirty = & git -c safe.directory=D:/ClaudeWS/train-game status --porcelain --untracked-files=no
    @("Built: $(Get-Date -Format o)", "Godot: 4.7.2 stable; Windows x86-64 release", "Source base: $revision", "Uncommitted tracked changes included: $([bool]$dirty)") |
        Set-Content -LiteralPath (Join-Path $buildRoot 'BUILD.txt') -Encoding utf8
    $hashes = foreach ($name in @('TrainGame.exe', 'TrainGame.pck')) {
        $file = Join-Path $buildRoot $name
        if (-not (Test-Path $file)) { throw "Missing build file: $file" }
        "$( (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLower() )  $name"
    }
    $hashes | Set-Content -LiteralPath (Join-Path $buildRoot 'SHA256SUMS.txt') -Encoding ascii
    Compress-Archive -LiteralPath $buildRoot -DestinationPath $archivePath -CompressionLevel Optimal -Force
    "$( (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLower() )  TrainGame-Windows.zip" |
        Set-Content -LiteralPath ($archivePath + '.sha256') -Encoding ascii
    Get-Item $archivePath | Select-Object FullName, Length
} finally {
    Pop-Location
}
