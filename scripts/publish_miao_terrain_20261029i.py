"""Publish seven new files only, using inherited success plus new residual evidence."""
import json
import re
import shutil
from pathlib import Path
from build_miao_terrain_20261029i import ROOT, STAGE, PROJECT, NAME, ART, SCENE, SCRIPT
from build_redrock_town_20261028a import save, sha

assert not (STAGE/'publication.json').exists()
artifacts=PROJECT/'artifacts-i'
reports={name:json.loads((artifacts/file).read_text('utf-8')) for name,file in [
    ('terrain','verification-terrain.json'),('routes','verification-routes.json'),
    ('journey','verification-journey.json'),('baked','verification-baked.json')]}
assert (reports['terrain']['count'],reports['terrain']['failed'])==(36,3)
assert (reports['routes']['count'],reports['routes']['failed'])==(16,1)
assert (reports['journey']['count'],reports['journey']['failed'])==(5,0)
assert (reports['baked']['count'],reports['baked']['failed'])==(7,0)
assert all((STAGE/(stem+'.stderr.log')).stat().st_size==0 for stem in ['terrain02','routes01','journey02','bake','baked02'])
before=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changes=[]
for r in before:
    p=Path(r['path'])
    if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changes.append(r['path'])
save(STAGE/'protected-before-publication.json',{'count':len(before),'changes':changes,'SHA_bytes_mtime_exact':not changes})
assert not changes,changes
terrain=json.loads((STAGE/'terrain.json').read_text('utf-8'))
scene=(PROJECT/SCENE).read_text('utf-8')
assert 'metadata/terrain_baked = true' in scene and '[node name="Terrain"' in scene
resources=set(re.findall(r'res://[^"\s<>\\]+',scene))
dynamic={'ground','path','water','interior','man_walk','woman_walk','side_stride','man_portrait','woman_portrait','woodland_floor'}
packs={}
for version in ['miao_town_20261029f','miao_recompose_20261029g','miao_building_variety_20261029h']:
    prior=json.loads((ROOT/'game/art/modules'/version/'resource-pack.json').read_text('utf-8'))
    rows=[r for r in prior['assets'] if 'res://'+r['destination'] in resources or r['key'] in dynamic]
    for r in rows:assert sha(ROOT/r['output'])==sha(PROJECT/r['destination'])==r['sha256']
    packs[version]=rows
save(PROJECT/ART/'resource-pack.json',{
    'status':'MIAO_THREE_HEIGHT_EDITOR_MAP','scene':'res://'+SCENE,'assets':[],
    'terrain_data':'res://'+ART+'/terrain.json','native_new_images':0,'PNG_processing':False,
    'heights':[0,120,240],'ramps':terrain['ramps'],'reused_asset_keys':{k:[r['key'] for r in rows] for k,rows in packs.items()},
    'previous_scene':'res://scenes/drafts/miao_building_variety_20261029h/miao_town.tscn',
    'previous_feedback':'地形没有变化，楼梯随机摆放没有实质作用',
    'new_elevation_proof':{'terrain_success_inherited':33,'route_success_inherited':15,'continuous_journey_checks':5,'baked_scene_checks':7,'old_reports_retained':True},
    'formal_world_enabled':False,'whole_city_final_ART':False})
# Every existing dependency copied into the private project must still match live bytes.
pending=[SCENE,SCRIPT];seen=set();reuse=[]
while pending:
    rel=pending.pop()
    if rel in seen:continue
    seen.add(rel);p=PROJECT/rel;assert p.is_file(),rel
    if not rel.startswith((ART+'/',f'scripts/drafts/{NAME}/',f'scenes/drafts/{NAME}/')):
        assert sha(p)==sha(ROOT/'game'/rel),'dependency drift '+rel
        reuse.append({'path':rel,'sha256':sha(p)})
    if p.suffix in ['.gd','.tscn','.gdshader','.json']:
        for child in re.findall(r'res://[^"\s<>\\]+',p.read_text('utf-8')):
            if (PROJECT/child[6:]).is_file():pending.append(child[6:])
for rows in packs.values():
    for r in rows:reuse.append({'path':r['destination'],'sha256':sha(ROOT/r['output'])})
save(STAGE/'existing-dependencies-exact.json',{'files':reuse,'all_exact':True})
rels=[SCENE,SCRIPT,f'scripts/drafts/{NAME}/terrain.gd',f'scripts/drafts/{NAME}/resident.gd',ART+'/terrain.json',ART+'/ground.gdshader',ART+'/resource-pack.json']
for rel in rels:assert (PROJECT/rel).is_file() and not (ROOT/'game'/rel).exists(),rel
for rel in rels:
    target=ROOT/'game'/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,target)
preview=ROOT/'assets/previews'/NAME;preview.mkdir(parents=True,exist_ok=True);shots=[]
for srcname,targetname in [('12-baked-overview','overview'),('11-baked-stair-top','plaza-top'),('08-clear-workshop-stair','workshop-stair'),('03-upper-stair-middle','stair-middle'),('09-continuous-upper-arrival','upper-arrival')]:
    src=artifacts/(srcname+'.png');dst=preview/(targetname+'.png');shutil.copyfile(src,dst);assert sha(src)==sha(dst)
    shots.append({'source':src.relative_to(ROOT).as_posix(),'output':dst.relative_to(ROOT).as_posix(),'sha256':sha(dst),'native_GPU_unchanged':True})
save(preview/'manifest.json',{'shots':shots,'note':'Native GPU captures, no screenshot editing; first failed reports retained in private artifacts.'})
payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'))[1])
save(STAGE/'catalog-nonresources-before.json',{k:v for k,v in payload.items() if k!='resources'})
save(STAGE/'publication.json',{'files':[{'path':'game/'+rel,'sha256':sha(ROOT/'game'/rel),'bytes':(ROOT/'game'/rel).stat().st_size} for rel in rels],
    'new_game_files':len(rels),'changed_existing_game_files':[],'new_PNG':0,'new_import_leaves':0,
    'scene_sha256':sha(ROOT/'game'/SCENE),'protected_count':len(before),'editor_geometry_baked':True,
    'same_actor_default_spawn_to_upper_journey':True,'formal_world_enabled':False,'whole_city_final_ART':False})
print('Published7new files/0PNG/0import leaves;',len(before),'protected exact;',sum(len(x) for x in packs.values()),'reused native media; sceneSHA',sha(ROOT/'game'/SCENE))
