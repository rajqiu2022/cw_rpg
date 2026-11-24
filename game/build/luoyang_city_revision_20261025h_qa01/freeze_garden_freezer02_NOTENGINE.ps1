$ErrorActionPreference='Stop'
$base='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261025h_qa01'
$p=Join-Path $base 'freeze_garden_UI_READY_NOTENGINE.ps1';if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash-ne 'FAB63A78FFD7C6E208CCB8429106E5C8995FA63AEA420192135FF43DF9ADA274'){throw 'Preserve old freezer'}
$old=[IO.File]::ReadAllText($p);$before="@(`$seed.bridge_png,`$seed.bridge_png+'.import')";$after="@(`$seed.bridge_png,(`$seed.bridge_png+'.import'))"
if($old.Split($before,[StringSplitOptions]::None).Count-ne 2){throw 'Unique tuple expression'};$new=$old.Replace($before,$after)
$cp=Join-Path $base 'freeze_garden_UI_READY02_NOTENGINE.ps1';$dp=Join-Path $base 'garden_freezer02_tuple_expression_inverse_NOTRUN.json'
foreach($target in @($cp,$dp)){if(Test-Path -LiteralPath $target){throw 'NEW only'}}
[IO.File]::WriteAllText($cp,$new,[Text.UTF8Encoding]::new($false))
$d=@{status='ONE_POWERSHELL_TUPLE_EXPRESSION_PARENTHESES_ONLY';parent_sha256='fab63a78ffd7c6e208ccb8429106e5c8995fa63aea420192135ff43df9ada274';child_sha256=(Get-FileHash -LiteralPath $cp -Algorithm SHA256).Hash.ToLowerInvariant();old_text=$old;new_text=$new;reverse_old_text=$new;reverse_new_text=$old;engine_calls=0;formal_writes=0;GDScript_behavior_unchanged=$true;original_freezer_FAIL_preserved=$true}
[IO.File]::WriteAllText($dp,(($d|ConvertTo-Json -Depth 5)+"`n"),[Text.UTF8Encoding]::new($false))
@{freezer_sha256=$d.child_sha256;inverse_sha256=(Get-FileHash -LiteralPath $dp -Algorithm SHA256).Hash}|ConvertTo-Json
