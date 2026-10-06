$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$cache = Join-Path $projectRoot '.local/scenery-reference'
New-Item -ItemType Directory -Force -Path $cache | Out-Null
$records = @()
foreach ($asset in @('aerial_asphalt_01','red_brick_plaster_patch_02','pavement_06')) {
    $filesPath = Join-Path $cache "$asset-files.json"
    $infoPath = Join-Path $cache "$asset-info.json"
    foreach ($request in @(@("https://api.polyhaven.com/files/$asset",$filesPath), @("https://api.polyhaven.com/info/$asset",$infoPath))) {
        & curl.exe --fail --location --silent --show-error $request[0] -o $request[1]
        if ($LASTEXITCODE -ne 0) { throw "Metadata download failed: $asset" }
    }
    $files = Get-Content -LiteralPath $filesPath -Raw | ConvertFrom-Json
    $info = Get-Content -LiteralPath $infoPath -Raw | ConvertFrom-Json
    $destination = Join-Path $projectRoot "assets/polyhaven/$asset"
    New-Item -ItemType Directory -Force -Path $destination | Out-Null
    foreach ($mapping in @(@('Diffuse','diff'),@('nor_gl','nor_gl'),@('Rough','rough'))) {
        $download = $files.($mapping[0]).'2k'.jpg
        if (!$download.url) { throw "Missing 2K map: $asset / $($mapping[0])" }
        $name = "${asset}_$($mapping[1])_2k.jpg"
        $target = Join-Path $destination $name
        & curl.exe --fail --location --silent --show-error $download.url -o $target
        if ($LASTEXITCODE -ne 0) { throw "Texture download failed: $name" }
        if ((Get-FileHash -LiteralPath $target -Algorithm MD5).Hash.ToLower() -ne $download.md5) { throw "Published checksum mismatch: $name" }
        $records += [ordered]@{asset=$asset; file="assets/polyhaven/$asset/$name"; source="https://polyhaven.com/a/$asset"; url=$download.url; authors=$info.authors; license='CC0-1.0'; license_url='https://polyhaven.com/license'; sha256=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLower()}
    }
    Write-Output "Verified ${asset}: 3 CC0 texture maps"
}
$records | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $projectRoot 'assets/polyhaven/scenery-provenance.json') -Encoding utf8
