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
 public static void Main(string[] args) {
  for (int i=0;i+1<args.Length;i++) if(args[i]=="--log-file") File.WriteAllText(args[i+1],"Capture fixture: not the game.\n");
  Console.WriteLine("Capture fixture started.");
  if (File.Exists(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"crash.flag"))) RaiseException(0xE0421001,1,0,IntPtr.Zero);
  Console.WriteLine("Capture fixture exiting normally.");
 }
}
'@ -OutputAssembly $helper -OutputType ConsoleApplication
'fixture, not a game package' | Set-Content -LiteralPath (Join-Path $fixture 'TrainGame.pck')
$capture=Join-Path $PSScriptRoot 'diagnostics/Capture-Crash.ps1'
foreach ($mode in @('normal','crash')) {
    if ($mode -eq 'crash') { 'intentional helper exception' | Set-Content -LiteralPath (Join-Path $fixture 'crash.flag') }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $capture -Executable $helper -AcceptLicense > (Join-Path $fixture ($mode+'.log')) 2>&1
    if ($LASTEXITCODE -ne 0) { throw "$mode capture launcher failed. See $fixture" }
    $session=Get-ChildItem -LiteralPath (Join-Path $fixture 'diagnostics') -Directory -Filter 'capture-*' | Sort-Object Name | Select-Object -Last 1
    $dumps=@(Get-ChildItem -LiteralPath $session.FullName -Filter '*.dmp')
    if ($dumps.Count -ne $(if($mode -eq 'crash'){1}else{0})) { throw "$mode dump count incorrect" }
    if ((Get-Content -LiteralPath (Join-Path $session.FullName 'godot.log') -Raw) -notmatch 'Capture fixture') { throw 'Quoted log path was not passed to child' }
    if (!(Test-Path -LiteralPath ($session.FullName+'.zip'))) { throw 'Diagnostic ZIP missing' }
    if ($mode -eq 'crash') {
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
    Write-Host "PASS $mode capture, paths with spaces, log and ZIP"
}
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
