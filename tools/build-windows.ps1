param(
    [switch]$SkipTests,
    [ValidatePattern('^[A-Za-z0-9_-]+$')][string]$BuildName = 'TrainGame-Windows',
    [switch]$SkipZip,
    [switch]$FullDownloadOnly,
    [ValidateRange(0,2147483647)][int]$UpdateSequence = 0
)
$ErrorActionPreference = 'Stop'
if ($FullDownloadOnly -and $SkipZip) { throw 'A full-download-only release requires a full ZIP.' }
# Streaming .NET hashing also works in hosts where Get-FileHash autoloading is
# unavailable. The PCK can be close to 2 GB; never load it into a byte array.
function Get-PortableSha256([string]$Path) {
    $stream=[IO.File]::OpenRead($Path)
    $algorithm=[Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
    finally { $algorithm.Dispose();$stream.Dispose() }
}
$projectRoot = Split-Path $PSScriptRoot -Parent
$engine = Join-Path $projectRoot '.local/godot/Godot_v4.7.2-stable_win64_console.exe'
$template = Join-Path $projectRoot '.local/export-templates/windows_release_x86_64.exe'
if (-not (Test-Path $engine) -or -not (Test-Path $template)) {
    throw 'Install the matching Godot engine and verified Windows templates. See docs/builds.md.'
}
$buildRoot = Join-Path $projectRoot "export/$BuildName"
$archivePath = Join-Path $projectRoot "export/$BuildName.zip"
# Signed block URLs are immutable, including while another PC is downloading.
if (Test-Path -LiteralPath (Join-Path $projectRoot "export/updates/$BuildName.json")) {
    throw 'This build is published for incremental updates. Use a new BuildName and increasing UpdateSequence.'
}
if ($UpdateSequence -gt 0 -and !(Test-Path -LiteralPath (Join-Path $projectRoot '.local/update-signing-private.pem'))) {
    throw 'Restore the update signing key before publishing. See docs/incremental-updates.md.'
}
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
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'benchmark-windows.ps1') -Destination (Join-Path $buildRoot 'Benchmark.ps1')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'run-performance-benchmark.cmd') -Destination (Join-Path $buildRoot 'Run Performance Benchmark.cmd')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/assets.md') -Destination (Join-Path $buildRoot 'ASSET-SOURCES.md')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/models/ported/station-notices') -Destination $buildRoot -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/models/trackside/notices') -Destination (Join-Path $buildRoot 'guides/trackside-notices') -Recurse -Force
    foreach ($guide in @('busy-timetable.md', 'dispatcher-capacity.md', 'graphics-settings.md', 'performance.md', 'corridor-rendering-2026-10-10.md', 'crowded-benchmark-2026-10-10.md', 'save-load.md', 'passengers.md', 'depot-workings.md', 'station-model-port.md', 'station-surroundings.md', 'speed-boards.md', 'kerala-scenery.md', 'trackside-collection.md')) {
        Copy-Item -LiteralPath (Join-Path $projectRoot "docs/$guide") -Destination (Join-Path $buildRoot "guides/$guide")
    }
    Copy-Item -LiteralPath (Join-Path $projectRoot 'art/performance/timetable-2026-10-10') -Destination (Join-Path $buildRoot 'guides/timetable-evidence') -Recurse -Force
    $timetableGuide = Join-Path $buildRoot 'guides/busy-timetable.md'
    [IO.File]::WriteAllText($timetableGuide, [IO.File]::ReadAllText($timetableGuide).Replace('../art/performance/timetable-2026-10-10/', 'timetable-evidence/'))
    Copy-Item -LiteralPath (Join-Path $projectRoot 'art/performance/timetable-through-2026-10-10') -Destination (Join-Path $buildRoot 'guides/timetable-through-evidence') -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $projectRoot 'art/timetables') -Destination (Join-Path $buildRoot 'guides/timetables') -Recurse -Force
    [IO.File]::WriteAllText($timetableGuide, [IO.File]::ReadAllText($timetableGuide).Replace('../art/performance/timetable-through-2026-10-10/', 'timetable-through-evidence/').Replace('../art/timetables/', 'timetables/'))
    Copy-Item -LiteralPath (Join-Path $projectRoot 'art/performance/crowded-2026-10-10') -Destination (Join-Path $buildRoot 'guides/crowded-benchmark-evidence') -Recurse -Force
    $crowdedGuide = Join-Path $buildRoot 'guides/crowded-benchmark-2026-10-10.md'
    [IO.File]::WriteAllText($crowdedGuide, [IO.File]::ReadAllText($crowdedGuide).Replace('../art/performance/crowded-2026-10-10/', 'crowded-benchmark-evidence/'))
    Copy-Item -LiteralPath (Join-Path $projectRoot 'art/performance/corridor-2026-10-10') -Destination (Join-Path $buildRoot 'guides/corridor-rendering-evidence') -Recurse -Force
    $corridorGuide = Join-Path $buildRoot 'guides/corridor-rendering-2026-10-10.md'
    [IO.File]::WriteAllText($corridorGuide, [IO.File]::ReadAllText($corridorGuide).Replace('../art/performance/corridor-2026-10-10/', 'corridor-rendering-evidence/'))
    Copy-Item -LiteralPath (Join-Path $projectRoot 'data/routes/kerala_coast/README.md') -Destination (Join-Path $buildRoot 'MAP-DATA-LICENSE.md')
    Copy-Item -LiteralPath (Join-Path $projectRoot 'art/scenery/coastal-fidelity') -Destination (Join-Path $buildRoot 'guides') -Recurse -Force
    Copy-Item -LiteralPath (Join-Path $projectRoot 'art/scenery/kerala-variety') -Destination (Join-Path $buildRoot 'guides') -Recurse -Force
    foreach ($guide in @('kerala-coast.md', 'kerala-station-audit.md', 'kerala-station-browser-audit.md', 'dispatcher-overhaul.md', 'ride-dynamics.md', 'rakes.md', 'coach-detail.md', 'walking.md', 'controllers.md', 'dispatching.md', 'timetables.md', 'services.md', 'lhb.md', 'wap7.md', 'wap7-detail.md', 'stations.md', 'visual-fidelity.md', 'imported-fleet.md', 'track.md', 'body-v2-audio.md', 'enhanced-audio.md')) {
        Copy-Item -LiteralPath (Join-Path $projectRoot "docs/$guide") -Destination (Join-Path $buildRoot "guides/$guide")
    }
    $revision = & git -c safe.directory=D:/ClaudeWS/train-game rev-parse --short HEAD
    $dirty = & git -c safe.directory=D:/ClaudeWS/train-game status --porcelain --untracked-files=no
    @("Build: $BuildName", "Built: $(Get-Date -Format o)", "Godot: 4.7.2 stable; Windows x86-64 release", "Source base: $revision", "Uncommitted tracked changes included: $([bool]$dirty)") |
        Set-Content -LiteralPath (Join-Path $buildRoot 'BUILD.txt') -Encoding utf8
    $hashes = foreach ($name in @('TrainGame.exe', 'TrainGame.pck')) {
        $file = Join-Path $buildRoot $name
        if (-not (Test-Path $file)) { throw "Missing build file: $file" }
        "$(Get-PortableSha256 $file)  $name"
    }
    $hashes | Set-Content -LiteralPath (Join-Path $buildRoot 'SHA256SUMS.txt') -Encoding ascii
    if ($UpdateSequence -gt 0 -or $FullDownloadOnly) {
        & (Join-Path $PSScriptRoot 'updater/build-launcher.ps1')
        foreach ($launcherFile in @('Update and Play.exe', 'UPDATER-README.txt')) {
            Copy-Item -LiteralPath (Join-Path $projectRoot "export/updater/$launcherFile") -Destination (Join-Path $buildRoot $launcherFile) -Force
        }
    }
    if (!$SkipZip) {
        Compress-Archive -LiteralPath $buildRoot -DestinationPath $archivePath -CompressionLevel Optimal -Force
        "$(Get-PortableSha256 $archivePath)  $BuildName.zip" |
            Set-Content -LiteralPath ($archivePath + '.sha256') -Encoding ascii
        Get-Item $archivePath | Select-Object FullName, Length
    }
    if ($UpdateSequence -gt 0) {
        & node.exe (Join-Path $PSScriptRoot 'updater/publish.mjs') "--build=$BuildName" "--sequence=$UpdateSequence"
        if ($LASTEXITCODE -ne 0) { throw 'Incremental publication failed; previous release remains available.' }
    }
    # Publish the download choice last, after all advertised files are complete.
    $releasePolicy = Join-Path $projectRoot 'export/download-release.json'
    $policyJson = @{format=1;build=$BuildName;incremental=($UpdateSequence -gt 0 -and !$FullDownloadOnly)} | ConvertTo-Json
    [IO.File]::WriteAllText(($releasePolicy + '.tmp'), $policyJson, [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath ($releasePolicy + '.tmp') -Destination $releasePolicy -Force
} finally {
    Pop-Location
}
