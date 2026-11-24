"""Resource registration and bounded, read-only publication checks."""
import re,subprocess
from urllib.parse import unquote
from sect_completion_20261030a import *

def catalog():
 s=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
 return json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',s,re.S)[1])

if sys.argv[1]=='pack':
 p=ROOT/'game'/ART/'resource-pack.json';assert not p.exists()
 source=json.loads((RAW/'manifest.json').read_text('utf-8'))
 pad={r['key']:r for r in json.loads((STAGE/'padding-verification.json').read_text('utf-8'))}
 layouts={key:json.loads((ROOT/'game'/ART/(key+'.json')).read_text('utf-8')) for key in ['lingyue','lieyun','mingwu']}
 rows=[];reused={}
 for r in source['assets']:
  key=r['key'];uses=['res://scenes/drafts/'+NAME+'/'+k+'.tscn' for k,v in layouts.items() if any(o.get('key')==key for o in v['objects'])]
  assert uses,key
  out='game/'+ART+'/'+key+'.png'
  rows.append({'key':key,'label':r['label'],'kind':'scene_prop' if key=='staff_rack' else 'building','sect':r['sect'],'source':r['output'],'processed':'assets/processed/'+NAME+'/'+key+'.png','output':out,'sha256':sha(ROOT/out),'scenes':uses,'padding':pad[key]['offset'],'original_RGBA_preserved':True,'alpha_cleaned_pixels':0})
 for key in layouts:
  scene='res://scenes/drafts/'+NAME+'/'+key+'.tscn';s=(ROOT/'game'/scene[6:]).read_text('utf-8')
  body=re.sub(r'^\[ext_resource[^\n]*\n','',s,flags=re.M)
  for path,id in re.findall(r'\[ext_resource type="Texture2D" path="res://([^"]+)" id="([^"]+)"\]',s):
   if 'ExtResource("'+id+'")' in body and NAME not in path:
    reused.setdefault('game/'+path,[]).append(scene)
 save(p,{'status':'FORMAL_OUTDOOR_ENTRIES_CONNECTED','assets':rows,'reused_consumers':reused,'original_interiors_retained':True,'notes':'docs/changes/town-layout-and-sect-entries-20261030a.md'})
 print('Registered',len(rows),'new components and',len(reused),'actual reused textures')
elif sys.argv[1]=='catalog':
 old=catalog();non={k:v for k,v in old.items() if k!='resources'}
 save(STAGE/'catalog-before-summary.json',{'nonresources_sha256':hashlib.sha256(json.dumps(non,sort_keys=True,ensure_ascii=False).encode()).hexdigest(),'summary':old['resources']['summary']})
 for script,args in [('build_arsenal_catalog.py',['--sync-resources-only']),('build_resource_reuse_index.py',[])]:
  p=subprocess.run([sys.executable,str(ROOT/'scripts'/script)]+args,capture_output=True,encoding='utf-8')
  (STAGE/(script+'.stdout.txt')).write_text(p.stdout,'utf-8');(STAGE/(script+'.stderr.txt')).write_text(p.stderr,'utf-8');assert p.returncode==0,p.stderr
 new=catalog();assert {k:v for k,v in new.items() if k!='resources'}==non
 rows=[r for r in new['resources']['records'] if NAME in r['diskPath']];assert len(rows)==21,len(rows)
 for r in rows:
  assert r['usageCount']>=1
  for field in ['url','thumbnail']:
   p=(ROOT/'docs'/unquote(r[field])).resolve();assert p.is_file(),p
   with Image.open(p) as im:im.verify()
 save(STAGE/'catalog-after.json',{'nonresources_unchanged':True,'summary':new['resources']['summary'],'new_paths':len(rows),'images_and_thumbnails_verified':len(rows)*2,'rows':rows})
 print(json.dumps(new['resources']['summary'],ensure_ascii=False))
elif sys.argv[1]=='guard':
 facts=json.loads((STAGE/'protected-before-publication.json').read_text('utf-8'));changes=[];saved=0
 for r in facts:
  p=Path(r['path'])
  if p.name in ['town_registry.gd','native_sources.json']:continue
  now={'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns}
  if now!=r:changes.append({'before':r,'after':now})
  if 'save' in str(p).lower():saved+=1
 base=ROOT/'game/build/three_towns_world_20261029j_system01';m=base/'native_sources.json';j=json.loads(m.read_text('utf-8'))
 for path,digest in j['sources'].items():assert sha(ROOT/'game'/path[6:])==digest,path
 assert sha(m) in (base/'town_registry.gd').read_text('utf-8')
 evidence={}
 for label in ['formal06','sects04','sects05','sects06']:
  p=ROOT/'game/build/town_layout_20261029r_qa'/(label+'.json');v=json.loads(p.read_text('utf-8'));assert v['ok'];evidence[label]={'checks':len(v['checks']),'sha256':sha(p)}
 save(STAGE/'final-verification.json',{'status':'PUBLISHED_AND_SCOPED_RUNTIME_VERIFIED','protected_objects':len(facts)-2,'save_paths':saved,'protected_changes':changes,'native_sources_valid':True,'native_sources':len(j['sources']),'formal_evidence':evidence,'shutdown_warnings':'Existing Texture/RenderingServer shutdown errors remain; natural exit 0 is not clean stderr.','hashes':{str(p.relative_to(ROOT)):sha(p) for p in [base/'town_registry.gd',m,ROOT/'game/build/sect_completion_20261030a_system01/sect_field.gd',base/'town_field.gd']}})
 print(json.dumps({'protected':len(facts)-2,'saves':saved,'changes':changes,'native_sources':len(j['sources'])},ensure_ascii=False));assert not changes
