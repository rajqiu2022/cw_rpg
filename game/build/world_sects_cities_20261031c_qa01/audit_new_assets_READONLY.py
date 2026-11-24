from pathlib import Path
from PIL import Image
import json, hashlib
root=Path('F:/Code/RPG_GAME')
rows=[]
for p in sorted((root/'game/art/modules/environment_repair_20261031c').glob('*.png')):
    im=Image.open(p).convert('RGBA'); a=im.getchannel('A'); h=a.histogram()
    raw=root/'assets/raw/environment_repair_20261031c'/p.name
    rows.append(dict(path=p.as_posix(),raw=raw.as_posix(),bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),raw_byte_same=p.read_bytes()==raw.read_bytes(),size=im.size,alpha_extrema=a.getextrema(),alpha8_bbox=a.point(lambda n:255 if n>=8 else 0).getbbox(),alpha128_bbox=a.point(lambda n:255 if n>=128 else 0).getbbox(),alpha1_count=h[1],sample_alpha=[a.getpixel(xy) for xy in [(0,0),(64,64),(im.width//2,0),(im.width//2,64),(im.width//2,im.height-32)]]))
print(json.dumps(rows,ensure_ascii=False))
