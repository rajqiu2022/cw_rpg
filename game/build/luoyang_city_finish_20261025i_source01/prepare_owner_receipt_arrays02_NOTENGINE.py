from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 with (N/name).open('xb') as s:s.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
old=(N/'original_owner_receipts01_NOTREADY.gd').read_bytes();assert sha(old)=='5aedc7728234cc01a01e1a0b435913a19461ec4a8435ae9112bfd32ce3424cfc'
text=old.decode();hunks=[]
def change(o,n):
 global text
 assert text.count(o)==1;text=text.replace(o,n);hunks.append({'old':o,'new':n})
change('static func _city_receipt(','''static func _plain_storage_value(raw: Variant) -> Variant:
	if raw is Dictionary:
		if raw.size()==4 and raw.has_all(["array_values","typed_builtin","typed_class_name","typed_script_path"]):
			if not raw.array_values is Array or String(raw.typed_script_path)!="": return null
			var items: Array=[]
			for item: Variant in raw.array_values: items.append(_plain_storage_value(item))
			return Array(items,int(raw.typed_builtin),StringName(raw.typed_class_name),null)
		var result: Dictionary={}
		for key: Variant in raw: result[key]=_plain_storage_value(raw[key])
		return result
	return raw

static func _with_original_arrays(result: Dictionary,blockers: Variant,native_rows: Variant) -> Dictionary:
	if result.is_empty() or not blockers is Array or not native_rows is Array: return {}
	result.original_parent_blockers=blockers.duplicate(true)
	result.original_native_navigation=native_rows.duplicate(true)
	result.original_arrays_expected_from="Original fully validated layout storage, not observed-current values"
	return result

static func _city_receipt(''')
change('return _common(scene,"C_COMPLETE_ORIGINAL",key,int(chosen.token),first,last,finalized)','return _with_original_arrays(_common(scene,"C_COMPLETE_ORIGINAL",key,int(chosen.token),first,last,finalized),chosen.output_layout.get("blockers"),chosen.output_layout.get("visual_objects"))')
change('return _common(scene,kind,key,token,first,last,finalized)','''var packet: Dictionary=family.packet(scene.scene_id) if kind=="QUARTER_ORIGINAL" else family.packet()
	var stored: Dictionary=packet.get("layout_storage",{}).get("fields",{})
	return _with_original_arrays(_common(scene,kind,key,token,first,last,finalized),_plain_storage_value(stored.get("blockers")),_plain_storage_value(stored.get("visual_objects")))''')
change('return _common(scene,"TEMPLE_OWN_FIELD_ORIGINAL",key,token,first,last,finalized)','return _with_original_arrays(_common(scene,"TEMPLE_OWN_FIELD_ORIGINAL",key,token,first,last,finalized),session._layout_storage.get("blockers"),session._layout_storage.get("visual_objects"))')
back=text
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'])
assert back.encode()==old
pin=emit('original_owner_receipts02_source_arrays_NOTREADY.gd',text.encode())
proof=emit('original_owner_receipts02_source_arrays_whole_inverse_BUILD.json',(json.dumps({'status':'ORIGINAL_RECEIPT_EXPECTED_ARRAY_ADAPTER_NOT_RUNTIME_PASS','candidate':pin,'parent_sha256':sha(old),'hunks':hunks,'whole_byte_inverse':True,'array_authority':'C/Temple direct original layout storage; Family original cached packet layout_storage.fields exact array unstorage, same expression as earlier Root parent probe. Never observed Scene values copied into expected.','no_packet_file_decode_or_collector':True,'engine_calls':0,'canonical_writes':0},indent=2)+'\n').encode())
print(json.dumps({'adapter':pin,'proof':proof}))
