"""Independent author-only A2 oracle; one authorized parent PNG decode, no PNG output.

Does not import the System preparer/compiler/publisher or consume its screening.
Vector2 operations round both scalar and operands to real_t/f32, as the frozen
Godot compiler expression requires. Only the eight changed primitive domains
are rasterized; the original 1786/2429 routes are not sampled again.
"""
import copy
import hashlib
import json
import math
import struct
from pathlib import Path

import numpy as np
from PIL import Image

QA = Path(__file__).resolve().parent
GAME = QA.parents[1]
BASE = 'res://build/luoyang_city_full_rollout_20261022ap_system01/'
AUTHOR_PATH = BASE+'artisan_revision4/author_READY.json'
NEW_PATH = BASE+'artisan_a2_workyards_epoch01/author_CANDIDATE_NOT_APPROVED.json'
COMPILER_PATH = BASE+'artisan_revision4/quarters_compiler.gd'
REPORT_PATH = BASE+'artisan_revision4/publication/53624/result.json'
PEOPLE_PATH = 'res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.json'
PINS = {
    AUTHOR_PATH: 'c2aa48ec6fe654f85e17be9081ca86c748fffe2506581405c4df4ec0b15add69',
    NEW_PATH: '1dd5a3949e36ecbada0b4a73f2c109cc1561572b64e3cd8a3e49fa4e2c21df09',
    COMPILER_PATH: 'e62b92a4d9eba3735357b23a2416aec51fae2012e2fe6a4925df2ff413db29a4',
    REPORT_PATH: '09301b55d1ea22c94d1dd35096597c87cfe691dba6e04e26b35e3db7c612b575',
    PEOPLE_PATH: '74759592d13ae8dade98e8b44daed34d62ca0acd00387b1ee654d9d300609b9b',
}
RETIRE = ['ap_smith_wall_w1','ap_smith_wall_w2','ap_smith_wall_e1',
          'ap_cloth_wall_w1','ap_cloth_wall_e1','ap_cloth_wall_e2']
RACK = 'ap_cloth_rack_v2'
SCENE = 'luoyang_artisan_residential_20261022ap'
OUT = QA/'artisan_a2_independent_source_and_local_RGBA_recipe01_READY.json'

def path(p):
    assert p.startswith('res://') and '..' not in p
    return GAME/p[6:]

def sha(v):
    return hashlib.sha256(v).hexdigest()

def read(p):
    data=path(p).read_bytes()
    if p in PINS:
        assert sha(data)==PINS[p], (p,sha(data))
    return data

def strict(a,b):
    if type(a) is not type(b): return False
    if isinstance(a,dict): return a.keys()==b.keys() and all(strict(a[k],b[k]) for k in a)
    if isinstance(a,list): return len(a)==len(b) and all(strict(x,y) for x,y in zip(a,b))
    return a==b

def f(x): return struct.unpack('<f',struct.pack('<f',x))[0]
def vec(x): return [f(q) for q in x]
def add(a,b): return [f(f(x)+f(y)) for x,y in zip(a,b)]
def sub(a,b): return [f(f(x)-f(y)) for x,y in zip(a,b)]
def mul(a,s): return [f(f(x)*f(s)) for x in a]
def div(a,b): return [f(f(x)/f(y)) for x,y in zip(a,b)]

def placements(author):
    out=[]
    for p in author['scenes'][0]['placements']:
        asset=author['assets'][p['asset']]
        scalar=float(p['width'])/float(asset['used_rect'][2])
        foot=vec(p['foot']);anchor=vec(asset['ground_anchor'])
        for i,r in enumerate(asset.get('solid_rects',[])):
            low=add(foot,mul(sub(r[:2],anchor),scalar));size=mul(r[2:],scalar)
            high=add(low,size)
            out.append({'id':p['id']+'_base_'+str(i),'kind':'source_rect',
                        'rect_px':low+size,'bounds_px':low+high,
                        'source_rect':r,'placement_id':p['id'],'asset_id':p['asset']})
        for i,poly in enumerate(asset.get('solid_polygons',[])):
            points=[add(foot,mul(sub(q,anchor),scalar)) for q in poly]
            low=[min(q[j] for q in points) for j in (0,1)]
            high=[max(q[j] for q in points) for j in (0,1)]
            out.append({'id':p['id']+'_hull_'+str(i),'kind':'source_polygon',
                        'polygon_px':points,'bounds_px':low+high,
                        'source_polygon':poly,'placement_id':p['id'],'asset_id':p['asset']})
    return out

def ground_rows(author):
    rows=[]
    for s in author['scenes'][0]['ground_sections']:
        asset=author['assets'][s['asset']]
        x0,y0,w,h=s['rect'];tw,th=s['tile_size']
        scale=f(tw)/f(asset['source_size'][0])
        assert scale==f(th)/f(asset['source_size'][1])
        for y in range(math.ceil(h/th)):
            for x in range(math.ceil(w/tw)):
                shown=[min(tw,w-x*tw),min(th,h-y*th)]
                texture=asset['texture']
                if shown!=[tw,th]:
                    crop=[f(f(v)/f(scale)) for v in shown]
                    assert all(v==int(v) for v in crop)
                    key=f'{int(crop[0])}x{int(crop[1])}'
                    texture=s['clip_textures'][key]
                center=add(add([x0,y0],[x*tw,y*th]),mul(shown,.5))
                rows.append({'id':s['id']+f'_{x}_{y}','texture':texture,
                    'pos':div(center,[3072,2048]),'render_size_px':vec(shown),
                    'centered':True,'sort_by_feet':False,'z_index':s['z']})
    return rows

def poly_contains(poly,x,y):
    """Exact source-plane integer query; no epsilon/expanded polygon."""
    inside=np.zeros(x.shape,dtype=bool)
    boundary=np.zeros(x.shape,dtype=bool)
    for a,b in zip(poly,poly[1:]+poly[:1]):
        ax,ay=a;bx,by=b
        cross=(x-ax)*(by-ay)-(y-ay)*(bx-ax)
        boundary |= (cross==0)&(x>=min(ax,bx))&(x<=max(ax,bx))&(y>=min(ay,by))&(y<=max(ay,by))
        if ay==by: continue
        straddles=(ay>y)!=(by>y)
        crossing=ax+(y-ay)*(bx-ax)/(by-ay)
        inside ^= straddles&(x<crossing)
    return inside|boundary

def paint_values(author,solids,flat):
    x=flat%3072;y=flat//3072
    wx,wy,ww,wh=author['scenes'][0]['walk_rect']
    white=(x>=wx)&(x<wx+ww)&(y>=wy)&(y<wy+wh)
    assert not author['scenes'][0]['water_regions']
    assert all(not a.get('support_rects',[]) for a in author['assets'].values())
    for s in solids:
        if s['kind']=='source_rect':
            lo=s['bounds_px'][:2];hi=s['bounds_px'][2:]
            hit=(x>=math.ceil(lo[0]))&(x<=math.floor(hi[0]))&(y>=math.ceil(lo[1]))&(y<=math.floor(hi[1]))
        else: hit=poly_contains(s['polygon_px'],x,y)
        white &= ~hit
    rgba=np.zeros((len(flat),4),dtype=np.uint8);rgba[:,3]=255
    rgba[white,:3]=255
    return rgba

def segment_box(a,b,box,half):
    lo=[box[0]-half[0],box[1]-half[1]];hi=[box[2]+half[0],box[3]+half[1]]
    enter=0.;leave=1.
    for j in (0,1):
        d=b[j]-a[j]
        if d==0:
            if a[j]<lo[j] or a[j]>hi[j]:return False
        else:
            t0=(lo[j]-a[j])/d;t1=(hi[j]-a[j])/d
            if t0>t1:t0,t1=t1,t0
            enter=max(enter,t0);leave=min(leave,t1)
            if enter>leave:return False
    return True

assert not OUT.exists()
old_bytes=read(AUTHOR_PATH);new_bytes=read(NEW_PATH)
old=json.loads(old_bytes);new=json.loads(new_bytes);read(COMPILER_PATH)
report=json.loads(read(REPORT_PATH));people=json.loads(read(PEOPLE_PATH))
assert report['published'] and report['visual_count']==106 and report['solid_count']==33
assert report['source_first'][AUTHOR_PATH]==report['source_final'][AUTHOR_PATH]==PINS[AUTHOR_PATH]
assert strict(old['assets'],new['assets'])
o=old['scenes'][0];n=new['scenes'][0]
assert len(old['scenes'])==len(new['scenes'])==1 and o['scene_id']==n['scene_id']==SCENE
oldp={p['id']:p for p in o['placements']};newp={p['id']:p for p in n['placements']}
assert set(oldp)-set(newp)==set(RETIRE) and not set(newp)-set(oldp)
for pid in newp:
    expected=copy.deepcopy(oldp[pid])
    if pid==RACK:
        assert expected['foot']==[2200,1405]
        expected['foot']=[2470,1446]
        expected['purpose']=newp[pid]['purpose']
    assert strict(expected,newp[pid]),pid
assert all(strict(o[k],n[k]) for k in o if k not in ('ground_sections','placements','visual_depth_overlap_pairs','visual_depth_semantics'))
assert new['adult_doors']==old['adult_doors']
assert n['visual_depth_overlap_pairs']==[]
oldsolids=placements(old);newsolids=placements(new)
assert (len(oldsolids),len(newsolids))==(33,27)
oldmap={s['id']:s for s in oldsolids};newmap={s['id']:s for s in newsolids}
changed={k for k in oldmap.keys()|newmap.keys() if not strict(oldmap.get(k),newmap.get(k))}
assert changed=={x+'_base_0' for x in RETIRE}|{RACK+'_hull_0'}
domains=[]
for pid in sorted(changed):
    for phase,table in [('old',oldmap),('new',newmap)]:
        if pid not in table:continue
        lowx,lowy,hix,hiy=table[pid]['bounds_px']
        closed=[math.floor(lowx)-1,math.floor(lowy)-1,math.ceil(hix)+1,math.ceil(hiy)+1]
        domains.append({'id':pid,'phase':phase,'raw_bounds':table[pid]['bounds_px'],
            'integer_guard_closed':closed})
assert len(domains)==8
indices=[]
for d in domains:
    x0,y0,x1,y1=d['integer_guard_closed']
    y,x=np.mgrid[y0:y1+1,x0:x1+1]
    d['pixels']=(x1-x0+1)*(y1-y0+1)
    indices.append((y*3072+x).ravel())
flat=np.unique(np.concatenate(indices))
mask_path=report['walk_candidate']['path'];PINS[mask_path]=report['walk_candidate']['sha256']
raw_png=read(mask_path)
# Exactly one PNG decode, of the original frozen parent only. No encoded output.
with Image.open(path(mask_path)) as im:
    assert im.size==(3072,2048) and im.mode=='RGBA'
    parent=np.array(im,dtype=np.uint8).reshape(-1,4)
parent_hash=sha(parent.tobytes())
assert parent_hash==report['walk_candidate']['rgba_sha256']
old_local=paint_values(old,oldsolids,flat)
assert np.array_equal(old_local,parent[flat]),'Independent old source raster must match parent in every delta-domain pixel'
new_local=paint_values(new,newsolids,flat)
child=parent.copy();child[flat]=new_local
inverse=child.copy();inverse[flat]=parent[flat]
assert np.array_equal(inverse,parent)
changed_pixels=np.flatnonzero(np.any(child!=parent,axis=1))
assert np.isin(changed_pixels,flat).all()
for d in domains:
    x0,y0,x1,y1=d['integer_guard_closed'];y,x=np.mgrid[y0:y1+1,x0:x1+1];idx=(y*3072+x).ravel()
    d['parent_local_RGBA_sha256']=sha(parent[idx].tobytes())
    d['new_local_RGBA_sha256']=sha(child[idx].tobytes())
    d['changed_pixels']=int(np.any(parent[idx]!=child[idx],axis=1).sum())
segments=[]
for route in o['routes']:
    for ordinal,(a,b) in enumerate(zip(route['points'],route['points'][1:])):
        hits=[{'id':d['id'],'phase':d['phase']} for d in domains if segment_box(a,b,d['integer_guard_closed'],[17,12])]
        segments.append({'route_id':route['id'],'ordinal':ordinal,'first':a,'last':b,'domain_hits':hits})
assert len(segments)==23 and not any(s['domain_hits'] for s in segments)
four=[p for p in people['people'] if p['scene_id']==SCENE]
assert len(four)==4
for p in four:
    assert not any(segment_box(p['foot_px'],p['foot_px'],d['integer_guard_closed'],[17,15]) for d in domains)
    assert not any(segment_box(p['approach_px'],p['approach_px'],d['integer_guard_closed'],[17,12]) for d in domains)
assert all(not any(segment_box(p['foot'],p['foot'],d['integer_guard_closed'],[17,12]) for d in domains) for p in o['portals'])
old_ground=ground_rows(old);new_ground=ground_rows(new)
assert len(old_ground)==86 and len(new_ground)==118 and len(n['ground_sections'])==18
for tex in {r['texture'] for r in new_ground if r['texture'].endswith('.tres')}:
    assert sha(path(tex).read_bytes())==new['source_sha256'][tex]
    PINS[tex]=new['source_sha256'][tex]
# Typed whole-author inverse: enumerate permitted top-level changes independently,
# restore old exact values, then require no undeclared mutation anywhere.
top=['scope','native_root','parent_publication','allowed_changed_solid_ids',
     'root_approved_body_successor','root_chinese_shell_wall_A1_successor',
     'visual_overlap_effective_contract']
inverse_author=copy.deepcopy(new)
for k in top:inverse_author[k]=copy.deepcopy(old[k])
del inverse_author['a2_ground_profiles'];del inverse_author['a2_pending_consumer_contract']
new_source_keys=set(new['source_sha256'])-set(old['source_sha256'])
assert len(new_source_keys)==21 and all(k.startswith(BASE+'artisan_a2_workyards_epoch01/atlases/') for k in new_source_keys)
for k in new_source_keys:del inverse_author['source_sha256'][k]
for k in ['ground_sections','placements','visual_depth_overlap_pairs','visual_depth_semantics']:
    inverse_author['scenes'][0][k]=copy.deepcopy(o[k])
assert strict(inverse_author,old)
for p,h in PINS.items():assert sha(path(p).read_bytes())==h,(p,'source changed during read')
out={'status':'INDEPENDENT_SOURCE_EXPECTATIONS_AND_LOCAL_RGBA_ONLY_NOT_ENGINE_NATIVE_ART_OR_DEPLOYMENT',
    'source_sha256':PINS,'parent_full_author_bytes_sha256':sha(old_bytes),
    'candidate_full_author_bytes_sha256':sha(new_bytes),'whole_typed_author_inverse':True,
    'expression_contract':'Frozen e62b compiler placement expression, independently transcribed; Vector2 operands and scalar rounded to f32 before multiply, each native vector operation f32. No System screen, producer compile, packet decode, or observed geometry expected values.',
    'old_source_solids':oldsolids,'new_source_solids':newsolids,
    'solid_count_before_after':[33,27],'retired_solid_ids':[p+'_base_0' for p in RETIRE],
    'relocated_id':RACK+'_hull_0','all_other_26_source_solids_strict_equal':True,
    'domains':domains,'union_domain_pixels':int(len(flat)),
    'local_mask_prior':{'original_full_RGBA_sha256':parent_hash,
        'new_expected_full_RGBA_sha256':sha(child.tobytes()),'whole_inverse_RGBA_sha256':sha(inverse.tobytes()),
        'changed_pixels':int(len(changed_pixels)),
        'white_to_black':int(((parent[:,0]==255)&(child[:,0]==0)).sum()),
        'black_to_white':int(((parent[:,0]==0)&(child[:,0]==255)).sum()),
        'all_old_local_pixels_reproduced_from_33_original_source_solids':True,
        'new_local_pixels_from_all_27_retained_source_solids_not_blind_white_fill':True,
        'outside_8_domains_RGBA_unchanged':True,'full_RGBA_inverse':True,
        'boundary':'Only union-domain pixels queried from source geometry; full image copied and hashed. Not a whole-world re-raster or route875/17 run.'},
    'exact_routes':o['routes'],'source_23_segments_and_domain_screen':segments,
    'affected_old_route_segments':[],'inherited_route_credit_scope':'Only original fixed-source route evidence outside union delta domains; no old 1786/2429 samples replayed.',
    'unchanged_four_people':four,'unchanged_four_portals':o['portals'],
    'unchanged_five_adult_door_declarations':old['adult_doors'],
    'new_ground_section_rows':n['ground_sections'],'new_ground_visual_rows':new_ground,
    'visual_counts':{'old_ground':86,'old_props':20,'old_total':106,'new_ground':118,'new_props':14,'new_total':132},
    'new_witnesses_pending_actual':{'front_route':[[2040,1430],[2040,1490],[2470,1490],[2470,1486]],
        'retired_wall_stands':[[1840,1430],[2160,1430],[2320,1430]],
        'rack_negative':[2470,1436],'rejected_pending_stand_not_safe':[2350,1446],
        'credit':'Declared source targets only; actual finite native/87517/Physics and ART pending. No route success inferred by target list.'},
    'PNG_decodes':1,'PNG_outputs':0,'engine_runs':0,'publisher_calls':0,'compiler_calls':0,
    'collector_calls':0,'canonical_writes':0,'old_A1_whole_ART_rejection_preserved':True}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'output':str(OUT),'sha256':sha(OUT.read_bytes()),'domain_pixels':len(flat),
    'changed_pixels':len(changed_pixels),'new_RGBA':out['local_mask_prior']['new_expected_full_RGBA_sha256'],
    'counts':[33,27,106,132],'old_route_segments_replayed':0,'engine_runs':0}))
