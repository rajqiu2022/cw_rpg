"""Read-only final source/media/catalog check; no extra engine run."""
import ast
import json
import re
from pathlib import Path

from PIL import Image
from build_redrock_town_20261028a import ROOT, save, sha
from redrock_city_life_20261029a import STAGE

publication=json.loads((STAGE/'publication.json').read_text('utf-8'))
for row in publication['files']:
    p=ROOT/row['path']
    assert sha(p)==row['sha256'] and p.stat().st_size==row['bytes'],row['path']
protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'))
for row in protected:
    p=Path(row['path'])
    assert sha(p)==row['sha256'] and p.stat().st_size==row['bytes'] and p.stat().st_mtime_ns==row['mtime_ns'],row['path']
html=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
payload=json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',html,re.S)[1])
records=payload['resources']['records']
rows=[r for r in records if 'redrock_city_life_20261029a' in r['diskPath']]
assert len(rows)==2
for r in rows:
    assert (ROOT/r['diskPath']).is_file() and r['usageCount']==1
    thumb=ROOT/'docs'/r['thumbnail']
    assert thumb.is_file()
    with Image.open(thumb) as im:im.verify()
assert 'openLightbox' in html or 'lightbox' in html
for name in ['build_resource_gallery.py','build_resource_reuse_index.py','redrock_city_life_20261029a.py','build_redrock_city_life_20261029a.py']:
    ast.parse((ROOT/'scripts'/name).read_text('utf-8'))
save(STAGE/'final-handoff.json',{'passed':True,'published_files_exact':len(publication['files']),
     'protected_sha_bytes_mtime_exact':len(protected),'protected_save_files':sum('save' in Path(r['path']).name for r in protected),
     'catalog_total':len(records),'catalog_images':sum(r['media']=='image' for r in records),
     'catalog_audio':sum(r['media']=='audio' for r in records),'new_catalog_paths_and_thumbnails':2,
     'thumbnail_decode':True,'existing_lightbox_markup_retained':True,'browser_actual_click_test':False,
     'equipment_count':len(payload['equipment']),'skills_count':len(payload['skills']),
     'scene_sha256':publication['scene_after_sha256'],'only_existing_game_file_changed':publication['changed_existing_files'],
     'new_art_backend':'builtin_image_gen','new_art_calls':1,'native_png_processing':False,
     'audio_driver_for_validation':'Dummy explicitly selected; audio not tested'})
print('Final handoff PASS; publication/protected/native paths/2 thumbnails exact')
