"""Mechanical instrumentation only; never edits formal source. Root runs Godot separately."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
REL = "game/build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/finish8_runtime_READY.gd"
EXPECTED = "05ef868ff19bb03f81cffe4e1f8f304a6fae3990d3f24bd52637555b25c818e9"
source = (ROOT / REL).read_bytes()
assert hashlib.sha256(source).hexdigest() == EXPECTED, "formal source changed; stop"
text = source.decode("utf-8").replace("\r\n", "\n")
begin = text.index("static func ensure(")
end = text.index("\nfunc acquire(", begin)
old = text[begin:end]
body = old.replace("static func ensure(", "static func _diag_ensure_body(", 1)
replacements = [
    ('\tvar config: Dictionary = _binding()', '\t_diag_mark("original_arrays")\n\tvar config: Dictionary = _binding()\n\t_diag_mark("binding")'),
    ('\tvar previous: Dictionary = _current(scene)', '\t_diag_mark("original_source_receipt_compare")\n\tvar previous: Dictionary = _current(scene)'),
    ('\tvar captured: Dictionary = {}', '\t_diag_mark("lease_lookup_prune")\n\tvar captured: Dictionary = {}'),
    ('\t\tcaptured[path] = FileAccess.get_sha256(path)', '\t\tvar diag_hash_start: int=Time.get_ticks_usec()\n\t\tcaptured[path] = FileAccess.get_sha256(path)\n\t\t_diag_details.append({"kind":"source_hash","path":path,"us":Time.get_ticks_usec()-diag_hash_start})'),
    ('\tvar bytes: PackedByteArray = FileAccess.get_file_as_bytes(row.payload.path)', '\t_diag_mark("required_sources_full_fresh_hash")\n\tvar bytes: PackedByteArray = FileAccess.get_file_as_bytes(row.payload.path)\n\t_diag_mark("payload_read")'),
    ('\tvar raw: Variant = bytes_to_var(bytes)', '\t_diag_mark("payload_bytes_sha")\n\tvar raw: Variant = bytes_to_var(bytes)\n\t_diag_mark("payload_decode")'),
    ('\tvar texture: Texture2D', '\t_diag_mark("payload_whole_validation_fingerprints")\n\tvar texture: Texture2D'),
    ('\t\ttexture = load(String(row.mask.path)) as Texture2D', '\t\ttexture = load(String(row.mask.path)) as Texture2D\n\t\t_diag_mark("mask_texture_load")'),
    ('\t\tmask = texture.get_image() if texture != null else null', '\t\tmask = texture.get_image() if texture != null else null\n\t\t_diag_mark("mask_texture_get_image")'),
    ('\t\tmask_sha = String(row.mask.RGBA_sha256)', '\t\t_diag_mark("mask_validate_convert")\n\t\tmask_sha = String(row.mask.RGBA_sha256)'),
    ('\tvar prepared: Array = []', '\t_diag_mark("mask_rgba_hash")\n\tvar prepared: Array = []'),
    ('\t_states[scene.get_instance_id()] = ', '\t_diag_mark("prepare_solids")\n\t_states[scene.get_instance_id()] = '),
    ('\tvar staged: Dictionary = _states[scene.get_instance_id()]', '\t_diag_mark("state_payload_fingerprint_copy")\n\tvar staged: Dictionary = _states[scene.get_instance_id()]'),
    ('\t\tvar object_texture: Texture2D = load(path) as Texture2D', '\t\tvar diag_texture_start: int=Time.get_ticks_usec()\n\t\tvar diag_texture_was_cached: bool=ResourceLoader.has_cached(path)\n\t\tvar object_texture: Texture2D = load(path) as Texture2D\n\t\t_diag_details.append({"kind":"object_texture_load","path":path,"us":Time.get_ticks_usec()-diag_texture_start,"cached_before":diag_texture_was_cached})'),
    ('\treturn true\n', '\t_diag_mark("object_textures_all")\n\treturn true\n'),
]
for before, after in replacements:
    assert body.count(before) == 1, repr(before)
    body = body.replace(before, after, 1)
wrapper = '''static var _diag_calls: Array=[]
static var _diag_segments: Array=[]
static var _diag_details: Array=[]
static var _diag_last: int=0
static func _diag_mark(label: String) -> void:
	var now: int=Time.get_ticks_usec()
	_diag_segments.append({"phase":label,"us":now-_diag_last})
	_diag_last=Time.get_ticks_usec()
static func diagnostic_calls() -> Array: return _diag_calls.duplicate(true)
static func ensure(scene: SceneScript,parent_native: Array,parent_blockers: Array,original: Dictionary) -> bool:
	_diag_segments=[];_diag_details=[]
	var started: int=Time.get_ticks_usec();_diag_last=started
	var okay: bool=_diag_ensure_body(scene,parent_native,parent_blockers,original)
	_diag_mark("return_tail")
	_diag_calls.append({"scene_id":String(scene.scene_id) if scene!=null else "", "ok":okay,"total_us":Time.get_ticks_usec()-started,"segments":_diag_segments.duplicate(true),"nested_details":_diag_details.duplicate(true)})
	return okay
'''
instrumented = text[:begin] + wrapper + body + text[end:]
inverse = body
for before, after in reversed(replacements):
    assert inverse.count(after) == 1
    inverse = inverse.replace(after, before, 1)
inverse = inverse.replace("static func _diag_ensure_body(", "static func ensure(", 1)
assert inverse == old
assert instrumented.replace(wrapper + body, old, 1) == text
inverse_full = instrumented.replace(wrapper + body, old, 1)
newline = "CRLF" if b"\r\n" in source else "LF"
inverse_bytes = inverse_full.replace("\n", "\r\n").encode("utf-8") if newline == "CRLF" else inverse_full.encode("utf-8")
assert inverse_bytes == source, "whole byte inverse failed"
candidate = instrumented.encode("utf-8")
(OUT / "finish_runtime_instrumented.gd.txt").write_bytes(candidate)
(OUT / "instrumentation_receipt.json").write_text(json.dumps({
    "status":"IN_MEMORY_DIAGNOSTIC_ONLY_NOT_FORMAL_ADOPTION",
    "formal_path":"res://"+REL.removeprefix("game/"),"formal_sha256":EXPECTED,
    "candidate_path":"res://build/loading_20261106_system02/finish_runtime_instrumented.gd.txt",
    "candidate_sha256":hashlib.sha256(candidate).hexdigest(),
    "whole_normalized_inverse_equal":True,"whole_byte_inverse_equal":True,"original_newline":newline,"formal_disk_writes":False,
    "guards_removed":0,"changes":[{"before":a,"after":b} for a,b in replacements],
    "wrapper":wrapper,"old_function":old,
    "measurement_limit":"Pure current-Family cold validation, not same-pair travel; instrumentation overhead included; nested_details are contained within segment totals and must not be summed twice."
},ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"candidate_sha256":hashlib.sha256(candidate).hexdigest(),"inverse_equal":True,"formal_unchanged":hashlib.sha256((ROOT/REL).read_bytes()).hexdigest()==EXPECTED}))
protected = [REL,
"game/project.godot",
"game/scripts/city/luoyang_quarters_family_20261022ap.gd",
"game/scripts/city/luoyang_quarters_index_20261022ap.gd",
"game/data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json",
"game/scripts/field/field_walkable_controller.gd",
"game/build/scene_cleanup_20261102c_system01/closure_READY01/finish8_binding_READY.json",
"game/build/luoyang_city_finish_20261025i_source01/temple_signed_iid_repair01/closure_READY01/original_owner_receipts_READY.gd",
"game/build/loading_20261106_system01/hash_batch.gd"]
(OUT / "plan.json").write_text(json.dumps({
    "status":"ROOT_APPROVED_DIAGNOSTIC_INSTRUMENTATION_ONLY",
    "formal_write_set":[],
    "candidate_write_set":[".gdignore","prepare_probe.py","finish_runtime_instrumented.gd.txt","instrumentation_receipt.json","plan.json","finish_phase_probe.gd","launch_finish_phase_root.ps1","run_metadata_protected_ROOT_ONLY.ps1","source_inventory.json"],
    "root_run_write_set":["run01_finish_diagnostic/appdata/**","run01_finish_diagnostic/localappdata/**","run01_finish_diagnostic/stdout.log","run01_finish_diagnostic/stderr.log","actual/<own_pid>/finish_phase_result.json"],
    "protected_sha256":{"res://"+p.removeprefix("game/"):hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in protected},
    "restrictions":["Root alone launches engine","No user process stop","No true save content read/write/restore","No travel","No failure bypass","Full original FIRST and FINAL independent fresh reads","No header cache adoption","Runtime in-memory instrumentation stripped produces exact formal original bytes"],
    "known_prior":"run07 actual94624: max loading frame4352.838ms, known FIRST+FINAL865.515ms, remaining3487.323ms unassigned; diagnostic pure validation is not a replacement paired benchmark."
},indent=2)+"\n",encoding="utf-8")
(OUT / "source_inventory.json").write_text(json.dumps({"source_paths":protected+[
    "game/build/loading_20261106_system02/"+p for p in [".gdignore","prepare_probe.py","finish_runtime_instrumented.gd.txt","instrumentation_receipt.json","plan.json","finish_phase_probe.gd","launch_finish_phase_root.ps1","run_metadata_protected_ROOT_ONLY.ps1"]
]},indent=2)+"\n",encoding="utf-8")
