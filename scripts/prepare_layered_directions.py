"""Byte-preserving import of built-in generated direction candidates. No pixel editing."""
import hashlib,json,shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
raw=ROOT/'assets/raw/layered_actor_20261106'
runtime=ROOT/'game/art/characters/layered_actor_20261106'
path=raw/'directions_generation.json'
data=json.loads(path.read_text(encoding='utf-8'))
for row in data['records']+data['rejected']:
    src=Path(row['source']); dst=raw/(row['key']+'.png')
    if dst.exists(): assert dst.read_bytes()==src.read_bytes(),str(dst)
    else: shutil.copyfile(src,dst)
    with Image.open(src) as im:
        row.update(size=list(im.size),mode=im.mode,alpha_extrema=list(im.getchannel('A').getextrema()))
        print(row['key'],im.size,im.getchannel('A').getextrema(), 'corner', im.getpixel((0,0)))
    row.update(raw=dst.relative_to(ROOT).as_posix(),sha256=hashlib.sha256(src.read_bytes()).hexdigest(),backend='builtin_image_gen',model=None,provider=None,processing='Byte-identical copies; no crop, resize, alpha cleanup or local pixel edits.')
    if row in data['records']:
        target=runtime/dst.name
        if target.exists(): assert target.read_bytes()==src.read_bytes()
        else: shutil.copyfile(src,target)
        row['runtime']=target.relative_to(ROOT).as_posix()
        row['status']='prototype_not_formal_adopted'
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
