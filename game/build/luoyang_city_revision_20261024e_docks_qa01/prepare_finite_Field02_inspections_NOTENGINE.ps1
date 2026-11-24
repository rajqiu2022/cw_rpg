$ErrorActionPreference='Stop'
$parent=Join-Path $PSScriptRoot 'finite_Field01_NOTREADY/test_NOTREADY.gd'
$out=Join-Path $PSScriptRoot 'finite_Field02_INSPECTIONS_NOTREADY'
if((Get-FileHash -LiteralPath $parent).Hash -cne '002DD93213B25018A5AA49604B6B19A1F80B1CFD8B3EA7730CA57C9BE742718D'){throw 'immutable parent changed'}
if(Test-Path -LiteralPath $out){throw 'NEW directory only'}
$pose=@'
func _inspection_start(at: Vector2,index: int) -> bool:
	if not check(inspection_writes==index and index<3 and _clear(at) and C.safe_body(DOCKS,at),"Root-approved source body/17mask/real Physics before inspection pose"): return false
	var before: Vector2=_player().position
	driver.release_movement()
	# Existing Player motion API zeroes velocity while retaining its can_move state.
	_player().set_can_move(_player().can_move)
	_player().position=at;inspection_writes+=1
	_player().reset_physics_interpolation()
	await physics_frame
	records.append({"kind":"ROOT_APPROVED_INSPECTION_POSITION_NOT_TRAVEL_OR_PERFORMANCE","index":index,"before":before,"fixed_start":at,"actual":_player().position,"position_writes":inspection_writes,"original_motion_API":"Player.set_can_move(existing); reset_physics_interpolation","NPC_camera_speed_changes":0,"continuous_connection_travel_credit":false})
	return check(_player().position==at and _clear(at) and C.safe_body(DOCKS,at),"Same live Field inspection pose after actual Physics; no endpoint relaxation")

'@
$pose=$pose.Replace('\t',"`t").Replace("`r`n","`n")
$reps=@(
 @{old='## No old packet/mask/route matrix/NPC replay. All connectors and approaches are INPUT.';new='## Root approved exactly3 inspection poses, then short INPUT. No connection-travel credit.'},
 @{old='finite_Field01_NOTREADY/fixture_PENDING_FINAL_SOURCE.json';new='finite_Field02_INSPECTIONS_NOTREADY/fixture_PENDING_FINAL_SOURCE.json'},
 @{old="var dock_mask: Image=null`n";new="var dock_mask: Image=null`nvar inspection_writes: int=0`n"},
 @{old='fixture.paths.approaches.size()==3 and fixture.paths.connectors.size()==3';new='fixture.paths.approaches.size()==3 and fixture.inspection_starts==[[600,1610],[1860,748],[638,670]] and fixture.Root_authorized_inspection_position_writes==3'},
 @{old='func exercise_cpu() -> bool:';new=($pose+"`nfunc exercise_cpu() -> bool:")},
 @{old='if not await _walk(fixture.paths.connectors[i],"NECESSARY_CONNECTOR_NOT_OLD_ROUTE_REPLAY_%d"%i): return false';new='if not await _inspection_start(_v(fixture.inspection_starts[i]),i): return false'},
 @{old='space_calls==2,"Warehouse true exact remembered foot/2Space/gameplay unchanged"';new='space_calls==2 and inspection_writes==3,"Warehouse exact foot/2Space/3explicit inspection poses/gameplay unchanged"'},
 @{old='finite_Field01_output/';new='finite_Field02_output/'},
 @{old='"Player_or_camera_position_writes":0';new='"Player_inspection_position_writes":inspection_writes,"Camera_position_writes":0,"continuous_connection_travel_credit":false'},
 @{old='DOCKS_THREE_FRONTAGES_NEW_NAV_LEASE_REAL_WAREHOUSE_RETURN_TEMPLATE_NOTREADY';new='DOCKS_THREE_FRONTAGES_3INSPECTION_SHORT_INPUT_NAV_LEASE_TRUE_WAREHOUSE_RETURN_NOTREADY'}
)
$old=[IO.File]::ReadAllText($parent);$new=$old
foreach($r in $reps){if(([regex]::Matches($new,[regex]::Escape($r.old))).Count -ne 1){throw ('not unique: '+$r.old)};$new=$new.Replace($r.old,$r.new)}
$back=$new;for($i=$reps.Count-1;$i -ge 0;$i--){$back=$back.Replace($reps[$i].new,$reps[$i].old)}
if($back -cne $old){throw 'whole inverse failed'}
$null=New-Item -ItemType Directory -Path $out
[IO.File]::WriteAllText((Join-Path $out 'test_NOTREADY.gd'),$new,[Text.UTF8Encoding]::new($false))
$sha=(Get-FileHash -LiteralPath (Join-Path $out 'test_NOTREADY.gd')).Hash
$proof=@{status='ROOT_APPROVED_3_INSPECTIONS_TEMPLATE_ONLY_NO_ENGINE';parent_sha256='002DD93213B25018A5AA49604B6B19A1F80B1CFD8B3EA7730CA57C9BE742718D';candidate_sha256=$sha;hunks=$reps;whole_forward_inverse_exact=$true;ready=$false;formal_deployed=$false;engine_runs=0;formal_writes=0;whole_ms=60000;entry_ms=20000;Player_inspection_writes=3;Camera_writes=0;prior_routes_NPC_packet_or_fullmask_replay=0;source_helper_map_and_deployment_pending=$true}
[IO.File]::WriteAllText((Join-Path $out 'whole_byte_delta_NOTREADY.json'),($proof|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($false))
@{script_sha256=$sha;proof_sha256=(Get-FileHash -LiteralPath (Join-Path $out 'whole_byte_delta_NOTREADY.json')).Hash}|ConvertTo-Json -Compress
