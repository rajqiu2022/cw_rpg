param([Parameter(Mandatory=$true)][string]$RunName)
$ErrorActionPreference = 'Stop'
if ($RunName -notmatch '^floor_import[0-9]+$') { throw 'Use floor_importNN' }
$scope = $PSScriptRoot
$evidence = Join-Path $scope $RunName
if (Test-Path -LiteralPath $evidence) { throw 'Evidence already exists; never overwrite' }
$plan = Get-Content -LiteralPath (Join-Path $scope 'floor_media_import_inputs.json') -Raw | ConvertFrom-Json
if ($plan.scope -ne 'ISOLATED_YIHONG_FLOORS_3_ONLY' -or $plan.records.Count -ne 3 -or
    $plan.project -ne (Join-Path $scope 'isolated_yihong_media_import')) { throw 'Invalid isolated scope' }
if (Test-Path -LiteralPath (Join-Path $plan.project '.godot')) { throw 'Isolated import project is not fresh' }
foreach ($item in $plan.engine_sha256.PSObject.Properties) {
    if ((Get-FileHash -LiteralPath $item.Name).Hash.ToLowerInvariant() -ne $item.Value) { throw 'Godot binary changed' }
}
foreach ($row in $plan.records) {
    if ((Get-FileHash -LiteralPath $row.png).Hash.ToLowerInvariant() -ne $row.candidate_sha256) { throw 'Candidate PNG changed' }
    foreach ($target in $row.targets.PSObject.Properties) {
        if (Test-Path -LiteralPath $target.Value) { throw 'Live path collision; no launch' }
    }
}
$engine = ($plan.engine_sha256.PSObject.Properties | Where-Object Name -like '*_console.exe').Name
New-Item -ItemType Directory -Path $evidence | Out-Null
$privateAppData = (New-Item -ItemType Directory -Path (Join-Path $evidence 'private_appdata')).FullName
$privateLocalAppData = (New-Item -ItemType Directory -Path (Join-Path $evidence 'private_localappdata')).FullName
$envOverride = @{ APPDATA=$privateAppData; LOCALAPPDATA=$privateLocalAppData }
$arguments = @('--headless','--path',('"' + $plan.project + '"'),'--editor','--import','--audio-driver','Dummy')
$proc = Start-Process -FilePath $engine -ArgumentList $arguments -WindowStyle Hidden -PassThru -Environment $envOverride -RedirectStandardOutput (Join-Path $evidence 'stdout.log') -RedirectStandardError (Join-Path $evidence 'stderr.log')
if (-not $proc.WaitForExit(45000)) { throw ('Own isolated import still running; Root inspect PID ' + $proc.Id) }
$proc.WaitForExit()
$result = @{ scope='THREE_ISOLATED_FLOOR_TEXTURES_NO_FORMAL_WRITES'; pid=$proc.Id; exit_code=$proc.ExitCode; real_save_content_access=$false }
[IO.File]::WriteAllText((Join-Path $evidence 'engine_exit.json'), ($result | ConvertTo-Json))
if ($proc.ExitCode -ne 0) { throw 'Import did not exit successfully' }
py (Join-Path $scope 'stage_floor_media.py') --plan-after-import $evidence
if ($LASTEXITCODE -ne 0) { throw 'Offline base/mip or collision check failed; no formal install plan' }
