"""One exact30 recipe: fixed latest declarations, final code, three finite source groups."""
from pathlib import Path
import json,hashlib,copy,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024c_source01/';P='res://build/luoyang_city_space_20261024b_source01/';R='res://build/luoyang_city_revision_20261024c_root01/';Y='res://build/luoyang_yamen_courts_20261024c_system01/'
EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';REGISTRY='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h and b'tokens truncated' not in b,(p,sha(b));return b
def load(p,h):return json.loads(read(p,h))
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def out(name,b):
    p=HERE/name
    with p.open('xb') as f:f.write(b)
    assert p.read_bytes()==b
    return dict(path=S+name,sha256=sha(b),bytes=len(b))
def at(v,ks):
    for k in ks:v=v[k]
    return v
def op(ks,a,b,ex=True):return dict(op='set',pointer=ks,existed=ex,old=copy.deepcopy(a),new=copy.deepcopy(b))
oldpath=P+'source_input_ENV_texture_union18_residual02_ROOT_READY.json';oldsha='be6595a374369182fe615cf8ab78f6cbb449f2001a3e41c2b40c3a73a6c60fcd';oldraw=read(oldpath,oldsha);old=json.loads(oldraw)
template=load(P+'source_input_worker_facts35_ROOT_READY.json','099895a0c20b817fcc90c09480d6ae5581d0f01a9a5b3771ac289488bc941641')
baseline=load(S+'current24b_formal_target_declarations_READONLY.json','4b591c8043820fd4ccc0d614a33dce6b3c9a53ae28f30de6937751e9e38c7fb7')
scopepath=S+'exact30_old_scope_PREPARATION_NOT_STAGE.json';scopehash='8fe4a63d01a0196bf05c8ff1768be08d2ce99ff9a0a826c88f230f380eecfef3';scope=load(scopepath,scopehash)
targets={r['target']:r['old_sha256'] for r in scope['targets']};current={r['target']:dict(path=r['immutable_snapshot'],sha256=r['old_sha256']) for r in baseline['targets']}
stages=[load(r['path'],r['sha256']) for r in baseline['formal_stages']];parent=stages[-1];parentpin=baseline['formal_stages'][-1]
latest_nodes={}
for stage in stages:latest_nodes.update(stage['nodes'])
proofpath=S+'code_dependencies30_READY/seven_code_execution_whole_inverse_NOT_STAGE.json';proofhash='559c7447719c31305ae27b90557f8223349704c5cb59a7d4e674eb31e0a7326c';proof=load(proofpath,proofhash)
authority=load(proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256'])
handoff=load(Y+'runtime04_READY/handoff_READY.json','e882ad1ff64bd784abb45dc87b34e79c1f7a5c9d75e4eb523dfdda7c0ea520a8')
field=load(S+'Field_courts_scholar_wholebyte_inverse_NOTREADY.json','431d92a9480e8cd138d415efe080a720fb6b86adad174e0d654edf504255189c')
ordinary=load(S+'ordinary_layers02_READY/layered_ordinary_whole_byte_inverse_NOTREADY.json','706ef2e8ce3dd5094fcb89870ad3eee889e96855248e917b2d84dddb99847523')
pins={r['id']:copy.deepcopy(r) for r in old['pinned_inputs']}
def pin(i,p,h):pins[i]=dict(id=i,path=p,sha256=h);return {'$pin':i}
pin('execution_approval',proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256'])
pin('space_parent_execution',proof['execution']['parent']['path'],proof['execution']['parent']['sha256'])
pin('space_parent_stage',parentpin['path'],parentpin['sha256']);pin('space_scope',scopepath,scopehash);pin('space_code_inverse',proofpath,proofhash)
pin('space_Root_backup',R+'exact30_old_backup/receipt.json','f55b46d79bac42868f840232f491569c6dc952c8518a576ddd61d7df3d1114fb')
pin('space_Root_preparation',R+'exact30_preparation_authorization.json','9c63a9086afb0713b7dfc39de60ed3be5dad61637fdb69af38cdaa3c6edebb1a')
pin('courts_Root_protection','res://build/luoyang_city_revision_20261024b_root01/c_start_fresh_observation.json','18eee16cb341f01a984acd1f260dd1511e0e543e0d61b90789cef3f960d5712a')
approval=load(pins['space_Root_preparation']['path'],pins['space_Root_preparation']['sha256'])
pin('courts_binding',handoff['files']['binding']['path'],handoff['files']['binding']['sha256'])
pin('courts_handoff',Y+'runtime04_READY/handoff_READY.json','e882ad1ff64bd784abb45dc87b34e79c1f7a5c9d75e4eb523dfdda7c0ea520a8')
pin('courts_ordinary',proof['ordinary_layers']['path'],proof['ordinary_layers']['sha256'])
pin('space_contract_literal',proof['contract']['candidate']['path'],proof['contract']['candidate']['sha256'])
pin('space_temple_binding',proof['temple_binding']['candidate']['path'],proof['temple_binding']['candidate']['sha256'])
refs={p:pin('courts_code_'+str(i),r['candidate']['path'],r['candidate']['sha256']) for i,(p,r) in enumerate(proof['records'].items())}
refs[EXEC]={'$pin':'execution_approval'};refs[CONTRACT]={'$sha':'runtime_contract_final'}
for n in template['nodes']:
    if n.get('target') in targets and n['target'] not in refs:refs[n['target']]={'$sha':n['id']}
groups={g['id']:copy.deepcopy(g) for g in old['source_groups']}
for g in groups.values():
    if g['kind']=='explicit':
        for p in g['leaves']:
            if p in refs:g['leaves'][p]=copy.deepcopy(refs[p])
yamen=copy.deepcopy(handoff['source_paths']['exact_required_source_sha256']);assert len(yamen)==13
for name in ['runtime','binding']:r=handoff['files'][name];assert r['path'] not in yamen;yamen[r['path']]=r['sha256']
groups['courts_Yamen_exact15']=dict(id='courts_Yamen_exact15',kind='explicit',leaves=yamen)
groups['portrait_Market_exact3']=copy.deepcopy(field['new_source_group']);groups['portrait_Market_exact3']['id']='portrait_Market_exact3'
groups['courts_Docks_ordinary2']=dict(id='courts_Docks_ordinary2',kind='explicit',leaves=ordinary['source_new_ordinary_leaves'])
assert len(groups['portrait_Market_exact3']['leaves'])==3 and len(groups['courts_Docks_ordinary2']['leaves'])==2
def additions(ident):
    if ident in ['legacy_manifest_3','finite08_yamen','expected_ch4_s1_luoyang_yamen_true']:return ['courts_Yamen_exact15']
    if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market','expected_ch4_s3_luoyang_market_true']:return ['portrait_Market_exact3']
    if ident in ['legacy_manifest_4','legacy_manifest_6','legacy_manifest_7','expected_ch4_s2_canal_docks_true']:return ['courts_Docks_ordinary2']
    return []
nodes=[]
for original in template['nodes']:
    n=copy.deepcopy(original);ident,kind=n['id'],n['kind'];r=latest_nodes[ident]
    if ident=='execution_final':nodes.append(dict(id=ident,kind='space_execution',base_input='execution_approval'));continue
    if n.get('target') not in targets and kind!='map':
        i='courts_frozen_'+ident;pin(i,r['path'],r['sha256']);nodes.append(dict(id=ident,kind='space_frozen',base_input=i,immutable_sha256=r['sha256'],is_json=r.get('value') is not None));continue
    if kind=='map':
        # Seed is the original fixed AO baseline; the complete latest table is the desired old domain.
        n=copy.deepcopy(next(x for x in old['nodes'] if x['id']==ident))
        wanted=parent['nodes'][ident]['value']['source_sha256'];seed=load(pins[n['base_input']]['path'],pins[n['base_input']]['sha256'])['source_sha256'];promoted=copy.deepcopy(seed)
        for p in promoted:
            if p in authority['owned']:promoted[p]=authority['owned'][p]['current_sha256']
        n['operations']=[op(['source_sha256',p],promoted.get(p),refs.get(p,h),p in promoted) for p,h in wanted.items() if p not in promoted or p in refs or promoted[p]!=h]
        n['operations']+=[dict(op='remove',pointer=['source_sha256',p],existed=True,old=promoted[p],new=None) for p in set(promoted)-set(wanted)]
        n['groups']+=additions(ident);n['declared_new_groups']=['authority_before_and_candidate_proofs']+additions(ident);nodes.append(n);continue
    target=n['target'];assert target in targets and r['sha256']==targets[target]
    i='courts_parent_'+ident;pin(i,r['path'],r['sha256']);n['base_input']=i;n['old_sha256']=r['sha256']
    if kind=='index':
        edits=[]
        for h in n['replacements']:
            v=h['new']
            if isinstance(v,dict) and '$sha' in v:edits.append(dict(old=latest_nodes[v['$sha']]['sha256'],new=v))
            elif v=={'$pin':'execution_approval'}:edits.append(dict(old=proof['execution']['parent']['sha256'],new=v))
            elif h['old']=='const FORMAL_ENABLED=true' and v=='const FORMAL_ENABLED=false':edits.append(h)
            else:raise AssertionError(('UNKNOWN_INDEX_EDIT',ident,h))
        assert len([h for h in edits if h['new']=='const FORMAL_ENABLED=false'])==1
        n['replacements']=edits;nodes.append(n);continue
    base=r['value']
    if ident=='runtime_contract_final':
        n['operations']=[op(['source_sha256',p],c['old_sha256'],refs[p]) for p,c in proof['contract']['changed'].items()]
        n['literal_candidate_input']='space_contract_literal';n['kind']='space_contract';n['file']='runtime_contract_C_Field_source_successor.json';nodes.append(n);continue
    if ident=='registry_final':
        paths=[x['pointer'] for x in original['operations']];assert len(paths)==5 and all(p[-1]=='res://scripts/city/luoyang_district_life_20261016f.gd' for p in paths)
        n['operations']=[op(p,at(base,p),refs[p[-1]]) for p in paths];nodes.append(n);continue
    fields=n.get('source_bundle',{}).get('fields',[])+[f['pointer'] for f in n.get('source_fields',[])]
    n['operations']=[op(ks+[p],h,refs[p]) for ks in fields for p,h in at(base,ks).items() if p in refs]
    if ident=='estate_final':
        n['kind']='space_estate_registry';n['operations'].append(op(['registry_sha256'],base['registry_sha256'],{'$sha':'registry_final'}))
    if n.get('source_bundle'):n['source_bundle']['groups']+=additions(ident)
    else:assert not additions(ident),('NEW_GROUP_WITHOUT_SOURCE_BUNDLE',ident)
    nodes.append(n)
spec=copy.deepcopy(old)
spec.update(nodes=nodes,source_groups=list(groups.values()),root_target_allowlist=list(targets),output_root=S+'outputs/root_courts_scholar_exact30_stage01/',
 source_baseline='Latest four deployed24b declarations plus exact30 existing-value successors; Yamen-only courts15, Market-only portrait3, Docks-only ordinary2. Original native/worker/Packed/ENV/room/author semantics unchanged; no current fill.')
passed=[dict(target=p,old_sha256=r['parent']['sha256'],candidate_path=r['candidate']['path'],candidate_sha256=r['candidate']['sha256']) for p,r in proof['records'].items()]
e=proof['execution'];passed.append(dict(target=EXEC,old_sha256=e['parent']['sha256'],candidate_path=e['candidate']['path'],candidate_sha256=e['candidate']['sha256']))
spec['pass_through_targets']=passed;spec['prospective_targets']=[dict(target=x['target'],candidate_path=x['candidate_path'],sha256=x['candidate_sha256']) for x in passed]
for gate in spec['required_gates']:
    if gate['id']=='root_target_preauthorization':gate.update(input='space_Root_backup',pointer=['count'],equals=30)
c=spec['space_contract'];c.update(Root_backup_prefix=R+'exact30_old_backup/',Root_protection_input='courts_Root_protection',expected_Root_preparation_document=approval,root_input_freeze_pending=False,expected_proofs=139,courts_binding_input='courts_binding')
driver=S+'stage_courts_scholar30_NOTREADY.py';driverraw=(GAME/driver[6:]).read_bytes();assert sha(driverraw)=='007835570ff10f00a9621c55cf47c6c0ebb5d407e87b09d578e0ad4956fefd44'
spec['required_generator']=dict(path=driver,sha256=sha(driverraw))
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,w in v.items():
            if (k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input'] or k.endswith('_input')) and isinstance(w,str) and w in pins:used.add(w)
            if k=='$pin':used.add(w)
            collect(w)
    elif isinstance(v,list):
        for w in v:collect(w)
collect(spec);used.update(['space_scope','space_parent_stage','space_parent_execution','space_code_inverse','space_Root_backup','space_Root_preparation','courts_Root_protection','courts_binding','courts_handoff','courts_ordinary','space_binding','space_publication','space_temple_binding','space_dialogue_admission'])
spec['pinned_inputs']=[r for k,r in pins.items() if k in used]
assert len(targets)==30 and len(passed)==8 and sum('target' in n for n in nodes)+len(passed)==30
# Static old-pointer and topological group checks only, not Stage execution.
known=set();oldptr=0
def checkrefs(v):
    if isinstance(v,dict):
        if '$sha' in v:assert v['$sha'] in known,('EARLY_NODE',v)
        if '$pin' in v:assert v['$pin'] in used
        for w in v.values():checkrefs(w)
    elif isinstance(v,list):
        for w in v:checkrefs(w)
def checkgroup(i,stack):
    assert i not in stack;g=groups[i];checkrefs(g)
    if g['kind']=='node_dictionary':assert g['node'] in known
    if g['kind']=='union':
        for z in g['groups']:checkgroup(z,stack+[i])
for n in nodes:
    checkrefs(n.get('operations',[]));checkrefs(n.get('replacements',[]))
    if n.get('operations') and n['kind']!='map':
        base=latest_nodes[n['id']]['value']
        for z in n['operations']:
            holder=at(base,z['pointer'][:-1]);k=z['pointer'][-1];assert (k in holder)==z['existed'] and (not z['existed'] or holder[k]==z['old']);oldptr+=1
    for i in n.get('source_bundle',{}).get('groups',[])+n.get('groups',[])+[i for f in n.get('source_fields',[]) for i in f.get('groups',[])]:checkgroup(i,[])
    known.add(n['id'])
raw=enc(spec);inp=out('source_input_courts_scholar30_READY_FOR_ROOT_REVIEW.json',raw);assert json.loads(raw)==spec
# Physical line-segment byte patch: full inverse proof without any model-rendered giant table.
left,right=oldraw.decode().splitlines(keepends=True),raw.decode().splitlines(keepends=True);delta=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,left,right,autojunk=False).get_opcodes():
    if tag!='equal':delta.append(dict(old_offset=sum(len(x.encode()) for x in left[:i]),new_offset=sum(len(x.encode()) for x in right[:k]),old=''.join(left[i:j]),new=''.join(right[k:l])))
f=oldraw
for d in reversed(delta):
    i=d['old_offset'];a,b=d['old'].encode(),d['new'].encode();assert f[i:i+len(a)]==a;f=f[:i]+b+f[i+len(a):]
back=raw
for d in reversed(delta):
    i=d['new_offset'];a,b=d['old'].encode(),d['new'].encode();assert back[i:i+len(b)]==b;back=back[:i]+a+back[i+len(b):]
assert f==raw and back==oldraw
patch=out('stage30_input_full_byte_patch_BUILD.json',enc(dict(parent=dict(path=oldpath,sha256=oldsha),candidate=inp,replacements=delta,wholebyte_forward_inverse=True)))
review=out('stage30_package_review_BUILD.json',enc(dict(status='EXACT30_RECIPE_BUILD_READY_FOR_ROOT_READ_NOT_EXECUTED',driver=spec['required_generator'],input=inp,input_wholebyte_inverse=patch,code_inverse=dict(path=proofpath,sha256=proofhash),target_count=30,partition=dict(GD=15,JSON=15),pass_through=8,nodes=len(nodes),groups=len(groups),pins=len(spec['pinned_inputs']),old_pointers_checked=oldptr,strict_DAG_checked=True,source_new_groups={g:groups[g] for g in ['courts_Yamen_exact15','portrait_Market_exact3','courts_Docks_ordinary2']},source_classification='ordinary new leaves default legacy; unchanged runtime authority whitelist',Root_backup=spec['pinned_inputs'][next(i for i,r in enumerate(spec['pinned_inputs']) if r['id']=='space_Root_backup')],engine_calls=0,Stage_calls=0,collector_calls=0,canonical_writes=0)))
print(json.dumps(dict(input=inp,review=review,patch=patch,nodes=len(nodes),groups=len(groups),pins=len(spec['pinned_inputs']),oldptr=oldptr)))
