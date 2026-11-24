"""A finite data decoder only; source/physical checks are untouched."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/'
parent=HERE/'worker_facts03/C_CANDIDATE.gd';candidate=HERE/'C_finite_packed_polygon_CANDIDATE.gd'
a,b=parent.read_bytes(),candidate.read_bytes();sha=lambda x:hashlib.sha256(x).hexdigest()
assert sha(a)=='b4af3c839ce383634af4c72f407a88dedbbc6559018375465164edc09dc23708'
old='static func _polygon(value: Variant) -> PackedVector2Array: return BASE._polygon(value)\n'
new='static func _polygon(value: Variant) -> PackedVector2Array:\n\tif value is PackedVector2Array:\n\t\tfor point: Vector2 in value:\n\t\t\tif not point.is_finite(): return PackedVector2Array()\n\t\treturn value.duplicate()\n\treturn BASE._polygon(value)\n'
assert a.count(old.encode())==b.count(new.encode())==1
assert a.replace(old.encode(),new.encode(),1)==b and b.replace(new.encode(),old.encode(),1)==a
proof=dict(status='C_FINITE_PACKED_POLYGON_DECODER_BUILD_NOT_RUNTIME',ready=False,
    parent=dict(path=S+'worker_facts03/C_CANDIDATE.gd',sha256=sha(a),bytes=len(a)),
    candidate=dict(path=S+candidate.name,sha256=sha(b),bytes=len(b)),hunks=[dict(old=old,new=new)],wholebyte_forward_inverse=True,
    finite_Packed_Vector2_only=True,reject_INF_NAN=True,return_independent_duplicate=True,original_BASE_fallback_expression_unchanged=True,
    C_object_solids_and_complete_physical_equal_guard_unchanged=True,no_packet_solids_copy_or_tolerance=True,
    consumer_boundaries=['C.object_solids typed native record','Field city_v3_solid_polygons_px decoder','nonprecomputed authoring mask existing call; not rerun'],
    required_CPU=['fixed newpacket record independent object_solids exact33','typed layout visual polygon wrappers decode match same-ID record','old Arrays compare BASE','finite copy mutation isolation','nonfinite Packed and unsupported types reject'],
    engine_calls=0,collector_calls=0,canonical_writes=0,native_republication=False)
raw=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();p=HERE/'C_packed_decoder_wholebyte_inverse_BUILD.json'
with p.open('xb') as stream:stream.write(raw)
print(json.dumps(dict(candidate=proof['candidate'],proof=dict(path=S+p.name,sha256=sha(raw),bytes=len(raw)))))
