"""Mechanical35 recipe from deployed516C; no Stage/collector/live expectations."""
from pathlib import Path
import json,hashlib,copy
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/';R='res://build/luoyang_city_revision_20261024b_root01/'
D='res://build/luoyang_docks_ordinary_space_20261024b_system01/READY04/'
EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
REGISTRY='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
G='res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
DT='res://scripts/city/luoyang_district_life_20261016f.gd'
FADE='res://scripts/city/luoyang_district_life_fade_20261016f.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=(GAME/p[6:]).read_bytes();assert h is None or sha(b)==h,(p,sha(b),h);assert b'tokens truncated' not in b;return b
def load(p,h=None):return json.loads(read(p,h))
def encode(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def at(v,keys):
    for k in keys:v=v[k]
    return v
parentpath=S+'outputs/root_market_dialogue_exact36_stage02/receipt.json';parenthash='516c535b908d5fb22d8620311431e2c1e8a13d01b4f0289d7d81732f4aeefd8c'
parent=load(parentpath,parenthash)
old=load(S+'source_input36_estate_registry02_ROOT_READY.json','6a1a0c78a7898a15526291f156c46d15f94c5f6382c44ffbc27e39579f839235')
proofpath=S+'worker_facts_closure35/code_execution_full_inverse_NOT_STAGE.json';proofhash='ab2e5b657d465407c8375d6b060b1510162fb426a6387acd6ac11934386225db';proof=load(proofpath,proofhash)
scopepath=S+'worker_facts35_scope_PREPARATION_NOT_STAGE.json';scopehash='3f990ee1bd4d45baa762f622c4410d5e6091680db89975fd6d051ed4b82e9f5a';scope=load(scopepath,scopehash)
oldtargets={r['target']:r['old_sha256'] for r in scope['targets']}
authority=load(proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256'])
literal=load(S+'worker_facts03/literal_candidates_and_four_facts_inverse_BUILD.json','e9c703aefb6de7290fdc8f66688399a1b3685d769a6356a835207eb8c52adbfb')
pins={p['id']:copy.deepcopy(p) for p in old['pinned_inputs']}
def pin(i,p,h):pins[i]=dict(id=i,path=p,sha256=h);return {'$pin':i}
pin('execution_approval',proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256'])
pin('space_parent_execution',proof['execution']['parent']['path'],proof['execution']['parent']['sha256'])
pin('space_parent_stage',parentpath,parenthash);pin('space_scope',scopepath,scopehash);pin('space_code_inverse',proofpath,proofhash)
pin('space_Root_backup',R+'worker_facts_predeploy35/backup_receipt.json','6c47b16fe01b6c71ace9fef922ff8e35e2658c3fc8400c1a709624cc4d394459')
pin('space_Root_preparation',R+'worker_facts35_preparation_approval.json','b79a718d89f9370d05ea3c3164a0a3a3770898bc5a4e5b4e9472ab2171de3c5e')
approval=load(pins['space_Root_preparation']['path'],pins['space_Root_preparation']['sha256'])
pin('space_contract_literal',proof['contract']['candidate']['path'],proof['contract']['candidate']['sha256'])
pin('space_temple_binding',proof['temple_binding']['candidate']['path'],proof['temple_binding']['candidate']['sha256'])
refs={p:pin('facts35_code_'+str(i),r['candidate']['path'],r['candidate']['sha256']) for i,(p,r) in enumerate(proof['records'].items())}
refs[EXEC]={'$pin':'execution_approval'};refs[CONTRACT]={'$sha':'runtime_contract_final'};refs[REGISTRY]={'$sha':'registry_final'}
for n in old['nodes']:
    if n.get('target') in oldtargets and n['target'] not in refs:refs[n['target']]={'$sha':n['id']}
groups={g['id']:copy.deepcopy(g) for g in old['source_groups']}
for group in groups.values():
    if group['kind']=='explicit':
        for p in group['leaves']:
            if p in refs:group['leaves'][p]=copy.deepcopy(refs[p])
newadapter=literal['records']['adapter']['candidate'];newruntime=literal['records']['runtime']['candidate']
groups['facts35_adapter']=dict(id='facts35_adapter',kind='explicit',leaves={newadapter['path']:newadapter['sha256']})
groups['facts35_runtime']=dict(id='facts35_runtime',kind='explicit',leaves={newruntime['path']:newruntime['sha256']})
groups['facts35_Docks_ordinary_proofs']=dict(id='facts35_Docks_ordinary_proofs',kind='explicit',leaves={D+'C_ordinary_source_wholebyte_proof_READY.json':'9e8ea745f8d25b0af58e50328b2c6283883debf34f7015caaa35eebd16eb8b99',D+'AA_ordinary_source_wholebyte_proof_READY.json':'3e8c8367414e16d515d3f6b000ac8d122b3854ea6e89accbd45049851e40e987'})
groups['common_four_city']['groups'].append('facts35_adapter')
def op(keys,old,new,exists=True):return dict(op='set',pointer=keys,existed=exists,old=copy.deepcopy(old),new=copy.deepcopy(new))
def sourceops(base,fields):
    return [op(keys+[p],h,refs[p]) for keys in fields for p,h in at(base,keys).items() if p in refs]
current={r['target']:dict(path=r['candidate_path'],sha256=r['candidate_sha256']) for r in parent['targets']}
nodes=[]
for original in old['nodes']:
    n=copy.deepcopy(original);ident,kind=n['id'],n['kind']
    if ident=='execution_final':nodes.append(dict(id=ident,kind='space_execution',base_input='execution_approval'));continue
    if ident in ['ENV_code','ground_code']:
        key='ENV' if ident=='ENV_code' else 'ground';r=literal['records'][key]['candidate'];i='facts35_'+ident;pin(i,r['path'],r['sha256'])
        nodes.append(dict(id=ident,kind='space_code',base_input=i,immutable_sha256=r['sha256'],is_json=False));continue
    if kind=='map':
        wanted=parent['nodes'][ident]['value']['source_sha256'];seed=load(pins[n['base_input']]['path'],pins[n['base_input']]['sha256'])['source_sha256']
        promoted=copy.deepcopy(seed)
        for p in promoted:
            if p in authority['owned']:promoted[p]=authority['owned'][p]['current_sha256']
        operations=[]
        for p,h in wanted.items():
            new=refs.get(p,h)
            if p not in promoted or not isinstance(new,str) or promoted[p]!=new:operations.append(op(['source_sha256',p],promoted.get(p),new,p in promoted))
        for p in set(promoted)-set(wanted):operations.append(dict(op='remove',pointer=['source_sha256',p],existed=True,old=promoted[p],new=None))
        extra=['facts35_adapter']
        if G in wanted:extra.append('facts35_runtime')
        if n['scene_id']=='ch4_s2_canal_docks':extra.append('facts35_Docks_ordinary_proofs')
        n['operations']=operations;n['groups']+=extra;n['declared_new_groups']=['authority_before_and_candidate_proofs']+extra;nodes.append(n);continue
    if ident=='ap_environment_index':nodes.append(n);continue
    target=n['target'];source=current[target];assert source['sha256']==oldtargets[target]
    i='facts35_parent_'+ident;pin(i,source['path'],source['sha256']);n['base_input']=i;n['old_sha256']=source['sha256']
    base=parent['nodes'][ident].get('value')
    if kind=='index':
        for h in n['replacements']:
            new=h['new']
            if isinstance(new,dict) and '$sha' in new:h['old']=parent['nodes'][new['$sha']]['sha256']
            elif new=={'$pin':'execution_approval'}:h['old']=proof['execution']['parent']['sha256']
        nodes.append(n);continue
    if ident=='runtime_contract_final':
        n['operations']=[op(['source_sha256',p],c['old_sha256'],refs[p]) for p,c in proof['contract']['changed'].items()];nodes.append(n);continue
    if ident=='registry_final':
        n['operations']=[op(['rooms',room,'source_sha256',DT],row['source_sha256'][DT],refs[DT]) for room,row in base['rooms'].items() if row.get('source_sha256',{}).get(DT)==oldtargets[DT]]
        assert len(n['operations'])==5;nodes.append(n);continue
    fields=n.get('source_bundle',{}).get('fields',[])+[r['pointer'] for r in n.get('source_fields',[])]
    n['operations']=sourceops(base,fields)
    if ident=='estate_final':n['kind']='space_estate_registry';n['operations'].append(op(['registry_sha256'],base['registry_sha256'],refs[REGISTRY]))
    if base.get('source_migration',{}).get('source_delta',{}).get(FADE):
        previous=base['source_migration']['source_delta'][FADE];updated=copy.deepcopy(previous);currentfade=proof['records'][FADE]['parent']['sha256']
        if currentfade not in updated['historical_sha256']:updated['historical_sha256'].append(currentfade)
        updated.update(current_before_sha256=currentfade,new_sha256=proof['records'][FADE]['candidate']['sha256'],candidate_path=proof['records'][FADE]['candidate']['path'])
        n['operations'].append(op(['source_migration','source_delta',FADE],previous,updated))
    if n.get('source_bundle'):
        n['source_bundle']['groups'].append('facts35_adapter')
        if any(G in at(base,keys) for keys in fields):n['source_bundle']['groups'].append('facts35_runtime')
        if ident in ['legacy_manifest_4','legacy_manifest_6','legacy_manifest_7']:n['source_bundle']['groups'].append('facts35_Docks_ordinary_proofs')
    if ident=='finite08_market':
        n['kind']='metadata';n['protected_pointers']=[[k] for k in ['geometry_proof_basis','artifacts','mask_sha256','parent_publication','finite_delta_parent_publication','author_path','author_sha256','layout_proof']]
    nodes.append(n)
spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=list(groups.values()),root_target_allowlist=list(oldtargets),output_root=S+'outputs/root_market_worker_facts_exact35_stage01/',
    source_baseline='Deployed Stage516C declarations and Root6C47 full35 backups; only four exact artifact facts functional hunk; all native/media/UI/old source classifications inherited')
passed=[dict(target=p,old_sha256=r['parent']['sha256'],candidate_path=r['candidate']['path'],candidate_sha256=r['candidate']['sha256']) for p,r in proof['records'].items()]
e=proof['execution'];passed.append(dict(target=EXEC,old_sha256=e['parent']['sha256'],candidate_path=e['candidate']['path'],candidate_sha256=e['candidate']['sha256']))
spec['pass_through_targets']=passed;spec['prospective_targets']=[dict(target=r['target'],candidate_path=r['candidate_path'],sha256=r['candidate_sha256']) for r in passed]
for gate in spec['required_gates']:
    if gate['id']=='root_target_preauthorization':gate.update(input='space_Root_backup',pointer=['count'],equals=35)
c=spec['space_contract'];c.update(Root_backup_prefix=R+'worker_facts_predeploy35/backups/',expected_Root_preparation_document=approval,expected_proofs=127)
driver=S+'stage_worker_facts35_NOTREADY.py';spec['required_generator']=dict(path=driver,sha256=sha(read(driver)))
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,w in v.items():
            if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input'] and isinstance(w,str) and w in pins:used.add(w)
            if k=='$pin':used.add(w)
            collect(w)
    elif isinstance(v,list):
        for w in v:collect(w)
collect(spec)
used.update(['space_scope','space_parent_stage','space_parent_execution','space_code_inverse','space_Root_backup','space_Root_preparation','space_binding','space_publication','space_temple_binding','space_dialogue_admission'])
spec['pinned_inputs']=[r for k,r in pins.items() if k in used]
assert len(oldtargets)==35 and len(passed)==13 and sum('target' in n for n in nodes)+len(passed)==35
# Finite-only structural audit. No compiler import/source leaf verification.
known=set();groupby={g['id']:g for g in spec['source_groups']}
def refs_ok(v):
    if isinstance(v,dict):
        if '$sha' in v:assert v['$sha'] in known,('EARLY_NODE',v)
        if '$pin' in v:assert v['$pin'] in used
        for w in v.values():refs_ok(w)
    elif isinstance(v,list):
        for w in v:refs_ok(w)
def checkgroup(i,stack):
    assert i not in stack;g=groupby[i];refs_ok(g)
    if g['kind']=='node_dictionary':assert g['node'] in known
    if g['kind']=='union':
        for child in g['groups']:checkgroup(child,stack+[i])
for n in nodes:
    refs_ok(n.get('operations',[]));refs_ok(n.get('replacements',[]))
    for i in n.get('source_bundle',{}).get('groups',[])+n.get('groups',[])+[i for f in n.get('source_fields',[]) for i in f.get('groups',[])]:checkgroup(i,[])
    known.add(n['id'])
raw=encode(spec);dest=HERE/'source_input_worker_facts35_ROOT_READY.json'
with dest.open('xb') as stream:stream.write(raw)
assert json.loads(dest.read_bytes())==spec
print(json.dumps(dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw),targets=35,nodes=len(nodes),groups=len(spec['source_groups']),pins=len(spec['pinned_inputs']),strict_node_DAG=True)))
