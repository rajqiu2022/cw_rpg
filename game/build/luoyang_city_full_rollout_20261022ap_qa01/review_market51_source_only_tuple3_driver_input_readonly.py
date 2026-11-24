"""Static exact3 DAG review only. Never import/execute the Stage compiler."""
from pathlib import Path
import copy,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01';R=GAME/'build/luoyang_city_full_rollout_20261022ap_root01/integration40'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(p):return GAME/p.removeprefix('res://')
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def same(a,b):return type(a)is type(b)and(a.keys()==b.keys()and all(same(a[k],b[k])for k in a)if isinstance(a,dict)else len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))if isinstance(a,list)else a==b)
def at(v,keys):
    for k in keys:v=v[k]
    return v
dp=S/'stage_performance51_market_tuple3_READY.py';ip=S/'performance51_market_tuple3_source_recipe/source_input_ROOT_LOCKED.json'
proofp=ip.with_name('driver_input_whole_inverse_READY.json')
assert sha(dp)=='b446d7fe3c5aa9b0e5dce35d21053f12ea3ef22ad6af71bc6b8058f33304da7c'
assert sha(ip)=='30254627510d38509c900b00402c29c7c5d1e45691b0a704e0544addf4808b0c'
assert sha(proofp).startswith('588f617e')
s,p=rd(ip),rd(proofp);parent=res(p['parent_driver']['path']).read_bytes();new=dp.read_bytes()
assert hashlib.sha256(parent).hexdigest()==p['parent_driver']['sha256']=='868c36954db0397c320a93eb04ab4f9ff95f3cf1e1d5c432ab1fa06de1d0c0c8'
forward=parent
for h in reversed(p['driver_hunks']):
    a,b=h['old_start'],h['old_end'];assert parent[a:b]==h['old'].encode();forward=forward[:a]+h['new'].encode()+forward[b:]
assert forward==new
reverse=new
for h in reversed(p['driver_hunks']):
    a,b=h['new_start'],h['new_end'];assert new[a:b]==h['new'].encode();reverse=reverse[:a]+h['old'].encode()+reverse[b:]
assert reverse==parent and len(p['driver_hunks'])==12
back=copy.deepcopy(s)
for delta in reversed(p['input_deltas']):
    keys=delta['pointer'];holder=at(back,keys[:-1]);key=keys[-1]
    assert same(holder[key],delta['new']);holder[key]=copy.deepcopy(delta['old'])
priorinput=res(p['parent_input']['path'])
assert sha(priorinput)==p['parent_input']['sha256']=='c16d31254944fc7b8a4fc0c20cc49dfa4b1e2a1ec4e01058240c4fc02db2e03a'
assert same(back,rd(priorinput)) and enc(back)==priorinput.read_bytes() and len(p['input_deltas'])==51
pins={x['id']:x for x in s['pinned_inputs']};assert len(pins)==len(s['pinned_inputs'])==48
small_count=0;large_inherited=[]
for row in pins.values():
    path=res(row['path'])
    if path.stat().st_size>=8*1024*1024:
        assert row['id']=='tuple3_prior_stage'and row['sha256']=='96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7'
        large_inherited.append(row['id']);continue
    assert sha(path)==row['sha256'];small_count+=1
assert large_inherited==['tuple3_prior_stage']and small_count==47
c=s['B_only_contract'];root=rd(res(pins[c['admission_input']]['path']))
assert root['status']=='ROOT_EXPLICIT_NEW_SOURCE_ONLY_TWO_LEAF_ADMISSION'and root['approved_by_root']and pins[c['admission_input']]['sha256']=='b1bb3a2ce1067f0d5029f052fe59631e785ca114a591dff5de07150e52d368e4'
leaves=root['source_leaves'];assert len(leaves)==2
scope=rd(res(pins[c['scope_input']]['path']));backups=rd(R/'old_full_backups_READY.json')
assert pins[c['scope_input']]['sha256']==backups['scope_sha256']=='cba12cace9f6ffb44be694ce6a27ccc9152793e460c2e03e79c109b8fa151342'
assert sha(R/'old_full_backups_READY.json')=='c36a4468c463554402fdb1d3a8e7e363a7fb974e30ee8e50da9929bc3177611f'
assert sha(R/'guard_before.json')=='43c680af9d180b0e7c8330d28ad5671faaa24da2329129d74307bb8f9ee98987'
targets={x['target']:x['old_sha256']for x in scope['targets']};assert len(targets)==3 and list(targets)==s['root_target_allowlist']
oldstage=rd(res(pins[c['parent_stage_input']]['path']))
oldcandidates={x['target']:x['candidate_sha256']for x in oldstage['targets']}
assert all(oldcandidates[k]==v for k,v in targets.items())
for row in backups['targets']:
    target,backup=Path(row['path']),Path(row['backup_path']);k='res://'+target.relative_to(GAME).as_posix()
    assert sha(target)==sha(backup)==row['sha256']==targets[k]and target.read_bytes()==backup.read_bytes()and target.stat().st_size==row['bytes']
nodes={x['id']:x for x in s['nodes']}
assert {x['target']:x['old_sha256']for x in s['nodes']if 'target'in x}==targets
assert {x['id']for x in s['nodes']if 'target'in x}=={'market_final','finite08_market','ap_city_index'}
assert not s['prospective_targets']and not s['pass_through_targets']
assert pins[s['authority_input']]['sha256']=='bf043ab07d6ecb2c713607753e3ab2c67621923456ed44e7ab3393d9d3e9ed0d'
frozen=[x for x in s['nodes']if x['kind']=='tuple3_frozen'];assert len(frozen)==20
for row in frozen:assert 'target'not in row and row['immutable_sha256']==pins[row['base_input']]['sha256']
assert len(s['source_groups'])==49
group=next(x for x in s['source_groups']if x['id']==c['literal_group'])
assert group=={'id':c['literal_group'],'kind':'explicit','leaves':leaves}
uses=[]
for row in s['nodes']:
    groups=row.get('groups',[])+row.get('source_bundle',{}).get('groups',[])
    if c['literal_group']in groups:uses.append(row['id'])
assert set(uses)=={'market_final','finite08_market','expected_ch4_s3_luoyang_market_true'}
assert {k:v for k,v in s.items()if k=='source_groups'}['source_groups'][:-1]==rd(priorinput)['source_groups']
for ident in ['market_final','finite08_market']:
    row=nodes[ident];assert row['kind']=='metadata'
    base=rd(res(pins[row['base_input']]['path']))
    assert all(all(path not in base[field]for field in ['legacy_source_sha256','runtime_authority_sha256','artifacts'])for path in leaves)
    assert row['source_bundle']['default_destination']==['legacy_source_sha256']
    for op in row.get('operations',[]):assert op['existed']and same(at(base,op['pointer']),op['old'])
index=nodes['ap_city_index'];data=res(pins[index['base_input']]['path']).read_bytes()
assert data.endswith(b'\n')and b'\r'not in data
assert len(s['required_gates'])==5 and s['required_gates'][:4]==rd(priorinput)['required_gates'][:4]
text=dp.read_text(encoding='utf-8')
for marker in ['FOUR_INDEPENDENT_AO_MAPS_EXACT_FIXED5857_PLUS3HEADERS_MARKET2_NO_COLLECTOR_FILL','ONLY_LEGACY_TWO_AND_EXISTING_HEADER_SUCCESSION_FULL_TYPED_INVERSE','PATCH1_COPY2_EXACT_DISJOINT_UNION3','ALL_PINNED_SOURCE_FIRST_FINAL_SAME','ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED','M._strict_lf_build_file_patch']:assert marker in text
assert sha(S/'stage_unified06_04_READY.py')=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
assert not res(s['output_root']).exists()
out=QA/'market51_sourceonly_tuple3_driver_input_independent_preStage_admission_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'SOURCE51_EXACT3_SOURCE_ONLY_DECLARATION_STATIC_NO_BLOCKER_ROOT_STAGE_DECISION_ONLY','driver_sha256':sha(dp),'input_sha256':sha(ip),'proof_sha256':sha(proofp),'checks':{'12tool_hunks_wholebyte_forward_reverse_to48':True,'51input_delta_wholetyped_serialized_inverse_to48':True,'47smallpins_currentSHA_exact_1largeprior96CA_externalpin_inherited_not_rehashed':True,'Root40_real_backup_schema_full3bytes_current_exact':True,'old3_from96CA_candidate_values':True,'RootB1BB_exact2_new_SOURCE_ONLY_pixeladmission':True,'only_APMarket_finiteMarket_legacy_add2_Index_hashsuccessor':True,'literalgroup_only_those2plusMarketmap_no_otherdomain_additions':True,'original48groups_whole_same_plus1explicit2leafgroup':True,'20othernodes_frozen_no_targets':True,'original8DE0core_5gates_typed_inverse_media_rules_kept':True,'all4maps_fixed5857_plus3headers_onlyMarket2_explicitguard':True,'FIRSTFINAL_buffered_NEWonly_1strictGDpatch2JSONcopy':True},'limits':['No Stage yet; actualgeneratedvalues/owner remain pending, candidateMarketkey staysfalse.','No B/C/G/DT/registry/room/native/runtimeTexture/admission broadening.','No borrowed historicaltuple/detect0 credit; only Root39NEW SOURCE_ONLY2leaf proof.','No firstentry/ART/performance claim; Root38FAIL preserved.'],'operations':{'Stage':0,'engine':0,'collector':0,'decode':0,'large_media_hash':0,'canonical_write':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'static_no_blocker':True}))
