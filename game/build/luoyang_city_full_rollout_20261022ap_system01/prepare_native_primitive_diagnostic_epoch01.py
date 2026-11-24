"""Freeze Root-only diagnostic handoff; no native or PNG decode, no engine."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent
GAME=ROOT.parent.parent
OUT=ROOT/'native_primitive_diagnostic_epoch01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def pin(p):return {'path':'res://'+p.relative_to(GAME).as_posix(),'sha256':sha(p),'bytes':p.stat().st_size}
fixed=ROOT/'finite_two_domain_publication_epoch04/input_READY.json'
assert sha(fixed)=='7b1da122d0342d2a6db4be264237422343bf3d2564060b1908225d4f0fc04dc2'
config=json.loads(fixed.read_text(encoding='utf-8'))
declared=[]
for path in [config['bundle_api_path'],config['wall_helper_path'],config['market']['packet_path']]:
    actual=GAME/path.removeprefix('res://')
    assert sha(actual)==config['source_pins'][path]
    declared.append({'path':path,'sha256':config['source_pins'][path],'declaration':'Frozen7B1D source_pins, not observed-value expected reconstruction'})
failure=ROOT/'finite_two_domain_publication_epoch04/output/runs/38992_1718/result.json'
old=json.loads(failure.read_text(encoding='utf-8'))
assert old['passed'] is False and old['error']=='INDEPENDENT_NATIVE_SOLIDS_IN_FIXED_COMBINED_ORACLE:ch4_s3_luoyang_market'
handoff={'status':'ROOT_REVIEW_READONLY_NATIVE_ONLY_DIAGNOSTIC_READY_NOT_RUN','script':pin(OUT/'diagnostic_READY.gd'),'fixed_input':pin(fixed),'fixed_read_inputs':declared,'original_failure':pin(failure),
    'actual_observation_not_yet_known':['A = exact ordered record-native vs packet solids','B = exact packet vs independent fixed oracle polygon multiset','C = exact computed record vs independent oracle multiset'],
    'read_only_outputs':'Counts, per-owner exact polygon types/coordinates/ordinals, unmatched exact primitives. No new expected rows or tolerance.',
    'scope':'Only fixed original EDCB packet variant decode; no PNG/Image load/decode, Scene/Layout Resource loads, C.prepare/resolve/collectors, Geometry2D, raster/mask/body/route/Field/Physics or native publication.',
    'engine_runs':0,'native_variant_decodes':0,'PNG_decodes':0,'canonical_writes':0,'Root_approval_and_execution_required':True}
p=OUT/'handoff_READY.json';assert not p.exists();p.write_bytes((json.dumps(handoff,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(pin(p)))
