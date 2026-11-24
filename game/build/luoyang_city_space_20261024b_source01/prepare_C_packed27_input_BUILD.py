"""One27 finite recipe from deployed AF129 declarations; no compiler import."""
from pathlib import Path
import json,hashlib,copy
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/';R='res://build/luoyang_city_revision_20261024b_root01/';D='res://build/luoyang_docks_ordinary_space_20261024b_system01/READY05/'
EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';REGISTRY='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=(GAME/p[6:]).read_bytes();assert h is None or sha(b)==h,(p,sha(b),h);assert b'tokens truncated' not in b;return b
def load(p,h=None):return json.loads(read(p,h))
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def at(v,keys):
    for key in keys:v=v[key]
    return v
old=load(S+'source_input_worker_facts35_ROOT_READY.json','099895a0c20b817fcc90c09480d6ae5581d0f01a9a5b3771ac289488bc941641')
parentpath=S+'outputs/root_market_worker_facts_exact35_stage01/receipt.json';parenthash='af129e34538479d7aaae3a1e87e7194d44fc52354ec44de9dcd41a77eecadd0c';parent=load(parentpath,parenthash)
scopepath=S+'C_packed27_scope_PREPARATION_NOT_STAGE.json';scopehash='a1362cb215c64f241874871e09beb513d5a2162aeba13a1794f0614dece552a4';scope=load(scopepath,scopehash);targets={r['target']:r['old_sha256'] for r in scope['targets']}
proofpath=S+'packed_closure27/code_execution_full_inverse_NOT_STAGE.json';proofhash='e233a9ab53d4767adc9078ceb909791cb61c383638f8626c75f7e8a9344aa6b3';proof=load(proofpath,proofhash);authority=load(proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256'])
pins={r['id']:copy.deepcopy(r) for r in old['pinned_inputs']}
def pin(i,p,h):pins[i]=dict(id=i,path=p,sha256=h);return {'$pin':i}
pin('execution_approval',proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256'])
pin('space_parent_execution',proof['execution']['parent']['path'],proof['execution']['parent']['sha256'])
pin('space_parent_stage',parentpath,parenthash);pin('space_scope',scopepath,scopehash);pin('space_code_inverse',proofpath,proofhash)
pin('space_Root_backup',R+'packed_predeploy27/backup_receipt.json','e35d93961b34bf321dcd0790c1afa58697efa5c1f34667afeb03cf4ff2d685ce')
pin('space_Root_preparation',R+'packed27_preparation_approval.json','cc2749b418a4a38bfc9d405a7c9cfaf9010251502585d222d50ab2005849f770');approval=load(pins['space_Root_preparation']['path'],pins['space_Root_preparation']['sha256'])
pin('space_contract_literal',proof['contract']['candidate']['path'],proof['contract']['candidate']['sha256']);pin('space_temple_binding',proof['temple_binding']['candidate']['path'],proof['temple_binding']['candidate']['sha256'])
refs={p:pin('packed27_code_'+str(i),r['candidate']['path'],r['candidate']['sha256']) for i,(p,r) in enumerate(proof['records'].items())}
refs[EXEC]={'$pin':'execution_approval'};refs[CONTRACT]={'$sha':'runtime_contract_final'}
for n in old['nodes']:
    if n.get('target') in targets and n['target'] not in refs:refs[n['target']]={'$sha':n['id']}
groups={g['id']:copy.deepcopy(g) for g in old['source_groups']}
for group in groups.values():
    if group['kind']=='explicit':
        for p in group['leaves']:
            if p in refs:group['leaves'][p]=copy.deepcopy(refs[p])
groups['packed27_Docks_ordinary_proofs']=dict(id='packed27_Docks_ordinary_proofs',kind='explicit',leaves={D+'C_ordinary_source_wholebyte_proof_READY.json':'213fdb1fec3078970c24b14c004ac47cad5347664a1fd15d271f8a54eda05029',D+'AA_ordinary_source_wholebyte_proof_READY.json':'6df87e86f81f96a695aa0b9b4ce31d185bc0a65b4182fc27825460fe134605f3'})
current={r['target']:dict(path=r['candidate_path'],sha256=r['candidate_sha256']) for r in parent['targets']}
def op(keys,old,new,exists=True):return dict(op='set',pointer=keys,existed=exists,old=copy.deepcopy(old),new=copy.deepcopy(new))
nodes=[]
for original in old['nodes']:
    n=copy.deepcopy(original);ident,kind=n['id'],n['kind']
    if ident=='execution_final':nodes.append(dict(id=ident,kind='space_execution',base_input='execution_approval'));continue
    if ident in ['ENV_code','ground_code','ap_environment_index']:nodes.append(n);continue
    if kind=='map':
        wanted=parent['nodes'][ident]['value']['source_sha256'];seed=load(pins[n['base_input']]['path'],pins[n['base_input']]['sha256'])['source_sha256'];promoted=copy.deepcopy(seed)
        for p in promoted:
            if p in authority['owned']:promoted[p]=authority['owned'][p]['current_sha256']
        operations=[]
        for p,h in wanted.items():
            new=refs.get(p,h)
            if p not in promoted or not isinstance(new,str) or promoted[p]!=new:operations.append(op(['source_sha256',p],promoted.get(p),new,p in promoted))
        for p in set(promoted)-set(wanted):operations.append(dict(op='remove',pointer=['source_sha256',p],existed=True,old=promoted[p],new=None))
        extra=['packed27_Docks_ordinary_proofs'] if n['scene_id']=='ch4_s2_canal_docks' else []
        n['operations']=operations;n['groups']+=extra;n['declared_new_groups']=['authority_before_and_candidate_proofs']+extra;nodes.append(n);continue
    if ident=='registry_final':
        r=parent['nodes'][ident];i='packed27_registry_frozen';pin(i,r['path'],r['sha256'])
        nodes.append(dict(id=ident,kind='space_frozen',base_input=i,immutable_sha256=r['sha256'],is_json=True));continue
    target=n['target'];assert target in targets
    r=current[target];assert r['sha256']==targets[target]
    i='packed27_parent_'+ident;pin(i,r['path'],r['sha256']);n['base_input']=i;n['old_sha256']=r['sha256']
    if kind=='index':
        for h in n['replacements']:
            new=h['new']
            if isinstance(new,dict) and '$sha' in new:h['old']=parent['nodes'][new['$sha']]['sha256']
            elif new=={'$pin':'execution_approval'}:h['old']=proof['execution']['parent']['sha256']
        nodes.append(n);continue
    if ident=='runtime_contract_final':
        n['operations']=[op(['source_sha256',p],c['old_sha256'],refs[p]) for p,c in proof['contract']['changed'].items()]
        assert len(n['operations'])==1;n['file']='runtime_contract_C_source_successor.json';nodes.append(n);continue
    base=parent['nodes'][ident]['value'];fields=n.get('source_bundle',{}).get('fields',[])+[r['pointer'] for r in n.get('source_fields',[])]
    n['operations']=[op(keys+[p],h,refs[p]) for keys in fields for p,h in at(base,keys).items() if p in refs]
    if ident=='estate_final':n['kind']='metadata'
    if n.get('source_bundle') and ident in ['legacy_manifest_4','legacy_manifest_6','legacy_manifest_7']:n['source_bundle']['groups'].append('packed27_Docks_ordinary_proofs')
    nodes.append(n)
spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=list(groups.values()),root_target_allowlist=list(targets),output_root=S+'outputs/root_C_packed_exact27_stage01/',
    source_baseline='Deployed AF129/A93D fixed tables plus exact27 literal source successors; sole finite Packed decoder; native/media/runtime/adapter/Field/UI and original source classification unchanged')
passed=[dict(target=p,old_sha256=r['parent']['sha256'],candidate_path=r['candidate']['path'],candidate_sha256=r['candidate']['sha256']) for p,r in proof['records'].items()]
e=proof['execution'];passed.append(dict(target=EXEC,old_sha256=e['parent']['sha256'],candidate_path=e['candidate']['path'],candidate_sha256=e['candidate']['sha256']))
spec['pass_through_targets']=passed;spec['prospective_targets']=[dict(target=r['target'],candidate_path=r['candidate_path'],sha256=r['candidate_sha256']) for r in passed]
for gate in spec['required_gates']:
    if gate['id']=='root_target_preauthorization':gate.update(input='space_Root_backup',pointer=['count'],equals=27)
c=spec['space_contract'];c.update(Root_backup_prefix=R+'packed_predeploy27/backups/',expected_Root_preparation_document=approval,expected_proofs=132)
driver=S+'stage_C_packed27_NOTREADY.py';spec['required_generator']=dict(path=driver,sha256=sha(read(driver)))
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,w in v.items():
            if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input'] and isinstance(w,str) and w in pins:used.add(w)
            if k=='$pin':used.add(w)
            collect(w)
    elif isinstance(v,list):
        for w in v:collect(w)
collect(spec);used.update(['space_scope','space_parent_stage','space_parent_execution','space_code_inverse','space_Root_backup','space_Root_preparation','space_binding','space_publication','space_temple_binding','space_dialogue_admission'])
spec['pinned_inputs']=[r for k,r in pins.items() if k in used]
assert len(targets)==27 and len(passed)==6 and sum('target' in n for n in nodes)+len(passed)==27
# Structural old-value and dependency checks only; no Stage or source scanning.
known=set();gg={g['id']:g for g in spec['source_groups']};oldptr=0
def checkrefs(v):
    if isinstance(v,dict):
        if '$sha' in v:assert v['$sha'] in known,('EARLY_NODE',v)
        if '$pin' in v:assert v['$pin'] in used
        for w in v.values():checkrefs(w)
    elif isinstance(v,list):
        for w in v:checkrefs(w)
def checkgroup(i,stack):
    assert i not in stack;g=gg[i];checkrefs(g)
    if g['kind']=='node_dictionary':assert g['node'] in known
    if g['kind']=='union':
        for x in g['groups']:checkgroup(x,stack+[i])
for n in nodes:
    checkrefs(n.get('operations',[]));checkrefs(n.get('replacements',[]))
    if n.get('operations') and n['kind']!='map':
        base=parent['nodes'][n['id']]['value']
        for o in n['operations']:
            holder=at(base,o['pointer'][:-1]);key=o['pointer'][-1];assert (key in holder)==o['existed'] and (not o['existed'] or holder[key]==o['old']);oldptr+=1
    for i in n.get('source_bundle',{}).get('groups',[])+n.get('groups',[])+[i for f in n.get('source_fields',[]) for i in f.get('groups',[])]:checkgroup(i,[])
    known.add(n['id'])
raw=enc(spec);dest=HERE/'source_input_C_packed27_ROOT_READY.json'
with dest.open('xb') as f:f.write(raw)
assert json.loads(dest.read_bytes())==spec
print(json.dumps(dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw),targets=27,nodes=len(nodes),groups=len(spec['source_groups']),pins=len(spec['pinned_inputs']),old_metadata_pointers=oldptr,strict_node_DAG=True)))
