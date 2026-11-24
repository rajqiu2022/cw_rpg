"""After authorized installation: append exactly three runtime PNG and one new RAW."""
from pathlib import Path
from collections import Counter
import json,hashlib,re,sys,copy
O=Path(__file__).resolve().parent;R=O.parents[2]
sys.path.insert(0,str(R/'scripts'))
import build_resource_gallery as gallery
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
plan=read(O/'formal_install_plan.json')
assert all(Path(r['target']).is_file() and sha(Path(r['target']))==r['after_sha256'] for r in plan['targets'])
assert sha(Path(plan['adapter_frozen']['path']))==plan['adapter_frozen']['sha256']
html=R/'docs/equipment-skill-catalog.html';cachefile=R/'docs/assets/resources/thumbnail-index.json'
oldhtml=html.read_bytes();oldcache=cachefile.read_bytes();text=oldhtml.decode('utf-8')
m=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
data=json.loads(m[1]);olddata=copy.deepcopy(data);cache=json.loads(oldcache);beforecache=copy.deepcopy(cache)
mapping=read(O/'source.batch02.candidate.json')['mappings'];facts=read(O/'preparation_receipt.json')
assets=[]
for source,row in mapping.items():
 f=next(f for f in facts if f['candidate_sha256']==row['atlas_sha256'])
 assets.append((R/'game'/row['atlas'][6:],source,row,f,False))
 if f['role']=='common_escort_idle':assets.append((Path(f['mother']),source,row,f,True))
assert len(assets)==4
existing={r['diskPath'] for r in data['resources']['records']};updates={};rows=[]
for p,source,row,f,raw in assets:
 key=p.relative_to(R).as_posix();assert key not in existing
 thumb,size=gallery.thumbnail(p,'npc',cache,updates)
 stage='内置原始来源' if raw else '正式动作贴图'
 uses=[{'label':'正式原生高清精确映射','url':'../game/art/characters/pc_hd_20261102c/source.json'}]
 rows.append({'id':hashlib.sha256(key.encode()).hexdigest()[:24],'name':f['role']+' · '+stage,'category':'npc','categoryLabel':'NPC与角色','group':'原生高清第二批20261106 / '+stage,'path':key if raw else row['atlas'],'diskPath':key,'url':gallery.href(p),'thumbnail':thumb,'media':'image','size':size,'bytes':p.stat().st_size,'format':'PNG','duration':None,'status':'referenced','statusLabel':stage,'usage':uses,'usageCount':1,'sceneIds':[],'note':'第二批书生1帧、共用黑衣护卫下向待机4帧/右向行走8帧；左向沿原镜像，非四向全动作。原生人体至少'+str(row['body_height'])+'px。只授权框外A1/透明补白/整数整帧对齐，RGB与保护RGBA精同；非低清放大。mipmap base精同，实际128world首帧视觉有限接受非逐场景ART。'+('本RAW只作派生来源，非运行贴图；调用1次，模型版本及成本未知。' if raw else ''),'sha256':sha(p),'sourcePath':Path(f['mother']).relative_to(R).as_posix(),'metadataPath':'game/build/npc_hd_20261106_batch02/preparation_receipt.json','formalSourceSprite':source,'animation':{'frames':row['framecount'],'source_hframes':row['source_hframes'],'source_vframes':row['source_vframes'],'independent_four_directions_created':False}})
res=data['resources'];res['records'].extend(rows)
for cat in res['categories']:cat['count']=sum(r['category']==cat['id'] for r in res['records'])
res['summary']={'total':len(res['records']),'images':sum(r['media']=='image' for r in res['records']),'audio':sum(r['media']=='audio' for r in res['records']),'states':dict(Counter(r['status'] for r in res['records']))}
assert res['records'][:-4]==olddata['resources']['records']
hits=list(re.finditer(r'"resources"\s*:\s*',m[1]));assert len(hits)==1
start=hits[0].end();value,end=json.JSONDecoder().raw_decode(m[1],start);assert value==olddata['resources']
newjson=m[1][:start]+json.dumps(res,ensure_ascii=False,separators=(',',':'))+m[1][end:]
assert json.loads(newjson)==data
cache.update(updates);assert all(cache[k]==v for k,v in beforecache.items())
assert html.read_bytes()==oldhtml and cachefile.read_bytes()==oldcache
for name,content in [('gallery_before.html',oldhtml),('gallery_cache_before.json',oldcache)]:
 p=O/name;assert not p.exists();p.write_bytes(content)
html.write_bytes((text[:m.start(1)]+newjson+text[m.end(1):]).encode('utf-8'))
cachefile.write_text(json.dumps(cache,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'gallery_records.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
(O/'gallery_receipt.json').write_text(json.dumps({'added':4,'before_total':len(olddata['resources']['records']),'after_total':len(res['records']),'old_records_exact':True,'html_outside_resources_exact':True,'old_cache_exact':True,'source_scan':False,'real_save_content_read':False},indent=2))
print(json.dumps({'added':4,'total':len(res['records']),'thumbnails':len(updates)}))
