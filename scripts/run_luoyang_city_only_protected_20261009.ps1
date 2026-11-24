param([Parameter(Mandatory=$true)][string]$RunName,[Parameter(Mandatory=$true)][string]$Entry,[Parameter(Mandatory=$true)][string[]]$SourcePaths,[string[]]$RunArgs=@(),[switch]$Gpu,[switch]$VerboseEngine)
# NEW isolated WASAPI A/B only; original wrapper remains unchanged.
# Installed --help confirms WASAPI/Dummy. Avoid --headless shortcut, which
# forces Dummy audio; use explicit headless DISPLAY with requested WASAPI.
# The diagnostic must independently assert AudioServer.get_driver_name().
# Does not change project/user audio/accessibility settings or grant approval.
$ErrorActionPreference = 'Stop'
$taskRoot = 'F:\Code\RPG_GAME'
$runDirectory = Join-Path $taskRoot ('game\build\joint_world_luoyang_20261003_qa\' + $RunName)
if (Test-Path -LiteralPath $runDirectory) { throw 'A unique evidence directory is required' }
New-Item -ItemType Directory -Path $runDirectory | Out-Null
[System.IO.File]::WriteAllText((Join-Path $runDirectory '.gdignore'), 'Root evidence only')
$sourceRecords = @($SourcePaths | ForEach-Object {
  $resolved = (Resolve-Path -LiteralPath (Join-Path $taskRoot $_)).Path
  $sourceFile = Get-Item -LiteralPath $resolved
  Copy-Item -LiteralPath $resolved -Destination (Join-Path $runDirectory ($sourceFile.Name + '.' + (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash + '.source'))
  [ordered]@{path=$resolved;sha256=(Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash;bytes=$sourceFile.Length}
})
$saveDirectory = 'C:\Users\rajqiu\AppData\Roaming\Godot\app_userdata\云影侠传'
function SnapshotPlayerFiles {
  foreach ($slot in 0..4) {
    foreach ($suffix in @('', '.bak', '.tmp')) {
      $playerPath = Join-Path $saveDirectory ('save_' + $slot + '.json' + $suffix)
      if (Test-Path -LiteralPath $playerPath) {
        $playerFile = Get-Item -LiteralPath $playerPath
        [ordered]@{path=$playerPath;exists=$true;sha256=(Get-FileHash -LiteralPath $playerPath -Algorithm SHA256).Hash;bytes=$playerFile.Length;utc_ticks=[string]$playerFile.LastWriteTimeUtc.Ticks}
      } else { [ordered]@{path=$playerPath;exists=$false} }
    }
  }
}
$playerBefore = @(SnapshotPlayerFiles)
$engine = 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
$engineArguments = @('--path',($taskRoot+'\game'),'--audio-driver','WASAPI','--accessibility','disabled','--script',$Entry)
if ($Gpu) { $engineArguments += @('--rendering-method','gl_compatibility') } else { $engineArguments = @('--display-driver','headless') + $engineArguments }
if ($VerboseEngine) { $engineArguments += '--verbose' }
if ($RunArgs.Count -gt 0) { $engineArguments += @('--') + $RunArgs }
$before = [ordered]@{started_utc=[datetime]::UtcNow.ToString('o');entry=$Entry;user_arguments=$RunArgs;actual_engine_arguments=$engineArguments;gpu=[bool]$Gpu;verbose_engine=[bool]$VerboseEngine;accessibility_mode='disabled';scope='ISOLATED_WASAPI_AUDIO_DRIVER_AB_NOT_GLOBAL_SETTING';requested_audio_driver='WASAPI';actual_driver_must_be_asserted_by_diagnostic=$true;production_audio_driver_approval=$false;production_accessibility_approval=$false;sources=$sourceRecords;player_files=$playerBefore}
[System.IO.File]::WriteAllText((Join-Path $runDirectory 'before.json'), ($before | ConvertTo-Json -Depth 8))
$process = Start-Process -FilePath $engine -ArgumentList $engineArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runDirectory 'stdout.log') -RedirectStandardError (Join-Path $runDirectory 'stderr.log')
$process.WaitForExit()
$playerAfter = @(SnapshotPlayerFiles)
$sourceChanges = @($sourceRecords | Where-Object { (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256 } | ForEach-Object { $_.path })
$playerChanges = @()
for ($index=0; $index -lt $playerBefore.Count; $index++) {
  if (($playerBefore[$index] | ConvertTo-Json -Compress) -ne ($playerAfter[$index] | ConvertTo-Json -Compress)) { $playerChanges += $playerBefore[$index].path }
}
$scope = if ($Gpu) { 'GPU_WASAPI_AB_NOT_FIELD_APPROVAL' } else { 'HEADLESS_DISPLAY_WASAPI_AB_NOT_FIELD_APPROVAL' }
$after = [ordered]@{actual_wrapper_pid=$process.Id;actual_os_exit=$process.ExitCode;after_utc=[datetime]::UtcNow.ToString('o');source_changes=$sourceChanges;player_file_changes=$playerChanges;scope=$scope;accessibility_mode='disabled';requested_audio_driver='WASAPI';actual_driver_must_be_asserted_by_diagnostic=$true;production_audio_driver_approval=$false;production_accessibility_approval=$false;stderr_reviewed=$false}
[System.IO.File]::WriteAllText((Join-Path $runDirectory 'after.json'), ($after | ConvertTo-Json -Depth 8))
$after | ConvertTo-Json -Depth 8
# Logs stay complete on disk. Do not print megabytes of runtime shader/asset logs.
Get-Content -LiteralPath (Join-Path $runDirectory 'stdout.log') -Tail 20
Get-Content -LiteralPath (Join-Path $runDirectory 'stderr.log') -Tail 20
