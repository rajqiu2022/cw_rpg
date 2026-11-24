"""Explicit31c candidates in this new directory only. No canonical writes/engine."""
from pathlib import Path
import hashlib,json,re,copy,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
OLD=GAME/'build/sect_adoption_20261030n_system01'
def sha(b):return hashlib.sha256(b).hexdigest()
def write(name,data):
 p=HERE/name
 if p.exists():assert p.read_bytes()==data,p
 else:
  with p.open('xb') as f:f.write(data)
 return {'path':str(p.relative_to(GAME.parent)).replace('\\','/'),'bytes':len(data),'sha256':sha(data)}
prefix='res://build/sect_repair_20261031c_system01/'
data=json.loads((OLD/'adoption_data.json').read_text(encoding='utf-8-sig'))
data['layout_version']=3006;data['scope']='ONLY_WUDANG_HUASHAN_OUTDOORS_AND_ORIGINAL_TAIJI_ID_ON_SAME_WUDANG_SITE'
w=data['towns']['openworld_wudang_gate'];h=data['towns']['openworld_huashan_forecourt']
walls=[]
for i,x in enumerate([485.5,945.5,2455.5,3205.5,3955.5,4705.5]):
 poly=[[x-390.5,3775.5],[x+389,3775.5],[x+389,3799.5],[x-390.5,3799.5]]
 walls.append({'path':'Town/GateClosure'+str(i)+'/Body','layer':16,'polygon':poly,'foot':[x,3800]})
w['solids'].extend([{k:v for k,v in row.items() if k!='foot'} for row in walls]);w['new_gate_walls']=walls
w['gate_wall_safe_entry']=[1680,3890];w['purple_arrow']=[2700,1160];w['purple_return']=[2700,1240]
w['portal_feet']={'return_world':[1700,4200],'to_wudang_purple_cloud_court':w['purple_arrow']}
w['inner_source']='openworld_wudang_purple_cloud_court';w['inner_return']=w['purple_return']
a=copy.deepcopy(w);a['id']='openworld_wudang_taiji_court';a['label']='武当派 · 太极场';a['arrival']=[2500,2700]
a['portal_feet']={'return_wudang_gate':[1700,4200],'to_wudang_purple_cloud_court':w['purple_arrow']}
a['old_inner_return_uv']=[.5,.15];a['on_site_alias_of']='openworld_wudang_gate'
data['towns']['openworld_wudang_taiji_court']=a
write('adoption_data.json',(json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode())

entry=(OLD/'router_entry.gd').read_text(encoding='utf8').replace('res://build/sect_adoption_20261030n_system01/adoption_contract.gd',prefix+'adoption_contract.gd')
write('router_entry.gd',entry.rstrip().encode()+b'\n')
field=(OLD/'sect_adoption_field.gd').read_text(encoding='utf8').replace('res://build/sect_adoption_20261030n_system01/adoption_contract.gd',prefix+'adoption_contract.gd')
start=field.index('func prepare_rows(');end=field.index('func _restore_native_terrain(',start)
prepare='''func prepare_rows(scene: SceneScript) -> void:
	var authored:=ADOPTION.raw(scene.scene_id)
	if scene.scene_id in [ADOPTION.WUDANG,ADOPTION.TAIJI]:
		# Merge only original rows of the already-rendered same outdoor site.
		# No duplicate "enter taiji" portal; original purple-cloud target survives.
		var gate:=load("res://data/scenes/openworld_wudang_gate.tres") as SceneScript
		var taiji:=load("res://data/scenes/openworld_wudang_taiji_court.tres") as SceneScript
		npc_rows=gate.npcs.duplicate(true);portal_rows=[];interaction_rows=[]
		var return_id: String="return_wudang_gate" if scene.scene_id==ADOPTION.TAIJI else "return_world"
		var return_source: SceneScript=taiji if scene.scene_id==ADOPTION.TAIJI else gate
		for original: Dictionary in return_source.map_layout.portals:
			if String(original.get("id",""))==return_id:portal_rows.append(original.duplicate(true))
		for original: Dictionary in taiji.map_layout.portals:
			if String(original.get("id",""))=="to_wudang_purple_cloud_court":portal_rows.append(original.duplicate(true))
		interaction_rows.append_array(gate.map_layout.interactions.duplicate(true))
		interaction_rows.append_array(taiji.map_layout.interactions.duplicate(true))
		interaction_rows.append_array(_legacy_hotspots_to_interactions(gate.hotspots))
		interaction_rows.append_array(_legacy_hotspots_to_interactions(taiji.hotspots))
	else:
		npc_rows=scene.npcs.duplicate(true);portal_rows=scene.map_layout.portals.duplicate(true)
		interaction_rows=scene.map_layout.interactions.duplicate(true)
		interaction_rows.append_array(_legacy_hotspots_to_interactions(scene.hotspots))
	if npc_rows.size()!=authored.original_npcs.size() or portal_rows.size()!=2 or not interaction_rows.is_empty():
		_field_loading_failed=true;push_error("[Sect31c] Original business row shape changed");return
	for npc: Dictionary in npc_rows:
		if not authored.npc_feet.has(String(npc.get("npc_id",""))):_field_loading_failed=true;return
		npc.pos=ADOPTION.vec(authored.npc_feet[String(npc.npc_id)])/_world_size
	for portal: Dictionary in portal_rows:
		if not authored.portal_feet.has(String(portal.get("id",""))):_field_loading_failed=true;return
		portal.pos=ADOPTION.vec(authored.portal_feet[String(portal.id)])/_world_size
		portal.size=Vector2(120,90)/_world_size;portal.show_destination_label=true

'''
field=field[:start]+prepare+field[end:]
start=field.index('func _on_exit_triggered(');end=field.index('func get_sect_adoption_debug(',start)
field=field[:start]+'''func _on_exit_triggered(target: String,pos: Vector2,source: Vector2) -> void:
	if not is_instance_valid(native_town) or _current_scene==null:return
	var authored:=ADOPTION.raw(_current_scene.scene_id)
	if _current_scene.scene_id in [ADOPTION.WUDANG,ADOPTION.TAIJI] and target==String(ADOPTION.PURPLE):
		source=ADOPTION.vec(authored.purple_return)/_world_size
	elif _current_scene.scene_id==ADOPTION.TAIJI and target==String(ADOPTION.WUDANG):
		# Keep original return target/UV. Entry explicitly restores the gate identity
		# at its authored outer entry, never alias->World or a default World foot.
		source=ADOPTION.vec(authored.arrival)/_world_size
	elif target==String(authored.inner_source):source=ADOPTION.vec(authored.inner_return)/_world_size
	super._on_exit_triggered(target,pos,source)

'''+field[end:]
field=field.replace('"source_scene_business_retained":true}', '"source_scene_business_retained":true,"taiji_same_site_integrated":_current_scene.scene_id in [ADOPTION.WUDANG,ADOPTION.TAIJI],"retired_same_site_arrow":"to_wudang_taiji_court" if _current_scene.scene_id in [ADOPTION.WUDANG,ADOPTION.TAIJI] else "","original_taiji_business_destination":String(ADOPTION.PURPLE) if _current_scene.scene_id in [ADOPTION.WUDANG,ADOPTION.TAIJI] else "","opaque_actor_ghost":native_town.repair_ghost.get_debug_state()}')
write('sect_field.gd',field.rstrip().encode()+b'\n')
tscn=(OLD/'sect_adoption_field.tscn').read_text(encoding='utf8').replace('res://build/sect_adoption_20261030n_system01/sect_adoption_field.gd',prefix+'sect_field.gd')
write('sect_field.tscn',tscn.rstrip().encode()+b'\n')

targets=[]
for key,scene in [('wudang','scenes/drafts/sect_maps_20261029k/wudang.tscn'),('huashan','scenes/drafts/huashan_map_20261029m/huashan.tscn')]:
 p=GAME/scene;before=p.read_bytes();s=before.decode('utf8');newline='\r\n' if b'\r\n' in before else '\n'
 old=('res://scripts/drafts/sect_maps_20261029k/controller.gd' if key=='wudang' else 'res://scripts/drafts/huashan_map_20261029m/controller.gd')
 assert s.count('path="'+old+'"')==1;s=s.replace('path="'+old+'"','path="'+prefix+key+'_controller.gd"')
 if key=='wudang':
  # Full original PNG, uniformly half size, no texture regions/UV deformation.
  marker='[sub_resource ';i=s.index(marker);s=s[:i]+'[ext_resource type="Texture2D" path="res://art/modules/sect_maps_20261029k/white_wall.png" id="repair_white_wall"]'+newline+newline+s[i:]
  append=''
  for i,row in enumerate(walls):
   x=row['foot'][0];name='GateClosure'+str(i)
   append+=f'''\n[node name="{name}" type="Node2D" parent="Town"]
z_index = 950
z_as_relative = false
position = Vector2({x}, 3800)
metadata/terrain_level = 0
metadata/elevation = 0.0

[node name="Art" type="Sprite2D" parent="Town/{name}"]
position = Vector2(-538, -352.5)
scale = Vector2(0.5, 0.5)
texture = ExtResource("repair_white_wall")
centered = false

[node name="Body" type="StaticBody2D" parent="Town/{name}"]
collision_layer = 16
collision_mask = 0

[node name="Outline" type="CollisionPolygon2D" parent="Town/{name}/Body"]
polygon = PackedVector2Array(-390.5, -24.5, 389, -24.5, 389, -0.5, -390.5, -0.5)
'''
  # Insert before Terrain, preserving all pre-existing node contents and order.
  m=re.search(r'^\[node name="Terrain"[^\n]*',s,re.M);assert m
  s=s[:m.start()]+append.replace('\n',newline)+newline+s[m.start():]
 after=s.encode();write(key+'.tscn.BEFORE',before);fact=write(key+'_BUSINESS_01.tscn',after)
 diff=''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile='game/'+scene,tofile='game/'+scene))
 write(key+'_BUSINESS_01.forward.diff',diff.encode());targets.append({'target':'game/'+scene,'before_sha256':sha(before),'candidate':fact})
write('business_candidate_manifest_01.json',(json.dumps({'status':'INTERMEDIATE_BUSINESS_ONLY_ASSETS_PENDING_NOT_FROZEN','scene_targets':targets,'new_wall_bodies':walls,'taiji_alias':'No direct alias World exit; original return_wudang_gate restored at outer entry.','version':3006,'engine_runs':0,'canonical_writes':0},ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'targets':targets,'new_runtime':[p.name for p in HERE.glob('*.gd')]},ensure_ascii=False))
