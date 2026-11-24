"""Read fixed declarations and emit NEW build files as JSON; no writes or Stage import."""
import ast,copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
O=S+'performance92_Docks_ordinary21_source_recipe/'
def p(x):return G/x.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(x,s):
    b=p(x).read_bytes();assert sha(b)==s,('PIN',x);return b
def read(x,s):return json.loads(fixed(x,s))
def js(x):return (json.dumps(x,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def ptr(x,ks):
    for k in ks:x=x[k]
    return x
tp=S+'stage_performance71_A1_ENV18_READY.py';oldtool=fixed(tp,'c30d8f17b6f2d058ab59a02c513ee9f150cfb88dc8b449768b48beb0db340e93') if False else p(tp).read_bytes()
ip=S+'performance71_A1_ENV18_source_recipe/source_input_ROOT_LOCKED.json';oldinput=p(ip).read_bytes();old=json.loads(oldinput)
assert old['required_generator']['path']==tp and old['required_generator']['sha256']==sha(oldtool)
templates=json.loads(p(S+'performance58_market_parent30_source_recipe/source_input_ROOT_LOCKED.json').read_bytes())
stagep=S+'outputs/root_A1_ENV18_stage01/receipt.json';stages='e4beb20d93cd00b91933f7879fc63edf5a173b3a3a772b5293fb56896f055468';stage=read(stagep,stages)
ownerp=S+'performance72_A1_ENV18_actual_independent_review/owner_source_maps_READY.json';owners='3715a958d0f9ee71d1ffdbe823ddcbd066d7613e2f5748d0e96e4bd25ed7e666';owner=read(ownerp,owners)
scopep=S+'performance90_Docks_ordinary_repair_scope_NOTREADY.json';scopes='838a2b435653a29efd4b4e9cba826835db3d47d562aec3ddd56e741da411bccb';scope=read(scopep,scopes)
rootp=R+'integration57/AC_execution_preparation_authorization.json';roots='ec1e49d5cca161ccbd23e459c863f7c1df5e55b2f4c53cb682645f3364661a17';root=read(rootp,roots)
backp=R+'integration57/full21_backup_receipt.json';backs='8242633f6f02452630c4ccf06311e176cb91c7ad30919018e9a37a77654b7d17';back=read(backp,backs)
beforep=R+'integration57/guard_before.json';befores='bbce7ebb9baa5b1b2d8eb56a7a35f430e3005d93b298c48651b227b1e2f71ed7'
codep=S+'performance89_Docks_ordinary_C_successor_BUILD/whole_code_inverse_BUILD_NOT_RUNTIME_READY.json';codes='d463e772039113c30852db2445b5756ed5dc85282c35957ac7d7a20eecfd6c5c';code=read(codep,codes)
ep=S+'performance91_Docks_AC_execution_BUILD/execution_successor_PROPOSAL_NOT_APPROVED.json';es='d184d50821f11bf012bd34baac374c4939fdfa5c51f6c415d31e249bbc8a6f29';authority=read(ep,es)
parentp=S+'performance57_market_receipt_dependencies/execution_successor_PROPOSAL.json';parents='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3'
AA=code['records']['AA']['target'];AC=code['records']['AC']['target'];EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
allow={r['path']:r['old_sha256']for r in scope['proposed_targets']};assert len(allow)==21 and {r['path']:r['sha256']for r in back['targets']}==allow
pins={r['id']:copy.deepcopy(r)for r in old['pinned_inputs']}
def pin(i,x,s):pins[i]={'id':i,'path':x,'sha256':s}
for i,x,s in [('ordinary_scope',scopep,scopes),('ordinary_root',rootp,roots),('ordinary_backups',backp,backs),('ordinary_before',beforep,befores),('ordinary_code_inverse',codep,codes),('ordinary_parent_execution',parentp,parents),('execution_approval',ep,es),('ordinary_prior_stage',stagep,stages),('ordinary_prior_owner',ownerp,owners)]:pin(i,x,s)
for name,r in code['records'].items():pin('ordinary_'+name+'_candidate',r['candidate']['path'],r['candidate']['sha256'])
ordinary={r['path']:r['sha256']for r in scope['runtime_ordinary_proof_leaves_Docks_only']}
for i,(x,s)in enumerate(ordinary.items()):pin('ordinary_proof_'+str(i),x,s)
cur={}
for ident,row in stage['nodes'].items():
    if ident.startswith('expected_ch4_'):continue
    b=fixed(row['path'],row['sha256']);cur[ident]={**row,'bytes':b,'parsed':json.loads(b)if row.get('value')is not None else None}
refs={n['target']:{'$sha':n['id']}for n in old['nodes']if n.get('target')in allow};refs[AA]={'$pin':'ordinary_AA_candidate'};refs[AC]={'$owned':AC};refs[EXE]={'$pin':'execution_approval'}
nodes=[{'id':'execution_final','kind':'ordinary_execution','base_input':'execution_approval'}];frozen={}
for original in old['nodes']:
    if original['kind']=='map':continue
    n=copy.deepcopy(original);ident=n['id'];v=cur[ident];base='ordinary_parent_'+ident;pin(base,v['path'],v['sha256'])
    if ident=='ap_execution_index':n=copy.deepcopy(next(x for x in templates['nodes']if x['id']==ident));refs[n['target']]={'$sha':ident}
    if n.get('target')not in allow:
        frozen[ident]=v['sha256'];nodes.append({'id':ident,'kind':'ordinary_frozen','base_input':base,'immutable_sha256':v['sha256'],'is_json':v['parsed']is not None});continue
    n['base_input']=base;n['old_sha256']=v['sha256'];assert allow[n['target']]==v['sha256']
    if n['kind']=='index':
        for h in n['replacements']:
            x=h['new']
            if isinstance(x,dict)and'$sha'in x:h['old']=cur[x['$sha']]['sha256']
            elif isinstance(x,dict)and x.get('$pin')=='execution_approval':h['old']=parents
            assert v['bytes'].count(h['old'].encode())==1
        nodes.append(n);continue
    assert n['kind']=='metadata';n['operations']=[]
    fields=n['source_bundle']['fields']if'source_bundle'in n else[f['pointer']for f in n.get('source_fields',[])]
    for ks in fields:
        values=ptr(v['parsed'],ks)
        for path,new in refs.items():
            if path in values and path!=AC:n['operations'].append({'op':'set','pointer':ks+[path],'existed':True,'old':values[path],'new':new})
    if ident in ['legacy_manifest_4','legacy_manifest_6','legacy_manifest_7']:n['source_bundle']['groups'].append('Docks_exact_ordinary_C_AA_proofs')
    nodes.append(n)
groups=copy.deepcopy(old['source_groups']);groups.append({'id':'Docks_exact_ordinary_C_AA_proofs','kind':'explicit','leaves':{x:{'$pin':'ordinary_proof_'+str(i)}for i,x in enumerate(ordinary)}})
for original in old['nodes']:
    if original['kind']!='map':continue
    n=copy.deepcopy(original);baseline=json.loads(p(pins[n['base_input']]['path']).read_bytes())['source_sha256']
    if n['scene_id']=='ch4_s2_canal_docks':
        assert baseline.get(AA)==allow[AA]
        matches=[op for op in n['operations']if op['pointer']==['source_sha256',AA]]
        assert not matches
        n['operations'].append({'op':'set','pointer':['source_sha256',AA],'existed':True,'old':baseline[AA],'new':{'$pin':'ordinary_AA_candidate'}});n['groups'].append('Docks_exact_ordinary_C_AA_proofs')
    nodes.append(n)
spec=copy.deepcopy(old);spec.update(status='BUILD_ONLY_SOURCE_INPUT_NOT_READY_FOR_STAGE',blockers=['Root explicit one-Stage authorization and NEW readiness freeze required'],nodes=nodes,source_groups=groups,root_target_allowlist=list(allow),prospective_targets=[{'target':AA,'candidate_path':code['records']['AA']['candidate']['path'],'sha256':code['records']['AA']['candidate']['sha256']}],output_root=S+'outputs/root_Docks_ordinary21_stage01/')
spec['pass_through_targets']=[{'target':r['target'],'old_sha256':r['parent_sha256'],'candidate_path':r['candidate']['path'],'candidate_sha256':r['candidate']['sha256']}for r in code['records'].values()]+[{'target':EXE,'old_sha256':parents,'candidate_path':ep,'candidate_sha256':es}]
spec['B_only_contract']={'scope_input':'ordinary_scope','admission_input':'ordinary_root','backup_input':'ordinary_backups','before_input':'ordinary_before','inverse_input':'ordinary_code_inverse','parent_execution_input':'ordinary_parent_execution','prior_owner_input':'ordinary_prior_owner','parent_stage_input':'ordinary_prior_stage','expected_Root_document':root,'frozen_nodes':frozen,'ordinary_Docks_only_pins':ordinary}
for gate in spec['required_gates']:
    if gate['id']=='root_target_preauthorization':gate.update(input='ordinary_backups',pointer=['counts','targets'],equals=21)
spec['source_baseline']='FixedE4BE/owner3715. ExactAA+AC ordinary predecessors and one AC execution edge95to96. No C/AA OWNED expansion. Docks only two ordinary proof leaves; old49 groups and all native/media semantics retained. Estate/registry/Temple binding/five room receipts frozen. BUILD false awaiting Root explicit one-Stage authorization.'
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,x in v.items():
            if k in ['input','base_input','predecessor_input','proof_input']and isinstance(x,str)and x in pins:used.add(x)
            if k=='$pin':used.add(x)
            collect(x)
    elif isinstance(v,list):
        for x in v:collect(x)
collect(nodes);collect(groups);collect(spec['required_gates']);used.update(x for k,x in spec['B_only_contract'].items()if k.endswith('_input'));used.update(['ordinary_AA_candidate','ordinary_AC_candidate']);spec['pinned_inputs']=[r for r in pins.values()if r['id']in used]
assert {n['target']for n in nodes if'target'in n}|{r['target']for r in spec['pass_through_targets']}==set(allow)
# Driver body is kept separately so this read-only emitter never imports a Stage.
driver=p(S+'stage_performance92_Docks_ordinary21_BUILD.py').read_bytes();ast.parse(driver);spec['required_generator']={'path':S+'stage_performance92_Docks_ordinary21_BUILD.py','sha256':sha(driver)}
diff=''.join(difflib.unified_diff(oldtool.decode().splitlines(True),driver.decode().splitlines(True),fromfile=tp,tofile=spec['required_generator']['path'])).encode()
def delta(a,b,ks=[]):
    if type(a)is type(b)and isinstance(a,dict)and a.keys()==b.keys():return [d for k in a for d in delta(a[k],b[k],ks+[k])]
    if type(a)is type(b)and isinstance(a,list)and len(a)==len(b):return [d for i in range(len(a))for d in delta(a[i],b[i],ks+[i])]
    return []if type(a)is type(b)and a==b else [{'pointer':ks,'old':a,'new':b}]
deltas=delta(old,spec);inv=copy.deepcopy(spec)
for d in reversed(deltas):ptr(inv,d['pointer'][:-1])[d['pointer'][-1]]=d['old']
assert js(inv)==oldinput
proofout={'status':'BUILD_ONLY_FALSE21_DRIVER_INPUT_FULL_DIFF_AND_INVERSE_NOT_STAGED','parent_driver':{'path':tp,'sha256':sha(oldtool)},'parent_input':{'path':ip,'sha256':sha(oldinput)},'driver_complete_diff':O+'driver_complete_vs71.diff','input_deltas':deltas,'whole_input_typed_serialized_UTF8_inverse':True,'frozen8DE0_unchanged':True,'target_count':21,'partition':{'GD':9,'JSON':12},'no_Stage_import_or_run':True,'false_readiness_blocks_execution':True,'fixed_Root57_schema':'counts.targets/GD/JSON; each res://path/backup/sha256/bytes','ordinary_group_added_only_Docks':True,'execution95to96_only_one_existing_AC_edge':True}
files={O+'source_input_NOTREADY.json':js(spec),O+'driver_complete_vs71.diff':diff,O+'driver_input_inverse_BUILD.json':js(proofout)}
assert all(not p(path).exists()for path in files)
print(json.dumps({'files':{str(p(path)):b.decode()for path,b in files.items()},'pins':{path:sha(b)for path,b in files.items()}},ensure_ascii=False))
