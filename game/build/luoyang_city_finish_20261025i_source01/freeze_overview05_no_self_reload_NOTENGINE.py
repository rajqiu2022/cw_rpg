from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 with (N/name).open('xb') as stream:stream.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
old_input=(N/'overview_eight_fields04_ROOT_READY_input.json').read_bytes();assert sha(old_input)=='f25c0eac956ae19ec2f2797a6bfc8ab9460e0a48a6d4ec5e4ff47bf5e3c47443'
a=json.loads(old_input);a['output_absolute']=(N/'overview_eight_fields05_ROOT_READY/output_ROOT_READY').as_posix()
ipin=emit('overview_eight_fields05_ROOT_READY_input.json',(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode())
old=(N/'overview_eight_fields04_ROOT_READY.gd').read_bytes();assert sha(old)=='a3d54fd28e2dd04024a22fb171e40fb26c648d54d7c6946911cbdef3a7409303'
text=old.decode();hunks=[]
def change(o,n):
 global text
 assert text.count(o)==1;text=text.replace(o,n);hunks.append({'old':o,'new':n})
change('const INPUT: String="'+NS+'overview_eight_fields04_ROOT_READY_input.json"\nconst INPUT_SHA: String="f25c0eac956ae19ec2f2797a6bfc8ab9460e0a48a6d4ec5e4ff47bf5e3c47443"\nconst SELF: String="'+NS+'overview_eight_fields04_ROOT_READY.gd"', 'const INPUT: String="'+ipin['path']+'"\nconst INPUT_SHA: String="'+ipin['sha256']+'"\nconst SELF: String="'+NS+'overview_eight_fields05_ROOT_READY.gd"')
change('\t# One ROOT process, no early-break: compile every new pure helper and this key.\n\tvar parse_paths: Array=fixture.parse_paths.duplicate();parse_paths.append(SELF)\n', '\t# Running SELF already compiled and is externally ROOT SHA-pinned. Never hot reload it.\n\t# Five pure dependencies only, once each, no early break.\n\tvar parse_paths: Array=fixture.parse_paths.duplicate()\n')
key=emit('overview_eight_fields05_ROOT_READY.gd',text.encode())
back=text
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'])
assert back.encode()==old
restored=copy.deepcopy(a);restored['output_absolute']=json.loads(old_input)['output_absolute'];assert (json.dumps(restored,ensure_ascii=False,indent=2)+'\n').encode()==old_input
proof=emit('overview_eight_fields05_no_self_reload_whole_inverse_READY.json',(json.dumps({'status':'ROOT_APPROVED_RUNNING_SELF_RELOAD_RESIDUAL_ONLY','parent_key_sha256':sha(old),'parent_input_sha256':sha(old_input),'key':key,'input':ipin,'key_hunks':hunks,'full_key_and_input_byte_inverse':True,'source_graph_geometry_material_and_render_body_unchanged':True,'engine_calls':0,'canonical_writes':0},ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'key':key,'input':ipin,'inverse':proof,'output':a['output_absolute']}))
