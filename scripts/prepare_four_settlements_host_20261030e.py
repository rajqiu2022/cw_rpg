"""Prepare additive native field host and source-pinned routing; no publication here."""
from four_settlements_20261030e import *
import re
HOST='build/four_settlements_20261030e_system01/'
ROWS={
 'openworld_bailu_ferry':('bailu','白鹿渡',[9300,4301.3623]),
 'openworld_east_sea_port':('donghai','东海埠',[11700,3417.3652]),
 'linxi_tutorial':('linxi_master','林西村·师徒院落',[2600,4000]),
 'linxi_village_center':('linxi_center','林西村·村中心',[2600,4000]),
 'linxi_village_scrollmap':('linxi_south','林西村·南坊',[2600,4000]),
 'ch1_s2_qingfeng':('zhuwei','竹尾村',[6500,4704.61]),
 'ch2_s1_zhuwei_market':('zhuwei','竹尾村·晨市',[6500,4704.61])}
def build():
 dst=STAGE/'ready'/HOST;dst.mkdir(parents=True,exist_ok=True)
 out={};original=json.loads((ROOT/'game/build/four_settlements_20261030e_qa/business01.json').read_text('utf-8'))
 for id,(key,label,world) in ROWS.items():
  layout=json.loads((PROJECT/ART/(key+'.json')).read_text('utf-8'));b=layout['business'];returns={}
  for r in original[id]['portals']:
   target=r.get('target_scene','world_map_jianghu' if r.get('action')=='world_map' else '')
   p=b['portal_targets'].get(target,b['portals'].get(r['id']));assert p,(id,r)
   returns[target]=p
  for n in original[id]['npcs']:
   assert n['npc_id'] in b['npcs'] or any(n['npc_id'].startswith(k) for k in b.get('npc_prefixes',{})),n['npc_id']
  out[id]={'id':id,'key':key,'label':label,'scene':'res://scenes/drafts/'+NAME+'/'+key+'.tscn','size':layout['size'],'arrival':layout['spawn'],'returns':returns,'world_foot':world}
 save(dst/'locations.json',out)
 source=(ROOT/'game/build/sect_completion_20261030a_system01/sect_field.gd').read_text('utf-8')
 # Inherit existing stable NPC/dialog/interaction handling, override only data projection.
 host='''extends "res://build/sect_completion_20261030a_system01/sect_field.gd"
const LOC=preload("res://build/four_settlements_20261030e_system01/locations.gd")
func _load_scene(id:StringName)->SceneScript:
	if not LOC.IDS.has(id):return null
	var scene:SceneScript=load("res://data/scenes/"+String(id)+".tres").duplicate(false)
	scene.actor_positions_are_feet=true
	return scene
func _setup_scene(scene:SceneScript,spawn:Variant=null,progressive:bool=false)->void:
	super._setup_scene(scene,spawn,progressive)
	if _field_loading_failed:return
	_setup_world_travel_minimap(scene)
func get_world_town_debug()->Dictionary:
	return {"id":_current_scene.scene_id,"source_scene":row.scene}
func _setup_world_travel_minimap(scene:SceneScript)->void:
	if not is_instance_valid(_primary_hud):return
	var map:Control=load("res://build/four_settlements_20261030e_system01/minimap.gd").new()
	map.name="CityLocalMinimap";_primary_hud.add_child(map)
	if map.configure(self,scene,_player,_world_camera,world_container):_world_travel_minimap=map
	else:map.queue_free()
func prepare_rows(scene:SceneScript)->void:
	var layout:Dictionary=native_town.layout.business
	npc_rows=scene.npcs.duplicate(true);portal_rows=scene.map_layout.portals.duplicate(true);interaction_rows=scene.map_layout.interactions.duplicate(true)
	for d:Dictionary in npc_rows:
		var a:Array=layout.npcs.get(d.npc_id,[])
		if a.is_empty():
			for prefix in layout.get("npc_prefixes",{}):
				if String(d.npc_id).begins_with(prefix):a=layout.npc_prefixes[prefix];break
		assert(not a.is_empty());d.pos=Vector2(a[0],a[1])/_world_size
	for d:Dictionary in portal_rows:
		var target:String=String(d.get("target_scene","world_map_jianghu" if d.get("action","")=="world_map" else ""))
		var a:Array=layout.portal_targets.get(target,layout.portals.get(d.id,[]));assert(not a.is_empty())
		d.pos=Vector2(a[0],a[1])/_world_size;d.size=Vector2(110,86)/_world_size;d.marker_offset=Vector2.ZERO;d.show_destination_label=true
	for d:Dictionary in interaction_rows:
		var a:Array=layout.interactions.get(d.id,[]);assert(not a.is_empty())
		d.pos=Vector2(a[0],a[1])/_world_size;d.size=Vector2(125,100)/_world_size;d.sect_floor=native_town.terrain.level_at(Vector2(a[0],a[1]));d.visual_baked=true
'''
 (dst/'field.gd').write_text(host,'utf-8')
 legacy=(ROOT/'game/build/luoyang_city_visual_minimap_20261030c_system01/legacy_marker_layout_snapshot.gd').read_text('utf-8')
 legacy=legacy.replace('return CITIES.has(scene.scene_id) or id in REGIONS or id in LUOYANG','return id in '+json.dumps(list(ROWS)) )
 (dst/'minimap_base.gd').write_text(legacy,'utf-8')
 mm=(ROOT/'game/build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd').read_text('utf-8').replace('res://build/luoyang_city_visual_minimap_20261030c_system01/legacy_marker_layout_snapshot.gd','res://'+HOST+'minimap_base.gd')
 (dst/'minimap.gd').write_text(mm,'utf-8')
 (dst/'field.tscn').write_text('[gd_scene load_steps=3 format=3]\n[ext_resource type="PackedScene" path="res://scenes/field_walkable.tscn" id="1"]\n[ext_resource type="Script" path="res://'+HOST+'field.gd" id="2"]\n[node name="SettlementField" instance=ExtResource("1")]\nscript = ExtResource("2")\n','utf-8')
 script='''extends RefCounted
const IDS := %IDS%
const VERSION:=3001
const FIELD:="res://build/four_settlements_20261030e_system01/field.tscn"
static func town(id:StringName)->Dictionary:
	var all:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://build/four_settlements_20261030e_system01/locations.json"))
	var row:Dictionary=all.get(String(id),{}).duplicate(true)
	if row.is_empty():return row
	for k in ["size","arrival","world_foot"]:row[k]=Vector2(row[k][0],row[k][1])
	return row
static func start(router:Node,id:StringName,requested:Variant,action:String,version:int)->bool:
	var row:=town(id)
	if row.is_empty():return false
	if not ContentPackManager.ensure_scene_pack(id,func(ok:bool)->void:
		if ok:router.go_field_smart(id,requested,action,-1,version)
	):return false
	if version>VERSION:return false
	var current:StringName=router.get("_current_field_id");var versions:Dictionary=router.get("_local_layout_versions")
	var foot:Vector2=row.arrival/row.size
	# Preserve only proven current-layout saves; stale coordinates migrate to the authored arrival.
	if current==id and (version==VERSION or (version<0 and int(versions.get(String(id),0))==VERSION)):
		var previous:Variant=requested if requested is Vector2 else router.get("_current_field_spawn")
		if previous is Vector2 and previous.is_finite() and previous.x>=0 and previous.y>=0 and previous.x<=1 and previous.y<=1:foot=previous
	elif row.returns.has(String(current)):
		var a:Array=row.returns[String(current)];foot=Vector2(a[0],a[1])/row.size
	var payload:Dictionary={"scene_id":id,"player_spawn":foot,"three_town_layout_version":VERSION}
	if not action.is_empty():payload.pending_action=action
	router.set("_field_payload",payload);router.set("_current_field_id",id);router.set("_current_field_spawn",foot);versions[String(id)]=VERSION;router.set("_local_layout_versions",versions)
	AudioManager.stop_dialog_audio();router.call("_transition_to",FIELD,&"field",{"title":"进入"+String(row.label)});return true
'''.replace('%IDS%','['+','.join('&'+json.dumps(k) for k in ROWS)+']')
 (dst/'locations.gd').write_text(script,'utf-8')
 print(dst)
if __name__=='__main__':build()
