"""Final thin driver/input inverse only. Never imports or runs the Stage."""
from pathlib import Path
import copy
import hashlib
import json

Q=Path(__file__).resolve().parent
G=Q.parents[1]
S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
D=S/'performance58_market_parent30_source_recipe'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def res(p): return G/p[6:]
def ptr(v,path):
    for key in path: v=v[key]
    return v
def strict(a,b):
    if type(a) is not type(b): return False
    if isinstance(a,dict): return list(a)==list(b) and all(strict(a[k],b[k]) for k in a)
    if isinstance(a,list): return len(a)==len(b) and all(strict(x,y) for x,y in zip(a,b))
    return a==b
tp=S/'stage_performance58_market_parent30_READY.py'
ip=D/'source_input_ROOT_LOCKED.json'
pp=D/'driver_input_whole_inverse_READY.json'
assert sha(tp)=='f5e9c84d5ad9aad7bc8780da6e23bda3a730ca8aacff78db358093a14b9932a7'
assert sha(ip)=='a29f32c01dcac22c4a1289e5bd5084c4cb76195d7666ee021165d6aba98dd140'
assert sha(pp)=='25a6c30299649d3a3310ce1e0d76ca9986e5a4fd3b7cd66a02c3ad2eb7307343'
p,s=rd(pp),rd(ip)
ot=res(p['parent_driver']['path']);oi=res(p['parent_input']['path'])
assert sha(ot)==p['parent_driver']['sha256'] and sha(oi)==p['parent_input']['sha256']
old,new=ot.read_text(encoding='utf-8'),tp.read_text(encoding='utf-8')
assert len(p['driver_hunks'])==15
chunks=[];cursor=0
for h in p['driver_hunks']:
    assert old[h['old_start']:h['old_end']]==h['old']
    assert new[h['new_start']:h['new_end']]==h['new']
    chunks.extend([old[cursor:h['old_start']],h['new']]);cursor=h['old_end']
chunks.append(old[cursor:])
assert ''.join(chunks).encode()==tp.read_bytes()
chunks=[];cursor=0
for h in p['driver_hunks']:
    chunks.extend([new[cursor:h['new_start']],h['old']]);cursor=h['new_end']
chunks.append(new[cursor:])
assert ''.join(chunks).encode()==ot.read_bytes()
o=rd(oi);back=copy.deepcopy(s)
assert len(p['input_deltas'])==54
for d in p['input_deltas']:
    assert strict(ptr(o,d['pointer']),d['old']) and strict(ptr(s,d['pointer']),d['new'])
    ptr(back,d['pointer'][:-1])[d['pointer'][-1]]=copy.deepcopy(d['old'])
assert strict(back,o)
assert (json.dumps(back,ensure_ascii=False,indent=2)+'\n').encode()==oi.read_bytes()
base=S/'stage_unified06_04_READY.py'
assert sha(base)=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
pins={r['id']:r for r in s['pinned_inputs']}
assert len(pins)==len(s['pinned_inputs'])==49
small=0;inherited=[]
oldpins={r['path']:r['sha256'] for r in o['pinned_inputs']}
backup_rows=rd(res(pins[s['B_only_contract']['backup_input']]['path']))['targets']
backup_pin_by_path={'res://'+Path(r['backup_path']).relative_to(G).as_posix():r for r in backup_rows}
for row in pins.values():
    path=res(row['path'])
    if path.stat().st_size<1048576:
        assert sha(path)==row['sha256'];small+=1
    else:
        if row['path'] in backup_pin_by_path:
            fixed=backup_pin_by_path[row['path']]
            assert row['sha256']==fixed['sha256'] and path.stat().st_size==fixed['bytes']
        elif row['id']=='repair30_prior_owner':
            assert row['sha256']=='fc11a02989c4e9d57628dccaa82c08cd11df6767c954f4ed4829b5dcdffc0f02'
        elif row['id']=='repair30_prior_stage':
            assert row['sha256']=='4c6121af07069bd98b115763ab5e02d7cd8cc2206810b8f9340430708f43a999'
        else:
            assert oldpins.get(row['path'])==row['sha256']
        inherited.append(row['path'])
c=s['B_only_contract']
root=rd(res(pins[c['Root_input']]['path']))
scope=rd(res(pins[c['scope_input']]['path']))
backup=rd(res(pins[c['backup_input']]['path']))
approval=rd(res(pins[c['execution_Root_input']]['path']))
assert strict(approval,c['expected_execution_Root_document'])
assert sha(res(pins[c['execution_Root_input']]['path']))==c['expected_execution_Root_sha256']
assert root['existing_targets']==30 and root['GD_targets']==root['JSON_targets']==15
assert backup['target_count']==30 and len(backup['targets'])==30
oldtargets={r['target']:r['old_sha256'] for r in scope['targets']}
assert list(oldtargets)==s['root_target_allowlist'] and len(oldtargets)==30
backed={'res://'+Path(r['path']).relative_to(G).as_posix():r['sha256'] for r in backup['targets']}
assert backed==oldtargets
owner=rd(res(pins[c['prior_owner_input']]['path']))
assert all(owner['core_source_sha256'][k]==v for k,v in oldtargets.items())
assert sum(k.endswith('.gd') for k in oldtargets)==15 and sum(k.endswith('.json') for k in oldtargets)==15
assert not any(k.endswith(('.res','.bin','.png','.ctex','.import')) for k in oldtargets)
assert len(s['pass_through_targets'])==8 and len(s['prospective_targets'])==8
assert {r['target'] for r in s['pass_through_targets']}=={r['target'] for r in s['prospective_targets']}
assert len(s['required_gates'])==5 and len({r['id'] for r in s['required_gates']})==5
nodes={r['id']:r for r in s['nodes']}
assert len(nodes['registry_final']['operations'])==5
for op in nodes['registry_final']['operations']:
    assert op['pointer'][0]=='rooms' and op['pointer'][2:]==['source_sha256','res://scripts/city/luoyang_district_life_20261016f.gd']
    assert op['old']=='cfb49f34d0bf68ebb6494b5c2e2a5dc3d98c127940d22c8acccc4c6bd680f0d5'
    assert op['new']=='ff20b43ec134188a1d90b1239593590f199e1483f88be0c715d0b5656e6ba7ed'
estateops=nodes['estate_final']['operations']
assert next(op for op in estateops if op['pointer']==['registry_sha256'])['new']=={'$sha':'registry_final'}
assert next(op for op in estateops if op['pointer']==['source_sha256','res://data/maps/luoyang_estate_rooms_20261021am/registry.json'])['new']=={'$sha':'registry_final'}
fade='res://scripts/city/luoyang_district_life_fade_20261016f.gd'
fadeops=[]
for row in s['nodes']:
    for op in row.get('operations',[]):
        if op['pointer']==['source_migration','source_delta',fade]:
            a,b=op['old'],op['new'];fadeops.append(row['id'])
            assert b['historical_sha256']==a['historical_sha256']+['58462561e7db2b3f26fd6e5a55b891fc85002d86c51228a771f354b3ca9311a8']
            assert b['current_before_sha256']==a['new_sha256']=='58462561e7db2b3f26fd6e5a55b891fc85002d86c51228a771f354b3ca9311a8'
            assert b['new_sha256']=='ad42f13efa29cef61f9a24125e1bdcc9c08003fd0336023ae44026dc1097d526'
assert len(fadeops)==4
assert len(s['source_groups'])==len(o['source_groups'])==49
assert strict(s['source_groups'][-1],o['source_groups'][-1])
assert s['source_groups'][-1]['id']=='source_only_proof_autoimport_exact2'
nonowned=['res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd',fade,'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/finite_adapter_READY.gd']
for row in s['source_groups']:
    if row['kind']=='input_dictionary':
        value=ptr(rd(res(pins[row['input']]['path'])),row['pointer'])
        assert not any(k in value for k in nonowned)
maps=[r for r in s['nodes'] if r['kind']=='map']
assert len(maps)==4
for row in maps:
    assert all(op['pointer'][0]=='source_sha256' for op in row['operations'])
    assert not any(op['pointer'][1] in rd(res(pins[s['authority_input']]['path']))['owned'] for op in row['operations'])
for row in s['nodes']:
    if row['kind'] in ['metadata','repair30_contract_literal']:
        for op in row.get('operations',[]):
            assert op['pointer'][0] in ['source_sha256','legacy_source_sha256','runtime_authority_sha256','source_migration','registry_sha256','rooms']
eof=rd(res(pins[c['eof_transport_input']]['path']))
assert eof['candidate_sha256']=='cf2aa3da4f8dbafd30d48d9310d69d7eacb9f17d25e47ce02ca221835eff3736'
candidate=G/'build/luoyang_city_full_rollout_20261022ap_system01/market_parent_receipt_fix_candidate_epoch01/finite_adapter_market_complete_parent_CANDIDATE.gd'
assert hashlib.sha256(candidate.read_bytes()+b'\n').hexdigest()==eof['patch_intermediate_sha256']=='9fc421182b8143f3fe0711322fe51788b443b5a5132dd7c524d961562b0f0025'
assert 'need(not res(self.out).exists()' in new and "with dest.open('xb')" in new
assert new.index("self.output('receipt.json'")<new.index('for path,b in self.outputs.items():')
assert 'M._strict_lf_build_file_patch(target,before,after)' in new
out=Q/'performance58_exact30_driver54inputdelta_static_Stage_admission_retry1_READY.json'
assert not out.exists()
out.write_text(json.dumps({
    'status':'STATIC_NO_BLOCKER_FOR_ONE_ROOT_STAGE58_EXACT30_NOT_EXECUTED_BY_QA',
    'pins':{'driver':sha(tp),'input':sha(ip),'inverse':sha(pp),'fixed_core8DE0':sha(base)},
    'inverse':{'driver_offset_hunks':15,'input_orderedtyped_deltas':54,'whole_driver_byte_and_input_serialized_UTF8_inverse_to51':True},
    'scope':{'exact30_Root_backed_current_FC11_oldSHAs':True,'GD_patch':15,'JSON_exactcopy':15,
        'eight_passthrough_seven_GD_plus_execution':True,'five_original_required_gates_preserved':True,
        'Root_execution_document_real_schema_typed_exact':True,'49pins_current_small_SHA_count':small,
        'large_pins_fixed_Root43_backups_or_previously_reviewed_FC11_4C612_not_rehashed':inherited},
    'DAG':{'registry_only5DT_values':True,'Estate_registry_scalar_and_source_same_generated_registry_SHA':True,
        'culture_contract_original_M_typed_inverse_then_exact_C_literal_byte_successor':True,
        'Fade_successor_rows':fadeops,'four_rows_preserve_history_and_currentbefore5846':True,
        'fourAO_map_ops_only_source_fields_after_owned_promotion_no_duplicate_ownedsetter':True,
        'input_dictionary_groups_no_stale_nonowned_C_Fade_adapter':True,
        'Root39_SOURCE_ONLY_exact2_group_whole_unchanged_Market_only':True,
        'four_T_runtime_authority_classification_not_modified_by_source_only_ops':True,
        'no_native_geometry_media_door_or_NPC_target':True},
    'EOF':{'only_adapter_exact5709_CF2A':True,'shadow9FC421_31207_then_remove_sole_final0A':True,
        'other14GD_original_strict_LF_function':True,'never_direct_final_GD_copy':True},
    'write_safety':{'all_output_buffered_until_full_preflight_and_FIRSTFINAL':True,'new_output_root_only_exclusive_open':True,'no_canonical_write':True},
    'limits':['One Root Stage invocation may proceed; not deployment/runtime/ART approval',
        '57 nine-record and four-owned95pin review inherited DEFBA802 without rereading historical85 code',
        'No whole3GB scan, engine, collector, packet/image decode or Stage was run by QA'],
    'operations':{'Stage':0,'engine':0,'collector':0,'decode':0,'canonical':0}
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'Stage_static_blocker':False,'smallpins':small,'large_not_rehashed':len(inherited)}))
