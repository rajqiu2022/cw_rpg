"""Independent staged-output and expected-owner audit; no Stage or collectors."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
QA=Path(__file__).parent
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://');q=(ROOT/p[6:]).resolve();assert q.is_relative_to(ROOT);return q
def read(p,s=None):
    b=p.read_bytes()
    if s:assert sha(b)==s,(p,'SHA')
    return json.loads(b)
def same(a,b):
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def at(v,ks):
    for k in ks:v=v[k]
    return v
rp=SF/'outputs/root_B_only_symmetric_wire_stage01/receipt.json'
r=read(rp,'7912fdd9a540b06c1d4804976a0fe582dcea9387daf2077ff20aca98c84617cf')
s=read(SF/'performance14_B_only_source_recipe/source_input_ROOT_LOCKED.json','231b66e6beaebdf7c72966e2ce1a19ee56bb3a643f254fbbe20efbcc6f713697')
pins={x['id']:x for x in s['pinned_inputs']};ns={x['id']:x for x in s['nodes']}
assert r['source_first']==r['source_final'] and len(r['source_first'])==3006
targets={x['target']:x for x in r['targets']}
assert len(targets)==22 and set(targets)==set(s['root_target_allowlist'])
rawc={};oldc={}
for p,row in targets.items():
    rawc[p]=res(row['candidate_path']).read_bytes();oldc[p]=res(p).read_bytes()
    assert sha(rawc[p])==row['candidate_sha256'] and sha(oldc[p])==row['old_sha256'] and rawc[p]!=oldc[p]
metadata=indexes=0
for ident,n in r['nodes'].items():
    row=ns[ident];kind=row['kind'];raw=res(n['path']).read_bytes();assert sha(raw)==n['sha256']
    if kind=='metadata':
        value=json.loads(raw);original=read(res(pins[row['base_input']]['path']))
        assert same(value,n['value']) and r['proofs'][ident]['whole_typed_inverse']
        back=copy.deepcopy(value)
        for d in reversed(r['proofs'][ident]['source_delta']):
            holder=at(back,d['pointer'][:-1]);key=d['pointer'][-1]
            if d['existed']:holder[key]=d['old']
            else:del holder[key]
        assert same(back,original),(ident,'full typed inverse')
        for ptr in row.get('protected_pointers',[]):assert same(at(value,ptr),at(original,ptr)),(ident,ptr)
        for key in ['artifacts','layout_proof','mask_sha256','geometry_proof_basis','native_artifacts','parent_publication']:
            if key in original:assert same(value[key],original[key]),(ident,key)
        if ident in ['finite08_market','finite08_yamen']:
            prefix='res://data/maps/luoyang_layout_bundle_20261018t_retry2/'
            assert not any(p.startswith(prefix) for p in value['legacy_source_sha256'])
        metadata+=1
    elif kind=='index':
        original=res(pins[row['base_input']]['path']).read_bytes();text=original.decode()
        for h in row['replacements']:
            new=h['new']
            if isinstance(new,dict):
                if set(new)=={'$pin'}:new=pins[new['$pin']]['sha256']
                else:
                    ref=r['nodes'][new['$sha']];new=ref['disabled_sha256'] if new.get('variant')=='disabled' else ref['sha256']
            assert text.count(h['old'])==1;text=text.replace(h['old'],new,1)
        disabled=res(n['disabled_path']).read_bytes();assert text.encode()==disabled
        assert disabled.count(row['disabled_literal'].encode())==1
        assert disabled.replace(row['disabled_literal'].encode(),row['enabled_literal'].encode(),1)==raw
        indexes+=1
    elif kind=='B_only_frozen_node':assert raw==res(pins[row['base_input']]['path']).read_bytes() and 'target'not in row
assert (metadata,indexes)==(12,8)
patch=res(r['patch_path']).read_bytes();assert sha(patch)==r['patch_sha256']
lines=patch.decode().splitlines(keepends=True);assert lines[0]=='*** Begin Patch\n' and lines[-1]=='*** End Patch\n'
i=1;patchtargets=[]
while i<len(lines)-1:
    assert lines[i].startswith('*** Update File: ')
    absolute=Path(lines[i].split(': ',1)[1].strip());p='res://'+absolute.relative_to(ROOT).as_posix();patchtargets.append(p)
    original=oldc[p].decode().splitlines(keepends=True);after=[];cursor=0;i+=1
    while i<len(lines)-1 and not lines[i].startswith('*** Update File: '):
        assert lines[i].startswith('@@');i+=1;before=[];new=[]
        while i<len(lines)-1 and not lines[i].startswith(('@@','*** Update File: ')):
            line=lines[i];assert line[0]in' +-'
            if line[0]in' -':before.append(line[1:])
            if line[0]in' +':new.append(line[1:])
            i+=1
        matches=[j for j in range(cursor,len(original)-len(before)+1) if original[j:j+len(before)]==before]
        assert len(matches)==1,(p,'unique patch hunk');j=matches[0];after+=original[cursor:j]+new;cursor=j+len(before)
    after+=original[cursor:];assert ''.join(after).encode()==rawc[p]
assert len(patchtargets)==9 and all(p.endswith('.gd')for p in patchtargets)
cp=read(res(r['byte_copy_plan']['path']),r['byte_copy_plan']['sha256']);copytargets={x['target']for x in cp['rows']}
assert len(copytargets)==13 and not copytargets&set(patchtargets) and copytargets|set(patchtargets)==set(targets)
for row in cp['rows']:
    assert row['mechanism']=='EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION' and row['target'].endswith('.json')
    assert row['candidate_bytes']==len(rawc[row['target']]) and row['candidate_sha256']==sha(rawc[row['target']])
prior=read(SF/'performance08_actual_independent_review/owner_source_maps_READY.json','9d004ac904f42807af3bc5dda757430200f7bebbdaa1ef29487911417e282551')
authority=read(res(pins[s['authority_input']]['path']))
parent=read(res(pins[s['B_only_contract']['parent_approval_input']]['path']))
addedproof={p:v for p,v in authority['source_sha256'].items() if p not in parent['source_sha256']};assert len(addedproof)==2
def migrate(table,proofs=True):
    v=copy.deepcopy(table)
    for p in v:
        if p in targets:v[p]=targets[p]['candidate_sha256']
    if proofs:
        for p,h in addedproof.items():assert p not in v;v[p]=h
    return v
changes={}
for ident,n in r['nodes'].items():
    if ns[ident]['kind']!='map':continue
    scene=n['value']['scene_id'];base=next(x for x in prior['scenes']if x['id']==scene)['source_sha256'];value=n['value']['source_sha256']
    assert same(migrate(base),value),(scene,'independent whole map delta')
    assert len(value)=={'ch4_s0_luoyang_gate':872,'ch4_s1_luoyang_yamen':1223,'ch4_s2_canal_docks':1700,'ch4_s3_luoyang_market':1684}[scene]
    changes[scene]={'old_count':len(base),'new_count':len(value),'added_proof_keys':sorted(addedproof),'changed_targets':sorted(p for p in base if base[p]!=value[p]),'removed':[]}
out=QA/'performance15_stage7912_independent_actual_output_inverse_review_READY.json'
result={'status':'INDEPENDENT_BONLY22_ACTUAL_SOURCE_OUTPUTS_NO_BLOCKER_NOT_DEPLOYED','actual_stage_sha256':sha(rp.read_bytes()),'actual_source_first_final_same':3006,'source_recrawl':False,'candidate_SHA_and_old_current_exact':22,'metadata_whole_typed_inverse_count':metadata,'index_whole_byte_count':indexes,'GD_independent_patch_forward_bytes':9,'JSON_exact_copy_partition':13,'maps_from_fixed9D004_and_explicit22_and_two_proofs':changes,'fourT_source_classes_and_original_native_mask_r3_parents_exact':True,'engine_Stage_collector_decode_calls':0,'canonical_writes':0,'blocking_findings':[]}
assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
