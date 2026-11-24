"""Read-only PNG/manifest validation. No PNG edits or save-file access."""
import hashlib,json
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
raw=ROOT/'assets/raw/layered_actor_20261106'
lab=ROOT/'game/build/layered_actor_20261106_lab'
d=json.loads((raw/'directions_generation.json').read_text(encoding='utf-8'))
old=json.loads((raw/'generation.json').read_text(encoding='utf-8'))
report={'checks':0,'failures':[],'assets':[],'scope':'Original 7+new 8 source/runtime SHA; frame bounds inspection only; no saves or formal adoption.'}
def check(ok,label):
 report['checks']+=1
 if not ok: report['failures'].append(label)
for row in old['records']+d['records']:
 for kind in ('raw','runtime'):
  check(hashlib.sha256((ROOT/row[kind]).read_bytes()).hexdigest()==row['sha256'],row['key']+kind+' SHA')
for row in d['records']:
 with Image.open(ROOT/row['raw']) as im:
  check(im.mode=='RGBA' and im.size==(2048,768),row['key']+' native RGBA')
  check(im.getchannel('A').getextrema()[0]==0,row['key']+' transparent pixels')
  # Threshold is solely for inspection; original channels never saved/modified.
  a=im.getchannel('A')
  bounds=[]
  for i in range(4):
   box=a.crop((i*512,0,(i+1)*512,768)).point(lambda x:255 if x>=24 else 0).getbbox()
   bounds.append(box)
   check(box is not None,row['key']+str(i)+' nonempty')
   check(box is not None and box[0]>0 and box[2]<512 and box[1]>0 and box[3]<768,row['key']+str(i)+' clear cell boundary')
  report['assets'].append({'key':row['key'],'native':list(im.size),'alpha24_bounds':bounds})
manifest=json.loads((lab/'manifest.json').read_text(encoding='utf-8'))
check(all(x['texture'] in manifest['textures'] for x in manifest['clips'].values()),'all clip textures registered')
check(not any('v1' in key or 'grip_v2' in key for key in manifest['textures']),'rejected assets not consumed')
check(all(row['key'] not in manifest['textures'] for row in d['rejected']),'all three rejected sources absent')
before=json.loads((lab/'evidence/before_directions/manifest.json').read_text(encoding='utf-8'))
check(all(manifest['clips'][key]['frames']==before['clips'][key]['frames'] for key in ('idle','walk','attack')),'accepted original 12 poses unchanged')
check(manifest['weapons']==before['weapons'],'original weapon definitions unchanged')
for c in manifest['clips'].values():
 for p in c['frames']:
  check(p['anchor_semantics']=='thumb_index_web_below_guard','thumb web semantics')
report['result']='PASS' if not report['failures'] else 'FAIL'
(lab/'evidence/directions_asset_audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
