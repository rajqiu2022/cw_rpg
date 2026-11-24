from pathlib import Path
import json,re,hashlib
G=Path(__file__).resolve().parents[2]
P=Path(__file__).resolve().parent
def sha(b):return hashlib.sha256(b).hexdigest()
raw=(P/'service_item_shop_sources_PROPOSAL_NOT_ADMITTED.json').read_bytes()
assert sha(raw)=='09c49a73ce87a04ebb242a3131505ec55b3ea4c4268deecfddd32e5c63a2ab65'
p=json.loads(raw)
s=json.loads((G/'build/luoyang_city_revision_20261025g_source01/outputs/root_market_courtyard45_exact32_stage02/receipt.json').read_bytes())
fixed=dict(s['source_first'])
for name in ['expected_ch4_s0_luoyang_gate_true','expected_ch4_s1_luoyang_yamen_true','expected_ch4_s2_canal_docks_true','expected_ch4_s3_luoyang_market_true']:
 for path,h in s['nodes'][name]['value']['source_sha256'].items():
  if not path.endswith(('.png','.png.import','.ctex')):continue
  if path in fixed: assert fixed[path]==h,path
  fixed[path]=h
pngs=sorted(x for x in p['bounded_dependency_observations'] if x.endswith('.png'))
rows=[]
for path in pngs:
 rawpath=G/path[6:]
 assert rawpath.is_file()
 assert sha(rawpath.read_bytes())==p['bounded_dependency_observations'][path]['sha256_observation']
 side=path+'.import';sb=(G/side[6:]).read_bytes()
 text=sb.decode('utf-8')
 remaps=re.findall(r'^path="(res://[^"\r\n]+\.ctex)"',text,re.M)
 assert len(remaps)==1,(side,remaps)
 dest=remaps[0];ctex=G/dest[6:];assert ctex.is_file(),dest
 leaves=[]
 for r,b in [(path,rawpath.read_bytes()),(side,sb),(dest,ctex.read_bytes())]:
  h=sha(b)
  if r in fixed:assert fixed[r]==h,r
  leaves.append({'path':r,'sha256_observation':h,'bytes':len(b),'exact_ticks':116444736000000000+(G/r[6:]).stat().st_mtime_ns//100,
   'fixed_25g_sha256':fixed.get(r),'inherited_fixed_value':r in fixed,'Root_new_ordinary_admission_required':r not in fixed})
 rows.append({'raw_png':path,'existing_tuple':leaves,'new_imports':0,'pixel_decodes':0})
value={'status':'EXISTING_SERVICE_PNG_IMPORT_REMAP_FACTS_PROPOSAL_NOT_ADMITTED',
 'proposal':{'path':'res://build/luoyang_city_revision_20261025h_source01/service_item_shop_sources_PROPOSAL_NOT_ADMITTED.json','sha256':sha(raw)},
 'raw_png_count':len(pngs),'source_leaf_count':sum(len(r['existing_tuple'])for r in rows),
 'new_ordinary_tuple_leaf_admission_count':sum(x['Root_new_ordinary_admission_required']for r in rows for x in r['existing_tuple']),
 'rows':rows,'imports':0,'pixel_decodes':0,'engine':0,'canonical_writes':0,
 'scope':'Only concrete raw PNG dependencies of the already Root-reviewed 09C49A bounded shop/stock report; inspect existing sidecars and sole exact ctex remaps, never run an importer or scan image directories. New observed leaves are NOT an admission until Root approval.'}
blob=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
dest=P/'service_existing_png_tuples_PROPOSAL_NOT_ADMITTED.json';assert not dest.exists()
with dest.open('xb')as f:f.write(blob)
print(json.dumps({'path':'res://'+dest.relative_to(G).as_posix(),'sha256':sha(blob),'raw_png_count':len(pngs),'tuple_leaf_count':value['source_leaf_count'],'new_unadmitted':value['new_ordinary_tuple_leaf_admission_count']}))
