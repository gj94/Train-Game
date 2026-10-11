param([ValidateRange(1,8)][int]$Workers=4)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$engine=Join-Path $projectRoot '.local/godot/Godot_v4.7.2-stable_win64_console.exe'
$jobs=@()
$began=Get-Date
Push-Location $projectRoot
try {
    for ($index=0;$index -lt $Workers;$index++) {
        $stdout=Join-Path $projectRoot ".local/timeline-worker-$index.stdout.log"
        $stderr=Join-Path $projectRoot ".local/timeline-worker-$index.stderr.log"
        $arguments=@('--headless','--path',('"'+$projectRoot+'"'),'--script','res://tools/prepare_railway_times.gd','--',"--part=$index","--parts=$Workers")
        $process=Start-Process -FilePath $engine -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $null=$process.Handle
        $jobs+=@{Process=$process;ErrorLog=$stderr;Index=$index}
        Write-Output "Preparing independent timeline partition $index / $Workers (PID $($process.Id))"
    }
    foreach ($job in $jobs) {
        $job.Process.WaitForExit()
        if ($job.Process.ExitCode -ne 0 -or (Get-Item -LiteralPath $job.ErrorLog).Length -gt 0) { throw "Timeline partition $($job.Index) failed. See $($job.ErrorLog)" }
    }
    if ($Workers -gt 1) {
        & $engine --headless --path $projectRoot --script res://tools/merge_railway_times.gd -- $Workers
        if ($LASTEXITCODE -ne 0) { throw 'Timeline merge failed.' }
    }
    & node.exe (Join-Path $PSScriptRoot 'verify-railway-times.mjs')
    if ($LASTEXITCODE -ne 0) { throw 'Timeline verification failed.' }
    Write-Output "Timeline prepared in $([math]::Round(((Get-Date)-$began).TotalSeconds,1)) wall seconds using $Workers isolated workers."
} finally { Pop-Location }
