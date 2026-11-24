"""Review actual staged bytes and inverses, never rerun compiler/collector."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
OUT=Path(__file__).with_name('artisan_a2_stage4688_independent_output_inverse_review_READY.json')
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://');q=(ROOT/p[6:]).resolve();assert q.is_relative_to(ROOT);return q
def read(p):return json.loads(p.read_bytes())
def at(v,ks):
    for k in ks:v=v[k]
    return v
def same(a,b):
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
rp=SF/'outputs/root_artisan_A2_source_stage01/receipt.json'
assert sha(rp.read_bytes())=='4688cdbb0fa137425cc5964d37d918da9358889e68dc6496f2b4fb6ee1405d8c'
r=read(rp);spec=read(SF/'a2_source_recipe08/source_input_ROOT_LOCKED.json')
pins={x['id']:x for x in spec['pinned_inputs']}; nodespec={x['id']:x for x in spec['nodes']}
assert r['source_first']==r['source_final'] and len(r['source_first'])==3016
targets={x['target']:x for x in r['targets']};assert len(targets)==28 and set(targets)==set(spec['root_target_allowlist'])
for p,row in targets.items():
    raw=res(row['candidate_path']).read_bytes();assert sha(raw)==row['candidate_sha256']
    assert sha(res(p).read_bytes())==row['old_sha256']
    assert raw!=res(p).read_bytes()
metadata=0;indexes=0
for ident,node in r['nodes'].items():
    row=nodespec[ident];kind=row['kind']
    assert sha(res(node['path']).read_bytes())==node['sha256']
    if kind in ('metadata','a2_contract','a2_quarter'):
        value=read(res(node['path']));original=read(res(pins[row['base_input']]['path']))
        assert same(value,node['value'])
        proof=r['proofs'][ident]
        deltas=proof['source_delta']+proof.get('exact_A2_declaration_delta',[])
        back=copy.deepcopy(value)
        for d in reversed(deltas):
            holder=at(back,d['pointer'][:-1]);key=d['pointer'][-1]
            if d['existed']:holder[key]=d['old']
            else:del holder[key]
        assert same(back,original),(ident,'whole inverse')
        for key in ['artifacts','layout_proof','mask_sha256','geometry_proof_basis','native_artifacts','parent_publication']:
            if key in original:assert same(value[key],original[key]),(ident,key)
        if ident=='quarter_final':
            assert same(original['scenes']['luoyang_riverside_garden_20261022ap'],value['scenes']['luoyang_riverside_garden_20261022ap'])
            for key in ['connections','seed_provenance']:assert same(original[key],value[key])
        metadata+=1
    elif kind=='index':
        original=res(pins[row['base_input']]['path']).read_bytes();text=original.decode()
        for h in row['replacements']:
            new=h['new']
            if isinstance(new,dict):
                ref=r['nodes'][new['$sha']];new=ref['disabled_sha256'] if new.get('variant')=='disabled' else ref['sha256']
            assert text.count(h['old'])==1;text=text.replace(h['old'],new,1)
        disabled=res(node['disabled_path']).read_bytes();assert text.encode()==disabled
        assert disabled.replace(row['disabled_literal'].encode(),row['enabled_literal'].encode(),1)==res(node['path']).read_bytes()
        indexes+=1
    elif kind=='a2_frozen_node':assert res(node['path']).read_bytes()==res(pins[row['base_input']]['path']).read_bytes() and 'target' not in row

patch=res(r['patch_path']).read_bytes();assert sha(patch)==r['patch_sha256']
lines=patch.decode().splitlines(keepends=True);assert lines[0]=='*** Begin Patch\n' and lines[-1]=='*** End Patch\n'
i=1;patchtargets=[]
while i<len(lines)-1:
    assert lines[i].startswith('*** Update File: ');absolute=Path(lines[i].split(': ',1)[1].strip());p='res://'+absolute.relative_to(ROOT).as_posix()
    patchtargets.append(p);old=res(p).read_bytes();original=old.decode().splitlines(keepends=True);after=[];cursor=0;i+=1
    while i<len(lines)-1 and not lines[i].startswith('*** Update File: '):
        assert lines[i].startswith('@@');i+=1;before=[];new=[]
        while i<len(lines)-1 and not lines[i].startswith(('@@','*** Update File: ')):
            line=lines[i];assert line[0] in ' +-'
            if line[0] in ' -':before.append(line[1:])
            if line[0] in ' +':new.append(line[1:])
            i+=1
        matches=[j for j in range(cursor,len(original)-len(before)+1) if original[j:j+len(before)]==before]
        assert len(matches)==1,(p,'ambiguous hunk',len(matches));j=matches[0]
        after+=original[cursor:j]+new;cursor=j+len(before)
    after+=original[cursor:];assert ''.join(after).encode()==res(targets[p]['candidate_path']).read_bytes(),p
assert len(patchtargets)==14 and all(p.endswith('.gd') for p in patchtargets)
copyplan=read(res(r['byte_copy_plan']['path']));assert sha(res(r['byte_copy_plan']['path']).read_bytes())==r['byte_copy_plan']['sha256']
copytargets={x['target'] for x in copyplan['rows']};assert len(copytargets)==14 and not set(patchtargets)&copytargets and set(patchtargets)|copytargets==set(targets)
for row in copyplan['rows']:
    assert row['mechanism']=='EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION'
    assert row['candidate_bytes']==res(row['candidate_path']).stat().st_size and row['target'].endswith('.json')
oldowner=read(SF/'finite10_yamen_classification/actual_deployment_review/owner_source_maps_ROOT_DEPLOYED_READY.json')
mapchanges={}
for ident,node in r['nodes'].items():
    if nodespec[ident]['kind']!='map':continue
    value=node['value'];scene=value['scene_id'];new=value['source_sha256']
    base=oldowner['scenes'][scene]['source_sha256']
    removed=sorted(set(base)-set(new));added=sorted(set(new)-set(base));changed=sorted(p for p in base.keys()&new.keys() if base[p]!=new[p])
    assert not removed
    assert all(p in targets and new[p]==targets[p]['candidate_sha256'] for p in changed),(scene,'non-target hash changed')
    assert len(new)=={'ch4_s0_luoyang_gate':866,'ch4_s1_luoyang_yamen':1217,'ch4_s2_canal_docks':1694,'ch4_s3_luoyang_market':1678}[scene]
    mapchanges[scene]={'old_count':len(base),'new_count':len(new),'added':added,'changed_existing_target_paths':changed,'removed':removed}
result={'status':'INDEPENDENT_ACTUAL_A2_STAGE_BYTES_AND_INVERSE_NOT_DEPLOYED_OR_RUNTIME','actual_stage':{'path':'res://'+rp.relative_to(ROOT).as_posix(),'sha256':sha(rp.read_bytes())},'actual_first_final_source_same':3016,'current_source_recrawl':False,'candidate_SHA_bytes_exact':28,'metadata_whole_typed_inverse_count':metadata,'index_literal_whole_byte_reconstruction_count':indexes,'GD_patch_independent_forward_exact_bytes':14,'JSON_copy_plan_exact':14,'map_delta_from_fixed_690F_only_not_collector':mapchanges,'Garden_native_connections_seed_unchanged':True,'native_artifact_mask_basis_r3_parent_values_unchanged':True,'limitations':['No stager replay, engine, collector, PNG/ctex/native decode, geometry, source3016 crawl or canonical writes.','Root only deployment and final independent owner maps still needed before actual Field.'],'blocking_static_findings':[]}
assert not OUT.exists();OUT.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(OUT),'sha256':sha(OUT.read_bytes()),'metadata':metadata,'indexes':indexes}))
