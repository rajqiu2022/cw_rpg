param(
    [string]$OutputDir = "game/art/audio/free"
)

$ErrorActionPreference = "Stop"
$sampleRate = 22050
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

function Write-Wav([string]$path, [double[]]$samples) {
    $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($stream)
    $dataBytes = $samples.Length * 2
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
    $writer.Write([int](36 + $dataBytes))
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
    $writer.Write([int]16)
    $writer.Write([int16]1)
    $writer.Write([int16]1)
    $writer.Write([int]$sampleRate)
    $writer.Write([int]($sampleRate * 2))
    $writer.Write([int16]2)
    $writer.Write([int16]16)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
    $writer.Write([int]$dataBytes)
    foreach ($sample in $samples) {
        $writer.Write([int16]([Math]::Round([Math]::Max(-1.0, [Math]::Min(1.0, $sample)) * 30000.0)))
    }
    $writer.Dispose()
    $stream.Dispose()
}

function New-Tone([double]$duration, [double]$frequency, [double]$volume, [string]$kind) {
    $count = [int]($duration * $sampleRate)
    $samples = [double[]]::new($count)
    for ($i = 0; $i -lt $count; $i++) {
        $t = $i / $sampleRate
        $phase = 2.0 * [Math]::PI * $frequency * $t
        $env = 1.0
        if ($kind -eq "hit" -or $kind -eq "ui") {
            $env = [Math]::Exp(-10.0 * $t)
        } elseif ($kind -eq "attack") {
            $env = [Math]::Min(1.0, $t * 38.0) * [Math]::Exp(-4.5 * $t)
        } elseif ($kind -eq "skill") {
            $env = [Math]::Min(1.0, $t * 8.0) * [Math]::Exp(-2.1 * $t)
        } elseif ($kind -eq "victory" -or $kind -eq "defeat") {
            $env = [Math]::Min(1.0, $t * 12.0) * [Math]::Exp(-1.3 * $t)
        }
        $value = [Math]::Sin($phase) * $volume
        if ($kind -eq "attack") { $value += [Math]::Sin($phase * 2.01) * 0.20 * $volume }
        if ($kind -eq "hit") { $value += ((Get-Random -Minimum -1000 -Maximum 1000) / 1000.0) * 0.08 * $volume }
        $samples[$i] = $value * $env
    }
    return $samples
}

function New-WuxiaWhoosh([double]$duration, [double]$lowFreq, [double]$highFreq, [double]$metal, [int]$seed) {
    $count = [int]($duration * $sampleRate)
    $samples = [double[]]::new($count)
    $random = [System.Random]::new($seed)
    $phase = 0.0
    $filteredNoise = 0.0
    for ($i = 0; $i -lt $count; $i++) {
        $t = $i / $sampleRate
        $x = $t / $duration
        $frequency = $lowFreq + ($highFreq - $lowFreq) * [Math]::Pow($x, 0.72)
        $phase += 2.0 * [Math]::PI * $frequency / $sampleRate
        $noise = $random.NextDouble() * 2.0 - 1.0
        $filteredNoise = $filteredNoise * 0.72 + $noise * 0.28
        $envelope = [Math]::Pow([Math]::Sin([Math]::PI * [Math]::Min(1.0, $x)), 0.72) * [Math]::Exp(-0.9 * $x)
        $air = $filteredNoise * 0.50 + [Math]::Sin($phase) * 0.16
        $ring = [Math]::Sin(2.0 * [Math]::PI * 1840.0 * $t) * $metal * [Math]::Exp(-14.0 * $t)
        $samples[$i] = ($air * $envelope + $ring) * 0.72
    }
    return $samples
}

function New-WuxiaImpact([double]$duration, [double]$bodyFreq, [double]$metal, [int]$seed) {
    $count = [int]($duration * $sampleRate)
    $samples = [double[]]::new($count)
    $random = [System.Random]::new($seed)
    $filteredNoise = 0.0
    for ($i = 0; $i -lt $count; $i++) {
        $t = $i / $sampleRate
        $noise = $random.NextDouble() * 2.0 - 1.0
        $filteredNoise = $filteredNoise * 0.45 + $noise * 0.55
        $body = [Math]::Sin(2.0 * [Math]::PI * $bodyFreq * $t) * [Math]::Exp(-18.0 * $t)
        $crack = $filteredNoise * [Math]::Exp(-30.0 * $t)
        $ring = [Math]::Sin(2.0 * [Math]::PI * 1320.0 * $t) * $metal * [Math]::Exp(-12.0 * $t)
        $samples[$i] = $body * 0.62 + $crack * 0.32 + $ring
    }
    return $samples
}

function New-Music([double]$duration, [bool]$battle) {
    $count = [int]($duration * $sampleRate)
    $samples = [double[]]::new($count)
    $fieldNotes = @(0, 4, 7, 9, 7, 4, 2, 4)
    $battleNotes = @(0, 0, 3, 5, 3, 2, 0, -2)
    $notes = if ($battle) { $battleNotes } else { $fieldNotes }
    $base = if ($battle) { 146.83 } else { 196.0 }
    for ($i = 0; $i -lt $count; $i++) {
        $t = $i / $sampleRate
        $step = [int]([Math]::Floor($t / 0.75)) % $notes.Length
        $freq = $base * [Math]::Pow(2.0, $notes[$step] / 12.0)
        $phase = 2.0 * [Math]::PI * $freq * $t
        $bass = [Math]::Sin($phase * 0.5) * 0.16
        $lead = [Math]::Sin($phase) * 0.12 + [Math]::Sin($phase * 2.0) * 0.035
        $pulse = if ($battle) { [Math]::Sin(2.0 * [Math]::PI * 73.42 * $t) * 0.06 } else { 0.0 }
        $samples[$i] = $bass + $lead + $pulse
    }
    return $samples
}

Write-Wav (Join-Path $OutputDir "bgm_field_free_v1.wav") (New-Music 18.0 $false)
Write-Wav (Join-Path $OutputDir "bgm_battle_free_v1.wav") (New-Music 12.0 $true)
Write-Wav (Join-Path $OutputDir "sfx_attack_free_v1.wav") (New-Tone 0.28 180.0 0.55 "attack")
Write-Wav (Join-Path $OutputDir "sfx_skill_free_v1.wav") (New-Tone 0.52 420.0 0.35 "skill")
Write-Wav (Join-Path $OutputDir "sfx_hit_free_v1.wav") (New-Tone 0.20 92.0 0.65 "hit")
Write-Wav (Join-Path $OutputDir "sfx_defend_free_v1.wav") (New-Tone 0.34 260.0 0.35 "ui")
Write-Wav (Join-Path $OutputDir "sfx_ui_confirm_free_v1.wav") (New-Tone 0.12 660.0 0.25 "ui")
Write-Wav (Join-Path $OutputDir "sfx_victory_free_v1.wav") (New-Tone 0.90 523.25 0.35 "victory")
Write-Wav (Join-Path $OutputDir "sfx_defeat_free_v1.wav") (New-Tone 0.75 164.81 0.35 "defeat")

# v2 武侠战斗层：短促风切负责出招，低频冲击负责命中，不再使用电子纯音。
$null = New-WuxiaWhoosh 0.01 100.0 120.0 0.0 1000  # 预热 PowerShell 数组绑定
Write-Wav (Join-Path $OutputDir "sfx_blade_light_wuxia_v2.wav") (New-WuxiaWhoosh 0.24 150.0 980.0 0.18 1101)
Write-Wav (Join-Path $OutputDir "sfx_blade_whoosh_wuxia_v2.wav") (New-WuxiaWhoosh 0.30 105.0 620.0 0.10 1102)
Write-Wav (Join-Path $OutputDir "sfx_staff_whoosh_wuxia_v2.wav") (New-WuxiaWhoosh 0.28 82.0 430.0 0.02 1103)
Write-Wav (Join-Path $OutputDir "sfx_palm_burst_wuxia_v2.wav") (New-WuxiaWhoosh 0.34 65.0 360.0 0.00 1104)
Write-Wav (Join-Path $OutputDir "sfx_hit_body_wuxia_v2.wav") (New-WuxiaImpact 0.22 92.0 0.00 2101)
Write-Wav (Join-Path $OutputDir "sfx_hit_metal_wuxia_v2.wav") (New-WuxiaImpact 0.26 118.0 0.20 2102)

Write-Output "Generated free original WAV assets in $OutputDir"
