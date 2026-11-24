"""Only one proposed point/near/ray/visual envelope; does not rerun action logic."""
from pathlib import Path
from PIL import Image
import hashlib, json, math, re
ROOT=Path('F:/Code/RPG_GAME');LIB=ROOT/'game/build/adventure_20261030k_qa01/static_maps_READONLY.py'
text=LIB.read_text(encoding='utf-8');marker='parser=argparse.ArgumentParser()';assert text.count(marker)==1
scope={};exec(compile(text[:text.index(marker)],str(LIB),'exec'),scope)
uri=lambda p: ROOT/'game'/p.removeprefix('res://')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
layout_uri='res://data/maps/adventure_20261030k/mine_layout.tres'
doc=scope['tres'](layout_uri)['props'];size=doc['design_size'];mask=scope['Mask'](doc['walkable_mask_path'],size)
site=[925,1680];near=[875,1730]
blockers=[]
for row in doc['blockers']:
    p=scope['vec'](row['pos'],size);s=scope['vec'](row['size'],size)
    blockers.append((row['id'],[p[0]-s[0]/2,p[1]-s[1]/2,*s]))
def body_at(p):return [p[0]-17.5,p[1]-12.5,35,25]
def hits(rect):return [name for name,box in blockers if scope['rect_hit'](rect,box)]
def line_hits_rect(a,b,rect):
    lo,hi=0.,1.
    for axis in [0,1]:
        origin=a[axis];delta=b[axis]-origin;minimum=rect[axis];maximum=minimum+rect[axis+2]
        if abs(delta)<1e-12:
            if origin<minimum or origin>maximum:return False
            continue
        first=(minimum-origin)/delta;last=(maximum-origin)/delta
        lo=max(lo,min(first,last));hi=min(hi,max(first,last))
        if hi<lo:return False
    return True
feet=[{'kind':label,'foot':point,'whole35x25_mask_clear':mask.whole(body_at(point)),'physical_hits':hits(body_at(point))} for label,point in [('site',site),('near',near)]]
# This full enclosing rectangle conservatively contains the whole diagonal foot sweep.
sweep=[min(site[0],near[0])-17.5,min(site[1],near[1])-12.5,abs(site[0]-near[0])+35,abs(site[1]-near[1])+25]
ray_hits=[name for name,box in blockers if line_hits_rect(near,site,box)]
actual_path=ROOT/'game/build/gather_actions_20261030l_qa01/actual02/138384/result.json'
actual=json.loads(actual_path.read_text(encoding='utf-8-sig'))
ore=next(row for row in actual['records'] if row.get('phase')=='completed_ore')
observed=ore['samples'][0]['debug'];ground=ore['raw_debug_final']['physical_before']['ground_anchored']
assert ground is True and observed['facing']=='right'
profile_path=ROOT/'game/scripts/life_skills/gathering_actions_20261030l.json'
profile=json.loads(profile_path.read_text(encoding='utf-8-sig'))['actions']['ore']
observed_scale=float(re.findall(r'-?\d+(?:\.\d+)?',observed['visual_scale'])[0])
assert abs(observed_scale-profile['frames'][0]['scale'])<1e-6
sheet=Image.open(uri(profile['sheet'])).convert('RGBA')
frames=[]
for index,row in enumerate(profile['frames']):
    x,y,w,h=row['rect'];cell=sheet.crop((x,y,x+w,y+h));box=cell.getchannel('A').getbbox()
    foot=row['source_foot'];scale=row['scale']
    # Ground-anchored Player's _visual_foot_offset() is exactly 0; helper only child scale.
    rect=[near[0]+(box[0]-foot[0])*scale,near[1]+(box[1]-foot[1])*scale,(box[2]-box[0])*scale,(box[3]-box[1])*scale]
    frames.append({'frame':index,'all_nonzero_alpha_bbox_in_cell':box,'source_foot':foot,'scale':scale,'world_all_alpha_bbox_xywh':rect,'right_from_actor_px':rect[0]+rect[2]-near[0]})
# Full pixel-derived nonzero-alpha AABBs of only this map's potential static occluders.
# AABB non-overlap is conservative: no alpha threshold or center-only judgment.
visual_rows=[];overlaps=[];images={}
for row in doc['visual_objects']:
    path=uri(row['texture'])
    if row['texture'] not in images:images[row['texture']]=Image.open(path).convert('RGBA')
    image=images[row['texture']];box=image.getchannel('A').getbbox()
    pos=scope['vec'](row['pos'],size);scale=row['scale'];sx,sy=scale
    offset=[-image.width/2,-image.height/2] if row.get('centered',True) else [0,0]
    rect=[pos[0]+(box[0]+offset[0])*sx,pos[1]+(box[1]+offset[1])*sy,(box[2]-box[0])*sx,(box[3]-box[1])*sy]
    collisions=[frame['frame'] for frame in frames if scope['rect_hit'](frame['world_all_alpha_bbox_xywh'],rect)]
    if collisions:overlaps.append({'id':row['id'],'frames':collisions,'visual_world_bbox':rect})
    if row['id']=='mine_cliff_11':visual_rows.append({'id':row['id'],'source_png':row['texture'],'source_png_sha256':sha(path),'source_nonzero_alpha_bbox':box,'world_bbox_xywh':rect,'minimum_horizontal_separation_px':rect[0]-max(frame['world_all_alpha_bbox_xywh'][0]+frame['world_all_alpha_bbox_xywh'][2] for frame in frames)})
passed=all(row['whole35x25_mask_clear'] and not row['physical_hits'] for row in feet) and not ray_hits and mask.whole(sweep) and not hits(sweep) and not overlaps and math.dist(site,near)<82
result={'passed':passed,'scope':'ONLY_PROPOSED_MINE_POINT01_REPOSITION_NOT_67_OR384_REPLAY','site_id':'adventure_mine_ore_01','original_site':[1040,1680],'proposed_site':site,'proposed_public_near':near,'distance':math.dist(site,near),'feet':feet,'ray_static_blocker_hits':ray_hits,'conservative_entire_foot_sweep_rectangle':sweep,'entire_sweep_mask_clear':mask.whole(sweep),'entire_sweep_blocker_hits':hits(sweep),'four_frames':frames,'cliff11_pixel_bounds':visual_rows,'any_existing_map_visual_AABB_overlaps':overlaps,'observed_original_Runtime_scale_used_not_new_Physics':observed_scale,'inherited_Runtime_result_sha256':sha(actual_path),'inputs':{layout_uri:sha(uri(layout_uri)),'res://scripts/life_skills/gathering_actions_20261030l.json':sha(profile_path),profile['sheet']:sha(uri(profile['sheet']))},'static_pixel_envelope_only_Root_one_normal_image_still_required':True,'engine_runs':0,'production_or_PNG_writes':0,'save_access':0}
print(json.dumps(result,separators=(',',':')))
