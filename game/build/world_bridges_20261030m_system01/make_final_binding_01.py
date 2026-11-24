"""Materialize producer-approved geometry using actual Root decode02 evidence.
Only new System namespace output. No formal deployment or engine/save access.
"""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
profile=HERE/'native_profiles_PENDING_02_FIVE.json'
actual=GAME/'build/world_bridges_20261030m_qa01/import_decode02_actual/100424/result.json'
geometry=GAME/'build/world_bridges_20261030m_art01/source_geometry_ALL_FIVE_V4_FINAL_REFERENCE_ONLY.json'
assert sha(profile)=='082641b70c8762e5f3091f25ca21ceaaf8c89ac82b29908ecdda684e807e52d2'
assert sha(geometry)=='ab4d0a817032ff02c848f0c824736983a1d43d8ef668ec429ad62817f5238156'
data=read(profile);proof=read(actual)
assert proof['passed'] is True and proof['checks']==32 and proof['errors']==[]
assert proof['Field_instances']==0 and proof['World_instances']==0
records={r['id']:r for r in proof['records'] if isinstance(r.get('resource'),dict)}
assert list(records)==[f'bridge_{i:02}' for i in range(5)]
for row in data['bridges']:
 record=records[row['id']];resource=record['resource']
 assert resource['path']==row['resource']['path'] and resource['sha256']==row['resource']['sha256'] and resource['size']==row['resource']['size']
 assert resource['full_RGBA_exact'] is True and resource['mipmap_count']==0
 assert record['source_RGBA8_sha256']==record['imported_RGBA8_sha256']
 for key,path in [('sha256',resource['path']),('import_sha256',resource['path']+'.import'),('compiled_sha256',resource['compiled_path'])]:
  assert path.startswith('res://') and sha(GAME/path[6:])==resource[key]
 row['resource']=resource
 row['decoded_RGBA8_sha256']=record['source_RGBA8_sha256']
data['approved']=True;data['approved_by']='root'
data['status']='ROOT_APPROVED_NATIVE_SOURCE_CANDIDATE_AWAITING_WORLD_GPU_ACCEPTANCE'
data['root_approval']='Producer message explicitly approves five actual geometry AB4D0A81 and native_profiles_PENDING_02_FIVE uniform transforms; System is authorized to seal new namespace only, Root alone deploys.'
data['import_decode_actual']={'path':actual.relative_to(GAME.parent).as_posix(),'sha256':sha(actual),'engine_pid':100424,'checks':32,'errors':0,'full_RGBA_exact_images':5,'geometry_or_GPU_acceptance':False}
data['source_geometry_reference']={'path':geometry.relative_to(GAME.parent).as_posix(),'sha256':sha(geometry),'manual_uncertainty_source_px':20,'not_collision_proof':True}
data['helper_sha256']=sha(HERE/'bridge_visual_patch.gd')
data['shader_sha256']=sha(HERE/'bridge_partition.gdshader')
data['overlap_sha256']=sha(HERE/'world_v15_stream_overlap_20261018r_CANDIDATE.gd')
assert data['helper_sha256']=='ef10cc93e67373f963fd459299a27adc89638491e607a6bdb100a687a9f21256'
out=HERE/'FINAL_01_binding_APPROVED.json'
assert not out.exists()
b=(json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f:f.write(b)
print(json.dumps({'path':str(out),'sha256':sha(out),'bytes':len(b),'bridges':len(data['bridges']),'approved_by':data['approved_by'],'canonical_writes':0,'engine_runs':0}))
