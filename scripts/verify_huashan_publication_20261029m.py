import re
from urllib.parse import unquote
from huashan_map_20261029m import *
p=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'))[1])
assert {k:v for k,v in p.items() if k!='resources'}==json.loads((STAGE/'catalog-nonresources-before.json').read_text('utf-8'))
rows={r['diskPath']:r for r in p['resources']['records']};pack=json.loads((ROOT/'game'/ART/'resource-pack.json').read_text('utf-8'));count=0
for r in pack['assets']:
    for field in ['source','processed','output']:
        row=rows[r[field]];assert row['usageCount']==1 and row['group'].startswith('华山派 /')
        assert row['sha256']==sha(ROOT/r[field])
        for key in ['url','thumbnail']:
            file=ROOT/'docs'/unquote(row[key]);assert file.is_file()
            with Image.open(file) as im:im.verify()
            count+=1
publication=json.loads((STAGE/'publication.json').read_text('utf-8'))
for r in publication['files']:assert sha(ROOT/r['path'])==r['sha256']
guard=json.loads((STAGE/'protected-before.json').read_text('utf-8'))
for r in guard:
    path=Path(r['path']);assert (sha(path),path.stat().st_size,path.stat().st_mtime_ns)==(r['sha256'],r['bytes'],r['mtime_ns']),path
save(STAGE/'final-verification.json',{'new_game_files':len(publication['files']),'new_asset_paths':24,'image_links_verified':count,'nonresources_unchanged':True,'protected_unchanged':len(guard),'summary':p['resources']['summary']})
print(json.dumps(json.loads((STAGE/'final-verification.json').read_text('utf-8')),ensure_ascii=False))
