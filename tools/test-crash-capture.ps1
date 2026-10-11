# Run with Windows PowerShell 5.1. The deliberate exception is in a disposable
# helper, never Train Game. No administrator privileges or registry setup.
$ErrorActionPreference='Stop'
foreach ($module in @('Microsoft.PowerShell.Utility','Microsoft.PowerShell.Management','Microsoft.PowerShell.Security')) {
    Import-Module (Join-Path $PSHOME ('Modules/'+$module+'/'+$module+'.psd1'))
}
$repo=Split-Path -Parent $PSScriptRoot
$fixture=Join-Path $repo ('.local/capture fixture '+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
$helper=Join-Path $fixture 'TrainGame.exe'
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Runtime.InteropServices;
public class CaptureFixture {
 [DllImport("kernel32.dll")] static extern void RaiseException(uint code, uint flags, uint count, IntPtr args);
 [DllImport("kernel32.dll")] static extern bool IsDebuggerPresent();
 public static void Main(string[] args) {
  foreach(string arg in args) if(arg=="--verbose") Environment.Exit(42);
  for (int i=0;i+1<args.Length;i++) if(args[i]=="--log-file") File.WriteAllText(args[i+1],"Capture fixture: not the game.\n");
  Console.WriteLine("Capture fixture started.");
  if(Array.IndexOf(args,"--wait")>=0) {
   string root=AppDomain.CurrentDomain.BaseDirectory;
   File.WriteAllText(Path.Combine(root,"started.ready"),IsDebuggerPresent()?"debugged":"normal");
   for(int i=0;i<600;i++) {
    if(IsDebuggerPresent()) File.WriteAllText(Path.Combine(root,"attached.ready"),"attached");
    if(File.Exists(Path.Combine(root,"release.flag"))) break;
    System.Threading.Thread.Sleep(100);
   }
  }
  if (File.Exists(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"crash.flag"))) RaiseException(0xE0421001,1,0,IntPtr.Zero);
  Console.WriteLine("Capture fixture exiting normally.");
 }
}
'@ -OutputAssembly $helper -OutputType ConsoleApplication
'fixture, not a game package' | Set-Content -LiteralPath (Join-Path $fixture 'TrainGame.pck')
$capture=Join-Path $PSScriptRoot 'diagnostics/Capture-Crash.ps1'
Copy-Item -LiteralPath $capture -Destination $fixture
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'diagnostics/Capture Crash.cmd') -Destination $fixture
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'diagnostics/Attach Crash Capture.cmd') -Destination $fixture
Set-Content -LiteralPath (Join-Path $fixture 'enter.txt') -Value ''
# Exercise the shipped double-click entry point, not just the PS script with
# extra flags that users do not receive. Its final pause consumes this newline.
foreach ($mode in @('normal','crash','attach')) {
    if ($mode -eq 'crash') { 'intentional helper exception' | Set-Content -LiteralPath (Join-Path $fixture 'crash.flag') }
    $entry='Capture Crash.cmd'
    if ($mode -eq 'attach') {
        $game=Start-Process -FilePath $helper -ArgumentList '--wait' -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $fixture 'running-game.stdout') -RedirectStandardError (Join-Path $fixture 'running-game.stderr')
        $entry='Attach Crash Capture.cmd'
    }
    $child=Start-Process -FilePath $env:ComSpec -ArgumentList ('/d /c ""'+(Join-Path $fixture $entry)+'""') -WindowStyle Hidden -PassThru -RedirectStandardInput (Join-Path $fixture 'enter.txt') -RedirectStandardOutput (Join-Path $fixture ($mode+'.log')) -RedirectStandardError (Join-Path $fixture ($mode+'.stderr'))
    $null=$child.Handle
    if ($mode -eq 'attach') {
        $timer=[Diagnostics.Stopwatch]::StartNew()
        while (!(Test-Path -LiteralPath (Join-Path $fixture 'attached.ready')) -and $timer.Elapsed.TotalSeconds -lt 30 -and !$child.HasExited) { Start-Sleep -Milliseconds 100 }
        if (!(Test-Path -LiteralPath (Join-Path $fixture 'attached.ready'))) { throw 'Capture did not attach to the running helper' }
        if ((Get-Content -LiteralPath (Join-Path $fixture 'started.ready') -Raw).Trim() -ne 'normal') { throw 'Attach test must start without a debugger' }
        'Trigger the isolated helper exception now' | Set-Content -LiteralPath (Join-Path $fixture 'release.flag')
    }
    $child.WaitForExit()
    if ($child.ExitCode -ne 0) { throw "$mode CMD launcher failed. See $fixture" }
    $session=Get-ChildItem -LiteralPath (Join-Path $fixture 'diagnostics') -Directory -Filter 'capture-*' | Sort-Object Name | Select-Object -Last 1
    $dumps=@(Get-ChildItem -LiteralPath $session.FullName -Filter '*.dmp')
    if ($dumps.Count -ne $(if($mode -eq 'normal'){0}else{1})) { throw "$mode dump count incorrect" }
    if ($mode -eq 'attach') {
        $metadata=Get-Content -LiteralPath (Join-Path $session.FullName 'session.json') -Raw | ConvertFrom-Json
        if($metadata.mode -ne 'attach' -or $metadata.attached_pid -ne $game.Id) { throw 'Attached to the wrong process' }
        $null=$game.WaitForExit(5000)
        if (!$game.HasExited) { throw 'Helper has not exited' }
    } elseif ((Get-Content -LiteralPath (Join-Path $session.FullName 'godot.log') -Raw) -notmatch 'Capture fixture') { throw 'Quoted log path was not passed to child' }
    if (!(Test-Path -LiteralPath ($session.FullName+'.zip'))) { throw 'Diagnostic ZIP missing' }
    if ($mode -ne 'normal') {
        $stream=[IO.File]::OpenRead($dumps[0].FullName)
        $reader=[IO.BinaryReader]::new($stream)
        try {
            if ($reader.ReadUInt32() -ne 0x504d444d) { throw 'Invalid minidump signature' }
            $stream.Position=8; $count=$reader.ReadUInt32();$directory=$reader.ReadUInt32();$found=$false
            for($i=0;$i -lt $count;$i++) {
                $stream.Position=$directory+12*$i
                $type=$reader.ReadUInt32();$null=$reader.ReadUInt32();$rva=$reader.ReadUInt32()
                if($type -eq 6) {
                    $stream.Position=$rva+8
                    if($reader.ReadUInt32() -ne [Convert]::ToUInt32('E0421001',16)) { throw 'Wrong exception captured' }
                    $found=$true
                }
            }
            if(!$found) { throw 'Missing exception stream' }
        } finally {$reader.Dispose()}
    }
    Write-Host "PASS $mode shipped CMD capture, paths with spaces, log and ZIP"
}
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $capture -Executable $helper > (Join-Path $fixture 'missing-license.log') 2>&1
if ($LASTEXITCODE -ne 1 -or (Get-Content -LiteralPath (Join-Path $fixture 'missing-license.log') -Raw) -notmatch 'with -AcceptLicense') { throw 'Missing acceptance should fail with actionable instructions' }
Write-Host 'PASS missing licence switch gives actionable failure'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $capture -Executable $helper -AcceptLicense -Attach > (Join-Path $fixture 'no-running-game.log') 2>&1
if ($LASTEXITCODE -ne 1 -or (Get-Content -LiteralPath (Join-Path $fixture 'no-running-game.log') -Raw) -notmatch 'Exactly one game from this folder') { throw 'Attach must reject a missing game' }
Write-Host 'PASS attachment requires the exact running game'
# Refuse an unsigned substitute before launching anything.
$unsigned=Join-Path $fixture 'unsigned'
New-Item -ItemType Directory -Path (Join-Path $unsigned 'diagnostics/tools') -Force | Out-Null
Copy-Item -LiteralPath $helper -Destination (Join-Path $unsigned 'TrainGame.exe')
Copy-Item -LiteralPath (Join-Path $fixture 'TrainGame.pck') -Destination $unsigned
Copy-Item -LiteralPath $helper -Destination (Join-Path $unsigned 'diagnostics/tools/procdump64.exe')
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $capture -Executable (Join-Path $unsigned 'TrainGame.exe') -AcceptLicense > (Join-Path $fixture 'unsigned.log') 2>&1
if ($LASTEXITCODE -ne 1 -or (Get-Content -LiteralPath (Join-Path $fixture 'unsigned.log') -Raw) -notmatch 'signature verification failed') { throw 'Unsigned capture tool was not rejected' }
Write-Host 'PASS unsigned-tool rejection'
Write-Host ('Evidence: '+$fixture)
