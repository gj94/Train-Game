param([Parameter(Mandatory=$true)][string]$ArchivePath,
      [Parameter(Mandatory=$true)][string]$ManifestPath)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
$manifest = [IO.File]::ReadAllText($ManifestPath) | ConvertFrom-Json
$stream = [IO.File]::OpenRead($ArchivePath)
$zip = [IO.Compression.ZipArchive]::new($stream, [IO.Compression.ZipArchiveMode]::Read)
try {
    $entries = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    foreach ($entry in $zip.Entries) {
        if ($entries.ContainsKey($entry.FullName)) { throw "Duplicate archive entry: $($entry.FullName)" }
        $entries.Add($entry.FullName, $entry)
    }
    foreach ($file in $manifest.files) {
        $name = $manifest.version + '/' + $file.path
        if (!$entries.ContainsKey($name) -or $entries[$name].Length -ne $file.size) { throw "Missing or wrong-sized ZIP entry: $name" }
        $inputStream = $entries[$name].Open()
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $hash = [BitConverter]::ToString($sha.ComputeHash($inputStream)).Replace('-','').ToLowerInvariant() }
        finally { $sha.Dispose(); $inputStream.Dispose() }
        if ($hash -ne $file.sha256) { throw "ZIP differs from the update files: $name" }
    }
    Write-Output "Full archive verified against every managed file."
} finally { $zip.Dispose(); $stream.Dispose() }
