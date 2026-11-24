$ErrorActionPreference='Stop'
$GameRoot='F:\Code\RPG_GAME\game'
$InputPath=Join-Path $GameRoot 'build\luoyang_city_full_rollout_20261022ap_system01\execution_input_handoff7_PENDING.json'
$Previous=Join-Path $GameRoot 'build\luoyang_city_full_rollout_20261022ap_root01\execution_ten_ROOT_LOCKED.json'
$Locked=Join-Path $GameRoot 'build\luoyang_city_full_rollout_20261022ap_root01\execution_ten_g_successor_ROOT_LOCKED.json'
if ((Get-FileHash -LiteralPath $InputPath).Hash.ToLowerInvariant() -cne '17b6db7d849645d692b69b2b22e642bd44ae00bef757630acb40f5e543d75ad8') {throw 'Fixed h7 input'}
if ((Get-FileHash -LiteralPath $Previous).Hash.ToLowerInvariant() -cne 'ad5e9a0c9bf4902e7b76449bee9a947f86ef9bb8925446547b3a04cd715150c3') {throw 'Preserved original locked input'}
if (Test-Path -LiteralPath $Locked) {throw 'Preserve locked successor'}
$Spec=Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json -AsHashtable
$Old=Get-Content -LiteralPath $Previous -Raw | ConvertFrom-Json -AsHashtable
if ($Spec.owned.Count -ne 10 -or $Spec.authority_helper_sha256 -cne $Old.authority_helper_sha256) {throw 'Same ten/helper'}
$Changed=0
for($Index=0;$Index -lt 10;$Index++) {
    $Row=$Spec.owned[$Index];$Before=$Old.owned[$Index]
    if($Row.path -cne $Before.path -or $Row.old_sha256 -cne $Before.old_sha256) {throw 'No new canonical identity'}
    if(($Row|ConvertTo-Json -Depth 40 -Compress) -cne ($Before|ConvertTo-Json -Depth 40 -Compress)) {
        if($Row.path -cne 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd' -or $Row.new_sha256 -cne '2e305b0477c2cc0b8f48450377409f88ef38e769e7fe3f827912c81f591d15f9') {throw 'Only exact G material-threshold successor'}
        $Changed++
    }
}
if($Changed -ne 1) {throw 'Exactly one code successor'}
$Spec.status='ROOT_LOCKED_AP_EXECUTABLE_TARGETS'
$Spec.output_root='res://build/luoyang_city_full_rollout_20261022ap_system01/execution_staged_root02_g/'
$Spec.root_scope='One reviewed G hunk for immutable native threshold1900 and separate return1924, only exact Artisan material room; nine other candidates exact. No geometry replay, canonical deployment, data/media or Field approval.'
$Spec.root_predecessor_lock_sha256='ad5e9a0c9bf4902e7b76449bee9a947f86ef9bb8925446547b3a04cd715150c3'
$Spec | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Locked -Encoding utf8NoBOM
Get-FileHash -LiteralPath $Locked
