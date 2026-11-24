"""One independent semantic review of final draft03, not its intermediate drafts."""
import difflib,hashlib,json,re
from pathlib import Path
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
B=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/a2_runtime_draft03'
H=B/'handoff_PUBLICATION_ADMISSION_RUTS_NOTREADY.json'
OUT=QA/'artisan_a2_runtime_draft03_independent_semantic_review_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def path(p):return GAME/p[6:]
def method(text,name):
    marker='static func '+name+'('
    start=text.index(marker)
    end=text.find('\nstatic func ',start+len(marker))
    return text[start:] if end<0 else text[start:end]
def inverse_deltas(parent,candidate):
    a=parent.splitlines(keepends=True);b=candidate.splitlines(keepends=True)
    changes=[];reconstructed=[]
    for op,ai,aj,bi,bj in difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes():
        if op=='equal':reconstructed+=b[bi:bj]
        else:
            changes.append({'old_lines':[ai+1,aj],'new_lines':[bi+1,bj],'operation':op,'old':''.join(a[ai:aj]),'new':''.join(b[bi:bj])})
            reconstructed+=a[ai:aj]
    assert ''.join(reconstructed)==parent
    return changes
assert not OUT.exists()
assert sha(H)=='7c5eed8743fbeab63c728c4e717661265344d343fabb6bdcd1fc24b5fa1830e3'
h=json.loads(H.read_bytes());texts={};deltas=[]
for row in h['candidates']:
    parent=path(row['formal_parent']['path']);candidate=path(row['candidate']['path'])
    assert sha(parent)==row['formal_parent']['sha256'] and sha(candidate)==row['candidate']['sha256']
    a=parent.read_bytes();b=candidate.read_bytes();aa=a.decode();bb=b.decode()
    ops=inverse_deltas(aa,bb)
    texts['Family' if 'quarters_family' in row['target'] else 'ENV']=(aa,bb)
    deltas.append({'target':row['target'],'parent_SHA':sha(parent),'candidate_SHA':sha(candidate),'whole_byte_inverse_to_formal_parent':True,'actual_line_deltas':ops})
old,family=texts['Family'];oldenv,env=texts['ENV']
runtime=path(h['unchanged_false_material_helper']['path'])
assert sha(runtime)=='720f2c9cd6806b89951f14b27eeaf97fd4cb7fdaf6a46988a7134a3a3ba556fc'
material=runtime.read_text(encoding='utf-8')
binding=path(h['binding']['path']);assert sha(binding)=='b2996187fcafb299b394291d2422ba6edbdbf50e05e192b0a80b2f095cd6c8bd'
bind=json.loads(binding.read_bytes())
assert bind['ready'] is False and bind['status']=='PENDING_ROOT_ARTISAN_A2_SOURCE_CLOSURE_NOT_RUNTIME_READY'
assert 'const A2_READY=false' in family and 'const A2_MATERIAL_READY=false' in env and 'const READY=false' in material
for name in ['manifest','validation_begin','validation_finish','validation_receipt','matches','source_paths','prepare_arrival','owns_route']:
    assert method(old,name)==method(family,name),name
assert 'spec.parent["packet.bin"].path' not in family
assert '_a2_packet_inverse' not in family and 'inverse_mask' not in family and 'for bounds: Array in' not in family
packet=method(family,'packet')
assert packet.index('b().bytes_sha(packet_bytes)!=spec.child["packet.bin"].sha256')<packet.index('bytes_to_var(packet_bytes)')
assert 'not b()._plain(raw)' in packet and 'raw.get("kind")!="AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER"' in packet and 'b().bytes_sha(raw.walk_bytes)!=raw.get("mask_sha256")' in packet
assert 'elif raw.has("a2_finite_proof"): return {}' in packet
assert 'if id==IDS[0] and _a2_declared(data)' in method(family,'_a2_artifact_path')
assert method(family,'safe_body').replace('_a2_artifact_path(_data,id,"walk.png")','ROOT+String(id)+"/walk.png"')==method(old,'safe_body')
assert 'not proof.get(key) is float' in method(family,'_a2_spec') and 'not native_proof.get(key) is int' in method(family,'_a2_published_packet_valid')
assert 'b().equal(proof,value.get("publication_finite_proof"))' in family
report=bind['publisher_report'];art=bind['root_art_admission'];review=bind['independent_publication_review']
for leaf in [report,art,review]:assert sha(path(leaf['path']))==leaf['sha256']
assert report['sha256']=='a5f2200e76ca6bb7932c5760b3954748c0578c0c093755af86493a51a4ce25b7'
assert art['sha256']=='eaab9607b0d325d9554a1e6d7a92559230fd58779a201f883393d7f649fb8135'
assert review['sha256']=='ec78d7309f652eb11048a8e0d3ee68a910eeb6189ef0fae394ccbe23b759d982'
actual=json.loads(path(report['path']).read_bytes());artdata=json.loads(path(art['path']).read_bytes())
assert bind['publication_finite_proof']==actual['finite_proof']
assert actual['source_first']==actual['source_final'] and len(actual['source_first'])==139
assert artdata['publisher_report']==report and artdata['independent_publication_review']==review and artdata['whole_district_ART_pass'] is False
for suffix,leaf in bind['child'].items():assert actual['artifacts'][leaf['path']]==leaf['sha256']
assert bind['publication_admission_contract']['parent_packet_runtime_read_decode_clone_and_mask_domain_replay'] is False
# Original alpha-stamp construction and the original final hash/attach remain
# byte-identical; only the Artisan union call chooses the exact new material.
loop_start='\tvar used: Dictionary={}';loop_end='\tvar artisan_union: Dictionary={}'
assert oldenv[oldenv.index(loop_start):oldenv.index(loop_end)]==env[env.index(loop_start):env.index(loop_end)]
hash_start='\tvar source_final: Dictionary={}'
receipt_start='\tvar receipt: Dictionary={"ok":true'
assert oldenv[oldenv.index(hash_start):oldenv.index(receipt_start)]==env[env.index(hash_start):env.index(receipt_start)]
assert 'return _install_a2_exact_material' not in env and 'var marker:=Node2D.new()' not in env
assert 'if A2_MATERIAL_READY: artisan_union=_attach_a2_exact_material' in env
assert 'else: artisan_union=attach_artisan_union_transition' in env
assert 'layer.set_meta("ap_environment_receipt",receipt.duplicate(true));world.add_child(layer)' in env
assert 'source_pins[A2_MATERIAL_HELPER]=A2_MATERIAL_HELPER_SHA' in env
assert 'if scene.scene_id!=&"luoyang_artisan_residential_20261022ap"' in method(env,'_attach_a2_exact_material')
assert 'world_size!=SIZE' in material and 'family.a2_source_bound_scene(scene)' in material
assert 'existing: Variant=field.get("_scene_object_nodes")' in material and 'nodes.size()!=132 or data.ground.size()!=118 or data.props.size()!=14' in material
assert 'not world.is_ancestor_of(child)' in material and 'nodes.has(String(child.name))' in material
assert 'node.material!=null' in material and 'if matched.size()!=132 or not owner.call()' in material
attach_at=material.index('# Attach only after the entire118ground+14prop immutable whitelist passed.')
assert material.index('for row: Dictionary in data.props:')<attach_at
assert 'node.material=material' in material[attach_at:]
assert 'not_source_final_credit":true' in material and 'no_geometry_modified":true' in material
out={'status':'INDEPENDENT_FINAL_DRAFT03_SEMANTICS_REVIEW_ONLY_NOT_PARSE_RUNTIME_READY',
 'handoff':{'path':'res://'+H.relative_to(GAME).as_posix(),'sha256':sha(H)},
 'whole_formal_parent_inverse_and_explicit_hunks':deltas,
 'runtime_material_helper':{'path':h['unchanged_false_material_helper']['path'],'sha256':sha(runtime)},
 'fixed_binding':{'path':h['binding']['path'],'sha256':sha(binding),'ready':False},
 'no_static_blocking_issue_found':True,
 'reviewed_contracts':{'publication_A5F2_EC78_EAAB_precise_local_authority':True,
    'native_int_and_JSON_float_proof_domains_separate':True,
    'child_packet_hashed_before_decode_original_plain_kind_scene_and_fullmask_checks':True,
    'original_full_Scene_Layout_matches_and_source_FIRST_FINAL_methods_unchanged':True,
    'no_added_parent_packet_read_decode_clone_or_mask_inverse_replay':True,
    'Garden_original_artifact_path_and_native_branch_unchanged':True,
    'opaque14_source_material_whitelist_before118ground_attach':True,
    'original_complete_alpha_rut_loop_and_finalhash_attach_byte_same':True,
    'new_material_or_old411B_union_mutually_exclusive':True,
    'no_wide_count_or_shader_fallback':True},
 'pending_before_runtime':['Three false readiness flags and pending binding status require Root-authorized exact production successor',
   'Actual new walk two import leaves and final necessary source DAG/owner maps/manifest-index closure',
   'Root-authorized minimal Field actual still needed; no new Field/NPC/Physics/load or whole-ART credit'],
 'opacity_credit_boundary':'Runtime helper preserves all14 prop source transforms/material-null and never writes their alpha. No standalone proof of live inherited CanvasItem alpha-chain from source review; future finite Field check must read it rather than infer it from opaque_props_unchanged label.',
 'future_QA_session_key':'Family._sessions is keyed by scene.get_instance_id(), not scene_id. Read exact weak scene/layout pair; do not invoke matches/validation merely to create credit.',
 'engine_runs':0,'parse_runs':0,'PNG_or_native_decode':0,'original_route_or_mask_replay':0,'G_Field_re_review':False,'collector_calls':0,'canonical_writes':0}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review':str(OUT),'sha256':sha(OUT),'static_blockers':[],'flags':False,'engine':0}))
