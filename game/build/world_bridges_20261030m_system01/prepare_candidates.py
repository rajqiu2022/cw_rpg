"""Two World-specific candidate GDs only. Zero canonical/engine/save writes."""
from pathlib import Path
import difflib,hashlib,json
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
STREAM='scripts/world/world_v15_visible_stream_20261018r.gd'
OVERLAP='scripts/world/world_v15_stream_overlap_20261018r.gd'
EXPECTED={STREAM:'9da2f8b5de0983fa5c23ca07ab651ab4dc0462e7b0353028fbfc96664f5dbba1',OVERLAP:'c41c13fd6f73c3486fcee9fa5d55540c3497f20ef836a383d5a15cf3307d93db'}
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def put(name,b):
 with (HERE/name).open('xb') as f:f.write(b)
def once(s,a,b):assert s.count(a)==1,(a[:100],s.count(a));return s.replace(a,b,1)
def hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True)
 for context in [4,8,16,32,10000]:
  result=[{'old':''.join(aa[g[0][1]:g[-1][2]]),'new':''.join(bb[g[0][3]:g[-1][4]])} for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context)]
  if all(a.count(r['old'].encode())==1 and b.count(r['new'].encode())==1 for r in result):
   forward=a
   for row in result:forward=forward.replace(row['old'].encode(),row['new'].encode(),1)
   assert forward==b
   for row in reversed(result):forward=forward.replace(row['new'].encode(),row['old'].encode(),1)
   assert forward==a
   return result
 raise AssertionError('Nonunique hunk')
before={p:(GAME/p).read_bytes() for p in EXPECTED}
for p,b in before.items():assert sha(b)==EXPECTED[p],('SOURCE_MOVED',p)
new={}
for p,b in before.items():
 eol='\r\n' if b.count(b'\r\n')==b.count(b'\n') and b'\r\n' in b else '\n'
 s=b.decode().replace('\r\n','\n')
 if p==STREAM:
  s=once(s,'const WORLD_CONTRACT = preload("res://scripts/world/world_map_v15_contract.gd")\n','const WORLD_CONTRACT = preload("res://scripts/world/world_map_v15_contract.gd")\nconst BRIDGE30M = preload("res://build/world_bridges_20261030m_system01/bridge_visual_patch.gd")\nconst BRIDGE_BINDING_SHA := "" # ROOT seals only after five actual native profiles/imports.\n')
  start=s.index('static func make_index(objects: Array, size: Vector2) -> Dictionary:\n')
  end=s.index('\nstatic func query(',start)
  original=s[start:end]
  replacement='''static func make_index(objects: Array, size: Vector2) -> Dictionary:
	for raw: Variant in objects:
		if not raw is Dictionary:return {"ok":false,"error":"OBJECT_TYPE"}
	var bridge: Dictionary=BRIDGE30M.prepare(objects,BRIDGE_BINDING_SHA)
	if not bridge.get("ok",false):return bridge
	var entries: Array[Dictionary]=[]
	var bins: Dictionary={}
	var ids: Dictionary={}
	var depth_ordinal:=0
	var bridge_visual_count:=0
	for ordinal in range(objects.size()):
		var source: Dictionary=objects[ordinal]
		var id:=String(source.get("id",""))
		var source_path:=String(source.get("texture",""))
		var source_bounds:=render_bounds(source,size)
		if id.is_empty() or ids.has(id) or source_path.is_empty() or not source_bounds.has_area():return {"ok":false,"error":"OBJECT_BOUNDS_OR_ID"}
		for key: String in ["require_flag","hide_flag","require_quest_active","require_quest_completed","interaction_action","ground_shadow_size_px"]:
			if source.has(key):return {"ok":false,"error":"UNSUPPORTED_WORLD_SEMANTIC:"+key}
		if bool(source.get("sort_by_feet",false)) and (not source.has("depth_sort_foot_y") or not is_finite(float(source.depth_sort_foot_y))):return {"ok":false,"error":"OBJECT_FOOT"}
		ids[id]=true
		# Count original depth slots even when their old visual is retired.
		var original_depth_ordinal: int=depth_ordinal
		if bool(source.get("sort_by_feet",false)):depth_ordinal+=1
		var data: Dictionary=BRIDGE30M.project(source,bridge)
		if data.is_empty():continue
		var path:=String(data.get("texture",""))
		var bounds:=render_bounds(data,size)
		if path.is_empty() or not bounds.has_area():return {"ok":false,"error":"BRIDGE_PRESENTATION_BOUNDS"}
		if data.get("_bridge_native30m",false):bridge_visual_count+=1
		# Sparse presentation array indices are not original source ordinals.
		var entry_index: int=entries.size()
		entries.append({"data":data,"bounds":bounds,"ordinal":ordinal,"depth_ordinal":original_depth_ordinal,"id":id,"path":path})
		for y in range(int(floor(bounds.position.y/BIN)),int(floor(bounds.end.y/BIN))+1):
			for x in range(int(floor(bounds.position.x/BIN)),int(floor(bounds.end.x/BIN))+1):
				var cell:=Vector2i(x,y)
				if not bins.has(cell):bins[cell]=[]
				bins[cell].append(entry_index)
	return {"ok":true,"entries":entries,"bins":bins,"depth_count":depth_ordinal,"bridge_visual_count":bridge_visual_count,"bridge_native_images":5,"bridge_original_visuals":93,"bridge_original_physics_unchanged":true}
'''
  s=once(s,original,replacement)
  s=once(s,'var _bytes:=0\n','var _bytes:=0\nvar _bridge_texture_refs: Dictionary={}\nvar _bridge_texture_costs: Dictionary={}\n')
  s=once(s,'\tmetrics.index_count=_index.entries.size()\n','\tmetrics.index_count=_index.entries.size()\n\tmetrics.bridge_visual_count=int(_index.bridge_visual_count)\n\tmetrics.bridge_native_images=5;metrics.bridge_original_visuals=93;metrics.bridge_original_physics_unchanged=true\n')
  s=once(s,'\t\tvar cost:=texture.get_width()*texture.get_height()*12\n','\t\tvar shared_bridge: String=_index.entries[ordinal].path if _index.entries[ordinal].data.get("_bridge_native30m",false) else ""\n\t\tvar native_cost:=texture.get_width()*texture.get_height()*12\n\t\tvar cost: int=0 if not shared_bridge.is_empty() and _bridge_texture_refs.has(shared_bridge) else native_cost\n')
  s=once(s,'\t\t_loaded[ordinal]={"node":node,"bytes":cost}\n\t\t_bytes+=cost\n','\t\tif not BRIDGE30M.attach(node,_index.entries[ordinal].data):\n\t\t\tfield.call("_detach_world_v15_visual",node);error="WORLD_BRIDGE_NATIVE_ATTACH_FAILED";return\n\t\t_loaded[ordinal]={"node":node,"bytes":cost,"shared_bridge":shared_bridge}\n\t\tif not shared_bridge.is_empty():\n\t\t\t_bridge_texture_refs[shared_bridge]=int(_bridge_texture_refs.get(shared_bridge,0))+1\n\t\t\t_bridge_texture_costs[shared_bridge]=native_cost\n\t\t_bytes+=cost\n')
  s=once(s,'\t_bytes-=int(row.bytes)\n\t_loaded.erase(ordinal)\n','\tvar shared_bridge: String=String(row.get("shared_bridge",""))\n\tif shared_bridge.is_empty():_bytes-=int(row.bytes)\n\telse:\n\t\t_bridge_texture_refs[shared_bridge]=int(_bridge_texture_refs[shared_bridge])-1\n\t\tif int(_bridge_texture_refs[shared_bridge])==0:\n\t\t\t_bytes-=int(_bridge_texture_costs[shared_bridge]);_bridge_texture_refs.erase(shared_bridge);_bridge_texture_costs.erase(shared_bridge)\n\t_loaded.erase(ordinal)\n')
  s=once(s,'\tvar result:=metrics.duplicate(true)\n','\tvar result:=metrics.duplicate(true)\n\tresult.bridge_shared_texture_refs=_bridge_texture_refs.duplicate();result.bridge_binding_sha=BRIDGE_BINDING_SHA\n\tresult.bridge_scope="DESKTOP_ONLY_ALL5_ORIGINAL_WORLD15_PHYSICS"\n')
  s=once(s,'\t_tickets.clear(); _wanted.clear(); _index.clear()\n','\t_tickets.clear(); _wanted.clear(); _index.clear()\n\t_bridge_texture_refs.clear();_bridge_texture_costs.clear()\n')
 else:
  s=once(s,'extends "res://scripts/world/v15_modular_overlap.gd"\n','extends "res://scripts/world/v15_modular_overlap.gd"\nconst BRIDGE30M = preload("res://build/world_bridges_20261030m_system01/bridge_visual_patch.gd")\n')
  s+='\nfunc _alpha_at(sprite: Sprite2D, image: Image, point: Vector2) -> float:\n\t# Same native source partition as GPU; all non-bridge alpha remains parent code.\n\tif not BRIDGE30M.source_pixel_visible(sprite,point):return 0.0\n\treturn super._alpha_at(sprite,image,point)\n'
 new[p]=s.replace('\n',eol).encode()
targets=[]
for p,b in new.items():
 name=Path(p).name
 put(name+'.BEFORE',before[p]);put(name.replace('.gd','_CANDIDATE.gd'),b)
 targets.append({'target':'game/'+p,'candidate':'game/build/world_bridges_20261030m_system01/'+name.replace('.gd','_CANDIDATE.gd'),'old_sha256':sha(before[p]),'new_sha256':sha(b),'bytes':len(b),'replacements':hunks(before[p],b),'whole_byte_inverse':True})
receipt={'status':'PENDING_REAL_NATIVE_PROFILES_SEAL_NOT_DEPLOYABLE','targets':targets,'binding_header_pending':True,'binding_path':'res://art/modules/world_bridges_20261030m/bridge_bindings.json','new_modules':{('game/build/world_bridges_20261030m_system01/'+name):{'sha256':sha((HERE/name).read_bytes()),'bytes':(HERE/name).stat().st_size} for name in ['bridge_visual_patch.gd','bridge_partition.gdshader','bridge_source_rows_READY.json','bridge_inventory_READY.json']},'runtime_scope':'DESKTOP_WORLD15_ALL5; WEB_UNCHANGED_ORIGINAL_FALLBACK','existing_targets_exactly_two_World_only_GD':True,'Router_Field_registry_native_project_writes':0,'physical_source_objects_unchanged':True,'engine_runs':0,'canonical_writes':0,'save_access':False}
data=enc(receipt);put('candidate_receipt_PENDING.json',data)
print(json.dumps({'receipt_sha256':sha(data),'targets':[{'path':r['target'],'sha256':r['new_sha256'],'bytes':r['bytes']} for r in targets],'new_modules':receipt['new_modules']}))
