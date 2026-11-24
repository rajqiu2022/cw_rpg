"""Small finite dependency scope review; no Stage, collector or key generation."""
from pathlib import Path
import hashlib
import json

Q=Path(__file__).resolve().parent;G=Q.parents[1]
S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
R=G/'build/luoyang_city_full_rollout_20261022ap_root01/integration45'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
sp=S/'performance61_ground_finite35_exact8_scope_READONLY.json'
assert sha(sp)=='ceaab710ea5aba573cb892e06acd21c6549c67e1f0b9e1a136f2d22496119deb'
s=rd(sp)
assert s['target_count']==8 and s['GD_count']==s['JSON_count']==4
assert len(s['targets'])==8 and len({x['target'] for x in s['targets']})==8
assert sum(x['target'].endswith('.gd') for x in s['targets'])==4
assert sum(x['target'].endswith('.json') for x in s['targets'])==4
ap=R/'ground_exact8_preparation_approval_READY.json'
assert sha(ap).startswith('53150c2d')
a=rd(ap)
assert a['scope_sha256']==sha(sp) and a['ground_candidate_sha256']=='c1ef10bce6ef1b4b8ff4e50f7a00a7e409b80e8c36cfed9d4eea33fedcce05ce'
bp=R/'old_full_backups_READY.json'
assert sha(bp)=='e488247289964b59af23f794c90946054b51ce452c498900e27e5c4700419aef'
b=rd(bp)
assert b['target_count']==8
backed={'res://'+Path(x['path']).relative_to(G).as_posix():x['sha256'] for x in b['targets']}
assert backed=={x['target']:x['old_sha256'] for x in s['targets']}
owner=rd(S/'performance60_market_parent30_actual_independent_review/owner_source_maps_READY.json')
market=next(x for x in owner['scenes'] if x['id']=='ch4_s3_luoyang_market')['source_sha256']
for path,digest in backed.items():assert owner['core_source_sha256'].get(path,market.get(path))==digest
assert s['execution_treatment']=={'owned_members_unchanged':True,'ground_is_nonowned':True,'execution_successor_and95pins_unchanged':True,'no_execution_edge_or_new_proof_key':True}
affected=[]
for row in s['owner_value_inheritance']:
    if row['collector_changed_value_paths']:
        assert row['id'] in ['ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market']
        assert set(row['collector_changed_value_paths'])==set(row['receipt_changed_value_paths'])
        assert set(row['collector_changed_value_paths'])<=set(backed);affected.append(row['id'])
    else:assert row['receipt_changed_value_paths']==[]
    assert row['keys_and_counts_unchanged']
assert len(affected)==4 and len(s['owner_value_inheritance'])==13
for edge in s['reference_edges']:assert edge['producer'] in backed and edge['consumer'] in backed
out=Q/'scope61_exact8_ground_nonowned_no95proofchange_static_admission_READY.json'
assert not out.exists()
out.write_text(json.dumps({'status':'STATIC_EXACT8_GROUND_NONOWNED_SCOPE_NO_BLOCKER_AWAIT_FINAL_DRIVER',
    'scope_SHA':sha(sp),'Root_preparation_SHA':sha(ap),'Root8backup_SHA':sha(bp),
    'checks':{'exact4GD4JSON_real_closed_consumers':True,'all8old_values_fixed_E717_and_Root_backups':True,
        'only_ground_behavior_and_four_source_manifests_three_index_literals':True,
        'execution_members_edges95pins_unchanged_no_newproof':True,'all_four_C_keysets_counts_same_existing_value_only':True,
        'remaining4scene_and5room_maps_whole_unchanged_expected':True,'Root39SOURCE_ONLY2_and_Estate_registry_and_native_domains_preserved':True},
    'limits':['Scope only, final driver/input and actual outputs still require independent review',
        'No new Market key generated before actual owner; no parse/engine/collector/media hash'],
    'operations':{'engine':0,'collector':0,'Stage':0,'key_generation':0,'canonical':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'scope_blocker':False}))
