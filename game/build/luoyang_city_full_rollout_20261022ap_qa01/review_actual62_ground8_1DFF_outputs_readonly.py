"""Actual exact8 staged-artifact inverses; no Stage or engine invocation."""
from pathlib import Path
import copy
import hashlib
import json

Q=Path(__file__).resolve().parent;G=Q.parents[1];S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(p):return G/p[6:]
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return set(a)==set(b) and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def at(v,ks):
    for k in ks:v=v[k]
    return v
def restore(value,changes):
    v=copy.deepcopy(value)
    for d in reversed(changes):
        holder,key=at(v,d['pointer'][:-1]),d['pointer'][-1]
        if d['existed']:holder[key]=d['old']
        else:del holder[key]
    return v
rp=S/'outputs/root_market_ground_exact8_stage01/receipt.json'
assert sha(rp)=='1dff38bf897130d74bb6c0d51b4436fa25d97de9bb8e4502ea8490364262ccfe'
r=rd(rp)
ip=S/'performance62_ground8_source_recipe/source_input_ROOT_LOCKED.json'
assert sha(ip)=='48d8f26e1b16cfde0636feab432a21ec20e137279ac9b1e9c5bae02b2e4ff277'
s=rd(ip);pins={x['id']:x for x in s['pinned_inputs']};ns={x['id']:x for x in s['nodes']}
assert r['source_first']==r['source_final'] and len(r['source_first'])==3019
assert r['target_partition']=={'patch_count':4,'copy_count':4,'total':8,'intersection_empty':True,'union_exact_targets':True}
targets={x['target']:x for x in r['targets']};assert len(targets)==8 and set(targets)==set(s['root_target_allowlist'])
raws={};olds={}
for path,row in targets.items():
    raws[path]=res(row['candidate_path']).read_bytes();olds[path]=res(path).read_bytes()
    assert hashlib.sha256(raws[path]).hexdigest()==row['candidate_sha256']
    assert hashlib.sha256(olds[path]).hexdigest()==row['old_sha256']!=row['candidate_sha256']
prior=rd(res(pins[s['B_only_contract']['parent_stage_input']]['path']))
metadata=[];indices=[];frozen=[]
for ident,node in r['nodes'].items():
    row=ns[ident]
    if row['kind']=='ground8_frozen':
        assert node['sha256']==row['immutable_sha256']==prior['nodes'][ident]['sha256']
        assert same(node.get('value'),prior['nodes'][ident].get('value'))
        assert 'target' not in row;frozen.append(ident);continue
    raw=res(node['path']).read_bytes();assert hashlib.sha256(raw).hexdigest()==node['sha256']
    if row['kind']=='metadata':
        original=rd(res(pins[row['base_input']]['path']))
        assert same(json.loads(raw),node['value']) and r['proofs'][ident]['whole_typed_inverse']
        assert same(restore(node['value'],r['proofs'][ident]['source_delta']),original)
        for pointer in row.get('protected_pointers',[]):assert same(at(node['value'],pointer),at(original,pointer))
        for key in ['artifacts','layout_proof','mask_sha256','geometry_proof_basis','native_artifacts','parent_publication','source_migration']:
            if key in original:assert same(node['value'][key],original[key])
        if ident=='finite08_market':assert not any(p.startswith('res://data/maps/luoyang_layout_bundle_20261018t_retry2/') for p in node['value']['legacy_source_sha256'])
        metadata.append(ident)
    elif row['kind']=='index':
        original=res(pins[row['base_input']]['path']).read_bytes();text=original.decode();changes=[]
        for h in row['replacements']:
            v=h['new']
            if isinstance(v,dict):v=r['nodes'][v['$sha']]['sha256'] if '$sha' in v else pins[v['$pin']]['sha256']
            assert text.count(h['old'])==1;text=text.replace(h['old'],v,1);changes.append((h['old'],v))
        assert hashlib.sha256(text.encode()).hexdigest()==r['proofs'][ident]['disabled_sha256']
        assert text.count(row['disabled_literal'])==1 and text.replace(row['disabled_literal'],row['enabled_literal'],1).encode()==raw
        for a,b in reversed(changes):assert text.count(b)==1;text=text.replace(b,a,1)
        assert text.encode()==original;indices.append(ident)
assert len(metadata)==4 and len(indices)==3 and len(frozen)==16
patch=res(r['patch_path']);assert sha(patch)==r['patch_sha256']
lines=patch.read_bytes().decode().splitlines(keepends=True);assert lines[0]=='*** Begin Patch\n' and lines[-1]=='*** End Patch\n'
i=1;patchtargets=[]
while i<len(lines)-1:
    assert lines[i].startswith('*** Update File: ')
    absolute=Path(lines[i].split(': ',1)[1].strip());path='res://'+absolute.relative_to(G).as_posix();patchtargets.append(path)
    original=olds[path].decode().splitlines(keepends=True);after=[];cursor=0;i+=1
    while i<len(lines)-1 and not lines[i].startswith('*** Update File: '):
        assert lines[i].startswith('@@');i+=1;a=[];b=[]
        while i<len(lines)-1 and not lines[i].startswith(('@@','*** Update File: ')):
            line=lines[i];assert line[0] in ' +-'
            if line[0] in ' -':a.append(line[1:])
            if line[0] in ' +':b.append(line[1:])
            i+=1
        found=[j for j in range(cursor,len(original)-len(a)+1) if original[j:j+len(a)]==a]
        assert len(found)==1;pos=found[0];after+=original[cursor:pos]+b;cursor=pos+len(a)
    after+=original[cursor:]
    assert ''.join(after).encode()==raws[path]
    proof=r['patch_reconstruction'][path]
    assert proof['forward_exact_bytes'] and proof['whole_inverse_exact_bytes']
assert len(patchtargets)==4 and all(p.endswith('.gd') for p in patchtargets)
copyfile=res(r['byte_copy_plan']['path']);assert sha(copyfile)==r['byte_copy_plan']['sha256']
copies=rd(copyfile);copytargets={x['target'] for x in copies['rows']}
assert len(copytargets)==4 and not copytargets&set(patchtargets) and copytargets|set(patchtargets)==set(targets)
for row in copies['rows']:assert row['mechanism']=='EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION' and row['candidate_bytes']==len(raws[row['target']])
owner=rd(res(pins[s['B_only_contract']['prior_owner_input']]['path']));scenes={x['id']:x for x in owner['scenes']};counts={}
for row in s['nodes']:
    if row['kind']!='map':continue
    expected=copy.deepcopy(scenes[row['scene_id']]['source_sha256'])
    for p in expected:
        if p in targets:assert expected[p]==targets[p]['old_sha256'];expected[p]=targets[p]['candidate_sha256']
    value=r['nodes'][row['id']]['value']['source_sha256']
    assert same(value,expected) and set(value)==set(scenes[row['scene_id']]['source_sha256']);counts[row['scene_id']]=len(value)
assert counts=={'ch4_s0_luoyang_gate':898,'ch4_s1_luoyang_yamen':1249,'ch4_s2_canal_docks':1726,'ch4_s3_luoyang_market':1712}
ex=res(pins[s['authority_input']]['path'])
assert sha(ex)=='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3'
assert sha(G/'data/maps/luoyang_full_city_20261022ap/execution_successor.json')==sha(ex)
assert len(rd(ex)['owned'])==10 and len(rd(ex)['source_sha256'])==95
out=Q/'actual62_1DFF_ground_exact8_artifact_inverse_merge_admission_READY.json'
assert not out.exists()
out.write_text(json.dumps({'status':'ACTUAL62_EXACT8_OUTPUT_INDEPENDENT_NO_MERGE_BLOCKER_OWNER_PENDING_NOT_RUNTIME',
    'actual_stage_SHA':sha(rp),'checks':{'actual8candidate_and_current8old_SHA_exact':True,'metadata4_whole_strict_typed_inverse':metadata,
        'indices3_complete_byte_forward_inverse':indices,'GD4_actualpatch_reconstructed_strictfinal_noEOF':True,
        'JSON4_exactcopy_disjoint_union8':True,'source3019_FIRSTFINAL_same_not_recrawled':True,
        'frozen16_declarations_values_exact_prior464BA':frozen,'four_full_E717_maps_only8existingvalue_migration_no_keychange':counts,
        'native_masks_parent_publication_Fadehistory_protectedfields_unchanged':True,
        'execution647949_owned10_proof95_current_and_fixed_unchanged':True},
    'limits':['Actual staged source outputs only, Root deployment and full8scene5room owner review pending',
        'No engine/collector/geometry/native packet or image decode/mediahash/wholecity or ART pass'],
    'operations':{'Stage':0,'engine':0,'collector':0,'decode':0,'mediahash':0,'canonical':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'merge_blocker':False}))
