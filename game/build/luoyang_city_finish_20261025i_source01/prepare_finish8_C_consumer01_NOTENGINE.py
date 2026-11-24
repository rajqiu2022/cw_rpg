from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;GAME=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
    with (N/name).open('xb') as f:f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))
target='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'
raw=(GAME/target.removeprefix('res://')).read_bytes()
assert sha(raw)=='5ba3e9f62979337c68db86b7533dd50d81c02221d7d568d3b419b970cd20d00f'
t=raw.decode();eol='\r\n' if '\r\n' in t else '\n';hunks=[]
def change(o,n):
    global t
    o=o.replace('\n',eol);n=n.replace('\n',eol)
    assert t.count(o)==1,(o[:120],t.count(o));t=t.replace(o,n);hunks.append(dict(old=o,new=n))
prefix='''# 25i exact terminal lease, after original complete FIRST/storage proof only.
const FINISH25I_ENABLED: bool=false
const FINISH25I_RUNTIME: String="res://build/luoyang_city_finish_20261025i_system01/finish8_runtime07_NOTREADY.gd"
const FINISH25I_RUNTIME_SHA: String="fec8a4e79478c2767941d79c7398f1df635e4e3498589558f74d4008ba9f94be"
const FINISH25I_OWNER: String="res://build/luoyang_city_finish_20261025i_source01/original_owner_receipts02_source_arrays_NOTREADY.gd"
const FINISH25I_OWNER_SHA: String="a427abf67f581e6970135cc4c1fe88393c1db99e9a9cf00b69eaf1dd5f30380a"
const FINISH25I_AMBIENT: String="res://build/luoyang_city_finish_20261025i_system01/ambient18_runtime04_NOTREADY.gd"
const FINISH25I_AMBIENT_SHA: String="44514521029882f84241cc24dce1ae8311e1564b4494fba5274172b29a49fe44"
static var _finish25i_handle: Variant=null
static func _finish25i_runtime() -> Variant:
	if not FINISH25I_ENABLED: return null
	if _finish25i_handle!=null: return _finish25i_handle
	if FileAccess.get_sha256(FINISH25I_RUNTIME)!=FINISH25I_RUNTIME_SHA: return null
	var value: Variant=load(FINISH25I_RUNTIME)
	if not value is GDScript or value.resource_path!=FINISH25I_RUNTIME: return null
	_finish25i_handle=value;return value
static func _finish25i_ensure(scene: SceneScript) -> bool:
	if not FINISH25I_ENABLED or scene==null or not owns_id(scene.scene_id): return not FINISH25I_ENABLED
	var runtime: Variant=_finish25i_runtime()
	if runtime==null or FileAccess.get_sha256(FINISH25I_OWNER)!=FINISH25I_OWNER_SHA: return false
	var adapter: Variant=load(FINISH25I_OWNER)
	var original: Dictionary=adapter.receipt(scene,null,false) if adapter is GDScript else {}
	return not original.is_empty() and runtime.ensure(scene,scene.map_layout.visual_objects,scene.map_layout.blockers,original)
'''
change('extends RefCounted\n','extends RefCounted\n'+prefix)
# Original sync/live proof publication is complete before the new cold lease.
needle='"mask_sha":_transition_bytes_sha(_masks[String(id)].get_data()), "reuses":0}\n\treturn result'
change(needle,'"mask_sha":_transition_bytes_sha(_masks[String(id)].get_data()), "reuses":0}\n\tif FINISH25I_ENABLED and not _finish25i_ensure(result): _fail("Finish25i original FIRST cold lease refused");return null\n\treturn result')
change('\t_record_live_tail_stage(token,id,"tail.proof.publish",tail_started_usec,tail_started_frame)\n\treturn result','\t_record_live_tail_stage(token,id,"tail.proof.publish",tail_started_usec,tail_started_frame)\n\tif FINISH25I_ENABLED and not _finish25i_ensure(result): _fail("Finish25i live original FIRST lease refused");return null\n\treturn result')
change('\t_transition_validation=proof\n\t_live_phase_msec["precomputed_packet_and_materialize"]','\t_transition_validation=proof\n\tif FINISH25I_ENABLED and not _finish25i_ensure(result): job.release();_live_revision_job=null;_fail("Finish25i complete bundle FIRST lease refused");return null\n\t_live_phase_msec["precomputed_packet_and_materialize"]')
sourcehook='''	if FINISH25I_ENABLED:
		var terminal: Variant=_finish25i_runtime()
		if terminal==null: return {}
		var terminal_paths: Dictionary=terminal.source_paths_for(id)
		if terminal_paths.is_empty(): return {}
		paths.merge(terminal_paths);paths[FINISH25I_OWNER]=true
		if FileAccess.get_sha256(FINISH25I_AMBIENT)!=FINISH25I_AMBIENT_SHA: return {}
		var ambient: Variant=load(FINISH25I_AMBIENT)
		var ambient_paths: Dictionary=ambient.source_paths_for(id) if ambient is GDScript else {}
		if ambient_paths.is_empty(): return {}
		paths.merge(ambient_paths)
'''
change('\t# Field-owned additive scenery has the same complete first/final source lease;',sourcehook+'\t# Field-owned additive scenery has the same complete first/final source lease;')
safe='''static func safe_body(id: StringName, point_px: Vector2) -> bool:
	if FINISH25I_ENABLED and owns_id(id):
		var original: Dictionary=_transition_validation if _transition_validation.get("id")==id else (_resident_ready if _resident_ready.get("id")==id else {})
		var scene: SceneScript=original.get("scene") as SceneScript
		var terminal: Variant=_finish25i_runtime()
		# Missing/invalid new lease never falls back to old bare geometry.
		return scene!=null and terminal!=null and not terminal.state_for(scene).is_empty() and terminal.safe_body(scene,point_px)
	return _original_body_safe25i(id,point_px)

static func _original_body_safe25i(id: StringName, point_px: Vector2) -> bool:
'''
change('static func safe_body(id: StringName, point_px: Vector2) -> bool:\n',safe)
change('static func _record_body_safe(point_px: Vector2, id: StringName) -> bool:\n\treturn safe_body(id, point_px)',
       'static func _record_body_safe(point_px: Vector2, id: StringName) -> bool:\n\t# Original authoring checks retain the original private geometry oracle.\n\t# Only post-FIRST public arrivals/live movement use the terminal lease.\n\treturn _original_body_safe25i(id, point_px)')
arrival='''	if FINISH25I_ENABLED:
		var terminal: Variant=_finish25i_runtime()
		if terminal==null: _fail("Finish25i authored arrival source missing");return {}
		var precise: Dictionary=terminal.authored_arrival(source,id,normalized)
		if precise.get("matched")==true:
			if precise.get("ok")!=true or precise.get("kind")!="ORIGINAL_FIRST_COLD_LEASE": _fail("Finish25i exact new public pair refused");return {}
			return {"scene_id":String(id),"spawn":precise.spawn,"source_version":1,"target_version":VERSION,"reason":"finish25i_exact_original_FIRST_public_pair"}
'''
change('\tvar route_key: String = String(source) + "->" + String(id)\n\tif source == &""',arrival+'\tvar route_key: String = String(source) + "->" + String(id)\n\tif source == &""')
back=t
for h in reversed(hunks):
    assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'])
assert back.encode()==raw
candidate=emit('C_finish8_ambient01_CANDIDATE.gd',t.encode())
proof=emit('C_finish8_ambient01_direct_formal_whole_inverse_BUILD.json',(json.dumps(dict(status='HARD_FALSE_FUNCTIONAL_CONSUMER_NOT_STAGE',target=target,parent_sha256=sha(raw),candidate=candidate,hunks=hunks,hunk_count=len(hunks),whole_byte_inverse=True,original_record_layout_storage_unchanged=True,original_private_geometry_checks_preserved=True,hot_IO='Cached runtime handle only; no hash/load/derive per safe query. Existing boundary FIRST/FINAL owns code freshness.',new_fields='Only exact4C Source paths/trueFIRST ensure/newlease safe and2 newly authored city pair arrivals. No new owner/token/whitelist.',engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(candidate=candidate,proof=proof,hunk_count=len(hunks))))
