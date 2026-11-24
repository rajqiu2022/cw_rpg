"""Pure frozen-data proof of unavoidable B.manifest legacy-root refusal."""
import copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
raw=(H/'outputs/root_finite09_two_domain_stage02/receipt.json').read_bytes()
assert sha(raw)=='885a813db26487582bc7cb31d02ec89827dc929a9e2653e71137defd8ff8c3a0'
stage=json.loads(raw);node=stage['nodes']['finite08_yamen']
assert node['sha256']=='f00d25e6037d1a706e53bf7c54cc846cb5bb81a72f552e1ef0a6b231c7f6b8d8'
root='res://data/maps/luoyang_layout_bundle_20261018t_retry2/'
old=node['value'];bad={p:s for p,s in old['legacy_source_sha256'].items() if p.startswith(root)}
assert set(bad)=={root+'ch4_s1_luoyang_yamen/'+n for n in ['scene.res','layout.res','packet.bin','manifest.json']}
b=(G/'scripts/city/luoyang_precomputed_bundle_20261018r.gd').read_bytes()
assert sha(b)=='84d230215701757a5e52f6afadc9156df206e87375cbf71534248839366f19bc'
assert b' or path.begins_with(ROOT): return {}' in b
assert b'path.begins_with(ROOM_ROOT) or path.begins_with(ROOT)' in b
proposed=copy.deepcopy(old)
for p,s in bad.items():
 assert p not in proposed['runtime_authority_sha256']
 del proposed['legacy_source_sha256'][p];proposed['runtime_authority_sha256'][p]=s
def union(v):
 out={}
 for field in ['legacy_source_sha256','runtime_authority_sha256','artifacts']:
  for p,s in v[field].items():assert p not in out;out[p]=s
 return out
assert union(old)==union(proposed) and len(union(old))==1203
inverse=copy.deepcopy(proposed)
for p,s in bad.items():del inverse['runtime_authority_sha256'][p];inverse['legacy_source_sha256'][p]=s
assert inverse==old
out={'status':'DETERMINISTIC_SOURCE_CLASS_GATE_REFUSAL_NOT_RUNTIME_DIAGNOSIS_RUN',
 'actual_failed_run':'qa01/yamen_three_low_props_metrics/14912_2691/result.json',
 'formal_B_sha256':sha(b),'frozen_stage_receipt_sha256':sha(raw),'finite_Yamen_manifest_sha256':node['sha256'],
 'cause':'B.manifest rejects every legacy path beginning T_ROOT. Frozen finite Yamen has exactly four such paths, introduced by finite_manifest old-artifact retention and old-parent-header insertion.',
 'four_wrongly_legacy_declared_leaves':bad,
 'source_control_chain':['B.manifest legacy T_ROOT gate returns {}','B.source_paths returns {} when formally requested manifest is empty','C._transition_sources first bundle gate returns {}','C._live_source_hashes returns empty','C reports Live complete source identity unavailable before native packet worker/Field'],
 'smallest_proposed_repair':'Move only these four declarations with original SHA from legacy_source_sha256 to runtime_authority_sha256; retain fixed formal path after explicit Root scope/backup, update only AP_INDEX Yamen manifest hash.',
 'source_union_before_after_exact':True,'source_union_count':1203,'final_city_expected1211_keys_values_unchanged_except_manifest_and_external_index_headers':True,
 'whole_typed_inverse_by_four_moves':True,'geometry_author_artifacts_layoutproof_mask_and_all_other_fields_unchanged':True,
 'candidate_written':False,'canonical_writes':0,'stage_calls':0,'engine_calls':0,'collector_calls':0}
p=H/'finite09_stage02_independent_review/yamen_legacy_class_diagnosis_READY.json';assert not p.exists()
data=(json.dumps(out,ensure_ascii=False,indent=2)+'\n').encode()
with p.open('xb') as f:f.write(data)
print(json.dumps({'diagnosis_sha256':sha(data),'wrong_class_leaf_count':4,'same_union_count':1203,'candidate_written':False,'engine_calls':0}))
