from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;GAME=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
    with (N/name).open('xb') as f:f.write(b)
    return dict(path=NS+name,sha256=sha(b),bytes=len(b))
old=(N/'finish8_source_views02_gate_polygon_key_NOTREADY.gd').read_bytes();assert sha(old)=='e9a14a0e5175c9d8cdc1f81fee2cfd123edf9efda19b2a675a424da6778f3e80'
t=old.decode();hunks=[]
def change(o,n):
    global t
    assert t.count(o)==1;t=t.replace(o,n);hunks.append(dict(old=o,new=n))
change('if old.is_empty() or String(old.get("target_scene",""))!="world_map_jianghu": return {}',
       'if old.is_empty() or String(old.get("action",""))!="world_map" or not String(old.get("target_scene","")).is_empty(): return {}')
change('var next: Dictionary=old.duplicate(true);next.target_scene="ch4_s4_ancient_temple";next.target_pos=Vector2(1380,980)/Vector2(1536,1024)',
       'var next: Dictionary=old.duplicate(true);next.action="";next.target_scene="ch4_s4_ancient_temple";next.target_pos=Vector2(1380,980)/Vector2(1536,1024)\n\t\tnext.label="城内东支路 · 古寺"')
oldend='\treturn result\n'
pos=t.index('static func diagnose(');head=t[:pos];tail=t[pos:]
assert tail.count(oldend)==1
extra='''	if id=="ch4_s2_canal_docks":
		result["native_count"]=native.size();result["DG_entries_count"]=district_entries(inputs.district_author,id).size()
		var parent: Array=docks_parent(native,inputs.docks_projection,inputs.district_author)
		result["parent39_source_projection_count"]=parent.size();result["changed_ids"]=inputs.docks_projection.get("changed_ids",[])
		result["three_rows"]=[]
		for target: String in inputs.docks_projection.get("changed_ids",[]):
			var prior: Dictionary=find(native,target);var declared: Dictionary=find(inputs.docks_projection.originals,target)
			result.three_rows.append({"id":target,"present":not prior.is_empty(),"texture":prior.get("texture"),"expected_texture":declared.get("texture"),"world_foot":prior.get("world_foot_px"),"expected_world_foot":declared.get("world_foot_px"),"render_size":prior.get("render_size_px"),"expected_render_size":declared.get("render_size_px")})
		result["ferry_source_row"]=find(parent_scene.map_layout.portals,"canal_world_ferry").duplicate(true)
		if not parent.is_empty():
			var craft: Dictionary=inputs.craft
			result["adjacent_source_derive_ok"]=helpers.adjacent.derive(id,inputs.adjacent_author,inputs.adjacent_library,parent,find(craft.building_and_life_render,"new_plain_kitchen_rear_house"),parent).get("ok")==true
	return result
'''
tail=tail.replace(oldend,extra);t=head+tail
back=(head+tail.replace(extra,oldend))
for h in reversed(hunks):back=back.replace(h['new'],h['old'])
assert back.encode()==old
view=emit('finish8_source_views03_ferry_actual_fields_NOTREADY.gd',t.encode())
raw=(N/'finish8_publication_input05_ROOT_READY.json').read_bytes();a=json.loads(raw)
a['ready']=False;a['root_run_authorized']=False;a['output_root']=NS+'publication06/output_NOTREADY'
a['sources'].pop(a['source_views']);a['source_views']=view['path'];a['sources'][view['path']]=view['sha256']
actualpath=NS+'publication05/output_ROOT_READY/35588/result.json'
reportbytes=(N/'publication05/output_ROOT_READY/35588/result.json').read_bytes();assert sha(reportbytes)=='3dc44eda4ecf8401b3981ba841a6d77f4b8eb37ce3337300fce5a917dc8d764a'
r=json.loads(reportbytes);assert r['source_first']==r['source_final'] and len(r['scenes'])==2
a['sources'][actualpath]=sha(reportbytes)
a['inherited_scenes']=r['scenes']
def pin_artifacts(value):
    if isinstance(value,dict):
        if {'path','sha256'}<=value.keys() and value['path'].startswith('res://'):
            p=value['path'];b=(GAME/p.removeprefix('res://')).read_bytes();assert sha(b)==value['sha256'];a['sources'][p]=value['sha256']
        for v in value.values():pin_artifacts(v)
    elif isinstance(value,list):
        for v in value:pin_artifacts(v)
pin_artifacts(a['inherited_scenes'])
a['inherited_publication_component']={'path':actualpath,'sha256':sha(reportbytes),'whole_pass':False,'scope':'Root explicitly admitted first2 complete scene components; original Docks wholeFAIL preserved. No geometry/raster replay of these2.'}
ip=emit('finish8_publication_input06_NOTREADY.json',(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode())
parent=(N/'publish_finish8_components05_ROOT_READY.gd').read_bytes();keytext=parent.decode();keyhunks=[]
def kchange(o,n):
    global keytext
    assert keytext.count(o)==1;keytext=keytext.replace(o,n);keyhunks.append(dict(old=o,new=n))
kchange('const READY: bool=true','const READY: bool=false')
kchange('const INPUT: String="'+NS+'finish8_publication_input05_ROOT_READY.json"\nconst INPUT_SHA: String="'+sha(raw)+'"','const INPUT: String="'+ip['path']+'"\nconst INPUT_SHA: String="'+ip['sha256']+'"')
kchange('\t\tvar id: String=String(scene_spec.id)\n\t\tvar original_source_scene:',
        '\t\tvar id: String=String(scene_spec.id)\n\t\tif config.inherited_scenes.has(id):\n\t\t\toutputs[id]=config.inherited_scenes[id].duplicate(true)\n\t\t\tcontinue\n\t\tvar original_source_scene:')
back=keytext
for h in reversed(keyhunks):back=back.replace(h['new'],h['old'])
assert back.encode()==parent
key=emit('publish_finish8_components06_NOTREADY.gd',keytext.encode())
proof=emit('publication06_ferry_and_remaining6_inverse_BUILD.json',(json.dumps(dict(status='ROOT_APPROVED_REMAINING6_ONLY_EXACT_FERRY_STORAGE_CONSUMER',entry=key,input=ip,source_views=view,view_parent_sha256=sha(old),view_hunks=hunks,diagnostic_addition=extra,key_parent_sha256=sha(parent),key_hunks=keyhunks,whole_byte_inverse=True,inherited_first2=r['scenes'],original_whole_FAIL_preserved=True,coordinates_native_geometry_and_priors_unchanged=True,semantic_note='Old world exit has action world_map and no target_scene. After explicitly clears action so ExitZone action-first dispatch cannot override the reviewed city target/target_pos. Only same ID local foot3401840 retained.',engine_calls=0,canonical_writes=0),ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(entry=key,input=ip,source_views=view,proof=proof)))
