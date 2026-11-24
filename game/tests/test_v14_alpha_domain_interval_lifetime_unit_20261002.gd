extends "res://tests/test_v14_alpha_domain_interval_proof_unit_20261002.gd"
## NEW isolated lifetime diagnostic. SOURCE ONLY pending producer execution.
## Replays the frozen98-check synthetic suite, records only WeakRefs to its
## owned images/provers, then observes normal process frames before exit.
## No autoload/manager reset, Field, GPU, save I/O or approval mutation.
## Producer may run --verbose to identify any unrelated ObjectDB warning.

const BASE_PATH := "res://tests/test_v14_alpha_domain_interval_proof_unit_20261002.gd"
const BASE_SHA := "fc4f928e4f8da8c5855346e8947958f0413fc51512144c2d03d516fdfc5b1d66"
var _owned_refs: Array[Dictionary] = []
var _fixture_sequence := 0

func _track(value: Object, label: String) -> void:
	_owned_refs.append({"ref": weakref(value), "label": label, "instance_id": value.get_instance_id(), "class": value.get_class()})

func _fixture(linear: bool = false, transparent: bool = false, prop_size: Vector2i = Vector2i(2, 2), prop_frame: Rect2i = Rect2i(0, 0, 2, 2), prop_rect: Rect2 = Rect2(-1, -1, 2, 2), origin: Vector2 = Vector2(5, 5)) -> Dictionary:
	var data: Dictionary = super._fixture(linear, transparent, prop_size, prop_frame, prop_rect, origin)
	_fixture_sequence += 1
	var prefix := "fixture%d:" % _fixture_sequence
	_track(data.proof, prefix + "proof")
	_track(data.nav, prefix + "original_nav")
	_track(data.prop, prefix + "original_prop")
	_track(data.actor, prefix + "original_actor")
	var mask: Dictionary = data.proof.get("_mask")
	var prop: Dictionary = data.proof.get("_prop")
	_track(mask.image, prefix + "initial_nav_snapshot")
	_track(prop.image, prefix + "initial_prop_snapshot")
	return data

func _run() -> void:
	_check(FileAccess.get_sha256(BASE_PATH).to_lower() == BASE_SHA, "lifetime diagnostic binds frozen FC4F98-check suite")
	_negative_and_positive_cases()
	_narrow_and_linear_cases()
	_closure_and_malformed_cases()
	_source_immutability_cases()
	# Only test-owned strong roots are removed. No speculation about autoloads.
	active.clear()
	results.clear()
	for frame in 4:
		await process_frame
	var retained := 0
	for row: Dictionary in _owned_refs:
		var alive: bool = row.ref.get_ref() != null
		if alive:
			retained += 1
			print("INTERVAL_OWNED_RETAINED label=%s id=%s class=%s" % [row.label, row.instance_id, row["class"]])
		_check(not alive, "test-owned weak reference released: " + String(row.label))
	print("INTERVAL_LIFETIME checks=%d failures=%d fixtures=%d owned_weakrefs=%d retained=%d normal_process_frames=4 base_sha=%s" % [checks, failures, _fixture_sequence, _owned_refs.size(), retained, BASE_SHA])
	_owned_refs.clear()
	quit(0 if failures == 0 else 1)
