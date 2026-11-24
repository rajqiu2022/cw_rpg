param([Parameter(Mandatory=$true)][string]$RunName)
$ErrorActionPreference='Stop'
# Root executes once. This wrapper does not run import/editor or any real field.
# The established bounded runner snapshots sources and save hashes only; no
# save deserialization/restoration, and only its own returned process is owned.
$inventory='F:\Code\RPG_GAME\game\build\npc_hd_20261106_candidate01\fixture_sources.json'
$entry='res://build/npc_hd_20261106_candidate01/root_hd_lease_fixture.gd'
& 'F:\Code\RPG_GAME\scripts\qa\run_luoyang_city_only_current_protected_20261010.ps1' -RunName $RunName -Entry $entry -SourcePathsFile $inventory -SourcePathsSHA (Get-FileHash -LiteralPath $inventory).Hash -Gpu -TimeoutSeconds 60
exit $LASTEXITCODE
