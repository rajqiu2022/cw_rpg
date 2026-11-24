"""Only approved exterior-alpha1 cleanup and transparent padding; no subject/RGB edits."""
from pathlib import Path
import hashlib,json,shutil
from PIL import Image,ImageChops
ROOT=Path(__file__).resolve().parents[3]
SOURCE=Path('C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8/exec-80b82126-2bdd-4fc4-b13d-3d8616051baa.png')
RAW=ROOT/'assets/raw/luoyang_estate_garden_20261029q/lotus_pond_v1.png'
DEST=ROOT/'assets/processed/luoyang_estate_garden_20261029q/lotus_pond_v1_padded.png'
EXPECTED='c4347b60b8ce552362a3ff05b30f203a0d80a7a96c34842a0213dad2a9fb6cd2'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==EXPECTED
assert not RAW.exists() and not DEST.exists(), 'Do not overwrite candidate or original.'
im=Image.open(SOURCE)
assert im.mode=='RGBA' and im.size==(1536,1024)
box=(40,100,1520,950)
clean=im.copy()
pixels=clean.load()
count=0
for y in range(im.height):
    for x in range(im.width):
        if box[0]<=x<box[2] and box[1]<=y<box[3]:continue
        r,g,b,a=pixels[x,y]
        assert a in (0,1),(x,y,a)
        if a==1:pixels[x,y]=(r,g,b,0);count+=1
assert count==1924
assert ImageChops.difference(im.convert('RGB'),clean.convert('RGB')).getbbox() is None
assert im.crop(box).tobytes()==clean.crop(box).tobytes()
pad=128
out=Image.new('RGBA',(1792,1280),(0,0,0,0))
out.paste(clean,(pad,pad))
assert out.crop((pad,pad,pad+im.width,pad+im.height)).tobytes()==clean.tobytes()
assert max(out.getchannel('A').getdata())==254
RAW.parent.mkdir(parents=True,exist_ok=True)
DEST.parent.mkdir(parents=True,exist_ok=True)
shutil.copyfile(SOURCE,RAW)
assert hashlib.sha256(RAW.read_bytes()).hexdigest()==EXPECTED
out.save(DEST)
receipt={'status':'ACTUAL_APPROVED_FRAME_OUTSIDE_ALPHA1_AND_PADDING_ONLY','raw_path':RAW.relative_to(ROOT).as_posix(),'raw_sha256':EXPECTED,'raw_size_px':list(im.size),'subject_protection_box':box,'outside_alpha_max':1,'outside_alpha1_removed':count,'all_original_RGB_preserved':True,'protected_RGBA_preserved':True,'padding_offset_px':[pad,pad],'output_path':DEST.relative_to(ROOT).as_posix(),'output_size_px':list(out.size),'output_sha256':hashlib.sha256(DEST.read_bytes()).hexdigest(),'output_RGBA_sha256':hashlib.sha256(out.tobytes()).hexdigest(),'nonzero_bbox':out.getchannel('A').getbbox(),'max_alpha':254,'no_resize_rotation_crop_repaint':True,'hidden_RGB_halo':'Sampled apparent exterior fog has alpha=0; no visible background removal or RGB erasure applied.','engine_calls':0,'game_art_writes':0}
(Path(__file__).parent/'pond_processing_ACTUAL.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt,ensure_ascii=False))
