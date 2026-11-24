param([Parameter(Mandatory=$true)][string]$RunName)
$ErrorActionPreference='Stop'
$candidate='F:\Code\RPG_GAME\game\build\npc_hd_20261106_candidate01'
$plan=Get-Content -LiteralPath (Join-Path $candidate 'mipmap_import_plan.json') -Raw | ConvertFrom-Json
if ($plan.formal_copy_allowed -ne $false -or $plan.records.Count -ne 15) {throw 'Wrong candidate scope'}
$evidence=Join-Path $candidate $RunName
if ($RunName -notmatch '^mipmap_import[0-9]+$' -or (Test-Path -LiteralPath $evidence)) {throw 'Use new mipmap_importNN evidence name'}
foreach($r in $plan.records){if((Get-FileHash -LiteralPath $r.png).Hash.ToLowerInvariant() -ne $r.sha256){throw 'PNG changed'}}
New-Item -ItemType Directory -Path $evidence | Out-Null
$engine='F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
$proc=Start-Process -FilePath $engine -ArgumentList @('--headless','--path',$plan.project,'--editor','--import','--audio-driver','Dummy') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $evidence 'stdout.log') -RedirectStandardError (Join-Path $evidence 'stderr.log')
if(-not $proc.WaitForExit(60000)){throw ('Own isolated import timeout, Root inspect PID '+$proc.Id)}
if($proc.ExitCode -ne 0){throw 'Import failed; no formal copies'}
$outputs=@()
foreach($r in $plan.records){
 if((Get-FileHash -LiteralPath $r.png).Hash.ToLowerInvariant() -ne $r.sha256){throw 'PNG changed during import'}
 $text=[IO.File]::ReadAllText($r.import)
 if(-not $text.Contains('source_file="'+$r.res+'"') -or -not $text.Contains('mipmaps/generate=true') -or -not $text.Contains('process/fix_alpha_border=false') -or -not $text.Contains('compress/mode=0') -or -not $text.Contains('process/size_limit=0')){throw 'Import parameters changed'}
 $outputs+=@{res=$r.res;png_sha=$r.sha256;import_path=$r.import;import_sha=(Get-FileHash -LiteralPath $r.import).Hash;ctex_path=$r.ctex;ctex_sha=(Get-FileHash -LiteralPath $r.ctex).Hash}
}
$receipt=@{scope='CANDIDATE_ONLY_15_MIPMAP_IMPORTS';pid=$proc.Id;exit_code=$proc.ExitCode;outputs=$outputs;formal_copies=0;real_save_content_access=$false;art_accepted=$false}
[IO.File]::WriteAllText((Join-Path $evidence 'receipt.json'),($receipt|ConvertTo-Json -Depth 8))
$receipt|ConvertTo-Json -Depth 8
