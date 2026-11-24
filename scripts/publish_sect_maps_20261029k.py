"""Promote only new sect files and their isolated import leaves."""
import re,json,shutil
from pathlib import Path
from sect_maps_20261029k import ROOT,NAME,RAW,STAGE,PROJECT,ART,save,sha

assert not (STAGE/'publication.json').exists()
reports={k:json.loads((PROJECT/'artifacts-k'/v).read_text('utf-8')) for k,v in [('first','verify01.json'),('routes','routes02.json'),('baked','baked03.json'),('input','baked-input04.json')]}
assert reports['first']['failures']==2
assert all(reports[k]['failures']==0 for k in ['routes','baked','input'])
for log in ['routes02','baked-input04','import03']:assert (STAGE/(log+'.stderr.txt')).stat().st_size==0
guard=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changes=[]
for r in guard:
    p=Path(r['path'])
    if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changes.append(r['path'])
save(STAGE/'protected-before-publication-attempt01.json',{'count':len(guard),'changes':changes}) if not (STAGE/'protected-before-publication-attempt01.json').exists() else None
# A concurrent city chat changed the shared Router. These private F6 scenes do not
# reference it or install an autoload. Preserve that external version, never restore it.
router=ROOT/'game/scripts/autoload/scene_router.gd'
allowed_external=[str(router)]
assert all(p in allowed_external for p in changes),changes
external=[{'path':p,'sha256':sha(Path(p)),'bytes':Path(p).stat().st_size,'mtime_ns':Path(p).stat().st_mtime_ns,'origin':'concurrent external edit; not written by this task'} for p in changes]
save(STAGE/'protected-before-publication.json',{'count':len(guard),'changes':changes,'unchanged_count':len(guard)-len(changes),'external_preserved':external})
scenes={k:f'scenes/drafts/{NAME}/{k}.tscn' for k in ['wudang','mingwu']}
texts={k:(PROJECT/v).read_text('utf-8') for k,v in scenes.items()}
assert all('metadata/terrain_baked = true' in t for t in texts.values())
media=json.loads((STAGE/'media.json').read_text('utf-8'));manifest=json.loads((RAW/'manifest.json').read_text('utf-8'));rows=[]
for r in manifest['assets']:
    m=media[r['key']];target=PROJECT/m['path'];source=ROOT/r['output'];processed=ROOT/m['processed']
    assert sha(source)==r['sha256'] and sha(target)==sha(processed)
    consumers=['res://'+scenes[k] for k,t in texts.items() if 'res://'+m['path'] in t];assert consumers,r['key']
    kind='ground' if r['key'] in ['quiet_ground','taiji_floor'] else ('vegetation' if r['key'] in ['wudang_pine','tea_rows'] else ('landform' if r['key']=='limestone_mass' else 'building'))
    rows.append({'key':r['key'],'label':r['label'],'kind':kind,'sect':r['sect'],'source':r['output'],'processed':m['processed'],'output':'game/'+m['path'],'sha256':sha(target),'scenes':consumers,'padding':m['padding'],'original_RGBA_preserved':True,'alpha_cleaned_pixels':0})
    r.update(kind=kind,consumers=consumers,processed=m['processed'],runtime='game/'+m['path'],status='USED_IN_ISOLATED_EDITOR_MAP',formal_world_enabled=False)
save(RAW/'manifest.json',manifest)
pack={'status':'TWO_SECT_EDITABLE_MAPS','assets':rows,'scenes':scenes,'formal_world_enabled':False,'whole_design_ART_accepted':False,'new_native_images':12,'reports':{'first_44_checks_2_failed_retained':True,'continuous_routes_14_passed':True,'baked_20_passed':True,'baked_input_14_passed':True},'notes':'武当0/180/360；茗雾0/60/120。每派4真阶口；两桥平接。新门派NPC/室内业务/正式世界入口未接。'}
save(PROJECT/ART/'resource-pack.json',pack)
prefixes=[ART,'scripts/drafts/'+NAME,'scenes/drafts/'+NAME]
rels=[p.relative_to(PROJECT).as_posix() for prefix in prefixes for p in (PROJECT/prefix).rglob('*') if p.is_file()]
# Resource dependency closure verifies every reused source byte against the live project.
pending=list(scenes.values())+['scripts/drafts/'+NAME+'/controller.gd','scripts/drafts/'+NAME+'/terrain.gd'];seen=set();reused=[]
while pending:
    rel=pending.pop()
    if rel in seen:continue
    seen.add(rel);p=PROJECT/rel;assert p.is_file(),rel
    if not any(rel.startswith(prefix+'/') for prefix in prefixes):
        assert (ROOT/'game'/rel).is_file() and sha(p)==sha(ROOT/'game'/rel),rel
        reused.append({'path':rel,'sha256':sha(p)})
    if p.suffix in ['.gd','.tscn','.json','.gdshader']:
        for child in re.findall(r'res://[^"\s<>\\]+',p.read_text('utf-8')):
            if (PROJECT/child[6:]).is_file():pending.append(child[6:])
save(STAGE/'existing-dependencies-exact.json',reused)
assert not any(r['path']=='scripts/autoload/scene_router.gd' for r in reused)
leaves=[]
for src in (PROJECT/ART).glob('*.png.import'):
    refs=set(re.findall(r'res://(\.godot/imported/[^"\]]+)',src.read_text('utf-8')))
    for ref in refs:
        assert (PROJECT/ref).is_file();leaves.append(ref)
        md5=str(Path(ref).with_suffix('.md5')).replace('\\','/')
        if (PROJECT/md5).is_file():leaves.append(md5)
rels=sorted(set(rels+leaves))
for rel in rels:assert not (ROOT/'game'/rel).exists(),rel
for rel in rels:
    dst=ROOT/'game'/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,dst);assert sha(dst)==sha(PROJECT/rel)
preview=ROOT/'assets/previews'/NAME;preview.mkdir(parents=True,exist_ok=True);shots=[]
for key in ['wudang_overview_final','wudang_hall_final','mingwu_overview_final','mingwu_hall_final','mingwu_workshop02','wudang_stair01']:
    src=PROJECT/'artifacts-k'/(key+'.png');dst=preview/(key+'.png');shutil.copyfile(src,dst);shots.append({'output':dst.relative_to(ROOT).as_posix(),'sha256':sha(dst),'native_GPU_unchanged':True})
save(preview/'manifest.json',{'shots':shots})
payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'))[1]);save(STAGE/'catalog-nonresources-before.json',{k:v for k,v in payload.items() if k!='resources'})
save(STAGE/'publication.json',{'files':[{'path':'game/'+rel,'sha256':sha(ROOT/'game'/rel),'bytes':(ROOT/'game'/rel).stat().st_size} for rel in rels],'new_files':len(rels),'new_import_leaves':len(set(leaves)),'protected_count':len(guard),'old_game_files_written':0,'scene_sha256':{k:sha(ROOT/'game'/v) for k,v in scenes.items()}})
for r in external:
    p=Path(r['path']);assert (sha(p),p.stat().st_size,p.stat().st_mtime_ns)==(r['sha256'],r['bytes'],r['mtime_ns'])
print('Published',len(rels),'new files;',len(set(leaves)),'import leaves;',len(guard)-len(external),'protected exact;',len(external),'external edit preserved;',len(reused),'reused dependencies exact')
