param([Parameter(Mandatory=$true)][string]$RunName)
$ErrorActionPreference='Stop'
$inventory='F:\Code\RPG_GAME\game\build\npc_hd_20261106_candidate01\visual_mipmap_sources.json'
& 'F:\Code\RPG_GAME\scripts\qa\run_luoyang_city_only_current_protected_20261010.ps1' -RunName $RunName -Entry 'res://build/npc_hd_20261106_candidate01/root_hd_visual_fixture.gd' -SourcePathsFile $inventory -SourcePathsSHA (Get-FileHash -LiteralPath $inventory).Hash -Gpu -TimeoutSeconds 60
exit $LASTEXITCODE
