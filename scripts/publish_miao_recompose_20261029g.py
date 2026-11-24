"""New-file-only release of the concept-layout correction; previous city stays exact."""
import json
import re
import shutil
from pathlib import Path
from miao_recompose_20261029g import ROOT, RAW, STAGE, PROJECT, ART, SCENE, SCRIPT, NAME
from build_redrock_town_20261028a import save, sha
assert not (STAGE/'publication.json').exists()
for file,count,failed in [('verification-recompose.json',65,6),('verification-residual.json',14,0)]:
    r=json.loads((PROJECT/'artifacts-g'/file).read_text('utf-8'));assert (r['count'],r['failed'])==(count,failed)
assert (STAGE/'residual.stderr.log').stat().st_size==0
protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changes=[]
for r in protected:
    p=Path(r['path'])
    if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changes.append(r['path'])
save(STAGE/'protected-before-publication.json',{'count':len(protected),'changes':changes,'exact_SHA_bytes_mtime':not changes});assert not changes,changes
layout=json.loads((STAGE/'layout.json').read_text('utf-8'));pack=[]
for key,r in layout['media'].items():
    assert r['calls']==1 and sha(ROOT/r['output'])==r['sha256'] and sha(PROJECT/r['destination'])==r['processed_sha256']
    pack.append({'key':key,'kind':r['kind'],'label':r['label'],'source':r['processed'],'parent_source':r['output'],'destination':r['destination'],
        'output':'game/'+r['destination'],'sha256':r['processed_sha256'],'scene':'res://'+SCENE,'review_note':'29f布局偏离总规后新制的高脚铺街/木楼、苔岩、叠瀑、栈道及林下底材；5透明原图完整保留，仅RGBA0留白。'})
used=sorted(set(layout['reused_media'])-{'terrace','shop'})
save(PROJECT/ART/'resource-pack.json',{'status':'MIAO_CONCEPT_RECOMPOSED_EDITOR_MAP','scene':'res://'+SCENE,'validated_image_count':6,'formal_world_enabled':False,
    'assets':pack,'reused_previous_asset_keys':used,'previous_pack':'game/art/modules/miao_town_20261029f/resource-pack.json',
    'previous_scene':'res://scenes/drafts/miao_town_20261029f/miao_town.tscn','previous_layout_status':'USER_REJECTED_CONCEPT_MISMATCH',
    'native_animation':'inherited four directional idle, native side4 with LEFT runtime mirror; original vertical walk not adopted'})
pending=[SCENE,SCRIPT];seen=set();reuse=[]
while pending:
    rel=pending.pop()
    if rel in seen:continue
    seen.add(rel);p=PROJECT/rel;assert p.is_file(),rel
    if not rel.startswith((ART+'/',f'scripts/drafts/{NAME}/',f'scenes/drafts/{NAME}/')):
        assert sha(p)==sha(ROOT/'game'/rel),'existing dependency drift '+rel
        reuse.append({'path':rel,'sha256':sha(p)})
    if p.suffix in ['.gd','.tscn','.gdshader','.json']:
        for child in re.findall(r'res://[^"\s<>\\]+',p.read_text('utf-8')):
            if (PROJECT/child[6:]).is_file():pending.append(child[6:])
for p in (PROJECT/'art/characters/weapon_variants/lengguyun/v7_idle_stable/sword').glob('*.png'):
    rel=p.relative_to(PROJECT).as_posix();assert sha(p)==sha(ROOT/'game'/rel);reuse.append({'path':rel,'sha256':sha(p)})
save(STAGE/'existing-dependencies-exact.json',{'files':reuse,'all_exact':True})
rels=[SCENE];rels += [p.relative_to(PROJECT).as_posix() for p in (PROJECT/f'scripts/drafts/{NAME}').iterdir() if p.is_file()]
imports=set()
for p in (PROJECT/ART).iterdir():
    if not p.is_file():continue
    rels.append(p.relative_to(PROJECT).as_posix())
    if p.suffix=='.import':imports.update(re.findall(r'res://(\.godot/imported/[^"\s]+)',p.read_text('utf-8')))
for rel in sorted(imports):rels.extend([rel,Path(rel).with_suffix('.md5').as_posix()])
assert len(imports)==6 and len(rels)==len(set(rels))
for rel in rels:assert (PROJECT/rel).is_file() and not (ROOT/'game'/rel).exists(),rel
for rel in rels:
    dst=ROOT/'game'/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,dst)
save(STAGE/'publication.json',{'files':[{'path':'game/'+rel,'sha256':sha(ROOT/'game'/rel),'bytes':(ROOT/'game'/rel).stat().st_size} for rel in rels],
    'new_files':len(rels),'changed_existing_game_files':[],'scene_sha256':sha(ROOT/'game'/SCENE),'import_leaves':12,'protected_count':len(protected),
    'native_images':6,'objects':len(layout['objects']),'blockers':len(layout['blockers']),'homes':36,'high_stilt_homes':8,'market_bays':6,
    'first_whole_FAIL_preserved':True,'formal_world_enabled':False,'art_status':'recomposed prototype, still differs in exact mountain relief/camera/roof density; no final concept-match claim'})
catalog=ROOT/'docs/equipment-skill-catalog.html';payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',catalog.read_text('utf-8'))[1])
save(STAGE/'catalog-nonresources-before.json',{k:v for k,v in payload.items() if k!='resources'})
preview=ROOT/'assets/previews'/NAME;preview.mkdir(parents=True,exist_ok=True);shots=[]
for srcname,dstname in [('20-clean-overview','overview'),('19-final-overview','overview-hud'),('17-final-plaza','plaza'),('18-final-workyard','workyard'),('11-market','market'),('15-stair','stair')]:
    src=PROJECT/'artifacts-g'/(srcname+'.png');dst=preview/(dstname+'.png');shutil.copyfile(src,dst);assert sha(src)==sha(dst)
    shots.append({'source':src.relative_to(ROOT).as_posix(),'output':dst.relative_to(ROOT).as_posix(),'sha256':sha(dst),'unchanged_native_GPU_copy':True})
save(preview/'manifest.json',{'shots':shots,'overview_note':'UI hidden in native GPU view only; PNG not edited'})
save(STAGE/'layout-rejection-and-successor.json',{'user_quote':'跟设计稿相差比较大啊','previous_scene':'game/scenes/drafts/miao_town_20261029f/miao_town.tscn','previous_scene_preserved':True,'successor_scene':'game/'+SCENE,'not_final_ART':True})
print('Published',len(rels),'new files,12new import leaves;',len(protected),'protected exact;',len(layout['objects']),'objects',len(layout['blockers']),'bodies')
