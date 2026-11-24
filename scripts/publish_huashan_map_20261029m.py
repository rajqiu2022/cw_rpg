"""Promote only Huashan's new namespace and exact new texture import leaves."""
import re
from huashan_map_20261029m import *
assert not (STAGE/'publication.json').exists()
for label in ['verify01','baked02']:
    r=json.loads((PROJECT/'artifacts-m'/(('baked02' if label=='baked02' else 'verify01')+'.json')).read_text('utf-8'));assert r['failures']==0
    run=json.loads((STAGE/(label+'.run.json')).read_text('utf-8'));assert run['state']=='NATURAL_EXIT' and run['exit_code']==0
assert (STAGE/'baked02.stderr.txt').stat().st_size==0 and (STAGE/'import01.stderr.txt').stat().st_size==0
guard=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changed=[]
for r in guard:
    p=Path(r['path'])
    if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changed.append(r['path'])
save(STAGE/'protected-before-publication.json',{'count':len(guard),'changes':changed});assert not changed,changed
scene='scenes/drafts/'+NAME+'/huashan.tscn';scene_text=(PROJECT/scene).read_text('utf-8');assert 'metadata/terrain_baked = true' in scene_text
manifest=json.loads((RAW/'manifest.json').read_text('utf-8'));media=json.loads((STAGE/'media.json').read_text('utf-8'));rows=[]
for r in manifest['assets']:
    m=media[r['key']];assert sha(ROOT/r['output'])==r['sha256'];assert sha(PROJECT/m['path'])==sha(ROOT/m['processed'])
    assert 'res://'+m['path'] in scene_text or r['key']=='granite_crag'
    kind='ground' if r['key']=='granite_ground' else ('landform' if r['key']=='granite_crag' else ('scene_prop' if r['key']=='sword_rack' else 'building'))
    rows.append({'key':r['key'],'label':r['label'],'kind':kind,'sect':'huashan','source':r['output'],'processed':m['processed'],'output':'game/'+m['path'],'sha256':sha(PROJECT/m['path']),'scenes':['res://'+scene],'padding':m['padding'],'original_RGBA_preserved':True,'alpha_cleaned_pixels':0})
    r.update(status='USED_IN_INDEPENDENT_EDITOR_MAP',runtime='game/'+m['path'],processed=m['processed'],consumers=['res://'+scene],formal_world_enabled=False)
save(RAW/'manifest.json',manifest)
pack={'status':'HUASHAN_EDITABLE_OUTDOOR_FIRST_VERSION','assets':rows,'scenes':{'huashan':scene},'formal_world_enabled':False,'new_native_images':8,'whole_design_ART_accepted':False,'notes':'六区/0-240-480真实高程/5阶口/山脊连续边界。门派NPC/业务内景与正式世界入口待接。'}
save(PROJECT/ART/'resource-pack.json',pack)
prefixes=[ART,'scripts/drafts/'+NAME,'scenes/drafts/'+NAME]
pending=[scene,'scripts/drafts/'+NAME+'/controller.gd','scripts/drafts/'+NAME+'/terrain.gd'];seen=set();reused=[]
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
rels=[p.relative_to(PROJECT).as_posix() for prefix in prefixes for p in (PROJECT/prefix).rglob('*') if p.is_file()];leaves=[]
for imp in (PROJECT/ART).glob('*.png.import'):
    for ref in set(re.findall(r'res://(\.godot/imported/[^"\]]+)',imp.read_text('utf-8'))):
        assert (PROJECT/ref).is_file();leaves.append(ref)
        md5=Path(ref).with_suffix('.md5').as_posix()
        if (PROJECT/md5).is_file():leaves.append(md5)
rels=sorted(set(rels+leaves))
for rel in rels:assert not (ROOT/'game'/rel).exists(),rel
for rel in rels:
    dst=ROOT/'game'/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,dst);assert sha(dst)==sha(PROJECT/rel)
preview=ROOT/'assets/previews'/NAME;preview.mkdir(parents=True,exist_ok=True);shots=[]
for key in ['overview_final','hall_final','domestic_final','debate_final','gate_final','stair_mid01','reflection01']:
    src=PROJECT/'artifacts-m'/(key+'.png');dst=preview/(key+'.png');shutil.copyfile(src,dst);shots.append({'output':dst.relative_to(ROOT).as_posix(),'sha256':sha(dst),'native_GPU_unchanged':True})
save(preview/'manifest.json',{'shots':shots,'note':'reflection01/stair_mid01 precede visual-only rim and ground-scale changes; other five are final'})
payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'))[1]);save(STAGE/'catalog-nonresources-before.json',{k:v for k,v in payload.items() if k!='resources'})
save(STAGE/'publication.json',{'files':[{'path':'game/'+rel,'sha256':sha(ROOT/'game'/rel),'bytes':(ROOT/'game'/rel).stat().st_size} for rel in rels],'new_files':len(rels),'new_import_leaves':len(set(leaves)),'protected_count':len(guard),'old_game_files_written':0,'scene_sha256':sha(ROOT/'game'/scene)})
print('Published',len(rels),'new files;',len(set(leaves)),'import leaves;',len(guard),'protected exact;',len(reused),'reused dependencies exact')
