param([switch]$SkipTests, [ValidatePattern('^[A-Za-z0-9_-]+$')][string]$BuildName = 'TrainGame-Windows')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$engine = Join-Path $projectRoot '.local/godot/Godot_v4.7.2-stable_win64_console.exe'
$template = Join-Path $projectRoot '.local/export-templates/windows_release_x86_64.exe'
if (-not (Test-Path $engine) -or -not (Test-Path $template)) {
    throw 'Install the matching Godot engine and verified Windows templates. See docs/builds.md.'
}
$buildRoot = Join-Path $projectRoot "export/$BuildName"
$archivePath = Join-Path $projectRoot "export/$BuildName.zip"
# The download page treats the checksum as the completion marker. A rebuild
# must not advertise the old ZIP while export/compression is still in progress.
if (Test-Path -LiteralPath ($archivePath + '.sha256')) {
    Remove-Item -LiteralPath ($archivePath + '.sha256')
}
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $buildRoot 'guides') -Force | Out-Null
$exportLog = Join-Path $projectRoot '.local/windows-export.log'
Push-Location $projectRoot
try {
    if (-not $SkipTests) {
        foreach ($script in @('tests/run_tests.gd', 'tools/check_controller_playable.gd', 'tools/check_track.gd', 'tools/check_fleet_finish.gd', 'tools/check_ported_assets.gd', 'tools/check_wap7_detail.gd', 'tools/check_wap7_controls.gd', 'tools/check_motion_playable.gd', 'tools/check_body_v2_audio.gd', 'tools/check_platform_audio.gd', 'tools/check_audio_routing.gd', 'tools/check_platform_integration.gd', 'tools/check_qol.gd', 'tools/check_traffic_playable.gd', 'tools/check_corridor_playable.gd', 'tools/check_ported_playable.gd', 'tools/check_scenery_playable.gd')) {
            $checkLog = Join-Path $projectRoot ('.local/build-check-' + [IO.Path]::GetFileNameWithoutExtension($script) + '.log')
            & $engine --headless --path $projectRoot --script "res://$script" *> $checkLog
            $checkExit = $LASTEXITCODE
            Get-Content -LiteralPath $checkLog -Tail 4
            if ($checkExit -ne 0 -or (Select-String -LiteralPath $checkLog -Pattern '^(SCRIPT ERROR:|SHADER ERROR:|ERROR:|FAIL[: ])' -Quiet)) {
                throw "Verification failed: $script. See $checkLog"
            }
        }
    }
    & $engine --headless --path $projectRoot --export-release 'Windows Portable' (Join-Path $buildRoot 'TrainGame.exe') *> $exportLog
    if ($LASTEXITCODE -ne 0 -or (Select-String -Path $exportLog -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet)) {
        Get-Content $exportLog -Tail 60
        throw "Export failed. See $exportLog"
    }
    & $engine --headless --path $projectRoot --script res://tools/write_export_notices.gd -- "res://export/$BuildName/ENGINE-LICENSES.txt"
    if ($LASTEXITCODE -ne 0) { throw 'Writing engine notices failed.' }
    Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/portable-readme.txt') -Destination (Join-Path $buildRoot 'README.txt')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/assets.md') -Destination (Join-Path $buildRoot 'ASSET-SOURCES.md')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'data/routes/kerala_coast/README.md') -Destination (Join-Path $buildRoot 'MAP-DATA-LICENSE.md')
    foreach ($guide in @('kerala-coast.md', 'kerala-station-audit.md', 'dispatcher-overhaul.md', 'ride-dynamics.md', 'coach-detail.md', 'walking.md', 'controllers.md', 'dispatching.md', 'timetables.md', 'services.md', 'lhb.md', 'wap7.md', 'wap7-detail.md', 'stations.md', 'visual-fidelity.md', 'imported-fleet.md', 'track.md', 'body-v2-audio.md', 'enhanced-audio.md')) {
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
    "$( (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLower() )  $BuildName.zip" |
        Set-Content -LiteralPath ($archivePath + '.sha256') -Encoding ascii
    Get-Item $archivePath | Select-Object FullName, Length
} finally {
    Pop-Location
}
