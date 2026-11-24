param([Parameter(Mandatory=$true)][string]$RunName)
$ErrorActionPreference='Stop'
$inventory='F:\Code\RPG_GAME\game\build\npc_hd_20261106_batch02\formal_sources.json'
& 'F:\Code\RPG_GAME\game\build\loading_20261106_system02\run_metadata_protected_ROOT_ONLY.ps1' -RunName $RunName -Entry 'res://build/npc_hd_20261106_batch02/root_formal3_fixture.gd' -SourcePathsFile $inventory -SourcePathsSHA (Get-FileHash -LiteralPath $inventory).Hash -Gpu -TimeoutSeconds 60
exit $LASTEXITCODE
