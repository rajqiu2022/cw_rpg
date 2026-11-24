"""Exact, reversible LifeSkills candidate; no canonical writes/engine/save IO."""
from pathlib import Path
import hashlib,json,difflib,sys
HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
SOURCE=GAME/'scripts/life_skills/life_skills.gd'
raw=SOURCE.read_bytes()
eol='\r\n' if raw.count(b'\r\n')==raw.count(b'\n') and b'\r\n' in raw else '\n'
text=raw.decode().replace('\r\n','\n')
before=text
def replace(a,b):
 global text
 assert text.count(a)==1,(a[:120],text.count(a))
 text=text.replace(a,b,1)
replace('const GATHER=preload("res://scripts/life_skills/gathering_service.gd")\n','const GATHER=preload("res://scripts/life_skills/gathering_service.gd")\nconst GATHER_ACTION=preload("res://build/gather_actions_20261030l_system01/gather_action.gd")\n')
replace('var _medicine_owner: Node\n','var _medicine_owner: Node\nvar _gather_action: Node\n')
replace('func _ready() -> void:\n','func _ready() -> void:\n\t_gather_action=GATHER_ACTION.new();_gather_action.name="GatherAction";add_child(_gather_action)\n\t_gather_action.finished.connect(_on_gather_action_finished)\n')
replace('\t_medicine_button.visible=not DialogPlayer.is_playing()','\t_medicine_button.visible=not _gather_action.is_active() and not DialogPlayer.is_playing()')
replace('func _open_panel(station: String, stock: Array, source: Node) -> void:\n','func _open_panel(station: String, stock: Array, source: Node) -> void:\n\tif is_instance_valid(_gather_action) and _gather_action.is_active():return\n')
replace('func _clear_sites() -> void:\n','func _clear_sites() -> void:\n\tif is_instance_valid(_gather_action):_gather_action.cancel("SITE_ROOT_CLEARED")\n')
replace('func _can_interact() -> bool:\n','func _can_interact(allow_owned_action: bool=false) -> bool:\n')
replace('\treturn is_instance_valid(_field) and is_instance_valid(_site_root)','\treturn (allow_owned_action or not is_instance_valid(_gather_action) or not _gather_action.is_active()) and is_instance_valid(_field) and is_instance_valid(_site_root)')
start=text.index('func try_gather(id: String) -> Dictionary:\n')
end=text.index('\nfunc _unhandled_input(',start)
old=text[start:end]
validator=old.replace('func try_gather(id: String) -> Dictionary:','func _validate_gather(id: String, allow_owned_action: bool=false) -> Dictionary:',1)
validator=validator.replace('if not _can_interact() or not _active_sites.has(id):return rejected','if not _can_interact(allow_owned_action) or not _active_sites.has(id):return rejected',1)
validator=validator.replace('if actor==null or not actor.can_move:return rejected','if actor==null or (not actor.can_move and not (allow_owned_action and is_instance_valid(_gather_action) and _gather_action.owns_actor(actor))):return rejected',1)
assert validator.count('var result: Dictionary=GATHER.collect(id);_refresh_sites();EventBus.toast_requested.emit(String(result.message));return result')==1
validator=validator.replace('var result: Dictionary=GATHER.collect(id);_refresh_sites();EventBus.toast_requested.emit(String(result.message));return result','return GATHER.preview(id)',1)
entry='''func try_gather(id: String) -> Dictionary:
	if is_instance_valid(_gather_action) and _gather_action.is_active():return {"ok":false,"pending":false,"message":"正在采集，请稍候。"}
	var ready: Dictionary=_validate_gather(id)
	if ready.get("ok")!=true:
		EventBus.toast_requested.emit(String(ready.get("message","当前不能采集。")));return ready
	var actor: Player=_field.get("_player") as Player
	var site: Dictionary=_active_sites[id]
	var context: Dictionary={"manager":self,"field":_field,"actor":actor,"world":_world,"site_root":_site_root,"field_id":_field_id,"site_id":id,"kind":String(site.type),"resource_foot":site.runtime_foot}
	var result: Dictionary=_gather_action.start(context,GATHER_ACTION.profile_for(String(site.type)),func()->Dictionary:return _validate_gather(id,true),func()->Dictionary:return GATHER.collect(id))
	if result.get("ok")!=true:EventBus.toast_requested.emit(String(result.get("message","当前不能采集。")))
	else:_hint.hide();_medicine_button.hide()
	return result

func _on_gather_action_finished(result: Dictionary) -> void:
	if _can_interact():_refresh_sites()
	if result.get("completed")==true or String(result.get("cancel_reason","")) in ["ESCAPE","MOVE_INPUT","FINAL_VALIDATION"]:
		EventBus.toast_requested.emit(String(result.get("message","采集已取消。")))

func get_gather_action_debug() -> Dictionary:
	return _gather_action.get_debug_state() if is_instance_valid(_gather_action) else {"active":false}

'''
replace(old,entry+validator)
new=text.replace('\n',eol).encode()
assert text.count('GATHER.collect(id)')==1
assert text.count('GATHER.preview(id)')==1
assert raw==before.replace('\n',eol).encode()
rows=[]
a=raw.decode().splitlines(keepends=True);b=new.decode().splitlines(keepends=True)
for g in difflib.SequenceMatcher(None,a,b,autojunk=False).get_grouped_opcodes(5):
 rows.append({'old':''.join(a[g[0][1]:g[-1][2]]),'new':''.join(b[g[0][3]:g[-1][4]])})
forward=raw
for r in rows:
 assert forward.count(r['old'].encode())==1
 forward=forward.replace(r['old'].encode(),r['new'].encode(),1)
assert forward==new
for r in reversed(rows):
 assert forward.count(r['new'].encode())==1
 forward=forward.replace(r['new'].encode(),r['old'].encode(),1)
assert forward==raw
def sha(data):return hashlib.sha256(data).hexdigest()
def put(name,data):
 with (HERE/name).open('xb') as f:f.write(data)
for name,value in [('life_skills.BEFORE.gd',raw),('life_skills_READY.gd',new)]:
 if (HERE/name).exists():assert (HERE/name).read_bytes()==value
 else:put(name,value)
helper=(HERE/'gather_action.gd').read_bytes()
inputs=['scripts/life_skills/gathering_actions_20261030l.json','art/sprites/life_skills_20261030l/gather_herb_right_4f_padded.png','art/sprites/life_skills_20261030l/mine_ore_right_4f_padded.png','art/audio/life_skills_20261030l/herb_rustle_pluck.wav','art/audio/life_skills_20261030l/pickaxe_stone_hit.wav']
input_facts={'game/'+p:{'sha256':sha((GAME/p).read_bytes()),'bytes':(GAME/p).stat().st_size} for p in inputs}
receipt={'status':'CANDIDATE_ONLY_ROOT_ENGINE_AND_DEPLOY_AUTHORITY','target':'game/scripts/life_skills/life_skills.gd','candidate':'game/build/gather_actions_20261030l_system01/life_skills_READY.gd','before_sha256':sha(raw),'after_sha256':sha(new),'bytes':len(new),'replacements':rows,'whole_byte_inverse':True,'new_runtime_modules':{'game/build/gather_actions_20261030l_system01/gather_action.gd':{'sha256':sha(helper),'bytes':len(helper)}},'required_profile':'res://scripts/life_skills/gathering_actions_20261030l.json','profile_not_guessed':True,'runtime_inputs':input_facts,'engine_runs':0,'canonical_writes':0,'save_contents_read':False,'save_writes':0}
encoded=(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode()
put('source_receipt_READY03.json' if '--final-debug' in sys.argv else ('source_receipt_READY02.json' if '--actual-padded-profile' in sys.argv else 'source_receipt_READY.json'),encoded)
print(json.dumps({'before_sha256':sha(raw),'after_sha256':sha(new),'helper_sha256':sha(helper),'receipt_sha256':sha(encoded),'bytes':len(new),'hunks':len(rows)}))
