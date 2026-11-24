"""Create reversible MEMORY-ONLY timers. Does not edit formal files or run Godot."""
from pathlib import Path
import hashlib, json, re

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
sha = lambda b: hashlib.sha256(b).hexdigest()
HOME = 'res://build/loading_20261106_system03/'
HELPER = '''
static func _trace03_begin() -> Array:
	if not Engine.has_meta("loading03_trace"): return []
	var state: Dictionary=Engine.get_meta("loading03_trace")
	if not state.get("enabled",false): return []
	var token: Array=[Time.get_ticks_usec(),state.stack.size(),Engine.get_process_frames()]
	state.stack.append(token[0])
	return token
static func _trace03_end(token: Array,label: String) -> void:
	if token.is_empty(): return
	var ended: int=Time.get_ticks_usec()
	var state: Dictionary=Engine.get_meta("loading03_trace")
	if not state.stack.is_empty(): state.stack.pop_back()
	if state.rows.size()<4096:
		state.rows.append({"name":label,"start_us":token[0],"end_us":ended,"elapsed_us":ended-int(token[0]),"depth":token[1],"start_frame":token[2],"end_frame":Engine.get_process_frames()})
	else: state.dropped+=1
'''

specs = {
 'family': ('game/scripts/city/luoyang_quarters_family_20261022ap.gd', [
 '_finish25i_runtime','original_receipt_for','_finish25i_promote_original_final','_finish25i_ensure',
 '_a2_spec','_a2_header_matches','_a2_published_packet_valid','garden_river_spec','_garden_river_header_matches',
 'source_header','_fresh_source_hashes','manifest','validation_begin','validation_finish','scene_path','packet','matches',
 '_life_spec','_life_header_matches','_life_published_packet_valid','_life_packet_from_bytes']),
 'router': ('game/scripts/autoload/scene_router.gd', [
 'go_field_smart','_go_field_smart_prepared','_load_field_scene_def','_scene_default_spawn',
 '_loading_title_for_field','_ap_market_artisan_header','_transition_to','get_field_scene_path']),
 'adapter': ('game/build/luoyang_city_finish_20261025i_source01/temple_signed_iid_repair01/closure_READY01/original_owner_receipts_READY.gd',[
 'receipt','_family_receipt','_with_original_arrays'])
}
receipts=[]
for group,(path,names) in specs.items():
 raw=(ROOT/path).read_bytes(); original=raw.decode('utf-8'); text=original
 changes=[]
 for name in names:
  pattern = re.compile(r'^(static )?func '+re.escape(name)+r'\(([^\r\n]*)\) -> ([A-Za-z0-9_\[\]]+):\r?$',re.M)
  found=list(pattern.finditer(text)); assert len(found)==1,(path,name,len(found))
  m=found[0]; decl=m.group(0); static=m.group(1) or ''; args=m.group(2); typ=m.group(3)
  argnames=[a.split(':')[0].strip() for a in args.split(',')] if args else []
  assert all(re.fullmatch('[a-zA-Z_][a-zA-Z0-9_]*',a) for a in argnames)
  call='_trace03_original_'+name+'('+','.join(argnames)+')'
  wrapper=decl.rstrip('\r')+'\n\tvar trace03_token: Array=_trace03_begin()\n'
  wrapper+= ('\t'+call+'\n') if typ=='void' else ('\tvar trace03_result: '+typ+'='+call+'\n')
  wrapper+='\t_trace03_end(trace03_token,"'+group+'.'+name+'")\n'
  if typ!='void':wrapper+='\treturn trace03_result\n'
  wrapper+='\n'+decl.replace('func '+name+'(','func _trace03_original_'+name+'(',1)
  text=text[:m.start()]+wrapper+text[m.end():]
  changes.append({'before':decl,'after':wrapper})
 text+=HELPER
 inverse=text[:-len(HELPER)]
 for c in reversed(changes):
  assert inverse.count(c['after'])==1
  inverse=inverse.replace(c['after'],c['before'],1)
 assert inverse.encode('utf-8')==raw
 target=OUT/(group+'_instrumented.gd.txt'); target.write_bytes(text.encode('utf-8'))
 receipts.append({'group':group,'formal_path':'res://'+path.removeprefix('game/'),'formal_sha256':sha(raw),
 'candidate_path':HOME+target.name,'candidate_sha256':sha(target.read_bytes()),'changes':changes,'suffix':HELPER,'exact_byte_inverse':True})

# Reuse the already reviewed exact-body instrumentation, then add absolute clock
# coordinates so its nested segments can be intersected with this same draw gap.
prior=ROOT/'game/build/loading_20261106_system02'
base=json.loads((prior/'instrumentation_receipt.json').read_text('utf-8'))
formal=(ROOT/('game/'+base['formal_path'][6:])).read_bytes()
assert sha(formal)==base['formal_sha256']
old=(prior/'finish_runtime_instrumented.gd.txt').read_bytes().decode('utf-8')
assert sha(old.encode('utf-8'))==base['candidate_sha256']
edits=[
 ('{"phase":label,"us":now-_diag_last}', '{"phase":label,"start_us":_diag_last,"end_us":now,"us":now-_diag_last}'),
 ('"total_us":Time.get_ticks_usec()-started,','"start_us":started,"end_us":Time.get_ticks_usec(),"total_us":Time.get_ticks_usec()-started,'),
 ('"kind":"source_hash","path":path,"us":Time.get_ticks_usec()-diag_hash_start', '"kind":"source_hash","path":path,"start_us":diag_hash_start,"end_us":Time.get_ticks_usec(),"us":Time.get_ticks_usec()-diag_hash_start'),
 ('"kind":"object_texture_load","path":path,"us":Time.get_ticks_usec()-diag_texture_start', '"kind":"object_texture_load","path":path,"start_us":diag_texture_start,"end_us":Time.get_ticks_usec(),"us":Time.get_ticks_usec()-diag_texture_start')]
new=old
for a,b in edits:
 assert new.count(a)==1,a
 new=new.replace(a,b,1)
inverse=new
for a,b in reversed(edits):inverse=inverse.replace(b,a,1)
assert inverse==old
inverse=inverse.replace(base['wrapper'],'',1).replace('static func _diag_ensure_body(','static func ensure(',1)
for c in reversed(base['changes']):inverse=inverse.replace(c['after'],c['before'],1)
if base['original_newline']=='CRLF':inverse=inverse.replace('\n','\r\n')
assert inverse.encode('utf-8')==formal
(OUT/'finish_instrumented.gd.txt').write_bytes(new.encode('utf-8'))
receipts.append({'group':'finish','formal_path':base['formal_path'],'formal_sha256':sha(formal),
 'candidate_path':HOME+'finish_instrumented.gd.txt','candidate_sha256':sha(new.encode('utf-8')),
 'absolute_changes':[{'before':a,'after':b} for a,b in edits],'base_receipt':base,'exact_byte_inverse':True})
(OUT/'instrumentation_receipt.json').write_text(json.dumps({'status':'DIAGNOSTIC_MEMORY_ONLY_NO_FORMAL_ADMISSION','scripts':receipts},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

# Build a one-leg successor, not a repeat of Market/Docks or old matrix.
probe=(ROOT/'game/build/loading_20261106_system01/paired_hash_residual.gd').read_text('utf-8')
probe=probe.replace('## Successor: unchanged one real Space pair, then (outside timing) actual Market/Docks C -> B source admission.','## Same-window diagnostic only; in-memory timers, not formal functional admission.')
probe=probe.replace('res://build/loading_20261106_system01/','res://build/loading_20261106_system03/')
probe=probe.replace('var sample_phase := "setup"','var sample_phase := "setup"\nvar instrumented_scripts: Array[GDScript] = []\nvar finish_runtime: GDScript\nvar instrumentation_ready := false')
probe=probe.replace('\tvar pairs: GDScript = load(PAIR) as GDScript','\tif not install_diagnostic():\n\t\tfinish()\n\t\treturn\n\tvar pairs: GDScript = load(PAIR) as GDScript')
probe=probe.replace('\tstarted_usec = Time.get_ticks_usec()','\tEngine.set_meta("loading03_trace", {"enabled":true,"rows":[],"stack":[],"dropped":0})\n\tstarted_usec = Time.get_ticks_usec()')
start=probe.index('\t# finished already freezes _draw;')
end=probe.index('\tvar output := HOME',start)
probe=probe[:start]+'''\tvar trace: Dictionary=Engine.get_meta("loading03_trace",{})
\ttrace["enabled"]=false
\tvar spans: Array=trace.get("rows",[])
\tvar names: Dictionary={}
\tfor span: Dictionary in spans: names[span.name]=true
\tfor required: String in ["router.go_field_smart","family.validation_begin","family.validation_finish","family.matches","family._finish25i_ensure"]:
\t\tneed(names.has(required),"ACTUAL_TRACE_HIT:"+required)
\tneed(trace.get("dropped",0)==0,"TRACE_NOT_TRUNCATED")
\tvar calls: Array=finish_runtime.call("diagnostic_calls") if finish_runtime!=null else []
\tvar target_calls: Array=[]
\tvar cold_hit:=false
\tfor call_row: Dictionary in calls:
\t\tif int(call_row.get("start_us",0))<started_usec or call_row.get("scene_id")!=String(endpoint.get("target",{}).get("scene_id","")): continue
\t\ttarget_calls.append(call_row)
\t\tfor segment: Dictionary in call_row.get("segments",[]):
\t\t\tif call_row.get("ok",false)==true and segment.get("phase")=="object_textures_all": cold_hit=true
\tneed(cold_hit,"SAME_PAIR_TARGET_COLD_ENSURE_HIT")
\tresult["scope"]="ONE_SAME_WINDOW_MEMORY_INSTRUMENTED_SPACE_PAIR_DIAGNOSTIC_NOT_FORMAL_ADMISSION_OR_FUNCTIONAL_PASS"
\tresult.erase("passed")
\tresult["diagnostic_completed"]=errors.is_empty()
\tresult["checks"]=checks
\tresult["errors"]=errors
\tresult["absolute_spans"]=spans
\tresult["same_pair_ensure_calls"]=target_calls
\tresult["trace_dropped"]=trace.get("dropped",0)
\tresult["limits"]="In-memory exact inverse timers; instrumentation overhead included. Nested spans overlap: union/clip to exact draw interval, never sum nested totals. PC atlas _ready runs before pair; this is not app-start measurement. No header or texture-batch optimization adopted."
''' + probe[end:]
# Avoid huge embedded source receipts. Keep only original scalar evidence.
probe=probe.replace('result["original_validation_receipt"] = load("res://scripts/city/luoyang_quarters_family_20261022ap.gd").call("validation_receipt")', '''var original: Dictionary=load("res://scripts/city/luoyang_quarters_family_20261022ap.gd").call("validation_receipt")
\tresult["original_validation_receipt"]={"source_count":original.get("source_first",{}).size(),"full_source_hash_passes":original.get("full_source_hash_passes",0),"finalized":original.get("finalized",false),"first_hash_elapsed_us":original.get("first_hash_elapsed_us",-1),"final_hash_elapsed_us":original.get("final_hash_elapsed_us",-1)}''')
probe+='''
func install_diagnostic() -> bool:
\tvar receipt: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(HOME+"instrumentation_receipt.json"))
\tfor spec: Dictionary in receipt.scripts:
\t\tvar formal: String=spec.formal_path
\t\tvar candidate: String=spec.candidate_path
\t\tif not need(FileAccess.get_sha256(formal)==spec.formal_sha256 and FileAccess.get_sha256(candidate)==spec.candidate_sha256,"INSTRUMENT_SOURCE_SHA:"+spec.group): return false
\t\tvar code: String=FileAccess.get_file_as_string(candidate)
\t\tvar inverse:=code
\t\tif spec.group=="finish":
\t\t\tvar absolute: Array=spec.absolute_changes.duplicate();absolute.reverse()
\t\t\tfor change: Dictionary in absolute: inverse=inverse.replace(change.after,change.before)
\t\t\tvar base: Dictionary=spec.base_receipt
\t\t\tinverse=inverse.replace(base.wrapper,"").replace("static func _diag_ensure_body(","static func ensure(")
\t\t\tvar changes: Array=base.changes.duplicate();changes.reverse()
\t\t\tfor change: Dictionary in changes: inverse=inverse.replace(change.after,change.before)
\t\t\tif base.original_newline=="CRLF": inverse=inverse.replace("\\n","\\r\\n")
\t\telse:
\t\t\tinverse=inverse.trim_suffix(String(spec.suffix))
\t\t\tvar changes: Array=spec.changes.duplicate();changes.reverse()
\t\t\tfor change: Dictionary in changes: inverse=inverse.replace(change.after,change.before)
\t\tif not need(inverse.to_utf8_buffer()==FileAccess.get_file_as_bytes(formal),"WHOLE_BYTE_INVERSE:"+spec.group): return false
\t\tvar script: GDScript=load(formal) as GDScript
\t\tif not need(script!=null and script.resource_path==formal,"MEMORY_SAME_PATH:"+spec.group): return false
\t\tscript.source_code=code
\t\tif not need(script.reload(true)==OK,"MEMORY_RELOAD_KEEP_STATE:"+spec.group): return false
\t\tinstrumented_scripts.append(script)
\t\tif spec.group=="finish": finish_runtime=script
\tinstrumentation_ready=true
\treturn true
'''
(OUT/'same_window_probe.gd').write_text(probe,encoding='utf-8')
protected=[s['formal_path'] for s in receipts]+[
 'res://project.godot','res://scripts/city/luoyang_quarters_index_20261022ap.gd',
 'res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json',
 'res://scripts/field/field_walkable_controller.gd',
 'res://build/city_navigation_20261101d_candidate01/city_navigation_runtime.gd',
 'res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd',
 'res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd',
 'res://build/scene_cleanup_20261102c_system01/closure_READY01/finish8_binding_READY.json',
 'res://build/loading_20261106_system01/hash_batch.gd',
 'res://build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd',
 'res://art/characters/pc_hd_20261102c/source.json']
plan={'status':'READY_FOR_ROOT_REVIEW_NOT_RUN','formal_write_set':[],
 'memory_reloaded_same_path':[s['formal_path'] for s in receipts],
 'protected_formal_sha256':{p:sha((ROOT/('game/'+p[6:])).read_bytes()) for p in protected},
 'diagnostic_target':'One Civic->Artisan real Space pair, same absolute monotonic clock for nested synchronous calls, finish segments and draw boundaries.',
 'restrictions':['Root only launches','No user process stop','Real saves metadata only explicit15 slots','No formal source/admission changes','Exact whole byte inverse before every in-memory reload','Do not sum overlapping spans','No Market/Docks or old travel matrix','No optimization admission from this diagnostic'],
 'startup_limit':'PCSpriteViewRuntime._ready hashes/loads all mappings before the sampled travel; cost is not attributed to travel. New HD atlas startup remains a separate unmeasured concern.',
 'write_set':['game/build/loading_20261106_system03/**','game/build/loading_20261106_system02/run03_same_window_diagnostic/**'],
 'prior_fact':'run07 max draw14985999..19338837us; navdispatch returns19292043us; Fieldsetup starts20114990us. Independent system02 headless durations are not a decomposition.'}
(OUT/'plan.json').write_text(json.dumps(plan,indent=2)+'\n',encoding='utf-8')
files=['.gdignore','prepare_diagnostic.py','family_instrumented.gd.txt','router_instrumented.gd.txt','adapter_instrumented.gd.txt','finish_instrumented.gd.txt','instrumentation_receipt.json','same_window_probe.gd','plan.json','launch_same_window_ROOT_ONLY.ps1']
(OUT/'source_inventory.json').write_text(json.dumps({'source_paths':protected+[HOME+p for p in files]},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'instrumented_scripts':len(receipts),'whole_byte_inverse_all':True,'formal_writes':0,'protected_formal_count':len(protected)}))
