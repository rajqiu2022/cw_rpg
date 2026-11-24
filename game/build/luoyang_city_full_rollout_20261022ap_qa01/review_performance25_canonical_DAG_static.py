"""Final B-only22 input/driver static review. Never imports compiler or Stage."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://');q=(ROOT/p[6:]).resolve();assert q.is_relative_to(ROOT);return q
def load(p,h=None):
    b=p.read_bytes()
    if h:assert sha(b)==h,(p,'SHA')
    return json.loads(b)
def same(a,b):
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
def at(v,ptr):
    for k in ptr:v=v[k]
    return v
ip=SF/'performance25_canonical_B_source_recipe/source_input_ROOT_LOCKED.json';s=load(ip,'706c58929266d6e0a9cf58a6b94f959383b5d34133acf059cc424251634473bd')
tool=(SF/'stage_performance25_canonical_B_READY.py').read_bytes();assert sha(tool)=='b7176b80b7be48c3114984909de35088eac55e446c44622a1293caf60516950c'
proof=load(SF/'performance25_canonical_B_source_recipe/driver_and_input_whole_inverse_READY.json','4053defd259178d3e0b78cc893be8dc70627cf920f0998437a5b34a6a7d03289')
old=res(proof['parent_tool']['path']).read_bytes();assert sha(old)==proof['parent_tool']['sha256']
def hunks_forward(raw,rows,reverse=False):
    out=[];cursor=0
    for row in rows:
        prefix='new'if reverse else'old';other='old'if reverse else'new';a=row[prefix+'_byte_start'];b=row[prefix+'_byte_end']
        assert a>=cursor and raw[a:b]==row[prefix].encode();out.extend([raw[cursor:a],row[other].encode()]);cursor=b
    out.append(raw[cursor:]);return b''.join(out)
assert hunks_forward(old,proof['tool_hunks'])==tool and hunks_forward(tool,proof['tool_hunks'],True)==old
assert sha((SF/'stage_unified06_04_READY.py').read_bytes())=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
oldinput_raw=res(proof['parent_input']['path']).read_bytes();assert sha(oldinput_raw)==proof['parent_input']['sha256']=='231b66e6beaebdf7c72966e2ce1a19ee56bb3a643f254fbbe20efbcc6f713697'
input_back=copy.deepcopy(s)
for delta in reversed(proof['input_deltas']):
    ptr=delta['pointer'];holder=at(input_back,ptr[:-1]);assert same(holder[ptr[-1]],delta['new']);holder[ptr[-1]]=copy.deepcopy(delta['old'])
assert same(input_back,json.loads(oldinput_raw))and (json.dumps(input_back,indent=2,ensure_ascii=False)+'\n').encode()==oldinput_raw
pins={r['id']:r for r in s['pinned_inputs']};assert len(pins)==46
rawpins={}
for k,row in pins.items():
    b=res(row['path']).read_bytes();assert sha(b)==row['sha256'];rawpins[k]=b
def inp(k):return json.loads(rawpins[k])
c=s['B_only_contract'];root=inp(c['execution_root_input']);scope=inp(c['scope_input']);request=inp(c['scope_request_input'])
assert pins[c['execution_root_input']]['sha256']==c['expected_root_execution_sha256']=='cea7e23ae7d79af8933a0871ce83178c0cceb465a3a31672b4aa9492af2840ed'
assert same(root,c['expected_root_execution_document'])and root['approved_by_root']and not root['stage_execution_authorized']and not root['formal_deployment_authorized']
assert pins[c['scope_input']]['sha256']==c['expected_scope_sha256']=='e12015172ba201b9b5cee989e617d42d9ea30b0f5865d859928b58bb1ac6229f'
assert same(scope,c['expected_scope_document'])and scope['approved_by_root']and scope['target_count']==22 and scope['GD_count']==9 and scope['JSON_count']==13
assert pins[c['actual_parent_stage_input']]['sha256']=='7912fdd9a540b06c1d4804976a0fe582dcea9387daf2077ff20aca98c84617cf'
oldowner=inp(c['prior_owner_input']);assert pins[c['prior_owner_input']]['sha256']=='5050ba8038aa1fbdf5c07f086427f5230171a93819ca5a6dd8ebb8da30d54e4e'and oldowner['actual_stage_receipt']['sha256']=='7912fdd9a540b06c1d4804976a0fe582dcea9387daf2077ff20aca98c84617cf'
parentstage=inp(c['actual_parent_stage_input']);parenttargets={r['target']:r['candidate_sha256']for r in parentstage['targets']}
targets={r['target']:r['old_sha256']for r in request['targets']};assert len(targets)==22 and targets=={r['target']:r['old_sha256']for r in scope['targets']}
declared=[r['target']for r in s['pass_through_targets']]+[r['target']for r in s['nodes']if 'target'in r]
assert len(declared)==len(set(declared))==22 and set(declared)==set(targets)==set(s['root_target_allowlist'])and all(parenttargets[p]==h for p,h in targets.items())
assert sum(p.endswith('.gd')for p in targets)==9 and sum(p.endswith('.json')for p in targets)==13
for row in scope['targets']:
    b=res(row['target']).read_bytes();backup=Path(row['backup_path']).read_bytes();assert b==backup and sha(b)==row['old_sha256']==row['backup_sha256']
excluded=['res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/city/luoyang_parallel_source_hash_20261017k.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd','res://data/maps/luoyang_estate_rooms_20261021am/registry.json','res://scripts/city/luoyang_quarters_family_20261022ap.gd','res://scripts/city/luoyang_environment_layer_20261022ap.gd','res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd','res://data/luoyang_culture_integration_20261019x/runtime_contract.json']
assert not set(excluded)&set(targets)
authority=inp(s['authority_input']);prior=inp(c['parent_approval_input']);assert len(authority['owned'])==10 and len(authority['source_sha256'])==71 and len(prior['source_sha256'])==69
for row in s['prospective_targets']:assert sha(res(row['candidate_path']).read_bytes())==row['sha256']
nodes={r['id']:r for r in s['nodes']};groups={r['id']:r for r in s['source_groups']};assert len(nodes)==27 and len(groups)==48
def refs(v):
    if isinstance(v,dict):
        if '$sha'in v:yield('n',v['$sha'])
        for x in v.values():yield from refs(x)
    elif isinstance(v,list):
        for x in v:yield from refs(x)
seen=set();active=set()
def visit(kind,ident):
    pair=(kind,ident);assert pair not in active
    if pair in seen:return
    active.add(pair);row=(nodes if kind=='n'else groups)[ident];deps=list(refs(row));deps += [('g',x)for x in row.get('groups',[])]
    if kind=='g'and row['kind']=='node_dictionary':deps.append(('n',row['node']))
    for f in row.get('source_fields',[]):deps += [('g',x)for x in f.get('groups',[])]
    deps += [('g',x)for x in row.get('source_bundle',{}).get('groups',[])]
    for d in deps:visit(*d)
    active.remove(pair);seen.add(pair)
for k in nodes:visit('n',k)
def val(v):
    if isinstance(v,dict):
        if '$pin'in v:return pins[v['$pin']]['sha256']
        if '$sha'in v:return '@node:'+v['$sha']
        return{k:val(x)for k,x in v.items()}
    if isinstance(v,list):return[val(x)for x in v]
    return v
hashp='res://scripts/city/luoyang_parallel_source_hash_20261017k.gd';newhash='85a7b0b86ca201679b227b1f39c7315bb7196b4d0943befa5397ce569fe650e1';oldchecks=0;tables=0
for g in groups.values():
    if g['kind']=='input_dictionary':
        src=at(inp(g['input']),g['pointer']);assert hashp not in src;tables+=1
    elif g['kind']=='explicit'and hashp in g['leaves']:assert g['leaves'][hashp]==newhash
for row in s['nodes']:
    if row['kind']=='B_only_frozen_node':
        assert row['id']in('registry_final','runtime_contract_final','ap_environment_index')and 'target'not in row
        if row['id']=='registry_final':assert pins[row['base_input']]['sha256']=='040664f7a2c73087b6c47e5f4d000cb4955648dd61b830d76d2a7ce54cafd95c'
        continue
    if row['kind']=='index':
        text=rawpins[row['base_input']].decode()
        for h in row['replacements']:assert text.count(h['old'])==1;text=text.replace(h['old'],str(val(h['new'])),1)
        continue
    value=inp(row['base_input'])
    if row['kind']=='map':
        value={'source_sha256':copy.deepcopy(value['source_sha256'])}
        for p in value['source_sha256']:
            if p in authority['owned']:value['source_sha256'][p]=authority['owned'][p]['current_sha256']
        assert any(o['pointer']==['source_sha256',hashp]and o['new']==newhash for o in row['operations'])
    for op in row.get('operations',[]):
        ptr=op['pointer'];holder=at(value,ptr[:-1]);k=ptr[-1]
        assert (k in holder)==op['existed']and(k not in holder or same(holder[k],op['old'])),(row['id'],ptr)
        if row['kind']=='metadata':assert ptr[0]in('source_sha256','owned_source_sha256','legacy_source_sha256','runtime_authority_sha256','runtime_source_successions','registry_sha256','source_migration','ap_source_successor')
        if op['op']=='remove':del holder[k]
        else:holder[k]=val(op['new'])
        oldchecks+=1
    if row['kind']=='metadata':
        for f in row.get('source_fields',[]):assert at(value,f['pointer']).get(hashp,newhash)==newhash
        for ptr in row.get('source_bundle',{}).get('fields',[]):assert at(value,ptr).get(hashp,newhash)==newhash
        if row['id'].startswith('finite08_'):
            assert not any(p.startswith('res://data/maps/luoyang_layout_bundle_20261018t_retry2/')for p in value['legacy_source_sha256'])
            for ptr in [['geometry_proof_basis'],['artifacts'],['mask_sha256'],['parent_publication']]:assert ptr in row['protected_pointers']
assert tables==9
assert nodes['quarter_final']['protected_pointers']==[['scenes'],['connections'],['seed_provenance']]
for gate in s['required_gates']:assert same(at(inp(gate['input']),gate['pointer']),gate['equals'])
assert len(s['required_gates'])==5
t=tool.decode();assert 'old!=expected'in t and 'PATCH9_COPY13_EXACT_DISJOINT_UNION22'in t and 'ALL_PINNED_SOURCE_FIRST_FINAL_SAME'in t and "final={path:sha(res(path).read_bytes()) for path in self.first}"in t
assert t.index("need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED")<t.index('for path,b in self.outputs.items():')
for k,row in pins.items():assert res(row['path']).read_bytes()==rawpins[k]
out=QA/'performance25_driverB717_input706C_independent_DAG_static_review_READY.json'
r={'status':'INDEPENDENT_FINAL_BONLY22_DAG_STATIC_NO_BLOCKER_NOT_STAGE_AUTHORITY','driver_sha256':sha(tool),'input_sha256':sha(ip.read_bytes()),'whole_driver_forward_inverse_0C709':True,'frozen_M8DE0_algorithm_bytes_exact':True,'46_pins_first_final_exact':True,'Root_E120_scope_and_CEA7_execution_actual_schema_exact':True,'actual_7912_parent_targets_exact':True,'22_current_old_and_full_backups_exact':True,'partition':{'GD':9,'JSON':13},'registry040664_contract_ENVindex_frozen_non_targets':True,'DT_hash_Temple_and_other7_exclusions_unchanged':True,'DAG_node_group_pairs':len(seen),'source_groups':48,'old_pointer_checks_operations_order_exact':oldchecks,'immutable_source_dictionaries_no_hidden_old_hash':tables,'fourT_source_classes_and_geometry_mask_r3_parent_protections':True,'Quarter_scene_connections_seed_protected':True,'five_original_gates_kept':True,'full_source_fresh_read_first_final_and_buffered_newonly_outputs_kept':True,'engine_Stage_import_collector_or_media_hash':False,'canonical_writes':0,'blocking_findings':[],'next':'Root may separately authorize exactly one source stage with full external input SHA lock; no deployment/runtime approval.'}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes()),'oldptrs':oldchecks}))
