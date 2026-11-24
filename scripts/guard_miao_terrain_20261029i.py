"""Read-only closeout: new scene, preserved sources/saves and categorized gallery links."""
import json
import re
from pathlib import Path
from urllib.parse import unquote
from PIL import Image
from build_miao_terrain_20261029i import ROOT, STAGE, PROJECT, NAME, ART, SCENE
from build_redrock_town_20261028a import save, sha

before=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changed=[]
for r in before:
    p=Path(r['path'])
    if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changed.append(r['path'])
assert not changed,changed
publication=json.loads((STAGE/'publication.json').read_text('utf-8'))
for r in publication['files']:
    p=ROOT/r['path'];assert sha(p)==r['sha256'] and p.stat().st_size==r['bytes']
pack=json.loads((ROOT/'game'/ART/'resource-pack.json').read_text('utf-8'))
payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'))[1])
assert {k:v for k,v in payload.items() if k!='resources'}==json.loads((STAGE/'catalog-nonresources-before.json').read_text('utf-8'))
rows={r['diskPath']:r for r in payload['resources']['records']};checked=[]
for family,keys in pack['reused_asset_keys'].items():
    oldpack=json.loads((ROOT/'game/art/modules'/family/'resource-pack.json').read_text('utf-8'))
    for r in oldpack['assets']:
        if r['key'] not in keys:continue
        assert sha(ROOT/r['output'])==r['sha256']==sha(PROJECT/r['destination'])
        for base in ['assets/raw/'+family,'assets/processed/'+family,'game/art/modules/'+family]:
            prior=json.loads((ROOT/base/'resource-pack.json').read_text('utf-8'))
            entry=next(item for item in prior['assets'] if item['key']==r['key'])
            row=rows[entry['output']]
            assert row['sha256']==entry['sha256'] and any(pack['scene'] in x['label'] for x in row['usage']),entry['output']
            for field in ['thumbnail','url']:
                p=ROOT/'docs'/unquote(row[field]);assert p.is_file()
                with Image.open(p) as im:im.verify()
            checked.append(entry['output'])
preview=json.loads((ROOT/'assets/previews'/NAME/'manifest.json').read_text('utf-8'))
for row in preview['shots']:assert sha(ROOT/row['output'])==sha(ROOT/row['source'])==row['sha256']
for row in json.loads((STAGE/'existing-dependencies-exact.json').read_text('utf-8'))['files']:
    assert sha(ROOT/'game'/row['path'])==row['sha256']
links=[];doc=ROOT/'docs/changes/miao-terrain-20261029i.md'
for link in re.findall(r'\]\(([^)]+)\)',doc.read_text('utf-8')):
    if link.startswith(('http:','https:','#')):continue
    assert (doc.parent/unquote(link.split('#')[0])).is_file(),link;links.append(link)
report={'protected_files':len(before),'SHA_bytes_exact_mtime_unchanged':True,'protected_changes':changed,
    'new_game_files_exact':len(publication['files']),'new_resource_PNG':0,'new_import_leaves':0,
    'reused_native_PNG':sum(len(v) for v in pack['reused_asset_keys'].values()),'current_gallery_paths':len(checked),
    'full_image_and_thumbnail_paths_verified':len(checked)*2,'nonresources_equal':True,'gallery':payload['resources']['summary'],
    'screenshots_native_exact':len(preview['shots']),'doc_links_verified':len(links),'scene_sha256':publication['scene_sha256'],
    'formal_world_enabled':False,'whole_city_final_ART':False}
save(STAGE/'final-guard.json',report);print(json.dumps(report,ensure_ascii=False))
