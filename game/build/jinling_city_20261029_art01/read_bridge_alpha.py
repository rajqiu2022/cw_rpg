"""Read-only alpha measurements; no image/engine/file output."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
paths=[
    "game/art/modules/world_map_v13/bridge_stone_northsouth_v1.png",
    "game/art/modules/world_map_v13/bridge_stone_eastwest_v1.png",
    "game/art/modules/luoyang_full_city_20261022ap/bridge.png",
]
rows=[]
for key in paths:
    path=ROOT/key
    im=Image.open(path).convert("RGBA")
    a=np.asarray(im)[:,:,3]
    ys,xs=np.nonzero(a>8)
    mask=np.zeros_like(a,dtype=bool)
    mask[:,:int(im.width*.18)]=True
    mask[:,int(im.width*.82):]=True
    values,counts=np.unique(a[mask],return_counts=True)
    rows.append(dict(path=key,size=im.size,sha256=hashlib.sha256(path.read_bytes()).hexdigest(),alpha_max=int(a.max()),
        a8bbox=[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)],
        outside18pct_alpha=dict(zip(map(int,values),map(int,counts))),
        samples={str(pt):im.getpixel(pt) for pt in [(20,im.height//2),(im.width//8,im.height//2),(im.width//2,20)]}))
print(json.dumps(rows))
