"""Source-only approval of reversed existing approach; does not execute journey."""
from pathlib import Path
import json,hashlib
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/';Q='res://build/luoyang_city_revision_20261024b_qa01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));return b
authorpath=S+'author_space_delta_route_detours_successor06_NOTREADY.json';authorhash='7e1f6b1dc4dd4d693438bd0f672657063b3f42c0092ad50028f3aa632b03d31f'
author=json.loads(read(authorpath,authorhash))
contractpath=Q+'market_apothecary_vendor_route_contract_source06_NOTREADY/route_contract_SOURCE_APPROVAL_PENDING.json';contracthash='6dea7d7651846bf14a19eadeb955d25b8ad5b27b274d19ec83e8acf722518ada';contract=json.loads(read(contractpath,contracthash))
start=[1690,1596];end=[1690,1663.7652439024391]
assert contract['paths']['entry_to_threshold']==[end,start]
def walk(v):
    if isinstance(v,dict):
        yield v
        for w in v.values():yield from walk(w)
    elif isinstance(v,list):
        for w in v:yield from walk(w)
routes=[v for v in walk(author) if v.get('id')=='room_northeastrear_approach' and v.get('new_points_px')]
assert len(routes)==1 and routes[0]['new_points_px'][-2:]==[end,start]
stagepath=S+'outputs/root_ENV_texture_union_exact18_stage02/receipt.json';stagehash='a7f8ce3a8b54cf78e3fe836c39ebab8ddb8e8f3ec58a53b6f6a2e6edf946ead6';stage=json.loads(read(stagepath,stagehash))
routerpath='res://scripts/autoload/scene_router.gd';routerhash=stage['nodes']['expected_ch4_s3_luoyang_market_true']['value']['source_sha256'][routerpath];router=read(routerpath,routerhash).decode()
assert 'var arrival: Variant=remembered' in router and 'authored!=_resident_city.authored_exit or not remembered is Vector2 or remembered!=_resident_city.return_spawn' in router
v=dict(status='SOURCE_APPROVED_REMAINING_ONLY_MARKET_WARM_RETURN_APPROACH_REVERSE',source_approved=True,production_change=False,engine_authorization_by_this_document=False,
    formal_stage=dict(path=stagepath,sha256=stagehash),formal_deployment=dict(path='res://build/luoyang_city_revision_20261024b_root01/deployment18_env_actual.json',sha256='6ec5f085a46e3ced5e6debc935c2ae68a8ed4604c91f97ff2d6647a5bda9a211'),
    router=dict(path=routerpath,sha256=routerhash,function='_try_resident_return',source_lines=[640,643,644,660,661],contract='For non-public room resident return, arrival is remembered. Authored exit and remembered return_spawn are validated independently. The cold authored return foot is not the warm arrival expectation.'),
    source_author=dict(path=authorpath,sha256=authorhash),prior_route_contract=dict(path=contractpath,sha256=contracthash),
    approved_suffix_entry=dict(from_world_px=start,to_world_px=end,mechanism='TRUE_INPUT_ONLY',witness=dict(route='room_northeastrear_approach',segment=4,original_direction=[end,start]),equivalence='Exact same closed straight segment, reverse direction; no new geometry, raster, mask, route domain or position write.'),
    following_paths_unchanged=['return_to_vendor','vendor_to_task'],
    preserved_limits=['Do not repeat room entry/exit or the already passed prefix.','No teleport, inspection pose or production change.','No new 875/PIP/Physics pre-pass credit. Remaining real Input may fail.','Two x780 connectors retain their original unvalidated status until real Input.','Latest four formal Stages remain frozen; no Stage/collector/media/engine run by Source.'],
    original_actual67928_whole_FAIL_preserved=True,source_only_scope='Approve the fixed approach reverse for remaining street/vender/task suffix; not a declaration that the remaining journey passed.')
b=(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();out=HERE/'market_warm_return_remaining_approach_SOURCE_APPROVED.json'
with out.open('xb') as f:f.write(b)
assert json.loads(out.read_bytes())==v
print(json.dumps(dict(path=S+out.name,sha256=sha(b),bytes=len(b),Router=routerhash)))
