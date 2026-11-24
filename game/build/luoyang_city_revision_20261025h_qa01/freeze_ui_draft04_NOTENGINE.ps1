$ErrorActionPreference='Stop'
$base='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261025h_qa01'
$q='res://build/luoyang_city_revision_20261025h_qa01/'
function Write-New($p,$v){if(Test-Path -LiteralPath $p){throw "Preserve $p"};[IO.File]::WriteAllText($p,$v,[Text.UTF8Encoding]::new($false))}
$parent=Join-Path $base 'inn03_NOTREADY.gd'
if((Get-FileHash -LiteralPath $parent -Algorithm SHA256).Hash -ne 'AD1D2E91036EFE261E9C7394852ACD76CC92D01002714B79D76BAEBA7A78352F'){throw 'Preserve parent byte identity'}
$old=[IO.File]::ReadAllText($parent);$new=$old
$before='hero.max_hp=109;hero.max_mp=43;gs25h.set("gold",4);_notify25h()'
$after='hero.max_hp=109;hero.max_mp=43;gs25h.set("gold",4 if service=="meal" else 20);_notify25h()'
if($new.Split($before,[StringSplitOptions]::None).Count-ne 2){throw 'Unique late current-state hunk'}
$new=$new.Replace($before,$after)
$before='if not await _one25h("meal","confirm",40,"damaged",true): return false'
if($new.Split($before,[StringSplitOptions]::None).Count-ne 2){throw 'Unique late current-state case'}
$new=$new.Replace($before,$before+"`n`t"+'if not await _one25h("lodging","confirm",40,"damaged",true): return false')
$new=$new.Replace('/inn03_output/','/inn04_output/').Replace('25H_INN03_HARDFALSE_FINAL_SOURCE_PENDING','25H_INN04_HARDFALSE_FINAL_SOURCE_PENDING')
$child=Join-Path $base 'inn04_NOTREADY.gd';Write-New $child $new
$delta=@{status='UI_DRAFT04_LATE_CURRENT_MAX_POSITIVE_REST_ONLY_NO_EXECUTION';parent_path=$q+'inn03_NOTREADY.gd';parent_sha256='ad1d2e91036efe261e9c7394852acd76cc92d01002714b79d76baeba7a78352f';child_path=$q+'inn04_NOTREADY.gd';child_sha256=(Get-FileHash -LiteralPath $child -Algorithm SHA256).Hash.ToLowerInvariant();old_text=$old;new_text=$new;reverse_old_text=$new;reverse_new_text=$old;engine_calls=0;formal_writes=0;scope='Same60/20, one inn image. Added one true rest confirmation with current max/gold changed after confirmation appears; existing late meal insufficient case retained. No pure matrix replay.'}
$dp=Join-Path $base 'inn04_whole_byte_inverse_NOTRUN.json';Write-New $dp (($delta|ConvertTo-Json -Depth 5)+"`n")
$files=@('common_ui01_NOTREADY.gd','ui_adapter01_NOTREADY.gd','shops02_NOTREADY.gd','inn04_NOTREADY.gd','service_oracle_NOTREADY.gd')
$rows=@();foreach($name in $files){$p=Join-Path $base $name;$rows+=@{path=$q+$name;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant();bytes=(Get-Item -LiteralPath $p).Length}}
$manifest=@{status='FOUR_KEEPERS_REAL_UI_ADAPTER_HARDFALSE_SOURCE_MAP_PENDING';ready=$false;formal_deployed=$false;files=$rows;whole_ms=60000;each_entry_ms=20000;max_pictures=@{shops=1;inn=1};positive_interaction='Real Space/numeric keys and ShopUI CloseBtn pointer; no direct helper.open/DP.play/go_shop/NPC signal';manual_finish='NEGATIVE replay and actual old-owner lifecycle only';no_engine_run=$true;no_formal_writes=$true;preserved_pure_credit='Root79460407_28checks_20cases_no_replay';inn03_preserved=$true}
$mp=Join-Path $base 'ui_draft04_manifest_NOTREADY.json';Write-New $mp (($manifest|ConvertTo-Json -Depth 8)+"`n")
@{manifest_sha256=(Get-FileHash -LiteralPath $mp -Algorithm SHA256).Hash;inn_delta_sha256=(Get-FileHash -LiteralPath $dp -Algorithm SHA256).Hash;files=$rows}|ConvertTo-Json -Depth 8
