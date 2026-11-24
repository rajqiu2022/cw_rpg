"""Only fixed EE47 map deltas + approved three ordinary material leaves."""
from pathlib import Path
import json,hashlib,copy,difflib,ast
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261025f_source01/';S24='res://build/luoyang_city_revision_20261024e_source01/';R='res://build/luoyang_city_revision_20261025f_root01/'
E='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),p;assert b'tokens truncated' not in b;return b
def load(p,h):return json.loads(read(p,h))
def at(v,ptr):
    for k in ptr:v=v[k]
    return v
def op(ptr,old,new):return dict(op='set',pointer=ptr,existed=True,old=copy.deepcopy(old),new=copy.deepcopy(new))
oldpath=S24+'source_input_docks31_residual03_ROOT_REVIEW.json';oldhash='12a8fddcd1e6e0e8fd253c6263dd3f202f152104533525bd9ccd3b2729e04cda';oldraw=read(oldpath,oldhash);old=json.loads(oldraw)
stagepin=dict(path=S24+'outputs/root_docks_frontages_exact31_stage03/receipt.json',sha256='8ea2ed3e987510ace0ef772e4f683468b714e77c6648f7c086e234520f9bd826');stage=load(stagepin['path'],stagepin['sha256'])
scopepin=dict(path=S+'street_materials18_scope_PREPARATION.json',sha256='c6920eb563c899186b3091cf2acb69cc70d592ec394e7603c49585671ef4428b');scope=load(scopepin['path'],scopepin['sha256']);targets={r['target']:r for r in scope['targets']}
proofpin=dict(path=S+'ENV_materials18_whole_inverse_NOT_STAGE.json',sha256='16e841bb2af32c5747281125c18e8bfe295dbc35c864d5fdbf95f08f2940fb42');proof=load(proofpin['path'],proofpin['sha256'])
approvalpin=dict(path=R+'material_overview_limited_admission.json',sha256='cc0df2ceefe9606481a00c63dccfbad16e525de877ce459c9524af6868fcd62c');approval=load(approvalpin['path'],approvalpin['sha256'])
pins={r['id']:copy.deepcopy(r) for r in old['pinned_inputs']}
def pin(i,p,h):pins[i]=dict(id=i,path=p,sha256=h.lower());return {'$pin':i}
pin('space_scope',scopepin['path'],scopepin['sha256']);pin('space_code_inverse',proofpin['path'],proofpin['sha256'])
pin('space_Root_backup',R+'predeploy18_backup_receipt.json','8d205d0cd8b4cb73e2bee5d444ccb39755458b22e2f12db78e728b2d95414444');pin('space_Root_preparation',approvalpin['path'],approvalpin['sha256'])
pin('space_parent_execution',proof['execution_frozen']['path'],proof['execution_frozen']['sha256']);pin('execution_approval',proof['execution_frozen']['path'],proof['execution_frozen']['sha256'])
pin('materials25f_System_proof',proof['System_full_inverse']['path'],proof['System_full_inverse']['sha256'])
record=proof['records'][E];oldENV=next(r for r in scope['targets'] if r['target']==E)
found=[]
for ident,p in pins.items():
    if p['path']==oldENV['immutable_old'] and p['sha256']==oldENV['old_sha256']:
        p.update(path=record['candidate']['path'],sha256=record['candidate']['sha256']);found.append(ident)
assert 'blocks_code_5' in found;refs={E:{'$pin':'blocks_code_5'}}
for n in old['nodes']:
    if n.get('target') in targets:refs[n['target']]={'$sha':n['id']}
groups={g['id']:copy.deepcopy(g) for g in old['source_groups']};newgroup='street25f_Market_material3';groups[newgroup]=dict(id=newgroup,kind='explicit',leaves=proof['new_Market_only_ordinary3'])
add_to={'legacy_manifest_5','legacy_manifest_8','market_final','finite08_market','expected_ch4_s3_luoyang_market_true'}
nodes=[];parentmaps={};checks=0;frozen=[]
for original in old['nodes']:
    n=copy.deepcopy(original);ident,kind=n['id'],n['kind'];prior=stage['nodes'][ident]
    if ident=='execution_final':nodes.append(dict(id=ident,kind='space_execution',base_input='execution_approval'));continue
    if ident=='ENV_code':
        n.update(base_input='blocks_code_5',immutable_sha256=record['candidate']['sha256']);nodes.append(n);continue
    if kind=='docks_incremental_map':
        parent_id='materials25f_parent_'+ident;pin(parent_id,prior['path'],prior['sha256']);parentmaps[ident]=parent_id
        wanted=load(prior['path'],prior['sha256'])['source_sha256'];assert wanted==prior['value']['source_sha256']
        n['base_input']=parent_id
        for row in n['ancestor_operations']:
            p=row['pointer'][1]
            if row['op']=='set' and p in refs:row['new']=refs[p]
        n['operations']=[op(['source_sha256',p],h,refs[p]) for p,h in wanted.items() if p in refs]
        if ident in add_to:n['groups'].append(newgroup)
        n['declared_new_groups']=[newgroup] if ident in add_to else []
        nodes.append(n);continue
    if n.get('target') not in targets:
        pi='materials25f_frozen_'+ident;pin(pi,prior['path'],prior['sha256']);n=dict(id=ident,kind='space_frozen',base_input=pi,immutable_sha256=prior['sha256'],is_json=isinstance(prior.get('value'),dict));frozen.append(dict(id=ident,path=prior['path'],sha256=prior['sha256']));nodes.append(n);continue
    target=n['target'];parent=targets[target];pi='materials25f_old_'+ident;pin(pi,parent['immutable_old'],parent['old_sha256']);n.update(base_input=pi,old_sha256=parent['old_sha256'])
    if kind=='index':
        edits=[]
        for h in n['replacements']:
            new=h['new']
            if isinstance(new,dict) and '$sha' in new:
                dest=next(x for x in old['nodes'] if x['id']==new['$sha']);assert dest.get('target') in targets;edits.append(dict(old=targets[dest['target']]['old_sha256'],new=new))
            elif h['old']=='const FORMAL_ENABLED=true' and new=='const FORMAL_ENABLED=false':edits.append(h)
            else:raise AssertionError((ident,h))
        n['replacements']=edits;nodes.append(n);continue
    assert kind=='metadata';base=load(parent['immutable_old'],parent['old_sha256']);fields=n.get('source_bundle',{}).get('fields',[])+[r['pointer'] for r in n.get('source_fields',[])]
    n['operations']=[op(ptr+[p],h,refs[p]) for ptr in fields for p,h in at(base,ptr).items() if p in refs]
    if ident in add_to:n['source_bundle']['groups'].append(newgroup)
    for row in n['operations']:assert at(base,row['pointer'])==row['old'];checks+=1
    nodes.append(n)
passed=[dict(target=E,old_sha256=record['parent']['sha256'],candidate_path=record['candidate']['path'],candidate_sha256=record['candidate']['sha256'])]
spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=list(groups.values()),root_target_allowlist=list(targets),pass_through_targets=passed,prospective_targets=[dict(target=E,candidate_path=record['candidate']['path'],sha256=record['candidate']['sha256'])],output_root=S+'outputs/root_street_materials_exact18_stage01/',source_baseline='Fixed current Stage8EA2/EE47 maps incremental; ENV0F223->C07B only functional source successor. Three new ordinary Market-only material leaves, old source keys/classes retained. OWNED10/proof162/depth16 and every execution byte frozen. No geometry, mask, native, room/NPC/dialogue/perf changes. All original five gates and four AO model equality remain.')
spec.pop('docks_contract');spec['materials_contract']=dict(scope_input='space_scope',Root_backup_input='space_Root_backup',Root_backup_prefix=R+'predeploy18_backup/',Root_preparation_input='space_Root_preparation',expected_Root_preparation_document=approval,code_inverse_input='space_code_inverse',parent_execution_input='space_parent_execution',parent_map_inputs=parentmaps,root_input_freeze_pending=False)
spec['status']='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT';spec['blockers']=[]
for gate in spec['required_gates']:
    if gate['id']=='root_target_preauthorization':gate.update(input='space_Root_backup',pointer=['count'],equals=18)
driver=S+'stage_street_materials18_ROOT_ONLY.py';driverraw=(GAME/driver[6:]).read_bytes();ast.parse(driverraw.decode());spec['required_generator']=dict(path=driver,sha256=sha(driverraw))
used={spec['authority_input'],spec['authority_helper_input'],'materials25f_System_proof'}
def collect(v):
    if isinstance(v,dict):
        for k,w in v.items():
            if (k in ['input','base_input','ancestor_base_input','literal_candidate_input','predecessor_input','proof_input'] or k.endswith('_input')) and isinstance(w,str) and w in pins:used.add(w)
            if k=='$pin':used.add(w)
            collect(w)
    elif isinstance(v,list):
        for w in v:collect(w)
collect(spec);used.update(parentmaps.values());spec['pinned_inputs']=[r for i,r in pins.items() if i in used]
assert sum('target' in n for n in nodes)+len(passed)==18 and len(passed)==1 and len(parentmaps)==4
known=set()
def check(v):
    if isinstance(v,dict):
        if '$sha' in v:assert v['$sha'] in known,('EARLY_NODE',v)
        if '$pin' in v:assert v['$pin'] in used
        for w in v.values():check(w)
    elif isinstance(v,list):
        for w in v:check(w)
def groupcheck(i,stack):
    assert i not in stack;g=groups[i];check(g)
    if g['kind']=='node_dictionary':assert g['node'] in known
    if g['kind']=='union':
        for child in g['groups']:groupcheck(child,stack+[i])
for n in nodes:
    for k in ['operations','replacements','ancestor_operations']:check(n.get(k,[]))
    for i in n.get('groups',[])+n.get('source_bundle',{}).get('groups',[])+[i for f in n.get('source_fields',[]) for i in f.get('groups',[])]:groupcheck(i,[])
    known.add(n['id'])
assert all(n.get('kind')!='space_code' or pins[n['base_input']]['sha256']==n['immutable_sha256'] for n in nodes)
assert set(next(n for n in nodes if n['id']=='finite08_market')['source_bundle']['fields'][0])=={'legacy_source_sha256'}
finite=next(n for n in nodes if n['id']=='finite08_market');assert any(r['pointer']==['legacy_source_sha256','res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json'] and r['new']=={'$sha':'market_final'} for r in finite['operations'])
raw=enc(spec);dest=HERE/'source_input_street_materials18_ROOT_REVIEW.json';assert not dest.exists();dest.write_bytes(raw)
aa,bb=oldraw.decode().splitlines(keepends=True),raw.decode().splitlines(keepends=True);patch=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':patch.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
f,v=oldraw,raw
for row in reversed(patch):
    x,y=row['old'].encode(),row['new'].encode();i,j=row['old_offset'],row['new_offset'];assert f[i:i+len(x)]==x and v[j:j+len(y)]==y;f=f[:i]+y+f[i+len(x):];v=v[:j]+x+v[j+len(y):]
assert f==raw and v==oldraw
proofout=dict(status='STREET25F_EXACT18_FINAL_INPUT_COMPLETE_BYTE_INVERSE_NOT_EXECUTED',driver=spec['required_generator'],input=dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw)),parent_input=dict(path=oldpath,sha256=oldhash),input_offset_byte_patch=patch,whole_byte_forward_inverse=True,strict_physical_JSON_parse=True,target_count=18,partition=dict(GD=7,JSON=11),pins=len(spec['pinned_inputs']),groups=len(groups),old_pointer_checks=checks,frozen_unmodified_nodes=frozen,code_proof=proofpin,backup_actual=dict(path=R+'predeploy18_backup_receipt.json',sha256='8d205d0cd8b4cb73e2bee5d444ccb39755458b22e2f12db78e728b2d95414444'),ordinary_new_keys_Market_only=proof['new_Market_only_ordinary3'],all_execution_bytes_and_162_old_proofs_unchanged=True,four_maps_fixed_8EA2_incremental=True,finite_AP_parent_header_edge_explicitly_retained=True,original_five_native_permission_gates_preserved=True,no_engine_collector_or_Stage_execution=True)
pr=enc(proofout);pp=HERE/'materials18_input_complete_inverse_NOT_EXECUTED.json';assert not pp.exists();pp.write_bytes(pr)
print(json.dumps(dict(driver=spec['required_generator'],input=proofout['input'],proof=dict(path=S+pp.name,sha256=sha(pr),bytes=len(pr)),pins=len(spec['pinned_inputs']),groups=len(groups),pointers=checks)))
