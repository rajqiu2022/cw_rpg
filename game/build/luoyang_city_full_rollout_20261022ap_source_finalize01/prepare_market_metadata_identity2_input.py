"""Only prepare frozen double-declaration input; never execute stager."""
import json
from prepare_handoff10 import HERE, resource, sha, write_new

P = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
S = "res://build/luoyang_city_full_rollout_20261022ap_system01/"
pins = {
    "root_scope": {"path": "res://build/luoyang_city_full_rollout_20261022ap_root01/integration8/scope_READY.json", "sha256": "69e98a976785d2bac7628b10c5738719d820cafb9e061dd0dbfa7bddb391d8d7"},
    "parent_stage14": {"path": P + "outputs/root_integration4_market14_stage01/receipt.json", "sha256": "fc3f84514009231a9d8e7b8cd15a4f1f8e4ee2b30b1ef5986c176443c688376e"},
    "parent_owners14": {"path": P + "market14_actual_stage_independent_qa_owner_source_maps_READY.json", "sha256": "c0e45a006f73b3759bcc2fe8fc7346ead6f322b3dc7ac441cd5b209b49298a10"},
    "market_publication17536": {"path": S + "market_alpha_pin_retry6/publication/17536/result.json", "sha256": "0058e2da30d0b0bbccc8579724ff9e916137de583cd3495bd2fdfb6025372511"},
    "market_publisher17536": {"path": S + "market_alpha_pin_retry6/publish_market.gd", "sha256": "7d1a37daba248bf150d00a12edaa6de9597b0253c8171fc00e4bb929a7446ab5"},
    "frozen_ao_manifest": {"path": "res://build/luoyang_market_two_shops_20261021ao_system01/staged_dependency_retry3/ao_manifest.json", "sha256": "c2cff298136ce4a3e97d6d0b87be3c9fe3c6a7577a8185b5bf1547f36477b19e"},
    "declared_ao_parent": {"path": "res://data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/manifest.json", "sha256": "be7cf173c832b1e9d4ab383135700dd0284a351346fd9d1e199a9c5e623e93b9"},
    "system_candidate": {"path": S + "market_two_declared_metadata_successor_READY.json", "sha256": "08e3456d654cfa19442c91540d730a10fec4db1159ed5e1a8250d95e062a38be"},
    "system_proof": {"path": S + "market_two_declared_metadata_successor_proof_READY.json", "sha256": "76d8c84390739bb47a5cd8d76f353d5d578ea55748d4fa17c768aee9b1985483"},
}
for pin in pins.values():
    assert sha(resource(pin["path"]).read_bytes()) == pin["sha256"]
tool = HERE / "stage_market_metadata_identity2_READY.py"
compile(tool.read_bytes(), str(tool), "exec")
spec = {"schema_version": 1, "status": "ROOT_LOCKED_MARKET_MASK_PARENT_EXACT_TWO_METADATA", "output_root": P + "outputs/root_integration8_market_identity_stage01/", "pinned_inputs": pins, "required_generator": {"path": P + tool.name, "sha256": sha(tool.read_bytes()), "pure_patch_utility_sha256": "23f21249602117ae9a3e638c94d5b1a17725d3bc1e9464912115a7ba3da776b4", "root_must_read_before_execution": True}, "scope": "Only two absent root declaration keys from frozen17536/AO/r3; no source key additions or geometry/import/runtime behavior changes; exact2 Root target set; future fresh deployment authorization still required"}
assert not resource(spec["output_root"]).exists()
result = write_new("market_metadata_identity2_ROOT_LOCKED.json", spec)
print(json.dumps({"input_sha256": result, "tool_sha256": spec["required_generator"]["sha256"], "target_count": 2, "stager_executed": False}))
