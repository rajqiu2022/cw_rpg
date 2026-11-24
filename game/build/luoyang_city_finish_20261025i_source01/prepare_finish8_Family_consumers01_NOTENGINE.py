from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
R='res://build/luoyang_city_finish_20261025i_system01/finish8_runtime07_NOTREADY.gd'
RS='fec8a4e79478c2767941d79c7398f1df635e4e3498589558f74d4008ba9f94be'
A=NS+'original_owner_receipts03_family_weak_snapshot_NOTREADY.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
    with (N/name).open('xb') as f:f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))

adapter_old=(N/'original_owner_receipts02_source_arrays_NOTREADY.gd').read_bytes()
assert sha(adapter_old)=='a427abf67f581e6970135cc4c1fe88393c1db99e9a9cf00b69eaf1dd5f30380a'
ao='var original: Dictionary=family.validation_receipt()'
an='var original: Dictionary=family.original_receipt_for(scene)'
assert adapter_old.decode().count(ao)==1
adapter_bytes=adapter_old.replace(ao.encode(),an.encode())
adapter_name='original_owner_receipts03_family_weak_snapshot_NOTREADY.gd'
if (N/adapter_name).exists():
    assert (N/adapter_name).read_bytes()==adapter_bytes
    adapter=dict(path=NS+adapter_name,sha256=sha(adapter_bytes),bytes=len(adapter_bytes))
else: adapter=emit(adapter_name,adapter_bytes)

common='''const FINISH25I_ENABLED: bool=false
const FINISH25I_RUNTIME: String="@R@"
const FINISH25I_RUNTIME_SHA: String="@RS@"
const FINISH25I_ADAPTER: String="@A@"
const FINISH25I_ADAPTER_SHA: String="@AS@"
static var _finish25i_handle: Variant=null
static var _finish25i_checking: bool=false
static var _finish25i_original_owners: Dictionary={}
static func _finish25i_runtime() -> Variant:
	if not FINISH25I_ENABLED: return null
	if _finish25i_handle!=null: return _finish25i_handle
	if FileAccess.get_sha256(FINISH25I_RUNTIME)!=FINISH25I_RUNTIME_SHA: return null
	var script: Variant=load(FINISH25I_RUNTIME)
	if not script is GDScript or script.resource_path!=FINISH25I_RUNTIME: return null
	_finish25i_handle=script;return script
static func original_receipt_for(scene: SceneScript) -> Dictionary:
	if not FINISH25I_ENABLED or scene==null or scene.map_layout==null: return {}
	var row: Dictionary=_finish25i_original_owners.get(scene.get_instance_id(),{})
	if row.is_empty() or row.scene.get_ref()!=scene or row.layout.get_ref()!=scene.map_layout: return {}
	return row.receipt.duplicate(true)
static func _finish25i_promote_original_final() -> void:
	if not FINISH25I_ENABLED: return
	var actual: Dictionary=validation_receipt()
	if actual.get("finalized")!=true or actual.get("full_source_hash_passes")!=2 or actual.get("source_first")!=actual.get("source_final"): return
	for key: int in _finish25i_original_owners.keys():
		var row: Dictionary=_finish25i_original_owners[key]
		if row.scene.get_ref()==null or row.layout.get_ref()==null:
			_finish25i_original_owners.erase(key);continue
		if row.receipt.get("serial")==actual.get("serial") and row.receipt.get("key")==actual.get("key") and row.receipt.get("source_first")==actual.get("source_first"):
			row.receipt=actual.duplicate(true)
static func _finish25i_ensure(scene: SceneScript) -> bool:
	if not FINISH25I_ENABLED: return true
	# Adapter recursively calls matches; its inner call still executes every old
	# whole-storage guard, but cannot recursively create or finalize a lease.
	if _finish25i_checking: return true
	var runtime: Variant=_finish25i_runtime()
	if runtime==null or scene==null or scene.map_layout==null: return false
	for key: int in _finish25i_original_owners.keys():
		var owner: Dictionary=_finish25i_original_owners[key]
		if owner.scene.get_ref()==null or owner.layout.get_ref()==null: _finish25i_original_owners.erase(key)
	if not _finish25i_original_owners.has(scene.get_instance_id()):
		var first: Dictionary=validation_receipt()
		if int(first.get("serial",0))<=0 or String(first.get("key",""))=="" or not first.get("source_first") is Dictionary or first.source_first.is_empty(): return false
		_finish25i_original_owners[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout),"receipt":first.duplicate(true)}
	if original_receipt_for(scene).is_empty() or FileAccess.get_sha256(FINISH25I_ADAPTER)!=FINISH25I_ADAPTER_SHA: return false
	var adapter: Variant=load(FINISH25I_ADAPTER)
	if not adapter is GDScript or adapter.resource_path!=FINISH25I_ADAPTER: return false
	_finish25i_checking=true
	var receipt: Dictionary=adapter.receipt(scene,null,false)
	_finish25i_checking=false
	if receipt.is_empty(): return false
	return runtime.ensure(scene,receipt.original_native_navigation,receipt.original_parent_blockers,receipt)
static func _finish25i_safe(id: StringName,foot: Vector2) -> bool:
	var runtime: Variant=_finish25i_handle
	if runtime==null or not foot.is_finite(): return false
	for row: Dictionary in _finish25i_original_owners.values():
		var scene: SceneScript=row.scene.get_ref()
		if scene!=null and scene.scene_id==id and row.layout.get_ref()==scene.map_layout and runtime.safe_body(scene,foot): return true
	return false
'''.replace('@R@',R).replace('@RS@',RS).replace('@A@',A).replace('@AS@',adapter['sha256'])

outputs=[]
for kind,path,expected in [
 ('Quarter','scripts/city/luoyang_quarters_family_20261022ap.gd','2e4890fe3f1c25afea01c8395d615496c36b3d581916ea24d0f465722cae63ee'),
 ('Estate','scripts/city/luoyang_estate_family_20261021am.gd','7cd3517bb2b67c007060e9e4f2dcc963aa4f3e3e2e57862f1248718060243d4e')]:
    old=(G/path).read_bytes();assert sha(old)==expected
    t=old.decode('utf-8');hunks=[]
    def change(a,b):
        global t
        assert t.count(a)==1,(kind,a,t.count(a))
        t=t.replace(a,b);hunks.append(dict(old=a,new=b))
    change('extends RefCounted\n','extends RefCounted\n'+common)
    if kind=='Quarter':
        change('_receipt.finalized=true;return true','_receipt.finalized=true;_finish25i_promote_original_final();return true')
        change('if _receipt.get("finalized")==true: return true','if _receipt.get("finalized")==true:\n\t\t_finish25i_promote_original_final();return true')
        start=t.index('static func matches(');end=t.index('static func safe_body(',start)
        block=t[start:end]
        assert block.endswith(';return true\n')
        change(block,block[:-len(';return true\n')]+';return _finish25i_ensure(scene)\n')
        change('static func safe_body(id: StringName,foot: Vector2) -> bool:\n','static func safe_body(id: StringName,foot: Vector2) -> bool:\n\tif FINISH25I_ENABLED and id in IDS: return _finish25i_safe(id,foot)\n')
        change('\tfor p: String in data.source_sha256: out[p]=true\n\treturn out',
               '\tfor p: String in data.source_sha256: out[p]=true\n\tif FINISH25I_ENABLED:\n\t\tvar runtime: Variant=_finish25i_runtime()\n\t\tif runtime==null: return {}\n\t\tfor id: StringName in IDS:\n\t\t\tvar extra: Dictionary=runtime.source_paths_for(id)\n\t\t\tif extra.is_empty(): return {}\n\t\t\tout.merge(extra,true)\n\t\tout[FINISH25I_ADAPTER]=true\n\treturn out')
        change('static func owns_route(source: StringName,target: StringName) -> bool:\n',
               'static func owns_route(source: StringName,target: StringName) -> bool:\n\tif FINISH25I_ENABLED and _finish25i_new_pair(source,target): return _finish25i_runtime()!=null\n')
        pair='''static func _finish25i_new_pair(source: StringName,target: StringName) -> bool:
	return (source==&"ch4_s1_luoyang_yamen" and target==IDS[0]) or (source==IDS[0] and target==&"ch4_s1_luoyang_yamen")
static func _finish25i_new_arrival(source: StringName,target: StringName,authored: Variant,remembered: Variant,destination: SceneScript) -> Dictionary:
	if not authored is Vector2 or destination==null or destination.scene_id!=target or (remembered!=null and not remembered is Vector2): return {}
	if target in IDS and not matches(destination): return {}
	var runtime: Variant=_finish25i_runtime()
	if runtime==null: return {}
	var authority: Dictionary=runtime.authored_arrival(source,target,authored)
	if authority.get("matched")!=true or authority.get("ok")!=true or authority.get("kind")!="ORIGINAL_FIRST_COLD_LEASE": return {}
	var arrival: Vector2=remembered if remembered is Vector2 else authored
	if not arrival.is_finite() or ((arrival-authored)*SIZE).length()>180.0 or not runtime.safe_body(destination,arrival*SIZE): return {}
	return {"spawn":arrival,"source_version":3,"target_version":3,"reason":"finish25i_exact_original_owner_public_pair"}
'''
        change('static func prepare_arrival(source: StringName,target: StringName,authored: Variant,remembered: Variant,destination: SceneScript) -> Dictionary:\n',pair+'static func prepare_arrival(source: StringName,target: StringName,authored: Variant,remembered: Variant,destination: SceneScript) -> Dictionary:\n\tif FINISH25I_ENABLED and _finish25i_new_pair(source,target): return _finish25i_new_arrival(source,target,authored,remembered,destination)\n')
    else:
        change('_validation.finalized=true\n\treturn true','_validation.finalized=true\n\t_finish25i_promote_original_final()\n\treturn true')
        change('if _validation.get("finalized")==true: return true','if _validation.get("finalized")==true:\n\t\t_finish25i_promote_original_final();return true')
        change('B.equal(B.storage(scene.map_layout),prior.packet.layout_storage)\n','B.equal(B.storage(scene.map_layout),prior.packet.layout_storage) and _finish25i_ensure(scene)\n')
        change('\t_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout),"packet":value}\n\treturn true',
               '\t_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout),"packet":value}\n\treturn _finish25i_ensure(scene)')
        change('static func safe_body(foot: Vector2) -> bool:\n','static func safe_body(foot: Vector2) -> bool:\n\tif FINISH25I_ENABLED: return _finish25i_safe(ID,foot)\n')
        change('\tfor path: String in data.source_sha256: paths[path]=true\n\treturn paths',
               '\tfor path: String in data.source_sha256: paths[path]=true\n\tif FINISH25I_ENABLED:\n\t\tvar runtime: Variant=_finish25i_runtime()\n\t\tif runtime==null: return {}\n\t\tvar extra: Dictionary=runtime.source_paths_for(ID)\n\t\tif extra.is_empty(): return {}\n\t\tpaths.merge(extra,true);paths[FINISH25I_ADAPTER]=true\n\treturn paths')
    back=t
    for h in reversed(hunks):
        assert back.count(h['new'])==1
        back=back.replace(h['new'],h['old'])
    assert back.encode('utf-8')==old
    candidate=emit(kind+'_finish8_original_owner01_CANDIDATE.gd',t.encode('utf-8'))
    proof=emit(kind+'_finish8_original_owner01_whole_inverse_BUILD.json',(json.dumps(dict(
      status='CANDIDATE_FALSE_ORIGINAL_FIRST_FINAL_WEAK_OWNER_SNAPSHOT',target='res://'+path,
      parent_sha256=sha(old),parent_bytes=len(old),candidate=candidate,hunks=hunks,
      whole_byte_inverse=True,original_whole_storage_gates_preserved=True,
      no_new_token=True,no_new_validation_begin=True,no_early_finalize=True,
      warm_snapshot_policy='Original per-Scene Weak owner snapshot survives other validation_begin; FINAL promotion only exact same serial/key/source_first after real original finish succeeds.',
      engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    outputs.append(dict(candidate=candidate,proof=proof))
ap=emit('owner_adapter03_family_weak_snapshot_whole_inverse_BUILD.json',(json.dumps(dict(
  parent_sha256=sha(adapter_old),candidate=adapter,hunks=[dict(old=ao,new=an)],whole_byte_inverse=True,
  no_owner_created_by_adapter=True,original_family_matches_remains=True,engine_calls=0),ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print(json.dumps(dict(adapter=adapter,adapter_proof=ap,families=outputs)))
