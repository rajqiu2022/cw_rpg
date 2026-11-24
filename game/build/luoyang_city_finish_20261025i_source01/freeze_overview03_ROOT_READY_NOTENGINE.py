"""ROOT explicitly authorized mechanical readiness and single-key parse prelude.
No Godot execution. All old candidates preserved, new output only.
"""
from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 with (N/name).open('xb') as stream:stream.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
raw=(N/'overview_eight_fields02_input_NOTREADY.json').read_bytes();assert sha(raw)=='dd19c3e085e2367037df448bb08b25b795a29d9eedb95c081d17ea02fe766164'
old_input=json.loads(raw);input=copy.deepcopy(old_input);input['ready']=True
input['output_absolute']=(N/'overview_eight_fields04_ROOT_READY/output_ROOT_READY').as_posix()
input['parse_paths']=[input[k] for k in ['axis_helper','artisan_helper','adjacent_helper','surface_factory','temple_builder']]
input['entry_self_hash_authority']='Root launcher locks exact READY key SHA externally; key includes its own file SHA in source_first/source_final, avoiding recursive INPUT/key SHA cycle.'
input_bytes=(json.dumps(input,ensure_ascii=False,indent=2)+'\n').encode('utf8')
ipin=emit('overview_eight_fields04_ROOT_READY_input.json',input_bytes)
old=(N/'overview_eight_fields02_NOTREADY.gd').read_bytes();assert sha(old)=='1b66e68750782cd84d976d156725dce36785dc0659adc770a346a010eca4d13c'
text=old.decode('utf8');hunks=[]
def replace(a,b):
 global text
 assert text.count(a)==1,a
 text=text.replace(a,b);hunks.append({'old':a,'new':b})
replace('const READY: bool=false\nconst INPUT: String="'+NS+'overview_eight_fields02_input_NOTREADY.json"\nconst INPUT_SHA: String="PENDING"\n',
 'const READY: bool=true\nconst INPUT: String="'+ipin['path']+'"\nconst INPUT_SHA: String="'+ipin['sha256']+'"\nconst SELF: String="'+NS+'overview_eight_fields04_ROOT_READY.gd"\n')
replace('\tfor path: String in fixture.sources: values[path]=FileAccess.get_sha256(path)\n\treturn values\n',
 '\tfor path: String in fixture.sources: values[path]=FileAccess.get_sha256(path)\n\t# Entry bytes are separately pinned by ROOT launcher, not cyclically by INPUT.\n\tvalues[SELF]=FileAccess.get_sha256(SELF)\n\treturn values\n')
a='\tcreate_timer(float(fixture.whole_budget_ms)/1000.0).timeout.connect(func() -> void: errors.append("WHOLE_AUTHORING_BUDGET");finish(out,started))\n'
b=a+'''\t# One ROOT process, no early-break: compile every new pure helper and this key.
\tvar parse_paths: Array=fixture.parse_paths.duplicate();parse_paths.append(SELF)
\tfor parse_path: String in parse_paths:
\t\tvar parsed: Variant=ResourceLoader.load(parse_path,"GDScript",ResourceLoader.CACHE_MODE_IGNORE)
\t\tcheck(parsed is GDScript and parsed.can_instantiate(),"LOAD_CAN_INSTANTIATE_ONLY:"+parse_path)
\tif not errors.is_empty(): finish(out,started);return
'''
replace(a,b)
replace('\t\tvar position: Vector2\n','\t\tvar position: Vector2\n\t\tvar fallback_foot: Vector2\n')
replace('\t\t\tposition=v(row.placement_foot_px)*ratio-v(row.source_ground_anchor_px)*sprite.scale\n','\t\t\tposition=v(row.placement_foot_px)*ratio-v(row.source_ground_anchor_px)*sprite.scale\n\t\t\tfallback_foot=v(row.placement_foot_px)*ratio\n')
replace('\t\tvar foot: Vector2=v(row.get("world_foot_px",[position.x,position.y]))\n','\t\t\tfallback_foot=position\n\t\tvar foot: Vector2=v(row.get("world_foot_px",[fallback_foot.x,fallback_foot.y]))\n')
data=text.encode('utf8');key=emit('overview_eight_fields04_ROOT_READY.gd',data)
inverse=text
for h in reversed(hunks):assert inverse.count(h['new'])==1;inverse=inverse.replace(h['new'],h['old'])
assert inverse.encode('utf8')==old
back=copy.deepcopy(input);back['ready']=False;back['output_absolute']=old_input['output_absolute'];del back['parse_paths'];del back['entry_self_hash_authority'];assert back==old_input
proof=emit('overview_eight_fields04_mechanical_whole_inverse_READY.json',(json.dumps({'status':'ROOT_AUTHORIZED_SINGLE_OVERVIEW_READY_NOT_EXECUTED','old_key_sha256':sha(old),'old_input_sha256':sha(raw),'key':key,'input':ipin,'key_hunks':hunks,'key_whole_byte_inverse':True,'input_whole_typed_inverse':True,'input_reverse_serialization_byte_equal':(json.dumps(back,ensure_ascii=False,indent=2)+'\n').encode()==raw,'parse_only_before_all_pure_methods_and_GPU':True,'Root_approved_native_foot_pivot_only_image_position_unchanged':True,'entry_hash_external_root_launcher_no_cycle':True,'engine_calls':0,'import_calls':0,'canonical_writes':0},ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'key':key,'input':ipin,'inverse':proof,'command':'Godot --path F:/Code/RPG_GAME/game --script '+key['path'],'output_absolute':input['output_absolute']}))
