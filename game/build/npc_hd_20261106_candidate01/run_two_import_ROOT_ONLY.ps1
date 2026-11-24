param([Parameter(Mandatory=$true)][string]$RunName)
$ErrorActionPreference='Stop'
$repo='F:\Code\RPG_GAME'
$candidate=Join-Path $repo 'game\build\npc_hd_20261106_candidate01'
$project=Join-Path $candidate 'import_project'
$evidence=Join-Path $candidate $RunName
if ($RunName -notmatch '^import[0-9]+$' -or (Test-Path -LiteralPath $evidence)) { throw 'Unique importNN evidence name required' }
$pairs=@(
 @{name='waiter_idle_down_20261106.png'; sha='0b2199b207c5b25a65b927dafe9e9d43325e8725af67372a944efdc2f2594b75'; hash='58bb655b4ed36df55fab471fb616f2f6'},
 @{name='vendor_idle_down_20261106.png'; sha='ac5b7429534b4a7b6808177c8265538127ed446f0a3e848736148123f418acc1'; hash='377d0e906e784c3df6cf6bf90bce1089'}
)
$relative='art\characters\pc_hd_20261102c'
$sourceDirectory=Join-Path $repo ('game\'+$relative)
$isolatedDirectory=Join-Path $project $relative
New-Item -ItemType Directory -Path $evidence,$isolatedDirectory -Force | Out-Null
foreach($pair in $pairs) {
 $png=Join-Path $sourceDirectory $pair.name
 if ((Get-FileHash -LiteralPath $png).Hash.ToLowerInvariant() -ne $pair.sha) { throw 'Formal PNG source changed' }
 $targetImport=$png+'.import'
 $targetCtex=Join-Path $repo ('game\.godot\imported\'+$pair.name+'-'+$pair.hash+'.ctex')
 if ((Test-Path -LiteralPath $targetImport) -or (Test-Path -LiteralPath $targetCtex)) { throw 'Target import exists; review rather than overwrite' }
 Copy-Item -LiteralPath $png -Destination (Join-Path $isolatedDirectory $pair.name)
}
$engine='F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
$engineBefore=(Get-FileHash -LiteralPath $engine).Hash
$argsList=@('--headless','--path',$project,'--editor','--import','--audio-driver','Dummy')
$importProcess=Start-Process -FilePath $engine -ArgumentList $argsList -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $evidence 'stdout.log') -RedirectStandardError (Join-Path $evidence 'stderr.log')
if (-not $importProcess.WaitForExit(60000)) { throw ('Isolated import timeout; Root inspect own PID '+$importProcess.Id) }
if ($importProcess.ExitCode -ne 0) { throw 'Isolated import failed; no formal import copies made' }
$records=@()
# All outputs are checked before any formal sidecar/cache installation.
foreach($pair in $pairs) {
 $png=Join-Path $sourceDirectory $pair.name
 if ((Get-FileHash -LiteralPath $png).Hash.ToLowerInvariant() -ne $pair.sha) { throw 'Formal PNG changed during import' }
 $import=Join-Path $isolatedDirectory ($pair.name+'.import')
 $ctexName=$pair.name+'-'+$pair.hash+'.ctex'
 $ctex=Join-Path $project ('.godot\imported\'+$ctexName)
 $text=[IO.File]::ReadAllText($import)
 if (-not $text.Contains('source_file="res://art/characters/pc_hd_20261102c/'+$pair.name+'"')) { throw 'Unexpected imported source path' }
 if (-not $text.Contains('path="res://.godot/imported/'+$ctexName+'"')) { throw 'Unexpected cache target' }
 if (-not $text.Contains('process/fix_alpha_border=false') -or -not $text.Contains('compress/mode=0') -or -not $text.Contains('process/size_limit=0')) { throw 'Lossless native pixel import parameters changed' }
 if (-not (Test-Path -LiteralPath $ctex)) { throw 'Missing isolated ctex' }
 $records+=@{source_sha=$pair.sha; import_source=$import; import_target=$png+'.import'; import_sha=(Get-FileHash -LiteralPath $import).Hash; ctex_source=$ctex; ctex_target=(Join-Path $repo ('game\.godot\imported\'+$ctexName)); ctex_sha=(Get-FileHash -LiteralPath $ctex).Hash}
}
if ((Get-FileHash -LiteralPath $engine).Hash -ne $engineBefore) { throw 'Executable changed' }
foreach($record in $records) {
 if ((Test-Path -LiteralPath $record.import_target) -or (Test-Path -LiteralPath $record.ctex_target)) { throw 'Concurrent target appeared; not overwritten' }
 Copy-Item -LiteralPath $record.import_source -Destination $record.import_target
 Copy-Item -LiteralPath $record.ctex_source -Destination $record.ctex_target
 if ((Get-FileHash -LiteralPath $record.import_target).Hash -ne $record.import_sha -or (Get-FileHash -LiteralPath $record.ctex_target).Hash -ne $record.ctex_sha) { throw 'Installed copy hash mismatch' }
}
$receipt=@{scope='EMPTY_PROJECT_TWO_PNG_IMPORT_ONLY'; pid=$importProcess.Id; exit_code=$importProcess.ExitCode; entries=$records; real_save_content_access=$false; game_editor_import=$false; other_game_imports_written=0; formal_runtime_adoption='PENDING_VISUAL_FIXTURE'}
[IO.File]::WriteAllText((Join-Path $evidence 'receipt.json'),($receipt|ConvertTo-Json -Depth 8))
$receipt|ConvertTo-Json -Depth 8
