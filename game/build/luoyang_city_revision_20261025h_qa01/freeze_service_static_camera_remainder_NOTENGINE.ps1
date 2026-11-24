$ErrorActionPreference='Stop'
$base='F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261025h_qa01';$q='res://build/luoyang_city_revision_20261025h_qa01/'
function Sha($p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
function Write-New($p,$text){if(Test-Path -LiteralPath $p){throw 'Preserve earlier candidate'};[IO.File]::WriteAllText($p,$text,[Text.UTF8Encoding]::new($false))}
function Read-Old($name,$sha){$p=Join-Path $base $name;if((Sha $p)-ne $sha){throw 'Parent drift'};[IO.File]::ReadAllText($p)}
$inverse=@()
$old=Read-Old 'common_ui02_NOTREADY.gd' 'b68662b73bfe7ded0a6cc223207ecb889f2c6dee84932ffdee69d6f13d76e00f';$new=$old
$start=$new.IndexOf('func _room_picture25h(');$end=$new.IndexOf('func _room25h(',$start)
if($start-lt 0-or $end-le $start){throw 'Unique old picture function'}
$replacement=@'
func _room_picture25h(name: String) -> bool:
	var camera: Camera2D=field.get("_world_camera") as Camera2D
	var world: Node2D=field.get("world_container") as Node2D
	if not check(pictures<int(fixture.max_pictures) and Time.get_ticks_msec()<deadline and current_scene==field and camera==null and root.get_camera_2d()==null and field.get("_camera_scroll_enabled")==false and scene.map_layout.design_size==Vector2i(1536,1024) and scene.camera_zoom==1.0 and field.get("_camera_zoom")==1.0 and field.get("_world_size")==Vector2(1920,1280) and world!=null and world.scale==Vector2.ONE and world.position==Vector2(0,-100) and root.get_visible_rect().size==Vector2(1920,1080),"Source static single-screen room: no Camera2D, cover1920x1280 at(0,-100)/scale1, original1920x1080 viewport"): return false
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	if not check(image!=null and image.get_size()==Vector2i(1920,1080),"Original room viewport, no edited composite"): return false
	DirAccess.make_dir_recursive_absolute(output);var path: String=output.path_join(name+".png")
	if not check(not FileAccess.file_exists(path) and image.save_png(path)==OK,"NEW representative image only"): return false
	pictures+=1;records.append({"kind":"25H_ORIGINAL_STATIC_ROOM_PNG_LOCAL_ONLY","path":path,"sha256":FileAccess.get_sha256(path),"camera":"NONE_SOURCE_STATIC_ROOM","world_position":world.position,"world_scale":world.scale,"number":pictures})
	return true
func _room_resume25h(row: Dictionary) -> bool:
	if not check(root.get_node("SceneRouter").call("go_field_smart",StringName(row.room_id),_v(row.approach_uv)),"Necessary same-source QA room setup for remaining UI, no previous body/portrait credit replay") or not await _arrive(StringName(row.room_id),20000,"25H_NECESSARY_REMAINING_UI_ROOM_SETUP_NOT_DEFAULT"): return false
	service25h=field.get("_indoor_services") as RefCounted
	if not check(service25h!=null and service25h.get_script().resource_path==fixture.runtime_path and scene.resource_path==row.scene_path and scene.map_layout.resource_path==row.layout_path,"Necessary correct live service owner before real INPUT, previous71508 source/body prefix retained separately"): return false
	var receipt: Dictionary=service25h.call("debug_state").get("source_receipt",{})
	records.append({"kind":"25H_PASSIVE_NEW_OWNER_NATURAL_SOURCE_SETUP_NOT_PREFIX_RETEST","room":row.room_id,"matched":receipt.get("matched"),"finalized":receipt.get("finalized"),"scope_count":receipt.get("scope_count"),"Field":_id(field),"Scene":_id(scene),"prior_71508_component_credit_not_new_test":true})
	room_refs25h=[weakref(field),weakref(_player()),weakref(scene),weakref(scene.map_layout)]
	await driver.completed_actor_stage()
	return true
'@
$new=$new.Substring(0,$start)+$replacement+"`n"+$new.Substring($end)
Write-New (Join-Path $base 'common_ui03_NOTREADY.gd') $new
$inverse+=@{parent='common_ui02_NOTREADY.gd';child='common_ui03_NOTREADY.gd';old_text=$old;new_text=$new;reverse_old_text=$new;reverse_new_text=$old}
$old=Read-Old 'ui_adapter01_NOTREADY.gd' '47ced78943c2d10d3d78fd06991dc5d9bc38dc37ec178cdd9e3353fb24d818ed';$new=$old
$needle="func enter_and_assert_source_actor(qa: Variant,row: Dictionary) -> bool:`n`treturn await qa._room25h(row)"
if($new.Split($needle,[StringSplitOptions]::None).Count-ne 2){throw 'Exact actor setup method'}
$new=$new.Replace($needle,"func enter_and_assert_source_actor(qa: Variant,row: Dictionary) -> bool:`n`tif row.role==`"pawn`": return await qa._room_resume25h(row)`n`treturn await qa._room25h(row)")
$needle="inn_row=fixture.inn`n`treturn await qa._room25h(inn_row)"
if($new.Split($needle,[StringSplitOptions]::None).Count-ne 2){throw 'Exact inn necessary setup method'}
$new=$new.Replace($needle,"inn_row=fixture.inn`n`treturn await qa._room_resume25h(inn_row)")
Write-New (Join-Path $base 'ui_adapter02_NOTREADY.gd') $new
$inverse+=@{parent='ui_adapter01_NOTREADY.gd';child='ui_adapter02_NOTREADY.gd';old_text=$old;new_text=$new;reverse_old_text=$new;reverse_new_text=$old}
foreach($r in @(@{old='shops03_NOTREADY.gd';sha='b80db079cb08ee3ec8e1761b8df25e552b87e683f8b3a86b8f47b676c3156486';new='shops04_remainder_NOTREADY.gd'},@{old='inn05_NOTREADY.gd';sha='b8e6cbfd45e7db42b977578127746da99d4a0a75dc9899f6d25a2fb47510428d';new='inn06_remainder_NOTREADY.gd'})){
 $old=Read-Old $r.old $r.sha;$new=$old.Replace('common_ui02_NOTREADY.gd','common_ui03_NOTREADY.gd').Replace('ui_adapter01_NOTREADY.gd','ui_adapter02_NOTREADY.gd')
 if($r.old-eq 'shops03_NOTREADY.gd'){$new=$new.Replace('fixture.rooms.size()==4','fixture.rooms.size()==3').Replace('Fixed four NPC/three ShopUI/one inn service menu,60/20/one pawn image','Only remaining pawn/herbal/smith true ShopUIs; inn71508 prefix retained,60/20/one pawn image').Replace('completed25h.size()==4','completed25h.size()==3').Replace('Four actor interactions/three true ShopUIs/one inn local menu; no purchase or gameplay effect','Remaining three true ShopUIs; prior inn/source-body prefixes not claimed again, no purchase/effect').Replace('25H_FOUR_SERVICE_NPCS_THREE_SHOPS_ONE_INN_MENU_ONLY','25H_REMAINING_THREE_SHOPS_INHERIT_INN71508_PREFIX').Replace('/shops03_output/','/shops04_remainder_output/').Replace('25H_SHOPS03_HARDFALSE_SOURCE_FINAL_PENDING','25H_SHOPS04_REMAINDER_HARDFALSE_FINAL_PENDING')}
 else{$new=$new.Replace('/inn05_output/','/inn06_remainder_output/').Replace('25H_INN05_HARDFALSE_FINAL_SOURCE_PENDING','25H_INN06_REMAINDER_HARDFALSE_FINAL_PENDING')}
 Write-New (Join-Path $base $r.new) $new;$inverse+=@{parent=$r.old;child=$r.new;old_text=$old;new_text=$new;reverse_old_text=$new;reverse_new_text=$old}
}
$dp=Join-Path $base 'static_camera_remaining_complete_inverse_NOTRUN.json'
Write-New $dp ((@{status='SOURCE_STATIC_CAMERA_ORACLE_REPAIR_RETAIN_ACTUAL71508_WHOLE_FAIL';changes=$inverse;engine_calls=0;production_writes=0;source_model='Field _should_scroll_camera false for1536x1024; viewport1920x1080; original coverworld1920x1280 zoom1 gives staticorigin(0,-100); no Camera2D';previous_inn_and_pawn_body_source_credit_inherited_not_retested=$true;whole_ms=60000;entry_ms=20000;max_two_service_images=$true}|ConvertTo-Json -Depth 8)+"`n")
$names=@('common_ui03_NOTREADY.gd','ui_adapter02_NOTREADY.gd','shops04_remainder_NOTREADY.gd','inn06_remainder_NOTREADY.gd')
@{inverse_sha256=Sha $dp;files=@($names|ForEach-Object{@{path=$q+$_;sha256=Sha (Join-Path $base $_)}})}|ConvertTo-Json -Depth 5
