$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath 'D:\ClaudeWS\train-game'
$activeReplay = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -like 'Godot*' -and $_.CommandLine -like '*--script res://tools/prepare_timetable_variant.gd*' -and $_.CommandLine -like '*--network*' })
if ($activeReplay.Count -gt 0) { throw 'A Network preparation replay is active; inspect it rather than duplicating it.' }
$activeSuite = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -like 'Godot*' -and $_.CommandLine -like '*--script res://tests/run_tests.gd*' })
if ($activeSuite.Count -gt 0) { throw 'Wait for the existing source suite.' }
$suiteLog = Get-Content -LiteralPath '.local/realism-2026-10-26/candidate33-full-tests.log' -Raw
if ($suiteLog -notmatch 'Tests: 1004 passed, 0 failed' -or (Get-Item -LiteralPath '.local/realism-2026-10-26/candidate33-full-tests.err').Length -ne 0) { throw 'Candidate33 source suite must pass before launch.' }
$guardLog = Get-Content -LiteralPath '.local/realism-2026-10-26/candidate39-authoring-guards.log' -Raw
if ($guardLog -notmatch 'Tests: 5 passed, 0 failed' -or (Get-Item -LiteralPath '.local/realism-2026-10-26/candidate39-authoring-guards.err').Length -ne 0) { throw 'Candidate39 authoring guards must pass before launch.' }
$selection = Get-Content -LiteralPath 'art/timetables/kerala-coast-network-service-selection.json' -Raw | ConvertFrom-Json
if ($selection.selected_count -ne 200 -or $selection.excluded.Count -ne 8) { throw 'Unexpected selection population.' }
$baseFolder = '.local/realism-2026-10-26/rehearsals-v39'
if (Test-Path -LiteralPath $baseFolder) { throw 'v39 outputs already exist; inspect their records.' }
$sourceRevision = (git -c safe.directory=D:/ClaudeWS/train-game rev-parse HEAD).Trim()
$sourceChanges = @(git -c safe.directory=D:/ClaudeWS/train-game diff HEAD --name-only -- sim data/routes art/timetables tools/prepare_timetable_variant.gd tools/wait_quality.gd tools/lib/wait-quality.mjs tools/record_service_traffic.gd tools/lib/traffic-encounters.mjs tools/finalize_timetable_variant.mjs tools/finalize_network_timetable.mjs tools/lib/network-population.mjs tools/verify_disturbed_timetable.mjs tools/verify-timetable-variants.mjs tools/author_network_timetable.gd tests/test_network_timetable.gd persistence/operating_days.gd)
if ($sourceChanges.Count -gt 0) { throw 'Commit tested frozen inputs before launch.' }
$jobs = @(
 @{ day='predictive-network'; pack='art/timetables/kerala-coast-network-v2.json'; options=@('--network','--snapshots') },
 @{ day='predictive-network-delayed'; pack='art/timetables/kerala-coast-network-v2.json'; options=@('--network','--delay=600','--delay-at=27000') }
)
$records = @()
foreach ($job in $jobs) {
 $outputFolder = "$baseFolder/$($job.day)"
 New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
 $options = $job.options
 if ($job.pack) { $options = @("--pack=res://$($job.pack)") + $options }
 $arguments = @('--headless','--path','D:/ClaudeWS/train-game','--script','res://tools/prepare_timetable_variant.gd','--',"--output=res://$outputFolder") + $options
 $process = Start-Process -FilePath '.local/godot/Godot_v4.7.2-stable_win64_console.exe' -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput "$outputFolder/run.log" -RedirectStandardError "$outputFolder/run.err"
 $record = [ordered]@{ day=$job.day; pid=$process.Id; started=$process.StartTime.ToString('o'); output=$outputFolder; options=$options; source_commit=$sourceRevision; status='running'; reason='Candidate39 changes only S03110:20 to11:00, M08918:10 to19:45 and M08718:50 to20:05 after both original38 failures were preserved in5facebaa. Exact selected200, all other departures and non-departure fields retained. Both actual NYY and KZT queues and full-rake samples informed the hypothesis, not guaranteed roads, gaps, escape or capacity. Both full V2 runs remain required' }
 if ($job.pack) { $record.pack_sha256 = (Get-FileHash -LiteralPath $job.pack -Algorithm SHA256).Hash.ToLowerInvariant() }
 $records += $record
 $records | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath '.local/realism-2026-10-26/rehearsal-jobs-v39.json' -Encoding utf8
 Write-Output "$($job.day): wrapper $($process.Id) -> $outputFolder"
}
