"""Publish only new-city files after targeted native runtime checks; protect shared state."""
import json
import re
import shutil
from pathlib import Path
from desert_town_20261029d import ROOT, RAW, STAGE, PROJECT, ART, SCENE, SCRIPT, NAME
from build_redrock_town_20261028a import save, sha

def main():
    assert not (STAGE/'publication.json').exists()
    expected=[('verification-town.json',49,2),('verification-residual.json',13,0),('verification-courts.json',222,5),('verification-access-final.json',8,0)]
    for file,count,failed in expected:
        r=json.loads((PROJECT/'artifacts'/file).read_text('utf-8'));assert (r['count'],r['failed'])==(count,failed)
    assert (STAGE/'access-final.stderr.log').stat().st_size==0 and (STAGE/'residual.stderr.log').stat().st_size==0
    protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changed=[]
    for r in protected:
        p=Path(r['path'])
        if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changed.append(r['path'])
    save(STAGE/'protected-before-publication.json',{'count':len(protected),'changed':changed,'exact_SHA_bytes_mtime':not changed})
    assert not changed,changed
    layout=json.loads((STAGE/'layout.json').read_text('utf-8'))
    pack=[]
    for key,r in layout['media'].items():
        assert sha(ROOT/r['output'])==r['sha256'] and sha(PROJECT/r['destination'])==r['processed_sha256']
        pack.append({'key':key,'kind':r['kind'],'label':r['label'],'source':r['processed'],'parent_source':r['output'],
            'destination':r['destination'],'output':'game/'+r['destination'],'sha256':r['processed_sha256'],
            'scene':'res://'+SCENE,'review_note':'沙漠六区可编辑地图引用；等比摆放，原图保持；透明组件仅补RGBA0留白，原A1失败保留。'})
    save(PROJECT/ART/'resource-pack.json',{'status':'DESERT_CITY_EDITOR_MAP','scene':'res://'+SCENE,'validated_image_count':13,
        'formal_world_enabled':False,'assets':pack,'reused_existing_art':layout['reused_art']})
    # Verify every existing literal dependency plus the dynamically selected sword strips.
    pending=[SCENE,SCRIPT];seen=set();reuse=[]
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
    for rel in layout['reused_art']:
        assert sha(PROJECT/rel)==sha(ROOT/'game'/rel),rel
    swords=PROJECT/'art/characters/weapon_variants/lengguyun/v7_idle_stable/sword'
    for p in swords.glob('*.png'):
        rel=p.relative_to(PROJECT).as_posix();assert sha(p)==sha(ROOT/'game'/rel)
        reuse.append({'path':rel,'sha256':sha(p)})
    save(STAGE/'existing-dependencies-exact.json',{'files':reuse,'reused_art':layout['reused_art'],'all_existing_exact':True})
    rels=[SCENE,SCRIPT]
    if (PROJECT/(SCRIPT+'.uid')).is_file():rels.append(SCRIPT+'.uid')
    imports=set()
    for p in (PROJECT/ART).iterdir():
        if not p.is_file():continue
        rels.append(p.relative_to(PROJECT).as_posix())
        if p.suffix=='.import':imports.update(re.findall(r'res://(\.godot/imported/[^"\s]+)',p.read_text('utf-8')))
    for rel in sorted(imports):rels.extend([rel,Path(rel).with_suffix('.md5').as_posix()])
    assert len(imports)==13
    for rel in rels:assert (PROJECT/rel).is_file() and not (ROOT/'game'/rel).exists(),rel
    for rel in rels:
        target=ROOT/'game'/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(PROJECT/rel,target)
    save(STAGE/'publication.json',{'files':[{'path':'game/'+rel,'sha256':sha(ROOT/'game'/rel),'bytes':(ROOT/'game'/rel).stat().st_size} for rel in rels],
        'new_files':len(rels),'changed_existing_game_files':[],'import_leaves':len(imports)*2,
        'protected_count':len(protected),'protected_SHA_bytes_mtime_exact':True,'production_import_invoked':False,
        'scene_sha256':sha(ROOT/'game'/SCENE),'native_images':13,'registered_builtin_calls':14,
        'rejected_native_first_enclosure_retained':True,'objects':len(layout['objects']),'blockers':len(layout['blockers']),
        'walking_residents':6,'interior':'one cached guest hall','formal_world_enabled':False,
        'visual_review':'native screenshots 07/09/10/16/17 viewed; general structure only, not whole-city final ART'})
    catalog=ROOT/'docs/equipment-skill-catalog.html'
    payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',catalog.read_text('utf-8'))[1])
    save(STAGE/'catalog-nonresources-before.json',{k:v for k,v in payload.items() if k!='resources'})
    save(ROOT/'assets/raw/desert_town_design_20261029c/selected-design-authorization.json',{
        'user_quote':'按照这个来创建沙漠成','interpreted_request':'按照这张总规创建独立沙漠城','confirmed_date':'2026-10-29',
        'design':'assets/raw/desert_town_design_20261029c/desert_masterplan_overview_v1.png','implementation_scene':'game/'+SCENE,
        'scope':'独立六区可编辑城镇；正式地点ID、世界入口与剧情未创建'})
    print(f'Published {len(rels)} NEW files, {len(imports)*2} import leaves; {len(protected)} protected files exact; no existing game file changed')

if __name__=='__main__':main()
