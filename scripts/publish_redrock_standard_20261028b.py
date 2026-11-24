"""Publish only the new Redrock namespace, and capture a truthful protection delta."""
import json
import re
import shutil
from pathlib import Path

from redrock_luoyang_standard_20261028b import ROOT,RAW,STAGE,PROJECT,ART,SCENE,SCRIPT,save,sha
from build_redrock_standard_20261028b import ROOM

assert not (STAGE/'publication.json').exists()
proof=json.loads((PROJECT/'artifacts/verification.json').read_text('utf-8'))
last=json.loads((PROJECT/'artifacts/verification-final.json').read_text('utf-8'))
assert proof['passed'] and len(proof['checks'])==79 and last['passed']
layout=json.loads((STAGE/'layout.json').read_text('utf-8'));files=[]
for row in layout['media']:
    assert sha(ROOT/row['source'])==row['sha256']==sha(PROJECT/row['destination'])
    side=row['destination']+'.import';text=(PROJECT/side).read_text('utf-8')
    assert 'process/fix_alpha_border=false' in text and 'compress/mode=0' in text
    ctex=re.search(r'(?m)^path="res://([^"]+\.ctex)"',text)[1]
    files += [ctex,ctex[:-5]+'.md5',side]
files += [SCRIPT,SCRIPT+'.uid',ART+'/ground.gdshader',ART+'/ground.gdshader.uid']+[r['destination'] for r in layout['media']]+[ROOM,SCENE]
for rel in files:assert (PROJECT/rel).is_file() and not (ROOT/'game'/rel).exists(),rel
published=[]
for rel in files:
    target=ROOT/'game'/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,target)
    assert sha(target)==sha(PROJECT/rel)
    published.append({'path':'game/'+rel,'sha256':sha(target),'bytes':target.stat().st_size})
old=json.loads((ROOT/'game/art/modules/redrock_town_20261028a/resource-pack.json').read_text('utf-8'))
lookup={r['key']:r for r in old['assets']}
lookup.update({r['key']:r for r in json.loads((RAW/'resource-pack.json').read_text('utf-8'))['assets']})
for key,label in {'counter':'驿舍木柜台','table':'前厅木桌','bench':'前厅长凳','shelf':'前厅酒茶架'}.items():lookup[key]={'label':label,'kind':'scene_prop'}
assets=[]
for r in layout['media']:
    item=lookup[r['key']]
    assets.append({**r,'output':'game/'+r['destination'],'kind':item['kind'],'label':item['label'],'scene':'res://'+(ROOM if r['key'] in ('inn_room','keeper_sprite','counter','table','bench','shelf') else SCENE),'review_note':'生活街段/独立前厅编辑草案；原PNG字节同，A1候选限制不变。'})
save(ROOT/'game'/ART/'resource-pack.json',{'status':'LIFE_STREET_AND_CACHED_INN_EDITOR_DRAFT','scene':'res://'+SCENE,'validated_image_count':28,'resource_status_label':'生活街段与前厅 · 编辑草案','assets':assets})
save(STAGE/'publication.json',{'files':published,'new_files_including_pack':len(published)+1,'scene':'game/'+SCENE,'room_scene':'game/'+ROOM,'image_count':28,'new_import_leaves':84,'production_import_invoked':False,'shared_router_modified':False,'native_region_views_only_no_raster_crop':True})
before=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changes=[]
for r in before:
    p=Path(r['path'])
    if not p.is_file() or sha(p)!=r['sha256'] or p.stat().st_size!=r['bytes'] or p.stat().st_mtime_ns!=r['mtime_ns']:
        changes.append({'before':r,'after':{'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} if p.is_file() else None})
save(STAGE/'protected-after.json',{'checked':len(before),'changes':changes,'all_equal':not changes,'save_files_checked':sum('app_userdata' in r['path'] for r in before),'interpretation':'只写新增赤岩命名空间，外部共享变化如实保留，不回退。'})
html=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
save(STAGE/'catalog-before.json',json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',html,re.S)[1]))
print(json.dumps({'published_files':len(published)+1,'protected_checked':len(before),'changed':len(changes),'scene':'game/'+SCENE},ensure_ascii=False))
