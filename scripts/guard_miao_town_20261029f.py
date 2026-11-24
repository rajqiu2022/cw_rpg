"""Read-only publication, native provenance, gallery and protected-state closeout."""
import json
import re
from pathlib import Path
from urllib.parse import unquote
from PIL import Image
from miao_town_20261029f import ROOT, RAW, STAGE, PROJECT
from build_redrock_town_20261028a import save, sha

def main():
    publication=json.loads((STAGE/'publication.json').read_text('utf-8'))
    protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changes=[]
    for r in protected:
        p=Path(r['path'])
        if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changes.append(r['path'])
    assert not changes,changes
    for r in publication['files']:assert sha(ROOT/r['path'])==r['sha256'] and (ROOT/r['path']).stat().st_size==r['bytes'],r['path']
    raw=json.loads((RAW/'manifest.json').read_text('utf-8'))['assets'];assert len(raw)==26
    for r in raw:
        assert r['calls']==1 and sha(Path(r['source_path']))==sha(ROOT/r['output'])==r['sha256']
        assert sha(ROOT/r['prompt'])==r['prompt_sha256'] and not r['fallback_used']
    html=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
    payload=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',html)[1])
    other={k:v for k,v in payload.items() if k!='resources'}
    assert other==json.loads((STAGE/'catalog-nonresources-before.json').read_text('utf-8'))
    gallery=payload['resources'];records=gallery['records'];wanted=[]
    for base in ['assets/raw/miao_town_20261029f','assets/processed/miao_town_20261029f','game/art/modules/miao_town_20261029f']:
        wanted+=json.loads((ROOT/base/'resource-pack.json').read_text('utf-8'))['assets']
    assert len(wanted)==78
    # Gallery records carry repository-relative diskPath, full image URL and independent preview URL.
    bypath={r['diskPath']:r for r in records}
    for r in wanted:
        g=bypath[r['output']];assert g['sha256']==r['sha256'] and g['usageCount']>=1 and '苗风山城' in g['group']
        for field in ['url','thumbnail']:
            q=ROOT/'docs'/unquote(g[field]);assert q.is_file(),(field,g[field])
            with Image.open(q) as im:im.verify()
    summary=gallery['summary'];assert summary['total']==len(records)
    doc=ROOT/'docs/changes/miao-town-20261029f.md';doc_links=[]
    for ref in re.findall(r'\]\(([^)]+)\)',doc.read_text('utf-8')):
        if ref.startswith(('http:','https:','#')):continue
        target=doc.parent/unquote(ref.split('#')[0]);assert target.is_file(),ref
        doc_links.append(ref)
    report={'protected_count':len(protected),'protected_SHA_bytes_mtime_exact':True,'protected_changes':changes,
        'new_game_files_exact':len(publication['files']),'native_sources_prompt_and_builtin_outputs_exact':26,
        'new_gallery_paths':78,'new_full_images_and_thumbnails_verified':156,'nonresources_equal':True,'gallery':summary,
        'scene_sha256':publication['scene_sha256'],'explicit_missing_reuse_paths':0,'change_doc_local_links_verified':len(doc_links),'formal_world_enabled':False}
    save(STAGE/'final-guard.json',report);print(json.dumps(report,ensure_ascii=False))

if __name__=='__main__':main()
