"""Small exact18 scope, exclusively from formal Stage91A1/AF129 declarations."""
from pathlib import Path
import json, hashlib
GAME=Path(__file__).resolve().parents[2]; HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/'
P='res://build/luoyang_market_use_20261024b_system01/texture_union_fix01/'
ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
def sha(b): return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=(GAME/p[6:]).read_bytes(); assert sha(b)==h,(p,sha(b)); return b
def load(p,h): return json.loads(read(p,h))
parentpath=S+'outputs/root_C_packed_exact27_stage01/receipt.json'
parenthash='91a1e5d25a596436066f508a6ac13cc4518125a88a1c271aae8061e5024423ed'
parent=load(parentpath,parenthash)
olderpath=S+'outputs/root_market_worker_facts_exact35_stage01/receipt.json'
olderhash='af129e34538479d7aaae3a1e87e7194d44fc52354ec44de9dcd41a77eecadd0c'
older=load(olderpath,olderhash)
proofpath=P+'whole_byte_inverse_and_five_group_static_READY.json'
proofhash='ae7d840b1a743c7ed49f2d5993b5e1fd39b24c766f3459dcfb60bd6ebadc59b1'
proof=load(proofpath,proofhash)
after=read(proof['candidate']['path'],proof['candidate']['sha256'])
before=read(next(r['candidate_path'] for r in older['targets'] if r['target']==ENV),proof['parent']['sha256'])
back=after
for r in reversed(proof['replacements']):
    a,b=r['old'].encode(),r['new'].encode(); assert back.count(b)==1; back=back.replace(b,a,1)
assert back==before
ids=['legacy_manifest_'+str(i) for i in range(2,9)]+['quarter_final','market_final','finite08_market','finite08_yamen']
indexids=['legacy_index_'+str(i) for i in range(1,5)]+['ap_quarter_index','ap_city_index']
rawplan=(HERE/'source_input_C_packed27_ROOT_READY.json').read_bytes()
assert sha(rawplan)=='c76126cf140b045ce14257a67652f1aa9bf3a53623a2fb8dc2fae3d3975efab6'
plan=json.loads(rawplan); byid={n['id']:n for n in plan['nodes']}
rows=[]
for ident in ids+indexids:
    target=byid[ident]['target']; i=next(i for i,r in enumerate(parent['targets']) if r['target']==target);r=parent['targets'][i]
    if ident in ids:
        value=parent['nodes'][ident]['value']; matches=[k for k,v in value.items() if isinstance(v,dict) and v.get(ENV)==proof['parent']['sha256']]
        assert matches,(ident,'NO_FIXED_ENV_SOURCE')
    rows.append(dict(target=target,old_sha256=r['candidate_sha256'],old_declaration=dict(path=parentpath,sha256=parenthash,pointer=['targets',i,'candidate_sha256']),node=ident))
i=next(i for i,r in enumerate(older['targets']) if r['target']==ENV);r=older['targets'][i]
rows.insert(0,dict(target=ENV,old_sha256=r['candidate_sha256'],old_declaration=dict(path=olderpath,sha256=olderhash,pointer=['targets',i,'candidate_sha256']),candidate=proof['candidate']))
assert len(rows)==18 and sum(r['target'].endswith('.gd') for r in rows)==7
binding=load(S+'packed_dependencies04/temple_binding_C_Coord_contract_CANDIDATE.json','31d93061ff74ad0fcaafe0cd62f145b5ca89d85b8c36e69a4607d5a7658145a5')
parentbinding=load(binding['parent_binding_path'],binding['parent_binding_sha256'])
merged=parentbinding['source_sha256']|binding['source_delta']; assert len(merged)==194 and ENV not in merged
assert ENV not in parent['nodes']['estate_final']['value']['source_sha256']
value=dict(status='ENV_EXACT_TEXTURE_UNION18_PREPARATION_NOT_STAGE',ready=False,parent_stage=dict(path=parentpath,sha256=parenthash),code_inverse=dict(path=proofpath,sha256=proofhash,whole_byte_inverse=True),target_count=18,targets=rows,partition=dict(strict_apply_patch_GD=7,exact_copy_JSON=11),
    sole_behavior='Market used texture keys include the already fixed five-purpose asset union before unchanged texture/source validation; no new texture/source/media key',
    ordinary_ENV=True,execution_frozen=dict(active_owned_members=10,proof_leaves=132,no_edge_or_member_change=True),
    excluded=dict(Temple='Merged194 fixed source table contains no ENV SHA; source_paths dynamically merges ENV source_paths_for(ID). No Temple or binding rewrite.',Estate='No ENV fixed source leaf; Estate manifest and EstateIndex unchanged.',other=['C','Field','AA','AC','runtime','adapter','B','DT','Fade','G','registry','Coordinator','culture_contract','dialogue','UI','all native/media/geometry']),
    maps=dict(source_keys_unchanged=True,note='Only existing values change via exact18 source/header successors; derive actual full maps in Stage, no collector/currentfill.'),Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)
# Counts are inherited directly, not guessed from a code delta.
for ident,key in [('expected_ch4_s0_luoyang_gate_true','Gate'),('expected_ch4_s1_luoyang_yamen_true','Yamen'),('expected_ch4_s2_canal_docks_true','Docks'),('expected_ch4_s3_luoyang_market_true','Market')]:
    value['maps'][key]=len(parent['nodes'][ident]['value']['source_sha256'])
b=(json.dumps(value,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
out=HERE/'ENV_texture_union18_scope_PREPARATION_NOT_STAGE.json'
with out.open('xb') as f:f.write(b)
assert json.loads(out.read_bytes())==value
print(json.dumps(dict(path=S+out.name,sha256=sha(b),bytes=len(b),targets=18,GD=7,JSON=11,maps=value['maps'])))
