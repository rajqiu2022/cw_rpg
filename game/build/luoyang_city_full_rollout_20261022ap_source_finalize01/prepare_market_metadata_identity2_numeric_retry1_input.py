"""NEW source-only input for the sole approved historical int/float pair."""
import json
from prepare_handoff10 import HERE, resource, sha, write_new

P = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
old_path = P + "market_metadata_identity2_ROOT_LOCKED.json"
old_bytes = resource(old_path).read_bytes()
assert sha(old_bytes) == "62264f1e1f8af021d56bcf1e49348f4f7ec2ddbd8f574dd264fca6ac0a0bfd06"
spec = json.loads(old_bytes)
old_tool = resource(spec["required_generator"]["path"]).read_bytes()
assert sha(old_tool) == "6052fd68b17be2f77236b1c71c3f18927fbe6331b332f040f417aa29ed27609e"
new_tool = HERE / "stage_market_metadata_identity2_numeric_retry1_READY.py"
compile(new_tool.read_bytes(), str(new_tool), "exec")
spec["required_generator"]["path"] = P + new_tool.name
spec["required_generator"]["sha256"] = sha(new_tool.read_bytes())
spec["output_root"] = P + "outputs/root_integration8_market_identity_stage02/"
spec["predecessor_input"] = {"path": old_path, "sha256": sha(old_bytes), "original_actual_source_stage_failed_before_any_buffered_output_or_canonical_write": True}
spec["finite_historical_number_representation_rule"] = {"root_explicitly_authorized": True, "frozen_ao_manifest_sha256": "c2cff298136ce4a3e97d6d0b87be3c9fe3c6a7577a8185b5bf1547f36477b19e", "r3_manifest_sha256": "2366dcb6461de06ef1be98f489171fb5cdf93140a3535530bbe7eedd08b159bc", "pointer": ["body_px"], "embedded_exact_typed_pair": "float34.0,float24.0", "actual_exact_typed_pair": "int34,int24(not bool)", "comparison_copy_only": True, "whole_tree_strict_same_after_only_two_indices": True, "all_candidate_authority_native_or_production_bytes_unchanged": True, "global_same_unchanged": True}
assert not resource(spec["output_root"]).exists()
result = write_new("market_metadata_identity2_numeric_retry1_ROOT_LOCKED.json", spec)
print(json.dumps({"input_sha256": result, "tool_sha256": spec["required_generator"]["sha256"], "stager_executed": False, "target_count": 2}))
