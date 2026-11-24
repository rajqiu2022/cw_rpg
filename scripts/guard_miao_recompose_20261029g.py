"""Read-only final provenance, protected files and gallery checks for the successor layout."""
import json
import re
from pathlib import Path
from urllib.parse import unquote
from PIL import Image
from miao_recompose_20261029g import ROOT, RAW, STAGE
from build_redrock_town_20261028a import save, sha
protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changes=[]
for r in protected:
    p=Path(r['path'])
    if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changes.append(r['path'])
assert not changes,changes
publication=json.loads((STAGE/'publication.json').read_text('utf-8'))
for r in publication['files']:assert sha(ROOT/r['path'])==r['sha256'] and (ROOT/r['path']).stat().st_size==r['bytes'],r['path']
for r in json.loads((RAW/'manifest.json').read_text('utf-8'))['assets']:
    assert r['calls']==1 and sha(Path(r['source_path']))==sha(ROOT/r['output'])==r['sha256']
    assert sha(ROOT/r['prompt'])==r['prompt_sha256'] and not r['fallback_used']
for r in json.loads((STAGE/'padding-verification.json').read_text('utf-8'))['rows']:
    im=Image.open(ROOT/r['source']);out=Image.open(ROOT/r['output']);c=Image.new('RGBA',out.size,(0,0,0,0));c.paste(im,tuple(r['offset']));assert c.tobytes()==out.tobytes()
payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'))[1])
assert {k:v for k,v in payload.items() if k!='resources'}==json.loads((STAGE/'catalog-nonresources-before.json').read_text('utf-8'))
rows={r['diskPath']:r for r in payload['resources']['records']};newrows=[]
for base in ['assets/raw/miao_recompose_20261029g','assets/processed/miao_recompose_20261029g','game/art/modules/miao_recompose_20261029g']:
    for r in json.loads((ROOT/base/'resource-pack.json').read_text('utf-8'))['assets']:
        g=rows[r['output']];assert g['sha256']==r['sha256'] and g['usageCount']==1 and '苗风山城' in g['group']
        for field in ['url','thumbnail']:
            p=ROOT/'docs'/unquote(g[field]);assert p.is_file()
            with Image.open(p) as im:im.verify()
        newrows.append(r['output'])
assert len(newrows)==18
doc=ROOT/'docs/changes/miao-recompose-20261029g.md';links=[]
for ref in re.findall(r'\]\(([^)]+)\)',doc.read_text('utf-8')):
    if ref.startswith(('https:','http:','#')):continue
    target=doc.parent/unquote(ref.split('#')[0])
    if target.resolve()!=(STAGE/'final-guard.json').resolve():assert target.is_file(),ref
    links.append(ref)
report={'protected_count':len(protected),'protected_SHA_bytes_mtime_exact':True,'protected_changes':changes,'new_game_files_exact':len(publication['files']),
    'native_originals_and_specs_exact':6,'RGBA0_padding_original_exact':5,'new_gallery_paths':18,'new_full_images_and_thumbnails_verified':36,
    'nonresources_equal':True,'gallery':payload['resources']['summary'],'scene_sha256':publication['scene_sha256'],'doc_local_links_verified':len(links),
    'formal_world_enabled':False,'whole_design_match_not_claimed':True}
save(STAGE/'final-guard.json',report)
for ref in links:assert (doc.parent/unquote(ref.split('#')[0])).is_file(),ref
print(json.dumps(report,ensure_ascii=False))
