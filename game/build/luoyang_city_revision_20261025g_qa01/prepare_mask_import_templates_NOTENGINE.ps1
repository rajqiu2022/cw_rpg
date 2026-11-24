$ErrorActionPreference='Stop'
$game=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function Abs([string]$p){return Join-Path $game $p.Substring(6)}
function NewText([string]$p,[string]$text){if(Test-Path -LiteralPath $p){throw 'exclusive new'};[IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false));return (Get-FileHash -LiteralPath $p).Hash.ToLowerInvariant()}
$base='res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/mask_import01/'
$builder=Abs ($base+'prepare_isolate_NOTENGINE.py');$verifier=Abs ($base+'verify_template_NOTEXEC.gd')
if((Get-FileHash $builder).Hash.ToLowerInvariant()-cne'b1fd66d67c3d7f15d02d4c7d6ce803a9bb12d89496c358cb4afe09ae3598caa0'-or(Get-FileHash $verifier).Hash.ToLowerInvariant()-cne'e08d20c376444c26c556ab364984674b2fff7c6a9cfb74c21a1d66b15750bb1f'){throw 'parent import templates'}
$out=Join-Path $PSScriptRoot 'mask_import01';if(Test-Path -LiteralPath $out){throw 'exclusive namespace'}
$old=[IO.File]::ReadAllText($builder);$text=$old
$reps=@(
 @{old='GAME=HERE.parents[3]';new='GAME=HERE.parents[2]'},
 @{old='luoyang_docks_frontages_mask_20261024e_import01';new='luoyang_market_courtyard_mask_20261025g_import01'},
 @{old="assert pub['status']=='DOCKS_THREE_FRONTAGES_CPU_OVERLAY_BUILD_ONLY' and pub['source_first']==pub['source_final']";new="assert pub['status']=='25G_LOCAL_PUBLICATION_ART_FIELD_SOURCE_PENDING' and pub['source_first']==pub['source_final']"},
 @{old="assert pub['local_geometry_ok'] is True and pub['full_parent_record_inverse'] is True and pub['full_RGBA_inverse'] is True";new="assert pub['parent_count']==43 and pub['child_count']==45 and pub['finite']['ok'] is True and pub['no_old_native_republish'] is True"},
 @{old="assert prior['ready'] is True and prior['passed'] is True and prior['expected_child_RGBA_sha256']==pub['walk_RGBA_sha256']==item['decoded_RGBA_sha256']";new="assert prior['ready'] is True and prior['failures']==0 and prior['full_RGBA_inverse'] is True and prior['outside_domains_unchanged'] is True and prior['expected_child_RGBA_sha256']==pub['walk_RGBA_sha256']==item['decoded_RGBA_sha256']"},
 @{old="assert pub['changed_pixels']==prior['changed_pixels']==206555 and pub['union_visited_pixels']==prior['union_visited_pixels']==311432";new="assert pub['changed_pixels']==prior['changed_pixels']==52354 and pub['visited_pixels']==prior['union_visited_pixels']==147739"},
 @{old="assert pub['domains']==prior['domains']==[[1483,421,2054,640],[272,531,1353,581],[223,1304,852,1510]]";new="assert pub['domains_closed']==[[a,b,c-1,d-1] for a,b,c,d in prior['half_open_domains']] and len(pub['domains_closed'])==10"}
)
foreach($r in $reps){if(([regex]::Matches($text,[regex]::Escape($r.old))).Count-ne1){throw ('unique hunk '+$r.old)};$text=$text.Replace($r.old,$r.new)}
# Label-only replacements are applied consistently to builder and inherited verifier.
$labels=@(@{old='DOCKS_FRONTAGE';new='MARKET_COURTYARD'},@{old='docks_frontage';new='market_courtyard'},@{old='Docks';new='Market Courtyard'},@{old='Docks overlay';new='Market courtyard overlay'})
foreach($r in $labels){$text=$text.Replace($r.old,$r.new)}
$vold=[IO.File]::ReadAllText($verifier);$vnew=$vold;foreach($r in $labels){$vnew=$vnew.Replace($r.old,$r.new)}
$null=New-Item -ItemType Directory -Path $out
$vh=NewText (Join-Path $out 'verify_template_NOTEXEC.gd') $vnew
$bh=NewText (Join-Path $out 'prepare_isolate_NOTENGINE.py') $text
$inputParent=Get-Content -Raw -LiteralPath (Abs ($base+'input_ROOT_READY.json'))|ConvertFrom-Json -AsHashtable
$cfg=$inputParent
$cfg.ready=$false;$cfg.status='ROOT_LOCKED_ONE_MARKET_COURTYARD_OVERLAY_MASK_ISOLATE_PREPARATION';$cfg.required_builder_sha256=$bh
$cfg.verifier_template=@{path='res://build/luoyang_city_revision_20261025g_qa01/mask_import01/verify_template_NOTEXEC.gd';sha256=$vh}
$cfg.publication=@{path='res://build/luoyang_market_courtyard_links_20261025g_system01/publication03/output/115716/overlay_header_NOTREADY.json';sha256='8a1064f33f5c6303e237c4ecb6e6fb31318e926edb58811a09def30d7c059d6e'}
$cfg.independent_prior=@{path='res://build/luoyang_city_revision_20261025g_qa01/prior01_output/33724/prior.json';sha256='4fe0b510d4200243a9f7f935888c5b97e98122439de30d4aafac28d92501f8c5'}
$png='res://build/luoyang_market_courtyard_links_20261025g_system01/publication03/output/115716/walk_overlay.png'
$md5=[Security.Cryptography.MD5]::HashData([Text.Encoding]::UTF8.GetBytes($png));$mh=[Convert]::ToHexString($md5).ToLowerInvariant()
$cfg.texture=@{domain='market_courtyard_overlay';png=$png;png_sha256='b59f79c8b408a326f1571a6918aeaa029328ae3e45083b47d60a7813c47790da';decoded_RGBA_sha256='ea4be52c5a599d2078d10946ea43b78068c7631c26cb1b19859a53264cca2ba1';source_size=@(3072,2048);sidecar=($png+'.import');compiled=('res://.godot/imported/walk_overlay.png-'+$mh+'.ctex')}
$cfg.scope='Only one exact published25g mask in NEW no-autoload isolate. Root sole prepare/import/verify;23 lossless params inherited exactly. Main project never imported. Only two ABSENT sidecar/ctex may later be separately promoted, never PNG/md5. Parent publisher wholeFAIL remains; component mask and independent prior agree, no geometry rerun.'
$cfg.protection='Root final precise guard covers savedata/source; builder fixed7 main paths SHA/bytes/ns and two main targets remainABSENT; verifier repeats full raw/import/directRGBA identity. No asset import.'
$ih=NewText (Join-Path $out 'input_NOTREADY.json') ($cfg|ConvertTo-Json -Depth 40)
$proof=@{status='ONLY_NEW25G_MASK_IMPORT_TEMPLATE_PREPARATION_NOT_RUN';builder_parent_path=($base+'prepare_isolate_NOTENGINE.py');builder_parent_sha256='b1fd66d67c3d7f15d02d4c7d6ce803a9bb12d89496c358cb4afe09ae3598caa0';builder_new_sha256=$bh;builder_hunks=$reps;label_replacements=$labels;verifier_parent_sha256='e08d20c376444c26c556ab364984674b2fff7c6a9cfb74c21a1d66b15750bb1f';verifier_new_sha256=$vh;input_sha256=$ih;exact_params23_unchanged=$true;parent_builder_full_text=$old;new_builder_full_text=$text;parent_verifier_full_text=$vold;new_verifier_full_text=$vnew;whole_byte_inverse_available=$true;publisher_whole_FAIL_preserved=$true;isolate_preparer_calls=0;engine_calls=0;production_promotions=0}
$ph=NewText (Join-Path $out 'whole_byte_delta_NOTRUN.json') ($proof|ConvertTo-Json -Depth 40)
@{builder_sha256=$bh;verifier_sha256=$vh;input_sha256=$ih;proof_sha256=$ph;engine_calls=0}|ConvertTo-Json -Compress
