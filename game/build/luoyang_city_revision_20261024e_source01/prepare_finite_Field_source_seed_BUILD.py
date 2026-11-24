"""Finite Field expectations from frozen source expressions, never runtime nodes."""
from pathlib import Path
import json,hashlib,struct,re
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/';N='res://build/luoyang_city_blocks_20261024e_system01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),(p,sha(b));return b
def f(x):return struct.unpack('<f',struct.pack('<f',float(x)))[0]
def vec(v):return [f(v[0]),f(v[1])]
def add(a,b):return [f(a[i]+b[i]) for i in range(2)]
def sub(a,b):return [f(a[i]-b[i]) for i in range(2)]
def mul(a,s):return [f(a[i]*f(s)) for i in range(2)]
def div(a,b):return [f(a[i]/b[i]) for i in range(2)]
authorpath=N+'author_market_block07_paper_foot_NOTREADY.json';authorhash='de1911cceb5fb10e6b3b1aba1fa6d9d34057358841febdd285d25a1a1eb65e95';a=json.loads(read(authorpath,authorhash));assert len(a['npc_migrations'])==8 and len(a['new_components'])==6
priorpath='res://build/luoyang_city_space_20261024b_source01/author_space_delta_route_detours_successor06_NOTREADY.json';priorhash='7e1f6b1dc4dd4d693438bd0f672657063b3f42c0092ad50028f3aa632b03d31f';prior=json.loads(read(priorpath,priorhash))
fbpath='res://build/luoyang_city_space_20261024b_source01/current_market_native_projection_ROOT_ACTUAL.json';fbhash='fb0bbddfb1a7d3b4616b7785dbf6f5241f44242d4f502b80705c5969e36e980a';fb=json.loads(read(fbpath,fbhash))
actors=[];crowd={r['id']:r for r in prior['runtime_district']['crowd']};native={r['npc_id']:r for r in fb['storage']['scene_storage']['fields']['npcs']['array_values']}
for row in a['npc_migrations']:
    id=row['id'];distance=70.0;mode='idle';expected_id=id
    if id.startswith('market_'):
        old=crowd[id];assert old['foot_px']==row['old_foot_px'];assert old['distance_px']==row['distance_px'];distance=float(old['distance_px']);mode='patrol' if distance>0 else 'idle';expected_id='district_life_'+id
    elif id=='luoyang_armorer':assert id in native and 'movement_mode' not in native[id] and 'patrol_distance' not in native[id]
    else:assert id=='luoyang_paper_artisan_20261016' and row['foot_px']==[888,1340]
    # Actual Field _norm_to_screen(Vector2(foot)/SIZE), not rounded displays.
    norm=div(vec(row['foot_px']),[3072,2048]);origin=[f(norm[0]*3072),f(norm[1]*2048)];assert origin==vec(row['foot_px'])
    actors.append(dict(npc_id=expected_id,origin=origin,movement_mode=mode,patrol_distance=distance))
catalog=(GAME/'data/npcs/npc_catalog.tres').read_text(encoding='utf8');assert 'npc_id = &"luoyang_armorer"' not in catalog and 'npc_id = &"luoyang_paper_artisan_20261016"' not in catalog
render=[]
for r in a['new_components']:
    asset=a['assets'][r['asset_id']];size=vec(asset['source_size_px']);anchor=vec(asset['source_ground_anchor_px']);foot=vec(r['foot_px']);scale=float(r['scale'])
    center=add(foot,mul(sub(mul(size,.5),anchor),scale));pos=div(center,[3072,2048]);position=[f(pos[0]*3072),f(pos[1]*2048)];render_size=mul(size,scale);sprite_scale=[f(render_size[i]/float(size[i])) for i in range(2)]
    render.append(dict(id=r['id'],texture=asset['texture'],position_px=position,scale=sprite_scale,source_ground_foot=foot,source_size=size,formula='Vector2 f32 each op: (foot+(size*.5-anchor)*scale)/SIZE; Field Vector2(component*screen_size); scale render_size/texture_size.'))
# Derive portal target multiset from the immutable native9, original G room
# parent declarations, Estate's exact one replacement, and Quarter links.
oldstagepath='res://build/luoyang_city_revision_20261024c_source01/outputs/root_courts_scholar_exact30_stage03/receipt.json';oldstagehash='99a719091627f5b6cbc015aa7c4281d42f01b1786a5a9f4cafe3becc55cc51ce';oldstage=json.loads(read(oldstagepath,oldstagehash));registry=oldstage['nodes']['registry_final']['value'];quarter=oldstage['nodes']['quarter_final']['value']
targets=[r['target_scene'] for r in fb['storage']['layout_storage']['fields']['portals']['array_values']];assert len(targets)==9 and len(set(targets))==9
room_sources=[]
for id,row in registry['rooms'].items():
    source=row.get('am_parent_row',row) if id=='luoyang_functional_mansion_candidate_20261016' else row
    raw=read(source['author_path'],source['author_sha256']);data=json.loads(raw);room=data.get('room',{})
    room_sources.append(dict(path=source['author_path'],sha256=source['author_sha256']))
    if room.get('city_id')=='ch4_s3_luoyang_market' and id not in targets:targets.append(id)
mansion='luoyang_functional_mansion_candidate_20261016';assert targets.count(mansion)==1;targets[targets.index(mansion)]='luoyang_estate_riverside_20261021ai'
for row in quarter['connections']:
    if row['source']=='ch4_s3_luoyang_market' and row['kind']=='PUBLIC_QUARTER_LINK' and row['target'] in ['luoyang_artisan_residential_20261022ap','luoyang_riverside_garden_20261022ap']:
        assert row['target'] not in targets;targets.append(row['target'])
assert len(targets)==12
# None of the six new closed structural entities adds a room. Six old room
# scalars/two external scalars move only feet, never target identities.
assert all(r.get('no_portal',True) is True for r in a['new_components'])
crowd_script=(GAME/'scripts/city/luoyang_district_life_crowd_20261016f.gd').read_text(encoding='utf8');merchant=re.search(r'^const MERCHANT_IDLE="([^"]+)"',crowd_script,re.M).group(1)
assert crowd['market_broker']['family']=='merchant' and crowd['market_broker']['distance_px']==65
npc_author=json.loads((GAME/'build/luoyang_city_full_rollout_20261022ap_npc01/author.json').read_bytes());assert not any(r.get('npc_id')=='district_life_market_broker' for r in npc_author['visual_rows'])
result=dict(status='ROOT_REVIEWED_SOURCE_DERIVED_MARKET_FIELD_SEED_NOT_RUNTIME_OBSERVATIONS',author_path=authorpath,author_sha256=authorhash,broker=dict(npc_id='district_life_market_broker',origin=[2290,1660],distance=65,sprite_path=merchant),expected_new_render=render,expected_exit_count=len(targets),expected_exit_targets=sorted(targets),expected_npc_positions=actors,source_basis=dict(fixed_parent_native_projection=dict(path=fbpath,sha256=fbhash),fixed24b_author=dict(path=priorpath,sha256=priorhash),fixed24c_registry_quarter_declarations=dict(path=oldstagepath,sha256=oldstagehash),room_authors=room_sources,source_expression='No runtime Field observations: native9 + G add absent Market room IDs + exact Mansion→Estate target replacement + AP public Quarter links; six new structural IDs add zero doors.',NPC_motion='CROWD.project keeps row.distance and patrol/idle; native armorer and task artisan have no catalog override, so Field defaults idle/distance70.',Root_source_design_review_inherited=True,Root_must_read_this_derived_seed_before_actual=True),engine_calls=0,packet_decodes=0,PNG_decodes=0,collector_calls=0,canonical_writes=0)
dest=HERE/'finite_Field_source_seed_READY_FOR_ROOT_REVIEW.json';assert not dest.exists();raw=(json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode()
with dest.open('xb') as stream:stream.write(raw)
print(json.dumps(dict(path=S+dest.name,sha256=sha(raw),new_render=6,NPCs=8,exit_count=12,exit_targets=result['expected_exit_targets'])))
