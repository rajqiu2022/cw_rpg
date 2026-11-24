from pathlib import Path
import json,re,hashlib
P=Path(__file__).resolve().parent;G=P.parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
ap=G/'build/luoyang_indoor_services_20261025h_system01/services_author03_CANDIDATE.json'
ab=ap.read_bytes();assert sha(ab)=='d98f360f141b1596f4d62be36ff50e54cca7dfef972735017bd3ee9b5f8fab92'
a=json.loads(ab)
raw_paths=sorted(set(re.findall(r'"(?:sprite_path|portrait_path)":\s*"(res://[^"\r\n]+\.png)"',ab.decode())))
assert len(raw_paths)==8
s=json.loads((G/'build/luoyang_city_revision_20261025g_source01/outputs/root_market_courtyard45_exact32_stage02/receipt.json').read_bytes())
fixed=dict(s['source_first'])
for name in ['expected_ch4_s0_luoyang_gate_true','expected_ch4_s1_luoyang_yamen_true','expected_ch4_s2_canal_docks_true','expected_ch4_s3_luoyang_market_true']:
 for path,h in s['nodes'][name]['value']['source_sha256'].items():
  if path.endswith(('.png','.png.import','.ctex')):
   if path in fixed:assert fixed[path]==h,path
   fixed[path]=h
rows=[]
for raw in raw_paths:
 side=raw+'.import';text=(G/side[6:]).read_text(encoding='utf-8')
 remaps=re.findall(r'^path="(res://[^"\r\n]+\.ctex)"',text,re.M)
 assert len(remaps)==1
 leaves=[]
 for path in [raw,side,remaps[0]]:
  p=G/path[6:];b=p.read_bytes();h=sha(b)
  if path in fixed:assert fixed[path]==h,path
  leaves.append({'path':path,'sha256_observation':h,'bytes':len(b),'fixed_25g_sha256':fixed.get(path),'inherited_fixed_value':path in fixed,'Root_new_ordinary_admission_required':path not in fixed})
 rows.append({'raw_png':raw,'existing_tuple':leaves,'obsolete_inn_portrait_not_final_source':raw=='res://art/characters/npc_vendor_neutral.png'})
value={'status':'SOURCE_FIXED_EXISTING_ACTOR_TUPLES_READONLY_PROPOSAL_NOT_ADMISSION',
 'author':{'path':'res://'+ap.relative_to(G).as_posix(),'sha256':sha(ab)},'rows':rows,
 'new_unadmitted_leaves':[x for row in rows if not row['obsolete_inn_portrait_not_final_source']for x in row['existing_tuple']if x['Root_new_ordinary_admission_required']],
 'scope':'Eight currently author03 referenced actor PNG groups. Old inn vendor portrait explicitly obsolete/pending Root new portrait: never freeze it as final. Seven remaining groups inherit exact fixed 25g media when present; absent tuple leaves are observations needing Root approval.',
 'engine':0,'imports':0,'pixel_decodes':0,'canonical_writes':0}
blob=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
dest=P/'service_actor_existing_tuples_PROPOSAL_NOT_ADMITTED.json';assert not dest.exists()
with dest.open('xb')as f:f.write(blob)
print(json.dumps({'path':'res://'+dest.relative_to(G).as_posix(),'sha256':sha(blob),'groups':len(rows),'new_unadmitted_nonobsolete_leaf_count':len(value['new_unadmitted_leaves'])}))
