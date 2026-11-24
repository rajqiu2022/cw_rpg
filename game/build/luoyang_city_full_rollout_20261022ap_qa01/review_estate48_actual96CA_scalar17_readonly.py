"""Review staged outputs and immutable recipes, never Stage/collector/native decode."""
from pathlib import Path
import copy,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(p):return GAME/p.removeprefix('res://')
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def same(a,b):return type(a)is type(b)and(a.keys()==b.keys()and all(same(a[k],b[k])for k in a)if isinstance(a,dict)else len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))if isinstance(a,list)else a==b)
def at(v,keys):
    for k in keys:v=v[k]
    return v
rp=S/'outputs/root_estate_registry_scalar17_stage01/receipt.json'
assert sha(rp)=='96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7'
r=rd(rp);spec=rd(S/'performance48_estate17_source_recipe/source_input_ROOT_LOCKED.json')
assert r['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED'
assert r['source_first']==r['source_final']and len(r['source_first'])==3017
assert r['target_partition']=={'patch_count':6,'copy_count':11,'total':17,'intersection_empty':True,'union_exact_targets':True}
scope=rd(S/'performance46_estate_registry_scalar_scope/exact17_existing_scope_PROPOSAL.json')
targets={x['target']:x for x in r['targets']}
assert len(targets)==17 and list(targets)==spec['root_target_allowlist']
assert {k:v['old_sha256']for k,v in targets.items()}=={x['target']:x['old_sha256']for x in scope['targets']}
pins={x['id']:x for x in spec['pinned_inputs']};rows={x['id']:x for x in spec['nodes']}
def value(v):
    if isinstance(v,dict)and set(v)=={'$sha'}:return r['nodes'][v['$sha']]['sha256']
    if isinstance(v,dict)and set(v)=={'$pin'}:return pins[v['$pin']]['sha256']
    return v
metadata=indices=0
for k,row in rows.items():
    node=r['nodes'][k];proof=r['proofs'][k]
    if row['kind']=='estate17_frozen':
        assert proof=={'frozen_original_bytes':True,'not_target':True}
        assert node['sha256']==row['immutable_sha256']==pins[row['base_input']]['sha256']
        continue
    p=res(node['path']);assert sha(p)==node['sha256']
    if 'target'in row:
        assert targets[row['target']]['candidate_path']==node['path']and targets[row['target']]['candidate_sha256']==node['sha256']
    if row['kind']=='metadata':
        metadata+=1;original=res(pins[row['base_input']]['path']).read_bytes();old=json.loads(original);new=rd(p)
        assert same(new,node['value'])and enc(new)==p.read_bytes()
        back=copy.deepcopy(new)
        for delta in reversed(proof['source_delta']):
            holder=at(back,delta['pointer'][:-1]);key=delta['pointer'][-1]
            if delta['existed']:holder[key]=copy.deepcopy(delta['old'])
            else:del holder[key]
        assert same(back,old)and enc(back)==original and proof['whole_typed_inverse']is True
        assert proof['geometry_native_history_unchanged']is True
        for pointer in row.get('protected_pointers',[]):assert same(at(old,pointer),at(new,pointer))
        # New semantics outside source maps are forbidden except the one scalar.
        a,b=copy.deepcopy(old),copy.deepcopy(new)
        for key in ['source_sha256','legacy_source_sha256','runtime_authority_sha256']:
            if key in a:
                assert set(a[key])==set(b[key])
                a[key]=b[key]
        if k=='estate_final':
            a['registry_sha256']=b['registry_sha256']
            registry='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
            assert new['registry_path']==registry and new['registry_sha256']==new['source_sha256'][registry]=='f5298b913fbaefda2c5f3679223c014c219292a54df412a8c3f2d96e4f082f28'
            assert p.read_bytes()==res(pins['estate17_scalar_candidate']['path']).read_bytes()
        assert same(a,b)
    elif row['kind']=='index':
        indices+=1;before=res(pins[row['base_input']]['path']).read_bytes();expected=before
        for op in row['replacements']:
            old,new=op['old'].encode(),value(op['new']).encode()
            assert expected.count(old)==1;expected=expected.replace(old,new,1)
        disabled=res(node['disabled_path']).read_bytes()
        assert expected==disabled and sha(res(node['disabled_path']))==node['disabled_sha256']
        assert disabled.count(row['disabled_literal'].encode())==1
        assert disabled.replace(row['disabled_literal'].encode(),row['enabled_literal'].encode(),1)==p.read_bytes()
        assert proof['disabled_to_enabled_sole_bool_whole_inverse']is True
        assert b'\r'not in before and before.endswith(b'\n')and b'\r'not in p.read_bytes()and p.read_bytes().endswith(b'\n')
assert metadata==11 and indices==6

# Pure in-memory reconstruction of the actual6file apply_patch; no applying it.
pp=res(r['patch_path']);assert sha(pp)==r['patch_sha256']
lines=pp.read_text(encoding='utf-8').splitlines(keepends=True)
assert lines[0]=='*** Begin Patch\n'and lines[-1]=='*** End Patch\n'
sections=[];section=None;hunk=None
for line in lines[1:-1]:
    if line.startswith('*** Update File: '):
        section={'path':Path(line[len('*** Update File: '):].strip()),'hunks':[]};sections.append(section);hunk=None
    elif line.startswith('@@'):
        hunk=[];section['hunks'].append(hunk)
    else:
        assert hunk is not None and line[0]in ' +-';hunk.append(line)
assert len(sections)==6
for sec in sections:
    target='res://'+sec['path'].relative_to(GAME).as_posix();tr=targets[target]
    before=res(next(x['old_snapshot']for x in scope['targets']if x['target']==target)).read_bytes()
    assert hashlib.sha256(before).hexdigest()==tr['old_sha256']
    forward=before.decode('utf-8')
    for h in sec['hunks']:
        old=''.join(x[1:]for x in h if x[0]in ' -');new=''.join(x[1:]for x in h if x[0]in ' +')
        assert forward.count(old)==1;forward=forward.replace(old,new,1)
    assert forward.encode()==res(tr['candidate_path']).read_bytes()
bp=res(r['byte_copy_plan']['path']);assert sha(bp)==r['byte_copy_plan']['sha256']
copyplan=rd(bp);assert len(copyplan['rows'])==11
assert set(copyplan['copy_targets']).isdisjoint(copyplan['patch_targets'])
assert set(copyplan['copy_targets'])|set(copyplan['patch_targets'])==set(targets)
for row in copyplan['rows']:
    assert row['target'].endswith('.json')and row['mechanism']=='EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION'
    assert row['candidate_sha256']==sha(res(row['candidate_path']))and row['candidate_bytes']==res(row['candidate_path']).stat().st_size

owner=rd(res(pins['estate17_prior_owner']['path']))
replacements={k:v['candidate_sha256']for k,v in targets.items()}
counts={}
for ident,row in rows.items():
    if row['kind']!='map':continue
    baseline=next(x for x in owner['scenes']if x['id']==row['scene_id'])['source_sha256']
    expected={k:replacements.get(k,v)for k,v in baseline.items()}
    actual=rd(res(r['nodes'][ident]['path']))['source_sha256']
    assert same(actual,expected)and set(actual)==set(baseline)
    counts[row['scene_id']]=len(actual)
assert counts=={'ch4_s0_luoyang_gate':888,'ch4_s1_luoyang_yamen':1239,'ch4_s2_canal_docks':1716,'ch4_s3_luoyang_market':1700}
assert r['no_engine_import_collector_or_canonical_write']and r['single_root_atomic_epoch_required']and not r['runtime_inverse_replayed']
out=QA/'estate48_actual96CA_scalar17_independent_output_admission_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'ESTATE48_ACTUAL17_OUTPUTS_INDEPENDENT_REVIEW_NO_MERGE_BLOCKER_NOT_DEPLOYMENT_AUTHORITY','receipt':{'path':str(rp),'sha256':sha(rp)},'checks':{'17candidate_SHA_exact':True,'11metadata_complete_typed_serialized_inverse':True,'6indices_complete_byte_reconstruction_and_sole_activation_bool_inverse':True,'6GD_applypatch_in_memory_exact_reconstruction':True,'11JSON_copy_partition_exact':True,'four_maps_fixed544819_plus_explicit17values_same_keys':counts,'Estate_registry_path_scalar_declared_source_fixedF529_three_equal_and_exact2410':True,'3017_source_FIRST_FINAL_tables_exact_no_rehash':True,'native_geometry_artifact_parent_history_and_fourT_classification_unchanged':True,'execution_runtime_registry_G_Quarter_frozen':True},'preserved_failures':['hall33/34 absentdoor and C0000005','old557 intended domain not observed runtime acceptance'],'boundaries':['No proof the runtimehall now admits; must await independently prepared owner and Root-authorized new actual.','No current3017collector/fullmedia rehash, no save modification, no engine/Stage/publicentry.','Source49 owner not yet audited here.'],'operations':{'Stage':0,'engine':0,'collector':0,'native_or_image_decode':0,'big_media_hash':0,'canonical_write':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'metadata':metadata,'indices':indices,'counts':counts}))
