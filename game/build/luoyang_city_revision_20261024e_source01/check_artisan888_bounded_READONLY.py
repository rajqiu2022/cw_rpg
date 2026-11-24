"""One approved NPC station only: exact closed-box proof and1085+17 pixels.
No engine/native decode/PIP/route/raster replay, no media output or formal write.
"""
from pathlib import Path
import hashlib,json,struct
from PIL import Image
G=Path(__file__).resolve().parents[2];B=Path(__file__).resolve().parent
OUT=B/'paper_artisan888_local_model_READONLY.json'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def fixed(path,h):
    raw=path.read_bytes();assert sha(raw)==h,(path,'FIXED_SOURCE_REQUIRED');return raw
modelpath=B/'market_prior01_NOTREADY/independent_f32_model_NOT_PIP.json'
model=json.loads(fixed(modelpath,'9f5a7707f8c92e18b6cb3516dbf2dcc9c471811ec0a4134d456fd23ec341fda5'))
legacy=G/'build/luoyang_city_space_20261024b_source01/worker_facts03/runtime_CANDIDATE.gd'
text=fixed(legacy,'08ca68dded03ba7da17d824d626cf83c59e927ecf9f87526ef2a1a4995d376aa').decode('utf8')
assert 'const TASK_ARTISAN="luoyang_paper_artisan_20261016"' in text
assert 'if npc.get("pos")!=Vector2(1320,1290)/SIZE: return {}' in text and 'npc.pos=Vector2(880,1340)/SIZE' in text
def f(n):return struct.unpack('<f',struct.pack('<f',n))[0]
def add(a,b):return [f(x+y) for x,y in zip(a,b)]
def sub(a,b):return [f(x-y) for x,y in zip(a,b)]
def mul(a,n):return [f(x*f(n)) for x in a]
def overlaps(a,b):return all(a[i]<=b[i+2] and b[i]<=a[i+2] for i in [0,1])
body=[871,1325,905,1355]
rows=[]
for row in model['after43']:
    for i,poly in enumerate(row['polygons']):
        low=[min(p[j] for p in poly) for j in (0,1)];high=[max(p[j] for p in poly) for j in (0,1)]
        end=add(low,sub(high,low))
        rows.append(dict(id=row['id']+'_poly_'+str(i),kind='POLYGON_CLOSED_BBOX',bbox=low+end))
    if all(n>0 for n in row['size']):
        low=sub(row['center'],mul(row['size'],.5));end=add(low,row['size'])
        rows.append(dict(id=row['id']+'_rect',kind='EXACT_PARENT_RECT',bbox=low+end))
hits=[r for r in rows if overlaps(body,r['bbox'])]
assert not hits,('NO_APPROXIMATE_PIP_ALLOWED',hits)
lamp=next(r for r in rows if r['id']=='district_luoyang_market_stock_lamp_0_poly_0')
tree=next(r for r in rows if r['id']=='market_west_court_tree_b_rect')
assert lamp['bbox']==[835.824951171875,1312.449951171875,863.635009765625,1330.0]
assert tree['bbox']==[908.0,1322.0,932.0,1340.0]
assert overlaps([863,1325,897,1355],lamp['bbox'])
mask=G/'build/luoyang_city_blocks_20261024e_system01/publication04/output/9720/walk_overlay.png'
maskbytes=fixed(mask,'051ac64ff157f1cc7ae4ab2abb4b03f650d8da74bd15bf5ff528164d5bfdc9d4')
with Image.open(mask) as source:
    assert source.size==(3072,2048)
    image=source.convert('RGBA')
    assert sha(image.tobytes())=='b6d6d0af0e2e03a7588a2f3561fd6c9aa4f821fe31265338ee79f0463305cb06'
    pixels=image.load();bad=[];sampled=0
    for y in range(1325,1356):
        for x in range(871,906):
            sampled+=1
            if pixels[x,y][0]<128 or pixels[x,y][3]<128:bad.append([x,y,list(pixels[x,y])])
    offsets=[[-17,-15],[0,-15],[17,-15],[-17,0],[0,0],[17,0],[-17,15],[0,15],[17,15],[-8.5,-15],[8.5,-15],[-8.5,15],[8.5,15],[-17,-7.5],[-17,7.5],[17,-7.5],[17,7.5]]
    # Godot roundi positive .5 rounds away from zero, not Python ties-to-even.
    import math
    controls=[]
    for dx,dy in offsets:
        x=math.floor(888+dx+.5);y=math.floor(1340+dy+.5)
        color=pixels[x,y];controls.append(dict(xy=[x,y],RGBA=list(color)))
        if color[0]<128 or color[3]<128:bad.append([x,y,list(color)])
    assert sampled==1085 and len(controls)==17 and not bad
    old_mask_negative=dict(xy=[863,1325],RGBA=list(pixels[863,1325]))
    assert pixels[863,1325][0]<128
assert not OUT.exists()
value=dict(status='SOURCE_ONLY_SINGLE_PAPER_ARTISAN888_LOCAL_CLEARANCE_NOT_FIELD',passed=True,
    exact_ID='luoyang_paper_artisan_20261016',old_source_foot=[880,1340],proposed_foot=[888,1340],body_half=[17,15],closed_body=body,
    fixed_model=dict(path=modelpath.as_posix(),sha256=sha(modelpath.read_bytes())),
    fixed_actual_mask=dict(path=mask.as_posix(),sha256=sha(maskbytes),RGBA_sha256='b6d6d0af0e2e03a7588a2f3561fd6c9aa4f821fe31265338ee79f0463305cb06',identity_from='Root9720 fixed components matched independent priorDCC92, never future expected filled from actual'),
    exact_closed_geometry=dict(primitives=len(rows),body_bbox_contacts=hits,proof='Body closed bbox disjoint from every finite source primitive bbox; therefore no native closed polygon or edge can touch/intersect. No Python PIP emulation or epsilon.',nearest_lamp=lamp,nearest_tree=tree,lamp_horizontal_gap=871-lamp['bbox'][2],tree_horizontal_gap=tree['bbox'][0]-905),
    mask=dict(full_body_pixels=sampled,extra17=controls,failures=bad,old_880_negative=old_mask_negative),
    consumer_chain=[dict(path='res://scripts/city/luoyang_city_tasks_20261016.gd',function='project',statement='fixed task spec creates exact artisan1320,1290'),dict(path='res://build/luoyang_city_space_20261024b_source01/worker_facts03/runtime_CANDIDATE.gd',sha256='08ca68dded03ba7da17d824d626cf83c59e927ecf9f87526ef2a1a4995d376aa',function='project_task_rows',statement='sameID exact1320,1290 ->880,1340'),dict(path='res://scripts/field/field_walkable_controller.gd',lines=[399,981],statement='both initial and warm task refresh run prior task projection'),dict(path='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd',function='project_rows',statement='last common row consumer before_spawn_npcs in both Field flows; exact-ID source-bound880->888 belongs here, not merely earlier runtime.project_npcs')],
    must_preserve=['all nonpos task fields/rewards/dialog/flags/identity','original1320,1290 task author and880 fixed projection historical source','sameScene/layout/owner lease and sourceFIRSTFINAL','all raw/native4 artifacts; no new raster'],
    scope=dict(NPC_positions_checked=1,PNG_decode=1,PNG_outputs=0,engine=0,packet_decode=0,closed_polygon_PIP_calls=0,route_audits=0,raster_repaint=0,canonical_writes=0),
    not_claimed='No travel, NPC-vs-NPC movement, Field/runtime, future publisher route or ART approval.')
OUT.write_bytes((json.dumps(value,ensure_ascii=True,indent=2)+'\n').encode('ascii'))
print(json.dumps(dict(path=OUT.as_posix(),sha256=sha(OUT.read_bytes()),full_pixels=1085,extra=17,geometry_contacts=0,gaps=[871-lamp['bbox'][2],tree['bbox'][0]-905])))
