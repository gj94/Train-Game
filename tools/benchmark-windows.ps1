param(
    [ValidateSet('1440p','4K','900p','Both')][string]$Resolution='Both',
    [ValidateRange(1,3)][int]$Passes=1,
    [ValidateSet('safe','separate')][string]$RenderThread='safe',
    [string]$Executable=(Join-Path $PSScriptRoot 'TrainGame.exe'),
    [string]$ProjectPath='',
    [switch]$Quick
)
$ErrorActionPreference='Stop'
if (!(Test-Path -LiteralPath $Executable)) { throw 'Place this script beside TrainGame.exe, or pass -Executable with its path.' }
$Executable=(Resolve-Path -LiteralPath $Executable).Path
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$folder=Join-Path ([Environment]::GetFolderPath('MyDocuments')) "TrainGame-Benchmark-$stamp"
New-Item -ItemType Directory -Path $folder | Out-Null
$warnings=[Collections.Generic.List[string]]::new()
$samples=[Collections.Generic.List[object]]::new()
$results=[Collections.Generic.List[object]]::new()
$sizes=@{'1440p'='2560x1440';'4K'='3840x2160';'900p'='1600x900'}
$resolutions=if ($Resolution -eq 'Both') {@('1440p','4K')} else {@($Resolution)}
$gpuMonitor=$null
$gameProcess=$null
$systemWriter=$null
$allPassed=$true

function Read-Inventory {
    $inventory=[ordered]@{
        collected_utc=[DateTime]::UtcNow.ToString('o')
        cpu=@(Get-CimInstance Win32_Processor | Select-Object Name,Manufacturer,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed)
        ram=@(Get-CimInstance Win32_PhysicalMemory | Select-Object Capacity,Speed,ConfiguredClockSpeed)
        os=Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,TotalVisibleMemorySize,FreePhysicalMemory
        gpu=@(Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion,DriverDate,VideoModeDescription,CurrentRefreshRate)
        volumes=@(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID,Size,FreeSpace,FileSystem)
        power_plan=(& powercfg.exe /getactivescheme | Out-String).Trim()
        resolutions=$resolutions
        passes=$Passes
        render_thread=$RenderThread
        quick_validation=[bool]$Quick
        telemetry_interval_seconds=1
        cpu_temperature='Unavailable through standard Windows counters; not estimated.'
    }
    try { $inventory.disks=@(Get-PhysicalDisk | Select-Object FriendlyName,MediaType,BusType,Size,HealthStatus) }
    catch { $warnings.Add('Physical disk details unavailable: '+$_.Exception.Message) }
    $build=Join-Path (Split-Path $Executable -Parent) 'BUILD.txt'
    if (Test-Path -LiteralPath $build) { $inventory.build=Get-Content -LiteralPath $build }
    $hashes=Join-Path (Split-Path $Executable -Parent) 'SHA256SUMS.txt'
    if (Test-Path -LiteralPath $hashes) { $inventory.build_hashes=Get-Content -LiteralPath $hashes }
    $inventory | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $folder 'hardware.json') -Encoding utf8
}

try {
    Read-Inventory
    try {
    $smi=Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
    $smiPath=if ($smi) {$smi.Source} else {Join-Path $env:WINDIR 'System32/nvidia-smi.exe'}
    if (Test-Path -LiteralPath $smiPath) {
        $fields='timestamp,index,name,driver_version,pstate,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.used,memory.free,clocks.current.graphics,clocks.current.memory,power.draw,power.limit,clocks_event_reasons.active'
        $probe=& $smiPath "--query-gpu=$fields" '--format=csv'
        if ($LASTEXITCODE -ne 0) {
            $warnings.Add('Extended NVIDIA fields unsupported; basic GPU telemetry used.')
            $fields='timestamp,index,name,driver_version,temperature.gpu,utilization.gpu,memory.total,memory.used,clocks.current.graphics,power.draw'
            $probe=& $smiPath "--query-gpu=$fields" '--format=csv'
        }
        if ($LASTEXITCODE -eq 0) {
            $probe | Set-Content -LiteralPath (Join-Path $folder 'gpu-start.csv') -Encoding utf8
            $gpuMonitor=Start-Process -FilePath $smiPath -ArgumentList @("--query-gpu=$fields",'--format=csv','--loop=1') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $folder 'gpu-telemetry.csv') -RedirectStandardError (Join-Path $folder 'gpu-telemetry-errors.txt')
        } else { $warnings.Add('NVIDIA telemetry could not start. Engine GPU timing/memory still recorded.') }
    } else { $warnings.Add('nvidia-smi unavailable. Engine GPU timing/memory still recorded.') }
    } catch { $warnings.Add('Optional NVIDIA telemetry unavailable: '+$_.Exception.Message) }
    $systemWriter=[IO.StreamWriter]::new((Join-Path $folder 'system-telemetry.jsonl'),$false)
    $logical=[int](Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
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
            Write-Host "Running $label. Leave the game focused; it controls the cameras and exits automatically."
            $gameProcess=Start-Process -FilePath $Executable -ArgumentList $arguments -PassThru -WindowStyle Hidden
            $started=[DateTime]::UtcNow
            $lastTime=$started
            $lastCpu=0.0
            $coreCounters=$true
            $memoryCounters=$true
            $diskCounters=$true
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
                if ($coreCounters) {
                    try { $sample.cpu=@(Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -ErrorAction Stop | Select-Object Name,PercentProcessorTime,PercentProcessorUtility,ProcessorFrequency,PercentofMaximumFrequency) }
                    catch { $coreCounters=$false;$warnings.Add('Per-core counters unavailable: '+$_.Exception.Message) }
                }
                if ($memoryCounters) {
                    try { $sample.memory=Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -ErrorAction Stop | Select-Object AvailableMBytes,CommittedBytes,CommitLimit,PagesInputPersec,PageReadsPersec }
                    catch { $memoryCounters=$false;$warnings.Add('System memory counters unavailable: '+$_.Exception.Message) }
                }
                if ($diskCounters) {
                    try {
                        $sample.disk=@(Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -ErrorAction Stop | Select-Object Name,DiskReadBytesPersec,DiskWriteBytesPersec,CurrentDiskQueueLength)
                        $sample.disk_raw=@(Get-CimInstance Win32_PerfRawData_PerfDisk_PhysicalDisk -ErrorAction Stop | Select-Object Name,AvgDisksecPerRead,AvgDisksecPerRead_Base,AvgDisksecPerWrite,AvgDisksecPerWrite_Base,Timestamp_PerfTime,Frequency_PerfTime)
                    }
                    catch { $diskCounters=$false;$warnings.Add('Disk counters unavailable: '+$_.Exception.Message) }
                }
                $systemWriter.WriteLine(($sample | ConvertTo-Json -Depth 6 -Compress))
                $systemWriter.Flush()
                $lastTime=$now;$lastCpu=$cpuSeconds
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
            if (Test-Path -LiteralPath $output) {
                $result=Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
                $results.Add([pscustomobject]@{run=$label;exit_code=$exitCode;report=$result})
                if (!$result.complete) { $allPassed=$false;$warnings.Add("$label did not complete all stages.") }
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
} finally {
    if ($gameProcess -and !$gameProcess.HasExited) { Stop-Process -Id $gameProcess.Id -ErrorAction SilentlyContinue }
    if ($gpuMonitor -and !$gpuMonitor.HasExited) { Stop-Process -Id $gpuMonitor.Id -ErrorAction SilentlyContinue }
    if ($systemWriter) { $systemWriter.Dispose() }
    $summary=[Collections.Generic.List[string]]::new()
    $summary.Add("Train Game benchmark - $stamp")
    $summary.Add("All runs completed without detected errors: $allPassed")
    $summary.Add('Frame percentiles are milliseconds; lower is better. 60 FPS = 16.67 ms; 120 FPS = 8.33 ms.')
    $summary.Add('NVIDIA memory is whole-GPU use. Engine GPU allocations are game-side estimates, not a VRAM residency guarantee.')
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
    Compress-Archive -LiteralPath $folder -DestinationPath $archive -CompressionLevel Optimal
    Write-Host ($summary -join [Environment]::NewLine)
    Write-Host "Send back this ZIP: $archive"
}
if (!$allPassed) { exit 1 }
