param(
    [ValidateSet('editor', 'run', 'import', 'test', 'doctor')]
    [string]$Action = 'editor'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$engine = Join-Path $projectRoot '.local/godot/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path $engine)) { throw 'Godot is missing. See docs/pc-setup.md.' }
if ($Action -eq 'doctor') {
    $nodeCommand = Get-Command node.exe -ErrorAction SilentlyContinue
    $nodePath = if ($nodeCommand) { $nodeCommand.Source } else { Join-Path $env:USERPROFILE 'Documents/Node_v24/node.exe' }
    Push-Location $projectRoot
    try { & $nodePath (Join-Path $projectRoot '.local/mcp/node_modules/godot-mcp-bridge/dist/index.js') doctor }
    finally { Pop-Location }
    exit $LASTEXITCODE
}
switch ($Action) {
    'editor' { & $engine --path $projectRoot --editor }
    'run' { & $engine --path $projectRoot }
    'import' { & $engine --headless --path $projectRoot --import }
    'test' { & $engine --headless --path $projectRoot --script res://tests/run_tests.gd }
}
exit $LASTEXITCODE
