"""31b read-only original Scene/terrain/PNG alpha diagnosis. No engine/art edits."""
from pathlib import Path
from PIL import Image
import hashlib,json,math,re
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
SCENE=GAME/'scenes/drafts/miao_terrain_20261029i/miao_town.tscn'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(SCENE)=='cd88d0003066eb42a0dcec5d20404e4bad6313456b383584386ef3f1eda9d756'
text=SCENE.read_text(encoding='utf-8-sig');nodes={}
def pair(raw,key,default):
 m=re.search(r'^'+re.escape(key)+r' = Vector2\(([^,]+), ([^)]+)\)',raw,re.M)
 return [float(m[1]),float(m[2])] if m else default
def scalar(raw,key,default=0):
 m=re.search(r'^'+re.escape(key)+r' = ([^\n]+)',raw,re.M)
 return float(m[1]) if m else default
for m in re.finditer(r'^\[node name="([^"]+)"[^\n]*\]\n(.*?)(?=^\[node |\Z)',text,re.M|re.S):
 head=m[0].split('\n',1)[0];p=re.search(r'parent="([^"]+)"',head)
 parent=p[1] if p else '';path=(parent+'/' if parent not in ['', '.'] else '')+m[1]
 pos=pair(m[2],'position',[0,0])
 if parent not in ['', '.']:
  root=nodes[parent]['position'];pos=[pos[0]+root[0],pos[1]+root[1]]
 nodes[path]={'path':path,'name':m[1],'head':head,'raw':m[2],'position':pos,'parent':parent,'z':scalar(m[2],'z_index')}
resources={m[2]:m[1] for m in re.finditer(r'\[ext_resource type="Texture2D" path="([^"]+)" id="([^"]+)"\]',text)}
images={}
def sprite(path,rootz=None):
 node=nodes[path];raw=node['raw'];tex=re.search(r'texture = ExtResource\("([^"]+)"\)',raw)[1];uri=resources[tex]
 if uri not in images:images[uri]=Image.open(GAME/uri[6:]).convert('RGBA')
 image=images[uri];alpha=image.getchannel('A');bbox=alpha.point(lambda a:255 if a>=8 else 0).getbbox()
 scale=pair(raw,'scale',[1,1]);offset=pair(raw,'offset',[0,0]);origin=[node['position'][i]+offset[i]*scale[i] for i in [0,1]]
 return {'path':path,'texture':uri,'position':node['position'],'scale':scale,'offset':offset,'origin':origin,'bbox':[origin[0]+bbox[0]*scale[0],origin[1]+bbox[1]*scale[1],origin[0]+bbox[2]*scale[0],origin[1]+bbox[3]*scale[1]],'z':node['z'] if rootz is None else rootz,'source_alpha_bbox8':list(bbox),'size':list(image.size),'_alpha':alpha}
def overlap(a,b,step=4):
 r=[max(a['bbox'][0],b['bbox'][0]),max(a['bbox'][1],b['bbox'][1]),min(a['bbox'][2],b['bbox'][2]),min(a['bbox'][3],b['bbox'][3])]
 if r[0]>=r[2] or r[1]>=r[3]:return None
 count=0
 for y in range(math.ceil(r[1]),math.floor(r[3])+1,step):
  for x in range(math.ceil(r[0]),math.floor(r[2])+1,step):
   pixels=[]
   for row in [a,b]:pixels.append((math.floor((x-row['origin'][0])/row['scale'][0]),math.floor((y-row['origin'][1])/row['scale'][1])))
   if all(0<=p[0]<row['size'][0] and 0<=p[1]<row['size'][1] and row['_alpha'].getpixel(p)>=8 for row,p in zip([a,b],pixels)):count+=1
 return {'bbox':r,'alpha8_samples_step4':count,'estimated_overlap_px2':count*step*step} if count else None
def clean(row):return {k:v for k,v in row.items() if not k.startswith('_')}
terrain=json.loads((GAME/'art/modules/miao_terrain_20261029i/terrain.json').read_text(encoding='utf-8-sig'))
banks=[sprite(path) for path in nodes if re.fullmatch(r'Terrain/NativeBank\d+',path)]
result=[]
for number in [1,2,3,4]:
 root=nodes[f'Town/Paddy{number}'];art=sprite(root['path']+'/Art',root['z'])
 body=nodes[root['path']+'/Body/Outline'];poly=re.search(r'polygon = PackedVector2Array\(([^)]+)\)',body['raw'])[1]
 values=[float(v) for v in poly.split(',')];physical=[[values[i]+body['position'][0],values[i+1]+body['position'][1]] for i in range(0,len(values),2)]
 hits=[]
 for bank in banks:
  value=overlap(art,bank)
  if value:hits.append({'bank':bank['path'],'position':bank['position'],'z':bank['z'],'renders_in_front_of_paddy':bank['z']>art['z'],**value})
 hits.sort(key=lambda r:-r['estimated_overlap_px2'])
 result.append({'name':root['name'],'physical_ground_foot':root['position'],'level':scalar(root['raw'],'metadata/terrain_level'),'elevation':scalar(root['raw'],'metadata/elevation'),'projected_foot':[root['position'][0],root['position'][1]-scalar(root['raw'],'metadata/elevation')],'art':clean(art),'body_world_polygon':physical,'body_layer':scalar(nodes[root['path']+'/Body']['raw'],'collision_layer',1),'native_bank_intersections':hits})
out={'status':'STATIC_ALPHA_AND_AUTHORED_GEOMETRY_NOT_ENGINE','Scene_sha256':sha(SCENE),'paddies':result,'terrain':terrain,'native_banks':[{k:v for k,v in clean(b).items() if k in ['path','position','scale','bbox','z']} for b in banks],'PNG_writes':0,'engine_runs':0,'save_access':False}
data=(json.dumps(out,ensure_ascii=False,indent=2)+'\n').encode();path=HERE/'diagnosis_STATIC_READY.json';assert not path.exists()
with path.open('xb') as f:f.write(data)
print(json.dumps({'sha256':sha(path),'bytes':len(data),'paddies':[{'name':r['name'],'foot':r['physical_ground_foot'],'art_bbox':r['art']['bbox'],'front_bank_intersections':[v for v in r['native_bank_intersections'] if v['renders_in_front_of_paddy']]} for r in result]},ensure_ascii=False))
