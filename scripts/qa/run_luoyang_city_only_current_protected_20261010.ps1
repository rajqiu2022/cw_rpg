param(
 [Parameter(Mandatory=$true)][string]$RunName,
 [Parameter(Mandatory=$true)][string]$Entry,
 [Parameter(Mandatory=$true)][string]$SourcePathsFile,
 [Parameter(Mandatory=$true)][string]$SourcePathsSHA,
 [string[]]$RunArgs=@(),[switch]$Gpu,[switch]$VerboseEngine,
 [ValidateRange(30,43200)][int]$TimeoutSeconds=21600,
 [string]$ProjectRoot='F:\Code\RPG_GAME',
 [string]$PlayerSaveDirectory='C:\Users\rajqiu\AppData\Roaming\Godot\app_userdata\云影侠传'
)
# NEW bounded direct-GUI runner. No approval/log whitelist/OS configuration.
# Source inventory is PATHS only: every file is freshly copied/hashed here.
# GUI avoids the old console bootstrap leaving an unowned GUI child behind.
$ErrorActionPreference='Stop'
$project=[IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\')
$game=Join-Path $project 'game'
$build=Join-Path $game 'build\joint_world_luoyang_20261003_qa'
if ($RunName -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_-]{0,159}$') {throw 'Unique simple run name required'}
$directory=Join-Path $build $RunName
if (Test-Path -LiteralPath $directory) {throw 'Evidence directory already exists'}
if ($SourcePathsSHA -cnotmatch '^[A-Fa-f0-9]{64}$') {throw 'Exact inventory SHA required'}
$inventory=[IO.Path]::GetFullPath($SourcePathsFile)
if (-not $inventory.StartsWith($project+'\',[StringComparison]::OrdinalIgnoreCase) -or (Get-FileHash -LiteralPath $inventory).Hash -ine $SourcePathsSHA) {throw 'Inventory path/SHA differs'}
$inputRecord=[IO.File]::ReadAllText($inventory)|ConvertFrom-Json -AsHashtable -Depth 100
if ($inputRecord -isnot [Collections.IDictionary] -or $inputRecord.source_paths -isnot [array] -or $inputRecord.source_paths.Count -eq 0) {throw 'Nonempty typed path inventory required'}
$paths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function Project-Leaf([string]$relative) {
 if ([IO.Path]::IsPathRooted($relative) -or $relative.StartsWith('res://',[StringComparison]::Ordinal)) {throw 'SourcePaths must be project-relative'}
 $path=[IO.Path]::GetFullPath((Join-Path $project $relative))
 if (-not $path.StartsWith($project+'\',[StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {throw "Missing/outside required source: $relative"}
 return $path
}
foreach ($relative in $inputRecord.source_paths) {
 if ($relative -isnot [string] -or [string]::IsNullOrWhiteSpace($relative)) {throw 'Typed nonempty relative path required'}
 $path=Project-Leaf $relative
 if (-not $paths.Add($path)) {throw 'Duplicate canonical source path'}
}
[void]$paths.Add($inventory);[void]$paths.Add([IO.Path]::GetFullPath($PSCommandPath))
if (-not $Entry.StartsWith('res://',[StringComparison]::Ordinal) -or -not $Entry.EndsWith('.gd',[StringComparison]::Ordinal)) {throw 'Explicit res script entry required'}
$entryFile=Project-Leaf ('game/'+$Entry.Substring(6))
if (-not $paths.Contains($entryFile)) {throw 'Actual entry missing from source first guard'}
foreach ($arg in $RunArgs) {if ($arg -isnot [string] -or $arg.Contains('"') -or $arg.Contains("`r") -or $arg.Contains("`n")) {throw 'Invalid user argument'}}
$gui='F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe'
$console='F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
$exePins=@{
 $gui='975BF1D254B989EE12B64DF4D07DA692A31175F72424BAA180F1078BFC0D71B0'
 $console='2A12DF24D1545FF3924A1F40E8ED9F4EC7CE9B140814C1B566DCD2BDF7B79492'
}
function File-Record([string]$path) {
 if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {return [ordered]@{path=$path;exists=$false}}
 $file=Get-Item -LiteralPath $path
 return [ordered]@{path=$file.FullName;exists=$true;sha256=(Get-FileHash -LiteralPath $path).Hash;bytes=[long]$file.Length;utc_ticks=$file.LastWriteTimeUtc.Ticks.ToString([Globalization.CultureInfo]::InvariantCulture)}
}
function Player-Records {
 foreach ($slot in 0..4) {foreach ($suffix in @('','.bak','.tmp')) {File-Record (Join-Path $PlayerSaveDirectory ('save_'+$slot+'.json'+$suffix))}}
}
function Write-Record([string]$path,$value) {[IO.File]::WriteAllText($path,($value|ConvertTo-Json -Depth 100),[Text.UTF8Encoding]::new($false))}
function Different($a,$b) {return (($a|ConvertTo-Json -Depth 8 -Compress) -cne ($b|ConvertTo-Json -Depth 8 -Compress))}
$exesBefore=@(foreach ($exe in @($gui,$console)) {
 $row=File-Record $exe
 if (-not $row.exists -or $row.sha256 -cne $exePins[$exe]) {throw 'Installed executable identity differs'}
 $row
})
New-Item -ItemType Directory -Path $directory|Out-Null
New-Item -ItemType Directory -Path (Join-Path $directory 'source_copies')|Out-Null
[IO.File]::WriteAllText((Join-Path $directory '.gdignore'),'Root evidence only')
$sourcesBefore=@(foreach ($path in @($paths|Sort-Object)) {
 $row=File-Record $path
 if (-not $row.exists) {throw 'Required source disappeared before launch'}
 # Include path identity in archive name; equal-basename/hash leaves cannot overwrite.
 $pathHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($path)))
 $copy=Join-Path $directory ('source_copies/'+$pathHash+'_'+[IO.Path]::GetFileName($path)+'.'+$row.sha256+'.source')
 Copy-Item -LiteralPath $path -Destination $copy
 if ((Get-FileHash -LiteralPath $copy).Hash -cne $row.sha256 -or (Different $row (File-Record $path))) {throw 'Source changed while first snapshot/copy was captured'}
 $row
})
$playersBefore=@(Player-Records)
$arguments=@('--path',$game,'--audio-driver','WASAPI','--accessibility','disabled','--script',$Entry)
if ($Gpu) {$arguments+=@('--rendering-method','gl_compatibility')} else {$arguments=@('--display-driver','headless')+$arguments}
if ($VerboseEngine) {$arguments+='--verbose'}
if ($RunArgs.Count -gt 0) {$arguments+=@('--')+$RunArgs}
$stdout=Join-Path $directory 'stdout.log';$stderr=Join-Path $directory 'stderr.log'
$before=[ordered]@{started_utc=[DateTime]::UtcNow.ToString('o');entry=$Entry;user_arguments=@($RunArgs);actual_engine_arguments=$arguments;gpu=[bool]$Gpu;verbose_engine=[bool]$VerboseEngine;requested_audio_driver='WASAPI';accessibility_mode='disabled';scope='BOUNDED_CURRENT_CITY_ONLY_ACTUAL_RUN_NOT_APPROVAL';source_inventory_path=$inventory;source_inventory_sha256=$SourcePathsSHA;sources=$sourcesBefore;player_files=$playersBefore;installed_executables=$exesBefore;selected_executable=$gui;timeout_seconds=$TimeoutSeconds;stderr_reviewed=$false}
Write-Record (Join-Path $directory 'before.json') $before
$process=$null;$timedOut=$false;$launchError='';$actualExit=$null
try {
 # Quote every native argument explicitly (project/engine paths may contain spaces).
 $quoted=@($arguments|ForEach-Object {'"'+$_+'"'}) -join ' '
 $process=Start-Process -FilePath $gui -ArgumentList $quoted -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
 Write-Record (Join-Path $directory 'owned_process.json') ([ordered]@{pid=$process.Id;start_utc=$process.StartTime.ToUniversalTime().ToString('o');executable=$gui;installed_sha256=$exePins[$gui];ownership='ONLY_THIS_START_PROCESS_RETURNED_GUI_PID';timeout_seconds=$TimeoutSeconds})
 if (-not $process.WaitForExit($TimeoutSeconds*1000)) {
  $timedOut=$true
  # This process object belongs solely to the above launch; never enumerate/kill other Godot/editor processes.
  if (-not $process.HasExited) {$process.Kill();if (-not $process.WaitForExit(10000)) {throw 'Owned GUI did not exit within kill deadline'}}
 }
 $process.Refresh();$actualExit=$process.ExitCode
} catch {$launchError=$_.Exception.Message;if ($null -ne $process -and -not $process.HasExited) {$process.Kill();if (-not $process.WaitForExit(10000)) {$launchError+='; owned GUI kill deadline exceeded'}}}
$sourcesAfter=@(foreach ($row in $sourcesBefore) {File-Record $row.path})
$playersAfter=@(Player-Records);$exesAfter=@(File-Record $gui;File-Record $console)
$sourceChanges=@(for ($n=0;$n -lt $sourcesBefore.Count;$n++) {if (Different $sourcesBefore[$n] $sourcesAfter[$n]) {$sourcesBefore[$n].path}})
$playerChanges=@(for ($n=0;$n -lt 15;$n++) {if (Different $playersBefore[$n] $playersAfter[$n]) {$playersBefore[$n].path}})
$exeChanges=@(for ($n=0;$n -lt 2;$n++) {if (Different $exesBefore[$n] $exesAfter[$n]) {$exesBefore[$n].path}})
$after=[ordered]@{after_utc=[DateTime]::UtcNow.ToString('o');actual_wrapper_pid=$PID;owned_gui_pid=$(if($null -ne $process){$process.Id}else{$null});actual_os_exit=$actualExit;timed_out=$timedOut;launch_or_wait_error=$launchError;source_changes=$sourceChanges;player_file_changes=$playerChanges;executable_changes=$exeChanges;sources=$sourcesAfter;player_files=$playersAfter;installed_executables=$exesAfter;stdout=$(File-Record $stdout);stderr=$(File-Record $stderr);scope='BOUNDED_CURRENT_CITY_ONLY_ACTUAL_RUN_NOT_APPROVAL';stderr_reviewed=$false;whole_phase_approval=$false}
Write-Record (Join-Path $directory 'after.json') $after
$after|ConvertTo-Json -Depth 5
if (Test-Path -LiteralPath $stdout) {Get-Content -LiteralPath $stdout -Tail 20}
if (Test-Path -LiteralPath $stderr) {Get-Content -LiteralPath $stderr -Tail 20}
if ($timedOut -or $launchError.Length -ne 0 -or $null -eq $actualExit -or $sourceChanges.Count -ne 0 -or $playerChanges.Count -ne 0 -or $exeChanges.Count -ne 0) {exit 1}
# Actual engine exit is propagated; exit zero alone is NOT a complete log/phase approval.
exit $actualExit
