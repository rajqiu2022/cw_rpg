"""Read-only final evidence plus resource-only catalog synchronization."""
import re,subprocess
from urllib.parse import unquote
from desert_city_rework_20261029o import *
import audit_desert_city_pixels_20261029n as audit

def catalog():
    text=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
    data=json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)[1])
    return data

if sys.argv[1]=='audit':
    assert not (STAGE/'native-density-after.json').exists()
    scenes={k:audit.audit_scene(p) for k,p in audit.SCENES.items()}
    assert all(s['summary']['logical_upscale_instances']==0 for s in scenes.values())
    save(STAGE/'native-density-after.json',{'scope':'Direct static sprites, source PNG plus ancestor transforms; shader UV and inherited/animated sprites excluded. Actual normal camera tested separately at 1920x1080.','scenes':scenes})
    pack_path=ROOT/'game'/ART/'resource-pack.json';pack=json.loads(pack_path.read_text('utf-8'));pack['status']='PUBLISHED_NATIVE_DENSITY_AND_TWO_FORMAL_WORLD_TRIPS_VERIFIED';save(pack_path,pack)
    print(json.dumps({k:s['summary'] for k,s in scenes.items()}))
elif sys.argv[1]=='catalog':
    old=catalog();old_non={k:v for k,v in old.items() if k!='resources'}
    save(STAGE/'catalog-before-summary.json',{'nonresources_sha256':hashlib.sha256(json.dumps(old_non,sort_keys=True,ensure_ascii=False).encode()).hexdigest(),'summary':old['resources']['summary']})
    for script,args in [('build_arsenal_catalog.py',['--sync-resources-only']),('build_resource_reuse_index.py',[])]:
        p=subprocess.run([sys.executable,str(ROOT/'scripts'/script)]+args,capture_output=True,encoding='utf-8');(STAGE/(script+'.stdout.txt')).write_text(p.stdout,'utf-8');(STAGE/(script+'.stderr.txt')).write_text(p.stderr,'utf-8');assert p.returncode==0,p.stderr
    new=catalog();assert {k:v for k,v in new.items() if k!='resources'}==old_non
    rows=[r for r in new['resources']['records'] if NAME in r['diskPath']]
    assert len(rows)==24,len(rows)
    checks=[]
    for r in rows:
        assert (ROOT/r['diskPath']).is_file() and r['thumbnail'] and r['usageCount']==1
        for field in ['url','thumbnail']:
            path=(ROOT/'docs'/unquote(r[field])).resolve();assert path.is_file(),str(path)
            with Image.open(path) as im:im.verify()
        checks.append({'path':r['diskPath'],'thumbnail':r['thumbnail'],'image_and_thumb_valid':True,'usage':r['usage']})
    save(STAGE/'catalog-after.json',{'nonresources_unchanged':True,'summary':new['resources']['summary'],'new_path_count':len(rows),'images_and_thumbnails_valid':len(rows)*2,'rows':checks})
    print(json.dumps({'catalog':new['resources']['summary'],'new_paths':len(rows),'nonresources_unchanged':True},ensure_ascii=False))
elif sys.argv[1]=='guard':
    facts=json.loads((STAGE/'publish-protected-before.json').read_text('utf-8'));changes=[];saved=0
    for r in facts:
        p=Path(r['path']);now={'path':str(p),'exists':p.is_file()}
        if p.is_file():now.update(sha256=sha(p),bytes=p.stat().st_size,mtime_ns=p.stat().st_mtime_ns)
        if now!=r:changes.append({'before':r,'after':now})
        if 'app_userdata' in str(p):saved+=1
    owned=json.loads((STAGE/'publish.json').read_text('utf-8'))['changed_existing']
    for r in owned:assert sha(ROOT/'game'/r['path'])==r['after_sha256'],r['path']
    manifest=json.loads((ROOT/'game/build/three_towns_world_20261029j_system01/native_sources.json').read_text('utf-8'))
    for path,digest in manifest['sources'].items():assert sha(ROOT/'game'/path[6:])==digest,path
    save(STAGE/'final-protection.json',{'objects':len(facts),'save_paths':saved,'changed_protected_objects':changes,'five_owned_targets_match_published':True,'source_manifest_valid':True})
    print(json.dumps({'objects':len(facts),'saves':saved,'protected_changes':changes},ensure_ascii=False))
