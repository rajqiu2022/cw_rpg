"""Read-only evidence for the new desert city design and resource-only sync."""
import ast
import json
import re
from pathlib import Path
from PIL import Image
from desert_town_design_20261029c import ROOT, RAW, STAGE
from build_redrock_town_20261028a import sha, save

protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'))
for row in protected:
    p=Path(row['path'])
    assert sha(p)==row['sha256'] and p.stat().st_size==row['bytes'] and p.stat().st_mtime_ns==row['mtime_ns'],row['path']
manifest=json.loads((RAW/'manifest.json').read_text('utf-8'))
r=manifest['items']['desert']
assert r['calls']==1 and sha(ROOT/r['output'])==r['sha256']==sha(Path(r['source_path']))
assert sha(ROOT/r['prompt'])==r['prompt_sha256']
with Image.open(ROOT/r['output']) as im:
    assert list(im.size)==r['size'] and im.mode==r['mode']
    im.verify()
html=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
payload=json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',html,re.S)[1])
before=json.loads((STAGE/'catalog-nonresources-before.json').read_text('utf-8'))
assert {k:v for k,v in payload.items() if k!='resources'}==before
records=payload['resources']['records']
new=[x for x in records if 'desert_town_design_20261029c' in x['diskPath']]
assert len(new)==1 and new[0]['category']=='design' and new[0]['usageCount']==0
thumb=ROOT/'docs'/new[0]['thumbnail']
with Image.open(thumb) as im:im.verify()
for name in ['build_resource_gallery.py','build_resource_reuse_index.py','desert_town_design_20261029c.py']:
    ast.parse((ROOT/'scripts'/name).read_text('utf-8'))
save(STAGE/'verification.json',{'passed':True,'protected_sha_bytes_mtime_exact':len(protected),
    'native_source_prompt_meta_exact':True,'builtin_calls':1,'new_design_gallery_records':1,
    'thumbnail_decode':True,'new_design_game_consumers':0,'nonresources_data_exact':True,
    'total':len(records),'images':sum(x['media']=='image' for x in records),'audio':sum(x['media']=='audio' for x in records),
    'no_game_or_engine_writes':True,'browser_click_test':False,'formal_city_id_created':False})
print('PASS: one new design, source/thumbnail exact, nonresources unchanged, Redrock and shared sources exact')
