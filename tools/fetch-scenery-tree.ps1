$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$cache = Join-Path $root '.local/polyhaven-tree'
New-Item -ItemType Directory -Path (Join-Path $cache 'textures') -Force | Out-Null
$api = Join-Path $cache 'files.json'
& curl.exe -fLsS 'https://api.polyhaven.com/files/tree_small_02' -o $api
if ($LASTEXITCODE) { throw 'Tree file catalogue download failed' }
$files = Get-Content $api -Raw | ConvertFrom-Json
$package = $files.blend.'1k'.blend
$records = @()
$downloads = @(@{ name='tree_small_02_1k.blend'; item=$package })
foreach ($entry in $package.include.PSObject.Properties) { $downloads += @{ name=$entry.Name; item=$entry.Value } }
foreach ($download in $downloads) {
    $target = Join-Path $cache $download.name
    if (-not (Test-Path -LiteralPath $target) -or (Get-FileHash -LiteralPath $target -Algorithm MD5).Hash.ToLower() -ne $download.item.md5) {
        & curl.exe -fLsS --retry 2 $download.item.url -o $target
        if ($LASTEXITCODE) { throw "Download failed: $($download.name)" }
    }
    if ((Get-FileHash -LiteralPath $target -Algorithm MD5).Hash.ToLower() -ne $download.item.md5) { throw "Hash mismatch: $($download.name)" }
    $records += @{file=$download.name;url=$download.item.url;md5=$download.item.md5;sha256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLower()}
}
$record = @{asset='Tree Small 02';author='Rico Cilliers';source='https://polyhaven.com/a/tree_small_02';license='CC0-1.0';license_url='https://polyhaven.com/license';source_files=$records}
$record | ConvertTo-Json -Depth 7 | Set-Content -Encoding utf8 (Join-Path $cache 'provenance.json')
Write-Output "Verified $($downloads.Count) CC0 source files in .local/polyhaven-tree"
