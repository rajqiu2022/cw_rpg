"""Root-only offline seal; new outputs only, never deploys/runs engine/saves.

Input must already be Root-approved five-profile binding with actual verified
lossless PNG/.import/.ctex receipts. An incomplete manual proposal is rejected.
"""
from pathlib import Path
import argparse,difflib,hashlib,json
HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def encoded(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def uri(u):
 assert u.startswith('res://') and '..' not in u
 return GAME/u[6:]
def fact(p):return {'sha256':sha(p),'bytes':Path(p).stat().st_size}
def put(p,b):
 assert p.parent==HERE and not p.exists()
 with p.open('xb') as f:f.write(b)
def hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True)
 for context in [4,8,16,32,10000]:
  rows=[{'old':''.join(aa[g[0][1]:g[-1][2]]),'new':''.join(bb[g[0][3]:g[-1][4]])} for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context)]
  if all(a.count(r['old'].encode())==1 and b.count(r['new'].encode())==1 for r in rows):
   proof=a
   for r in rows:proof=proof.replace(r['old'].encode(),r['new'].encode(),1)
   assert proof==b
   for r in reversed(rows):proof=proof.replace(r['new'].encode(),r['old'].encode(),1)
   assert proof==a
   return rows
 raise AssertionError('NONUNIQUE_HUNK')
ap=argparse.ArgumentParser()
ap.add_argument('--root-approved-binding',required=True)
ap.add_argument('--out-prefix',required=True)
args=ap.parse_args()
assert args.out_prefix.replace('_','').isalnum()
binding_path=Path(args.root_approved_binding).resolve()
binding=json.loads(binding_path.read_text(encoding='utf-8-sig'))
assert binding['schema_version']==1 and binding['approved'] is True and binding['approved_by']=='root'
assert binding['helper_sha256'].lower()==sha(HERE/'bridge_visual_patch.gd')
assert binding['shader_sha256'].lower()==sha(HERE/'bridge_partition.gdshader')
overlap_candidate=HERE/'world_v15_stream_overlap_20261018r_CANDIDATE.gd'
assert binding['overlap_sha256'].lower()==sha(overlap_candidate)
assert [r['id'] for r in binding['bridges']]==[f'bridge_{i:02}' for i in range(5)]
inputs={}
for row in binding['bridges']:
 resource=row['resource']
 expected=f"res://art/modules/world_bridges_20261030m/{row['id']}.png"
 assert resource['path']==expected and resource['full_RGBA_exact'] is True and resource['mipmap_count']==0
 for key,path in [('sha256',uri(expected)),('import_sha256',uri(expected+'.import')),('compiled_sha256',uri(resource['compiled_path']))]:
  assert len(resource[key])==64 and resource[key].lower()==sha(path)
  inputs[path.relative_to(GAME.parent).as_posix()]=fact(path)
 assert 0<float(row['scale'])<=1 and abs(float(row['rotation_degrees']))<=15
 assert len(row['source_deck_quad_px'])==4 and row['foreground_parts']
 assert 'PENDING' not in json.dumps(resource)
stream_template=(HERE/'world_v15_visible_stream_20261018r_CANDIDATE.gd').read_bytes()
needle=b'const BRIDGE_BINDING_SHA := "" # ROOT seals only after five actual native profiles/imports.'
assert stream_template.count(needle)==1
binding_sha=sha(binding_path)
sealed=stream_template.replace(needle,('const BRIDGE_BINDING_SHA := "'+binding_sha+'" # Root-approved actual native profiles/imports.').encode(),1)
stream_out=HERE/(args.out_prefix+'_stream_READY.gd')
binding_out=HERE/(args.out_prefix+'_binding_READY.json')
receipt_out=HERE/(args.out_prefix+'_receipt_READY.json')
for out in [stream_out,binding_out,receipt_out]:assert not out.exists()
initial=json.loads((HERE/'candidate_receipt_PENDING.json').read_text(encoding='utf-8'))
targets=[]
for row in initial['targets']:
 target=GAME.parent/row['target'];old=target.read_bytes()
 assert hashlib.sha256(old).hexdigest()==row['old_sha256'],'EXTERNAL_SOURCE_MOVED:'+str(target)
 before=HERE/(target.name+'.BEFORE')
 assert old==before.read_bytes()
 candidate=stream_out if 'visible_stream' in target.name else overlap_candidate
 new=sealed if candidate==stream_out else candidate.read_bytes()
 targets.append({'target':row['target'],'candidate':candidate.relative_to(GAME.parent).as_posix(),'old_sha256':row['old_sha256'],'new_sha256':hashlib.sha256(new).hexdigest(),'bytes':len(new),'replacements':hunks(old,new),'whole_byte_inverse':True})
new_modules={('game/build/world_bridges_20261030m_system01/'+name):fact(HERE/name) for name in ['bridge_visual_patch.gd','bridge_partition.gdshader','bridge_source_rows_READY.json','bridge_inventory_READY.json']}
new_modules['game/art/modules/world_bridges_20261030m/bridge_bindings.json']={'sha256':binding_sha,'bytes':binding_path.stat().st_size,'candidate':binding_out.relative_to(GAME.parent).as_posix()}
receipt={'schema_version':1,'status':'ROOT_APPROVED_SOURCE_CANDIDATE_NOT_ENGINE_VERIFIED','targets':targets,'new_modules':new_modules,'immutable_runtime_inputs':inputs,'binding_sha256':binding_sha,'binding_self_cycle':False,'source_scope':'EXACTLY_TWO_WORLD_ONLY_GD; NO_ROUTER_NATIVE_REGISTRY_SUCCESSOR','runtime_scope':'DESKTOP_WORLD15_ALL5;WEB_ORIGINAL_FALLBACK_UNCHANGED','original93_input_rows_untouched':True,'original88_physical_rows_untouched':True,'all_nonbridge_input_rows_untouched':True,'Root_still_must_parse_and_view5':True,'engine_runs':0,'canonical_writes':0,'save_access':False,'supersedes_receipt_sha256':sha(HERE/'candidate_receipt_PENDING.json')}
put(stream_out,sealed)
put(binding_out,binding_path.read_bytes())
put(receipt_out,encoded(receipt))
print(json.dumps({'receipt':str(receipt_out),**fact(receipt_out),'binding_sha256':binding_sha,'targets':[{k:r[k] for k in ['target','candidate','new_sha256','bytes']} for r in targets]}))
