from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
    with (N/name).open('xb') as f:f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))
helper_path=NS+'artisan_existing_rooms_return_projection01_NOTREADY.gd'
helper=(N/'artisan_existing_rooms_return_projection01_NOTREADY.gd').read_bytes()
rel='scripts/city/luoyang_assembled_interiors_20261016g.gd';old=(G/rel).read_bytes()
assert sha(old)=='537ca3d782a97144a19c6f22683833f4541640deb4a8fc981daf e3a790d09105'.replace(' ','')
t=old.decode('utf-8');hunks=[]
def change(o,n):
    global t
    assert t.count(o)==1,(o,t.count(o));t=t.replace(o,n);hunks.append(dict(old=o,new=n))
header='''const FINISH25I_RETURNS_ENABLED: bool=false
const FINISH25I_RETURNS: String="@P@"
const FINISH25I_RETURNS_SHA: String="@S@"
static var _finish25i_returns_handle: Variant=null
static func _finish25i_returns() -> Variant:
	if not FINISH25I_RETURNS_ENABLED: return null
	if _finish25i_returns_handle!=null: return _finish25i_returns_handle
	if FileAccess.get_sha256(FINISH25I_RETURNS)!=FINISH25I_RETURNS_SHA: return null
	var value: Variant=load(FINISH25I_RETURNS)
	if not value is GDScript or value.resource_path!=FINISH25I_RETURNS or not value.source_bound(): return null
	_finish25i_returns_handle=value;return value
'''.replace('@P@',helper_path).replace('@S@',sha(helper))
change('extends RefCounted\n','extends RefCounted\n'+header)
change('\treturn paths\nstatic func storage_for(','''	if FINISH25I_RETURNS_ENABLED:
		var finish_returns: Variant=_finish25i_returns()
		if finish_returns==null: return {}
		paths.merge(finish_returns.source_paths(),true)
	return paths
static func storage_for(''')
change('static func return_binding(id: StringName) -> Dictionary:\n', '''static func return_binding(id: StringName) -> Dictionary:
	var parent: Dictionary=_original_return_binding_finish25i(id)
	if not FINISH25I_RETURNS_ENABLED: return parent
	var finish_returns: Variant=_finish25i_returns()
	return finish_returns.room_binding(id,parent) if finish_returns!=null else {}
static func _original_return_binding_finish25i(id: StringName) -> Dictionary:
''')
change('static func project_portals(scene: SceneScript,original: Array) -> Dictionary:\n','''static func project_portals(scene: SceneScript,original: Array) -> Dictionary:
	var parent: Dictionary=_original_project_portals_finish25i(scene,original)
	if not FINISH25I_RETURNS_ENABLED or parent.get("ok")!=true: return parent
	var finish_returns: Variant=_finish25i_returns()
	if finish_returns==null: return {"ok":false,"error":"ARTISAN25I_RETURNS_SOURCE","portals":[]}
	if scene!=null and finish_returns.owns(scene.scene_id) and not matches(scene,scene.scene_id): return {"ok":false,"error":"ARTISAN25I_ORIGINAL_ROOM_NATIVE_STORAGE","portals":[]}
	return finish_returns.portals(scene,parent.portals)
static func _original_project_portals_finish25i(scene: SceneScript,original: Array) -> Dictionary:
''')
back=t
for h in reversed(hunks):back=back.replace(h['new'],h['old'])
assert back.encode('utf-8')==old
c=emit('G_finish8_artisan_returns01_CANDIDATE.gd',t.encode('utf-8'))
p=emit('G_finish8_artisan_returns01_whole_inverse_BUILD.json',(json.dumps(dict(status='HARD_FALSE_THREE_EXISTING_ROOMS_TERMINAL_RETURNS_ONLY',target='res://'+rel,parent_sha256=sha(old),candidate=c,helper=dict(path=helper_path,sha256=sha(helper),bytes=len(helper)),hunks=hunks,whole_byte_inverse=True,original_project_portals_all_gates_first=True,original_12native_registry_geometry_and_service_unchanged=True,new_shared_ordinary_leaf_count=2,engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print(json.dumps(dict(candidate=c,proof=p,helper_sha256=sha(helper))))
