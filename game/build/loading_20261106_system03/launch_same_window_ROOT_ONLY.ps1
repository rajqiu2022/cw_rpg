$ErrorActionPreference = 'Stop'
$taskRoot = 'F:\Code\RPG_GAME\game\build\loading_20261106_system03'
$inventory = Join-Path $taskRoot 'source_inventory.json'
& 'F:\Code\RPG_GAME\game\build\loading_20261106_system02\run_metadata_protected_ROOT_ONLY.ps1' -RunName 'run03_same_window_diagnostic' -Entry 'res://build/loading_20261106_system03/same_window_probe.gd' -SourcePathsFile $inventory -SourcePathsSHA (Get-FileHash -LiteralPath $inventory).Hash -Gpu -TimeoutSeconds 90
exit $LASTEXITCODE
