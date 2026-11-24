"""Only NEW Router/lease candidates, exact pair, original whole-byte inverses."""
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parent
GAME=ROOT.parent.parent
OUT=ROOT/"exact_market_artisan_resident_candidate01"
OUT.mkdir(exist_ok=True)
def sha(b):return hashlib.sha256(b).hexdigest()
def rp(p):return "res://"+str(p.relative_to(GAME)).replace("\\","/")
def save(name,b):
 p=OUT/name;assert not p.exists(),p;p.write_bytes(b)
 return {"path":rp(p),"sha256":sha(b),"bytes":len(b)}
def change(b,old,new,edits,eol="\r\n"):
 old=old.replace("\n",eol).encode();new=new.replace("\n",eol).encode()
 assert b.count(old)==1,old[:140]
 edits.append({"old":old.decode(),"new":new.decode()});return b.replace(old,new,1)
def inverse(b,edits):
 for e in reversed(edits):
  n=e['new'].encode();assert b.count(n)==1;b=b.replace(n,e['old'].encode(),1)
 return b

router_path=GAME/"scripts/autoload/scene_router.gd"
router=router_path.read_bytes()
assert sha(router)=="c3452fd4735cfed1d1bc2b12dbf689b09a46ca093f430ba3ee940241ff443de6"
save("Router_parent_C345.gd",router)
data=router;edits=[]
data=change(data,'const RESIDENT_CITY = preload("res://scripts/city/luoyang_resident_field_20261016.gd")', '''const RESIDENT_CITY = preload("res://scripts/city/luoyang_resident_field_20261016.gd")
const AP_RETURN_SHA = preload("res://scripts/city/luoyang_parallel_source_hash_20261017k.gd")
const AP_LEASE_MARKET := &"ch4_s3_luoyang_market"
const AP_LEASE_ARTISAN := &"luoyang_artisan_residential_20261022ap"''',edits)
data=change(data,'var _resident_return_state: Dictionary = {}','''var _resident_return_state: Dictionary = {}
var _ap_return_source_job: RefCounted = null
var _ap_return_source_task: int = -1''',edits)

park='''func _ap_market_artisan_header() -> Dictionary:
\t# Two literal existing public links only, with their original author feet.
\tvar header: Dictionary=AP_QUARTERS.source_header()
\tif header.is_empty(): return {}
\tvar forward: Dictionary={};var backward: Dictionary={}
\tfor row: Dictionary in header.get("connections",[]):
\t\tif row.get("source")==String(AP_LEASE_MARKET) and row.get("target")==String(AP_LEASE_ARTISAN):
\t\t\tif not forward.is_empty(): return {}
\t\t\tforward=row
\t\tif row.get("source")==String(AP_LEASE_ARTISAN) and row.get("target")==String(AP_LEASE_MARKET):
\t\t\tif not backward.is_empty(): return {}
\t\t\tbackward=row
\tif forward.get("id")!="market_to_artisan" or backward.get("id")!="artisan_to_market" or forward.get("kind")!="PUBLIC_QUARTER_LINK" or backward.get("kind")!="PUBLIC_QUARTER_LINK": return {}
\tif forward.get("source_foot")!=[1100,1860] or forward.get("target_foot")!=[2816,1740] or backward.get("source_foot")!=[2816,1740] or backward.get("target_foot")!=[1100,1860]: return {}
\treturn {"forward":forward,"backward":backward}

func _ap_live_pair_portal(field: Node,source: StringName,target: StringName) -> bool:
\tif not is_instance_valid(field) or not field.is_inside_tree() or not field.get("_exit_nodes") is Array: return false
\tvar source_scene: SceneScript=field.get("_current_scene") as SceneScript
\tif source_scene==null or source_scene.scene_id!=source or field.get("_world_size")!=LUOYANG_V3.SIZE: return false
\tvar expected_pos: Vector2=Vector2(1100,1860) if source==AP_LEASE_MARKET else Vector2(2816,1740)
\tvar expected_target: Vector2=(Vector2(2816,1740) if source==AP_LEASE_MARKET else Vector2(1100,1860))/LUOYANG_V3.SIZE
\tvar count: int=0
\tfor zone: Node in field.get("_exit_nodes"):
\t\tif is_instance_valid(zone) and zone.get("target_scene_id")==String(target):
\t\t\tif zone.get("target_spawn_pos")!=expected_target or zone.get("position")!=(expected_pos/LUOYANG_V3.SIZE)*LUOYANG_V3.SIZE or zone.get("is_locked")!=false or zone.get("action")!="" or zone.get("_in_range")!=true: return false
\t\t\tif not zone is Area2D or not (zone as Area2D).get_overlapping_bodies().has(field.get("_player")): return false
\t\t\tcount+=1
\treturn count==1

func _park_market_for_exact_artisan() -> bool:
\tif OS.has_feature("web") or not RESIDENT_CITY.extended_enabled() or not _resident_return.is_empty() or _resident_city.state().occupied: return false
\tvar field: Node=get_tree().current_scene
\tif not is_instance_valid(field) or not field.has_method("resident_begin_park") or _ap_market_artisan_header().is_empty() or not _ap_live_pair_portal(field,AP_LEASE_MARKET,AP_LEASE_ARTISAN): return false
\tvar scene: SceneScript=field.get("_current_scene") as SceneScript
\tvar foot: Variant=_portal_return_spawns.get(_portal_route_key(AP_LEASE_ARTISAN,AP_LEASE_MARKET))
\tvar authored: Vector2=Vector2(1100,1860)/LUOYANG_V3.SIZE
\t# Keep the existing public-link return policy (author portal UV), not a new
\t# actor movement sample. Actual feet still must be safe and in the real Area.
\tif scene==null or scene.scene_id!=AP_LEASE_MARKET or not foot is Vector2 or foot!=authored or not LUOYANG_V3.safe_body(AP_LEASE_MARKET,foot*LUOYANG_V3.SIZE): return false
\tvar actual: Vector2=field.call("resident_actual_spawn")
\tif not actual.is_finite() or not LUOYANG_V3.safe_body(AP_LEASE_MARKET,actual*LUOYANG_V3.SIZE): return false
\tvar proof: Dictionary=LUOYANG_V3.resident_receipt(scene)
\tif proof.is_empty(): return false
\tvar family: Dictionary=AP_QUARTERS.validation_receipt()
\tif family.get("finalized")!=true or family.get("full_source_hash_passes")!=2 or family.get("source_first")!=family.get("source_final"): return false
\tvar loading: Node=get_node_or_null("/root/LoadingManager")
\tvar mode: int=int(loading.get("_source_process_mode")) if loading!=null and loading.get("_source_field")!=null else field.process_mode
\tif not _resident_city.stage(field,AP_LEASE_ARTISAN,proof,foot,authored,mode,"ap_artisan"): return false
\tif _resident_city.detach(get_tree()): return true
\t_resident_city.release("AP_ARTISAN_DETACH_REFUSED");return false

func park_resident_exterior_for_excursion(destination: StringName) -> bool:
\tif destination==AP_LEASE_ARTISAN: return _park_market_for_exact_artisan()
'''
data=change(data,'func park_resident_exterior_for_excursion(destination: StringName) -> bool:\n',park,edits)
data=change(data,'\tif public_request:\n\t\tvar retained: SceneScript=_resident_city.field.get("_current_scene") as SceneScript','''\tif public_request and _resident_city.excursion_kind=="ap_artisan":
\t\t_resident_city.release("AP_ARTISAN_PUBLIC_RETURN_NOT_AUTHORED");return false
\tif public_request:
\t\tvar retained: SceneScript=_resident_city.field.get("_current_scene") as SceneScript''',edits)
data=change(data,'\telif _resident_city.excursion_kind=="room":','''\telif _resident_city.excursion_kind=="ap_artisan":
\t\tvar source_node: Node=get_tree().current_scene
\t\tvar source_scene: SceneScript=source_node.get("_current_scene") as SceneScript if is_instance_valid(source_node) else null
\t\tvar expected_source: Vector2=Vector2(2816,1740)/LUOYANG_V3.SIZE
\t\tif _current_field_id!=AP_LEASE_ARTISAN or target!=AP_LEASE_MARKET or not action.is_empty() or _ap_market_artisan_header().is_empty() or source_scene==null or not AP_QUARTERS.matches(source_scene) or not _ap_live_pair_portal(source_node,AP_LEASE_ARTISAN,AP_LEASE_MARKET): _resident_city.release("AP_ARTISAN_RETURN_PAIR_DIFFERS");return false
\t\tif not authored is Vector2 or authored!=_resident_city.authored_exit or not source_spawn is Vector2 or source_spawn!=expected_source or not remembered is Vector2 or remembered!=_resident_city.return_spawn or not LUOYANG_V3.safe_body(target,remembered*LUOYANG_V3.SIZE): _resident_city.release("AP_ARTISAN_RETURN_FEET_DIFFERS");return false
\telif _resident_city.excursion_kind=="room":''',edits)

sha_functions='''func _finish_ap_return_source_job(cancel: bool) -> void:
\tif _ap_return_source_job!=null and cancel: _ap_return_source_job.call("request_cancel")
\tif _ap_return_source_task>=0: WorkerThreadPool.wait_for_task_completion(_ap_return_source_task)
\t_ap_return_source_task=-1;_ap_return_source_job=null

func _ap_return_complete_source_sha(context: Dictionary) -> bool:
\tif not _resident_return_owns(context) or _ap_return_source_task>=0 or _ap_return_source_job!=null: return false
\tvar expected: Dictionary=_resident_city.receipt.get("sources",{}).duplicate(true)
\tif expected.is_empty(): return false
\tvar job: RefCounted=AP_RETURN_SHA.new()
\tjob.set("paths",expected.keys());job.set("worker_limit",4)
\t_ap_return_source_job=job
\tvar started: int=Time.get_ticks_usec()
\tvar task: int=WorkerThreadPool.add_task(job.run,false,"Exact AP Market lease complete source SHA")
\tif task<0: _finish_ap_return_source_job(true);return false
\t_ap_return_source_task=task
\t_resident_return_state.phase="VERIFYING_COMPLETE_MARKET_SOURCES"
\twhile _ap_return_source_task==task and not WorkerThreadPool.is_task_completed(task):
\t\tif not _resident_return_owns(context): _finish_ap_return_source_job(true);return false
\t\tawait get_tree().process_frame
\tif not _resident_return_owns(context) or _ap_return_source_task!=task: return false
\tWorkerThreadPool.wait_for_task_completion(task)
\tvar actual: Dictionary=job.get("hashes")
\tvar details: Dictionary=job.call("debug_state")
\t_ap_return_source_task=-1;_ap_return_source_job=null
\tvar valid: bool=details.get("complete")==true and actual.size()==expected.size() and LUOYANG_V3._equal_value(actual,expected)
\t_resident_return_state.source_fresh_sha=valid
\t_resident_return_state.source_hash_passes=1
\t_resident_return_state.source_count=expected.size()
\t_resident_return_state.source_sha_ms=(Time.get_ticks_usec()-started)/1000.0
\t_resident_return_state.source_worker=details
\t_resident_return_state.source_basis="FRESH_COMPLETE_MARKET_SHA_THEN_ORIGINAL_LIVE_IDENTITY_AND_METADATA"
\treturn valid

func _cancel_resident_return(reason: String) -> bool:
\t_finish_ap_return_source_job(true)
'''
data=change(data,'func _cancel_resident_return(reason: String) -> bool:\n',sha_functions,edits)
data=change(data,'\t_resident_return_state.metadata_ms=(Time.get_ticks_usec()-started)/1000.0\n\tif not valid:', '''\t_resident_return_state.metadata_ms=(Time.get_ticks_usec()-started)/1000.0
\tif valid and _resident_city.excursion_kind=="ap_artisan":
\t\tvalid=await _ap_return_complete_source_sha(context)
\t\tif not _resident_return_owns(context): return
\t\t# Full SHA is additional, never a substitute for original live/metadata.
\t\tvalid=valid and _field_preparation_is_current(loading,int(context.token)) and get_tree().current_scene==context.room and _resident_city.identities_match() and LUOYANG_V3.resident_matches(_resident_city.receipt,scene)
\tif not valid:''',edits)

# Only this outbound private portal acquires the LoadingManager Field protocol;
# old city/room/world branches and public enqueue remain unchanged.
data=change(data,'\tvar loading_context := {"title": _loading_title_for_field(scene_id)}\n\tif LUOYANG_V3.is_v3(city_scene) or new_world or revision_room:', '''\tvar loading_context := {"title": _loading_title_for_field(scene_id)}
\tvar exact_ap_excursion: bool=scene_id==AP_LEASE_ARTISAN and not _ap_market_artisan_header().is_empty() and is_instance_valid(get_tree().current_scene) and (get_tree().current_scene.get("_current_scene") as SceneScript)!=null and (get_tree().current_scene.get("_current_scene") as SceneScript).scene_id==AP_LEASE_MARKET
\tif LUOYANG_V3.is_v3(city_scene) or new_world or revision_room or exact_ap_excursion:''',edits)
assert inverse(data,edits)==router
router_row=save("Router_exact_market_artisan_resident_READY.gd",data)

lease_path=GAME/"scripts/city/luoyang_resident_field_20261016.gd"
lease=lease_path.read_bytes();assert sha(lease)=="f1730e461fe6328763cfd70c79b2bbc36c80a2afb7609c364fa7ea7af8acdd7f"
save("Resident_parent_F173.gd",lease)
lease_edits=[]
lease_new=change(lease,'\tif scene==null or not supports_city(scene.scene_id) or kind not in ["room","world"] or (kind=="world" and not extended_enabled()): return false','''\tif scene==null or not supports_city(scene.scene_id) or kind not in ["room","world","ap_artisan"] or (kind=="world" and not extended_enabled()): return false
\tif kind=="ap_artisan" and (not extended_enabled() or scene.scene_id!=CITY or id!=&"luoyang_artisan_residential_20261022ap" or spawn!=Vector2(1100,1860)/Vector2(3072,2048) or authored!=spawn): return false''',lease_edits,"\n")
assert inverse(lease_new,lease_edits)==lease
lease_row=save("Resident_exact_market_artisan_READY.gd",lease_new)
receipt={"status":"NEW_BUILD_ONLY_NOT_ENGINE_CHECKED_NOT_DEPLOYED","targets":[{"canonical":rp(router_path),"parent_sha256":sha(router),"candidate":router_row,"whole_byte_inverse":True,"edits":edits},{"canonical":rp(lease_path),"parent_sha256":sha(lease),"candidate":lease_row,"whole_byte_inverse":True,"edits":lease_edits}],"scope":{"pair":["ch4_s3_luoyang_market","luoyang_artisan_residential_20261022ap"],"new_kind":"ap_artisan","return_policy":"preserve fixed authored public-link portal UV, same as current original E; actual actor must overlap live unlocked ExitZone and safe body","market_foot":[1100,1860],"artisan_foot":[2816,1740],"one_complete_fresh_market_sha_pass_before_attach":True,"original_parallel_worker":"res://scripts/city/luoyang_parallel_source_hash_20261017k.gd","original_worker_sha256":sha((GAME/"scripts/city/luoyang_parallel_source_hash_20261017k.gd").read_bytes()),"same_original_field_then_original_identity_and_metadata":True,"original512MiB_limit":True},"control_flow_review":["original Artisan destination lacked LoadingManager field context; exact outbound context now supplied","private authored route calls _go_field_smart_prepared, never public _enqueue COLD_CITY_REQUEST","_transition_to LEAVING_EXCURSION runs before first park; same-room context retains it on subsequent same route","Artisan field is not C-owned; its exit/discard does not clear retained Market C receipt","Artisan owns separate Scene/layout/packet/motion/actors; Market detached Field own subtree retained","other authored targets release lease via original LEAVING_EXCURSION; public returns explicitly do not use this pair lease","SHA cancellation joins pure-file task/children; ownership loss does not attach; hash or metadata fail original cold fallback remains","attach/resume failure original rollback and safe-body/full collision resume remain"],"preserved":["old room/world branches and public bool contract","source/mask/geometry/native/NPC/route and authored feet","34x24 Player body/speed","original metadata checks before and after attach, C resident_matches, original same-object identity, safe foot and rollback"],"not_claimed":["under10s actual result","Godot parse/worker runtime","global residency or no-load other routes","source finalizer closure"]}
row=save("handoff_READY.json",(json.dumps(receipt,ensure_ascii=False,indent=2)+"\n").encode())
print(json.dumps({"router":router_row,"lease":lease_row,"handoff":row},indent=2))
