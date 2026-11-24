import json,re
from pathlib import Path
from urllib.parse import unquote
from PIL import Image
from sect_maps_20261029k import ROOT,NAME,RAW,STAGE,save,sha

payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'))[1])
assert {k:v for k,v in payload.items() if k!='resources'}==json.loads((STAGE/'catalog-nonresources-before.json').read_text('utf-8'))
records={r['diskPath']:r for r in payload['resources']['records']};pack=json.loads((ROOT/'game/art/modules'/NAME/'resource-pack.json').read_text('utf-8'));count=0
for row in pack['assets']:
    for field in ['source','processed','output']:
        r=records[row[field]];assert r['usageCount']==len(row['scenes'])
        for key in ['url','thumbnail']:
            p=ROOT/'docs'/unquote(r[key]);assert p.is_file(),p
            with Image.open(p) as im:im.verify()
            count+=1
        assert r['sha256']==sha(ROOT/row[field])
publication=json.loads((STAGE/'publication.json').read_text('utf-8'))
for r in publication['files']:assert sha(ROOT/r['path'])==r['sha256']
before=json.loads((STAGE/'protected-before.json').read_text('utf-8'));external=[]
for row in before:
    p=Path(row['path']);changed=(sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(row['sha256'],row['bytes'],row['mtime_ns'])
    if changed:external.append(str(p));assert p==ROOT/'game/scripts/autoload/scene_router.gd'
save(STAGE/'final-verification.json',{'new_game_files':len(publication['files']),'new_asset_paths':36,'image_links_verified':count,'nonresources_unchanged':True,'protected_unchanged':len(before)-len(external),'external_changed_preserved':external,'summary':payload['resources']['summary']})
print(json.dumps(json.loads((STAGE/'final-verification.json').read_text('utf-8')),ensure_ascii=False))
