"""Small offline BUILD review; no engine or media reads."""
from pathlib import Path
import hashlib,json
BASE=Path(__file__).resolve().parent
GAME=BASE.parents[1]
SYS=GAME/'build/luoyang_city_blocks_20261024e_system01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def j(p):return json.loads(p.read_bytes())
out=BASE/'market_prior01_static_review_READONLY.json'
assert not out.exists()
model=j(BASE/'market_prior01_NOTREADY/independent_f32_model_NOT_PIP.json')
fixture=j(BASE/'market_prior01_NOTREADY/fixture_NOTREADY.json')
handoff=j(BASE/'market_prior01_NOTREADY/handoff_NOTREADY.json')
assert not fixture['ready'] and fixture['whole_ms']==60000
assert (len(model['native25']),len(model['before37']),len(model['after43']))==(25,37,43)
assert len(model['raw_half_open_domains'])==62 and len(model['merged_half_open_domains'])==27 and model['union_visited_pixels']==1000516
assert not any('PENDING_' in (BASE/'market_prior01_NOTREADY/oracle_NOTREADY.gd').read_text(encoding='utf8') for _ in [0])
for name in ['author_market_block04_NOTREADY.json','publication_input01_NOTREADY.json']:
    j(SYS/name)
for name in ['author_market_block04_NOTREADY.json','market_block_projection03_NOTREADY.gd','publish_market_block01_NOTREADY.gd','publication_input01_NOTREADY.json']:
    raw=(SYS/name).read_bytes();assert b'tokens truncated' not in raw and b'...truncated' not in raw
for k in ['key','fixture','model','project']:
    assert sha(Path(handoff[k]['path']))==handoff[k]['sha256']
for path,h in fixture['source_sha256'].items():
    # Do not rehash media/native for this small review: only source docs/code.
    p=Path(path)
    if p.suffix in ['.json','.gd']:assert sha(p)==h,(path,'source changed')
rects=[]
for r in model['native25']:
    if all(n>0 for n in r['size']) and r['id'] in model['changed_ids']:rects.append(r['id'])
author=j(SYS/'author_market_block04_NOTREADY.json')
parent=j(GAME/'build/luoyang_city_space_20261024b_source01/author_space_delta_route_detours_successor06_NOTREADY.json')
distances=[]
for row in author['npc_migrations']:
    if 'distance_px' in row:
        old=[p for p in parent['runtime_district']['crowd'] if p['id']==row['id']]
        assert len(old)==1 and old[0]['distance_px']==row['distance_px']
        distances.append(dict(id=row['id'],old=old[0]['distance_px'],proposed=row['distance_px']))
value=dict(status='SOURCE24E_INDEPENDENT_PRIOR_SMALL_STATIC_REVIEW_NOT_NATIVE_EXECUTION',passed=True,
    files={name:dict(path=(SYS/name).as_posix(),sha256=sha(SYS/name)) for name in ['author_market_block04_NOTREADY.json','market_block_projection03_NOTREADY.gd','publish_market_block01_NOTREADY.gd','publication_input01_NOTREADY.json']},
    executable=handoff,
    source_model=dict(native=25,before=37,after=43,raw_domains=62,merged_domains=27,union_pixels=1000516,changed_nonzero_rectangle_ids=rects),
    parent_basis='F484 source model independently recomputed from fixed FB0B23 plus7E1F06 and exact-equal to child25; prior108288 accepted F6DA inherited. New source transformations independently explicit IEEE754binary32; Root oracle independently recomputes37/43 and all coordinate bitstrings before native PIP.',
    findings=[],bounded_cautions=[
      'Current crowd distance fields all equal existing source values; publisher currently reads old distance. Thus no concrete mismatch in04, but future unequal field must be rejected or audited from proposed value.',
      'Pixel oracle deliberately does not claim full geometry, routes, NPC/body clearance, ART or Field. Those remain original bounded publisher/runtime gates.',
      'Broker-only author05 successor may inherit04 pixel prior only if all geometric source fields and placement tables remain exact; no prior must be filled from publisher actual.',
      'No Godot parser/runtime execution performed by Source; Root must freeze and run one native CPU oracle.'
    ],prior_hash_and_changed_count='UNKNOWN, never derived from future publisher',
    domain_scope='Parent mask was native25-only; new effective mask adds whole child43 primitives in affected merged closure. Existing DG old bodies formerly guarded separately. Old-local native25+raw must have zero differences or oracle fails.',
    explicit_float_policy='Vector2 constructors and every subtract/multiply/add rounded to binary32, scalar cast binary32; no epsilon, no Python PIP.',
    preserved=dict(canonical_writes=0,PNG_decodes=0,packet_decodes=0,engine=0,collectors=0,source_classification_change=0),
    recommendation='Root read/freeze one CPU oracle; no independent implementation defect demonstrated in current04 geometry. Do not Stage or publish until native prior is successful.')
raw=(json.dumps(value,ensure_ascii=True,indent=2)+'\n').encode('ascii')
out.write_bytes(raw)
print(json.dumps(dict(path=out.as_posix(),sha256=sha(out),rect_ids=rects)))
