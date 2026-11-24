"""Opaque diagnostic views of RAW alpha, not processed game assets. Raw files read only."""
from pathlib import Path
import hashlib,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
SPECS=[('chinese_open_ironwork_v2','ce9eb745773590cedda2ac448aa9fa6ab03af84cf50abe5a285608822b9ff475'),('pottery_kiln_house_v2','6dcfd35123df03e5147411c820f6cbbc68dcab9eb8cad583763a067845cf983b'),('ordinary_kitchen_rear_body_v2','1f65539478c6e042bbb3726f9a281679759168589b7eb4363dc3f93c52bda935')]
rows=[]
for ident,expected in SPECS:
    p=ROOT/f'assets/raw/luoyang_city_finish_20261025i/{ident}.png';raw=p.read_bytes();before=p.stat()
    assert hashlib.sha256(raw).hexdigest()==expected
    source=Image.open(p).convert('RGBA')
    diagnostic=Image.alpha_composite(Image.new('RGBA',source.size,(225,225,220,255)),source).convert('RGB')
    out=OUT/f'{ident}_RAW_alpha_over_neutral_DIAGNOSTIC_ONLY.png'
    with out.open('xb') as f:diagnostic.save(f,format='PNG')
    assert p.read_bytes()==raw and p.stat().st_mtime_ns==before.st_mtime_ns
    rows.append(dict(raw=expected,diagnostic=str(out.relative_to(ROOT)).replace('\\','/'),sha256=hashlib.sha256(out.read_bytes()).hexdigest(),not_candidate_not_import=True))
print(json.dumps(rows))
