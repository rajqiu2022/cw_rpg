"""Read-only independent final26 driver/input audit. Never imports Stage."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://');q=(ROOT/p[6:]).resolve();assert q.is_relative_to(ROOT);return q
def load(p,s=None):
    b=p.read_bytes()
    if s:assert sha(b)==s
    return json.loads(b)
def same(a,b):
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def at(v,ks):
    for k in ks:v=v[k]
    return v
ip=SF/'performance07_source_recipe/source_input_ROOT_LOCKED.json';tp=SF/'stage_performance07_READY.py'
s=load(ip,'1e40d5b252afd5246f78cc14a00ea541cdd940cb31011077d26105cf12842d95')
tool=tp.read_bytes();assert sha(tool)=='5db6aadad7de09caac94579633ce99f03da05aa1d42ad62c9a32c296e0d8709f'
proof=load(SF/'performance07_source_recipe/source_tool_and_input_inverse_READY.json','d1b8f5910f0fbfd8216c869da7d92acf78766c5eef45a3e42edb5eb0c84798c3')
oldtool=res(proof['parent_tool']['path']).read_bytes();assert sha(oldtool)==proof['parent_tool']['sha256']
forward=oldtool.decode()
for h in proof['hunks']:assert forward.count(h['old'])==1;forward=forward.replace(h['old'],h['new'],1)
assert forward.encode()==tool
back=tool.decode()
for h in reversed(proof['hunks']):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==oldtool
core=SF/'stage_unified06_04_READY.py';assert sha(core.read_bytes())=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
pins={r['id']:r for r in s['pinned_inputs']};assert len(pins)==45
rawpins={};first={}
for k,r in pins.items():
    b=res(r['path']).read_bytes();assert sha(b)==r['sha256'];rawpins[k]=b;first[r['path']]=sha(b)
def inp(k):return json.loads(rawpins[k])
c=s['performance_contract'];root=inp(c['execution_root_input'])
assert pins[c['execution_root_input']]['sha256']=='f934dff214d96eb1cc9dbe45914db90a8094d8be0d9560fc9a9cbe5f907b878b'
assert same(root,c['expected_root_execution_document']) and root['approved_by_root'] is True
assert root['stage_execution_authorized'] is False and root['formal_deployment_authorized'] is False
authority=inp(s['authority_input']);hand=inp(c['production_input'])
assert len(authority['owned'])==10 and len(authority['source_sha256'])==67
for r in hand['owned_changed_exactly3']:
    assert same(authority['owned'][r['path']]['edges'][-1],r)
hashp='res://scripts/city/luoyang_parallel_source_hash_20261017k.gd';oldhash='80261e1bf9b34400c6aa99959d98502b648589fccf2138231f3907d9826d8b0b';newhash='85a7b0b86ca201679b227b1f39c7315bb7196b4d0943befa5397ce569fe650e1'
assert hashp not in authority['owned']
scope=inp(c['scope_input']);request=inp(c['scope_request_input'])
assert scope['approved_by_root'] and scope['target_count']==26 and scope['GD_count']==12 and scope['JSON_count']==14
targets={r['target']:r for r in request['targets']};declared=[r['target']for r in s['pass_through_targets']]+[r['target']for r in s['nodes']if 'target'in r]
assert len(declared)==len(set(declared))==26 and set(declared)==set(targets)==set(s['root_target_allowlist'])
assert sum(p.endswith('.gd')for p in declared)==12 and sum(p.endswith('.json')for p in declared)==14
for row in scope['targets']:
    b=res(row['target']).read_bytes();backup=Path(row['backup_path']).read_bytes()
    assert sha(b)==row['old_sha256']==row['backup_sha256'] and backup==b
excluded=['res://scripts/city/luoyang_quarters_family_20261022ap.gd','res://scripts/city/luoyang_environment_layer_20261022ap.gd','res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd','res://data/luoyang_culture_integration_20261019x/runtime_contract.json']
assert not set(excluded)&set(targets)
for row in s['prospective_targets']:assert sha(res(row['candidate_path']).read_bytes())==row['sha256']
groups={r['id']:r for r in s['source_groups']};nodes={r['id']:r for r in s['nodes']};assert len(groups)==48 and len(nodes)==27
tables=[]
for g in groups.values():
    if g['kind']=='input_dictionary':
        table=at(inp(g['input']),g['pointer']);assert hashp not in table,(g['id'],'nonowned old hash via immutable table')
        tables.append({'group':g['id'],'keys':len(table),'HASH':'ABSENT'})
    elif g['kind']=='explicit' and hashp in g['leaves']:assert g['leaves'][hashp]==newhash
def refs(v):
    if isinstance(v,dict):
        if '$sha'in v:yield('n',v['$sha'])
        for x in v.values():yield from refs(x)
    elif isinstance(v,list):
        for x in v:yield from refs(x)
seen=set();active=set();edges=0
def visit(kind,ident):
    global edges
    pair=(kind,ident);assert pair not in active
    if pair in seen:return
    active.add(pair);row=(nodes if kind=='n' else groups)[ident];deps=list(refs(row))
    deps += [('g',x)for x in row.get('groups',[])]
    if kind=='g' and row['kind']=='node_dictionary':deps.append(('n',row['node']))
    for f in row.get('source_fields',[]):deps += [('g',x)for x in f.get('groups',[])]
    deps += [('g',x)for x in row.get('source_bundle',{}).get('groups',[])]
    for d in deps:edges+=1;visit(*d)
    active.remove(pair);seen.add(pair)
for name in nodes:visit('n',name)
def val(v):
    if isinstance(v,dict):
        if '$pin'in v:return pins[v['$pin']]['sha256']
        if '$sha'in v:return '@node:'+v['$sha']
        return{k:val(x)for k,x in v.items()}
    if isinstance(v,list):return[val(x)for x in v]
    return v
oldchecks=0
for row in s['nodes']:
    if row['kind']=='performance_frozen_node':assert row['id']in('runtime_contract_final','ap_environment_index') and 'target'not in row;continue
    if row['kind']=='index':
        text=rawpins[row['base_input']].decode()
        for h in row['replacements']:assert text.count(h['old'])==1;text=text.replace(h['old'],str(val(h['new'])),1)
        continue
    value=inp(row['base_input'])
    if row['kind']=='map':
        value={'source_sha256':copy.deepcopy(value['source_sha256'])}
        for p in value['source_sha256']:
            if p in authority['owned']:value['source_sha256'][p]=authority['owned'][p]['current_sha256']
        hashops=[o for o in row['operations']if o['pointer']==['source_sha256',hashp]]
        assert len(hashops)==1 and hashops[0]['old']==oldhash and hashops[0]['new']==newhash
    for op in row.get('operations',[]):
        holder=at(value,op['pointer'][:-1]);k=op['pointer'][-1];assert (k in holder)==op['existed'] and (k not in holder or same(holder[k],op['old'])),(row['id'],op['pointer'])
        if op['op']=='remove':del holder[k]
        else:holder[k]=val(op['new'])
        oldchecks+=1
    if row['kind']=='metadata':
        for f in row.get('source_fields',[]):
            table=at(value,f['pointer']);assert table.get(hashp,newhash)==newhash,(row['id'],'old nonowned hash in source field')
        for ptr in row.get('source_bundle',{}).get('fields',[]):
            table=at(value,ptr);assert table.get(hashp,newhash)==newhash,(row['id'],'old nonowned hash in bundle')
reg=nodes['registry_final'];assert reg['kind']=='metadata'and len(reg['operations'])==5
for op in reg['operations']:
    assert len(op['pointer'])==4 and op['pointer'][0]=='rooms'and op['pointer'][2]=='source_sha256'and op['pointer'][3]=='res://scripts/city/luoyang_district_life_20261016f.gd'
    assert op['old']=='185b51ff7b9256657424ba0681660d6d335f890f6c919260b3f467384d03ac16'and op['new']=='39242c343d2e4981c2773b39fd79d84a451aab923a173a099eb8fb9b290acbe2'
for name in ['finite08_market','finite08_yamen']:
    row=nodes[name];base=inp(row['base_input']);assert not any(p.startswith('res://data/maps/luoyang_layout_bundle_20261018t_retry2/') for p in base['legacy_source_sha256'])
    assert row['source_bundle']['new_source_routes'][0]['destination']==['runtime_authority_sha256']
    for ptr in [['geometry_proof_basis'],['artifacts'],['mask_sha256'],['parent_publication']]:assert ptr in row['protected_pointers']
assert nodes['quarter_final']['protected_pointers']==[['scenes'],['connections'],['seed_provenance']]
for gate in s['required_gates']:assert same(at(inp(gate['input']),gate['pointer']),gate['equals'])
assert {x['id']for x in s['required_gates']}=={'market_native_publication','garden_background_permission','artisan_native_publication','garden_native_publication','root_target_preauthorization'}
text=tool.decode();assert 'ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED'in text and text.index("need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED")<text.index('for p,b in self.outputs.items():')
assert 'old!=expected'in text and 'PATCH12_COPY14_EXACT_DISJOINT_UNION26'in text
assert all(sha(res(p).read_bytes())==digest for p,digest in first.items())
out=QA/'performance07_driver5DB6_input1E40_independent_static_review_READY.json'
r={'status':'INDEPENDENT_FINAL26_SOURCE_DRIVER_INPUT_STATIC_NO_BLOCKER_NOT_STAGE_AUTHORITY','driver_sha256':sha(tool),'input_sha256':sha(ip.read_bytes()),'whole_driver_forward_inverse_to_A2source07_exact':True,'imported_M8DE0_bytes_exact_unchanged':True,'RootF934_actual_document_fulltyped_exact':True,'current_pins_first_final_exact':45,'RootD3EB26_full_old_backups_exact':True,'targets':26,'partition':{'GDpatch':12,'JSONcopy':14},'six_excluded_paths_exact':excluded,'immutable_input_dictionary_HASH_check':tables,'all9_immutable_source_tables_parallel_hash_absent':len(tables)==9,'all_existing_metadata_hash_explicitly_new_before_merge':True,'four_maps_nonowned_HASH_explicit_80261_to85A7':True,'metadata_old_pointers_checked':oldchecks,'groups':48,'node_group_DAG_pairs':len(seen),'dependency_edges':edges,'registry_five_DT_explicit_successors_only':True,'fourT_runtime_sourceclass_routes_and_mask_r3_parent_protected':True,'Quarter_native_scenes_connections_seed_no_delta':True,'five_required_gates_retained_actual_true':True,'no_noop_and_new_output_buffer_guard_retained':True,'source_geometry_or_media_targets':False,'review_Stage_engine_collector_or_native_decode_calls':0,'canonical_writes':0,'blocking_findings':[],'next':'Root may separately authorize exactly one source stage with external full input hash. This receipt does not authorize deployment/runtime.'}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes()),'oldpointer_checks':oldchecks}))
