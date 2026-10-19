param([ValidateRange(1,8)][int]$Workers=4)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$engine=Join-Path $projectRoot '.local/godot/Godot_v4.7.2-stable_win64_console.exe'
$trafficJobs=@()
Push-Location $projectRoot
try {
    & node.exe tools/verify-service-starts.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Prepare valid departures first.' }
    & node.exe tools/verify-railway-times.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Prepare valid five-minute states first.' }
    & node.exe --test tools/test-traffic-encounters.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Encounter detector tests failed.' }
    $null=New-Item -ItemType Directory -Force -Path .local/service-traffic
    for ($index=0;$index -lt $Workers;$index++) {
        $stdout=Join-Path $projectRoot ".local/service-traffic/$index.stdout.log"
        $stderr=Join-Path $projectRoot ".local/service-traffic/$index.stderr.log"
        $arguments=@('--headless','--path',('"'+$projectRoot+'"'),'--script','res://tools/record_service_traffic.gd','--',"--part=$index","--parts=$Workers")
        $process=Start-Process -FilePath $engine -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $null=$process.Handle
        $trafficJobs+=@{Process=$process;ErrorLog=$stderr}
        Write-Output "Replaying traffic partition $index / $Workers (PID $($process.Id))"
    }
    foreach ($job in $trafficJobs) {
        $job.Process.WaitForExit()
        if ($job.Process.ExitCode -ne 0 -or (Get-Item -LiteralPath $job.ErrorLog).Length -gt 0) { throw "Traffic recording failed. See $($job.ErrorLog)" }
    }
    & node.exe tools/prepare-service-traffic.mjs $Workers
    if ($LASTEXITCODE -ne 0) { throw 'Traffic merge failed.' }
    & node.exe tools/verify-service-traffic.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Traffic verification failed.' }
} finally { Pop-Location }
