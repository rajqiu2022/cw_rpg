"""Default: in-memory dry plan only. No RAW writes, no generated bitmap edits.
Execution is blocked until Root supplies a separately pinned batch permission.
"""
from pathlib import Path
import argparse, hashlib, json, math
import numpy as np
from PIL import Image
from scipy import ndimage

G = Path(__file__).resolve().parents[3]
RAW = G / 'assets/raw/luoyang_city_rebuild_20261027d'
OUT = Path(__file__).resolve().parent / 'three_RAW_cleanup08_ROOT_ONLY_OUTPUT'
FIXED = {
 'east_shop_residence_v1': ('68a9501e4a8cf74742d01e0169c7fd92e8408f2c12e897eae9586d42daee6ee3', [106,137,1136,1213]),
 'west_shop_residence_v1': ('0ecc57a5a83f05cc589ff1fcf3fb4cef483cb479a3bda9e6b2e660f2343f92b5', [54,98,1132,1246]),
 'spring_house_complete_v1': ('64a50beb1ca3e23d53d209a3b391c911ce5c061dc441a1638ffb8c96ab16d5be', [70,62,1311,1056])
}
def sha(raw): return hashlib.sha256(raw).hexdigest()
def bbox(mask):
 y,x=np.nonzero(mask); assert len(x)
 return [int(x.min()),int(y.min()),int(x.max())+1,int(y.max())+1]
def prepare(id, pin, protect):
 p=RAW/(id+'.png'); raw=p.read_bytes(); assert sha(raw)==pin
 im=Image.open(p); assert im.mode=='RGBA'
 a=np.array(im); h,w=a.shape[:2]; alpha=a[:,:,3]
 labels,n=ndimage.label(alpha>0, structure=np.ones((3,3),dtype=np.uint8))
 counts=np.bincount(labels.ravel()); counts[0]=0; main=labels==counts.argmax()
 x0,y0,x1,y1=protect; region=np.zeros((h,w),dtype=bool);region[y0:y1,x0:x1]=True
 assert np.all(region[main])
 remove=(~region)&(alpha>=1)&(alpha<=3)
 # Every nonzero pixel outside fixed protection must be within allowed weak range.
 assert np.all(remove[(alpha>0)&(~region)])
 clean=a.copy(); clean[:,:,3][remove]=0
 assert np.array_equal(clean[:,:,:3],a[:,:,:3])
 assert np.array_equal(clean[region],a[region]) and np.array_equal(clean[main],a[main])
 assert np.array_equal(clean[~remove],a[~remove])
 restored=clean.copy();restored[:,:,3][remove]=alpha[remove];assert np.array_equal(restored,a)
 b=bbox(clean[:,:,3]>0)
 px=max(0,math.ceil(max(w*.1-b[0],b[2]-w*.9)/.8))
 py=max(0,math.ceil(max(h*.1-b[1],b[3]-h*.9)/.8))
 padded=np.zeros((h+2*py,w+2*px,4),dtype=np.uint8);padded[py:py+h,px:px+w]=clean
 assert np.array_equal(padded[py:py+h,px:px+w],clean)
 pb=bbox(padded[:,:,3]>0);ph,pw=padded.shape[:2]
 ratios=[pb[0]/pw,pb[1]/ph,(pw-pb[2])/pw,(ph-pb[3])/ph]
 assert min(ratios)>=.1
 return a,clean,padded,remove,{
  'id':id,'raw_path':str(p),'raw_sha256':pin,'raw_size':[w,h],
  'largest_8connected_A1_bbox':bbox(main),'largest_component_pixels':int(main.sum()),
  'protected_rect_xyxy':protect,'protected_all_RGBA':True,'all_RGB_unchanged':True,
  'allow_alpha_inclusive':[1,3],'expected_alpha_histogram':{str(i):int(((alpha==i)&remove).sum()) for i in [1,2,3]},
  'expected_deleted_pixels':int(remove.sum()),'complete_clean_A1':b,
  'padding_offset_px':[px,py],'padding_LTRB':[px,py,px,py],
  'padded_size':[pw,ph],'complete_padded_A1':pb,'four_margins_ratio':ratios,
  'clean_pixel_RGBA_sha256':sha(clean.tobytes()),'padded_pixel_RGBA_sha256':sha(padded.tobytes()),
  'world_invariant':'Every raw source anchor/base/door point adds exactly padding_offset_px; uniform scale and target world foot unchanged. No crop/resample/rotation.',
  'inverse':'Padded native crop equals whole clean RGBA; saved changed-alpha coordinates/values restore clean to every original RGBA byte. Original RAW is retained.'
 }

args=argparse.ArgumentParser();args.add_argument('--execute',action='store_true');args.add_argument('--permission-json');args.add_argument('--permission-sha256');opt=args.parse_args()
prepared={id:prepare(id,*value) for id,value in FIXED.items()}
if opt.execute:
 assert opt.permission_json and opt.permission_sha256, 'No permission: execution denied'
 raw=Path(opt.permission_json).read_bytes();assert sha(raw)==opt.permission_sha256.lower()
 permit=json.loads(raw);assert permit.get('approved') is True and permit.get('scope')=='ONLY_27D_THREE_RAW_OUTSIDE_WEAK_ALPHA_AND_INTEGER_PADDING'
 assert permit.get('raw_sha256')=={id:pin for id,(pin,rect) in FIXED.items()}
 assert not OUT.exists(), 'Output must be NEW and absent'
 OUT.mkdir()
 receipt={'status':'ROOT_EXECUTED_EXACT_BATCH_ONLY','permission_sha256':sha(raw),'assets':[]}
 for id,(a,clean,padded,remove,facts) in prepared.items():
  for suffix,pixels in [('clean',clean),('padded',padded)]:
   p=OUT/(id+'_'+suffix+'.png');assert not p.exists();Image.fromarray(pixels,'RGBA').save(p)
   assert np.array_equal(np.array(Image.open(p)),pixels);facts[suffix+'_PNG']={'path':str(p),'sha256':sha(p.read_bytes())}
  ys,xs=np.nonzero(remove);inverse={'source_sha256':facts['raw_sha256'],'changed_alpha':[[int(x),int(y),int(a[y,x,3])] for y,x in zip(ys,xs)]}
  p=OUT/(id+'_alpha_inverse.json');p.write_text(json.dumps(inverse,separators=(',',':'))+'\n',encoding='utf-8')
  assert sha((RAW/(id+'.png')).read_bytes())==facts['raw_sha256']
  receipt['assets'].append(facts)
 p=OUT/'receipt.json';p.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 print(json.dumps({'path':str(p),'sha256':sha(p.read_bytes())}))
else:
 assert not OUT.exists(), 'Unexpected output: do not overwrite'
 print(json.dumps({'status':'DRY_ONLY_PERMISSION_PENDING_NO_PNG_WRITES','assets':[p[4] for p in prepared.values()]},ensure_ascii=False,indent=2))
