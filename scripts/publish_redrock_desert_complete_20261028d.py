"""Publish only the validated new namespace and exact private import leaves."""
import json
import re
import shutil
from pathlib import Path
from redrock_desert_complete_20261028d import ROOT,NAME,RAW,STAGE,PROJECT,ART,SCENE,SCRIPT
from build_redrock_desert_complete_20261028d import ROOM,HOME
from build_redrock_town_20261028a import save,sha

assert not (STAGE/'publication.json').exists()
for name in ['verification-residual.json','verification-edges.json','verification-delivery-captures.json']:
    proof=json.loads((PROJECT/'artifacts'/name).read_text('utf-8'));assert proof['passed']
layout=json.loads((STAGE/'layout.json').read_text('utf-8'))
assert len(layout['media'])==17
files=[]
for row in layout['media']:
    assert sha(ROOT/row['source'])==row['sha256']==sha(PROJECT/row['destination'])
    side=row['destination']+'.import';text=(PROJECT/side).read_text('utf-8')
    assert 'process/fix_alpha_border=false' in text and 'compress/mode=0' in text
    leaf=re.search(r'(?m)^path="res://([^"]+\.ctex)"',text)[1]
    files += [leaf,leaf[:-5]+'.md5',side]
# Existing dependencies are readonly and must still equal the actual verified copies.
shared=[f'scripts/drafts/redrock_luoyang_standard_20261028b/{name}.gd' for name in ['town_controller','preview_player']]+['scripts/field/player.gd','scenes/player.tscn']
shared += [r['destination'] for r in layout['base_media']]
for rel in shared:assert sha(ROOT/'game'/rel)==sha(PROJECT/rel),rel
files += [SCRIPT,SCRIPT+'.uid',str(Path(SCRIPT).with_name('ambient_actor.gd')).replace('\\','/'),str(Path(SCRIPT).with_name('ambient_actor.gd.uid')).replace('\\','/'),ART+'/ground.gdshader',ART+'/ground.gdshader.uid',ART+'/atlases.json']
files += [r['destination'] for r in layout['media']]+[ROOM,HOME,SCENE]
assert len(files)==len(set(files))
for rel in files:
    assert (PROJECT/rel).is_file(),rel
    assert not (ROOT/'game'/rel).exists(),rel
    if rel.endswith('.gd'):assert (PROJECT/rel).read_bytes().endswith(b'\n') and not (PROJECT/rel).read_bytes().endswith(b'\n\n'),rel
published=[]
for rel in files:
    dest=ROOT/'game'/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,dest)
    assert sha(dest)==sha(PROJECT/rel)
    published.append({'path':'game/'+rel,'sha256':sha(dest),'bytes':dest.stat().st_size})
assets=[]
for r in layout['media']:
    scene=HOME if r['key'] in ['bed','cloth_rack'] else SCENE
    assets.append({**r,'output':'game/'+r['destination'],'scene':'res://'+scene,'review_note':'六区与关外地图编辑装配；原生PNG保持，未授正式A1/世界业务准入。'})
pack={'status':'SIX_ZONES_AND_CANYON_APPROACH_EDITOR_MAP','scene':'res://'+SCENE,'validated_image_count':17,'resource_status_label':'六区与关外商路 · 已装配','assets':assets,'existing_dependencies':[{'path':'game/'+p,'sha256':sha(ROOT/'game'/p)} for p in shared],'source_pixels_changed':False,'formal_world_entry':False,'runtime_npc_native_frames':36,'worker_left_pose_runtime_mirror':True}
save(ROOT/'game'/ART/'resource-pack.json',pack)
save(STAGE/'publication.json',{'files':published,'new_files_including_pack':len(published)+1,'new_image_count':17,'new_import_leaves':51,'existing_dependencies_unchanged':len(shared),'scene':'game/'+SCENE,'production_import_invoked':False,'shared_router_written':False})
before=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changes=[]
for row in before:
    p=Path(row['path'])
    now={'sha256':sha(p),'bytes':p.stat().st_size,'mtime_ns':p.stat().st_mtime_ns} if p.exists() else None
    old={k:row[k] for k in ['sha256','bytes','mtime_ns']}
    if now!=old:changes.append({'path':str(p),'before':old,'after':now,'note':'protected source delta observed; no writer attribution inferred'})
save(STAGE/'protected-after.json',{'checked':len(before),'changes':changes,'new_namespace_only_publication':True,'all_unchanged':not changes})
html=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
save(STAGE/'catalog-before.json',json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',html,re.S)[1]))
raw=json.loads((RAW/'manifest.json').read_text('utf-8'));raw['status']='NATIVE_PRODUCED_EDITOR_MAP_ASSEMBLED_A1_CANDIDATE'
for r in raw['assets']:
    r['current_consumers']=['res://'+SCENE]
    r['runtime_use']='NPC native region atlas; worker left uses runtime flip' if r['key']=='worker_walk' else 'native map / portrait asset, original PNG unchanged'
save(RAW/'manifest.json',raw);save(RAW/'resource-pack.json',{'status':raw['status'],'assets':raw['assets']})
print(json.dumps({'published':len(published)+1,'new_images':17,'guard_checked':len(before),'observed_guard_deltas':len(changes)},ensure_ascii=False))
