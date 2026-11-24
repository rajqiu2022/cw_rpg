"""Exact pure reconstruction of B.describe's declared expected table, no collector."""
from pathlib import Path
import json,hashlib,re
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
p=GAME/'build/luoyang_city_revision_20261024e_source01/outputs/root_market_blocks_prewarm_exact33_stage03/receipt.json';raw=p.read_bytes();assert hashlib.sha256(raw).hexdigest()=='ea657a57c4a884cd3f645b6de7f8fb2010c8920b737b2ab6b9f3c998288c2abc';s=json.loads(raw)
v=s['nodes']['finite08_market']['value'];m=s['nodes']['expected_ch4_s3_luoyang_market_true']['value']['source_sha256'];expected={}
for k in ['legacy_source_sha256','runtime_authority_sha256','artifacts']:expected.update(v[k])
b=(GAME/'scripts/city/luoyang_precomputed_bundle_20261018r.gd').read_bytes().decode();assert hashlib.sha256(b.encode()).hexdigest()=='07a9711a108e089df31c1d93144b9af0e39b107c6a7d996163ab32b840c12120'
constants=dict(re.findall(r'^const ([A-Z_]+)\s*=\s*"([^"]+)"',b,re.M))
for n in ['INDEX','ESTATE_INDEX','AO_INDEX','AP_INDEX','AP_ENV_INDEX','AP_EXEC_INDEX','AP_QUARTER_INDEX','MG_INDEX']:expected[constants[n]]=m[constants[n]]
target='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/runtime_market_manifest_READY.json';expected[target]=s['nodes']['finite08_market']['sha256']
only_map={p:m[p] for p in sorted(m.keys()-expected.keys())};only_b={p:expected[p] for p in sorted(expected.keys()-m.keys())};diff={p:dict(B=expected[p],declared_map=m[p]) for p in sorted(expected.keys()&m.keys()) if expected[p]!=m[p]}
report=dict(status='READONLY_B_DESCRIBE_FORMULA_VS_FIXED_STAGE_MAP_NOT_RUNTIME_CAPTURE',B_expected_count=len(expected),map_count=len(m),only_map=only_map,only_B=only_b,different_values=diff,source_formula='B.describe finite config union legacy/runtime/artifacts + eight exact fixed index declared leaves + finite manifest header; compare independent Stage map. No FileAccess SHA/current collector execution.',engine_calls=0,collector_calls=0,canonical_writes=0)
out=HERE/'B_describe_static_delta_READONLY.json';assert not out.exists();r=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f:f.write(r)
print(json.dumps(dict(path=out.as_posix(),sha256=hashlib.sha256(r).hexdigest(),**report)))
