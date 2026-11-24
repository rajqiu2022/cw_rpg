"""Thin exact8 final static audit; never imports or invokes the Stage."""
from pathlib import Path
import copy
import hashlib
import json

Q=Path(__file__).resolve().parent;G=Q.parents[1];S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
D=S/'performance62_ground8_source_recipe'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(p):return G/p[6:]
def at(v,ks):
    for k in ks:v=v[k]
    return v
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return list(a)==list(b) and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
tp=S/'stage_performance62_ground8_READY.py';ip=D/'source_input_ROOT_LOCKED.json';pp=D/'driver_input_whole_inverse_READY.json'
assert sha(tp)=='b7114e62b03dca467030ad2c6fde04bbd8367aa1267776866e5fe92fc983067c'
assert sha(ip)=='48d8f26e1b16cfde0636feab432a21ec20e137279ac9b1e9c5bae02b2e4ff277'
assert sha(pp)=='7f50f649df72f1f2327354c3a4bba4a0851536f38a54ebae0cf8ce76452a1399'
p,s=rd(pp),rd(ip)
ot,oi=res(p['parent_driver']['path']),res(p['parent_input']['path'])
assert sha(ot)==p['parent_driver']['sha256'] and sha(oi)==p['parent_input']['sha256']
old,new=ot.read_text(encoding='utf-8'),tp.read_text(encoding='utf-8')
assert len(p['driver_hunks'])==17
forward=[];backward=[];a=b=0
for h in p['driver_hunks']:
    assert old[h['old_start']:h['old_end']]==h['old'] and new[h['new_start']:h['new_end']]==h['new']
    forward.extend([old[a:h['old_start']],h['new']]);a=h['old_end']
    backward.extend([new[b:h['new_start']],h['old']]);b=h['new_end']
forward.append(old[a:]);backward.append(new[b:])
assert ''.join(forward).encode()==tp.read_bytes() and ''.join(backward).encode()==ot.read_bytes()
o=rd(oi);inverse=copy.deepcopy(s)
assert len(p['input_deltas'])==12
for d in p['input_deltas']:
    assert same(at(o,d['pointer']),d['old']) and same(at(s,d['pointer']),d['new'])
    at(inverse,d['pointer'][:-1])[d['pointer'][-1]]=copy.deepcopy(d['old'])
assert same(inverse,o) and (json.dumps(inverse,ensure_ascii=False,indent=2)+'\n').encode()==oi.read_bytes()
assert sha(S/'stage_unified06_04_READY.py')=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
pins={x['id']:x for x in s['pinned_inputs']};assert len(pins)==46
c=s['B_only_contract'];scope=rd(res(pins[c['scope_input']]['path']));backup=rd(res(pins[c['backup_input']]['path']))
root=rd(res(pins[c['admission_input']]['path']))
assert scope['target_count']==backup['target_count']==8
assert root['scope_sha256']==pins[c['scope_input']]['sha256']=='ceaab710ea5aba573cb892e06acd21c6549c67e1f0b9e1a136f2d22496119deb'
assert root['old_full_backups_sha256']==pins[c['backup_input']]['sha256']=='e488247289964b59af23f794c90946054b51ce452c498900e27e5c4700419aef'
assert root['before_sha256']==pins[c['before_input']]['sha256']=='c168a30baf8a4d9435468e276810f6220d445864813bdecfb795e065b3d2e355'
oldtargets={x['target']:x['old_sha256'] for x in scope['targets']}
assert list(oldtargets)==s['root_target_allowlist'] and len(oldtargets)==8
assert sum(p.endswith('.gd') for p in oldtargets)==sum(p.endswith('.json') for p in oldtargets)==4
assert {'res://'+Path(x['path']).relative_to(G).as_posix():x['sha256'] for x in backup['targets']}==oldtargets
stage=rd(res(pins[c['parent_stage_input']]['path']));owner=rd(res(pins[c['prior_owner_input']]['path']))
GROUND='res://scripts/city/luoyang_market_ground_20261020ae.gd'
assert GROUND not in owner['core_source_sha256']
prior={x['target']:x['candidate_sha256'] for x in stage['targets']}
prior[GROUND]=next(x for x in owner['scenes'] if x['id']=='ch4_s3_luoyang_market')['source_sha256'][GROUND]
assert all(prior[p]==h for p,h in oldtargets.items())
assert 'prior[GROUND]=next(r for r in self.owner[\'scenes\']if r[\'id\']==\'ch4_s3_luoyang_market\')[\'source_sha256\'][GROUND]' in new
authority=rd(res(pins[s['authority_input']]['path']))
assert pins[s['authority_input']]['sha256']=='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3'
assert len(authority['owned'])==10 and len(authority['source_sha256'])==95 and GROUND not in authority['owned'] and GROUND not in authority['source_sha256']
assert not s['pass_through_targets'] and not s['prospective_targets']
assert same(s['source_groups'],o['source_groups']) and len(s['source_groups'])==49
assert len(s['required_gates'])==5 and len({x['id'] for x in s['required_gates']})==5
nodes={x['id']:x for x in s['nodes']}
assert s['nodes'][0]['id']=='ground_code' and nodes['ground_code']['kind']=='ground8_code'
assert sum(x['kind']=='ground8_frozen' for x in s['nodes'])==16
assert sum(x['kind']=='metadata' for x in s['nodes'])==4 and sum(x['kind']=='index' for x in s['nodes'])==3
for row in s['nodes']:
    if row['kind']=='metadata':
        for op in row['operations']:
            assert op['pointer'][0]=='legacy_source_sha256'
            assert op['pointer'][1] in [GROUND,'res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json']
    if row['kind']=='map':
        assert all(op['pointer'][0]=='source_sha256' and op['pointer'][1] not in authority['owned'] for op in row['operations'])
        groundops=[op for op in row['operations'] if op['pointer']==['source_sha256',GROUND]]
        if row['scene_id']=='ch4_s3_luoyang_market':assert len(groundops)==1 and groundops[0]['old']==oldtargets[GROUND]
        else:assert not groundops
assert '_exact_eof_transport_patch' not in new and 'old_shadow' not in new and 'M._strict_lf_build_file_patch(res(row[\'target\']).as_posix(),before,candidate)' in new
assert 'FOUR_FULL_FIXED_E717_MAPS_EXACT8_VALUES_KEYS_COUNTS_UNCHANGED' in new
assert new.index("self.output('receipt.json'")<new.index('for path,b in self.outputs.items():')
assert "with dest.open('xb')" in new and "need(not res(self.out).exists()" in new
small=0;large=[]
fixed={x['candidate_path']:x['candidate_sha256'] for x in stage['targets']}
fixed.update({x['path']:x['sha256'] for x in stage['nodes'].values()})
for row in pins.values():
    path=res(row['path'])
    if path.stat().st_size<1048576:
        assert sha(path)==row['sha256'];small+=1
    else:
        assert fixed.get(row['path'],{'ground8_prior_stage':'464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f','ground8_prior_owner':'e7177cb8e97e957bab6f0f88bbcbb5bb5d82de4087f2bb45085d4cf06f2a1f03'}.get(row['id']))==row['sha256']
        large.append(row['path'])
for row in s['source_groups']:
    if row['kind']=='input_dictionary':assert GROUND not in at(rd(res(pins[row['input']]['path'])),row['pointer'])
out=Q/'stage62_ground8_17tool12input_inverse_final_static_admission_READY.json'
assert not out.exists()
out.write_text(json.dumps({
    'status':'STATIC_NO_BLOCKER_FOR_ONE_ROOT_STAGE62_EXACT8_NOT_EXECUTED_BY_QA',
    'pins':{'driver':sha(tp),'input':sha(ip),'wholeinverse':sha(pp)},
    'checks':{'17driver_offset_hunks_wholebyte_forward_inverse51':True,'12input_orderedtyped_serialized_UTF8_inverse58':True,
        'fixed8DE0_all_original_gates_typed_map_media_FIRSTFINAL_unchanged':True,
        'exact8_4GD4JSON_Root45_scope_backups_schema_and_fixed_old_values':True,
        'only_ground_old02A4_from_fixed_E717_Market_not_core47_other7_from464BA':True,
        'ground_first_nonowned_target_then4_existing_source_manifests_and3indices':True,
        'whole49groups58_unchanged_nine_input_dictionary_groups_no_old_ground':True,
        'fixed_execution647949_10owned95pins_noedge_noproofkey':True,
        'four_complete_maps_E717_existing_values_only_sourcecounts_unchanged':True,
        'Root39SOURCE_ONLY2_and_all_otherdomains_frozen':True,
        'all4GD_original_strictLF_noEOFtransport_or_GDcopy':True,
        'all_buffered_until_final_source_preflight_newroot_xb_only':True,
        'current_small_pin_SHA_count':small,'large_metadata_fixed_actual_inherited_not_rehashed':large},
    'limits':['One Root Stage may proceed; not deployment, Field or ART approval',
        'No new Market key generated; wait actualowner and Rootformal guard',
        'No engine/collector/packetdecode/geometry/mediahash or Stage imported/invoked'],
    'operations':{'engine':0,'collector':0,'Stage':0,'decode':0,'canonical':0,'key_generation':0}
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'static_blocker':False,'smallpins':small,'large_inherited':len(large)}))
