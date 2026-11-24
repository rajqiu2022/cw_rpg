"""Static RSRC texture-string field enumeration, not packet/resource/native decode.
Only uncompressed fixed old resource byte fields are read. Expected hashes stay in
the immutable Stage05 tables, never filled from their observed current contents.
"""
from pathlib import Path
import copy,hashlib,json,re,struct
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 with (N/name).open('xb') as stream:stream.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
def load(p):return json.loads(p.read_text(encoding='utf8'))
old_input=(N/'overview_eight_fields06_ROOT_READY_input.json').read_bytes();assert sha(old_input)=='acbb3da29b8a19749f29a8bd1ad286ba34c3a47494dc3e69646ac40b55955ff9'
a=json.loads(old_input)
stage=load(G/'build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json');authority={}
for key,node in stage['nodes'].items():
 if key.startswith('expected_'):
  for path,h in node['value']['source_sha256'].items():
   assert path not in authority or authority[path]==h;authority[path]=h
marker=struct.pack('<II',5,8)+b'texture\0'+struct.pack('<I',5)
specs=[('Estate111','res://data/maps/luoyang_estate_courtyard_20261021am/layout.res',111),('Garden56','res://build/luoyang_garden_river_20261025h_source01/publication01/output/native/luoyang_riverside_garden_20261022ap/layout.res',56),('DocksNative29AndNestedOriginalWharfTexture','res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/layout.res',30)]
audit=[];added={}
for name,path,count in specs:
 b=(G/path[6:]).read_bytes();assert sha(b)==authority[path] and b[:4]==b'RSRC'
 values=[]
 for match in re.finditer(re.escape(marker),b):
  offset=match.end();length=struct.unpack_from('<I',b,offset)[0];start=offset+4
  assert 0<length<4096 and b[start+length-1]==0
  value=b[start:start+length-1].decode('utf8');assert value.startswith('res://') and value in authority,value
  values.append(value)
 assert len(values)==count,(name,len(values),count)
 for value in values:
  if value not in a['texture_authority']:added[value]=authority[value]
 audit.append({'name':name,'layout_path':path,'immutable_layout_sha256':authority[path],'serialized_texture_string_field_count_not_visual_row_count':len(values),'ordered_texture_keys':values,'unique_old_texture_keys':sorted(set(values)),'Docks_extra_field_scope':'Resource text fields include original and successor dry_loading_wharf texture; this does not assert30 actual visual rows. Actual loaded native29 remains strict.' if name.startswith('Docks') else 'Native bound count matched fixed producer count'})
district=load(G/a['district_author'][6:]);dg=district['districts']['ch4_s2_canal_docks']['placements'];assert len(dg)==10
dgtextures=[district['assets'][r['asset_id']]['texture'] for r in dg]
for value in dgtextures:
 assert value in authority
 if value not in a['texture_authority']:added[value]=authority[value]
audit.append({'name':'DocksDG10','exact_texture_field_count':10,'ordered_texture_keys':dgtextures,'combined_navigation_source_row_count':39,'not_task_visual_count':True})
a['texture_authority'].update(added);a['sources'].update(added)
report=N/'overview_eight_fields06_ROOT_READY/output_ROOT_READY/18164/result.json';rb=report.read_bytes();assert load(report)['errors']==['ROW_TEXTURE:estate_an3_north_west_0a']
a['sources'][NS+'overview_eight_fields06_ROOT_READY/output_ROOT_READY/18164/result.json']=sha(rb)
for id in ['luoyang_artisan_residential_20261022ap','ch4_s4_ancient_temple','ch4_s3_luoyang_market']:
 p=report.parent/(id+'.png');b=p.read_bytes();path=NS+'overview_eight_fields06_ROOT_READY/output_ROOT_READY/18164/'+p.name
 a['inherited_images'][id]={'path':path,'sha256':sha(b),'source':'Root actual18164 complete per-scene PNG; wholeFAIL retained, no repeat render'};a['sources'][path]=sha(b)
a['output_absolute']=(N/'overview_eight_fields07_ROOT_READY/output_ROOT_READY').as_posix()
audit_pin=emit('overview_remaining3_static_texture_fields07_READONLY.json',(json.dumps({'status':'STATIC_RS_RESOURCE_TEXTURE_STRING_FIELDS_MATCH_FIXED_OLD_AUTHORITY','rows':audit,'added_old_texture_keys':added,'expected_from':'Immutable25h Stage05 source tables; no current hash fill','packet_decode_calls':0,'ResourceLoader_calls':0,'engine_calls':0},ensure_ascii=False,indent=2)+'\n').encode())
a['sources'][audit_pin['path']]=audit_pin['sha256']
ipin=emit('overview_eight_fields07_ROOT_READY_input.json',(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode())
old=(N/'overview_eight_fields06_ROOT_READY.gd').read_bytes();assert sha(old)=='e28f8d815eadb98dd43061727da82b430568bcec3233652c1b7bdd5c292235bc'
text=old.decode();hunks=[]
def change(o,n):
 global text
 assert text.count(o)==1;text=text.replace(o,n);hunks.append({'old':o,'new':n})
change('const INPUT: String="'+NS+'overview_eight_fields06_ROOT_READY_input.json"\nconst INPUT_SHA: String="acbb3da29b8a19749f29a8bd1ad286ba34c3a47494dc3e69646ac40b55955ff9"\nconst SELF: String="'+NS+'overview_eight_fields06_ROOT_READY.gd"','const INPUT: String="'+ipin['path']+'"\nconst INPUT_SHA: String="'+ipin['sha256']+'"\nconst SELF: String="'+NS+'overview_eight_fields07_ROOT_READY.gd"')
change('\t\tif index<2:\n\t\t\tvar inherited:', '\t\tif index<5:\n\t\t\tvar inherited:')
change('sheet.blit_rect(parent_view,Rect2i(0,0,1024,683),Vector2i(index*1024,0))','sheet.blit_rect(parent_view,Rect2i(0,0,1024,683),Vector2i((index%4)*1024,int(index/4)*683))')
key=emit('overview_eight_fields07_ROOT_READY.gd',text.encode())
inverse=text
for h in reversed(hunks):assert inverse.count(h['new'])==1;inverse=inverse.replace(h['new'],h['old'])
assert inverse.encode()==old
proof=emit('overview_eight_fields07_remaining3_whole_inverse_READY.json',(json.dumps({'status':'ROOT_AUTHORIZED_ONLY_REMAINING_ESTATE_GARDEN_DOCKS_RENDER','key':key,'input':ipin,'static_texture_field_audit':audit_pin,'key_hunks':hunks,'key_full_byte_inverse':True,'old_source_classes_or_runtime_gates_modified':False,'old_material_and_pure_geometry_changed':False,'inherited_first5_full_PNGs':a['inherited_images'],'added_old_AtlasTexture_count':len(added),'engine_calls':0,'canonical_writes':0},ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'key':key,'input':ipin,'inverse':proof,'audit':audit_pin,'new_oldTexture_count':len(added)}))
