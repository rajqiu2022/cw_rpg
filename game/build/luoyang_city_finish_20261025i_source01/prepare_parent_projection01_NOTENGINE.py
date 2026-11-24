"""Prepare one ROOT-only two-packet source probe; never run Godot."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def p(res):return GAME/res[6:]
def fixed(res,h):
    raw=p(res).read_bytes();assert sha(raw)==h,res
    return json.loads(raw)
stage=fixed('res://build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json','ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5')
auth={}
for k,row in stage['nodes'].items():
    if not k.startswith('expected_'):continue
    for path,h in row['value']['source_sha256'].items():
        assert path not in auth or auth[path]==h
        auth[path]=h
for r in stage['targets']:auth[r['target']]=r['candidate_sha256']
readback=fixed('res://build/luoyang_city_revision_20261024b_root01/ratio_readback_READY/output/result.json','a789e73761b3ef903759d36ca5a30b341104fe224da75830a568eef4833c680c')
fresh=fixed(NS+'fresh25i_protection_observation02.json','53f2f27efaac24701cc807c648fd0d4d38930c7905eed18fc0dd1589dddfef58')
paths={'dg_author':'res://data/maps/luoyang_district_life_20261016f/author.json',
 'dg_math':'res://scripts/city/luoyang_district_life_geometry_20261016f.gd',
 'courts_author':'res://build/luoyang_yamen_courts_20261024c_system01/author_courts_NOTREADY.json',
 'courts_pure':'res://build/luoyang_yamen_courts_20261024c_system01/retired_order02/courts_projection_CANDIDATE.gd',
 'C_source_expression':'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd',
 'DT_source_expression':'res://scripts/city/luoyang_district_life_20261016f.gd'}
sources={}
for name,path in paths.items():
    raw=p(path).read_bytes();assert sha(raw)==auth[path],path
    sources[name]={'path':path,'absolute_path':str(p(path)),'sha256':auth[path],'bytes':len(raw),'kind':'JSON' if path.endswith('.json') else 'SCRIPT'}
packets=[]
for r in readback['regions']:
    if r['scene_id'] not in ['ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen']:continue
    path=r['packet_path'];assert auth[path]==r['packet_sha256']
    # Do not read/decode packets in preparation. Fixed bytes are inherited from
    # the earlier immutable projection; ROOT one actual will verify fullSHA.
    row={'path':path,'absolute_path':str(p(path)),'sha256':r['packet_sha256'],'bytes':r['packet_bytes'],'scene_id':r['scene_id'],'native_count':r['record_object_count'],'kind':'PACKET'}
    packets.append(row);sources['packet_'+r['scene_id']]=row
assert len(packets)==2
outdir=HERE/'parent_projection01_NOTREADY'
outdir.mkdir(exist_ok=False)
fixture={'status':'ROOT_ONLY_FIXED_GATE_YAMEN_PARENT_SOURCE_PROJECTION_NOTREADY','ready':False,'whole_budget_ms':20000,
 'parent_authority':{'stage_path':'res://build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json','stage_sha256':'ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5'},
 'sources':sources,'packets':packets,'save_absolute_paths':[r['path'] for r in fresh['groups']['saves']],
 'current_save_protection_start':{'path':NS+'fresh25i_protection_observation02.json','sha256':'53f2f27efaac24701cc807c648fd0d4d38930c7905eed18fc0dd1589dddfef58','exact_ticks_external_guard':'Root retains actual fresh15; no old25h save restoration'},
 'output_absolute':str(outdir/'output_NOTREADY'),'no_Field_Scene_PNG_Geometry2D_PIP_Physics_collector':True,
 'output_authority_scope':'Source-declared current parent only. Not a new geometry oracle, runtime pass or allowed-current-hash bypass.',
 'renderer_source_expression':'Native layout_storage visual_objects exact unstorage; DG.project formula without Geometry2D; exact existing G.apply_render; current court project_render/restore/derive source-only.'}
raw=(json.dumps(fixture,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
with (outdir/'fixture_NOTREADY.json').open('xb') as stream:stream.write(raw)
project=b'config_version=5\n\n[application]\nconfig/name="25i ROOT two-parent source projection only"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
with (outdir/'project.godot').open('xb') as stream:stream.write(project)
print(json.dumps({'fixture':{'path':NS+'parent_projection01_NOTREADY/fixture_NOTREADY.json','sha256':sha(raw),'bytes':len(raw)},'project':{'path':NS+'parent_projection01_NOTREADY/project.godot','sha256':sha(project)},'packets_not_read_in_preparation':True},ensure_ascii=False))
