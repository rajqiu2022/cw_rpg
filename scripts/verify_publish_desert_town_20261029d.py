"""Final read-only proof of publication, gallery paths, sources and protected state."""
import json
import re
from pathlib import Path
from PIL import Image
from desert_town_20261029d import ROOT, RAW, STAGE, NAME
from build_redrock_town_20261028a import save, sha

def main():
    pub=json.loads((STAGE/'publication.json').read_text('utf-8'))
    for r in pub['files']:
        p=ROOT/r['path'];assert sha(p)==r['sha256'] and p.stat().st_size==r['bytes'],r['path']
    raw=json.loads((RAW/'manifest.json').read_text('utf-8'))
    assert len(raw['assets'])==14 and all(r['calls']==1 and r['status']=='RAW_CANDIDATE' for r in raw['assets'])
    for r in raw['assets']:assert sha(ROOT/r['output'])==r['sha256'] and sha(Path(r['source_path']))==r['sha256']
    pad=json.loads((STAGE/'padding-verification.json').read_text('utf-8'))
    assert len(pad['rows'])==12
    for r in pad['rows']:
        source=Image.open(ROOT/r['source']);dest=Image.open(ROOT/r['output']);x,y=r['offset'];w,h=source.size
        assert dest.crop((x,y,x+w,y+h)).tobytes()==source.tobytes()
        assert r['raw_A1_pass'] is False and r['padded_A1_pass'] is True
    html=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
    data=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',html)[1])
    before=json.loads((STAGE/'catalog-nonresources-before.json').read_text('utf-8'))
    assert {k:v for k,v in data.items() if k!='resources'}==before
    rows=[r for r in data['resources']['records'] if NAME in r['diskPath']]
    assert len(rows)==40,len(rows)
    for r in rows:
        assert (ROOT/r['diskPath']).is_file() and (ROOT/'docs'/r['thumbnail']).is_file()
        assert r['sha256']==sha(ROOT/r['diskPath'])
        with Image.open(ROOT/'docs'/r['thumbnail']) as im:im.load()
        assert r['group'].startswith('沙漠城镇 /')
        for u in r['usage']:assert 'desert_town_20261029d/desert_town.tscn' in u['label']
    changed=[]
    protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'))
    for r in protected:
        p=Path(r['path'])
        if (sha(p),p.stat().st_size,p.stat().st_mtime_ns)!=(r['sha256'],r['bytes'],r['mtime_ns']):changed.append(r['path'])
    assert not changed,changed
    report={'passed':True,'published_files_exact':len(pub['files']),'raw_native_calls':14,'raw_native_sources_exact':14,
        'padded_RGBA_exact':12,'new_gallery_paths_thumbnails_and_groups':len(rows),'gallery':data['resources']['summary'],
        'nonresources_payload_exact':True,'protected_SHA_bytes_mtime_exact':len(protected),'protected_changes':changed,
        'raw_A1_failures_retained':True,'formal_world_enabled':False,'scene_sha256':pub['scene_sha256']}
    save(STAGE/'verification-published.json',report)
    print(json.dumps(report,ensure_ascii=False))

if __name__=='__main__':main()
