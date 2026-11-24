"""Read-only native anchor projection; writes new pending JSON in this namespace.

Not a game writer or engine test. Root must approve real GPU presentation and
seal actual PNG/import/ctex receipts before these profiles become deployable.
"""
from pathlib import Path
import argparse,hashlib,json,math,struct

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[2]
GAME=REPO/'game'
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def add(a,b):return [a[0]+b[0],a[1]+b[1]]
def sub(a,b):return [a[0]-b[0],a[1]-b[1]]
def mul(a,s):return [a[0]*s,a[1]*s]
def mid(a,b):return mul(add(a,b),.5)
def length(a):return math.hypot(*a)
def angle(a):return math.atan2(a[1],a[0])
def rotate(a,r):return [a[0]*math.cos(r)-a[1]*math.sin(r),a[0]*math.sin(r)+a[1]*math.cos(r)]
def dot(a,b):return a[0]*b[0]+a[1]*b[1]
def lerp(a,b,t):return add(a,mul(sub(b,a),t))
def png_size(p):
 b=Path(p).read_bytes()[:24]
 assert b[:8]==b'\x89PNG\r\n\x1a\n'
 return list(struct.unpack('>II',b[16:24]))

ap=argparse.ArgumentParser()
ap.add_argument('--geometry',required=True)
ap.add_argument('--out',required=True)
ap.add_argument('--root-adopt-bridge04-geometry-sha',default='')
args=ap.parse_args()
out=(HERE/args.out).resolve()
assert out.parent==HERE and not out.exists()
geometry=read(args.geometry)
inventory=read(HERE/'bridge_inventory_READY.json')
source={r['id']:r for r in read(HERE/'bridge_source_rows_READY.json')['rows']}
profiles=[];pending=[]
for i,old in enumerate(inventory['bridges']):
 bid=old['id']; measured=geometry['bridges'][i]
 assert measured['id']==bid
 if bid=='bridge_04' and args.root_adopt_bridge04_geometry_sha.lower()!=sha(args.geometry):
  pending.append({'id':bid,'reason':'ROOT_EXPLICIT_ADOPTION_REQUIRED_V1_V2_V3_REJECTED_ASPECT','geometry_sha256':sha(args.geometry)})
  continue
 path=GAME/'art/modules/world_bridges_20261030m'/f'{bid}.png'
 size=png_size(path)
 assert size==measured['padded_size']
 raw=measured['deck_corners_raw']
 # Match original deck-quad end/side semantics; 04 is east->west, never
 # rotate the new PNG180 degrees just because the source dict lists west first.
 order=[0,1,2,3] if i==0 else ([2,3,0,1] if i==4 else [1,2,3,0])
 quad=[add(raw[j],[256,256]) for j in order]
 sa=mid(quad[0],quad[3]);sb=mid(quad[1],quad[2])
 wa,wb=old['deck_surface_bank_centers_world_px']
 native_width=(length(sub(quad[0],quad[3]))+length(sub(quad[1],quad[2])))*.5
 # Match existing real passage width by one uniform downscale. Native extra
 # length remains inside the EXISTING outer approach, never changes NAV.
 scale=old['deck_surface_width_px']/native_width
 rot=angle(sub(wb,wa))-angle(sub(sb,sa))
 rot=(rot+math.pi)%(2*math.pi)-math.pi
 assert 0<scale<=1 and abs(math.degrees(rot))<=15
 origin=sub(mid(wa,wb),rotate(mul(mid(sa,sb),scale),rot))
 def world(p):return add(origin,rotate(mul(p,scale),rot))
 mapped=[world(p) for p in quad]
 axis=mul(sub(wb,wa),1/length(sub(wb,wa)))
 normal=[-axis[1],axis[0]]
 mapped_a=mid(mapped[0],mapped[3]);mapped_b=mid(mapped[1],mapped[2])
 t0=dot(sub(mapped_a,wa),axis);t1=dot(sub(mapped_b,wa),axis)
 passage=[dot(sub(p,wa),axis) for p in old['outer_passage_endpoints_world_px']]
 assert t0<=8 and t1>=length(sub(wb,wa))-8
 assert t0>=min(passage)-16 and t1<=max(passage)+16
 # Only the ACTUAL NEW near-rail polygon is split into three source regions.
 # The middle retains original nearrail depth; end slices use nearest original
 # nearpost foot. This is presentation only, not rail collision manufacture.
 rail_name='near_south' if i in [0,4] else 'west_left'
 rail=[add(p,[256,256]) for p in measured['rails_source_polygons_raw'][rail_name]]
 segments=[];used=set()
 for j in range(3):
  lo=j/3;hi=(j+1)/3
  poly=[lerp(rail[0],rail[1],lo),lerp(rail[0],rail[1],hi),lerp(rail[3],rail[2],hi),lerp(rail[3],rail[2],lo)] if i in [0,4] else [lerp(rail[0],rail[3],lo),lerp(rail[1],rail[2],lo),lerp(rail[1],rail[2],hi),lerp(rail[0],rail[3],hi)]
  foot_world=world(mid(poly[2],poly[3]))
  owner=old['nearrail_id'] if j==1 else min((p for p in old['nearside_post_ids'] if p not in used),key=lambda p:abs(source[p]['depth_sort_foot_y']*8192-foot_world[1]))
  used.add(owner)
  segments.append({'source_component_id':owner,'source_polygons_px':[poly],'reference_world_foot_px':foot_world,'original_depth_foot_world_y':source[owner]['depth_sort_foot_y']*8192})
 profiles.append({'id':bid,'resource':{'path':f'res://art/modules/world_bridges_20261030m/{bid}.png','sha256':sha(path),'size':size,'import_sha256':'PENDING_ROOT_IMPORT','compiled_path':'PENDING_ROOT_IMPORT','compiled_sha256':'PENDING_ROOT_IMPORT','full_RGBA_exact':False,'mipmap_count':-1},'scale':scale,'rotation_degrees':math.degrees(rot),'origin_world_px':origin,'source_deck_quad_px':quad,'foreground_parts':segments,'reference_only':{'mapped_deck_quad_world_px':mapped,'source_geometry_sha256':sha(args.geometry),'old_deck_bank_world_px':[wa,wb],'mapped_open_ends_world_px':[mapped_a,mapped_b],'source_span_px':length(sub(sb,sa)),'world_span_px':length(sub(mapped_b,mapped_a)),'world_width_mean_px':old['deck_surface_width_px'],'existing_passage_axis_px':passage,'new_deck_axis_px':[t0,t1],'manual_source_uncertainty_px':20,'not_collision_evidence':True}})
result={'schema_version':1,'status':'PENDING_ROOT_GPU_CALIBRATION_AND_NATIVE_IMPORTS_NOT_DEPLOYABLE','approved':False,'approved_by':'PENDING_ROOT','helper_sha256':sha(HERE/'bridge_visual_patch.gd'),'shader_sha256':sha(HERE/'bridge_partition.gdshader'),'overlap_sha256':sha(HERE/'world_v15_stream_overlap_20261018r_CANDIDATE.gd'),'bridges':profiles,'pending':pending,'formal_source_writes':0,'engine_runs':0,'save_access':False,'scope':'DESKTOP_ONLY_WEB_UNCHANGED','original_visuals_retired':93,'original_physical_rows_preserved':88,'nonuniform_scale':False}
data=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f:f.write(data)
print(json.dumps({'path':str(out),'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'profiles':len(profiles),'pending':pending,'scales':[{k:p[k] for k in ['id','scale','rotation_degrees']} for p in profiles]}))
