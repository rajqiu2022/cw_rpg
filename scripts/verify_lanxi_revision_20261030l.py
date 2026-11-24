from lanxi_revision_20261030l import *
def nodes(s):
 d={}
 for b in re.split(r'(?=\[node )',s)[1:]:
  h=b.splitlines()[0];n=re.search(r'name="([^"]+)"',h)[1];pm=re.search(r'parent="([^"]+)"',h);key=(pm[1]+'/' if pm else '')+n;d[key]=b.strip()
 return d
old=nodes((STAGE/'backup'/OLD).read_text('utf-8'));new=nodes((GAME/OLD).read_text('utf-8'));changed=[k for k in old.keys()&new.keys() if old[k]!=new[k]];removed=old.keys()-new.keys();added=new.keys()-old.keys()
expected={'Town/'+n for n in json.loads((QA/'moved_objects.json').read_text('utf-8'))}
assert set(changed)==expected,(changed,expected)
assert len(removed)==88 and all('type="Polygon2D" parent="Terrain"' in old[k].splitlines()[0] for k in removed)
assert len(added)==166 and all('metadata/native_full_image = true' in new[k] for k in added)
for key in added:
 s=[float(v) for v in re.search(r'scale = Vector2\(([^)]+)\)',new[key])[1].split(',')];assert s[0]==s[1] and 0<s[0]<=1
bank=GAME/'art/modules/miao_recompose_20261029g/rock_bank.png';pack=json.loads(bank.with_name('resource-pack.json').read_text('utf-8'));assert sha(bank)==next(r['sha256'] for r in pack['assets'] if r['key']=='rock_bank')
from PIL import Image
import numpy as np
a=np.asarray(Image.open(QA/'ghost06_half.png')).astype(int);b=np.asarray(Image.open(QA/'ghost06_none.png')).astype(int);roi=np.max(abs(a-b),axis=2)[490:600,770:830]
save(STAGE/'static-final.json',{'changed_roots':changed,'removed_deformed_faces':len(removed),'added_native_banks':len(added),'all_banks_uniform_scale_no_upscale':True,'original_ramp_collision_and_platform_nodes_exact':True,'bank_png_exact_original_sha':sha(bank),'ghost_render_pixel_probe':{'changed_pixels_above_2':int((roi>2).sum()),'max_difference':int(roi.max()),'basis':'frozen scene half-alpha / hidden overlay; no PNG processing'}})
print('static passed',len(changed),len(removed),len(added),'pixelprobe',int((roi>2).sum()))
