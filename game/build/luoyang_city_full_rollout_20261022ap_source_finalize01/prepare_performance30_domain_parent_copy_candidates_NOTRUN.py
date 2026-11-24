"""NEW build-only domain copies and deferred B child. Never run Godot."""
import difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance30_domain_parent_copy_candidate01/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def apply(source,hunks):
    out=source
    for h in hunks:
        a,b=h['old'].encode(),h['new'].encode();assert out.count(a)==1;out=out.replace(a,b,1)
    inverse=out
    for h in reversed(hunks):
        a,b=h['new'].encode(),h['old'].encode();assert inverse.count(a)==1;inverse=inverse.replace(a,b,1)
    assert inverse==source
    return out
ap=S+'finite_adapter_production08/finite_adapter_READY.gd';as_='999a687a1c6ed70a010e9b46c4c1fe4ce2a86b7cb2ca51b3a745c7e153a15e90'
bp='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd';bs='9d5b9b379f5e7962d91550a95b2b9a12a35b98d7fb4402cdfa5947e7152f9e54'
adapter=fixed(ap,as_);bundle=fixed(bp,bs)
# Every original control-flow line keeps its original CRLF. Only new lines use
# the same existing CRLF; no global normalization or formatting is performed.
def a(s):return s.replace('\n','\r\n')
ah=[
 {'old':a('static func _map_parent(scene: SceneScript,current: Dictionary,data: Dictionary,state: Dictionary,domain: String) -> Dictionary:\n'),
  'new':a('static func _copy_parent_pair(parent: Dictionary,domain: String) -> Dictionary:\n\t# Internal exact-domain schema: preserve TWO independent deep copies.\n\t# No source/session credit here; _map_parent calls only after all gates.\n\tif domain=="yamen":\n\t\treturn {"ok":true,"current_t_record":parent.duplicate(true),"frozen_t_record":parent.duplicate(true)}\n\tif domain=="market":\n\t\treturn {"ok":true,"current_ap_record":parent.duplicate(true),"frozen_ap_record":parent.duplicate(true)}\n\treturn {}\nstatic func _map_parent(scene: SceneScript,current: Dictionary,data: Dictionary,state: Dictionary,domain: String) -> Dictionary:\n\tif domain not in ["yamen","market"]: return {}\n')},
 {'old':a('\treturn {"ok":true,"current_t_record":parent.duplicate(true),"frozen_t_record":parent.duplicate(true),"current_ap_record":parent.duplicate(true),"frozen_ap_record":parent.duplicate(true)}\n'),
  'new':a('\treturn _copy_parent_pair(parent,domain)\n')}
]
bh=[
 {'old':a('\tvar child: Dictionary=data.record.duplicate(true); var prior: Dictionary=data.t_parent_record.duplicate(true)\n'),
  'new':a('\tvar child: Dictionary={}; var prior: Dictionary=data.t_parent_record.duplicate(true)\n')},
 {'old':a('\t\tcurrent=restored_ap.current_ap_record; child=restored_ap.frozen_ap_record\n'),
  'new':a('\t\tcurrent=restored_ap.current_ap_record; child=restored_ap.frozen_ap_record\n\t# A requested finite mapping either supplied independent child or refused.\n\t# Only the unchanged nonfinite path needs this original deep copy.\n\tif not yamen_state.get("requested",false) and not market_state.get("requested",false):\n\t\tchild=data.record.duplicate(true)\n')}
]
newa=apply(adapter,ah);newb=apply(bundle,bh)
newap=O+'finite_adapter_domain_copies_CANDIDATE.gd';newbp=O+'Bundle_deferred_finite_child_CANDIDATE.gd'
reportpath='res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s1_luoyang_yamen/packet.bin'
reportsha='04f2d7f253b229e924211a0e241750bd5013ef96dd63794f2ce8b7380d9da7df'
fixture={'status':'PENDING_ROOT_SINGLE_FIXED_RECORD_COPY_COMPARISON_NOT_FIELD_OR_NATIVE_DOMAIN_CREDIT','ready':False,
 'blockers':['Root and QA must review candidates and exact pure-copy key before any engine execution'],
 'source_sha256':{ap:as_,bp:bs,newap:sha(newa),newbp:sha(newb),reportpath:reportsha},
 'old_adapter_path':ap,'candidate_adapter_path':newap,'fixed_T_packet_path':reportpath,
 'large_case':'One fixed04F2 T packet bytes_to_var decode, record only, Yamen pair only. No claim of Market actual shape or Field timing.',
 'tiny_case':'Typed plain Dictionary with nested ordinary arrays, StringName key/value, Vector2 and PackedInt32Array; clone-isolation checks only, no equality-helper expansion.',
 'old_reference':'Exact original adapter319 return expression (four separate deep copies), tested as pure copy operation, not substitute _map_parent/session validation.',
 'timing':'Only old four-copy reference and candidate two-copy helper wall times; all equality, mutation, SHA, source parsing outside timer; fixed order/cache bias; no performance threshold.',
 'future_binary_packet_decode_count':1,'ResourceLoader_res_Field_Scene_geometry_image_collector_calls':0}
fp=O+'parent_copy_comparison_fixture_PENDING_ROOT.json';fb=js(fixture)
key=r'''extends SceneTree
const FIXTURE="__FIXTURE__"
const FIXTURE_SHA="__FIXTURE_SHA__"
var checks: int=0
var errors: Array=[]
var rows: Array=[]
var packet_decodes: int=0
func check(value: bool,label: String) -> bool:
	checks+=1
	if not value: errors.append(label)
	return value
func _initialize() -> void: call_deferred("_run")
func old_four_copy_reference(parent: Dictionary) -> Dictionary:
	return {"ok":true,"current_t_record":parent.duplicate(true),"frozen_t_record":parent.duplicate(true),"current_ap_record":parent.duplicate(true),"frozen_ap_record":parent.duplicate(true)}
func compare_one(old: Variant,candidate: Variant,parent: Dictionary,domain: String,label: String) -> void:
	var before: int=Time.get_ticks_usec()
	var baseline: Dictionary=old_four_copy_reference(parent)
	var old_usec: int=Time.get_ticks_usec()-before
	before=Time.get_ticks_usec()
	var proposed: Dictionary=candidate._copy_parent_pair(parent,domain)
	var new_usec: int=Time.get_ticks_usec()-before
	# All whole comparisons, deep clones and mutations below are OUTSIDE timers.
	var current_key: String="current_t_record" if domain=="yamen" else "current_ap_record"
	var frozen_key: String="frozen_t_record" if domain=="yamen" else "frozen_ap_record"
	var omitted: Array=["current_ap_record","frozen_ap_record"] if domain=="yamen" else ["current_t_record","frozen_t_record"]
	check(proposed.size()==3 and proposed.get("ok")==true,label+": exact ok plus two domain records")
	check(not proposed.has(omitted[0]) and not proposed.has(omitted[1]),label+": no unused other-domain records")
	check(old._same(proposed.get(current_key),baseline[current_key]) and old._same(proposed.get(frozen_key),baseline[frozen_key]),label+": both retained whole trees match old reference")
	check(old._same(proposed[current_key],parent) and old._same(proposed[frozen_key],parent),label+": source whole tree retained")
	var original: Dictionary=parent.duplicate(true)
	proposed[current_key]["__copy_isolation_probe__"]={"rows":[{"value":1}]}
	check(old._same(proposed[frozen_key],original) and old._same(parent,original),label+": current root mutation does not escape")
	proposed[frozen_key]["__frozen_probe__"]=true
	check(not proposed[current_key].has("__frozen_probe__") and old._same(parent,original),label+": frozen mutation does not escape")
	if label.begins_with("single large"):
		var field: String="material_binding_evidence"
		var marker: String="__nested_copy_isolation_probe__"
		check(parent[field] is Dictionary and not parent[field].has(marker),label+": fixed nested dictionary is unmarked")
		proposed[current_key][field][marker]=true
		check(not proposed[frozen_key][field].has(marker) and not parent[field].has(marker),label+": nested current mutation isolated")
		proposed[current_key][field].erase(marker)
		proposed[frozen_key][field][marker]=true
		check(not proposed[current_key][field].has(marker) and not parent[field].has(marker),label+": nested frozen mutation isolated")
		proposed[frozen_key][field].erase(marker)
		check(old._same(proposed[current_key][field],original[field]) and old._same(proposed[frozen_key][field],original[field]),label+": removed test markers restore nested whole values")
	rows.append({"label":label,"domain":domain,"old_four_copy_wall_usec":old_usec,"candidate_two_copy_wall_usec":new_usec,"all_checks_and_mutations_outside_timers":true,"no_Field_or_stable_speed_claim":true})
func finish() -> void:
	var root: String="__OUTPUT__/output/%d_%d"%[OS.get_process_id(),Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(root)
	var file: FileAccess=FileAccess.open(root+"/result.json",FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify({"status":"PURE_DOMAIN_PARENT_COPY_COMPARISON_NOT_FIELD_OR_MARKET_NATIVE_SHAPE_CREDIT","passed":errors.is_empty(),"checks":checks,"errors":errors,"rows":rows,"binary_packet_decodes":packet_decodes,"Field_Scene_geometry_image_collector_calls":0,"timed_copy_only_fixed_order_cache_bias":true},"  ",true,true)+"\n")
	file.close();print("DOMAIN_PARENT_COPY_RESULT "+root+"/result.json");quit(0 if errors.is_empty() else 1)
func _run() -> void:
	if not check(FileAccess.get_sha256(FIXTURE)==FIXTURE_SHA,"Fixed pending fixture SHA"): finish();return
	var fixture: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not check(fixture is Dictionary and fixture.get("ready")==true,"Root NEW ready freeze required; pending never admits"): finish();return
	for path: String in fixture.source_sha256:
		if not check(FileAccess.get_sha256(path)==fixture.source_sha256[path],"Fixed before "+path): finish();return
	var old: Variant=load(fixture.old_adapter_path)
	var candidate: Variant=load(fixture.candidate_adapter_path)
	if not check(old is GDScript and candidate is GDScript,"Fixed two pure scripts"): finish();return
	var tiny: Dictionary={"nested":{"rows":[{&"id":&"copyprobe","foot":Vector2(1,2),"values":PackedInt32Array([1,2])}]}}
	compare_one(old,candidate,tiny,"yamen","tiny typed Yamen")
	compare_one(old,candidate,tiny,"market","tiny typed Market")
	check(candidate._copy_parent_pair(tiny,"unknown").is_empty(),"Unknown domain refuses")
	# Nested alias negative controls are distinct from timed comparisons.
	var isolation: Dictionary=candidate._copy_parent_pair(tiny,"yamen")
	isolation.current_t_record.nested.rows[0].foot=Vector2(9,9)
	isolation.current_t_record.nested.rows[0].values[0]=99
	isolation.current_t_record.nested.rows.append({"extra":true})
	check(old._same(isolation.frozen_t_record,tiny) and tiny.nested.rows.size()==1 and tiny.nested.rows[0].values[0]==1,"Nested current dictionary/array/packed mutation isolated from frozen and source")
	isolation.frozen_t_record.nested.rows[0].foot=Vector2(8,8)
	check(isolation.current_t_record.nested.rows[0].foot==Vector2(9,9) and tiny.nested.rows[0].foot==Vector2(1,2),"Nested frozen mutation isolated from current and source")
	packet_decodes+=1
	var packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(fixture.fixed_T_packet_path))
	if not check(packet is Dictionary and packet.get("scene_id")=="ch4_s1_luoyang_yamen" and packet.get("record") is Dictionary and packet.record.get("material_binding_evidence") is Dictionary,"One fixed04F2 native T record domain with nested mutation control"): finish();return
	compare_one(old,candidate,packet.record,"yamen","single large fixed native T record; not Field timing")
	for path: String in fixture.source_sha256:
		check(FileAccess.get_sha256(path)==fixture.source_sha256[path],"Fixed after "+path)
	finish()
'''.replace('__FIXTURE__',fp).replace('__FIXTURE_SHA__',sha(fb)).replace('__OUTPUT__',O.rstrip('/')).encode()
# Only pure helper and _same calls, never _map_parent or forged auth state.
kp=O+'test_domain_parent_copy_PENDING_ROOT.gd'
def diff(a,b,ap,bp):return ''.join(difflib.unified_diff(a.decode().splitlines(True),b.decode().splitlines(True),fromfile=ap,tofile=bp)).encode()
files={'finite_adapter_domain_copies_CANDIDATE.gd':newa,'Bundle_deferred_finite_child_CANDIDATE.gd':newb,
 'adapter_complete_vs999A.diff':diff(adapter,newa,ap,newap),'B_complete_vs9D5B.diff':diff(bundle,newb,bp,newbp),
 'parent_copy_comparison_fixture_PENDING_ROOT.json':fb,'test_domain_parent_copy_PENDING_ROOT.gd':key}
proof={'status':'BUILD_ONLY_DOMAIN_TWO_COPIES_AND_DEFERRED_INITIAL_CHILD_WHOLE_BYTE_INVERSE_NOT_PARSED_OR_RUN',
 'source':{'adapter':{'path':ap,'sha256':as_},'B':{'path':bp,'sha256':bs}},
 'candidate':{'adapter':{'path':newap,'sha256':sha(newa)},'B':{'path':newbp,'sha256':sha(newb)}},
 'hunks':{'adapter':ah,'B':bh},'whole_forward_and_reverse_bytes_equal':True,
 'adapter_contract':'Explicit Root-approved current internal API narrowing only: exact yamen T pair, exact market AP pair. Each output remains its own deep copy, independent of scratch parent and static parent. Unknown domain refuses before state or lookup. No external/future consumer compatibility claim.',
 'gate_order':'All prior _state_matches, complete _same(data,packet), cloned-child receipt strip, complete _same(current,child) and scratch-parent receipt strip retain their order. Pure helper is called only after those same gates.',
 'B_branch_completeness':[
  'AC and AA earlier returns are unchanged.',
  'Yamen not requested leaves child empty pending later branch; Yamen requested false-ok/null/mapping-fail returns empty as before; accepted Yamen supplies independent child.',
  'Market not requested leaves Yamen child intact or empty; Market requested bad-state/chain/mapping returns empty as before; accepted Market supplies independent child.',
  'Both domains cannot be requested for one formal scene: B finite state scene-id gates require different exact scene IDs. The explicit two-not-requested guard allocates the unchanged original deep copy only for nonfinite scenes.',
  'No child is read between initialization and accepted finite assignments. Its first subsequent consumer is the unchanged AP/AO inverse region. prior stays cloned before all finite checks.',
  'All whole_bound, state checks relative order, current/expected/prior isolation, receipt erases, both full wire comparisons and returned expected deep copy remain unchanged.'
 ],
 'clone_count_scope':'One accepted mapping omits exactly two unused parent outputs; one accepted finite B call omits its overwritten initial child. No wall-time or Field claim.',
 'formal_B_adapter_pin_deliberately_unmodified':'Candidate B still pins old999A adapter, so these are separately reviewable semantic candidates, NOT an integrated source-closed runnable production pair. Future authorized dependency literal successor is required.',
 'fixture':{'path':fp,'sha256':sha(fb),'ready':False},'key':{'path':kp,'sha256':sha(key),'ready':False},
 'test_scope':'Pure helper only, no _map_parent/state forgery. Future key has exactly one fixed04F2 T packet decode and one native record Yamen copy comparison; separate tiny typed mutation controls. No Market actual shape or Field/loading evidence. This build preparation did not decode a packet.',
 'packet_decode_engine_parse_collector_Stage_formal_writes':0,
 'diffs':{n:{'path':O+n,'sha256':sha(b)}for n,b in files.items()if n.endswith('.diff')}}
files['whole_byte_inverse_and_test_handoff_NOT_RUN.json']=js(proof)
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
assert fixed(ap,as_)==adapter and fixed(bp,bs)==bundle
print(json.dumps({n:sha(b)for n,b in files.items()},indent=2))
