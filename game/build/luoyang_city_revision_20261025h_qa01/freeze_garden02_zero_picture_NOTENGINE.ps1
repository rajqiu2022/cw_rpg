$ErrorActionPreference='Stop'
$base='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261025h_qa01';$q='res://build/luoyang_city_revision_20261025h_qa01/'
$p=Join-Path $base 'garden01_NOTREADY.gd';if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ne 'B203ABEA88381DE0ED7EA2EFC551D7C3DA16A0A399C7E4FD5EA15921FAF98F70'){throw 'Preserve exact original'}
$old=[IO.File]::ReadAllText($p);$new=$old.Replace('fixture.max_pictures in [0,1]','fixture.max_pictures==0').Replace('60/20/max1 image','60/20/zero actual pictures')
$start=$new.IndexOf('func _picture25h() -> bool:');$end=$new.IndexOf('func exercise_cpu() -> bool:',$start)
if($start-lt 0 -or $end-le $start){throw 'Unique original picture function'}
$replacement="func _picture25h() -> bool:`n`treturn check(pictures==0 and int(fixture.max_pictures)==0 and not String(fixture.inherited_source_art_receipt).is_empty(),`"Root approved native overview inherited by exact source pin; zero actual PNG readback or camera change`")`n"
$new=$new.Substring(0,$start)+$replacement+$new.Substring($end)
$new=$new.Replace('/garden01_output/','/garden02_output/').Replace('25H_GARDEN01_HARDFALSE_FINAL_SOURCE_PENDING','25H_GARDEN02_ZERO_PNG_HARDFALSE_FINAL_SOURCE_PENDING')
$child=Join-Path $base 'garden02_NOTREADY.gd';$dp=Join-Path $base 'garden02_zero_picture_whole_inverse_NOTRUN.json'
foreach($target in @($child,$dp)){if(Test-Path -LiteralPath $target){throw 'NEW only'}}
[IO.File]::WriteAllText($child,$new,[Text.UTF8Encoding]::new($false))
$sha=(Get-FileHash -LiteralPath $child -Algorithm SHA256).Hash.ToLowerInvariant()
$d=@{status='ROOT_APPROVED_ACTUAL_ZERO_PNG_NATIVE_OVERVIEW_INHERITANCE_ONLY';parent_path=$q+'garden01_NOTREADY.gd';parent_sha256='b203abea88381de0ed7ea2efc551d7c3da16a0a399c7e4fd5ea15921faf98f70';child_path=$q+'garden02_NOTREADY.gd';child_sha256=$sha;old_text=$old;new_text=$new;reverse_old_text=$new;reverse_new_text=$old;engine_calls=0;formal_writes=0;previous_routes_and_queries_unchanged=$true}
[IO.File]::WriteAllText($dp,(($d|ConvertTo-Json -Depth 6)+"`n"),[Text.UTF8Encoding]::new($false))
@{key=$q+'garden02_NOTREADY.gd';sha256=$sha;inverse_sha256=(Get-FileHash -LiteralPath $dp -Algorithm SHA256).Hash}|ConvertTo-Json
