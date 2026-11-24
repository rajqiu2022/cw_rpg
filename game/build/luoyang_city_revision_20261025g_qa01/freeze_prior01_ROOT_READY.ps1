$ErrorActionPreference='Stop'
$rootPath=[IO.Path]::GetFullPath($PSScriptRoot).Replace('\','/')
$template=Join-Path $PSScriptRoot 'prior01_NOTREADY.gd';$templateSHA='03e4ef77a50625d5ccf4d4ee00501f37caaaa90800628780d986225318825a9a'
$inputPath=Join-Path $PSScriptRoot 'prior01_INPUT_NOTREADY.json';$inputSHA='39febf30db3a961a5f492451b90f00f03a7c2ffbd5669ded03f8528691ed8dc6'
if((Get-FileHash -LiteralPath $template).Hash.ToLowerInvariant()-cne$templateSHA-or(Get-FileHash -LiteralPath $inputPath).Hash.ToLowerInvariant()-cne$inputSHA){throw 'frozen parents'}
$cfg=Get-Content -Raw -LiteralPath $inputPath|ConvertFrom-Json -AsHashtable
foreach($p in $cfg.pins.Keys){if((Get-FileHash -LiteralPath $p).Hash.ToLowerInvariant()-cne$cfg.pins[$p]){throw ('fixed input '+$p)}}
$out=Join-Path $PSScriptRoot 'prior01_ROOT_READY';if(Test-Path -LiteralPath $out){throw 'exclusive new directory'}
$null=New-Item -ItemType Directory -Path $out
function NewText([string]$path,[string]$text){if(Test-Path -LiteralPath $path){throw 'exclusive new file'};[IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false));return (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()}
$cfg.ready=$true
$readyInput=(Join-Path $out 'input_READY.json').Replace('\','/')
$ih=NewText $readyInput ($cfg|ConvertTo-Json -Depth 30)
$reps=@(@{old='const READY25G=false';new='const READY25G=true'},@{old='PENDING_ROOT_FROZEN_INPUT';new=$readyInput},@{old='PENDING_ROOT_FROZEN_SHA';new=$ih})
$old=[IO.File]::ReadAllText($template);$new=$old
foreach($r in $reps){if(([regex]::Matches($new,[regex]::Escape($r.old))).Count-ne1){throw 'unique hunk'};$new=$new.Replace($r.old,$r.new)}
$back=$new;for($i=$reps.Count-1;$i-ge0;$i--){$back=$back.Replace($reps[$i].new,$reps[$i].old)};if($back-cne$old){throw 'whole inverse'}
$sh=NewText (Join-Path $out 'oracle_READY.gd') $new
$proof=@{status='ROOT_READY_INDEPENDENT_LOCAL_PRIOR_NOT_EXECUTED';parent_template_sha256=$templateSHA;parent_input_sha256=$inputSHA;candidate_sha256=$sh;input_sha256=$ih;hunks=$reps;whole_byte_forward_inverse=$true;world_ms=60000;maximum_visited=500000;new_visual_count=45;changed_old_ids=7;added_ids=2;old_geometry_decode_count=1;old_render_packet_decodes=0;parent_raw_PNG_decodes=2;source_asset_PNG_decodes=0;System_pure_or_publisher_calls=0;new_short_route_samples_expected=30;unchanged_NPC_swept_square_superset=$true;old1396_buyer_body_negative_controls=4;new135_only_center_probes=2;all_prior_global87517_route_door_material_portrait_replays=0;engine_calls=0;formal_writes=0;child_RGBA_sha256='UNKNOWN_UNTIL_ROOT_RUN';changed_pixels=$null;visited_pixels=$null;source_texture_alias_note='C210 corridor candidate PNG and approved formal PNG both fixed A335 bytes; immutable geometry donor uses ground_anchor/solid_rects_px field names.'}
$ph=NewText (Join-Path $out 'whole_byte_delta_ROOT_READY.json') ($proof|ConvertTo-Json -Depth 30)
@{script=(Join-Path $out 'oracle_READY.gd');script_sha256=$sh;input_sha256=$ih;proof_sha256=$ph;engine_calls=0}|ConvertTo-Json -Compress
