$ErrorActionPreference = 'Stop'
$taskRoot = 'F:\Code\RPG_GAME\game\build\loading_20261106_system02'
$inventory = Join-Path $taskRoot 'texture_source_inventory.json'
& (Join-Path $taskRoot 'run_metadata_protected_ROOT_ONLY.ps1') -RunName 'run02_texture_candidate' -Entry 'res://build/loading_20261106_system02/texture_batch_probe.gd' -SourcePathsFile $inventory -SourcePathsSHA (Get-FileHash -LiteralPath $inventory).Hash -TimeoutSeconds 90
exit $LASTEXITCODE
