from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 with (N/name).open('xb') as stream:stream.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
def load(p):return json.loads(p.read_text(encoding='utf8'))
old_input=(N/'overview_eight_fields05_ROOT_READY_input.json').read_bytes();assert sha(old_input)=='0c983bef487d0fe1257edd15e1341fa4f267cddbac8a75b0f651637091d11c11'
a=json.loads(old_input);back_expected=copy.deepcopy(a)
stage=load(G/'build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json')
fixed_family=stage['nodes']['expected_Family_sources']['value']['source_sha256']
old_author=load(G/a['artisan_old_author'][6:]);added={}
for group in old_author['scenes'][0]['ground_sections']:
 for path in group.get('clip_textures',{}).values():
  assert path in fixed_family
  assert path not in a['texture_authority']
  added[path]=fixed_family[path]
a['texture_authority'].update(added);a['sources'].update(added)
result_path=N/'overview_eight_fields05_ROOT_READY/output_ROOT_READY/18176/result.json'
raw=result_path.read_bytes();parent=load(result_path);assert parent['errors']==['ROW_TEXTURE:ap_a2_main_loading_street_0_0']
a['sources'][NS+'overview_eight_fields05_ROOT_READY/output_ROOT_READY/18176/result.json']=sha(raw)
a['inherited_images']={}
for id in ['ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen']:
 p=result_path.parent/(id+'.png');b=p.read_bytes();path=NS+'overview_eight_fields05_ROOT_READY/output_ROOT_READY/18176/'+p.name
 a['inherited_images'][id]={'path':path,'sha256':sha(b),'source':'Root actual18176 complete per-scene PNG, wholeFAIL retained; not rerendered'};a['sources'][path]=sha(b)
a['inherited_parse_component']='Five pure dependency load/can_instantiate checks reached before first two rendered PNGs in Root18176. No explicit parse replay; ordinary dependency loads are still necessary for residual business.'
a['output_absolute']=(N/'overview_eight_fields06_ROOT_READY/output_ROOT_READY').as_posix()
ipin=emit('overview_eight_fields06_ROOT_READY_input.json',(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode())
old=(N/'overview_eight_fields05_ROOT_READY.gd').read_bytes();assert sha(old)=='1e484ce76eba8628aa90581691ffa165b941f13e35b750381d4d6fce923c1d96'
text=old.decode();hunks=[]
def change(o,n):
 global text
 assert text.count(o)==1;text=text.replace(o,n);hunks.append({'old':o,'new':n})
change('const INPUT: String="'+NS+'overview_eight_fields05_ROOT_READY_input.json"\nconst INPUT_SHA: String="0c983bef487d0fe1257edd15e1341fa4f267cddbac8a75b0f651637091d11c11"\nconst SELF: String="'+NS+'overview_eight_fields05_ROOT_READY.gd"','const INPUT: String="'+ipin['path']+'"\nconst INPUT_SHA: String="'+ipin['sha256']+'"\nconst SELF: String="'+NS+'overview_eight_fields06_ROOT_READY.gd"')
begin=text.index('\t# Running SELF already compiled');end=text.index('\tvar axis: Variant=',begin)
change(text[begin:end],'\t# Five dependency parse components inherited from ROOT18176; no explicit replay.\n')
anchor='\t\tvar spec: Dictionary=fixture.scenes[index];var id: String=spec.id\n'
insert=anchor+'''\t\tif index<2:
\t\t\tvar inherited: Dictionary=fixture.inherited_images.get(id,{})
\t\t\tif not check(not inherited.is_empty() and FileAccess.get_sha256(inherited.path)==inherited.sha256,"FIXED_ALREADY_RENDERED_VIEW:"+id): break
\t\t\tvar parent_view: Image=Image.load_from_file(inherited.path)
\t\t\tif not check(parent_view!=null and parent_view.get_size()==Vector2i(1024,683),"INHERITED_FULL_VIEW_SIZE:"+id): break
\t\t\tsheet.blit_rect(parent_view,Rect2i(0,0,1024,683),Vector2i(index*1024,0))
\t\t\tcontinue
'''
change(anchor,insert)
key=emit('overview_eight_fields06_ROOT_READY.gd',text.encode())
back=text
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'])
assert back.encode()==old
restore=copy.deepcopy(a)
for path in added:del restore['texture_authority'][path];del restore['sources'][path]
for value in a['inherited_images'].values():del restore['sources'][value['path']]
del restore['sources'][NS+'overview_eight_fields05_ROOT_READY/output_ROOT_READY/18176/result.json']
del restore['inherited_images'];del restore['inherited_parse_component'];restore['output_absolute']=back_expected['output_absolute']
assert (json.dumps(restore,ensure_ascii=False,indent=2)+'\n').encode()==old_input
proof=emit('overview_eight_fields06_atlas_residual_whole_inverse_READY.json',(json.dumps({'status':'ROOT_AUTHORIZED_SIX_REMAINING_VIEWS_ONLY','key':key,'input':ipin,'key_hunks':hunks,'key_and_input_whole_byte_inverse':True,'missing_texture_cause':'Fixture texture_authority originally filtered PNG/JPG/RES, omitted source-declared TRES AtlasTexture for old118 A2 ground prefix. Actual clipTexture keys already in fixed Family table, not new physical assets or observed-livefill.','added_old_AtlasTexture_keys':added,'inherited_two_PNGs':a['inherited_images'],'new_expected_geometry_or_source_author':False,'engine_calls':0,'canonical_writes':0},ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'key':key,'input':ipin,'inverse':proof,'old_AtlasTexture_count':len(added)}))
