"""Auto-slice quest panel atlases by detecting non-white regions."""
from PIL import Image
import numpy as np
from pathlib import Path
from scipy.ndimage import binary_closing, label, find_objects

SRC_LARGE = Path("assets/raw/ui/quest/ui_quest_large_panels.png")
SRC_SMALL = Path("assets/raw/ui/quest/ui_quest_small_controls.png")
DST = Path("game/art/ui/quest")

def find_elements(img_path: Path, min_area=500, margin=6):
    img = Image.open(img_path).convert("RGB")
    arr = np.array(img).astype(float)
    diff = np.sqrt(((arr - 255) ** 2).sum(axis=2))
    binary = (diff > 40).astype(np.uint8)
    closed = binary_closing(binary, structure=np.ones((8,8)), iterations=2)
    labeled, num = label(closed)
    regions = find_objects(labeled)
    components = []
    for i, sl in enumerate(regions, 1):
        area = (labeled[sl] == i).sum()
        if area < min_area:
            continue
        min_y, max_y = sl[0].start, sl[0].stop
        min_x, max_x = sl[1].start, sl[1].stop
        w2 = max_x - min_x
        h2 = max_y - min_y
        if w2 > img.width * 0.7 or h2 > img.height * 0.7:
            continue
        components.append({
            "bbox": (max(0,min_x-margin), max(0,min_y-margin), 
                      min(img.width-max(0,min_x-margin), w2+margin*2),
                      min(img.height-max(0,min_y-margin), h2+margin*2)),
            "area": int(area),
        })
    components.sort(key=lambda c: (c["bbox"][1], c["bbox"][0]))
    return components

for name, src in [("large", SRC_LARGE), ("small", SRC_SMALL)]:
    if not src.exists():
        print(f"SKIP {src}")
        continue
    print(f"\n=== {name}: {src.name} ===")
    img = Image.open(src)
    elems = find_elements(src, min_area=400)
    print(f"Found {len(elems)} elements")
    for i, e in enumerate(elems):
        x, y, w, h = e["bbox"]
        print(f"  [{i:02d}] ({x:4d},{y:4d}) {w:4d}x{h:4d}  area={e['area']}")
    # Auto-slice
    DST.mkdir(parents=True, exist_ok=True)
    for i, e in enumerate(elems):
        x, y, w, h = e["bbox"]
        crop = img.crop((x, y, x+w, y+h))
        fname = f"auto_{name}_{i:02d}.png"
        crop.save(DST / fname)
        print(f"  saved {fname}")
print("\nDONE")
