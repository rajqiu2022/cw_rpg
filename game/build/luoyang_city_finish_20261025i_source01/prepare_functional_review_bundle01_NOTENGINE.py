from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
names=['C_finish8_consumer02_direct_formal_whole_inverse_BUILD.json','Quarter_finish8_consumer02_direct_formal_whole_inverse_BUILD.json','Estate_finish8_consumer02_direct_formal_whole_inverse_BUILD.json','G_finish8_artisan_returns01_whole_inverse_BUILD.json','Temple_finish8_purpose_source01_whole_inverse_BUILD.json','ENV_finish8_purpose_source01_whole_inverse_BUILD.json']
rows=[]
for name in names:
    pb=(N/name).read_bytes();p=json.loads(pb)
    raw=(G/p['target'].removeprefix('res://')).read_bytes();assert sha(raw)==p['parent_sha256']
    cb=(G/p['candidate']['path'].removeprefix('res://')).read_bytes();assert sha(cb)==p['candidate']['sha256']
    text=raw.decode('utf-8')
    for h in p['hunks']:
        assert text.count(h['old'])==1;text=text.replace(h['old'],h['new'])
    assert text.encode('utf-8')==cb
    for h in reversed(p['hunks']):
        assert text.count(h['new'])==1;text=text.replace(h['new'],h['old'])
    assert text.encode('utf-8')==raw
    rows.append(dict(target=p['target'],old_sha256=sha(raw),old_bytes=len(raw),candidate=p['candidate'],proof=dict(path=NS+name,sha256=sha(pb),bytes=len(pb)),hunk_count=len(p['hunks']),whole_forward_inverse=True,formal_bytes_unchanged=True))
deps=[]
for rel in ['original_owner_receipts03_family_weak_snapshot_NOTREADY.gd','artisan_existing_rooms_return_projection01_NOTREADY.gd','city_purpose_surface04_explicit_repeat_NOTREADY.gd','city_purpose_surface04_explicit_repeat_NOTREADY.gdshader','eight_fields_purpose_surface04_explicit_repeat_NOTREADY.json']:
    b=(N/rel).read_bytes();deps.append(dict(path=NS+rel,sha256=sha(b),bytes=len(b)))
system=G/'build/luoyang_city_finish_20261025i_system01'
for rel in ['finish8_runtime_Field08_arrival_handoff_NOTREADY.json','finish8_runtime07_NOTREADY.gd','Field_finish8_ambient_toast08_CANDIDATE.gd','ambient18_Field05_handoff_NOTREADY.json']:
    b=(system/rel).read_bytes();deps.append(dict(path='res://build/luoyang_city_finish_20261025i_system01/'+rel,sha256=sha(b),bytes=len(b)))
value=dict(status='ROOT_FUNCTIONAL_REVIEW_BUNDLE_NOT_PARSE_NOT_STAGE_NOT_DEPLOYED',ready=False,rows=rows,dependencies=deps,
    exact_functional_target_count=6,Field_functional_owned_by_System=True,DT_functional_change=False,
    DT_noop_evidence='System Field08._district_position_safe and _interior_safe_position dispatch exact8 to new lease first; original DT.prepare/render/inverse remains untouched. Field payload projection occurs strictly after original post-DT navigation.',
    pending_finalization_only=['Root seven-mask isolate/import/promotion exact tuples','Root eight-field finite trial permission','System runtime binding/SELF/READY mechanical closure','System Field adapter03/READY-helper mechanical pins','C/Family/Temple/ENV helper READY path/SHA and enabled literal closure','ordinary AA/AC and source metadata/index exact dependency successors','Root single combined parse and Source-only Stage'],
    owned_membership_unchanged=10,old_proof_count_preserved=176,history_depth_unchanged=16,
    no_old_geometry_or_collector_replay=True,engine_calls=0,canonical_writes=0)
b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode('utf-8');p=N/'finish8_functional_consumers_review_bundle01_NOT_STAGE.json'
with p.open('xb') as f:f.write(b)
print(json.dumps(dict(path=NS+p.name,sha256=sha(b),bytes=len(b),targets=len(rows),hunks=sum(x['hunk_count'] for x in rows))))
