import hashlib
import json
import re
import shutil
from pathlib import Path
from PIL import Image
import numpy as np

work = Path("game/build/menu_buttons_20261109")
inputs = json.loads((work / "sources.json").read_text(encoding="utf-8-sig"))
batch = "menu_buttons_20261109"
art = Path("art/ui") / batch
runtime = Path("game") / art
archive = Path("assets/raw/ui") / batch
import_target = work / "import_project" / art
for folder in (runtime, archive, import_target):
    folder.mkdir(parents=True,exist_ok=True)

regions = {
    "system": [[73,264,877,204],[73,550,877,204],[73,837,877,204],[73,1124,877,204]],
    "hud": [[200,53,1136,204],[200,295,1136,204],[200,535,1136,204],[200,774,1136,204]],
    "compact": [[420,47,695,208],[420,280,695,208],[420,516,695,208],[420,754,695,208]],
    "action": [[37,394,450,314],[538,394,450,314],[37,830,450,314],[538,830,450,314]],
}
build = "extends RefCounted\n\nconst SHEETS := {\n"
for name in regions:
    build += f'\t"{name}": preload("res://{art.as_posix()}/{name}.png"),\n'
build += "}\n\n# The four original cells are normal, hover, pressed, and disabled.\nconst REGIONS := {\n"
for name, frames in regions.items():
    source = Path(inputs["paths"][name])
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    with Image.open(source) as image:
        alpha = np.asarray(image.convert("RGBA"))[:,:,3]
        safe = np.zeros_like(alpha,dtype=bool)
        for x,y,w,h in frames:
            cell = alpha[y:y+h,x:x+w]
            assert cell.shape==(h,w) and np.percentile(cell,35)>230
            assert np.percentile(cell[[0,-1]],99)<40
            assert np.percentile(cell[:,[0,-1]],99)<40
            safe[y:y+h,x:x+w]=True
        assert not np.any(alpha[~safe] >= 96)
        size = list(image.size)
    meta = {
        "backend":"builtin_image_gen","model":None,"provider":None,"fallback_used":False,
        "prompt":inputs["prompts"][name], "size":size, "transparent_background":True,
        "sha256":digest,"regions":frames,"runtime":str((runtime/(name+".png")).as_posix())
    }
    for folder in (runtime,archive,import_target):
        shutil.copyfile(source,folder/(name+".png"))
    (archive/(name+".meta.json")).write_text(json.dumps(meta,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    build += '\t"'+name+'": ['+", ".join("Rect2("+", ".join(map(str,frame))+")" for frame in frames)+"],\n"
(runtime/"atlas_data.gd").write_text(build+"}\n",encoding="utf-8")

