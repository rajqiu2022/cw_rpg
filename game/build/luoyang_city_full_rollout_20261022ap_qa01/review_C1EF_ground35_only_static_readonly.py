"""Ground-only sufficient finite count admission review; no engine or geometry."""
from pathlib import Path
import hashlib
import json

Q=Path(__file__).resolve().parent;G=Q.parents[1]
D=G/'build/luoyang_city_full_rollout_20261022ap_system01/market_ground_finite_count_candidate_epoch01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(p):return G/p[6:]
pp=D/'authorproof_and_wholebyte_inverse_READY_NOT_RUNTIME.json'
assert sha(pp)=='2cb284c359ece3eff07efe379d02a1ea7f88fa6f1e717896b821b184eb20d00d'
p=rd(pp);cp=res(p['candidate']['path']);bp=res(p['parent']['path'])
child,parent=cp.read_bytes(),bp.read_bytes()
assert sha(cp)=='c1ef10bce6ef1b4b8ff4e50f7a00a7e409b80e8c36cfed9d4eea33fedcce05ce' and len(child)==8495
assert sha(bp)=='02a43e66bee985eaf67b6184d43270454ba3d648fbee8ae2789e0e188fabafd3' and len(parent)==7748
assert child.endswith(b'\n') and parent.endswith(b'\n') and b'\r' not in child+parent
assert len(p['hunks'])==2
insert,condition=p['hunks'];helper=insert['new'].encode()
assert insert['old']=='' and child.count(helper)==1
inverse=child.replace(helper,b'')
a,b=condition['old'].encode(),condition['new'].encode()
assert inverse.count(b)==1 and parent.count(a)==1
assert inverse.replace(b,a)==parent
forward=parent.replace(a,b)
anchor=b'static func prepare('
assert forward.count(anchor)==1
forward=forward.replace(anchor,helper+anchor,1)
assert forward==child
text=child.decode()
assert helper.index(b'base_render.size()==BASE_COUNT: return true') < helper.index(b'base_render.size()!=BASE_COUNT-1')
assert b'scene==null or scene.scene_id!=ID or scene.map_layout==null' in helper
assert b'if native.size()!=23: return false' in helper
assert b'if row.get("id")=="v13_market_west_plot_wall": return false' in helper
assert b'b.finite_market_retired_visual_id(scene,"v13_market_west_plot_wall",native)' in helper
assert b'finite_market_retired_visual_id(scene,"v13_market_west_plot_wall",base_render)' not in helper
Bpath=G/'scripts/city/luoyang_precomputed_bundle_20261018r.gd'
Apath=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/finite_adapter_READY.gd'
B,A=Bpath.read_text(encoding='utf-8-sig'),Apath.read_text(encoding='utf-8-sig')
assert sha(Bpath)=='2488a13465cc992071440fa223259586dba552259ed0e60e3271ce7a1e7d61ae'
assert sha(Apath)=='cf2aa3da4f8dbafd30d48d9310d69d7eacb9f17d25e47ce02ca221835eff3736'
state=B[B.index('static func finite_market_child_state('):B.index('static func whole_bound(')]
assert 'if not whole_bound(scene): return {"requested":true,"ok":false}' in state
assert 'adapter.market_public_session_proof(scene,session.data,session.config)' in state
assert 'proof.get("ok")!=true or typeof(proof.get("token"))!=TYPE_INT or proof.token<=0' in state
assert 'if id!="v13_market_west_plot_wall": return false' in state
assert '_finite_native_adapter().market_retired_entry_proven(scene,id,parent_objects,state)' in state
api=A[A.index('static func _render_storage('):A.index('static func native_low_prop_role_valid(')]
assert '_b()._storage_value(rows,graph)' in api
assert 'graph.invalid==null and graph.resources.is_empty() and encoded is Dictionary' in api
assert '_state_matches(scene,state,"market") and _same(_render_storage(parent_objects),_packets.market.layout_storage.fields.visual_objects)' in api
assert 'proof.get("scene")!=scene' in A and 'int(proof.get("token",0))!=session.token' in A
pub=res(p['fixed_cause']['publisher_result'])
assert sha(pub)=='6118b1fef2453eb99dbe4a5ceb743249728feb01ccf5064b0c3d0902acf203fa'
published=rd(pub)
assert published['market']['finite_proof']['combined_visual36_to35'] is True
assert published['market']['finite_proof']['DG12_unchanged'] is True
manifest=res(p['unchanged_ground_manifest']['path'])
assert sha(manifest)==p['unchanged_ground_manifest']['sha256'].lower()
m=rd(manifest)
assert len(m['source_sha256'])==5 and len(m['overlays'])==1 and m['overlays'][0]['opacity']==0.38
assert 'res://scripts/city/luoyang_market_ground_20261020ae.gd' not in m['source_sha256']
for retained in ['MARKET_GROUND_BUNDLE_OWNER','MARKET_GROUND_FIRST_SOURCE_OWNER','MARKET_GROUND_TEXTURE_PROOF','MARKET_GROUND_ACTUAL_RGBA','MARKET_GROUND_WHOLE_PNG_REQUIRED','MARKET_GROUND_OWNER_CHANGED']:
    assert text.count(retained)==parent.decode().count(retained)
out=Q/'C1EF_ground_finite35_sufficient_contract_static_admission_NOT_RUNTIME_READY.json'
assert not out.exists()
out.write_text(json.dumps({
    'status':'STATIC_NO_BLOCKER_GROUND_ONLY_EXACT_FINITE35_PREPARATION_NOT_RUNTIME_READY',
    'pins':{'candidate':sha(cp),'parent':sha(bp),'authorproof':sha(pp),'B':sha(Bpath),'adapter':sha(Apath),'published_source_fact':sha(pub)},
    'wholebyte':{'insert_one_helper_and_replace_one_count_condition_forward_inverse_exact':True,
        'all_other_ground_functions_and_source_RGBA_owner_checks_byteidentical':True,'parent_candidate_LF_final_noCR':True},
    'sufficient_contract':{'legacy36_fastpath_before_extra_checks_no_new_B_call':True,
        'prepare_scene_ID_owner_valid_and_owner_call_order_original':True,
        'new35_only_sameMarket_native23_and_fixed_westwall_absent':True,
        'passes_native23_Array_not_DG35_to_existing_B_API':True,
        'adapter_render_storage_compares_complete_native_layout_Array_typed_wrapper':True,
        'B_full_whole_bound_sameScene_layout_and_same_positive_FIRSTtoken_proof_preserved':True,
        'not_metaalone_not_arbitrary35_count_acceptance':True,
        'no_new_whole35_recomposition_expected_from_actual':True,
        'DT_G_AP_source_chain_existing_native23_plus_DG12_inherited_not_geometry_replayed':True},
    'downstream':{'unchanged_ground_manifest5_sources_oneWear_opacity038':True,
        'original_full_parent_render_identity_and_overlay_texture_RGBA_and_finalowner_checks_retained':True,
        'no_B_DT_C_Fade_adapter_G_implementation_or_executionowned_change':True},
    'limits':['Allows preparation of minimal source-only propagation; final DAG still needs audit',
        'No parse/engine/Field/nextgate or ART pass from this source review',
        'ROOT44 aggregate error was not a measured subpredicate trace; deterministic source23+12 mismatch proof is separate',
        'No media or geometry replay and no packet decode'],
    'operations':{'engine':0,'parse':0,'collector':0,'packet_image_decode':0,'geometry':0,'Stage':0,'canonical':0}
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'static_blocker':False}))
