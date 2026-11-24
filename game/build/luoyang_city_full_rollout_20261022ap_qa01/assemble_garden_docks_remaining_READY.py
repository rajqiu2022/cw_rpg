"""Only remove completed itinerary components from the externally frozen fixture."""
import hashlib
import json
from pathlib import Path

QA = Path(__file__).resolve().parent
base = QA / "bounded_remaining_fade_history_BDE_joint_estate_READY.json"
assert hashlib.sha256(base.read_bytes()).hexdigest() == "0d8b2464e9909ea856cd5c213330429a8941591fc85c9973f2c44e551fd7d956"
plan = json.loads(base.read_bytes())
plan["schema"] = "AP_QA_REMAINING_GARDEN_DOCKS_ONLY"
plan["permitted_remaining_groups"] = ["D"]
plan["groups"] = {"D": {"whole_ms": 180000, "captures": ["ch4_s2_canal_docks"], "doors": [], "links": ["garden_docks"], "dialogues": [], "start": "Explicit legal near Garden exit, not claimed continuous old city travel. Only missing Garden-Docks true Space both directions and final Docks ordinary image. Previously completed Estate-Garden, two pictures and four Garden negative stations are not replayed."}}
plan["completed_D_evidence_not_replayed"] = {"result": "res://build/luoyang_city_full_rollout_20261022ap_qa01/bounded_remaining_fade_history_D/106236_2819/result.json", "overall_result_remains_FAIL": True, "components": ["true_initial_Market_to_Estate", "same_Field_south_loop", "estate_garden_both_directions", "Estate_picture", "Garden_picture", "two_water_two_stone_base_negative_stations"]}
out = QA / "bounded_remaining_garden_docks_READY.json"
assert not out.exists()
payload = (json.dumps(plan, ensure_ascii=False, indent=2) + "\n").encode()
out.write_bytes(payload)
print(json.dumps({"path": str(out), "sha256": hashlib.sha256(payload).hexdigest(), "engine_executed": False, "unchanged_all_source_geometry_actor_expected_maps": True}))
