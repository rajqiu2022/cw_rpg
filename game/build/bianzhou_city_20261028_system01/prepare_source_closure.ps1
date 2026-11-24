param()
$ErrorActionPreference='Stop'
$taskRoot='F:/Code/RPG_GAME'
$taskDir="$taskRoot/game/build/bianzhou_city_20261028_system01/source_closure01_READY"
$snapshotDir="$taskRoot/game/build/luoyang_bianzhou_router_20261028_source01"
if ((Test-Path -LiteralPath $taskDir) -or (Test-Path -LiteralPath $snapshotDir)) { throw 'Immutable output already exists; do not overwrite.' }
$utf8=[System.Text.UTF8Encoding]::new($false,$true)
function ReadUtf8([string]$path) { return $utf8.GetString([IO.File]::ReadAllBytes("$taskRoot/$path")) }
function SHA([byte[]]$bytes) { return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant() }
function RenderJson($value) { return ($value|ConvertTo-Json -Depth 100)+"`n" }
function PutArtifact([string]$path,[byte[]]$bytes) {
    $parent=[IO.Path]::GetDirectoryName($path)
    if (-not (Test-Path -LiteralPath $parent)) { [IO.Directory]::CreateDirectory($parent)|Out-Null }
    $file=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try {$file.Write($bytes,0,$bytes.Length)} finally {$file.Dispose()}
}
$routerTarget='game/scripts/autoload/scene_router.gd'
$exTarget='game/data/maps/luoyang_full_city_20261022ap/execution_successor.json'
$eiTarget='game/scripts/city/luoyang_execution_index_20261022ap.gd'
$gateTarget='game/data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'
$biTarget='game/scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
$routerBefore=ReadUtf8 $routerTarget
if (([regex]::Matches($routerBefore,"`r`n")).Count -ne 13) {throw 'Router original mixed EOL differs.'}
if (-not $routerBefore.EndsWith("`n") -or $routerBefore.EndsWith("`n`n")) {throw 'Router EOF not editor single LF.'}
$hunk=(Get-Content -LiteralPath "$taskRoot/game/build/bianzhou_city_20261028_system01/router_hunks_CANDIDATE.json" -Raw|ConvertFrom-Json).hunks[0]
if (($routerBefore.Split([string[]]@($hunk.before),[StringSplitOptions]::None).Length-1) -ne 1) {throw 'Router hunk not unique.'}
$routerAfter=$routerBefore.Replace([string]$hunk.before,[string]$hunk.after)
if ($routerAfter.Replace([string]$hunk.after,[string]$hunk.before) -cne $routerBefore) {throw 'Router full inverse failed.'}
$oldRouterSHA=SHA $utf8.GetBytes($routerBefore)
$newRouterSHA=SHA $utf8.GetBytes($routerAfter)
if ($oldRouterSHA -ne 'd25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc') {throw 'Router baseline moved.'}
$oldSnapshot='res://build/luoyang_regions_20261027d_source01/visual_finish04_BUILD/closure27/Router_READY.gd'
$newSnapshot='res://build/luoyang_bianzhou_router_20261028_source01/Router_READY.gd'
$canonicalRouter='res://scripts/autoload/scene_router.gd'
if ((SHA ([IO.File]::ReadAllBytes("$taskRoot/game/"+$oldSnapshot.Substring(6)))) -ne $oldRouterSHA) {throw 'Original snapshot differs.'}
$exBefore=ReadUtf8 $exTarget
$ex=ConvertFrom-Json -AsHashtable -InputObject $exBefore
if ($ex.owned[$canonicalRouter].current_sha256 -ne $oldRouterSHA) {throw 'EX current Router differs.'}
$oldEdges=$ex.owned[$canonicalRouter].edges.Count
$ex.owned[$canonicalRouter].current_sha256=$newRouterSHA
$ex.owned[$canonicalRouter].edges+=,[ordered]@{path=$canonicalRouter;old_sha256=$oldRouterSHA;new_sha256=$newRouterSHA;old_snapshot=$oldSnapshot;new_snapshot=$newSnapshot;whole_inverse=$true;replacements=@([ordered]@{old=$hunk.before;new=$hunk.after})}
$ex.source_sha256[$newSnapshot]=$newRouterSHA
$exAfter=RenderJson $ex
$exInverse=ConvertFrom-Json -AsHashtable -InputObject $exAfter
$exInverse.owned[$canonicalRouter].current_sha256=$oldRouterSHA
$exInverse.owned[$canonicalRouter].edges=@($exInverse.owned[$canonicalRouter].edges|Select-Object -First $oldEdges)
$exInverse.source_sha256.Remove($newSnapshot)
if ((RenderJson $exInverse) -cne (RenderJson (ConvertFrom-Json -AsHashtable -InputObject $exBefore))) {throw 'EX whole typed inverse failed.'}
$exSHA=SHA $utf8.GetBytes($exAfter)
$oldExSHA=SHA $utf8.GetBytes($exBefore)
$eiBefore=ReadUtf8 $eiTarget
if (-not $eiBefore.Contains($oldExSHA)) {throw 'Execution index old pointer differs.'}
$eiAfter=$eiBefore.Replace($oldExSHA,$exSHA)
if ($eiAfter.Replace($exSHA,$oldExSHA) -cne $eiBefore) {throw 'Execution index inverse failed.'}
$gateBefore=ReadUtf8 $gateTarget
$gate=ConvertFrom-Json -AsHashtable -InputObject $gateBefore
if ($gate.legacy_source_sha256[$canonicalRouter] -ne $oldRouterSHA) {throw 'Gate executed Router pin differs.'}
$gate.legacy_source_sha256[$canonicalRouter]=$newRouterSHA
$gateAfter=RenderJson $gate
$gateInverse=ConvertFrom-Json -AsHashtable -InputObject $gateAfter
$gateInverse.legacy_source_sha256[$canonicalRouter]=$oldRouterSHA
if ((RenderJson $gateInverse) -cne (RenderJson (ConvertFrom-Json -AsHashtable -InputObject $gateBefore))) {throw 'Gate whole typed inverse failed.'}
$oldGateSHA=SHA $utf8.GetBytes($gateBefore)
$gateSHA=SHA $utf8.GetBytes($gateAfter)
$biBefore=ReadUtf8 $biTarget
if (-not $biBefore.Contains($oldGateSHA)) {throw 'Gate B index old pointer differs.'}
$biAfter=$biBefore.Replace($oldGateSHA,$gateSHA)
if ($biAfter.Replace($gateSHA,$oldGateSHA) -cne $biBefore) {throw 'B index inverse failed.'}
$outputs=@(
    @($routerTarget,'Router_READY.gd',$routerBefore,$routerAfter),
    @($exTarget,'execution_successor_READY.json',$exBefore,$exAfter),
    @($eiTarget,'execution_index_READY.gd',$eiBefore,$eiAfter),
    @($gateTarget,'gate_bundle_manifest_READY.json',$gateBefore,$gateAfter),
    @($biTarget,'bundle_index_READY.gd',$biBefore,$biAfter)
)
$rows=@()
foreach($row in $outputs) {
    $bytes=$utf8.GetBytes([string]$row[3]);$beforeBytes=$utf8.GetBytes([string]$row[2]);$path="$taskDir/$($row[1])"
    PutArtifact $path $bytes
    $rows+=,[ordered]@{target=$row[0];candidate=$path.Replace("$taskRoot/",'');old_sha256=(SHA $beforeBytes);new_sha256=(SHA $bytes);bytes=$bytes.Length;whole_typed_or_source_inverse=$true}
}
PutArtifact "$snapshotDir/Router_READY.gd" $utf8.GetBytes($routerAfter)
$receipt=[ordered]@{status='FIVE_TARGET_READY_NOT_DEPLOYED';targets=$rows;router_original_crlf=13;router_new_crlf=([regex]::Matches($routerAfter,"`r`n")).Count;router_single_final_lf=$true;old_edges_retained=$oldEdges;new_router_edges=$oldEdges+1;other_owned_unchanged=$true;new_immutable_snapshot=$newSnapshot;source_first_only=$true;canonical_writes=0;engine_runs=0;reason='Gate actually executes B.describe exact full source dict; execution authority authenticates historical ordinary source consumers. New Region bins and pure presentation do not execute canonical Router byte pins.'}
PutArtifact "$taskDir/receipt.json" $utf8.GetBytes((RenderJson $receipt))
$receipt|ConvertTo-Json -Depth 8
