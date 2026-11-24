"""Only pinned9876 parent table deltas and approved final45 source declarations. No Stage."""
from pathlib import Path
import copy,json,hashlib,ast,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261025g_source01/'
OLD='res://build/luoyang_city_revision_20261024e_source01/'
SF='res://build/luoyang_city_revision_20261025f_source01/'
R='res://build/luoyang_city_revision_20261025g_root01/'
EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
REGISTRY='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
DT='res://scripts/city/luoyang_district_life_20261016f.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    raw=(GAME/p[6:]).read_bytes();assert sha(raw)==h.lower(),p;assert b'tokens truncated' not in raw;return raw
def load(p,h):return json.loads(read(p,h))
def at(v,ptr):
    for p in ptr:v=v[p]
    return v
def op(ptr,old,new):return dict(op='set',pointer=ptr,existed=True,old=copy.deepcopy(old),new=copy.deepcopy(new))
oldpath=SF+'source_input_street_materials18_ROOT_REVIEW.json';oldhash='a0d03ff0c7011a926d25b216c9a928ef29e619464ff35b31dcad93b74f25b797';oldraw=read(oldpath,oldhash);old=json.loads(oldraw)
base31=load(OLD+'source_input_docks31_residual03_ROOT_REVIEW.json','12a8fddcd1e6e0e8fd253c6263dd3f202f152104533525bd9ccd3b2729e04cda');templates={n['id']:n for n in base31['nodes']}
stage=load(SF+'outputs/root_street_materials_exact18_stage01/receipt.json','9876e1cc4bab5e292d9d15052b7758c7d4f1ce5e98fecfb49fda4b6f45feff67')
scopepin=dict(path=S+'courtyard45_exact32_scope_PREPARATION.json',sha256='823dcc493006e0a439dc4f4caa1ce8a1ad6b029fb9c3e8f847620731defac4d5');scope=load(**dict(p=scopepin['path'],h=scopepin['sha256']));targets={r['target']:r for r in scope['targets']}
proofpin=dict(path=S+'courtyard32_candidates01/code_execution_whole_inverse_NOT_STAGE.json',sha256='e4c12661d767a9f72db3848adaf75557d6341f74103d7a1c56f81b45047a016e');proof=load(proofpin['path'],proofpin['sha256'])
authority=load(proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256'])
approvalpin=dict(path=R+'exact32_preparation_authorization.json',sha256='da3b92cd39612672d163f9ce988d4fc353bd67f3a2e9f9dcec4ad90562d4b071');approval=load(approvalpin['path'],approvalpin['sha256'])
pins={r['id']:copy.deepcopy(r) for r in old['pinned_inputs']}
def pin(i,p,h):pins[i]=dict(id=i,path=p,sha256=h.lower());return {'$pin':i}
pin('space_scope',scopepin['path'],scopepin['sha256']);pin('space_code_inverse',proofpin['path'],proofpin['sha256'])
pin('space_Root_backup',S+'predeploy32_backup_receipt.json','207a8da07bb9991bcb0f017a482d208da46a8759d082c94b899b2a106fc63a21')
pin('space_Root_preparation',approvalpin['path'],approvalpin['sha256']);pin('space_parent_execution',proof['execution']['parent']['path'],proof['execution']['parent']['sha256'])
pin('execution_approval',proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256'])
pin('space_contract_literal',proof['contract']['candidate']['path'],proof['contract']['candidate']['sha256']);pin('space_temple_binding',proof['temple_binding']['candidate']['path'],proof['temple_binding']['candidate']['sha256'])
refs={}
for p,r in proof['records'].items():
    found=[]
    for ident,row in pins.items():
        if row['path']==r['parent']['path'] and row['sha256']==r['parent']['sha256']:
            row.update(path=r['candidate']['path'],sha256=r['candidate']['sha256']);found.append(ident)
    if not found:
        ident='courtyard_code_'+str(len(refs));pin(ident,r['candidate']['path'],r['candidate']['sha256']);found=[ident]
    refs[p]={'$pin':next((i for i in found if i.startswith('blocks_code_')),found[0])}
refs[EXEC]={'$pin':'execution_approval'};refs[CONTRACT]={'$sha':'runtime_contract_final'};refs[REGISTRY]={'$sha':'registry_final'}
for n in base31['nodes']:
    if n.get('target') in targets and n['target'] not in refs:refs[n['target']]={'$sha':n['id']}
assert set(refs)==set(targets)
groups={g['id']:copy.deepcopy(g) for g in old['source_groups']}
for ident,leaves in [('courtyard45_Market_full26',proof['Market_full26']),('courtyard45_G_shared4',proof['G_shared4']),('courtyard45_Docks_ordinary2',proof['ordinary']['Docks_only_source_additions'])]:groups[ident]=dict(id=ident,kind='explicit',leaves=leaves)
def additions(ident):
    out=[]
    if ident in ['legacy_manifest_3','legacy_manifest_4','legacy_manifest_5','legacy_manifest_6','legacy_manifest_7','legacy_manifest_8','finite08_market','finite08_yamen','market_final','quarter_final','expected_ch4_s1_luoyang_yamen_true','expected_ch4_s2_canal_docks_true','expected_ch4_s3_luoyang_market_true']:out.append('courtyard45_G_shared4')
    if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market','expected_ch4_s3_luoyang_market_true']:out.append('courtyard45_Market_full26')
    if ident in ['legacy_manifest_4','legacy_manifest_6','legacy_manifest_7','expected_ch4_s2_canal_docks_true']:out.append('courtyard45_Docks_ordinary2')
    return out
parentmaps={};nodes=[];pointer_checks=0
for original in old['nodes']:
    n=copy.deepcopy(original);ident=n['id'];template=templates[ident]
    if ident=='execution_final':nodes.append(dict(id=ident,kind='space_execution',base_input='execution_approval'));continue
    if template.get('target') in targets:n=copy.deepcopy(template)
    kind=n['kind']
    if kind in ['space_frozen','space_code']:
        n['immutable_sha256']=pins[n['base_input']]['sha256'];nodes.append(n);continue
    if kind=='docks_incremental_map':
        prior=stage['nodes'][ident];pi='courtyard45_parent_'+ident;pin(pi,prior['path'],prior['sha256']);parentmaps[ident]=pi
        wanted=load(prior['path'],prior['sha256'])['source_sha256'];assert wanted==prior['value']['source_sha256']
        n['base_input']=pi
        # Preserve current25f ancestor mathematical equality declaration, not old31 groups.
        n=copy.deepcopy(original);n['base_input']=pi
        for item in n['ancestor_operations']:
            p=item['pointer'][1]
            if item['op']=='set' and p in refs:item['new']=refs[p]
        promoted={p:authority['owned'][p]['current_sha256'] if p in authority['owned'] else h for p,h in wanted.items()}
        n['operations']=[op(['source_sha256',p],promoted[p],refs[p]) for p in wanted if p in refs]
        n['groups']+=additions(ident);n['declared_new_groups']=['authority_before_and_candidate_proofs']+additions(ident);nodes.append(n);continue
    p=n['target'];assert p in targets,(ident,p);parent=targets[p];pi='courtyard45_old_'+ident;pin(pi,parent['immutable_old'],parent['old_sha256']);n.update(base_input=pi,old_sha256=parent['old_sha256'])
    if kind=='index':
        edits=[]
        for h in n['replacements']:
            val=h['new']
            if val=={'$pin':'execution_approval'}:edits.append(dict(old=targets[EXEC]['old_sha256'],new=val))
            elif isinstance(val,dict) and '$sha' in val:
                dest=templates[val['$sha']].get('target')
                if val['$sha']=='registry_final':dest=REGISTRY
                assert dest in targets;edits.append(dict(old=targets[dest]['old_sha256'],new=val))
            elif h['old']=='const FORMAL_ENABLED=true' and val=='const FORMAL_ENABLED=false':edits.append(h)
            else:raise AssertionError((ident,h))
        n['replacements']=edits;nodes.append(n);continue
    if ident=='runtime_contract_final':
        n['kind']='space_contract';n['file']='runtime_contract_C_Field_courtyard_successor.json';n['literal_candidate_input']='space_contract_literal';n['operations']=[op(['source_sha256',p],d['old'],refs[p]) for p,d in proof['contract']['changed'].items()];nodes.append(n);continue
    base=load(parent['immutable_old'],parent['old_sha256'])
    if ident=='registry_final':
        n['operations']=[op(item['pointer'],at(base,item['pointer']),refs[DT]) for item in n['operations']]
        assert len(n['operations'])==5 and all(r['old']==targets[DT]['old_sha256'] for r in n['operations']);nodes.append(n);continue
    assert kind=='metadata',(ident,kind)
    # Current25f group history is retained even when the original31 node is reactivated.
    if original['kind']=='metadata':n=copy.deepcopy(original);n.update(base_input=pi,old_sha256=parent['old_sha256'])
    fields=n.get('source_bundle',{}).get('fields',[])+[r['pointer'] for r in n.get('source_fields',[])]
    n['operations']=[op(ptr+[p],h,refs[p]) for ptr in fields for p,h in at(base,ptr).items() if p in refs]
    if ident=='estate_final':
        assert n['protected_pointers']==[['registry_path'],['geometry_receipt'],['publication_receipt']]
        n['operations'].append(op(['registry_sha256'],base['registry_sha256'],refs[REGISTRY]))
    elif n.get('source_bundle'):n['source_bundle']['groups']+=additions(ident)
    elif additions(ident):
        assert len(n['source_fields'])==1;n['source_fields'][0]['groups']+=additions(ident)
    for item in n['operations']:assert at(base,item['pointer'])==item['old'];pointer_checks+=1
    nodes.append(n)
passed=[dict(target=p,old_sha256=r['parent']['sha256'],candidate_path=r['candidate']['path'],candidate_sha256=r['candidate']['sha256']) for p,r in proof['records'].items()]
ex=proof['execution'];passed.append(dict(target=EXEC,old_sha256=ex['parent']['sha256'],candidate_path=ex['candidate']['path'],candidate_sha256=ex['candidate']['sha256']))
spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=list(groups.values()),root_target_allowlist=list(targets),pass_through_targets=passed,prospective_targets=[dict(target=r['target'],candidate_path=r['candidate_path'],sha256=r['candidate_sha256']) for r in passed],output_root=S+'outputs/root_market_courtyard45_exact32_stage01/',source_baseline='Fixed current9876/9154 independent maps incremented only32 existing actual target values and explicit source-bound child45 groups. Original D29637->43 whole storage/FIRST+FINAL remains. Market full26 plus Gcaller shared4 and Docks ordinary2 only. Original source classification, material25f, Registry5/Estate3eq/native4/Router preserved. Owned10/162+8=170/depth16/no shortcut; no live collector expectations.')
spec.pop('materials_contract');spec['courtyard_contract']=dict(scope_input='space_scope',Root_backup_input='space_Root_backup',Root_backup_prefix=S+'predeploy32_old_backup/',Root_preparation_input='space_Root_preparation',expected_Root_preparation_document=approval,code_inverse_input='space_code_inverse',parent_execution_input='space_parent_execution',parent_map_inputs=parentmaps,root_input_freeze_pending=False)
spec['status']='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT';spec['blockers']=[]
for gate in spec['required_gates']:
    if gate['id']=='root_target_preauthorization':gate.update(input='space_Root_backup',pointer=['count'],equals=32)
driver=S+'stage_courtyard45_exact32_ROOT_ONLY.py';driverraw=read(driver,'935d797e591cc7c50bf487262655cf2f13753e159cb38ef46f414445e9692979');ast.parse(driverraw.decode());spec['required_generator']=dict(path=driver,sha256=sha(driverraw))
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,w in v.items():
            if (k in ['input','base_input','ancestor_base_input','literal_candidate_input','predecessor_input','proof_input'] or k.endswith('_input')) and isinstance(w,str) and w in pins:used.add(w)
            if k=='$pin':used.add(w)
            collect(w)
    elif isinstance(v,list):
        for w in v:collect(w)
collect(spec);used.update(parentmaps.values());spec['pinned_inputs']=[r for i,r in pins.items() if i in used]
assert sum('target' in n for n in nodes)+len(passed)==32 and len(passed)==10 and len(parentmaps)==4
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
    if n['kind'] in ['space_frozen','space_code']:assert pins[n['base_input']]['sha256']==n['immutable_sha256']
    known.add(n['id'])
finite=next(n for n in nodes if n['id']=='finite08_market');assert any(r['pointer']==['legacy_source_sha256','res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json'] and r['new']=={'$sha':'market_final'} for r in finite['operations'])
raw=enc(spec);dest=HERE/'source_input_courtyard45_exact32_ROOT_REVIEW.json'
with dest.open('xb') as out:out.write(raw)
assert json.loads(dest.read_bytes())==spec
aa,bb=oldraw.decode().splitlines(keepends=True),raw.decode().splitlines(keepends=True);patch=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':patch.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
f,v=oldraw,raw
for row in reversed(patch):
    x,y=row['old'].encode(),row['new'].encode();i,j=row['old_offset'],row['new_offset'];assert f[i:i+len(x)]==x and v[j:j+len(y)]==y;f=f[:i]+y+f[i+len(x):];v=v[:j]+x+v[j+len(y):]
assert f==raw and v==oldraw
report=dict(status='COURTYARD45_EXACT32_INPUT_COMPLETE_BYTE_INVERSE_NOT_EXECUTED',driver=spec['required_generator'],input=dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw)),parent_input=dict(path=oldpath,sha256=oldhash),input_offset_byte_patch=patch,whole_byte_forward_inverse=True,physical_JSON_strict_parse=True,scope=scopepin,code_proof=proofpin,target_count=32,partition=dict(GD=17,JSON=15),pinned_inputs=len(spec['pinned_inputs']),group_count=len(groups),old_pointer_checks=pointer_checks,incremental_parent9876=True,all_original_five_gates_four_AO_literals_and_classification_preserved=True,finite_AP_header_nested_edge_explicit=True,no_Stage_import_execution_or_engine=True)
pr=enc(report);out=HERE/'courtyard32_input_whole_inverse_NOT_EXECUTED.json'
with out.open('xb') as stream:stream.write(pr)
print(json.dumps(dict(driver=report['driver'],input=report['input'],proof=dict(path=S+out.name,sha256=sha(pr),bytes=len(pr)),pins=len(spec['pinned_inputs']),groups=len(groups),old_pointer_checks=pointer_checks)))
