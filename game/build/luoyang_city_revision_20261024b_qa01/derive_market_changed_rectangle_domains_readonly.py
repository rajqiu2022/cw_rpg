"""Exact f32/ceil-half-open rectangle delta only. No PNG/PIP/native packet read."""
from pathlib import Path
import hashlib,json,struct,math
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p,h): assert sha(p)==h;return json.loads(p.read_bytes())
def res(p): return 'res://'+p.relative_to(ROOT).as_posix()
def f(v): return struct.unpack('<f',struct.pack('<f',float(v)))[0]
def v(raw):
    if isinstance(raw,dict): raw=raw['xy']
    assert len(raw)==2 and all(math.isfinite(x) for x in raw)
    return tuple(f(x) for x in raw)
def add(a,b): return tuple(f(x+y) for x,y in zip(a,b))
def sub(a,b): return tuple(f(x-y) for x,y in zip(a,b))
def mul(a,k): return tuple(f(x*f(k)) for x in a)
def rect(center,size):
    low=sub(center,mul(size,.5));high=add(low,size)
    painted=[math.ceil(low[0]),math.ceil(low[1]),math.ceil(high[0])-1,math.ceil(high[1])-1]
    guard=[math.floor(low[0])-1,math.floor(low[1])-1,math.ceil(high[0])+1,math.ceil(high[1])+1]
    return {'center_f32':list(center),'size_f32':list(size),'position_f32':list(low),'end_f32':list(high),'closed_exact_painted_pixels':painted,'suggested_closed_bbox_plus1':guard}
src=ROOT/'build/luoyang_city_space_20261024b_source01'
author_path=src/'author_space_delta_NOTREADY.json'
projection_path=src/'current_market_native_projection_ROOT_ACTUAL.json'
a=load(author_path,'bcf36e611984d4b8f7325e9e53616bc40b5c1809f0eb2f3913464db51631c68d')
p=load(projection_path,'fb0bbddfb1a7d3b4616b7785dbf6f5241f44242d4f502b80705c5969e36e980a')
objects={x['id']:x for x in p['record']['objects']}
assert len(objects)==23
domains=a['changed_mask_domains_closed'];seen=set()
for x0,y0,x1,y1 in domains:
    seen.update(y*3072+x for y in range(y0,y1+1) for x in range(x0,x1+1))
assert len(seen)==142319 and len(domains)==16
rows=[];extra=[]
for move in a['native_object_moves']:
    old=objects[move['id']]
    assert v(old['world_foot_px'])==v(move['old_foot_px'])
    size=v(old.get('collision_size_px',[0,0]))
    row={'id':move['id'],'native_polygon_count':len(old.get('solid_polygons_px',[])),'collision_size_px_f32':list(size),'new_rectangle_domain_required':size[0]>0}
    if size[0]>0:
        delta=sub(v(move['new_foot_px']),v(move['old_foot_px']))
        oldcenter=v(old['physical_center_px']);newcenter=add(oldcenter,delta)
        row['old']=rect(oldcenter,size);row['new']=rect(newcenter,size)
        for name in ['old','new']:
            rr=row[name];x0,y0,x1,y1=rr['closed_exact_painted_pixels']
            covered=sum(y*3072+x in seen for y in range(y0,y1+1) for x in range(x0,x1+1))
            rr['exact_painted_count']=(x1-x0+1)*(y1-y0+1)
            rr['covered_by_original16_domains']=covered
            assert covered==0
            extra.append(rr['suggested_closed_bbox_plus1'])
    rows.append(row)
assert len(rows)==9 and len(extra)==10
updated=seen.copy()
for x0,y0,x1,y1 in extra:
    updated.update(y*3072+x for y in range(y0,y1+1) for x in range(x0,x1+1))
report={'status':'FIXED_AUTHOR16_DOMAIN_GAP_READONLY_NOT_RGBA_PRIOR','source':{'author_path':res(author_path),'author_sha256':sha(author_path),'current_projection_path':res(projection_path),'current_projection_sha256':sha(projection_path)},'original16_union':142319,'all9_native_object_moves_checked':rows,'required_extra10_closed_bbox_plus1_in_author_move_order_old_then_new':extra,'proposed26_union_from_integer_domains_only':len(updated),'new_union_pixels_vs_old':len(updated)-142319,'math_source':'Vector2 source normalization uses binary32; new delta=newFoot-oldFoot, newphysicalcenter=oldcenter+delta, Rect2.position=center-size*.5/end=position+size, all Vector2 operations narrowed tobinary32. Native rectangle painting is ceil(position) <= point < ceil(end). No PIP approximation or epsilon. All five rectangle old/new painted pixelsets are wholly outside original16 domains.','not_image_or_geometry_proof':'No PNG decode/PIP/Scene/packet/Field/Physics/NAV/875; output only necessary domain closure, not expected childRGBA or pass. Original BCF/CAC preserved; Source must author a NEW successor before independentRGBA prior.'}
path=OUT/'market_mask_rectangle_domain_gap_READONLY.json';assert not path.exists();path.write_bytes((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode())
print('REPORT',sha(path),'EXTRA10',extra,'PROPOSED_UNION',len(updated))
