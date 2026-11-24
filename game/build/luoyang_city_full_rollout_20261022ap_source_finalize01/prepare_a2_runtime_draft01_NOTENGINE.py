"""Prepare closed A2 Family/ENV/material runtime drafts; artifact hashes stay null."""
import copy
import difflib
import hashlib
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
OUT=S+'a2_runtime_draft01/'
SYSTEM='res://build/luoyang_city_full_rollout_20261022ap_system01/'
A2=SYSTEM+'artisan_a2_publication_epoch01/'
FAMILY='res://scripts/city/luoyang_quarters_family_20261022ap.gd'
ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
PREVIEW=A2+'ground_material_helper_READY.gd'
RUNTIME_HELPER=OUT+'material_runtime_DRAFT_NOTREADY.gd'
ARTISAN='luoyang_artisan_residential_20261022ap'
GARDEN='luoyang_riverside_garden_20261022ap'
def sha(b):return hashlib.sha256(b).hexdigest()
def path(p):
    assert p.startswith('res://') and '..' not in p
    return GAME/p[6:]
def fixed(p,s):
    b=path(p).read_bytes();assert sha(b)==s,('PIN_CHANGED',p);return b
def encoded(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
owner=json.loads(fixed(S+'finite10_yamen_classification/actual_deployment_review/owner_source_maps_ROOT_DEPLOYED_READY.json','690fba034f8b865e0cbbe31e21a8ee8095ede2471b73235f500fbcb4052c8902'))
input_record=json.loads(fixed(A2+'input_crossings6_READY.json','68a754894f570ea74e0dd617b8a03454fa5e76fb0c53f1182616d14d8c9589e1'))
family_sha='cc97a68a178936ccb6bf54c1c8a65292adaeb7e5f6ae5a314c343810d07210f1'
env_sha='a751dbd4ce014abd2e808d7c9a947dc0e4a314d4b42930a6392a1d6eb7c20a7d'
parent_bytes={FAMILY:fixed(FAMILY,family_sha),ENV:fixed(ENV,env_sha),PREVIEW:fixed(PREVIEW,'ec6cb76e379c73747bb420c5dcd0c920cb48e633ee1ae076b7c6f00a60957ce1')}
for p,s in [(FAMILY,family_sha),(ENV,env_sha)]:
    assert any(r['source_sha256'].get(p)==s for r in owner['scenes'])
texts={p:b.decode() for p,b in parent_bytes.items()};ops={p:[] for p in texts}
def change(p,label,old,new):
    if texts[p].count(old)==0 and texts[p].count(old.replace('\n','\r\n'))==1:
        old=old.replace('\n','\r\n');new=new.replace('\n','\r\n')
    assert texts[p].count(old)==1 and old!=new,(p,label,texts[p].count(old))
    offset=len(texts[p][:texts[p].index(old)].encode())
    ops[p].append({'label':label,'byte_offset_before_this_change':offset,'old':old,'new':new})
    texts[p]=texts[p].replace(old,new,1)

change(PREVIEW,'runtime_false_gate_and_exact_source_parent',
    '## Pure exact132-sprite A2 preview constructor only. No Field/Family lease.\n',
    '## Closed runtime draft: exact Field owner plus finite Family source-FIRST.\nconst READY=false\nconst FAMILY="'+FAMILY+'"\nconst FIELD="res://scripts/field/field_walkable_controller.gd"\n')
change(PREVIEW,'runtime_entry_exact_Field_family_owner',
    'static func attach_exact_preview(container: Node2D,world_size: Vector2) -> Dictionary:\n\tif container==null or world_size!=SIZE: return fail("A2_EXACT_PREVIEW_CONTEXT")\n',
    '''static func attach_exact_runtime(field: Node,scene: SceneScript,world: Node2D,world_size: Vector2,owner: Callable) -> Dictionary:
	if not READY or field==null or scene==null or scene.scene_id!=ID or world==null or world_size!=SIZE or not owner.is_valid() or not owner.call(): return fail("A2_RUNTIME_NOT_ADMITTED_OR_OWNER")
	if field.get_script().resource_path!=FIELD or not field.is_inside_tree() or field.get("_current_scene")!=scene or field.get("world_container")!=world: return fail("A2_EXACT_FIELD_SCENE_WORLD")
	var family: Variant=load(FAMILY)
	if not family is GDScript or family.resource_path!=FAMILY or not family.a2_source_bound_scene(scene): return fail("A2_EXACT_FAMILY_NATIVE_SOURCE_FIRST")
''')
change(PREVIEW,'use_existing_Field_owned_native_sprite_array_no_reparent_or_new_sprite',
    '\tfor child: Node in container.get_children():\n\t\tif not String(child.name).begins_with("SceneObject_"): continue\n',
    '\tvar existing: Variant=field.get("_scene_object_nodes")\n\tif not existing is Array: return fail("A2_FIELD_NATIVE_SPRITE_ARRAY")\n\tfor child: Node in existing:\n\t\tif not is_instance_valid(child) or not world.is_ancestor_of(child) or not String(child.name).begins_with("SceneObject_"): return fail("A2_FIELD_NATIVE_OWNER_OR_NAME")\n')
change(PREVIEW,'runtime_owner_checked_before_materials',
    '\tif matched.size()!=132: return fail("A2_ALL_ROWS_EXACT")\n',
    '\tif matched.size()!=132 or not owner.call(): return fail("A2_ALL_ROWS_EXACT_OR_OWNER")\n')
change(PREVIEW,'do_not_claim_preview_as_runtime_or_source_final',
    '\treturn {"ok":true,"ground_material_count":118,"opaque_props_unchanged":14,"no_Field_lease_or_runtime_admission":true,"no_geometry_modified":true,"all_source_pixels_unchanged":true}\n',
    '\tif not owner.call(): return fail("A2_RUNTIME_OWNER_CHANGED")\n\treturn {"ok":true,"ground_material_count":118,"opaque_props_unchanged":14,"exact_Field_owner_and_Family_source_first":true,"not_source_final_credit":true,"no_geometry_modified":true,"all_source_pixels_unchanged":true}\n')
runtime_helper=texts[PREVIEW].encode();runtime_sha=sha(runtime_helper)

fragment=(HERE/'a2_family_extension_DRAFT_NOTREADY.fragment.gd').read_bytes()
change(FAMILY,'append_exact_disabled_A2_spec_and_whole_inverse_helpers',
    'static func b() -> Variant: return load(B_PATH)\n',
    fragment.decode()+'static func b() -> Variant: return load(B_PATH)\n')
change(FAMILY,'header_declared_A2_fails_closed_and_Garden_old_paths_preserved',
    '\tfor id: StringName in IDS:\n\t\tvar row: Dictionary=raw.scenes.get(String(id),{})\n\t\tif row.get("scene_path")!=ROOT+String(id)+"/scene.res" or row.get("layout_path")!=ROOT+String(id)+"/layout.res" or row.get("packet_path")!=ROOT+String(id)+"/packet.bin": return {}\n\t\tfor p: String in [row.scene_path,row.layout_path,row.packet_path,ROOT+String(id)+"/walk.png",COMPILER,SELF]:\n',
    '\tif not _a2_header_matches(raw): return {}\n\tfor id: StringName in IDS:\n\t\tvar row: Dictionary=raw.scenes.get(String(id),{})\n\t\tif row.get("scene_path")!=_a2_artifact_path(raw,id,"scene.res") or row.get("layout_path")!=_a2_artifact_path(raw,id,"layout.res") or row.get("packet_path")!=_a2_artifact_path(raw,id,"packet.bin"): return {}\n\t\tfor p: String in [row.scene_path,row.layout_path,row.packet_path,_a2_artifact_path(raw,id,"walk.png"),COMPILER,SELF]:\n')
change(FAMILY,'Artisan_scene_path_from_exact_manifest_row_Garden_unchanged',
    '\treturn ROOT+String(id)+"/scene.res" if id in IDS and not manifest().is_empty() else ""\n',
    '\tvar data: Dictionary=manifest()\n\treturn String(data.scenes[String(id)].scene_path) if id in IDS and not data.is_empty() else ""\n')
change(FAMILY,'packet_bytes_exact_new_binding_pin_before_parse',
    '\tvar raw: Variant=bytes_to_var(FileAccess.get_file_as_bytes(row.packet_path))\n',
    '\tvar packet_bytes: PackedByteArray=FileAccess.get_file_as_bytes(row.packet_path)\n\tif id==IDS[0] and _a2_declared(data):\n\t\tvar spec: Dictionary=_a2_spec()\n\t\tif spec.is_empty() or b().bytes_sha(packet_bytes)!=spec.child["packet.bin"].sha256: return {}\n\tvar raw: Variant=bytes_to_var(packet_bytes)\n')
change(FAMILY,'only_exact_A2_child_can_enter_A2_parent_inverse',
    '\t_packets[id]=raw;return raw\n',
    '\tif id==IDS[0] and _a2_declared(data):\n\t\tif not _a2_packet_inverse(raw,data): return {}\n\telif raw.has("a2_finite_proof"): return {}\n\t_packets[id]=raw;return raw\n')
change(FAMILY,'walk_mask_exact_A2_path_only_for_Artisan',
    '\t\tvar image: Image=Image.load_from_file(ROOT+String(id)+"/walk.png")\n',
    '\t\tvar image: Image=Image.load_from_file(_a2_artifact_path(_data,id,"walk.png"))\n')
change(FAMILY,'connection_target_Artisan_path_not_old_revision4',
    '"target_scene_path":ROOT+row.target+"/scene.res"',
    '"target_scene_path":_a2_artifact_path(data,StringName(row.target),"scene.res")')

env_constants='''const A2_MATERIAL_READY=false
const A2_MATERIAL_HELPER="'''+RUNTIME_HELPER+'''"
const A2_MATERIAL_HELPER_SHA="'''+runtime_sha+'''"
const A2_MATERIAL_CONTRACT="'''+A2+'''ground_contract_READY.json"
const A2_MATERIAL_CONTRACT_SHA="87abb71b03de83e2d5c14434b52d56a8be51dfe940ed85478fc34b029a4ed5af"
const A2_MATERIAL_SHADER="'''+A2+'''ground_use_candidate.gdshader"
const A2_MATERIAL_SHADER_SHA="11b32bb0efbc9b1317c2ad06d028742d9bfce899e2d9b9467874c28898c2eb1e"
'''
change(ENV,'closed_exact_A2_material_sources',
    'const EXAMINER_SOURCES=',env_constants+'const EXAMINER_SOURCES=')
change(ENV,'Artisan_only_new_material_source_paths_else_original_union',
    '\tif id==&"luoyang_artisan_residential_20261022ap": out[ARTISAN_UNION_SHADER]=true\n',
    '\tif id==&"luoyang_artisan_residential_20261022ap":\n\t\tif A2_MATERIAL_READY:\n\t\t\tfor p: String in [A2_MATERIAL_HELPER,A2_MATERIAL_CONTRACT,A2_MATERIAL_SHADER]: out[p]=true\n\t\telse: out[ARTISAN_UNION_SHADER]=true\n')
change(ENV,'Artisan_only_install_exact_new_material_pins',
    '\tif scene.scene_id==&"luoyang_artisan_residential_20261022ap": source_pins[ARTISAN_UNION_SHADER]=ARTISAN_UNION_SHADER_SHA\n',
    '\tif scene.scene_id==&"luoyang_artisan_residential_20261022ap":\n\t\tif A2_MATERIAL_READY:\n\t\t\tsource_pins[A2_MATERIAL_HELPER]=A2_MATERIAL_HELPER_SHA\n\t\t\tsource_pins[A2_MATERIAL_CONTRACT]=A2_MATERIAL_CONTRACT_SHA\n\t\t\tsource_pins[A2_MATERIAL_SHADER]=A2_MATERIAL_SHADER_SHA\n\t\telse: source_pins[ARTISAN_UNION_SHADER]=ARTISAN_UNION_SHADER_SHA\n')
change(ENV,'early_Artisan_A2_material_path_does_not_draw_old_rectangles',
    '\tvar used: Dictionary={}\n',
    '\tif scene.scene_id==&"luoyang_artisan_residential_20261022ap" and A2_MATERIAL_READY:\n\t\treturn _install_a2_exact_material(field,scene,world,world_size,owner,source_first)\n\tvar used: Dictionary={}\n')
env_helper='''static func _install_a2_exact_material(field: Node,scene: SceneScript,world: Node2D,world_size: Vector2,owner: Callable,source_first: Dictionary) -> Dictionary:
	if not A2_MATERIAL_READY or scene.scene_id!=&"luoyang_artisan_residential_20261022ap" or not owner.call(): return fail("A2_MATERIAL_NOT_ADMITTED")
	var helper: Variant=load(A2_MATERIAL_HELPER)
	if not helper is GDScript or helper.resource_path!=A2_MATERIAL_HELPER: return fail("A2_EXACT_RUNTIME_MATERIAL_HELPER")
	var attached: Dictionary=helper.attach_exact_runtime(field,scene,world,world_size,owner)
	if attached.get("ok")!=true: return attached
	var source_final: Dictionary={}
	for p: String in source_first:
		source_final[p]=FileAccess.get_sha256(p)
		if source_final[p]!=source_first[p]: return fail("A2_MATERIAL_SOURCE_FINAL_CHANGED",p)
	if not owner.call() or world.get_node_or_null(NodePath(NAME))!=null: return fail("A2_MATERIAL_OWNER_OR_DUPLICATE_LAYER")
	var marker:=Node2D.new();marker.name=NAME;marker.z_index=Z
	var receipt: Dictionary={"ok":true,"matched":true,"scene_id":String(scene.scene_id),"count":118,"opaque_props_unchanged":14,"source_first":source_first,"source_final":source_final,"source_hash_passes":2,"a2_exact_runtime_material":attached,"no_old_rect_or_411B_union_install":true,"no_physics_support_ghost_or_interactions":true}
	marker.set_meta("ap_environment_receipt",receipt);world.add_child(marker)
	return receipt


'''
change(ENV,'append_finite_material_install_no_other_scene_branch',
    'static func attach_artisan_union_transition(field: Node,scene: SceneScript,world_size: Vector2,owner: Callable) -> Dictionary:\n',
    env_helper+'static func attach_artisan_union_transition(field: Node,scene: SceneScript,world_size: Vector2,owner: Callable) -> Dictionary:\n')

# The binding explicitly names expected paths; unknown actual/native/ART hashes remain null.
binding={
    'status':'PENDING_ROOT_ARTISAN_A2_BINDING_NOT_RUNTIME_READY','ready':False,'scene_id':ARTISAN,
    'child':{suffix:{'path':A2+'output_crossings6/native/'+suffix,'sha256':None} for suffix in ['scene.res','layout.res','packet.bin','walk.png']},
    'parent':{suffix:{'path':input_record[key],'sha256':input_record['source_pins'][input_record[key]]} for suffix,key in [('scene.res','parent_scene'),('layout.res','parent_layout'),('packet.bin','parent_packet'),('walk.png','parent_walk')]},
    'author':{'path':input_record['author'],'sha256':input_record['source_pins'][input_record['author']]},
    'publisher_report':{'path':None,'sha256':None},'root_art_admission':{'path':None,'sha256':None},
    'parent_rgba_sha256':input_record['parent_rgba_sha256'],
    'local_domains_xywh':input_record['local_domains_xywh'],'allowed_changed_solid_ids':input_record['allowed_changed_solid_ids'],
    'source_sha256':{input_record[k]:input_record['source_pins'][input_record[k]] for k in ['parent_scene','parent_layout','parent_packet','parent_walk','parent_report','parent_author','author']},
    'pending_source_leaves':['four actual native artifacts + eventual walk import/compiled leaves','actual publisher report','Root finite ART authority','exact final Family/material helper code pins in the shared Quarter manifest, never binding->final manifest SHA'],
    'unknown_artifact_sha_not_guessed':True,
    'runtime_spec_requires_Root_actual_schema_and_status_binding_before_READY':True,
}
outputs={OUT+'a2_binding_DRAFT_NOTREADY.json':encoded(binding),RUNTIME_HELPER:runtime_helper}
descriptors=[]
for p,filename in [(FAMILY,'Family_A2_DRAFT_NOTREADY.gd'),(ENV,'ENV_A2_DRAFT_NOTREADY.gd'),(PREVIEW,'material_runtime_DRAFT_NOTREADY.gd')]:
    candidate=texts[p].encode();inverse=candidate
    for row in reversed(ops[p]):
        offset=row['byte_offset_before_this_change'];old=row['old'].encode();new=row['new'].encode()
        assert inverse[offset:offset+len(new)]==new,row['label']
        inverse=inverse[:offset]+old+inverse[offset+len(new):]
    assert inverse==parent_bytes[p],('WHOLE_BYTE_INVERSE',p)
    target=p if p!=PREVIEW else None
    descriptor={'target':target,'parent':{'path':p,'sha256':sha(parent_bytes[p])},'candidate':{'path':OUT+filename,'sha256':sha(candidate),'bytes':len(candidate)},'whole_byte_inverse':True,'operations':ops[p]}
    descriptors.append(descriptor)
    outputs[OUT+filename]=candidate
    outputs[OUT+filename+'.diff']=''.join(difflib.unified_diff(parent_bytes[p].decode().splitlines(True),texts[p].splitlines(True),fromfile=p,tofile=OUT+filename,n=4)).encode()
handoff={
    'status':'A2_EXACT_NATIVE_AND_MATERIAL_RUNTIME_DRAFT_FLAGS_FALSE_NOT_SOURCE_AUTHORITY',
    'candidates':descriptors,'binding':{'path':OUT+'a2_binding_DRAFT_NOTREADY.json','sha256':sha(encoded(binding))},
    'existing_parents':{'owner690F':'690fba034f8b865e0cbbe31e21a8ee8095ede2471b73235f500fbcb4052c8902','Yamen_runtime_ED4C':'ed4cee9e730f96af624354dd08ad6d8875259ba38827fc96df0c493da44c1794','AP_INDEX_DB9D':'db9d5e277d7e86e58e799804822d83959833c3700d24444f5fe48d359d9bd088'},
    'false_gates':['Family.A2_READY=false and A2_BINDING_SHA empty','ENV.A2_MATERIAL_READY=false','runtime material helper.READY=false','binding.ready=false/artifact and report/ART SHA null'],
    'Family_delta':['One exact Artisan manifest-row path migration to fixed output_crossings6; Garden oldROOT row stays exact.','New child packet SHA must be fixed in binding and in full shared source map, kind/scene_id stay old.','Decode/hash frozen53624 parent once per packet validation; exact SceneMETA/layout3field and11packetkey whole typed inverse.','Old33/new27 fixed source solids only six IDs retired and existing rack moved; mask full inverse only eight fixed domains.','source_paths remains full FIRST/FINAL unchanged, new binding/proofs/parent leaves explicit in shared Quarter map.','scene_path/walk and cross-quarter connection target use only exact declared Artisan paths; no generic packet/path fallback.'],
    'ENV_delta':['Artisan-only three material leaves; new constructor consumes original Field-owned132 SceneObject sprites, not preview wrapper or reparenting.','118 ground and14 opaque props checked by complete frozen contract and exact texture/transform before attaching any material.','New branch requires sameField/scene/world and owner plus Family.a2_source_bound_scene, source-FIRST allowed before original Family.validation_finish.','A2 branch replaces old Artisan ENV rectangles and411B union attachment, not double-draw; other seven scenes unchanged.','ENV local sourceFIRST/FINAL and original Family final full source checks retained.'],
    'not_yet_satisfied':['Root actual native four artifact SHA and final report','Root finite outdoor ART schema/pin','New walk import/compiled exact promotion if required by Field ResourceLoader','Concrete source-only manifest/index closure and execution successor including authorized G7B195/Field67A83','Root code review and unique parsing if authorized','Runtime source manifest classification and masks/timing acceptance'],
    'performance_risks':['Draft Family one-time parent50MiB decode and mask inverse are synchronous under existing packet API; no measured cost or worker authority. Must review before activation; do not silently remove checks.','Shared Quarter proof domain includes new Artisan sources in Garden collector but Garden native/material branch remains old.'],
    'minimal_DAG_plan':['Keep Garden native3+mask bytes unchanged. Preserve old Artisan53624 native4 as pinned inverse ancestors; publish only one new Artisan row/path quartet.','New binding+runtime material code/contract/shader and actual report/ART provenance enter Quarter source map; avoid any binding->final manifest back edge.','Family and ENV code are direct source consumers, not a new OWNED domain. G/Field are existing OWNED rows; contract/Coordinator/Temple/execution exact successors only where required.','Update only actual source-bearing Estate/registry/legacy/APMarket/two finite-runtime headers and their real index consumers; Yamen startsED4C and APINDEX startsDB9D.','Independent expected owners derive from690F plus fixed author/actual publication/proofs, not current collector output. Prune no-op targets before final Root scope; do not replay29.'],
    'no_expected_maps_or_artifact_hashes_generated_from_live_crawl':True,
    'engine_parse_collector_decode_source_stage_or_canonical_writes':0,
}
outputs[OUT+'handoff_DRAFT_NOTREADY.json']=encoded(handoff)
assert not path(OUT).exists()
for p,b in outputs.items():
    path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as h:h.write(b)
print(json.dumps({'handoff':{'path':OUT+'handoff_DRAFT_NOTREADY.json','sha256':sha(encoded(handoff))},'candidates':[r['candidate'] for r in descriptors],'canonical_writes':0}))
