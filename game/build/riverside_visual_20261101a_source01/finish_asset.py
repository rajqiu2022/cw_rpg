"""Authorized deterministic alpha-one cleanup only; no resynthesis or resampling."""
from pathlib import Path
from PIL import Image
import hashlib, json, shutil

ROOT = Path('F:/Code/RPG_GAME')
SOURCE = Path('C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8/exec-6c824493-a5e0-4f9a-b40e-131f8c124d92.png')
RAW = ROOT / 'assets/raw/riverside_visual_20261101a/shelter_v1.png'
OUT = ROOT / 'game/art/modules/riverside_visual_20261101a/shelter_v1.png'
REPORT = ROOT / 'game/build/riverside_visual_20261101a_source01/asset_ACTUAL.json'
BOX = (88, 170, 1470, 900)
MARGIN = 128
def sha(data): return hashlib.sha256(data).hexdigest()

assert not RAW.exists() and not OUT.exists() and not REPORT.exists(), 'NEW_OUTPUTS_ONLY'
original_bytes = SOURCE.read_bytes()
image = Image.open(SOURCE)
assert image.mode == 'RGBA' and image.size == (1536,1024), (image.mode,image.size)
original = image.tobytes()
pixels = bytearray(original)
count = 0
alpha_gt_one = image.getchannel('A').point(lambda a: 255 if a > 1 else 0)
bbox = alpha_gt_one.getbbox()
assert bbox is not None and BOX[0] <= bbox[0] and BOX[1] <= bbox[1] and BOX[2] >= bbox[2] and BOX[3] >= bbox[3], bbox
for y in range(image.height):
    for x in range(image.width):
        if BOX[0] <= x < BOX[2] and BOX[1] <= y < BOX[3]: continue
        offset = (y*image.width+x)*4+3
        if pixels[offset] == 1: pixels[offset] = 0; count += 1
clean = Image.frombytes('RGBA',image.size,bytes(pixels))
assert clean.convert('RGB').tobytes() == image.convert('RGB').tobytes(), 'RGB_CHANGED'
assert clean.crop(BOX).tobytes() == image.crop(BOX).tobytes(), 'PROTECTED_RGBA_CHANGED'
assert sum(a != b for a,b in zip(original,bytes(pixels))) == count, 'NON_ALPHA_ONE_CHANGE'
padded = Image.new('RGBA',(image.width+MARGIN*2,image.height+MARGIN*2),(0,0,0,0))
padded.paste(clean,(MARGIN,MARGIN))
assert padded.crop((MARGIN,MARGIN,MARGIN+image.width,MARGIN+image.height)).tobytes() == bytes(pixels)
RAW.parent.mkdir(parents=True,exist_ok=True);OUT.parent.mkdir(parents=True,exist_ok=True)
shutil.copyfile(SOURCE,RAW)
padded.save(OUT)
assert RAW.read_bytes() == original_bytes
report = dict(source=str(SOURCE),raw=str(RAW),runtime=str(OUT),source_sha256=sha(original_bytes),raw_sha256=sha(RAW.read_bytes()),runtime_sha256=sha(OUT.read_bytes()),source_size=list(image.size),runtime_size=list(padded.size),alpha_gt1_bbox=list(bbox),protected_bbox=list(BOX),padding=MARGIN,alpha1_outside_protected_cleared=count,source_RGB_exact=True,protected_RGBA_exact=True,source_full_rectangle_preserved_except_explicit_alpha1=True,all_original_source_pixels_present=True,raw_original_bytes_exact=True,source_rgba_sha256=sha(original),runtime_source_rect_rgba_sha256=sha(bytes(pixels)),new_generation_calls=0,resynthesis=False,resampling=False,prior_safe_assert_failure='Protectedbottom890 rejected actualalpha>1bboxbottom894 before output; expanded preservationonly bottom900.')
REPORT.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
