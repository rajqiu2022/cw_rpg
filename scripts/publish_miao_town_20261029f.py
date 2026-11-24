"""Publish the validated new Miao city namespace, preserving shared sources and saves."""
import json
import re
import shutil
from pathlib import Path
from PIL import Image
from miao_town_20261029f import ROOT, RAW, STAGE, PROJECT, ART, SCENE, SCRIPT, NAME
from build_redrock_town_20261028a import save, sha

assert not (STAGE/'publication.json').exists()
for file,count,failed in [('verification-city.json',85,1),('verification-refined.json',52,0),('verification-final-prop.json',7,0)]:
    r=json.loads((PROJECT/'artifacts'/file).read_text('utf-8'));assert (r['count'],r['failed'])==(count,failed)
for stem in ['refined','final-prop','import-lusheng']:
    assert (STAGE/(stem+'.stderr.log')).stat().st_size==0
protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changed=[]
for r in protected:
    p=Path(r['path'])
    if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changed.append(r['path'])
save(STAGE/'protected-before-publication.json',{'count':len(protected),'changed':changed,'exact_SHA_bytes_mtime':not changed});assert not changed,changed
layout=json.loads((STAGE/'layout.json').read_text('utf-8'));assert len(layout['media'])==26
padding=json.loads((STAGE/'padding-verification.json').read_text('utf-8'));assert len(padding['rows'])==23
for r in padding['rows']:
    src=Image.open(ROOT/r['source']);out=Image.open(ROOT/r['output']);x,y=r['offset'];w,h=src.size
    assert src.mode==out.mode=='RGBA' and out.crop((x,y,x+w,y+h)).tobytes()==src.tobytes()
    canvas=Image.new('RGBA',out.size,(0,0,0,0));canvas.paste(src,(x,y));assert canvas.tobytes()==out.tobytes()
pack=[]
for key,r in layout['media'].items():
    assert sha(ROOT/r['output'])==r['sha256'] and sha(PROJECT/r['destination'])==r['processed_sha256']
    assert sha(ROOT/r['processed'])==r['processed_sha256'] and r['calls']==1
    pack.append({'key':key,'kind':r['kind'],'label':r['label'],'source':r['processed'],'parent_source':r['output'],'destination':r['destination'],
        'output':'game/'+r['destination'],'sha256':r['processed_sha256'],'scene':'res://'+SCENE,
        'review_note':'苗风山城独立六区编辑地图；原PNG保持，23透明图仅补RGBA0，原A1失败保留。四向待机、侧行四相/左向运行镜像；未采用原稿上下行走。'})
save(PROJECT/ART/'resource-pack.json',{'status':'MIAO_CITY_EDITOR_MAP','scene':'res://'+SCENE,'validated_image_count':26,'formal_world_enabled':False,
    'assets':pack,'reused_existing_art':layout['reused_art'],'animation_contract':{'identities':2,'live_patrols':8,'idle_directions':4,
    'accepted_walk':'native four-phase right side; LEFT runtime mirror','original_vertical_walk_adopted':False}})
pending=[SCENE,SCRIPT,'scripts/drafts/'+NAME+'/resident.gd'];seen=set();reuse=[]
while pending:
    rel=pending.pop()
    if rel in seen:continue
    seen.add(rel);p=PROJECT/rel;assert p.is_file(),rel
    if not rel.startswith((ART+'/',f'scripts/drafts/{NAME}/',f'scenes/drafts/{NAME}/')):
        target=ROOT/'game'/rel;assert target.is_file() and sha(target)==sha(p),'Existing dependency differs: '+rel
        reuse.append({'path':rel,'sha256':sha(p)})
    if p.suffix in ['.gd','.tscn','.gdshader','.json']:
        for path in re.findall(r'res://[^"\s<>\\]+',p.read_text('utf-8')):
            child=path[6:]
            if (PROJECT/child).is_file():pending.append(child)
for rel in layout['reused_art']:assert sha(PROJECT/rel)==sha(ROOT/'game'/rel),rel
for p in (PROJECT/'art/characters/weapon_variants/lengguyun/v7_idle_stable/sword').glob('*.png'):
    rel=p.relative_to(PROJECT).as_posix();assert sha(p)==sha(ROOT/'game'/rel);reuse.append({'path':rel,'sha256':sha(p)})
save(STAGE/'existing-dependencies-exact.json',{'files':reuse,'reused_art':layout['reused_art'],'all_existing_exact':True})
rels=[SCENE]
for p in (PROJECT/f'scripts/drafts/{NAME}').iterdir():
    if p.is_file():rels.append(p.relative_to(PROJECT).as_posix())
imports=set()
for p in (PROJECT/ART).iterdir():
    if not p.is_file():continue
    rels.append(p.relative_to(PROJECT).as_posix())
    if p.suffix=='.import':imports.update(re.findall(r'res://(\.godot/imported/[^"\s]+)',p.read_text('utf-8')))
for rel in sorted(imports):rels.extend([rel,Path(rel).with_suffix('.md5').as_posix()])
assert len(imports)==26 and len(rels)==len(set(rels))
for rel in rels:assert (PROJECT/rel).is_file() and not (ROOT/'game'/rel).exists(),rel
for rel in rels:
    target=ROOT/'game'/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,target)
save(STAGE/'publication.json',{'files':[{'path':'game/'+rel,'sha256':sha(ROOT/'game'/rel),'bytes':(ROOT/'game'/rel).stat().st_size} for rel in rels],
    'new_files':len(rels),'changed_existing_game_files':[],'import_leaves':len(imports)*2,'protected_count':len(protected),
    'protected_SHA_bytes_mtime_exact':True,'production_import_invoked':False,'scene_sha256':sha(ROOT/'game'/SCENE),
    'native_images':26,'registered_builtin_calls':26,'original_whole_FAIL_preserved':True,'objects':len(layout['objects']),
    'blockers':len(layout['blockers']),'walking_residents':8,'resident_identities':2,'interior':'one cached wooden hall',
    'formal_world_enabled':False,'visual_review':'native panorama17/plaza16/stair12/market13/dye15 viewed; first editable version, not final whole-city ART'})
payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'))[1])
save(STAGE/'catalog-nonresources-before.json',{k:v for k,v in payload.items() if k!='resources'})
save(ROOT/'assets/raw/miao_town_design_20261029e/selected-design-authorization.json',{'user_quote':'可以，按照这个创造',
    'confirmed_date':'2026-10-29','design':'assets/raw/miao_town_design_20261029e/miao_masterplan_overview_v1.png',
    'implementation_scene':'game/'+SCENE,'scope':'独立六区编辑地图；正式地点ID/世界入口/剧情未创建'})
previews=ROOT/'assets/previews'/NAME;previews.mkdir(parents=True,exist_ok=True);shots=[]
for srcname,dstname in [('17-final-panorama','overview'),('16-final-plaza','plaza'),('12-refined-stair-2900','stairs'),
    ('15-refined-dye-yard','workyard'),('04-wooden-hall','wooden-hall'),('11-refined-roofed-bridge','covered-bridge')]:
    src=PROJECT/'artifacts'/(srcname+'.png');dst=previews/(dstname+'.png');shutil.copyfile(src,dst);assert sha(src)==sha(dst)
    shots.append({'source':src.relative_to(ROOT).as_posix(),'output':dst.relative_to(ROOT).as_posix(),'sha256':sha(dst),'native_copy_unchanged':True})
save(previews/'manifest.json',{'shots':shots,'note':'Original GPU screenshots; no image editing. Hall success inherited from original run.'})
print('Published',len(rels),'NEW files,52import leaves;',len(protected),'protected exact;objects',len(layout['objects']),'blockers',len(layout['blockers']))
