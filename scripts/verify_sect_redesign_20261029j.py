import json,re
from urllib.parse import unquote
from PIL import Image
from sect_redesign_20261029j import ROOT,BASE,save,sha
p=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'))[1])
assert {k:v for k,v in p.items() if k!='resources'}==json.loads((BASE/'catalog-nonresources-before.json').read_text('utf-8'))
rows={r['diskPath']:r for r in p['resources']['records']}
for asset in json.loads((BASE/'manifest.json').read_text('utf-8'))['assets']:
    row=rows[asset['output']];assert row['usageCount']==0 and asset['sha256']==sha(ROOT/asset['output'])
    for field in ['thumbnail','url']:
        path=ROOT/'docs'/unquote(row[field]);assert path.is_file()
        with Image.open(path) as im:im.verify()
save(BASE/'verification.json',{'native_designs':2,'game_consumers':0,'gallery_full_and_thumbnail_paths':4,'nonresources_unchanged':True,'summary':p['resources']['summary']})
print('2designs/4image links verified; nonresources unchanged; 0game consumers')
