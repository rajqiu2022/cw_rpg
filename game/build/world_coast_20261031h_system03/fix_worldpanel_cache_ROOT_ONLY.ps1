[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidatePattern('^[a-f0-9]{64}$')][string]$BeforeCacheSHA,[switch]$Apply)
# Derived editor cache only; runtime sources and old candidate bytes are untouched.
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$taskRepo='F:/Code/RPG_GAME'
$taskCache=$taskRepo+'/game/.godot/global_script_class_cache.cfg'
$taskOld='res://build/world_coast_20261031h_system03/sealed_candidate/copies/game/scripts/ui/world_map_panel.gd'
$taskNew='res://scripts/ui/world_map_panel.gd'
$taskIgnores=@(
 'game/build/world_coast_20261031h_system02/prepared/.gdignore',
 'game/build/world_coast_20261031h_system02/prepared02/.gdignore',
 'game/build/world_coast_20261031h_system02/prepared03/.gdignore',
 'game/build/world_coast_20261031h_system03/sealed_candidate/.gdignore',
 'game/build/world_coast_20261031h_system03/sealed_candidate03/.gdignore'
)
function Get-BytesSHA([byte[]]$Bytes) {return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()}
function Read-Exact([string]$Path) {return [IO.File]::ReadAllBytes($Path)}
$taskReceiptBytes=Read-Exact ($taskRepo+'/game/build/world_coast_20261031h_system03/sealed_candidate03/receipt_REVIEW_ONLY.json')
if ((Get-BytesSHA $taskReceiptBytes) -cne '8e61ae93e1b11e51d983300fe64ad3dd651ff1515d972df2ff8f19ac484a43ef') {throw 'SEALED03_RECEIPT_CHANGED'}
$taskReceipt=[Text.Encoding]::UTF8.GetString($taskReceiptBytes)|ConvertFrom-Json
$taskPanelRows=@($taskReceipt.targets | Where-Object {$_.path -ceq 'game/scripts/ui/world_map_panel.gd'})
if ($taskPanelRows.Count -ne 1) {throw 'EXACT_CANONICAL_PANEL_ROW_REQUIRED'}
$taskPanelBytes=Read-Exact ($taskRepo+'/game/scripts/ui/world_map_panel.gd')
if ((Get-BytesSHA $taskPanelBytes) -cne $taskPanelRows[0].candidate_sha256 -or -not [Text.Encoding]::UTF8.GetString($taskPanelBytes).StartsWith("class_name WorldMapPanel`r`nextends Control`r`n")) {throw 'CANONICAL_ACTUAL_PANEL_CLASS_OR_PIN_DIFF'}
foreach($taskIgnore in $taskIgnores) {
 $taskIgnoreBytes=Read-Exact ($taskRepo+'/'+$taskIgnore)
 if ([Text.Encoding]::UTF8.GetString($taskIgnoreBytes).Trim() -cne '# Review-only byte archive; do not register duplicate global script classes.') {throw 'ARCHIVE_IGNORE_MISSING_OR_CHANGED'}
}
$taskBefore=Read-Exact $taskCache
if ((Get-BytesSHA $taskBefore) -cne $BeforeCacheSHA) {throw 'EDITOR_CACHE_CHANGED_BEFORE_READ_NO_WRITES'}
$taskUTF8=[Text.UTF8Encoding]::new($false)
$taskText=$taskUTF8.GetString($taskBefore)
if ((Get-BytesSHA $taskUTF8.GetBytes($taskText)) -cne $BeforeCacheSHA) {throw 'CACHE_UTF8_BYTE_ROUNDTRIP_FAILED'}
$taskBlocks=@([regex]::Matches($taskText,'(?s)\{[^{}]*"class":\s*&"WorldMapPanel"[^{}]*\}'))
if ($taskBlocks.Count -ne 1 -or -not $taskBlocks[0].Value.Contains('"path": "'+$taskOld+'"')) {throw 'EXACT_ONE_WORLD_PANEL_ARCHIVE_MAPPING_REQUIRED'}
if ([regex]::Matches($taskText,[regex]::Escape($taskOld)).Count -ne 1) {throw 'EXACT_SINGLE_OLD_PATH_REQUIRED'}
$taskOtherCoast=@([regex]::Matches($taskText,'"path":\s*"res://build/world_coast_20261031h[^"\r\n]+"'))
if ($taskOtherCoast.Count -ne 1) {throw 'UNEXPECTED_ADDITIONAL_COAST_CLASS_MAPPING_REVIEW_REQUIRED'}
$taskAfterText=$taskText.Replace($taskOld,$taskNew)
if ($taskAfterText.Replace($taskNew,$taskOld) -cne $taskText) {throw 'NONUNIQUE_INVERSE_CACHE_REPLACEMENT'}
$taskAfter=$taskUTF8.GetBytes($taskAfterText)
$taskAfterSHA=Get-BytesSHA $taskAfter
if ($Apply) {
 if ((Get-BytesSHA (Read-Exact $taskCache)) -cne $BeforeCacheSHA) {throw 'EDITOR_RACE_PRECOMMIT_NO_WRITES'}
 [IO.File]::WriteAllBytes($taskCache,$taskAfter)
 if ((Get-BytesSHA (Read-Exact $taskCache)) -cne $taskAfterSHA) {throw 'DERIVED_CACHE_POST_WRITE_DIFF_RETAINED'}
}
[ordered]@{status=($(if($Apply){'ROOT_DERIVED_SINGLE_WORLD_PANEL_CACHE_PATH_APPLIED'}else{'DRY_READONLY_EXACT_CACHE_PATH_PROPOSAL'}));before_sha256=$BeforeCacheSHA;after_sha256=$taskAfterSHA;old_path=$taskOld;new_path=$taskNew;mapping_count=1;other_class_records_changed=0;production_source_writes=0;candidate_archive_byte_writes=0;archive_ignore_files=5;engine_runs=0;process_stops=0;real_save_APIs=0}|ConvertTo-Json
