$ErrorActionPreference='Stop'
$base='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261025h_qa01'
$helper='F:/Code/RPG_GAME/game/build/luoyang_indoor_services_20261025h_system01/services_runtime01_CANDIDATE.gd'
$parent=Join-Path $base 'service_plan01_NOTREADY.gd'
if((Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash -ne '37F767E67C672A5438E897B76F7852C898128BCD3D26BB352FDE0F92F52DEA5B' -or (Get-FileHash -LiteralPath $parent -Algorithm SHA256).Hash -ne '4B252CD7D627300704A4056E2AFCD999CD6F1D4D104E935950037DC4DE601AE9'){throw 'Fixed parent/helper drift'}
$old=[IO.File]::ReadAllText($parent);$text=$old
function Once([string]$s,[string]$a,[string]$b){if($s.Split($a,[StringSplitOptions]::None).Count -ne 2){throw "Unique $a"};return $s.Replace($a,$b)}
$text=Once $text 'const PLAN_READY25H=false' 'const PLAN_READY25H=true'
$text=Once $text 'service_plan01_output/' 'service_plan01_ROOT_READY_output/'
$text=Once $text '25H_ACTUAL_PURE_PLAN_ONLY_NO_ROOM_UI_OR_OWNER_CREDIT_NOTREADY' '25H_ACTUAL_PURE_PLAN_ONLY_NO_ROOM_UI_OR_OWNER_CREDIT_ROOT_READY'
$target=Join-Path $base 'service_plan01_ROOT_READY.gd';if(Test-Path -LiteralPath $target){throw 'Preserve newkey'}
[IO.File]::WriteAllText($target,$text,[Text.UTF8Encoding]::new($false));$sha=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
if((Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash -ne '37F767E67C672A5438E897B76F7852C898128BCD3D26BB352FDE0F92F52DEA5B'){throw 'Helper moved while freezing; do not run'}
$delta=@{status='ROOT_AUTHORIZED_PURE20CASE_KEY_FREEZE_NOT_EXECUTED';parent=@{path='res://build/luoyang_city_revision_20261025h_qa01/service_plan01_NOTREADY.gd';sha256='4b252cd7d627300704a4056e2afcd999cd6f1d4d104e935950037dc4de601ae9'};child=@{path='res://build/luoyang_city_revision_20261025h_qa01/service_plan01_ROOT_READY.gd';sha256=$sha};old_text=$old;new_text=$text;reverse_old_text=$text;reverse_new_text=$old;helper_sha256_before_after='37f767e67c672a5438e897b76f7852c898128bcd3d26bb352fde0f92f52dea5b';engine_calls=0;Field_calls=0;_data_calls=0;attach_calls=0;production_writes=0}
$dp=Join-Path $base 'service_plan01_ROOT_READY_whole_byte_delta.json';if(Test-Path -LiteralPath $dp){throw 'Preserve delta'};[IO.File]::WriteAllText($dp,(($delta|ConvertTo-Json -Depth 7)+"`n"),[Text.UTF8Encoding]::new($false))
@{key='res://build/luoyang_city_revision_20261025h_qa01/service_plan01_ROOT_READY.gd';sha256=$sha;whole_delta_sha256=(Get-FileHash -LiteralPath $dp -Algorithm SHA256).Hash.ToLowerInvariant();engine_calls=0}|ConvertTo-Json
