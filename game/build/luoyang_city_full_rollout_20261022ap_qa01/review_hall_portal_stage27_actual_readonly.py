"""Retained Stage27 artifacts only; no Stage/engine/native decode/media hash."""
from pathlib import Path
import hashlib,json,copy
G=Path('F:/Code/RPG_GAME/game');S=G/'build/luoyang_hall_portal_fix_20261024a_source01'
OUT=G/'build/luoyang_city_full_rollout_20261022ap_qa01/hall_portal_stage27_actual_review_READY.json'
assert not OUT.exists()
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return G/p[6:] if p.startswith('res://') else Path(p)
def read(p):return json.loads(res(p).read_bytes())
def same(a,b):
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
rp=S/'outputs/root_hall_portal_exact27_stage01/receipt.json';raw=rp.read_bytes()
assert sha(raw)=='f085977a59f3a31de20bf1910e1822ff1ad20154f75d97c4c141a3826523a235'
r=json.loads(raw);spec=json.loads((S/'source_input_ROOT_READY.json').read_bytes())
scope=json.loads((S/'exact27_scope_PROPOSAL_NOT_APPROVED.json').read_bytes())
pins={x['id']:x for x in spec['pinned_inputs']}
targets={x['target']:x for x in r['targets']};scope_rows={x['target']:x for x in scope['targets']}
assert len(targets)==27 and targets.keys()==scope_rows.keys()
assert r['target_partition']=={'patch_count':13,'copy_count':14,'total':27,'intersection_empty':True,'union_exact_targets':True}
assert r['source_first']==r['source_final'] and len(r['source_first'])==3089
for p,row in targets.items():
    assert row['old_sha256']==scope_rows[p]['old_sha256'] and row['old_sha256']!=row['candidate_sha256']
    assert sha(res(row['candidate_path']).read_bytes())==row['candidate_sha256']
    assert not p.endswith(('.res','.png','.ctex')) and not p.endswith('/registry.json') and not p.endswith('/author.json')
phases={sha(res(p).read_bytes())==row['candidate_sha256'] for p,row in targets.items()}
assert phases=={True},'Root formal27 exact current candidates required after deployment'
def base_bytes(node):
    pin=pins[node['base_input']];b=res(pin['path']).read_bytes();assert sha(b)==pin['sha256'];return b
def restore(value,deltas):
    value=copy.deepcopy(value)
    for d in reversed(deltas):
        at=value
        for part in d['pointer'][:-1]:at=at[part]
        leaf=d['pointer'][-1]
        if d['existed']:at[leaf]=copy.deepcopy(d['old'])
        else:del at[leaf]
    return value
metadata=[];indices=[];frozen=[]
for n in spec['nodes']:
    ident=n['id'];kind=n['kind'];v=r['nodes'][ident];proof=r['proofs'][ident]
    if kind in ['metadata','hall_contract']:
        assert proof['whole_typed_inverse'] is True
        parent=json.loads(base_bytes(n));candidate=json.loads(res(v['path']).read_bytes())
        assert same(candidate,v['value']) and same(restore(candidate,proof['source_delta']),parent),ident
        if kind=='hall_contract':
            old_field='f98b22cd600f3d09dbb153db5baac9d0dcc22c3658803d30f23b2ae9b7df47a4'
            new_field='93c4d7a7b2fef829f8f7e1c88c9dd00b17795f4794e167682a59ae1f52ee22e0'
            assert base_bytes(n).replace(old_field.encode(),new_field.encode())==res(v['path']).read_bytes()
        # Root64 ordinary Root proof leaves must stay in legacy, not resurrect
        # an older FD58 runtime_authority classification.
        for p,h in parent.get('legacy_source_sha256',{}).items():
            if p.startswith('res://build/luoyang_city_full_rollout_20261022ap_root01/'):
                assert p in candidate['legacy_source_sha256'] and p not in candidate.get('runtime_authority_sha256',{}),p
        metadata.append(ident)
    elif kind=='index':
        b=base_bytes(n)
        for change in n['replacements']:
            new=change['new'];new=r['nodes'][new['$sha']]['sha256'] if isinstance(new,dict) else new
            old=change['old'].encode();assert old in b;b=b.replace(old,str(new).encode())
        assert b.count(n['disabled_literal'].encode())==1
        b=b.replace(n['disabled_literal'].encode(),n['enabled_literal'].encode())
        assert b==res(v['path']).read_bytes(),ident
        indices.append(ident)
    elif kind=='hall_frozen':
        assert proof['fixed_frozen_non_target'] and v['sha256']==sha(base_bytes(n))
        assert n.get('target') is None;frozen.append(ident)
assert len(metadata)==13 and len(indices)==8 and 'registry_final' in frozen
patch=res(r['patch_path']).read_bytes();assert sha(patch)==r['patch_sha256']
lines=patch.splitlines(keepends=True);sections={};current=None;chunks=[]
for line in lines:
    if line.startswith(b'*** Update File: '):
        current=line[len(b'*** Update File: '):].strip().decode();sections[current]=[]
    elif line.startswith(b'@@'):
        assert current is not None;sections[current].append([])
    elif line.startswith((b' ',b'+',b'-')) and current is not None:
        sections[current][-1].append(line)
assert len(sections)==13
old_by_target={n['target']:base_bytes(n) for n in spec['nodes'] if n.get('target') and n.get('base_input')}
for p in targets:
    if p not in old_by_target:
        snap=scope_rows[p]['old_snapshot'];b=res(snap).read_bytes();assert sha(b)==targets[p]['old_sha256'];old_by_target[p]=b
for absolute,chunks in sections.items():
    relative='res://'+Path(absolute).resolve().relative_to(G).as_posix();old=old_by_target[relative]
    assert sha(old)==targets[relative]['old_sha256'];b=old
    for chunk in chunks:
        before=b''.join(x[1:] for x in chunk if x[:1] in [b' ',b'-'])
        after=b''.join(x[1:] for x in chunk if x[:1] in [b' ',b'+'])
        assert b.count(before)==1,relative;b=b.replace(before,after,1)
    assert b==res(targets[relative]['candidate_path']).read_bytes(),relative
copy_plan=read(r['byte_copy_plan']['path']);assert sha(res(r['byte_copy_plan']['path']).read_bytes())==r['byte_copy_plan']['sha256']
assert len(copy_plan['rows'])==14 and all(x['target'].endswith('.json') for x in copy_plan['rows'])
# Retained native/registry content identity from existing source declarations,
# not an independent reread of .res/media or full3089payload scan.
owner=read('res://build/luoyang_city_full_rollout_20261022ap_qa01/unified102_deployed_classification15_owner_ROOT64_READY/owner_source_maps_READY.json')
domain={}
for row in owner['rooms']:domain.update(row['source_sha256'])
native_kept=[p for p in domain if p.endswith(('.res','/author.json','/registry.json')) and p in r['source_first']]
assert native_kept and all(r['source_first'][p]==domain[p] for p in native_kept)
registry='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
assert r['source_first'][registry]=='56c5bd39f02f32b45a606c84e22a8784be4900c616b7ec20c7547e497ce49f12'
review={'status':'ACTUAL_STAGE27_AND_FORMAL_CURRENT_SMALL_ARTIFACT_REVIEW_NOT_FIELD_PASS','actual_receipt_sha256':sha(raw),'exact_targets':27,'partition':r['target_partition'],'current27_sha_match_candidates':True,'metadata_whole_typed_inverse_count':len(metadata),'index_whole_byte_reconstruction_count':len(indices),'GD_patch_independent_reconstruction_count':len(sections),'JSON_copy_count':14,'source_first_final_equal_declarations':len(r['source_first']),'Root64_ordinary_Root_proof_legacy_classification_preserved':True,'room_native_author_registry_declared_unchanged_count':len(native_kept),'room_native_redecoded_or_rehashed':False,'registry_frozen':registry,'frozen_nodes':frozen,'no_engine_Stage_collector_or_mediahash':True,'scope':'Runtime G/Field/world_v15 plus exact dependent code/index/source metadata; two new build helpers tracked but no native/registry/actor author changes. Field real runtime checks still NOTREADY until independent new owner/fresh guard.'}
OUT.write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'path':str(OUT),'sha256':sha(OUT.read_bytes()),'targets':27,'typed_metadata':len(metadata),'index_bytes':len(indices),'GDpatch':len(sections),'source_first_final':len(r['source_first'])}))
