"""NEW build-only A2 admission draft. No native decode, engine or formal writes."""
import copy
import difflib
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
S = 'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
OUT = S + 'a2_runtime_draft03/'
ROOT = 'res://build/luoyang_city_full_rollout_20261022ap_root01/'
SYSTEM = 'res://build/luoyang_city_full_rollout_20261022ap_system01/'
ART = ROOT + 'artisan_A2_local_layout_material_admission_READY.json'
REPORT = SYSTEM + 'artisan_a2_publication_epoch01/output_crossings6/runs/118352_1733/result.json'
QA = 'res://build/luoyang_city_full_rollout_20261022ap_qa01/artisan_a2_publication118352_independent_readonly_review_READY.json'
FAMILY = 'res://scripts/city/luoyang_quarters_family_20261022ap.gd'
ENV = 'res://scripts/city/luoyang_environment_layer_20261022ap.gd'

def sha(data): return hashlib.sha256(data).hexdigest()
def path(p):
    assert p.startswith('res://') and '..' not in p
    return GAME / p[6:]
def fixed(p, digest):
    data = path(p).read_bytes()
    assert sha(data) == digest, ('PIN_CHANGED', p)
    return data
def enc(value): return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode()

old_handoff = json.loads(fixed(S+'a2_runtime_draft01/handoff_DRAFT_NOTREADY.json', '755a759c3cdabbcff67f93263bfd19f676bf3b0810e34d802ce33785c491b6d7'))
binding = json.loads(fixed(S+'a2_runtime_draft02/a2_binding_ACTUAL_NATIVE_ART_PENDING.json', 'bf6209ce0be198c7ff56ddb7d79c479f0f629154cb52cec88833a59741bf6ad4'))
art_bytes = fixed(ART, 'eaab9607b0d325d9554a1e6d7a92559230fd58779a201f883393d7f649fb8135')
art = json.loads(art_bytes)
report_bytes = fixed(REPORT, 'a5f2200e76ca6bb7932c5760b3954748c0578c0c093755af86493a51a4ce25b7')
report = json.loads(report_bytes)
qa_bytes = fixed(QA, 'ec78d7309f652eb11048a8e0d3ee68a910eeb6189ef0fae394ccbe23b759d982')
assert art['approved_by_root'] is True and art['whole_district_ART_pass'] is False
assert art['publisher_report'] == binding['publisher_report']
assert art['independent_publication_review'] == {'path': QA, 'sha256': sha(qa_bytes)}
assert report['passed'] is True and report['published'] is True
assert report['source_first'] == report['source_final'] and len(report['source_first']) == 137
assert report['whole_packet_inverse'] is True and report['whole_scene_layout_inverse'] is True
proof = report['finite_proof']
assert proof['native_storage_inverse'] is True and proof['local_mask']['whole_RGBA_inverse'] is True
assert proof['local_mask']['outside_eight_guarded_domains_exact'] is True
for key, value in {'old_visual_count':106, 'old_solid_count':33, 'new_visual_count':132, 'new_solid_count':27, 'new_ground_count':118, 'retained_opaque_props':14}.items():
    assert type(proof[key]) is int and proof[key] == value
assert all(report['artifacts'][row['path']] == row['sha256'] for row in binding['child'].values())
binding['status'] = 'PENDING_ROOT_ARTISAN_A2_SOURCE_CLOSURE_NOT_RUNTIME_READY'
binding['root_art_admission'] = {'path': ART, 'sha256': sha(art_bytes)}
binding['independent_publication_review'] = {'path': QA, 'sha256': sha(qa_bytes)}
binding['publication_admission_contract'] = {
    'runtime_inverse_replay': False,
    'fixed_publisher_inverse_inherited': True,
    'native_packet_admission': 'exact_child_packet_SHA_then_existing_plain_kind_scene_and_whole_mask_SHA',
    'resource_admission': 'existing_exact_Scene_and_Layout_whole_storage_equality_against_child_packet',
    'source_admission': 'existing_complete_shared_Quarter_FIRST_and_FINAL_unchanged',
    'parent_packet_runtime_read_decode_clone_and_mask_domain_replay': False,
    'whole_district_ART_or_Field_or_loading_credit': False,
}
binding['publication_finite_proof'] = copy.deepcopy(proof)
binding['source_sha256'][ART] = sha(art_bytes)
binding['source_sha256'][QA] = sha(qa_bytes)
binding['actual_native_publication_only_not_ART_or_runtime'] = False
binding['limited_Root_ART_actual_not_runtime_or_whole_district'] = True
binding['pending_source_leaves'] = ['eventual new walk import/ctex if required; no hashes guessed', 'final code-only source pins and exact manifests/indices in the shared source closure', 'Root production flag and final target approval']
binding_bytes = enc(binding)
binding_sha = sha(binding_bytes)

parents = {row['target']: row for row in old_handoff['candidates'] if row['target']}
buffers = {}
operations = {}
original = {}
for target, row in parents.items():
    original[target] = fixed(row['candidate']['path'], row['candidate']['sha256'])
    buffers[target] = original[target].decode()
    operations[target] = []

def change(target, label, old, new):
    text = buffers[target]
    if text.count(old) == 0 and text.count(old.replace('\n','\r\n')) == 1:
        old, new = old.replace('\n','\r\n'), new.replace('\n','\r\n')
    assert text.count(old) == 1 and old != new, (target, label, text.count(old))
    offset = len(text[:text.index(old)].encode())
    operations[target].append({'label':label, 'byte_offset_before_this_change':offset, 'old':old, 'new':new})
    buffers[target] = text.replace(old, new, 1)

change(FAMILY, 'wire_fixed_actual_native_limited_ART_binding_but_keep_A2_READY_false',
       'const A2_BINDING="'+S+'a2_runtime_draft01/a2_binding_DRAFT_NOTREADY.json"\nconst A2_BINDING_SHA=""\n',
       'const A2_BINDING="'+OUT+'a2_binding_NATIVE_LOCAL_ART_CLOSURE_PENDING.json"\nconst A2_BINDING_SHA="'+binding_sha+'"\n')
old_spec = buffers[FAMILY][buffers[FAMILY].index('static func _a2_spec()'):buffers[FAMILY].index('static func _a2_declared(')]
new_spec = '''static func _a2_spec() -> Dictionary:
	if not A2_READY or not b()._hash(A2_BINDING_SHA): return {}
	if not _a2_fixed_binding.is_empty(): return _a2_fixed_binding
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(A2_BINDING)
	if b().bytes_sha(bytes)!=A2_BINDING_SHA: return {}
	var value: Variant=JSON.parse_string(bytes.get_string_from_utf8())
	if not value is Dictionary or value.get("status")!="ROOT_FIXED_A2_ARTISAN_NATIVE_AND_ART_BINDING" or value.get("ready")!=true or value.get("scene_id")!=String(IDS[0]): return {}
	for key: String in ["child","parent"]:
		if not value.get(key) is Dictionary: return {}
		for suffix: String in ["scene.res","layout.res","packet.bin","walk.png"]:
			var leaf: Dictionary=value[key].get(suffix,{})
			if not leaf.get("path") is String or ".." in leaf.path or not leaf.path.begins_with("res://") or not b()._hash(leaf.get("sha256")): return {}
	for key: String in ["publisher_report","root_art_admission","independent_publication_review"]:
		var leaf: Dictionary=value.get(key,{})
		if not leaf.get("path") is String or not leaf.path.begins_with("res://build/") or ".." in leaf.path or not b()._hash(leaf.get("sha256")) or FileAccess.get_sha256(leaf.path)!=leaf.sha256: return {}
	var report: Variant=JSON.parse_string(FileAccess.get_file_as_string(value.publisher_report.path))
	var art: Variant=JSON.parse_string(FileAccess.get_file_as_string(value.root_art_admission.path))
	if not report is Dictionary or report.get("passed")!=true or report.get("published")!=true or not art is Dictionary or art.get("status")!="ROOT_VIEWED_A2_LOCAL_LAYOUT_AND_MATERIAL_SCOPE_ONLY" or art.get("approved_by_root")!=true or art.get("whole_district_ART_pass")!=false or art.get("Field_NPC_Player_Physics_or_loading_credit")!=false: return {}
	if not b().equal(art.get("publisher_report"),value.publisher_report) or not b().equal(art.get("independent_publication_review"),value.independent_publication_review): return {}
	if report.get("whole_packet_inverse")!=true or report.get("whole_scene_layout_inverse")!=true or not report.get("source_first") is Dictionary or report.source_first.size()!=137 or not b().equal(report.source_first,report.get("source_final")): return {}
	var proof: Dictionary=report.get("finite_proof",{})
	if not b().equal(proof,value.get("publication_finite_proof")) or proof.get("native_storage_inverse")!=true or proof.get("all_7_routes_all4NPC_all4portals_exact")!=true: return {}
	for key: String in ["old_visual_count","old_solid_count","new_visual_count","new_solid_count","new_ground_count","retained_opaque_props"]:
		var expected: Dictionary={"old_visual_count":106,"old_solid_count":33,"new_visual_count":132,"new_solid_count":27,"new_ground_count":118,"retained_opaque_props":14}
		if not proof.get(key) is float or proof[key]!=float(expected[key]): return {}
	var mask: Dictionary=proof.get("local_mask",{})
	if mask.get("whole_RGBA_inverse")!=true or mask.get("outside_eight_guarded_domains_exact")!=true or mask.get("child_rgba_sha256")!=value.get("child_rgba_sha256_from_fixed_independent_prior_and_Root_report") or mask.get("parent_rgba_sha256")!=value.get("parent_rgba_sha256"): return {}
	var contract: Dictionary=value.get("publication_admission_contract",{})
	if contract.get("runtime_inverse_replay")!=false or contract.get("fixed_publisher_inverse_inherited")!=true or contract.get("parent_packet_runtime_read_decode_clone_and_mask_domain_replay")!=false: return {}
	for suffix: String in value.child:
		if report.get("artifacts",{}).get(value.child[suffix].path)!=value.child[suffix].sha256: return {}
	if not value.get("source_sha256") is Dictionary or not value.get("local_domains_xywh") is Array or value.local_domains_xywh.size()!=8: return {}
	_a2_fixed_binding=value
	return _a2_fixed_binding
'''
change(FAMILY, 'fixed_publication_admission_with_real_limited_Root_ART_schema_not_runtime_inverse_credit', old_spec, new_spec)
old_inverse = buffers[FAMILY][buffers[FAMILY].index('static func _a2_packet_inverse('):buffers[FAMILY].index('static func a2_source_bound_scene(')]
new_admission = '''static func _a2_published_packet_valid(raw: Dictionary,data: Dictionary) -> bool:
	# Exact child bytes were hashed before decoding. The fixed publisher already
	# proved the complete parent inverse; runtime does NOT replay that operation.
	if not _a2_header_matches(data): return false
	var spec: Dictionary=_a2_spec()
	if spec.is_empty() or not raw.get("a2_finite_proof") is Dictionary or not b().equal(raw.a2_finite_proof,spec.publication_finite_proof): return false
	if raw.get("parent_packet_sha256")!=spec.parent["packet.bin"].sha256 or raw.get("author_path")!=spec.author.path or raw.get("author_sha256")!=spec.author.sha256: return false
	if raw.get("mask_sha256")!=spec.child_rgba_sha256_from_fixed_independent_prior_and_Root_report or not raw.get("solids") is Array or raw.solids.size()!=27: return false
	for key: String in ["scene_storage","layout_storage"]:
		if not raw.get(key) is Dictionary or not raw[key].get("fields") is Dictionary: return false
	for key: String in ["visual_objects","blockers"]:
		if not raw.layout_storage.fields.get(key) is Dictionary or not raw.layout_storage.fields[key].get("array_values") is Array: return false
	return raw.layout_storage.fields.visual_objects.array_values.size()==132 and raw.layout_storage.fields.blockers.array_values.size()==27 and raw.layout_storage.fields.walkable_mask_path==spec.child["walk.png"].path
'''
change(FAMILY, 'remove_parent_50MiB_read_decode_fullpacket_clone_and_eight_domain_replay', old_inverse, new_admission)
change(FAMILY, 'use_fixed_child_publication_admission_not_replayed_inverse', 'if not _a2_packet_inverse(raw,data): return {}', 'if not _a2_published_packet_valid(raw,data): return {}')

change(ENV, 'retain_normal_ground_stamp_loop_before_new_material_attachment',
       '\tif scene.scene_id==&"luoyang_artisan_residential_20261022ap" and A2_MATERIAL_READY:\n\t\treturn _install_a2_exact_material(field,scene,world,world_size,owner,source_first)\n', '')
change(ENV, 'A2_material_at_original_union_slot_after_complete_alpha_rut_stamp',
       '\t\tartisan_union=attach_artisan_union_transition(field,scene,world_size,owner)\n',
       '\t\tif A2_MATERIAL_READY: artisan_union=_attach_a2_exact_material(field,scene,world,world_size,owner)\n\t\telse: artisan_union=attach_artisan_union_transition(field,scene,world_size,owner)\n')
change(ENV, 'separate_new_material_receipt_from_original_411B_union_credit',
       '\tif not artisan_union.is_empty(): receipt["artisan_union_visual_only"]=artisan_union\n',
       '\tif not artisan_union.is_empty():\n\t\tif A2_MATERIAL_READY:\n\t\t\treceipt["a2_exact_runtime_material"]=artisan_union\n\t\t\treceipt["original_complete_alpha_ground_stamps_retained"]=count\n\t\telse: receipt["artisan_union_visual_only"]=artisan_union\n')
old_install = buffers[ENV][buffers[ENV].index('static func _install_a2_exact_material('):buffers[ENV].index('static func attach_artisan_union_transition(')]
new_attach = '''static func _attach_a2_exact_material(field: Node,scene: SceneScript,world: Node2D,world_size: Vector2,owner: Callable) -> Dictionary:
	if not A2_MATERIAL_READY or scene.scene_id!=&"luoyang_artisan_residential_20261022ap" or not owner.call(): return fail("A2_MATERIAL_NOT_ADMITTED")
	var helper: Variant=load(A2_MATERIAL_HELPER)
	if not helper is GDScript or helper.resource_path!=A2_MATERIAL_HELPER: return fail("A2_EXACT_RUNTIME_MATERIAL_HELPER")
	# Existing install() owns the original stamp layer and source-FIRST/FINAL.
	# Do not replace it with an empty marker or repeat its hash passes here.
	return helper.attach_exact_runtime(field,scene,world,world_size,owner)


'''
change(ENV, 'reuse_original_layer_final_hash_and_attach_preserving_ruts_no_empty_marker', old_install, new_attach)

outputs = {OUT+'a2_binding_NATIVE_LOCAL_ART_CLOSURE_PENDING.json': binding_bytes}
rows = []
for target, filename in [(FAMILY,'Family_A2_PUBLICATION_ADMISSION_NOTREADY.gd'),(ENV,'ENV_A2_RUTS_PRESERVED_NOTREADY.gd')]:
    candidate = buffers[target].encode()
    inverse = candidate
    for op in reversed(operations[target]):
        i = op['byte_offset_before_this_change']; new = op['new'].encode()
        assert inverse[i:i+len(new)] == new
        inverse = inverse[:i]+op['old'].encode()+inverse[i+len(new):]
    assert inverse == original[target]
    # Compose original draft01 exact inverse back to deployed canonical parent.
    for op in reversed(parents[target]['operations']):
        i = op['byte_offset_before_this_change']; new = op['new'].encode()
        assert inverse[i:i+len(new)] == new
        inverse = inverse[:i]+op['old'].encode()+inverse[i+len(new):]
    assert sha(inverse) == parents[target]['parent']['sha256']
    outputs[OUT+filename] = candidate
    outputs[OUT+filename+'.diff'] = ''.join(difflib.unified_diff(original[target].decode().splitlines(True),buffers[target].splitlines(True),fromfile=parents[target]['candidate']['path'],tofile=OUT+filename,n=4)).encode()
    rows.append({'target':target,'parent_draft01':parents[target]['candidate'],'formal_parent':parents[target]['parent'],'candidate':{'path':OUT+filename,'sha256':sha(candidate),'bytes':len(candidate)},'whole_byte_inverse_to_draft01_and_formal_parent':True,'operations':operations[target]})

# Verify preservation on exact byte slices, not a vague textual statement.
old_env = original[ENV].decode()
new_env = buffers[ENV]
stamp_start = '\tfor row: Dictionary in data.scenes[String(scene.scene_id)].ground:'
stamp_end = '\tvar artisan_union: Dictionary={}'
def slice_stamp(text):
    text = text.replace('\r\n','\n')
    return text[text.index(stamp_start, text.index('var count:')):text.index(stamp_end)]
assert slice_stamp(old_env) == slice_stamp(new_env)
assert '_a2_packet_inverse' not in buffers[FAMILY]
new_gate = buffers[FAMILY][buffers[FAMILY].index('static func _a2_published_packet_valid('):buffers[FAMILY].index('static func a2_source_bound_scene(')]
assert all(token not in new_gate for token in ['FileAccess.', 'bytes_to_var', '.duplicate(', 'range(', 'Rect2i('])
handoff = {
    'status':'A2_FIXED_PUBLICATION_ADMISSION_AND_ORIGINAL_RUTS_CANDIDATES_NOT_RUNTIME_READY',
    'candidates':rows,
    'binding':{'path':OUT+'a2_binding_NATIVE_LOCAL_ART_CLOSURE_PENDING.json','sha256':binding_sha},
    'unchanged_false_material_helper':old_handoff['candidates'][2]['candidate'],
    'runtime_flags_false_and_source_closure_pending':True,
    'fixed_publication_report':binding['publisher_report'], 'limited_Root_ART':binding['root_art_admission'],
    'independent_publication_review':binding['independent_publication_review'],
    'admission_contract':binding['publication_admission_contract'],
    'runtime_checks_retained':['Exact child packet SHA before decode; original _plain/kind/scene_id/full walk_bytes SHA check.','Original matches() exact Scene and Layout B.storage equality and source-author metadata check.','Original full shared Quarter source FIRST/FINAL and existing Image whole RGBA equality/safe_body.','New small fixed publisher/independent review/limited ART evidence and exact child declaration; no generic fallback.'],
    'runtime_work_removed':['No additional parent packet read or bytes_to_var.','No whole packet/storage deep clone for an inverse already fixed by actual publication.','No eight-domain mask reconstruction or parent walk_bytes replay.'],
    'rut_preservation':{'original_ground_loop_whole_source_slice_equal':True,'id':'artisan_service_cart_ruts','asset':'cart_ruts','center':[610,1535],'uniform_scale':0.16,'normal_source_FIRST_FINAL_and_layer_attach_retained':True,'empty_marker_removed':True},
    'minimum_DAG_not_final_scope':['Family + ENV exact code successors only; existing material helper is a new build source leaf, not a new OWNED domain.','Quarter shared manifest/index: exact Artisan row four paths/pins plus binding/A5F2/EC78/EAAB/new21Atlas/material3. Garden native paths/geometry/material branch unchanged.','ENV-bearing legacy sources/indices and AP Market + finite-runtime headers only by actual consumer pin reachability; begin Yamen ED4C/APINDEX DB9D.','Authorized G7B195/Field67A83 need existing execution-owned and x-contract/Coordinator/Temple source-only dependency successors; preserve old parent graphs and unchanged OWNED11.','Registry/Estate and maps only where their actual G/Field/Family source leaves or consumed header pins change. No full29 replay/no no-op targets.','Independent owner690F recipes inherit declared author/publication sources; never fill expected sources from a collector or current crawl.'],
    'pending':['Root code review and production flags/source authority.','Exact actual walk import/compiled leaf admission if required.','Final necessary target set and full source-only DAG/stager review.'],
    'whole_district_ART_pass':False,'whole_city_complete':False,'Field_Physics_or_loading_credit':False,
    'native_decode_engine_parse_collector_stage_or_canonical_writes':0,
}
outputs[OUT+'handoff_PUBLICATION_ADMISSION_RUTS_NOTREADY.json'] = enc(handoff)
assert not path(OUT).exists()
for p,data in outputs.items():
    path(p).parent.mkdir(parents=True, exist_ok=True)
    with path(p).open('xb') as stream: stream.write(data)
print(json.dumps({'handoff':{'path':OUT+'handoff_PUBLICATION_ADMISSION_RUTS_NOTREADY.json','sha256':sha(enc(handoff))},'candidates':[r['candidate'] for r in rows],'binding_sha256':binding_sha,'engine_or_canonical_writes':0}))
