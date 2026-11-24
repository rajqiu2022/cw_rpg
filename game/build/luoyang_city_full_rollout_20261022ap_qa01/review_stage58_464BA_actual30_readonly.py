"""Actual staged artifacts and inverses; no stager import, decode or source crawl."""
from pathlib import Path
import copy
import hashlib
import json

Q=Path(__file__).resolve().parent;G=Q.parents[1]
S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(p):return G/p[6:]
def at(v,ks):
    for k in ks:v=v[k]
    return v
def strict(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return set(a)==set(b) and all(strict(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(strict(x,y) for x,y in zip(a,b))
    return a==b
def restore(value,changes):
    v=copy.deepcopy(value)
    for d in reversed(changes):
        holder,key=at(v,d['pointer'][:-1]),d['pointer'][-1]
        if d['existed']:holder[key]=d['old']
        else:del holder[key]
    return v
def chunks(lines):
    out=[];a=[];b=[]
    for line in lines:
        if line=='@@\n':
            if a or b:out.append((''.join(a),''.join(b)))
            a=[];b=[]
        else:
            assert line and line[0] in ' +-'
            if line[0] in ' -':a.append(line[1:])
            if line[0] in ' +':b.append(line[1:])
    if a or b:out.append((''.join(a),''.join(b)))
    return out
def replay(text,hunks):
    out=[];cursor=0
    for a,b in hunks:
        pos=text.find(a,cursor);assert pos>=0
        out.extend([text[cursor:pos],b]);cursor=pos+len(a)
    return ''.join(out)+text[cursor:]

rp=S/'outputs/root_market_complete_parent30_stage01/receipt.json'
assert sha(rp)=='464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f'
r=rd(rp)
ip=S/'performance58_market_parent30_source_recipe/source_input_ROOT_LOCKED.json'
assert sha(ip)=='a29f32c01dcac22c4a1289e5bd5084c4cb76195d7666ee021165d6aba98dd140'
s=rd(ip);pins={x['id']:x for x in s['pinned_inputs']};ns={x['id']:x for x in s['nodes']}
assert r['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED' and r['source_first']==r['source_final'] and len(r['source_first'])==3026
assert r['source_first']['res://'+ip.relative_to(G).as_posix()]==sha(ip)
assert r['target_partition']=={'patch_count':15,'copy_count':15,'total':30,'intersection_empty':True,'union_exact_targets':True}
assert r['no_engine_import_collector_or_canonical_write'] and not r['runtime_inverse_replayed']
targets={x['target']:x for x in r['targets']}
assert len(targets)==30 and set(targets)==set(s['root_target_allowlist'])
raws={};olds={}
for path,row in targets.items():
    raw=res(row['candidate_path']).read_bytes();old=res(path).read_bytes()
    assert hashlib.sha256(raw).hexdigest()==row['candidate_sha256']
    assert hashlib.sha256(old).hexdigest()==row['old_sha256']!=row['candidate_sha256']
    raws[path]=raw;olds[path]=old
metadata=[];indices=[]
for ident,node in r['nodes'].items():
    row=ns[ident];raw=res(node['path']).read_bytes();assert hashlib.sha256(raw).hexdigest()==node['sha256']
    if row['kind'] in ['metadata','repair30_contract_literal']:
        original=rd(res(pins[row['base_input']]['path']))
        assert strict(json.loads(raw),node['value'])
        assert r['proofs'][ident]['whole_typed_inverse'] and strict(restore(node['value'],r['proofs'][ident]['source_delta']),original)
        for ptr in row.get('protected_pointers',[]):assert strict(at(node['value'],ptr),at(original,ptr))
        for key in ['artifacts','layout_proof','mask_sha256','geometry_proof_basis','native_artifacts','parent_publication']:
            if key in original:assert strict(node['value'][key],original[key])
        if ident in ['finite08_market','finite08_yamen']:
            assert not any(path.startswith('res://data/maps/luoyang_layout_bundle_20261018t_retry2/') for path in node['value']['legacy_source_sha256'])
        metadata.append(ident)
    elif row['kind']=='index':
        original=res(pins[row['base_input']]['path']).read_bytes();text=original.decode();replacements=[]
        for h in row['replacements']:
            value=h['new']
            if isinstance(value,dict):
                if '$pin' in value:value=pins[value['$pin']]['sha256']
                else:
                    ref=r['nodes'][value['$sha']];value=ref['disabled_sha256'] if value.get('variant')=='disabled' else ref['sha256']
            assert text.count(h['old'])==1;text=text.replace(h['old'],value,1);replacements.append((h['old'],value))
        assert hashlib.sha256(text.encode()).hexdigest()==r['proofs'][ident]['disabled_sha256']
        assert text.count(row['disabled_literal'])==1 and text.replace(row['disabled_literal'],row['enabled_literal'],1).encode()==raw
        for old,new in reversed(replacements):
            assert text.count(new)==1;text=text.replace(new,old,1)
        assert text.encode()==original;indices.append(ident)
assert len(metadata)==14 and len(indices)==8
patch=res(r['patch_path']);assert sha(patch)==r['patch_sha256']
lines=patch.read_bytes().decode().splitlines(keepends=True)
assert lines[0]=='*** Begin Patch\n' and lines[-1]=='*** End Patch\n'
sections={};path=None;body=[]
for line in lines[1:-1]:
    if line.startswith('*** Update File: '):
        if path is not None:sections[path]=chunks(body)
        path=line[len('*** Update File: '):].rstrip('\n');body=[]
    else:body.append(line)
if path is not None:sections[path]=chunks(body)
assert len(sections)==15
adapter='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/finite_adapter_READY.gd'
for path,row in targets.items():
    if not path.endswith('.gd'):continue
    a,b=olds[path],raws[path];proof=r['patch_reconstruction'][path]
    if path==adapter:
        assert not a.endswith(b'\n') and not b.endswith(b'\n') and b'\r' not in a+b
        assert proof['forward_exact_bytes'] is False and proof['whole_inverse_exact_bytes'] is False and proof['whole_shadow_inverse_exact_bytes']
        assert proof['reconstructed_sha256']==proof['patch_intermediate_sha256']=='9fc421182b8143f3fe0711322fe51788b443b5a5132dd7c524d961562b0f0025'
        assert proof['eof_format']['required_final_sha256']==row['candidate_sha256']=='cf2aa3da4f8dbafd30d48d9310d69d7eacb9f17d25e47ce02ca221835eff3736'
        assert proof['patch_intermediate_bytes']==31207 and len(b)==31206
        assert proof['eof_format']['must_first_apply_patch_then_mechanically_remove_one_final_byte_from_deployed_characters']
        a+=b'\n';b+=b'\n'
    else:assert proof['forward_exact_bytes'] and proof['whole_inverse_exact_bytes']
    hunks=sections[res(path).as_posix()]
    assert replay(a.decode(),hunks).encode()==b
    assert replay(b.decode(),[(y,x) for x,y in hunks]).encode()==a
copyfile=res(r['byte_copy_plan']['path']);assert sha(copyfile)==r['byte_copy_plan']['sha256']
copies=rd(copyfile);copytargets={x['target'] for x in copies['rows']}
assert len(copytargets)==15 and copytargets=={p for p in targets if p.endswith('.json')}
assert set(sections)=={res(p).as_posix() for p in targets if p.endswith('.gd')}
for row in copies['rows']:
    assert row['mechanism']=='EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION' and row['candidate_bytes']==len(raws[row['target']])
registry=r['nodes']['registry_final']['value'];estate=r['nodes']['estate_final']['value']
assert estate['registry_path']=='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
assert estate['registry_sha256']==estate['source_sha256'][estate['registry_path']]==r['nodes']['registry_final']['sha256']
oldregistry=rd(res(pins[ns['registry_final']['base_input']]['path']))
changes=[]
for ident,room in registry['rooms'].items():
    oldroom=oldregistry['rooms'][ident]
    keys=[k for k in room['source_sha256'] if room['source_sha256'][k]!=oldroom['source_sha256'][k]]
    if keys:
        assert keys==['res://scripts/city/luoyang_district_life_20261016f.gd'];changes.append(ident)
assert len(changes)==5
fade='res://scripts/city/luoyang_district_life_fade_20261016f.gd';fadeids=[]
for ident,node in r['nodes'].items():
    row=ns[ident]
    for op in row.get('operations',[]):
        if op['pointer']==['source_migration','source_delta',fade]:
            actual=at(node['value'],op['pointer']);assert strict(actual,op['new'])
            assert actual['current_before_sha256']=='58462561e7db2b3f26fd6e5a55b891fc85002d86c51228a771f354b3ca9311a8'
            assert actual['historical_sha256']==op['old']['historical_sha256']+[actual['current_before_sha256']];fadeids.append(ident)
assert len(fadeids)==4
prior=rd(res(pins[s['B_only_contract']['prior_owner_input']]['path']))
authority=rd(res(pins[s['authority_input']]['path']))
oldauth=rd(res(pins[s['B_only_contract']['parent_execution_input']]['path']))
extra={p:v for p,v in authority['source_sha256'].items() if p not in oldauth['source_sha256']}
assert len(extra)==10
def migrate(table):
    v={p:targets[p]['candidate_sha256'] if p in targets else x for p,x in table.items()}
    for p,x in extra.items():assert p not in v;v[p]=x
    return v
scenes={x['id']:x for x in prior['scenes']};counts={}
for row in s['nodes']:
    if row['kind']!='map':continue
    actual=r['nodes'][row['id']]['value']['source_sha256']
    assert strict(actual,migrate(scenes[row['scene_id']]['source_sha256']))
    counts[row['scene_id']]=len(actual)
assert counts=={'ch4_s0_luoyang_gate':898,'ch4_s1_luoyang_yamen':1249,'ch4_s2_canal_docks':1726,'ch4_s3_luoyang_market':1712}
two=next(g for g in s['source_groups'] if g['id']=='source_only_proof_autoimport_exact2')['leaves']
assert len(two)==2
for row in s['nodes']:
    if row['kind']=='map':
        present=set(two)&set(r['nodes'][row['id']]['value']['source_sha256'])
        assert present==(set(two) if row['scene_id']=='ch4_s3_luoyang_market' else set())
root=G/'build/luoyang_city_full_rollout_20261022ap_root01/integration43/guard_before.json'
assert sha(root)=='25374fe35efa1d64f7efeadb8ccaec28e6e0574b53e471d77af837a48fc75c20'
guard=rd(root);saves=[x for x in guard['facts'] if x['path'] in guard['save_paths']]
assert len(saves)==15
for f in saves:
    p=Path(f['path'])
    if f['sha256']=='ABSENT':assert not p.exists()
    else:assert p.stat().st_size==f['bytes'] and sha(p)==f['sha256']
out=Q/'stage58_464BA_actual30_artifact_inverse_merge_admission_READY.json'
assert not out.exists()
out.write_text(json.dumps({
    'status':'INDEPENDENT_ACTUAL_STAGE58_OUTPUTS_NO_MERGE_BLOCKER_PENDING_OWNER_AND_ROOT_DEPLOYMENT',
    'actual_stage_SHA':sha(rp),'candidate30_and_currentold30_SHA_exact':True,'source_FIRSTFINAL_same_declared_not_rehashed':3026,
    'metadata_whole_strict_typed_inverse':metadata,'index_whole_byte_inverse':indices,
    'patch':{'GD15_forward_inverse_reconstructed':True,'other14_exactfinal':True,'adapter_only_shadow9FC421_31207':True,
        'finalCF2A31206_requires_Root_actual_patch_then_exact_final0A_remove':True,'direct_final_patch_credit':False,'GDcopy':False},
    'JSON15_exactcopy_disjoint_full30_union':True,'registry5_DT_only_room_source_changes':changes,
    'Estate_registry_path_scalar_and_source_triple_equal':True,'four_Fade_rows5846_history_append':fadeids,
    'four_source_maps_independent_FC11_plus30_existing_values_and_exact10proofs':counts,
    'Root39_SOURCE_ONLY_exact2_onlyMarket_and_source_classifications_unchanged':True,
    'original_native_artifacts_masks_r3_parentpublication_protected_fields_exact':True,
    '15save_current_SHAbytes_equal_fixed_Root43':True,'save_exactticks_inherited_guard_not_new_after_measurement':True,
    'limits':['Source Stage only, no Field/ART/runtime entrance pass','Full 8scene5room owner awaits actual owner tool output',
        'No3026 source recrawl, no media or packet decode, no old failure rewritten'],
    'operations':{'Stage':0,'engine':0,'collector':0,'decode':0,'canonical':0}
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'merge_static_blocker':False,'source_counts':counts}))
