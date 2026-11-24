param(
 [string]$Workspace='F:/Code/RPG_GAME',
 [string]$Output='F:/Code/RPG_GAME/game/build/luoyang_gate_stable_import_20261017_system01'
)
$ErrorActionPreference='Stop'
$Workspace=[IO.Path]::GetFullPath($Workspace)
$Output=[IO.Path]::GetFullPath($Output)
$build=[IO.Path]::GetFullPath((Join-Path $Workspace 'game/build'))+[IO.Path]::DirectorySeparatorChar
if (!$Output.StartsWith($build,[StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $Output)) { throw 'Output must be one NEW named child of game/build' }
$game=Join-Path $Workspace 'game'
$manifestResource='res://art/maps/luoyang_gate_fortification_v3_refined/runtime_manifest.json'
$manifestPath=Join-Path $game $manifestResource.Substring(6)
$manifestSha='6800370f5d343c8212332f497990ee50e4ea0dfb2002319794ed9a69f72009d0'
function Hash([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
if ((Hash $manifestPath) -cne $manifestSha) { throw 'Immutable Gate56 manifest changed' }
$manifest=Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json -AsHashtable
$backup=Join-Path $game 'build/luoyang_gate_import_restore_20261014_system01'
$rowsSpec=@(
 @{id='rock_01_arm_2k';texture='res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_arm_2k.jpg';old='61c7d4a5938895f7ba6411f0839b71038a3b7930faa49b366311e6fb04bf6003'},
 @{id='rock_01_diff_2k';texture='res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_diff_2k.jpg';old='4226182873b5033a1c756cab335ad5e3bac7f3cad80b2d5cfba7ad68682f8c9b'},
 @{id='rock_01_nor_gl_2k';texture='res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_nor_gl_2k.jpg';old='79e15a58ff6040e7bcc11d44df3ffbc1c8370f9b918e1412563e8b569d889b1c'},
 @{id='worn_bluestone_v2';texture='res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png';old='4f9144ae8c4fc6c17427c65647a23e29bfdcdff96752b53bfde8f27372c2c928'}
)
$encoding=[Text.UTF8Encoding]::new($false,$true)
Add-Type -AssemblyName System.Drawing
$preparedRows=@()
# First verify ALL immutable inputs and one-line transforms, before any output.
foreach($spec in $rowsSpec) {
 $texture=[string]$spec.texture
 $raw=Join-Path $game $texture.Substring(6)
 $rawSha=Hash $raw
 if ($rawSha -cne $manifest.asset_sha256[$texture] -or $manifest.asset_sha256[$texture+'.import'] -cne $spec.old) { throw ('Original source pin changed: '+$texture) }
 $name=[IO.Path]::GetFileName($texture)
 $expected=Join-Path $backup ($name+'.import.'+$spec.old.ToUpperInvariant()+'.expected.source')
 if ((Hash $expected) -cne $spec.old) { throw ('Expected full snapshot differs: '+$expected) }
 $bytes=[IO.File]::ReadAllBytes($expected)
 $text=$encoding.GetString($bytes)
 if ([regex]::Matches($text,'(?m)^detect_3d/compress_to=1\r?$').Count -ne 1) { throw 'Expected exactly one detect3D=1 setting' }
 $new=$text.Replace('detect_3d/compress_to=1','detect_3d/compress_to=0')
 if ($new.Replace('detect_3d/compress_to=0','detect_3d/compress_to=1') -cne $text) { throw 'Transform is not exactly reversible one-line change' }
 $remap=[regex]::Match($text,'(?m)^path="(res://\.godot/imported/[^"\r\n]+\.ctex)"\r?$')
 if (!$remap.Success) { throw 'Expected ordinary non-S3TC native CTEX path' }
 $compiled=$remap.Groups[1].Value
 $compiledFile=Join-Path $game $compiled.Substring(6)
 $compiledSha=Hash $compiledFile
 if ($compiledSha -cne $manifest.asset_sha256[$compiled]) { throw ('Original ordinary CTEX changed: '+$compiled) }
 $image=[Drawing.Image]::FromFile($raw)
 try { $dimensions=@($image.Width,$image.Height) } finally { $image.Dispose() }
 $preparedRows+=@{spec=$spec;raw=$raw;raw_sha=$rawSha;size_px=$dimensions;expected=$expected;old_bytes=$bytes;new_bytes=$encoding.GetBytes($new);compiled=$compiled;compiled_file=$compiledFile;compiled_sha=$compiledSha}
}
[IO.Directory]::CreateDirectory($Output)|Out-Null
[IO.Directory]::CreateDirectory((Join-Path $Output 'expected_imports'))|Out-Null
[IO.Directory]::CreateDirectory((Join-Path $Output 'expected_compiled'))|Out-Null
$rows=@()
foreach($inputRow in $preparedRows) {
 $spec=$inputRow.spec
 $texture=[string]$spec.texture
 $target=Join-Path $Output $texture.Substring(6)
 [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))|Out-Null
 [IO.File]::Copy($inputRow.raw,$target,$false)
 # All targets are within the just-created output; CreateNew refuses overwrite.
 $stream=[IO.File]::Open($target+'.import',[IO.FileMode]::CreateNew)
 try { $stream.Write($inputRow.new_bytes,0,$inputRow.new_bytes.Length) } finally { $stream.Dispose() }
 $oldSnapshot='res://expected_imports/'+$spec.id+'.import.source'
 [IO.File]::Copy($inputRow.expected,(Join-Path $Output $oldSnapshot.Substring(6)),$false)
 $oldCompiled='res://expected_compiled/'+[IO.Path]::GetFileName($inputRow.compiled)
 [IO.File]::Copy($inputRow.compiled_file,(Join-Path $Output $oldCompiled.Substring(6)),$false)
 $rows+= [ordered]@{id=$spec.id;texture=$texture;source_sha256=$inputRow.raw_sha;size_px=$inputRow.size_px;old_import_snapshot=$oldSnapshot;old_import_sha256=$spec.old;new_import_path=$texture+'.import';new_import_sha256=(Hash ($target+'.import'));compiled_path=$inputRow.compiled;expected_compiled_snapshot=$oldCompiled;expected_compiled_sha256=$inputRow.compiled_sha;only_import_change='detect_3d/compress_to=1 -> detect_3d/compress_to=0';source_length=(Get-Item -LiteralPath $inputRow.raw).Length;source_mtime_ticks=(Get-Item -LiteralPath $inputRow.raw).LastWriteTimeUtc.Ticks.ToString()}
}
$params=[ordered]@{'compress/mode'=0;'compress/high_quality'=$false;'compress/lossy_quality'=0.7;'compress/uastc_level'=0;'compress/rdo_quality_loss'=0.0;'compress/hdr_compression'=1;'compress/normal_map'=0;'compress/channel_pack'=0;'mipmaps/generate'=$false;'mipmaps/limit'=-1;'roughness/mode'=0;'roughness/src_normal'='';'process/channel_remap/red'=0;'process/channel_remap/green'=1;'process/channel_remap/blue'=2;'process/channel_remap/alpha'=3;'process/fix_alpha_border'=$true;'process/premult_alpha'=$false;'process/normal_map_invert_y'=$false;'process/hdr_as_srgb'=$false;'process/hdr_clamp_exposure'=$false;'process/size_limit'=0;'detect_3d/compress_to'=0}
$prepared=[ordered]@{status='ISOLATED_FOUR_IMPORT_VARIANTS_ONLY_NOT_VERIFIED_OR_PUBLISHED';gate_manifest_path=$manifestResource;gate_manifest_sha256=$manifestSha;rows=$rows;params23=$params;preparation_script_sha256=(Hash $PSCommandPath);live_imports_changed=$false;raw_pixel_edits=$false;old_ctex_expected_exact=$true}
[IO.File]::WriteAllText((Join-Path $Output 'prepared.json'),($prepared|ConvertTo-Json -Depth 12),$encoding)
[IO.File]::WriteAllText((Join-Path $Output 'project.godot'),"config_version=5`n[application]`nconfig/name=`"Gate stable four import variants`"`n[rendering]`nrenderer/rendering_method=`"gl_compatibility`"`n",$encoding)
Write-Output ([ordered]@{output=$Output;prepared_sha256=(Hash (Join-Path $Output 'prepared.json'));project_sha256=(Hash (Join-Path $Output 'project.godot'));rows=$rows;engine_started=$false;live_imports_changed=$false}|ConvertTo-Json -Depth 8)
