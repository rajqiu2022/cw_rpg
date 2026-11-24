"""Publish only the architecture-variation successor, after its changed-domain checks."""
import json
import re
import shutil
from pathlib import Path
from miao_building_variety_20261029h import ROOT, RAW, STAGE, PROJECT, ART, SCENE, SCRIPT, NAME
from build_redrock_town_20261028a import save, sha
assert not (STAGE/'publication.json').exists()
for file,count in [('verification-variety.json',62),('verification-views.json',6)]:
    r=json.loads((PROJECT/'artifacts-h'/file).read_text('utf-8'));assert (r['count'],r['failed'])==(count,0)
for stem in ['verify','views','import']:assert (STAGE/(stem+'.stderr.log')).stat().st_size==0
protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changes=[]
for r in protected:
    p=Path(r['path'])
    if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changes.append(r['path'])
save(STAGE/'protected-before-publication.json',{'count':len(protected),'changes':changes,'exact_SHA_bytes_mtime':not changes});assert not changes,changes
layout=json.loads((STAGE/'layout.json').read_text('utf-8'));pack=[]
for key,r in layout['media'].items():
    assert r['calls']==1 and sha(ROOT/r['output'])==r['sha256'] and sha(PROJECT/r['destination'])==r['processed_sha256']
    pack.append({'key':key,'kind':r['kind'],'label':r['label'],'source':r['processed'],'parent_source':r['output'],'destination':r['destination'],'output':'game/'+r['destination'],'sha256':r['processed_sha256'],
        'scene':'res://'+SCENE,'review_note':'29h建筑差异版：五种原生结构替换12处同尺度楼型；5透明只补RGBA0，原RGBA保持，原A1失败保留。成人门约105—120px，小粮棚为独立储藏舱。'})
objectkeys={r['key'] for r in layout['objects']}
fpack=json.loads((ROOT/'game/art/modules/miao_town_20261029f/resource-pack.json').read_text('utf-8'))
gpack=json.loads((ROOT/'game/art/modules/miao_recompose_20261029g/resource-pack.json').read_text('utf-8'))
dynamic={'ground','path','water','interior','man_walk','woman_walk','side_stride','man_portrait','woman_portrait','woodland_floor'}
fused=sorted({r['key'] for r in fpack['assets']}&(objectkeys|dynamic));gused=sorted({r['key'] for r in gpack['assets']}&(objectkeys|dynamic))
save(PROJECT/ART/'resource-pack.json',{'status':'MIAO_BUILDING_VARIETY_EDITOR_MAP','scene':'res://'+SCENE,'validated_image_count':5,'formal_world_enabled':False,'assets':pack,
    'reused_29f_asset_keys':fused,'reused_29g_asset_keys':gused,'previous_scene':'res://scenes/drafts/miao_recompose_20261029g/miao_town.tscn',
    'previous_layout_feedback':'建筑太接近，都是一个大小的，不够丰富','replaced_buildings':12,'native_animation':'inherited side4 and LEFT runtime mirror; vertical NPC walk not adopted'})
pending=[SCENE,SCRIPT];seen=set();reuse=[]
while pending:
    rel=pending.pop()
    if rel in seen:continue
    seen.add(rel);p=PROJECT/rel;assert p.is_file(),rel
    if not rel.startswith((ART+'/',f'scripts/drafts/{NAME}/',f'scenes/drafts/{NAME}/')):
        assert sha(p)==sha(ROOT/'game'/rel),'existing dependency drift '+rel;reuse.append({'path':rel,'sha256':sha(p)})
    if p.suffix in ['.gd','.tscn','.gdshader','.json']:
        for child in re.findall(r'res://[^"\s<>\\]+',p.read_text('utf-8')):
            if (PROJECT/child[6:]).is_file():pending.append(child[6:])
for p in (PROJECT/'art/characters/weapon_variants/lengguyun/v7_idle_stable/sword').glob('*.png'):
    rel=p.relative_to(PROJECT).as_posix();assert sha(p)==sha(ROOT/'game'/rel);reuse.append({'path':rel,'sha256':sha(p)})
save(STAGE/'existing-dependencies-exact.json',{'files':reuse,'all_exact':True})
rels=[SCENE];rels += [p.relative_to(PROJECT).as_posix() for p in (PROJECT/f'scripts/drafts/{NAME}').iterdir() if p.is_file()];imports=set()
for p in (PROJECT/ART).iterdir():
    if not p.is_file():continue
    rels.append(p.relative_to(PROJECT).as_posix())
    if p.suffix=='.import':imports.update(re.findall(r'res://(\.godot/imported/[^"\s]+)',p.read_text('utf-8')))
for rel in sorted(imports):rels.extend([rel,Path(rel).with_suffix('.md5').as_posix()])
assert len(imports)==5 and len(rels)==len(set(rels))
for rel in rels:assert (PROJECT/rel).is_file() and not (ROOT/'game'/rel).exists(),rel
for rel in rels:
    dst=ROOT/'game'/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,dst)
save(STAGE/'publication.json',{'files':[{'path':'game/'+rel,'sha256':sha(ROOT/'game'/rel),'bytes':(ROOT/'game'/rel).stat().st_size} for rel in rels],
    'new_files':len(rels),'changed_existing_game_files':[],'scene_sha256':sha(ROOT/'game'/SCENE),'import_leaves':10,'protected_count':len(protected),'native_images':5,
    'replaced_buildings':12,'objects':len(layout['objects']),'blockers':len(layout['blockers']),'formal_world_enabled':False,'whole_city_final_ART':False})
payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'))[1]);save(STAGE/'catalog-nonresources-before.json',{k:v for k,v in payload.items() if k!='resources'})
preview=ROOT/'assets/previews'/NAME;preview.mkdir(parents=True,exist_ok=True);shots=[]
for srcname,dstname in [('12-final-overview','overview'),('08-final-wide-hall','hall'),('09-final-tall','tower'),('10-final-low-cottage','cottage'),('04-angle-workshop','workshop'),('11-final-grain-shed','grain-shed'),('06-street-tower','street-tower')]:
    src=PROJECT/'artifacts-h'/(srcname+'.png');dst=preview/(dstname+'.png');shutil.copyfile(src,dst);assert sha(src)==sha(dst);shots.append({'source':src.relative_to(ROOT).as_posix(),'output':dst.relative_to(ROOT).as_posix(),'sha256':sha(dst),'unchanged_native_GPU_copy':True})
save(preview/'manifest.json',{'shots':shots,'note':'Native GPU images, no PNG editing; initial imperfect screenshot positions retained separately.'})
print('Published',len(rels),'new files,10import leaves;',len(protected),'protected exact;12buildings replaced')
