"""Immutable old-parent foot oracle for only declared migration examples."""
from pathlib import Path
import struct,json,hashlib
N=Path(__file__).resolve().parent;R=N.parents[2]
s=(R/'game/build/luoyang_city_finish_20261025i_source01/audit_finish8_render_texture_domains_READONLY.py').read_text();scope={'struct':struct}
exec(s[s.index('class FrozenVariant:'):s.index('binding_pin=')],scope)
raw=(R/'game/build/luoyang_yihongyuan_20261029n_system01/visual03/output/60160/luoyang_civic_market_region_27d.bin').read_bytes();d=scope['FrozenVariant'](raw).value()
def clipped(poly,box):
 out=list(poly)
 for axis,v,sign in [(0,box[0],1),(0,box[2],-1),(1,box[1],1),(1,box[3],-1)]:
  source=out;out=[]
  if not source:break
  for a,b in zip(source,source[1:]+source[:1]):
   ai=(a[axis]-v)*sign>=0;bi=(b[axis]-v)*sign>=0
   if ai:out.append(a)
   if ai!=bi:
    t=(v-a[axis])/(b[axis]-a[axis]);out.append(tuple(a[i]+t*(b[i]-a[i])for i in range(2)))
 return out
def body(p):return [p[0]-17,p[1]-12,p[0]+17,p[1]+12]
def legal(p):
 b=body(p);ys=sorted(set([b[1],b[3]]+[y for x,y,w,h in d['floor_rects']if b[1]<y<b[3]]+[y+h for x,y,w,h in d['floor_rects']if b[1]<y+h<b[3]]));ground=True
 for l,h in zip(ys,ys[1:]):
  y=(l+h)/2;at=b[0]
  for x,end in sorted((x,x+w)for x,top,w,height in d['floor_rects']if top<=y<=top+height):
   if x>at:break
   at=max(at,end)
  if at<b[2]:ground=False
 solids=[i for i,poly in enumerate(d['solids'])if clipped(poly,b)]
 return {'old_ground_full_union':ground,'old_solid_hits':solids,'old_valid_no_NPC':ground and not solids}
cases={'new_covered_cloth':(2017,3650),'old_illegal_annex':(2017,3800),'cloth_target':(2640,4280),'unchanged_xuantong_front':(2730,3930),'new_covered_side':(2490,3400)}
result={k:{'foot':p,**legal(p)}for k,p in cases.items()}
assert result['new_covered_cloth']['old_valid_no_NPC'] and not result['old_illegal_annex']['old_valid_no_NPC'] and result['cloth_target']['old_valid_no_NPC']
report={'parent_sha256':hashlib.sha256(raw).hexdigest(),'cases':result,'method':'Finite exact floor slab coverage and rect clipping of all old solids; full NPC envelopes separately audited, no engine/save API.'}
p=N/'ly_cases_READONLY.json';assert not p.exists();p.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps(report))
