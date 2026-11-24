"""Small source-derived NAV IDs and f32 transform seed; no packet/PNG/Godot."""
from pathlib import Path
import json,hashlib,struct
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(pin):
    raw=(GAME/pin['path'][6:]).read_bytes();assert sha(raw)==pin['sha256'];return json.loads(raw)
def f32(x):return struct.unpack('<f',struct.pack('<f',x))[0]
readback=dict(path='res://build/luoyang_city_revision_20261024b_root01/ratio_readback_READY/output/result.json',sha256='a789e73761b3ef903759d36ca5a30b341104fe224da75830a568eef4833c680c')
authorpin=dict(path='res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/author02_exact_sack_NOTREADY.json',sha256='7a370e1782fdc4366c2ae73635debe3db3f39b70ef82a71d6d87e480b58c792e')
dgpin=dict(path='res://data/maps/luoyang_district_life_20261016f/author.json',sha256='d98c65879681b58feea64158a4d0bde33d2ef9fc6b8a25d7d2f33dc961a9c59c')
rb=load(readback);a=load(authorpin);dg=load(dgpin);region=next(r for r in rb['regions'] if r['scene_id']=='ch4_s2_canal_docks')
assert rb['complete'] is True and rb['failures']==0 and region['packet_sha256']==a['fixed_parent_packet']['sha256']
native=[r['id'] for r in region['record_objects']];layout=[r['id'] for r in region['layout_visuals']];assert native==layout and len(native)==len(set(native))==29
added=[r['id'] for r in dg['districts']['ch4_s2_canal_docks']['placements']];assert len(added)==10 and not set(native)&set(added)
donors={k:load(v) for k,v in a['fixed_source_manifests'].items()};transforms=[]
for change in a['changes']:
    donor=next(r for r in donors[change['source_manifest']]['objects'] if r['id']==change['source_id'])
    assert donor['texture']==change['texture'];ratio=f32(change['new_ratio']);size=[f32(f32(x)*ratio) for x in donor['render_size_px']]
    position=[]
    for i,extent in enumerate([3072,2048]):
        difference=f32(f32(.5)-f32(donor['foot_uv'][i]));offset=f32(difference*size[i]);center=f32(f32(change['new_foot'][i])+offset)
        normalized=f32(center/f32(extent));position.append(f32(normalized*f32(extent)))
    scale=[f32(size[i]/change['source_size'][i]) for i in range(2)]
    transforms.append(dict(id=change['id'],texture=change['texture'],position_px=position,scale=scale,render_size_px=size,foot_px=change['new_foot']))
assert transforms[0]['position_px']==[754.0,417.25]
assert transforms[1]['position_px']==[492.17950439453125,1310.1602783203125]
assert transforms[2]['position_px']==[1752.179443359375,440.1602783203125]
doc=dict(status='ROOT_REVIEWABLE_SOURCE_DERIVED_DOCKS_NAV_AND_TRANSFORM_NOT_RUNTIME_OBSERVATIONS',scene_id='ch4_s2_canal_docks',native_readback=readback,fixed_parent_packet=a['fixed_parent_packet'],author=authorpin,DG_author=dgpin,donors=a['fixed_source_manifests'],expected_native29_ids=native,expected_DG10_ids=added,expected_navigation39_ids=native+added,expected_three_render=transforms,formula='Every native Vector2 component/operation explicitly IEEE754 binary32: donor size * f32 ratio; (.5f-uvf)*size; +f32 foot; /f32 canvas; Field *f32 canvas. Field scale: f32(render size / original PNG dimensions). No epsilon.',no_helper_render_output_used=True,packet_decodes=0,PNG_decodes=0,engine_calls=0,collector_calls=0)
raw=(json.dumps(doc,ensure_ascii=False,indent=2)+'\n').encode();dest=HERE/'docks_navigation_transform_source_seed_NOT_RUNTIME.json';assert not dest.exists();dest.write_bytes(raw)
print(json.dumps(dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw))))
