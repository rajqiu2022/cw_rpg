$ErrorActionPreference = 'Stop'
$inventory = 'F:\Code\RPG_GAME\game\build\npc_hd_20261106_batch03_qa\source_formal_inventory.json'
& 'F:\Code\RPG_GAME\game\build\loading_20261106_system02\run_metadata_protected_ROOT_ONLY.ps1' -RunName 'run_b03_formal01' -Entry 'res://build/npc_hd_20261106_batch03_qa/formal5_fixture.gd' -SourcePathsFile $inventory -SourcePathsSHA (Get-FileHash -LiteralPath $inventory).Hash -Gpu -TimeoutSeconds 60
exit $LASTEXITCODE
