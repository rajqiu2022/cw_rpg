"""Register original, padded and runtime assets with exact current consumers."""
from four_settlements_20261030e import *
import re
media=json.loads((STAGE/'media.json').read_text('utf-8'))
manifest=json.loads((RAW/'manifest.json').read_text('utf-8'))
scenes={p.stem:p for p in (ROOT/'game/scenes/drafts'/NAME).glob('*.tscn')}
consumers={}
for key,p in scenes.items():
 for path in re.findall(r'path="(res://[^"\n]+\.png)"',p.read_text('utf-8')):
  consumers.setdefault('game/'+path[6:],[]).append('res://'+p.relative_to(ROOT/'game').as_posix())
rows=[]
for r in manifest['assets']:
 if r['kind']!='component':continue
 r['status']='RAW_ADOPTED_WITH_RGBA0_PADDING'
 key=r['key'];output='game/'+media[key]['path']
 rows.append({'key':key,'label':r['label'],'kind':{'wood_pier':'码头栈台','willow':'岸边植被','ferry_boat':'渡船','repair_shed':'修船棚'}[key],
 'source':r['output'],'processed':media[key]['processed'],'output':output,'sha256':sha(ROOT/output),'scenes':consumers[output]})
designs=[{**r,'label':{'bailu_plan':'白鹿渡 · 柳岸渡口','donghai_plan':'东海埠 · 石岸货港','linxi_plan':'林西村 · 三片村落','zhuwei_plan':'竹尾村 · 竹林村街'}[r['key']]} for r in manifest['assets'] if r['kind']=='design']
save(RAW/'manifest.json',manifest)
pack={'batch':NAME,'assets':rows,'designs':designs,'reused_consumers':{k:v for k,v in consumers.items() if not k.startswith('game/'+ART+'/')},'scenes':{k:'res://'+p.relative_to(ROOT/'game').as_posix() for k,p in scenes.items()}}
save(ROOT/'game'/ART/'resource-pack.json',pack)
# Preserve the latest non-resource payload before changing the gallery.
catalog=ROOT/'docs/equipment-skill-catalog.html'
data=json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',catalog.read_text('utf-8'),re.S).group(1));data.pop('resources',None)
save(STAGE/'catalog-nonresources-before.json',data)
reg=ROOT/'game/build/three_towns_world_20261029j_system01/town_registry.gd';mp=reg.with_name('native_sources.json')
native=json.loads(mp.read_text('utf-8'));assert sha(mp) in reg.read_text('utf-8')
for p,digest in native['sources'].items():assert sha(ROOT/'game'/p[6:])==digest,p
md5=[]
for key in ['wood_pier','willow','ferry_boat','repair_shed']:
 for p in (PROJECT/'.godot/imported').glob(key+'.png-*.md5'):
  dst=ROOT/'game/.godot/imported'/p.name
  assert dst.exists() and sha(dst)==sha(p),p.name
  md5.append({'name':p.name,'sha256':sha(dst),'status':'already present, exact isolated bytes; preserved'})
save(STAGE/'followup.json',{'changed':['locations.json','linxi_center.tscn','linxi_center.json'],'md5':md5,'registry_sha':sha(reg),'manifest_sha':sha(mp),'note':'Initial followup completed source mutations, then stopped on existing md5 assertion. Existing identical import metadata verified without overwriting.'})
print('pack',len(rows),'designs',len(designs),'reused',len(pack['reused_consumers']))
