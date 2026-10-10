param(
    [ValidateSet('1440p','4K','900p','Both')][string]$Resolution='Both',
    [ValidateRange(1,3)][int]$Passes=1,
    [ValidateSet('safe','separate')][string]$RenderThread='safe',
    [string]$Executable='',
    [string]$ProjectPath='',
    [switch]$Quick,
    [switch]$CrowdedOnly,
    [switch]$SkipHardware,
    [ValidateSet('','inventory','counters')][string]$Collector='',
    [string]$CollectorFolder='',
    [string]$CollectorLabel=''
)
$ErrorActionPreference='Stop'
Write-Host 'Train Game benchmark - launcher 2'

# Isolate optional Windows/driver calls from the launcher and its game watchdog.
# A provider can ignore its own timeout; the parent also bounds the process.
function Write-BenchmarkStatus([string]$Message) {
    $line='['+[DateTime]::Now.ToString('HH:mm:ss')+'] '+$Message
    Write-Host $line
    if ($script:statusPath) { [IO.File]::AppendAllText($script:statusPath,$line+[Environment]::NewLine) }
}
function Stop-OwnedProcess($Process) {
    if ($Process -and !$Process.HasExited) {
        try { $Process.Kill();$null=$Process.WaitForExit(1000) } catch { Write-Host ('Could not stop helper: '+$_.Exception.Message) }
    }
}
function Invoke-BoundedProcess([string]$FilePath,[string[]]$Arguments,[string]$OutputPath,[string]$ErrorPath,[int]$TimeoutSeconds=25,[switch]$ShowProgress) {
    $child=$null;$shown=0;$completed=$false
    $timer=[Diagnostics.Stopwatch]::StartNew()
    try {
        $child=Start-Process -FilePath $FilePath -ArgumentList $Arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $OutputPath -RedirectStandardError $ErrorPath
        # Retain the native handle before HasExited can close its temporary one.
        # Windows PowerShell otherwise sometimes exposes a null ExitCode.
        $null=$child.Handle
        while (!$child.HasExited -and $timer.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
            if ($ShowProgress -and (Test-Path -LiteralPath $OutputPath)) {
                $lines=@(Get-Content -LiteralPath $OutputPath)
                while ($shown -lt $lines.Count) { Write-BenchmarkStatus $lines[$shown];$shown++ }
            }
            Start-Sleep -Milliseconds 200
        }
        $completed=$child.HasExited
        if ($completed) { $null=$child.WaitForExit(1000) }
        return [pscustomobject]@{completed=$completed;exit_code=$(if ($completed) {$child.ExitCode} else {$null});elapsed_seconds=$timer.Elapsed.TotalSeconds}
    } finally { Stop-OwnedProcess $child }
}
function Invoke-InventoryCollector {
    $data=[ordered]@{collected_utc=[DateTime]::UtcNow.ToString('o');complete=$false;errors=@()}
    $queries=[ordered]@{
        cpu={Get-CimInstance Win32_Processor -OperationTimeoutSec 5 | Select-Object Name,Manufacturer,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed}
        ram={Get-CimInstance Win32_PhysicalMemory -OperationTimeoutSec 5 | Select-Object Capacity,Speed,ConfiguredClockSpeed}
        os={Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 5 | Select-Object Caption,Version,BuildNumber,TotalVisibleMemorySize,FreePhysicalMemory}
        gpu={Get-CimInstance Win32_VideoController -OperationTimeoutSec 5 | Select-Object Name,DriverVersion,DriverDate,VideoModeDescription,CurrentRefreshRate}
        volumes={Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -OperationTimeoutSec 5 | Select-Object DeviceID,Size,FreeSpace,FileSystem}
        disks={Get-PhysicalDisk | Select-Object FriendlyName,MediaType,BusType,Size,HealthStatus}
    }
    foreach ($name in $queries.Keys) {
        # Persist the last attempted query before entering a potentially stuck provider.
        $data.current_query=$name
        $data | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $CollectorFolder 'inventory-partial.json') -Encoding utf8
        Write-Host "Checking $name..."
        try { $data[$name]=@(& $queries[$name]) }
        catch { $data.errors+=($name+': '+$_.Exception.Message) }
    }
    $data.complete=$true;$data.current_query=''
    $data | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $CollectorFolder 'inventory-partial.json') -Encoding utf8
}
function Invoke-CounterCollector {
    $counterPath=Join-Path $CollectorFolder ($CollectorLabel+'-system-counters.jsonl')
    $writer=[IO.StreamWriter]::new($counterPath,$false)
    $queries=[ordered]@{
        cpu={Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -OperationTimeoutSec 3 | Select-Object Name,PercentProcessorTime,PercentProcessorUtility,ProcessorFrequency,PercentofMaximumFrequency}
        memory={Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -OperationTimeoutSec 3 | Select-Object AvailableMBytes,CommittedBytes,CommitLimit,PagesInputPersec,PageReadsPersec}
        disk={Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -OperationTimeoutSec 3 | Select-Object Name,DiskReadBytesPersec,DiskWriteBytesPersec,CurrentDiskQueueLength}
        disk_raw={Get-CimInstance Win32_PerfRawData_PerfDisk_PhysicalDisk -OperationTimeoutSec 3 | Select-Object Name,AvgDisksecPerRead,AvgDisksecPerRead_Base,AvgDisksecPerWrite,AvgDisksecPerWrite_Base,Timestamp_PerfTime,Frequency_PerfTime}
    }
    $disabled=@{}
    try {
        while ($disabled.Count -lt $queries.Count) {
            foreach ($name in $queries.Keys) {
                if ($disabled[$name]) { continue }
                $sample=[ordered]@{utc=[DateTime]::UtcNow.ToString('o');unix_ms=([DateTimeOffset]::UtcNow).ToUnixTimeMilliseconds();run=$CollectorLabel;counter=$name}
                try { $sample.data=@(& $queries[$name]) }
                catch { $sample.error=$_.Exception.Message;$disabled[$name]=$true }
                $writer.WriteLine(($sample | ConvertTo-Json -Depth 6 -Compress));$writer.Flush()
            }
            Start-Sleep -Milliseconds 900
        }
    } finally { $writer.Dispose() }
}
if ($Collector) {
    if (!(Test-Path -LiteralPath $CollectorFolder -PathType Container)) { throw 'Collector output folder is missing.' }
    if ($Collector -eq 'inventory') { Invoke-InventoryCollector } else { Invoke-CounterCollector }
    exit 0
}

Write-BenchmarkStatus 'Starting. Optional hardware checks have time limits; the game will open automatically.'
if (!$Executable) { $Executable=[IO.Path]::Combine($PSScriptRoot,'TrainGame.exe') }
if (!(Test-Path -LiteralPath $Executable)) { throw 'Place this script beside TrainGame.exe, or pass -Executable with its path.' }
$Executable=(Resolve-Path -LiteralPath $Executable).Path
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$folder=Join-Path ([Environment]::GetFolderPath('MyDocuments')) "TrainGame-Benchmark-$stamp"
New-Item -ItemType Directory -Path $folder | Out-Null
$script:statusPath=Join-Path $folder 'launcher.log'
Write-BenchmarkStatus "Reports: $folder"
$workerShell=Join-Path $env:WINDIR 'System32/WindowsPowerShell/v1.0/powershell.exe'
$workerArguments=@('-NoLogo','-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$PSCommandPath+'"'),'-CollectorFolder',('"'+$folder+'"'))
$warnings=[Collections.Generic.List[string]]::new()
$samples=[Collections.Generic.List[object]]::new()
$results=[Collections.Generic.List[object]]::new()
$sizes=@{'1440p'='2560x1440';'4K'='3840x2160';'900p'='1600x900'}
$resolutions=if ($Resolution -eq 'Both') {@('1440p','4K')} else {@($Resolution)}
$gpuMonitor=$null
$gameProcess=$null
$counterProcess=$null
$systemWriter=$null
$allPassed=$true

function Read-Inventory {
    $inventory=[ordered]@{
        collected_utc=[DateTime]::UtcNow.ToString('o')
        logical_cpus=[Environment]::ProcessorCount
        launcher_version=2
        resolutions=$resolutions
        passes=$Passes
        render_thread=$RenderThread
        quick_validation=[bool]$Quick
        crowded_only=[bool]$CrowdedOnly
        telemetry_interval_seconds=1
        cpu_temperature='Unavailable through standard Windows counters; not estimated.'
    }
    if (!$SkipHardware) {
        Write-BenchmarkStatus 'Collecting hardware details (25-second limit)...'
        try {
            $probe=Invoke-BoundedProcess $workerShell ($workerArguments+@('-Collector','inventory')) (Join-Path $folder 'inventory-worker.log') (Join-Path $folder 'inventory-errors.log') 25 -ShowProgress
            $inventory.collector=$probe
            if (!$probe.completed -or $probe.exit_code -ne 0) {
                $warnings.Add('Hardware inventory did not finish; partial details retained. See inventory-worker.log.')
                Write-BenchmarkStatus 'Hardware check timed out or failed. Continuing with partial details.'
            }
        } catch { $warnings.Add('Hardware inventory unavailable: '+$_.Exception.Message) }
        $partial=Join-Path $folder 'inventory-partial.json'
        if (Test-Path -LiteralPath $partial) {
            try {
                $collected=Get-Content -LiteralPath $partial -Raw | ConvertFrom-Json
                foreach ($property in $collected.PSObject.Properties) { $inventory[$property.Name]=$property.Value }
                foreach ($issue in $collected.errors) { $warnings.Add('Hardware inventory: '+$issue) }
            } catch { $warnings.Add('Could not read partial inventory: '+$_.Exception.Message) }
        }
        Write-BenchmarkStatus 'Checking active power plan (5-second limit)...'
        try {
            $powerOutput=Join-Path $folder 'power-plan.txt'
            $powerProbe=Invoke-BoundedProcess (Join-Path $env:WINDIR 'System32/powercfg.exe') @('/getactivescheme') $powerOutput (Join-Path $folder 'power-plan-errors.txt') 5
            if ($powerProbe.completed -and $powerProbe.exit_code -eq 0) { $inventory.power_plan=[IO.File]::ReadAllText($powerOutput).Trim() }
            else { $warnings.Add('Active power plan unavailable; see power-plan-errors.txt.') }
        } catch { $warnings.Add('Active power plan unavailable: '+$_.Exception.Message) }
    } else { $warnings.Add('Optional hardware collection skipped by request.') }
    $build=Join-Path (Split-Path $Executable -Parent) 'BUILD.txt'
    # Get-Content strings carry PSDrive/PSProvider metadata in Windows PowerShell.
    # Deep JSON serialization can walk that object graph and appear to hang.
    # Read plain strings so packaged BUILD/SHA256 metadata stays plain JSON.
    if (Test-Path -LiteralPath $build) { $inventory.build=[IO.File]::ReadAllLines($build) }
    $hashes=Join-Path (Split-Path $Executable -Parent) 'SHA256SUMS.txt'
    if (Test-Path -LiteralPath $hashes) { $inventory.build_hashes=[IO.File]::ReadAllLines($hashes) }
    $inventory | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $folder 'hardware.json') -Encoding utf8
}

try {
    Read-Inventory
    try {
    Write-BenchmarkStatus 'Checking optional NVIDIA telemetry (5-second limit per probe)...'
    $smi=Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
    $smiPath=if ($smi) {$smi.Source} else {Join-Path $env:WINDIR 'System32/nvidia-smi.exe'}
    if (!$SkipHardware -and (Test-Path -LiteralPath $smiPath)) {
        $fields='timestamp,index,name,driver_version,pstate,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.used,memory.free,clocks.current.graphics,clocks.current.memory,power.draw,power.limit,clocks_event_reasons.active'
        $probe=Invoke-BoundedProcess $smiPath @("--query-gpu=$fields",'--format=csv') (Join-Path $folder 'gpu-probe.csv') (Join-Path $folder 'gpu-probe-errors.txt') 5
        if (!$probe.completed -or $probe.exit_code -ne 0) {
            $warnings.Add('Extended NVIDIA fields unsupported; basic GPU telemetry used.')
            $fields='timestamp,index,name,driver_version,temperature.gpu,utilization.gpu,memory.total,memory.used,clocks.current.graphics,power.draw'
            $probe=Invoke-BoundedProcess $smiPath @("--query-gpu=$fields",'--format=csv') (Join-Path $folder 'gpu-basic-probe.csv') (Join-Path $folder 'gpu-basic-probe-errors.txt') 5
        }
        if ($probe.completed -and $probe.exit_code -eq 0) {
            $gpuMonitor=Start-Process -FilePath $smiPath -ArgumentList @("--query-gpu=$fields",'--format=csv','--loop=1') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $folder 'gpu-telemetry.csv') -RedirectStandardError (Join-Path $folder 'gpu-telemetry-errors.txt')
        } else { $warnings.Add('NVIDIA telemetry could not start. Engine GPU timing/memory still recorded.') }
    } else { $warnings.Add('nvidia-smi unavailable. Engine GPU timing/memory still recorded.') }
    } catch { $warnings.Add('Optional NVIDIA telemetry unavailable: '+$_.Exception.Message) }
    $systemWriter=[IO.StreamWriter]::new((Join-Path $folder 'system-telemetry.jsonl'),$false)
    $logical=[math]::Max(1,[Environment]::ProcessorCount)
    foreach ($pass in 1..$Passes) {
        foreach ($resolutionName in $resolutions) {
            $label="$resolutionName-$RenderThread-pass$pass"
            $output=Join-Path $folder "$label.json"
            $log=Join-Path $folder "$label-engine.log"
            $arguments=@('--windowed','--resolution',$sizes[$resolutionName],'--render-thread',$RenderThread,'--log-file',('"'+$log+'"'))
            if ($ProjectPath) {
                $resolvedProject=(Resolve-Path -LiteralPath $ProjectPath).Path
                $arguments+=@('--path',('"'+$resolvedProject+'"'))
            }
            $arguments+=@('--','--benchmark',('"--benchmark-output='+$output.Replace('\','/')+'"'))
            if ($Quick) { $arguments+='--benchmark-quick' }
            if ($CrowdedOnly) { $arguments+='--benchmark-traffic-only' }
            Write-BenchmarkStatus "Running $label. Leave the game focused; it controls the cameras and exits automatically."
            # This is the visible game under test. Helpers remain hidden; keeping
            # the game foreground avoids driver background-app FPS limits.
            $gameProcess=Start-Process -FilePath $Executable -ArgumentList $arguments -PassThru -WindowStyle Normal
            $started=[DateTime]::UtcNow
            $lastTime=$started
            $lastCpu=0.0
            $lastProgress=$started
            if (!$SkipHardware) {
                try {
                    $counterProcess=Start-Process -FilePath $workerShell -ArgumentList ($workerArguments+@('-Collector','counters','-CollectorLabel',$label)) -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $folder "$label-counters.log") -RedirectStandardError (Join-Path $folder "$label-counter-errors.log")
                } catch { $warnings.Add('Windows counter helper unavailable: '+$_.Exception.Message) }
            }
            while (!$gameProcess.HasExited) {
                $now=[DateTime]::UtcNow
                $gameProcess.Refresh()
                if ($gameProcess.HasExited) { break }
                $cpuSeconds=$gameProcess.TotalProcessorTime.TotalSeconds
                $elapsed=[math]::Max(.001,($now-$lastTime).TotalSeconds)
                $coresUsed=[math]::Max(0.0,($cpuSeconds-$lastCpu)/$elapsed)
                $sample=[ordered]@{
                    utc=$now.ToString('o');unix_ms=([DateTimeOffset]$now).ToUnixTimeMilliseconds();run=$label
                    process_id=$gameProcess.Id;cpu_seconds=$cpuSeconds;cpu_cores_used=$coresUsed;cpu_percent_machine=100*$coresUsed/$logical
                    working_set_bytes=$gameProcess.WorkingSet64;private_bytes=$gameProcess.PrivateMemorySize64
                    peak_working_set_bytes=$gameProcess.PeakWorkingSet64;threads=$gameProcess.Threads.Count;handles=$gameProcess.HandleCount
                }
                if ($counterProcess) {
                    $counterFile=Join-Path $folder "$label-system-counters.jsonl"
                    $lastCounter=if (Test-Path -LiteralPath $counterFile) {(Get-Item -LiteralPath $counterFile).LastWriteTimeUtc} else {$started}
                    if ($counterProcess.HasExited -or ($now-$lastCounter).TotalSeconds -gt 20) {
                        Stop-OwnedProcess $counterProcess;$counterProcess=$null
                        $warnings.Add("$label Windows counters stopped or stalled; partial counters retained, game/process/GPU capture continues.")
                        Write-BenchmarkStatus 'Windows counters unavailable. Continuing the benchmark.'
                    }
                }
                $systemWriter.WriteLine(($sample | ConvertTo-Json -Depth 6 -Compress))
                $systemWriter.Flush()
                $lastTime=$now;$lastCpu=$cpuSeconds
                if (($now-$lastProgress).TotalSeconds -ge 15) {
                    Write-BenchmarkStatus ("$label running: {0:N0} seconds. Leave the game focused." -f ($now-$started).TotalSeconds)
                    $lastProgress=$now
                }
                if (($now-$started).TotalMinutes -gt 30) {
                    Stop-Process -Id $gameProcess.Id -ErrorAction SilentlyContinue
                    $warnings.Add("$label exceeded the 30-minute limit; partial data retained.")
                    $allPassed=$false
                    break
                }
                Start-Sleep -Milliseconds 900
            }
            $gameProcess.WaitForExit()
            $exitCode=$gameProcess.ExitCode
            $gameProcess=$null
            Stop-OwnedProcess $counterProcess;$counterProcess=$null
            $counterFile=Join-Path $folder "$label-system-counters.jsonl"
            if (Test-Path -LiteralPath $counterFile) {
                foreach ($entry in @(Select-String -LiteralPath $counterFile -Pattern '"error":')) {
                    try { $failure=$entry.Line | ConvertFrom-Json;$warnings.Add("$label $($failure.counter) counters unavailable: $($failure.error)") } catch { }
                }
            }
            Write-BenchmarkStatus "$label finished. Reading results..."
            if (Test-Path -LiteralPath $output) {
                $result=Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
                $results.Add([pscustomobject]@{run=$label;exit_code=$exitCode;report=$result})
                if (!$result.complete) { $allPassed=$false;$warnings.Add("$label did not complete all stages.") }
                $unfocused=($result.cases | Measure-Object -Property unfocused_frames -Sum).Sum
                if ($unfocused -gt 0) { $warnings.Add("$label contains $unfocused unfocused frames; driver background limits may affect those samples.") }
                $expected=$sizes[$resolutionName].Split('x')
                if ($result.resolution[0] -ne [int]$expected[0] -or $result.resolution[1] -ne [int]$expected[1]) {
                    $warnings.Add("$label ran at a different window size. Use the actual resolution recorded in its report.")
                }
            } else { $allPassed=$false;$warnings.Add("$label did not write its report. Inspect the engine log.") }
            if ($exitCode -ne 0) { $allPassed=$false;$warnings.Add("$label exited with code $exitCode.") }
            if (Test-Path -LiteralPath $log) {
                $errors=Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|SHADER ERROR:|^ERROR:'
                if ($errors) { $allPassed=$false;$warnings.Add("$label reported engine errors; see its log.") }
            }
        }
    }
} catch {
    $allPassed=$false
    $warnings.Add($_.Exception.Message)
    Write-BenchmarkStatus ('Benchmark error: '+$_.Exception.Message)
} finally {
    Stop-OwnedProcess $gameProcess
    Stop-OwnedProcess $gpuMonitor
    Stop-OwnedProcess $counterProcess
    if ($systemWriter) { $systemWriter.Dispose() }
    $summary=[Collections.Generic.List[string]]::new()
    $summary.Add("Train Game benchmark - $stamp")
    $summary.Add("All runs completed without detected errors: $allPassed")
    $summary.Add('Frame percentiles are milliseconds; lower is better. 60 FPS = 16.67 ms; 120 FPS = 8.33 ms.')
    $summary.Add('NVIDIA memory is whole-GPU use. Engine GPU allocations are game-side estimates, not a VRAM residency guarantee.')
    $summary.Add('Static engine RAM is unavailable in release builds; use process working/private RAM in system-telemetry.jsonl.')
    $summary.Add('No CPU temperature sensor is installed by this script. N/A GPU fields are unavailable, not zero.')
    foreach ($entry in $results) {
        $summary.Add("")
        $summary.Add($entry.run+' - '+$entry.report.adapter)
        foreach ($case in $entry.report.cases) {
            $m=$case.metrics
            $summary.Add(('{0,-25} median {1,7:N2}  p95 {2,7:N2}  p99 {3,7:N2}  max {4,8:N2}  GPU {5,7:N2}  VRAM peak {6:N2} GiB  loading {7}' -f $case.view,$m.frame_ms.median,$m.frame_ms.p95,$m.frame_ms.p99,$m.frame_ms.maximum,$m.gpu_ms.median,($m.gpu_bytes.maximum/1GB),$case.loading_frames))
        }
    }
    if ($warnings.Count) { $summary.Add("");$summary.Add('Warnings:');foreach ($warning in $warnings) {$summary.Add($warning)} }
    $summary | Set-Content -LiteralPath (Join-Path $folder 'SUMMARY.txt') -Encoding utf8
    $warnings | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $folder 'warnings.json') -Encoding utf8
    $archive=$folder+'.zip'
    Write-BenchmarkStatus 'Packing the report ZIP...'
    Compress-Archive -LiteralPath $folder -DestinationPath $archive -CompressionLevel Optimal
    Write-Host ($summary -join [Environment]::NewLine)
    Write-Host "Send back this ZIP: $archive"
}
if (!$allPassed) { exit 1 }
