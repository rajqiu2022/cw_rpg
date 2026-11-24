param([Parameter(Mandatory=$true)][ValidateSet('Import','Verify')][string]$Phase)
$ErrorActionPreference='Stop'
$stagePath='F:\Code\RPG_GAME\game\build\major_cities_20261028_art01\import01'
$enginePath='F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
$otherGodot=Get-Process -Name 'Godot*' -ErrorAction SilentlyContinue | Where-Object {$_.Id -ne 51856}
if($otherGodot){throw 'Another Godot process exists; do not stop user process. Root must coordinate.'}
$runStamp=[DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss_fffffff')
$stdoutPath=Join-Path $stagePath ($Phase+'_'+$runStamp+'.stdout.log')
$stderrPath=Join-Path $stagePath ($Phase+'_'+$runStamp+'.stderr.log')
$claimPath=Join-Path $stagePath ($Phase+'_ROOT_CLAIMED.json')
if(Test-Path -LiteralPath $claimPath){throw 'This phase was already claimed; preserve output and inspect instead of repeating.'}
[IO.File]::WriteAllText($claimPath,('{"phase":"'+$Phase+'","status":"ROOT_CLAIMED_NOT_COMPLETED"}'))
if($Phase -eq 'Import'){$engineArgs=@('--headless','--path',$stagePath,'--editor','--import')}else{$engineArgs=@('--headless','--path',$stagePath,'--script','res://verify.gd')}
$proc=Start-Process -FilePath $enginePath -ArgumentList $engineArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
$proc.WaitForExit()
$naturalCode=$proc.ExitCode
$result=[ordered]@{phase=$Phase;pid=$proc.Id;natural_exit_code=$naturalCode;stdout=$stdoutPath;stderr=$stderrPath;editor_left_running=([bool](Get-Process -Id 51856 -ErrorAction SilentlyContinue));production_written=$false}
$result | ConvertTo-Json -Depth 4
if($naturalCode -ne 0){throw ('Godot '+$Phase+' natural failure; preserve logs')}
