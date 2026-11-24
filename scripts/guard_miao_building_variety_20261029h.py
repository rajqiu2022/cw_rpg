"""Read-only native provenance, inherited geometry, publication and gallery closeout."""
import json
import re
from pathlib import Path
from urllib.parse import unquote
from PIL import Image
from miao_building_variety_20261029h import ROOT, RAW, STAGE, SCENE
from build_redrock_town_20261028a import save, sha
protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changes=[]
for r in protected:
    p=Path(r['path'])
    if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changes.append(r['path'])
assert not changes,changes
publication=json.loads((STAGE/'publication.json').read_text('utf-8'))
for r in publication['files']:assert sha(ROOT/r['path'])==r['sha256'] and (ROOT/r['path']).stat().st_size==r['bytes'],r['path']
for r in json.loads((RAW/'manifest.json').read_text('utf-8'))['assets']:
    assert r['calls']==1 and sha(Path(r['source_path']))==sha(ROOT/r['output'])==r['sha256'] and sha(ROOT/r['prompt'])==r['prompt_sha256'] and not r['fallback_used']
for r in json.loads((STAGE/'padding-verification.json').read_text('utf-8'))['rows']:
    im=Image.open(ROOT/r['source']);out=Image.open(ROOT/r['output']);c=Image.new('RGBA',out.size,(0,0,0,0));c.paste(im,tuple(r['offset']));assert c.tobytes()==out.tobytes()
old=(ROOT/'game/scenes/drafts/miao_recompose_20261029g/miao_town.tscn').read_text('utf-8');new=(ROOT/'game'/SCENE).read_text('utf-8')
inherited=[]
for name,parent in [('HouseHall','.'),('GateBridge','Town'),('MiddleBridge','Town'),('UpperBridge','Town'),('Stairs1','Town'),('Stairs2','Town'),('Stairs3','Town'),('Stairs4','Town')]:
    def subtree(text):
        result=[];prefix=name if parent=='.' else parent+'/'+name
        for b in re.split(r'(?=\[node )',text):
            h=b.splitlines()[0] if b else ''
            if (f'name="{name}" type=' in h and f'parent="{parent}"' in h) or re.search(r'parent="'+re.escape(prefix)+r'(?:/|")',h):result.append(b.rstrip())
        return result
    assert subtree(old)==subtree(new) and subtree(new),name;inherited.append(name)
payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8'))[1])
assert {k:v for k,v in payload.items() if k!='resources'}==json.loads((STAGE/'catalog-nonresources-before.json').read_text('utf-8'))
rows={r['diskPath']:r for r in payload['resources']['records']};newrows=[]
for base in ['assets/raw/miao_building_variety_20261029h','assets/processed/miao_building_variety_20261029h','game/art/modules/miao_building_variety_20261029h']:
    for r in json.loads((ROOT/base/'resource-pack.json').read_text('utf-8'))['assets']:
        g=rows[r['output']];assert g['sha256']==r['sha256'] and g['usageCount']==1 and '苗风山城' in g['group']
        for field in ['url','thumbnail']:
            p=ROOT/'docs'/unquote(g[field]);assert p.is_file()
            with Image.open(p) as im:im.verify()
        newrows.append(r['output'])
assert len(newrows)==15
report={'protected_count':len(protected),'protected_SHA_bytes_mtime_exact':True,'protected_changes':changes,'new_game_files_exact':len(publication['files']),
    'native_originals_prompts_exact':5,'RGBA0_padding_original_exact':5,'inherited_subtrees_exact':inherited,'new_gallery_paths':15,'new_full_images_and_thumbnails_verified':30,
    'nonresources_equal':True,'gallery':payload['resources']['summary'],'scene_sha256':publication['scene_sha256'],'formal_world_enabled':False,'whole_city_final_ART':False}
save(STAGE/'final-guard.json',report)
doc=ROOT/'docs/changes/miao-building-variety-20261029h.md';links=[]
for ref in re.findall(r'\]\(([^)]+)\)',doc.read_text('utf-8')):
    if ref.startswith(('https:','http:','#')):continue
    assert (doc.parent/unquote(ref.split('#')[0])).is_file(),ref
    links.append(ref)
report['doc_local_links_verified']=len(links);save(STAGE/'final-guard.json',report);print(json.dumps(report,ensure_ascii=False))
