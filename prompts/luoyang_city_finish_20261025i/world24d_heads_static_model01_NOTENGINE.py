"""Finite CPU design checks, not a Godot shader/mesh/render/Physics pass."""
from pathlib import Path
import json,hashlib,math
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01/world24d_heads01'
P=OUT/'project_NOTREADY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
f=json.loads((P/'input_shore_heads01_NOTREADY.json').read_bytes());a=f['shore_heads_author']
poly=np.array(f['bridge']['deck_polygon'],dtype=np.float32)
def p3(p):return np.array([(float(p[0])-6144)/a['ppm_x'],-.008,(float(p[1])-4096)/a['ppm_source_z']],dtype=np.float32)
na,nb,sa,sb=[p3(p) for p in [poly[3],poly[0],poly[2],poly[1]]]
along=(sa+sb-na-nb)*np.float32(.5);along[1]=0;along/=np.linalg.norm(along)
verts=[]
for one,two,sign in [(na,nb,1),(sa,sb,-1)]:
    top=np.array([one,two,two+along*np.float32(.07*sign),one+along*np.float32(.07*sign)])
    bottom=top-np.array([0,.082,0],dtype=np.float32)
    verts.extend(top.tolist());verts.extend(bottom.tolist())
v=np.array(verts,dtype=np.float32);low=v.min(0);high=v.max(0)
oldlow,oldhigh=np.array(f['bridge']['parts'][0]['bounds'])
assert np.all(low>=oldlow) and np.all(high<=oldhigh)
assert high[1]<=0 and low[1]>=-.091
center=np.array(a['bridge_center_source_px']);axis=np.array(a['bridge_axis_source_unit']);lat=np.array(a['bridge_lateral_source_unit'])
assert abs(float(np.dot(axis,lat)))<1e-12
passage=[]
for p in f['bridge']['source_passage']:
    delta=np.array(p)-center;side=abs(float(delta@lat));forward=abs(float(delta@axis))
    assert side<=70 and forward<=278
    passage.append({'source_point':p,'abs_lateral_px':side,'abs_along_px':forward,'new_terrain_patch_lane_owner_exact_zero_by_author_expression':True})
rect=f['material']['water_source_rect'];rx,ry,rw,rh=rect
for r in a['terrain_patches']:
    radius=max(r['radii_px']);x,y=r['center_px']
    assert x-radius>=rx and x+radius<=rx+rw and y-radius>=ry and y+radius<=ry+rh
    assert r['RF_dry_above_water_m']>0
report={'status':'SOURCE_FLOAT32_DESIGN_MODEL_ONLY_NOT_ENGINE_ART_OR_PHYSICS','candidate_input_sha256':sha(P/'input_shore_heads01_NOTREADY.json'),'helper_sha256':sha(OUT/'shore_heads_author01_NOTREADY.gd'),'two_new_visual_beam_bounds_native_metres':[low.tolist(),high.tolist()],'original_deck_proof_AABB_native_metres':f['bridge']['parts'][0]['bounds'],'new_beam_bounds_inside_old_deck_render_AABB':True,'beam_top_not_above_deck0':True,'candidate_beam_corners':verts,'future_unindexed_triangle_vertices':72,'sourcepassage_endpoint_lane_zero_controls':passage,'all7patch_bbox_within_existing_material_source_context':True,'all7centers_above_frozen_RF_waterline':True,'shader_intent_not_claimed_actual_compile':True,'generated_images_or_shaders_executed':0,'PNG_write':0,'formal_write':0,'remaining':['Root orQA GDScript/GLSL actual parsing','single finite newheads/shore visual review','actual state all17parentarrays/64walk/physics unchanged independently','formalvisualcapture/sourceoverride, not implied by this model']}
path=OUT/'static_design_model01_NOTENGINE.json';assert not path.exists()
with path.open('xb') as stream:stream.write((json.dumps(report,indent=2)+'\n').encode())
print(json.dumps({'status':report['status'],'sha256':sha(path),'new_bounds':report['two_new_visual_beam_bounds_native_metres'],'passage_controls':passage,'engine':0,'PNGwrite':0}))
