$ErrorActionPreference='Stop'
$base='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261025h_qa01';$q='res://build/luoyang_city_revision_20261025h_qa01/'
function Write-New($p,$v){if(Test-Path -LiteralPath $p){throw "Preserve $p"};[IO.File]::WriteAllText($p,$v,[Text.UTF8Encoding]::new($false))}
$specs=@(
 @{old='common_ui01_NOTREADY.gd';sha='D799166176D5022C2A28A16C668A9EBECDBC91E7F5CAF53526E877EE05A09AB9';new='common_ui02_NOTREADY.gd'},
 @{old='shops02_NOTREADY.gd';sha='1E866A566FB81273B70E8860226F1728D56D9FAEFCAC224F90E3D46217A78A2D';new='shops03_NOTREADY.gd'},
 @{old='inn04_NOTREADY.gd';sha='75BF3264BE93392926675ABC925C811E1BE60F44C2F013452ECA192F9FE918C2';new='inn05_NOTREADY.gd'})
$delta=@()
foreach($spec in $specs){
 $p=Join-Path $base $spec.old;if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ne $spec.sha){throw 'Parent drift'}
 $old=[IO.File]::ReadAllText($p);$new=$old
 if($spec.old -eq 'common_ui01_NOTREADY.gd'){
  $needle="`tvar actors: Array=[]"
  if($old.Split($needle,[StringSplitOptions]::None).Count-ne 2){throw 'Unique receipt insertion'}
  $block=@'
	var receipt: Dictionary=service25h.call("debug_state").get("source_receipt",{})
	var expected_scope: Dictionary=row.expected_service_sources
	if not check(not expected_scope.is_empty() and receipt.get("matched")==true and receipt.get("finalized")==true and receipt.get("scene_id")==row.room_id and receipt.get("scene")==scene.get_instance_id() and receipt.get("layout")==scene.map_layout.get_instance_id() and receipt.get("field")==field.get_instance_id() and receipt.get("revision")==field.get("_city3_motion_revision") and receipt.get("scope_count")==expected_scope.size() and receipt.get("source_first",{})==expected_scope and receipt.get("source_final",{})==expected_scope,"Natural service FIRST/FINAL exact independent room scope and current weak-owner IDs/revision; no collector"): return false
	records.append({"kind":"25H_NATURAL_SERVICE_SOURCE_FIRST_FINAL_EXACT","room":row.room_id,"scope_count":expected_scope.size(),"Field":_id(field),"Scene":_id(scene),"layout":_id(scene.map_layout),"revision":receipt.revision,"preparation_token":str(receipt.preparation_token),"QA_collector_or_finalize_calls":0})
'@
  $new=$new.Replace($needle,$block+"`n"+$needle)
 }else{
  $new=$new.Replace('common_ui01_NOTREADY.gd','common_ui02_NOTREADY.gd')
  if($spec.old -eq 'shops02_NOTREADY.gd'){$new=$new.Replace('/shops02_output/','/shops03_output/').Replace('25H_SHOPS02_HARDFALSE_SOURCE_FINAL_PENDING','25H_SHOPS03_HARDFALSE_SOURCE_FINAL_PENDING')}
  else{$new=$new.Replace('/inn04_output/','/inn05_output/').Replace('25H_INN04_HARDFALSE_FINAL_SOURCE_PENDING','25H_INN05_HARDFALSE_FINAL_SOURCE_PENDING')}
 }
 $child=Join-Path $base $spec.new;Write-New $child $new
 $delta+=@{parent_path=$q+$spec.old;parent_sha256=$spec.sha.ToLowerInvariant();child_path=$q+$spec.new;child_sha256=(Get-FileHash -LiteralPath $child -Algorithm SHA256).Hash.ToLowerInvariant();old_text=$old;new_text=$new;reverse_old_text=$new;reverse_new_text=$old}
}
$out=Join-Path $base 'ui_scope05_whole_byte_inverse_NOTRUN.json'
Write-New $out ((@{status='ROOT_APPROVED_ONCE_PER_ROOM_SOURCE_RECEIPT_ONLY_HARDFALSE';ready=$false;changes=$delta;engine_calls=0;production_writes=0;other_eight_rooms_tested=0;whole_ms=60000;each_entry_ms=20000;max_pictures_per_key=1}|ConvertTo-Json -Depth 9)+"`n")
@{delta_sha256=(Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash;files=@($delta|ForEach-Object{@{path=$_.child_path;sha256=$_.child_sha256}})}|ConvertTo-Json -Depth 5
