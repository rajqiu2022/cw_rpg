"""Finite uninstalled candidate: native texture request batches, original validation retained."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
REL='game/build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/finish8_runtime_READY.gd'
source=(ROOT/REL).read_bytes()
assert hashlib.sha256(source).hexdigest()=='05ef868ff19bb03f81cffe4e1f8f304a6fae3990d3f24bd52637555b25c818e9'
original=source.decode('utf-8').replace('\r\n','\n')
helper='''static func _load_texture_batch(rows: Array,captured: Dictionary,original_first: Dictionary) -> Dictionary:
	# Only prefetch fully source-proved rows. Any malformed row uses the original serial path.
	var paths: Array[String] = []
	var seen: Dictionary = {}
	for object: Dictionary in rows:
		var path: String = String(object.get("texture",""))
		if path.is_empty(): continue
		if not captured.has(path) and not original_first.has(path): return {}
		if not seen.has(path): paths.append(path);seen[path]=true
	var loaded: Dictionary = {}
	for offset: int in range(0,paths.size(),4):
		var requested: Dictionary = {}
		var stop: int = mini(offset+4,paths.size())
		for index: int in range(offset,stop):
			var path: String = paths[index]
			if ResourceLoader.has_cached(path):
				loaded[path]=load(path)
			elif ResourceLoader.load_threaded_request(path,"Texture2D",false)==OK:
				requested[path]=true
		# Drain every request owned by this batch, including a failed resource, before validation.
		for index: int in range(offset,stop):
			var path: String = paths[index]
			if requested.has(path): loaded[path]=ResourceLoader.load_threaded_get(path)
	return loaded

'''
hunks=[
    ('static func ensure(',helper+'static func ensure('),
    ('\tvar staged: Dictionary = _states[scene.get_instance_id()]\n', '\tvar staged: Dictionary = _states[scene.get_instance_id()]\n\tvar batch_textures: Dictionary = _load_texture_batch(raw.effective_navigation,captured,original.source_first)\n'),
    ('\t\tvar object_texture: Texture2D = load(path) as Texture2D\n','\t\tvar object_texture: Texture2D = batch_textures.get(path) as Texture2D\n\t\tif object_texture == null: object_texture = load(path) as Texture2D\n')]
candidate=original
for before,after in hunks:
    assert candidate.count(before)==1
    candidate=candidate.replace(before,after,1)
inverse=candidate
for before,after in reversed(hunks):
    assert inverse.count(after)==1
    inverse=inverse.replace(after,before,1)
assert inverse==original
assert (inverse.replace('\n','\r\n') if b'\r\n' in source else inverse).encode()==source
dest=OUT/'texture_batch_candidate.gd.txt'
dest.write_text(candidate,encoding='utf-8',newline='\n')
(OUT/'texture_candidate_hunks.json').write_text(json.dumps({
    'status':'UNINSTALLED_UNMEASURED_CANDIDATE_NOT_ADMISSION',
    'formal_path':REL,'formal_sha256':hashlib.sha256(source).hexdigest(),
    'candidate_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),
    'whole_byte_inverse_equal':True,
    'hunks':[{'before':a,'after':b} for a,b in hunks],
    'unchanged':['FIRST/FINAL fresh hashes','all required source SHA reads','mask RGBA hash','original object type/path checks and first false outcome','OWNED and lease checks','all formal files'],
    'benefit_bound':'Only 576.765ms measured headless texture segment is targeted; no claim to remove 4.353s frame. Speedup not yet measured.',
    'tradeoff':'At most four unique native resource requests in flight; all successful requests drained before original ordered checks; no scene-tree mutation, persistent application cache, or source receipt reuse added. Prefetch may load later authorized resources before an earlier invalid texture is rejected, so final ordered false outcome is preserved but failure logs/side-effect ordering is not identical to serial. Request ownership means this call received OK and must get; not global ResourceLoader task exclusivity.'
},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'candidate_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'formal_unchanged':hashlib.sha256((ROOT/REL).read_bytes()).hexdigest()==hashlib.sha256(source).hexdigest(),'byte_inverse':True}))
receipt=json.loads((OUT/'instrumentation_receipt.json').read_text(encoding='utf-8'))
instrumented=(OUT/'finish_runtime_instrumented.gd.txt').read_text(encoding='utf-8')
diag_hunks=[('func acquire(',helper+'func acquire(')]+hunks[1:]
diag_hunks.append(('\tvar batch_textures: Dictionary = _load_texture_batch(raw.effective_navigation,captured,original.source_first)\n','\tvar batch_textures: Dictionary = _load_texture_batch(raw.effective_navigation,captured,original.source_first)\n\t_diag_mark("texture_batch_native")\n'))
for before,after in diag_hunks:
    assert instrumented.count(before)==1
    instrumented=instrumented.replace(before,after,1)
receipt['changes'] += [{'before':a,'after':b} for a,b in diag_hunks]
inverse=instrumented.replace(receipt['wrapper'],'').replace('static func _diag_ensure_body(','static func ensure(')
for change in reversed(receipt['changes']):
    assert inverse.count(change['after'])==1
    inverse=inverse.replace(change['after'],change['before'],1)
assert (inverse.replace('\n','\r\n') if b'\r\n' in source else inverse).encode()==source
diagpath=OUT/'texture_batch_instrumented.gd.txt'
diagpath.write_text(instrumented,encoding='utf-8',newline='\n')
receipt['status']='UNINSTALLED_TEXTURE_BATCH_CANDIDATE_MEASUREMENT_NOT_FORMAL_ADMISSION'
receipt['candidate_path']='res://build/loading_20261106_system02/texture_batch_instrumented.gd.txt'
receipt['candidate_sha256']=hashlib.sha256(diagpath.read_bytes()).hexdigest()
(OUT/'texture_instrumentation_receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
probe=(OUT/'finish_phase_probe.gd').read_text(encoding='utf-8').replace('instrumentation_receipt.json','texture_instrumentation_receipt.json').replace('IN_MEMORY_DIAGNOSTIC_ONLY_NOT_FORMAL_ADMISSION_OR_FUNCTIONAL_PASS','UNINSTALLED_TEXTURE_BATCH_CANDIDATE_TIMING_ONLY')
(OUT/'texture_batch_probe.gd').write_text(probe,encoding='utf-8',newline='\n')
inventory=json.loads((OUT/'source_inventory.json').read_text(encoding='utf-8'))
inventory['source_paths'] += ['game/build/loading_20261106_system02/'+p for p in ['prepare_texture_candidate.py','texture_batch_candidate.gd.txt','texture_candidate_hunks.json','texture_batch_instrumented.gd.txt','texture_instrumentation_receipt.json','texture_batch_probe.gd','launch_texture_candidate_root.ps1']]
(OUT/'texture_source_inventory.json').write_text(json.dumps(inventory,indent=2)+'\n',encoding='utf-8')
