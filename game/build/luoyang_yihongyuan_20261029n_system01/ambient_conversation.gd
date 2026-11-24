extends RefCounted
## A bounded, zero-effect daily conversation for this one new room only.
const ID := "yihongyuan27n_interior"
var _graph: DialogScript
var _owner: RefCounted
func handles(region: Dictionary,npc: NPCNode) -> bool:
	return region.get("id")==ID and region.get("yihongyuan_daily",{}).has(npc.npc_id)
func open(field: Node,npc: NPCNode) -> Dictionary:
	var region: Dictionary=field.get("_region")
	if not handles(region,npc) or DialogPlayer.is_playing() or _graph!=null:return {"ok":false}
	var owner: RefCounted=field.get("_region_owner")
	if owner==null or not owner.revalidate_boundary(field,field.get("_current_scene"),region):return {"ok":false}
	var rows: Array=region.npcs.filter(func(row: Dictionary) -> bool:return row.data.npc_id==npc.npc_id)
	if rows.size()!=1 or field.get("_region_actors").get(rows[0].slot_key,{}).get("node")!=npc:return {"ok":false}
	var words: Dictionary=region.yihongyuan_daily[npc.npc_id]
	if not words.get("hero") is String or not words.get("lines") is Array or words.lines.is_empty():return {"ok":false}
	_graph=DialogScript.new();_graph.dialog_id=StringName("yihongyuan_daily_"+npc.npc_id);_graph.entry_node_id=&"hero"
	var hero:=DialogNode.new();hero.node_id=&"hero";hero.speaker=GameState.player.display_name
	hero.portrait_path=GameState.player.portrait_path;hero.text=words.hero;hero.on_end="next:npc_0"
	_graph.nodes.append(hero)
	for i: int in range(words.lines.size()):
		var node:=DialogNode.new();node.node_id=StringName("npc_"+str(i));node.speaker=npc.npc_name
		node.portrait_path=npc.portrait_path;node.text=words.lines[i]
		node.on_end="next:npc_"+str(i+1) if i+1<words.lines.size() else "end"
		_graph.nodes.append(node)
	if not owner.pin("yihongyuan_daily"):_graph=null;return {"ok":false}
	_owner=owner
	return {"ok":true,"matched":true,"npc":npc,"script":_graph}
func finish(id: StringName) -> void:
	if _graph==null or _graph.dialog_id!=id:return
	if _owner!=null:_owner.unpin("yihongyuan_daily")
	_graph=null;_owner=null
