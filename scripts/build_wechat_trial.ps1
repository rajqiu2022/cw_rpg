param(
    [string]$AppId = "touristappid",
    [string]$CdnUrl = "http://127.0.0.1:8000/",
    [string]$GodotPath = "",
    [string]$PythonPath = "python",
    [string]$NodePath = "node",
    [ValidatePattern('^wechat_trial(?:_[A-Za-z0-9_-]+)?$')]
    [string]$OutputDirectoryName = "wechat_trial",
    [switch]$SkipGodotExport,
    [switch]$LoadDataFromSubpackage,
    [switch]$FullProject
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$gameRoot = Join-Path $repoRoot "game"
$webRoot = Join-Path $gameRoot "build\wechat_web"
$outputRoot = Join-Path $gameRoot ("build\" + $OutputDirectoryName)
$configPath = Join-Path $gameRoot "build\wechat_transform_config.json"
$packProjectsRoot = Join-Path $gameRoot "build\wechat_pack_projects"
$packBuildRoot = Join-Path $gameRoot "build\wechat_packs"
$compatRuntimeRoot = Join-Path $gameRoot "addons\godot_mini_game\engine"
$compatRuntimeJsPath = Join-Path $compatRuntimeRoot "godot.js"
$compatRuntimeBrPath = Join-Path $compatRuntimeRoot "godot.wasm.br"
$compatRuntimeManifestPath = Join-Path $compatRuntimeRoot "template.json"
$wechatEngineVersion = "4.6.1"
$contentPackIds = @("chapter1_start", "chapter1_late", "chapter2", "chapter3")
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
# Windows PowerShell 5.1 reads UTF-8 scripts without a BOM using the active
# ANSI code page. Build the Chinese display name from code points so the
# converter and project config receive stable Unicode on every machine.
$appName = -join ([char[]](0x4E91, 0x5F71, 0x4FA0, 0x4F20))
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $downloadFolder = -join ([char[]](0x6587, 0x4EF6, 0x4E0B, 0x8F7D))
    $toolsFolder = -join ([char[]](0x7F16, 0x7A0B, 0x5DE5, 0x5177))
    $GodotPath = Join-Path (
        Join-Path (Join-Path "F:\" $downloadFolder) $toolsFolder
    ) "Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"
}

if (-not $SkipGodotExport) {
    if (-not (Test-Path -LiteralPath $GodotPath)) {
        throw "Godot console executable not found: $GodotPath"
    }
    $exportProjectRoot = $gameRoot
    if (-not $FullProject) {
        & $PythonPath (Join-Path $PSScriptRoot "prepare_wechat_trial_stage.py")
        if ($LASTEXITCODE -ne 0) {
            throw "Preparing the chapters 1-3 staging project failed with exit code $LASTEXITCODE"
        }
        & $PythonPath (Join-Path $PSScriptRoot "prepare_wechat_content_packs.py") --cdn-base-url ($CdnUrl.TrimEnd('/') + '/packs/')
        if ($LASTEXITCODE -ne 0) {
            throw "Preparing WeChat content-pack projects failed with exit code $LASTEXITCODE"
        }
        foreach ($packId in $contentPackIds) {
            $packProject = Join-Path $packProjectsRoot $packId
            $packPath = Join-Path $packBuildRoot "$packId.pck"
            & $GodotPath --headless --path $packProject --export-pack "Web-WeChat-Base" $packPath
            if ($LASTEXITCODE -ne 0) {
                throw "Exporting $packId failed with exit code $LASTEXITCODE"
            }
        }
        & $PythonPath (Join-Path $PSScriptRoot "prepare_wechat_content_packs.py") --finalize-only --cdn-base-url ($CdnUrl.TrimEnd('/') + '/packs/')
        if ($LASTEXITCODE -ne 0) {
            throw "Finalizing WeChat content-pack manifest failed with exit code $LASTEXITCODE"
        }
        $exportProjectRoot = Join-Path $packProjectsRoot "common"
    }
    New-Item -ItemType Directory -Force -Path $webRoot | Out-Null
    & $GodotPath --headless --path $exportProjectRoot --export-release "Web-WeChat-Base" (Join-Path $webRoot "index.html")
    if ($LASTEXITCODE -ne 0) {
        throw "Godot Web export failed with exit code $LASTEXITCODE"
    }
}

$jsPath = Join-Path $webRoot "index.js"
$wechatJsPath = Join-Path $webRoot "index.wechat.js"
$wechatWasmPath = Join-Path $webRoot "index.wechat.compat.wasm"
$wasmPath = Join-Path $webRoot "index.wasm"
$pckPath = Join-Path $webRoot "index.pck"
$dataContainerPath = Join-Path $webRoot "index.wechat.data"
foreach ($required in @($jsPath, $wasmPath, $pckPath, $compatRuntimeJsPath, $compatRuntimeBrPath, $compatRuntimeManifestPath)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing Web export artifact: $required"
    }
}

& $NodePath (Join-Path $PSScriptRoot "prepare_wechat_compat_runtime.mjs") --manifest $compatRuntimeManifestPath --source $compatRuntimeBrPath --output $wechatWasmPath
if ($LASTEXITCODE -ne 0) {
    throw "Preparing the no-EH WeChat runtime failed with exit code $LASTEXITCODE"
}
& $PythonPath (Join-Path $PSScriptRoot "prepare_wechat_framework.py") --source $compatRuntimeJsPath --output $wechatJsPath
if ($LASTEXITCODE -ne 0) {
    throw "Preparing the WeChat-safe Godot framework failed with exit code $LASTEXITCODE"
}
& $PythonPath (Join-Path $PSScriptRoot "prepare_wechat_data_container.py") --source $pckPath --output $dataContainerPath
if ($LASTEXITCODE -ne 0) {
    throw "Preparing the WXGameKit data container failed with exit code $LASTEXITCODE"
}

$verifiedBuildRoot = [System.IO.Path]::GetFullPath((Join-Path $gameRoot "build"))
$verifiedOutputRoot = [System.IO.Path]::GetFullPath($outputRoot)
if (
    (Split-Path -Parent $verifiedOutputRoot) -ne $verifiedBuildRoot -or
    (Split-Path -Leaf $verifiedOutputRoot) -ne $OutputDirectoryName -or
    $OutputDirectoryName -notmatch '^wechat_trial(?:_[A-Za-z0-9_-]+)?$'
) {
    throw "Refusing unsafe WeChat output path: $verifiedOutputRoot"
}
if (Test-Path -LiteralPath $verifiedOutputRoot) {
    Remove-Item -LiteralPath $verifiedOutputRoot -Recurse -Force
}

$transformer = & (Join-Path $PSScriptRoot "setup_wechat_transformer.ps1")
$transformConfig = [ordered]@{
    jsFile = $wechatJsPath
    wasmFile = $wechatWasmPath
    dataFile = $dataContainerPath
    cdnUrl = $CdnUrl
    outputDir = $outputRoot
    appID = $AppId
    appName = $appName
    engineName = "Godot"
    engineVersion = $wechatEngineVersion
    webglVersion = 2
    alphaChannel = $false
    deviceOrientation = "landscape"
    loadFromSubpackage = [bool]$LoadDataFromSubpackage
    # The official transformer wraps index.pck in UnityWebData1.0. WXGameKit
    # recognizes that container and writes index.pck into Emscripten FS before
    # Godot starts with --main-pack index.pck.
    compressData = $false
    forceSingleThread = $true
}
[System.IO.File]::WriteAllText(
    $configPath,
    ($transformConfig | ConvertTo-Json -Depth 5),
    $utf8NoBom
)

& $transformer --config $configPath
if ($LASTEXITCODE -ne 0) {
    throw "WeChat transformer failed with exit code $LASTEXITCODE"
}

$miniRoot = Join-Path $outputRoot "minigame"
$wxGameKitConfigPath = Join-Path $miniRoot "wx-game-kit\config.json"
if (-not (Test-Path -LiteralPath $wxGameKitConfigPath)) {
    throw "WeChat transformer did not create WXGameKit config: $wxGameKitConfigPath"
}
$godotCustomInstanceSource = Join-Path $PSScriptRoot "wechat_godot_custom_instance.js"
$godotCustomInstanceTarget = Join-Path $miniRoot "wx-game-kit\custom\custom-instance.js"
foreach ($required in @($godotCustomInstanceSource, $godotCustomInstanceTarget)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing Godot WXGameKit runtime adapter path: $required"
    }
}
Copy-Item -LiteralPath $godotCustomInstanceSource -Destination $godotCustomInstanceTarget -Force
$gameEntryPath = Join-Path $miniRoot "game.js"
$gameEntrySource = [System.IO.File]::ReadAllText($gameEntryPath, $utf8NoBom)
$loaderStartMarker = "if (typeof WXGameKit.loader !== 'undefined') {"
if ($gameEntrySource.Count -eq 0 -or -not $gameEntrySource.Contains($loaderStartMarker)) {
    throw "WXGameKit game entry no longer contains the expected loader start marker"
}
if (-not $gameEntrySource.Contains("configureGodotWXGameKit(")) {
    $adapterCall = "GameGlobal.configureGodotWXGameKit();"
    $gameEntrySource = $gameEntrySource.Replace(
        $loaderStartMarker,
        ($adapterCall + [Environment]::NewLine + $loaderStartMarker)
    )
    [System.IO.File]::WriteAllText($gameEntryPath, $gameEntrySource, $utf8NoBom)
}

$projectConfigPath = Join-Path $miniRoot "project.config.json"
if (-not (Test-Path -LiteralPath $projectConfigPath)) {
    throw "WeChat transformer did not create project.config.json: $projectConfigPath"
}
$projectConfig = Get-Content -LiteralPath $projectConfigPath -Raw | ConvertFrom-Json
$projectConfig.appid = $AppId
$projectConfig.projectname = $appName
$projectConfig.isGameTourist = $AppId -eq "touristappid"
[System.IO.File]::WriteAllText(
    $projectConfigPath,
    ($projectConfig | ConvertTo-Json -Depth 20),
    $utf8NoBom
)

# Leave a human-readable sentinel in the exact folder that must be imported.
# There are older native-adapter experiments under game/build; without a
# sentinel it is too easy to import one of those folders and get a menu that
# cannot enter the current Godot chapters.
$trialMarkerPath = Join-Path $miniRoot "WECHAT_TRIAL_PROJECT.txt"
$trialMarker = @(
    "云影侠传：微信小游戏前三章试玩工程",
    "请在微信开发者工具中导入本文件所在目录。",
    "不要导入 game/build/wechat_native_trial 或 wechat_native_trial_v2。",
    ("AppID: " + $AppId),
    ("构建时间: " + (Get-Date).ToString('o'))
) -join [Environment]::NewLine
[System.IO.File]::WriteAllText($trialMarkerPath, $trialMarker, $utf8NoBom)

$frameworkPath = Join-Path $miniRoot "framework.js"
if (-not (Test-Path -LiteralPath $frameworkPath)) {
    throw "WeChat transformer did not create framework.js: $frameworkPath"
}
Get-Content -LiteralPath $frameworkPath -Raw | & $NodePath --input-type=module --check
if ($LASTEXITCODE -ne 0) {
    throw "Converted framework.js failed JavaScript syntax validation"
}

if (-not $FullProject -and (Test-Path -LiteralPath $packBuildRoot)) {
    $publishedPackRoot = Join-Path $outputRoot "packs"
    New-Item -ItemType Directory -Force -Path $publishedPackRoot | Out-Null
    $packFiles = @($contentPackIds | ForEach-Object { Join-Path $packBuildRoot "$_.pck" })
    Copy-Item -LiteralPath $packFiles -Destination $publishedPackRoot -Force
}

$gameJsonPath = Join-Path $miniRoot "game.json"
$subpackageRoots = @()
if (Test-Path -LiteralPath $gameJsonPath) {
    $gameJson = Get-Content -LiteralPath $gameJsonPath -Raw | ConvertFrom-Json
    $packages = if ($gameJson.subpackages) { $gameJson.subpackages } else { $gameJson.subPackages }
    foreach ($package in $packages) {
        if ($package.root) { $subpackageRoots += [string]$package.root }
    }
}

$allFiles = @(Get-ChildItem -LiteralPath $miniRoot -Recurse -File)
$codeFiles = @($allFiles | Where-Object {
    $relative = $_.FullName.Substring($miniRoot.Length + 1).Replace('\', '/')
    -not $relative.StartsWith('data-package/') -or $LoadDataFromSubpackage
})
$mainFiles = @($codeFiles | Where-Object {
    $relative = $_.FullName.Substring($miniRoot.Length + 1).Replace('\', '/')
    -not ($subpackageRoots | Where-Object { $relative.StartsWith($_.TrimEnd('/') + '/') })
})

$codeBytes = [int64](($codeFiles | Measure-Object Length -Sum).Sum)
$mainBytes = [int64](($mainFiles | Measure-Object Length -Sum).Sum)
$dataBytes = [int64](Get-Item -LiteralPath $pckPath).Length
$sourceFiles = @(Get-Item -LiteralPath (Join-Path $gameRoot "project.godot")) + @(
    Get-ChildItem -LiteralPath (Join-Path $gameRoot "scripts"),(Join-Path $gameRoot "scenes"),(Join-Path $gameRoot "data") -Recurse -File
)
$latestSourceWrite = ($sourceFiles | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1).LastWriteTimeUtc
$webWrite = (Get-Item -LiteralPath $pckPath).LastWriteTimeUtc
$staleWebExport = $webWrite -lt $latestSourceWrite
$report = [ordered]@{
    generatedAt = (Get-Date).ToString('o')
    appId = $AppId
    cdnUrl = $CdnUrl
    loadDataFromSubpackage = [bool]$LoadDataFromSubpackage
    web = @{ jsBytes = (Get-Item $jsPath).Length; wechatJsBytes = (Get-Item $wechatJsPath).Length; wasmBytes = (Get-Item $wechatWasmPath).Length; pckBytes = $dataBytes; dataCompression = "none"; runtimeVersion = $wechatEngineVersion; wasmExceptions = $false }
    minigame = @{ mainBytes = $mainBytes; totalCodeBytes = $codeBytes; packageLimitBytes = 30MB; mainLimitBytes = 4MB; subpackageRoots = $subpackageRoots }
    freshness = @{ latestSourceWriteUtc = $latestSourceWrite.ToString('o'); webPackageWriteUtc = $webWrite.ToString('o'); staleWebExport = $staleWebExport }
    pass = @{ mainPackage = $mainBytes -le 4MB; totalCodePackage = $codeBytes -le 30MB; remoteDataConfigured = $LoadDataFromSubpackage -or -not $CdnUrl.StartsWith('http://localhost'); sourceFresh = -not $staleWebExport; frameworkSyntax = $true }
}
$publishedPacks = @()
$publishedPackRoot = Join-Path $outputRoot "packs"
if (Test-Path -LiteralPath $publishedPackRoot) {
    $publishedPacks = @(Get-ChildItem -LiteralPath $publishedPackRoot -File -Filter "*.pck" | ForEach-Object {
        @{ file = $_.Name; bytes = $_.Length; sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
    })
}
$report.contentPacks = $publishedPacks
$reportPath = Join-Path $outputRoot "wechat-package-report.json"
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding utf8

Write-Host "WeChat project: $miniRoot"
Write-Host ("Main package: {0:N2} MB / 4 MB" -f ($mainBytes / 1MB))
Write-Host ("Total code package: {0:N2} MB / 30 MB" -f ($codeBytes / 1MB))
Write-Host ("Remote data package: {0:N2} MB" -f ($dataBytes / 1MB))
if ($staleWebExport) {
    Write-Warning "The converted Web package is older than current scripts/data. Re-run without -SkipGodotExport before device testing."
}
Write-Host "Report: $reportPath"

if ($mainBytes -gt 4MB -or $codeBytes -gt 30MB) {
    throw "WeChat code package size gate failed. See $reportPath"
}
