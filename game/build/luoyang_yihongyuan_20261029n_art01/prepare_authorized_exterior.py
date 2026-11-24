"""Apply the user's standing alpha=1 outside-subject cleanup and RGBA0 padding only."""
from pathlib import Path
import hashlib, json
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[3]
SRC = ROOT / 'assets/raw/luoyang_yihongyuan_20261029n/yihongyuan_exterior_v1.png'
DST = ROOT / 'assets/processed/luoyang_yihongyuan_20261029n/yihongyuan_exterior_v1_padded.png'
EXPECTED = 'e80f44f0a1cc9779bb375d0f77a96131befe73b6ff98d28e7ae2356f047b57dd'
assert hashlib.sha256(SRC.read_bytes()).hexdigest() == EXPECTED
assert not DST.exists(), 'Do not overwrite a previous processed candidate.'
im = Image.open(SRC)
assert im.mode == 'RGBA' and im.size == (1377, 1142)
box = (134, 110, 1246, 1008)
clean = im.copy()
pixels = clean.load()
changed = 0
for y in range(im.height):
    for x in range(im.width):
        if box[0] <= x < box[2] and box[1] <= y < box[3]:
            continue
        r,g,b,a = pixels[x,y]
        assert a in (0,1), (x,y,a)
        if a == 1:
            pixels[x,y] = (r,g,b,0)
            changed += 1
assert changed == 399
assert ImageChops.difference(im.convert('RGB'),clean.convert('RGB')).getbbox() is None
assert ImageChops.difference(im.crop(box),clean.crop(box)).getbbox() is None
pad = 32
out = Image.new('RGBA',(im.width+2*pad,im.height+2*pad),(0,0,0,0))
out.paste(clean,(pad,pad))
assert out.crop((pad,pad,pad+im.width,pad+im.height)).tobytes() == clean.tobytes()
alpha_box = out.getchannel('A').getbbox()
margins = [alpha_box[0]/out.width,alpha_box[1]/out.height,(out.width-alpha_box[2])/out.width,(out.height-alpha_box[3])/out.height]
assert min(margins) >= .10
DST.parent.mkdir(parents=True, exist_ok=True)
out.save(DST)
receipt = {'status':'ACTUAL_AUTHORIZED_ALPHA1_AND_PADDING_ONLY','raw_path':str(SRC.relative_to(ROOT)),'raw_sha256':EXPECTED,'raw_size_px':list(im.size),'subject_protection_box':box,'outside_alpha1_removed':changed,'all_original_RGB_preserved':True,'protected_RGBA_preserved':True,'padding_offset_px':[pad,pad],'output_path':str(DST.relative_to(ROOT)),'output_size_px':list(out.size),'output_sha256':hashlib.sha256(DST.read_bytes()).hexdigest(),'nonzero_bbox':alpha_box,'four_margins_ratio':margins,'no_resize_rotation_crop_repaint':True}
(Path(__file__).parent/'exterior_processing_actual.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt,ensure_ascii=False))
