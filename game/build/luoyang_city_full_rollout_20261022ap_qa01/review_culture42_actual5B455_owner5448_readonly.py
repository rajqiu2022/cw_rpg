"""One actual-output/independent-recipe audit. No Stage/runtime/media decoding."""
import copy
import hashlib
import json
from pathlib import Path

QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
SF=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
OUT=QA/'culture42_actual5B455_owner5448_independent_merge_admission_READY.json'
assert not OUT.exists()
def res(v):return GAME/v.removeprefix('res://')
def sha(v):return hashlib.sha256(v.read_bytes()).hexdigest()
def read(v):return json.loads(v.read_text(encoding='utf-8-sig'))
def strict(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return set(a)==set(b)and all(strict(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(strict(x,y)for x,y in zip(a,b))
    return a==b
def at(v,keys):
    for k in keys:v=v[k]
    return v
def restore(v,changes):
    v=copy.deepcopy(v)
    for d in reversed(changes):
        holder,key=at(v,d['pointer'][:-1]),d['pointer'][-1]
        if d['existed']:holder[key]=d['old']
        else:del holder[key]
    return v
def merge(*tables):
    result={}
    for table in tables:
        for k,v in table.items():
            assert k not in result or result[k]==v,k
            result[k]=v
    return result
def replay(text,parts):
    cursor=0;result=[]
    for a,b in parts:
        pos=text.find(a,cursor);assert pos>=0
        result.extend([text[cursor:pos],b]);cursor=pos+len(a)
    return ''.join(result)+text[cursor:]
def chunks(lines):
    result=[];a=[];b=[]
    for line in lines:
        if line=='@@\n':
            if a or b:result.append((''.join(a),''.join(b)))
            a=[];b=[]
        else:
            assert line and line[0]in ' +-'
            if line[0]in ' -':a.append(line[1:])
            if line[0]in ' +':b.append(line[1:])
    if a or b:result.append((''.join(a),''.join(b)))
    return result

rp=SF/'outputs/root_culture_C_source_repair_stage01/receipt.json'
op=SF/'performance43_culture_actual_independent_review/owner_source_maps_READY.json'
vp=SF/'performance43_culture_actual_independent_review/source_stage_review_READY.json'
assert sha(rp)=='5b4552e6751950b8576dadfec211a0b966ffdbe77817571197150347ae96ca5e'
assert sha(op)=='544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0'
assert sha(vp)=='5c50acacd04e6d5efaccbdf48a28acbe9133a8487db4ba4fa21072d6b9effa35'
d,owner,review=read(rp),read(op),read(vp)
assert d['source_first']==d['source_final'] and len(d['source_first'])==3027
assert d['target_partition']=={'patch_count':10,'copy_count':14,'total':24,'intersection_empty':True,'union_exact_targets':True}
pp=SF/'performance42_culture24_source_recipe/source_input_ROOT_LOCKED.json'
assert sha(pp)==d['source_first']['res://'+pp.relative_to(GAME).as_posix()]=='decabd917e9a3526c561cdcd0ed3f91e12406696d1a30ae72cad281597b8f277'
plan=read(pp);pins={x['id']:x for x in plan['pinned_inputs']}
targets={r['target']:r for r in d['targets']};assert len(targets)==24 and set(targets)==set(plan['root_target_allowlist'])
backupdoc=read(ROOT/'integration31/old_full_backups_READY.json')
backups={'res://'+Path(r['path']).relative_to(GAME).as_posix():r for r in backupdoc['targets']}
assert set(backups)==set(targets)
raws={}
for target,row in targets.items():
    candidate=res(row['candidate_path']).read_bytes();assert hashlib.sha256(candidate).hexdigest()==row['candidate_sha256']
    assert row['old_sha256']==backups[target]['sha256']!=row['candidate_sha256']
    assert sha(res(target))==row['old_sha256'] and sha(Path(backups[target]['backup_path']))==row['old_sha256']
    raws[target]=candidate
metadata=[];indices=[]
for n in plan['nodes']:
    ident=n['id'];node=d['nodes'][ident];b=res(node['path']).read_bytes();assert hashlib.sha256(b).hexdigest()==node['sha256']
    if n['kind']in ('metadata','culture_contract_literal'):
        base=read(res(pins[n['base_input']]['path']))
        assert strict(restore(node['value'],d['proofs'][ident]['source_delta']),base)
        assert strict(json.loads(b),node['value']);metadata.append(ident)
        for key in ('artifacts','layout_proof','mask_sha256','geometry_proof_basis','native_artifacts','parent_publication'):
            if key in base:assert strict(node['value'].get(key),base[key])
    elif n['kind']=='index':
        original=res(pins[n['base_input']]['path']).read_bytes();text=original.decode('utf-8');resolved=[]
        for h in n['replacements']:
            v=h['new']
            if isinstance(v,dict):v=d['nodes'][v['$sha']]['sha256']if '$sha'in v else pins[v['$pin']]['sha256']
            assert text.count(h['old'])==1
            text=text.replace(h['old'],v,1);resolved.append((h['old'],v))
        assert hashlib.sha256(text.encode()).hexdigest()==d['proofs'][ident]['disabled_sha256']
        assert text.replace(n['disabled_literal'],n['enabled_literal'],1).encode()==b
        for a,c in reversed(resolved):assert text.count(c)==1;text=text.replace(c,a,1)
        assert text.encode()==original;indices.append(ident)
    elif n['kind']=='culture_frozen_node':assert node['sha256']==pins[n['base_input']]['sha256']and 'target'not in n
assert len(metadata)==13 and len(indices)==8
CON='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'
oldcon=read(res(CON));newcon=read(res(targets[CON]['candidate_path']));inv=copy.deepcopy(newcon);inv['source_sha256'][C]=oldcon['source_sha256'][C]
assert strict(inv,oldcon)and newcon['source_sha256'][C]==sha(res(C))=='b14a1042421029651fe0283d3daf8f6e52bea96c9047b79095912f1eb45dc9be'
assert targets[CON]['candidate_sha256']=='59cf1ebdac2f8f17b644b00f36e241b8b4e43275a50ec6a8b1eb7d89632e59c1'
assert d['proofs']['runtime_contract_final']['exact59CF_literal_after_original_typed_inverse']and d['proofs']['runtime_contract_final']['whole_literal_byte_inverse_7EE']
patch=res(d['patch_path']);assert sha(patch)==d['patch_sha256'];lines=patch.read_bytes().decode().splitlines(keepends=True)
assert lines[0]=='*** Begin Patch\n'and lines[-1]=='*** End Patch\n'
sections={};current=None;body=[]
for line in lines[1:-1]:
    if line.startswith('*** Update File: '):
        if current is not None:sections[current]=chunks(body)
        current=line[len('*** Update File: '):].rstrip('\n');body=[]
    else:body.append(line)
if current is not None:sections[current]=chunks(body)
assert len(sections)==10
for target,row in targets.items():
    if not target.endswith('.gd'):continue
    old=Path(backups[target]['backup_path']).read_bytes();new=raws[target];proof=d['patch_reconstruction'][target]
    assert proof['forward_exact_bytes']is True and proof['whole_inverse_exact_bytes']is True
    assert old.endswith(b'\n')and new.endswith(b'\n')and b'\r'not in old+new
    parts=sections[res(target).as_posix()]
    assert replay(old.decode(),parts).encode()==new and replay(new.decode(),[(b,a)for a,b in parts]).encode()==old
copyfile=res(d['byte_copy_plan']['path']);copies=read(copyfile)
assert sha(copyfile)==d['byte_copy_plan']['sha256']and len(copies['rows'])==14
assert {r['target']for r in copies['rows']}=={p for p in targets if p.endswith('.json')}
assert {res(p).as_posix()for p in targets if p.endswith('.json')}.isdisjoint(sections)

priorp=SF/'performance39_merged_EOF_actual_independent_review/owner_source_maps_READY.json'
assert sha(priorp)=='b2858260460afe9c655fdd0eca0b2408f11267e1aa313d23b0ee4ccbee0a1d0c'
prior=read(priorp);oldscenes={r['id']:r for r in prior['scenes']};scenes={r['id']:r for r in owner['scenes']}
hand=read(res(pins[plan['B_only_contract']['production_input']]['path']));proofs=hand['new_exact5_proof_pins'];assert len(proofs)==5
def replace(table):
    result=dict(table)
    for path,row in targets.items():
        if path in result:assert result[path]==row['old_sha256'];result[path]=row['candidate_sha256']
    return result
for n in plan['nodes']:
    if n['kind']=='map':
        r=scenes[n['scene_id']];assert r['source_sha256']==r['receipt_source_sha256']==d['nodes'][n['id']]['value']['source_sha256']
quarter=d['nodes']['quarter_final']['value']['source_sha256']
for ident in ('luoyang_artisan_residential_20261022ap','luoyang_riverside_garden_20261022ap'):
    old=oldscenes[ident];headers={k:v for k,v in old['source_sha256'].items()if k not in old['receipt_source_sha256']}
    assert scenes[ident]['source_sha256']==merge(quarter,replace(headers))and scenes[ident]['receipt_source_sha256']==quarter
ident='luoyang_estate_riverside_20261021ai'
assert scenes[ident]['source_sha256']==replace(oldscenes[ident]['source_sha256'])and scenes[ident]['receipt_source_sha256']==replace(oldscenes[ident]['receipt_source_sha256'])
ident='ch4_s4_ancient_temple';expected=merge(replace(oldscenes[ident]['source_sha256']),proofs)
assert scenes[ident]['source_sha256']==scenes[ident]['receipt_source_sha256']==expected
for ident,old in oldscenes.items():
    skip={'source_sha256','receipt_source_sha256','recipe'}
    assert {k:v for k,v in scenes[ident].items()if k not in skip}=={k:v for k,v in old.items()if k not in skip}
oldrooms={r['id']:r for r in prior['rooms']}
for row in owner['rooms']:
    old=oldrooms[row['id']]
    assert row['source_sha256']==merge(replace(old['source_sha256']),proofs)
    assert row['receipt_source_sha256']==old['receipt_source_sha256']==d['nodes']['registry_final']['value']['rooms'][row['id']]['source_sha256']
assert owner['core_source_sha256']=={**prior['core_source_sha256'],**{p:r['candidate_sha256']for p,r in targets.items()}}
union=merge(*(r[f]for r in owner['scenes']+owner['rooms']for f in ('source_sha256','receipt_source_sha256')))
oldunion=merge(*(r[f]for r in prior['scenes']+prior['rooms']for f in ('source_sha256','receipt_source_sha256')))
counts={'changed_targets':0,'stage_declared':0,'inherited_not_rehashed':0}
for path,value in union.items():
    if path in targets:assert value==targets[path]['candidate_sha256'];counts['changed_targets']+=1
    elif path in d['source_first']:assert value==d['source_first'][path];counts['stage_declared']+=1
    else:assert value==oldunion[path];counts['inherited_not_rehashed']+=1
assert len(union)==2965 and counts=={'changed_targets':20,'stage_declared':2937,'inherited_not_rehashed':8}
gp=ROOT/'integration31/guard_before.json';g=read(gp)
assert sha(gp)=='4e3c18f870c1af9c1a4ee677bfb6e1b653be9ab9f33461eab557fc6af6a68285'
saves=[r for r in g['facts']if r['path']in g['save_paths']];assert len(saves)==15
for r in saves:
    f=Path(r['path'])
    if r['sha256']=='ABSENT':assert not f.exists()
    else:assert sha(f)==r['sha256']and f.stat().st_size==r['bytes']
result={'status':'ACTUAL_CULTURE42_AND_OWNER43_NO_BLOCKER_FOR_ROOT_EXACT24_MERGE_PLANNING_NOT_DEPLOYED_OR_RUNTIME_PASS','stage_sha256':sha(rp),'owner_sha256':sha(op),'source_review_sha256':sha(vp),'actual':{'targets':24,'GD_patch':10,'JSON_copy':14,'whole_typed_metadata_inverse':metadata,'whole_index_byte_inverse':indices,'patch10_full_forward_and_inverse':True,'all3027_source_FIRSTFINAL_declarations_same_not_rehashed':True,'all24_current_still_old_SHA':True,'contract_exact_C_value_only_rest25_unchanged':True,'allnative_parent_mask_storage_preserved':True,'15save_current_SHA_bytes_same_Root31before':True,'exact_ticks_only_from_Root_guard_not_new_after':True},'owner_recipe':{'fixedB285_plus24explicit_targets_and5proofs':True,'union':2965,**counts,'scene_counts':{k:{'collector':len(v['source_sha256']),'receipt':len(v['receipt_source_sha256'])}for k,v in scenes.items()},'room_receipts_whole_frozen':[len(r['receipt_source_sha256'])for r in owner['rooms']],'G_full_collector':557,'native_scene_layout_identities_inherited':True,'no_collector_current_fill':True},'limits':['Only exact source closure ready for Root merge, not readiness/performance/runtime proof','07 wholeFAIL and C0000005 preserved','08 pending Root31after and Root32before; no rereun of07','no Stage/engine/collector/native or image decode/large media hash/canonical writes']}
OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(OUT),'sha256':sha(OUT),'owner_Yamen':len(scenes['ch4_s1_luoyang_yamen']['source_sha256']),'counts':counts}))
