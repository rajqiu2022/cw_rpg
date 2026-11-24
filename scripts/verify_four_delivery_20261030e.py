"""Read-only final sources, gallery and protection evidence."""
from four_settlements_20261030e import *
import re
from urllib.parse import unquote
baseline=json.loads((STAGE/'protected-before.json').read_text('utf-8'));rows=[]
for r in baseline:
 p=Path(r['path']);now={'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} if p.exists() else None
 rows.append({'path':r['path'],'same':now is not None and all(now[k]==r[k] for k in now),'before':{k:r[k] for k in ['sha256','bytes','mtime_ns']},'after':now})
reg=ROOT/'game/build/three_towns_world_20261029j_system01/town_registry.gd';mp=reg.with_name('native_sources.json');j=json.loads(mp.read_text('utf-8'));assert sha(mp) in reg.read_text('utf-8')
for p,h in j['sources'].items():assert sha(ROOT/'game'/p[6:])==h,p
catalog=ROOT/'docs/equipment-skill-catalog.html';data=json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',catalog.read_text('utf-8'),re.S).group(1));resources=data.pop('resources')
assert data==json.loads((STAGE/'catalog-nonresources-before.json').read_text('utf-8'))
pack=json.loads((ROOT/'game'/ART/'resource-pack.json').read_text('utf-8'));expected=[r['output'] for r in pack['designs']]+[r[k] for r in pack['assets'] for k in ['source','processed','output']]
found=[]
for p in expected:
 candidates=[r for r in resources['records'] if str(r.get('path','')).replace('res://','game/')==p]
 assert len(candidates)==1,(p,len(candidates));r=candidates[0]
 # Local URLs are relative to docs/; allow explicit ../ and percent encoding.
 for k in ['url','thumbnail','thumb']:
  if k not in r:continue
  path=(catalog.parent/unquote(r[k])).resolve();assert path.is_file(),(k,path)
  with Image.open(path) as im:im.verify()
 found.append(r)
native=[]
for p in (ROOT/'game/scenes/drafts'/NAME).glob('*.tscn'):
 layout=json.loads((ROOT/'game'/ART/(p.stem+'.json')).read_text('utf-8'))
 oversized=[o for o in layout['objects'] if o.get('scale',1)>1.00001];assert not oversized,p
 native.append({'key':p.stem,'objects':len(layout['objects']),'sha256':sha(p),'enlarged':len(oversized)})
result={'protected':len(rows),'same':sum(r['same'] for r in rows),'differences':[r for r in rows if not r['same']],'saves':[r for r in rows if 'app_userdata' in r['path']],
 'native_sources':len(j['sources']),'registry_sha':sha(reg),'manifest_sha':sha(mp),'non_resources_exact':True,'gallery_records':resources['summary'],'new_paths':len(found),'layouts':native}
save(STAGE/'delivery-verification.json',result)
print(json.dumps({k:v for k,v in result.items() if k not in ['saves','differences']},ensure_ascii=False));print('differences',[(r['path'],r['before']['sha256'][:8],r['after']['sha256'][:8] if r['after'] else None) for r in result['differences']]);print('saves',len(result['saves']),'same',sum(r['same'] for r in result['saves']))
