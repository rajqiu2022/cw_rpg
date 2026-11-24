"""Only fixed-source envelopes and explicitly approved parent rawRGBA small rectangle."""
import hashlib,json,pathlib,struct
G=pathlib.Path(__file__).resolve().parents[2];Q=G/'build/luoyang_city_full_rollout_20261022ap_qa01'
def sha(p):
    h=hashlib.sha256()
    with p.open('rb')as f:
        for b in iter(lambda:f.read(1048576),b''):h.update(b)
    return h.hexdigest()
def read(p,h):assert sha(p)==h,p;return json.loads(p.read_bytes())
p=read(Q/'artisan_a2_independent_native_ABI_prior_and_whole_source_inverse_READY.json','d0d544ed24996bf3bc4569ae9b4fd4fc3c6edba85f264075e8e67c336675ce3e')
n=read(Q/'artisan_life_independent_four_polygon_pixel_prior_READY_NOT_RUNTIME.json','3eb82257dc87d92fa354ac3340d99b5d41dd82d77b60fecb2bac92c85b1cc48e')
def f(v):return struct.unpack('<f',struct.pack('<f',v))[0]
def bounds(ps):return[min(x[0]for x in ps),min(x[1]for x in ps),max(x[0]for x in ps),max(x[1]for x in ps)]
def box(r):
    if'polygon_px'in r:return bounds(r['polygon_px'])
    x,y,w,h=r['rect_px'];return[x,y,f(x+w),f(y+h)]
def touch(a,b):return a[0]<=b[2]and b[0]<=a[2]and a[1]<=b[3]and b[1]<=a[3]
sweep=[1243,1164,1277,1212];old=p['expected27_source_solids'];assert len(old)==27
contacts=[r['id']for r in old if touch(sweep,box(r))]
newcontacts=[r['id']for r in n['polygons']if touch(sweep,bounds(r['points']))]
actors=[r['npc_id']for r in p['exact_4_people_and_approaches']if touch(sweep,[r['foot_px'][0]-17,r['foot_px'][1]-15,r['foot_px'][0]+17,r['foot_px'][1]+15])]
assert contacts==newcontacts==actors==[]
for r in p['prior_mask']['domains']:assert not touch(sweep,r['closed'])
bench=next(r for r in n['polygons']if r['id']=='ap_life_well_wait_bench');b=bounds(bench['points']);assert b[1]==1212.3599853515625
cache=Q/'artisan_parent53624_original_RGBA_6e725411_cache.rgba8';expected='6e72541153449e571516c340838794ff44fdf96dfc8b601b93733b3d4ff4c6da'
assert cache.stat().st_size==3072*2048*4 and sha(cache)==expected
xs,ys,xe,ye=sweep;local=bytearray()
with cache.open('rb')as file:
    for y in range(ys,ye+1):
        file.seek((y*3072+xs)*4);row=file.read((xe-xs+1)*4)
        assert len(row)==(xe-xs+1)*4 and row==b'\xff'*len(row),(y,'FIXED_PARENT_LOCAL_NOT_ALL_WHITE')
        local.extend(row)
assert len(local)==35*49*4
meta_path=G.parent/'assets/raw/luoyang_interiors_assembly_20261016g/long_bench_v1.meta.json'
meta=read(meta_path,'33d1ad462102814210f142bc1e293cfab83416fa7978a7c79904be9e6e7bacf7')
assert meta['sha256']=='41759460141f9a6ba742d5df9d2de3fce10ba040af5a86fa8f31bd540877108e'
print(json.dumps({'status':'SOURCE_ONLY_BENCH_SUFFIX1176_TO1200_CLEAR_PRIOR_NOT_ALPHA_OR_RUNTIME_PASS','source_prior_SHA':'d0d544ed24996bf3bc4569ae9b4fd4fc3c6edba85f264075e8e67c336675ce3e','four_poly_prior_SHA':'3eb82257dc87d92fa354ac3340d99b5d41dd82d77b60fecb2bac92c85b1cc48e','suffix':[[1260,1176],[1260,1200]],'reverse_same_suffix':True,'full_Player34x24_continuous_closed_sweep':sweep,'all27_retained_source_AABB_disjoint':True,'all4_new_source_AABB_disjoint':True,'four_idle_NPC34x30_AABB_disjoint':True,'bench_min_y':b[1],'body_bottom_at1200':1212,'strict_gap_no_epsilon':b[1]-1212,'mask_proof':{'fixed_original_parent_cache_SHA':expected,'bytes':cache.stat().st_size,'read_rectangle_closed':sweep,'pixels':1715,'localbytes_SHA':hashlib.sha256(local).hexdigest(),'all_RGBA_white':True,'outside_all_A2_eight_delta_domains':True,'four_new_polygons_bbox_disjoint_even_integer1212':True,'child_C0C5_local_inherits_original_white_not_wholemask_replayed':True,'rounded17_offsets_max_y':1212},'alpha_basis':{'source_metadata_SHA':'33d1ad462102814210f142bc1e293cfab83416fa7978a7c79904be9e6e7bacf7','source_strong_bbox_ge8':meta['bbox_alpha_ge8'],'complete_nonzero_bbox_includes_A1':meta['bbox_nonzero'],'V14_requires_actual_actor_alpha_times_prop_alpha_positive':True,'bbox_is_not_sufficient_pixel_overlap_proof':True,'intended1200_positive_ghost_is_failable_runtime_check_not_predeclared_PASS':True},'cache_scope_authority':'Root explicit message: permit fixed6E725 cache corresponding bench suffix small rectangle, SHA/range; no PNGdecode/fullPIP/875.','QA_actions':{'engine':0,'PNG_decode':0,'PIP':0,'875':0,'Physics':0,'packet':0,'publisher':0,'source_current_fill':0,'original_source_write':0}},indent=2))
