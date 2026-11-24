#requires -Version 7.5
## Recovery only. Never writes a city other than Gate, a layout, or player data.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$canonical = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../data/scenes/ch4_s0_luoyang_gate.tres'))
$backup = Join-Path $PSScriptRoot 'canonical_gate_before.tres.source'
$oldSha = '872b4ff502f4f8c88eb238a25e3bcdfcb37bec5f71d2e84906ad53f751c90e17'
$newSha = '00d0867a56efec29aa509b4366546c8dfbcc2f4d9a73d062acfa756a2252a581'
$bytes = [IO.File]::ReadAllBytes($backup)
$capturedSha = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
if ($capturedSha -cne $oldSha) { throw 'Recovery backup differs; no write' }
$stream = $null
try {
    $stream = [IO.File]::Open($canonical,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    $current = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)).ToLowerInvariant()
    if ($current -ceq $oldSha) { Write-Host 'Original Gate already restored; no write'; return }
    if ($current -cne $newSha) { throw 'Unknown canonical edit; preserve it and refuse rollback' }
    $stream.Position = 0; $stream.SetLength(0); $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true)
    $stream.Position = 0
    if ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream)).ToLowerInvariant() -cne $oldSha) { throw 'Gate restore readback differs' }
    Write-Host 'Only canonical Gate restored to original exact bytes. No other resource or save changed.'
} finally { if ($null -ne $stream) { $stream.Dispose() } }
