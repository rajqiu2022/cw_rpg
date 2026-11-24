from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p):return json.loads(p.read_text(encoding='utf8'))
def rpath(p):return 'res://'+p.relative_to(G).as_posix()
def emit(p,b):
 with p.open('xb') as stream:stream.write(b)
 return {'path':rpath(p),'sha256':sha(b),'bytes':len(b)}
old=(N/'overview_eight_fields01_input_NOTREADY.json').read_bytes();assert sha(old)=='4633068fedf42a2e107b2ebb806b23c2b4a60382a3945003ff2439a9ffe56d64'
a=json.loads(old)
def replace(key,name):
 prior=a[key];p=N/name;b=p.read_bytes();del a['sources'][prior];a[key]=rpath(p);a['sources'][rpath(p)]=sha(b)
replace('artisan_helper','artisan_block_projection06_processed_NOTREADY.gd')
replace('temple_builder','temple_native_builder02_direct_UV_NOTREADY.gd')
promotion=G/'build/luoyang_city_finish_20261025i_art01/ten_media30_promotion_ROOT_EXECUTED.json'
raw=promotion.read_bytes();assert sha(raw)=='43289bd6757cb470cdafb955658a386b04faea0143a91d18916fd76461d798a1'
receipt=json.loads(raw);assert receipt['passed'] is True and len(receipt['written'])==30
a['sources'][rpath(promotion)]=sha(raw)
declaration=G/'build/luoyang_city_finish_20261025i_art01/three_buildings_processed_source_declarations01_CANDIDATE.json'
b=declaration.read_bytes();assert sha(b)=='5d60e295a201a7f5be85572c47ae76357b8a81c18740802636e5206ebaa2288b'
a['processed_buildings']=rpath(declaration);a['sources'][rpath(declaration)]=sha(b)
names=['chinese_open_ironwork_v2','pottery_kiln_house_v2','ordinary_kitchen_rear_body_v2'];count=0
for row in receipt['written']:
 p=Path(row['path'])
 if not any(name in p.name for name in names):continue
 source=rpath(p);a['sources'][source]=row['sha256'];a['texture_authority'][source]=row['sha256'];count+=1
assert count==9
a['raw_sources']={};a['status']='PROCESSED_THREE_BUILDINGS_EIGHT_FIELDS_AUTHORING_PENDING_ROOT_REVIEW'
a['output_absolute']=(N/'overview_eight_fields02_NOTREADY/output').as_posix()
a['processed_three_source_scope']='All3 PNG/import/ctex Root-promoted43289, no RAW proxy. Uniform/old-pixel scale unchanged; padded source anchors and vertex offsets matched5D60. Not runtime adoption.'
input_bytes=(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode('utf8')
input_pin=emit(N/'overview_eight_fields02_input_NOTREADY.json',input_bytes)
template=(N/'overview_eight_fields01_NOTREADY.gd').read_bytes()
text=template.decode('utf8').replace('overview_eight_fields01_input_NOTREADY.json','overview_eight_fields02_input_NOTREADY.json')
key_pin=emit(N/'overview_eight_fields02_NOTREADY.gd',text.encode('utf8'))
# Finite preflight only: declared inputs are exact. This is not a source collector.
for path,expected in a['sources'].items():
 actual=sha((G/path[6:]).read_bytes());assert actual==expected,(path,expected,actual)
assert all(len(h)==64 for h in a['sources'].values())
parse_names=['gate_yamen_projection03_NOTREADY.gd','artisan_block_projection06_processed_NOTREADY.gd','adjacent_courts_projection03_NOTREADY.gd','city_purpose_surface01_NOTREADY.gd','temple_native_builder02_direct_UV_NOTREADY.gd','overview_eight_fields02_NOTREADY.gd']
parse=[{'path':rpath(N/name),'sha256':sha((N/name).read_bytes()),'bytes':(N/name).stat().st_size} for name in parse_names]
proof={'status':'UNIFIED_SOURCE_AUTHORING_OVERVIEW_NOT_ROOT_READY_NOT_ENGINE','key':key_pin,'input':input_pin,'parse_once_candidates':parse,'one_new_shader':{'path':a['surface_shader'],'sha256':a['sources'][a['surface_shader']]},'all_declared_finite_input_bytes_checked':True,'no_packet_decode_or_collector':True,'canonical_writes':0,'engine_calls':0,'import_calls':0,'Root_only_next_action':'Review then one non-business load/can-instantiate parse of six new GD; mechanically Ready input/key, one eight-field authoring GPU overview. No old Temple/Axis prior replay.'}
proof_pin=emit(N/'overview_eight_fields02_handoff_NOTREADY.json',(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode('utf8'))
print(json.dumps({'key':key_pin,'input':input_pin,'handoff':proof_pin,'parse_candidates':parse,'finite_sources':len(a['sources'])}))
