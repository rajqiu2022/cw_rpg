import json,re
from pathlib import Path
from urllib.parse import unquote
from PIL import Image
from sect_remaining_designs_20261029l import ROOT,BASE,save,sha

html=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
p=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',html)[1])
assert {k:v for k,v in p.items() if k!='resources'}==json.loads((BASE/'catalog-nonresources-before.json').read_text('utf-8'))
rows={r['diskPath']:r for r in p['resources']['records']}
checked=[]
for asset in json.loads((BASE/'manifest.json').read_text('utf-8'))['assets']:
    row=rows[asset['output']]
    assert row['usageCount']==0 and row['category']=='design' and asset['calls']==1
    assert asset['sha256']==sha(ROOT/asset['output'])==sha(Path(asset['source_path']))
    assert sha(ROOT/asset['prompt'])==asset['prompt_sha256']
    for field in ['thumbnail','url']:
        path=ROOT/'docs'/unquote(row[field]);assert path.is_file()
        with Image.open(path) as im:im.verify()
    checked.append({'key':asset['key'],'group':row['group'],'size':asset['size'],'sha256':asset['sha256']})
save(BASE/'verification.json',{'native_designs':3,'game_consumers':0,'gallery_full_and_thumbnail_paths':6,'nonresources_unchanged':True,'summary':p['resources']['summary'],'assets':checked,'scope':'source bytes, prompt bytes, gallery category and image links; not engine validation'})
print(json.dumps({'designs':3,'image_links':6,'nonresources_unchanged':True,'summary':p['resources']['summary'],'assets':checked},ensure_ascii=False))
