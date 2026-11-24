param([Parameter(Mandatory=$true)][string]$RunName,[Parameter(Mandatory=$true)][string]$Entry,[Parameter(Mandatory=$true)][string[]]$SourcePaths,[string[]]$RunArgs=@(),[switch]$Gpu,[switch]$VerboseEngine,[switch]$ImportOnly)
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
$before = [ordered]@{started_utc=[datetime]::UtcNow.ToString('o');entry=$Entry;user_arguments=$RunArgs;gpu=[bool]$Gpu;verbose_engine=[bool]$VerboseEngine;editor_import_only=[bool]$ImportOnly;sources=$sourceRecords;player_files=$playerBefore}
[System.IO.File]::WriteAllText((Join-Path $runDirectory 'before.json'), ($before | ConvertTo-Json -Depth 8))
$engine = 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
$engineArguments = @('--path',($taskRoot+'\game'),'--audio-driver','Dummy','--script',$Entry)
if ($ImportOnly) {
  if ($Gpu -or $RunArgs.Count -gt 0) { throw 'Editor import must not carry gameplay flags or GPU mode' }
  $engineArguments = @('--path',($taskRoot+'\game'),'--audio-driver','Dummy','--editor','--import')
}
if ($Gpu) { $engineArguments += @('--rendering-method','gl_compatibility') } else { $engineArguments = @('--headless') + $engineArguments }
if ($VerboseEngine) { $engineArguments += '--verbose' }
if ($RunArgs.Count -gt 0) { $engineArguments += @('--') + $RunArgs }
$process = Start-Process -FilePath $engine -ArgumentList $engineArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runDirectory 'stdout.log') -RedirectStandardError (Join-Path $runDirectory 'stderr.log')
$process.WaitForExit()
$playerAfter = @(SnapshotPlayerFiles)
$sourceChanges = @($sourceRecords | Where-Object { (Get-FileHash -LiteralPath $_.path -Algorithm SHA256).Hash -ne $_.sha256 } | ForEach-Object { $_.path })
$playerChanges = @()
for ($index=0; $index -lt $playerBefore.Count; $index++) {
  if (($playerBefore[$index] | ConvertTo-Json -Compress) -ne ($playerAfter[$index] | ConvertTo-Json -Compress)) { $playerChanges += $playerBefore[$index].path }
}
$scope = if ($Gpu) { 'ART_CAPTURE_ONLY_NOT_FIELD_APPROVAL' } else { 'SOURCE_OR_SYNTHETIC_ONLY' }
if ($ImportOnly) { $scope = 'EDITOR_IMPORT_ONLY_NOT_FIELD_APPROVAL' }
$after = [ordered]@{actual_wrapper_pid=$process.Id;actual_os_exit=$process.ExitCode;after_utc=[datetime]::UtcNow.ToString('o');source_changes=$sourceChanges;player_file_changes=$playerChanges;scope=$scope;stderr_reviewed=$false}
[System.IO.File]::WriteAllText((Join-Path $runDirectory 'after.json'), ($after | ConvertTo-Json -Depth 8))
$after | ConvertTo-Json -Depth 8
Get-Content -LiteralPath (Join-Path $runDirectory 'stdout.log')
Get-Content -LiteralPath (Join-Path $runDirectory 'stderr.log')
