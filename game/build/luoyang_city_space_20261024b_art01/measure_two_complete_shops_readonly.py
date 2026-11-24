"""Read-only original PNG metrics; no pixel edits, image output, imports or engine."""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
RAW = ROOT / "assets/raw/luoyang_city_space_20261024b"
rows = []
for kind, door, foot in [
    ("apothecary", [636, 505, 917, 770], [777, 864]),
    ("bookshop", [719, 548, 951, 781], [791, 876]),
]:
    path = RAW / ("luoyang_20261024b_complete_" + kind + "_v1.png")
    image = Image.open(path)
    assert image.mode == "RGBA"
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    width, height = image.size
    margins = [bbox[0] / width, bbox[1] / height, (width - bbox[2]) / width, (height - bbox[3]) / height]
    bw, bh = bbox[2] - bbox[0], bbox[3] - bbox[1]
    dh = door[3] - door[1]
    minimum_scale = 145 / dh
    rows.append({
        "id": kind, "path": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "mode": image.mode, "source_size": [width, height], "complete_a1_bbox_xyxy": list(bbox),
        "complete_a1_size": [bw, bh], "margins_left_top_right_bottom": margins,
        "all_four_margins_at_least_ten_percent": min(margins) >= .10,
        "manual_conservative_door_rect_xyxy_NOT_geometry": door,
        "manual_visual_front_step_foot_NOT_geometry": foot,
        "door_height_source": dh, "door_to_complete_a1_height_ratio": dh / bh,
        "at_door_145_uniform_scale": minimum_scale,
        "at_door_145_complete_a1_world_size": [bw * minimum_scale, bh * minimum_scale],
        "at_complete_a1_width_650_door_height": dh * 650 / bw,
        "status": "RAW_ONLY_PADDING_FAIL_NO_LOCAL_PROCESSING_NO_RUNTIME_ADMISSION"
    })
task_bytes = (ROOT / "prompts/tasks.yaml").read_bytes()
marker = b"  - id: luoyang_20261024b_complete_apothecary_v1"
prefix = task_bytes.split(marker)[0]
expected = "9C27FFC9F97A9BA2C238F6DA8A7BDAB193027E1622445D086BE8B727D7B56544"
prefix_proofs = []
for trim in range(5):
    candidate = prefix if trim == 0 else prefix[:-trim]
    if hashlib.sha256(candidate).hexdigest().upper() == expected:
        prefix_proofs.append({"trim_new_separator_bytes": trim, "old_bytes_preserved": True})
print(json.dumps({"status": "MEASURED_RAW_CANDIDATES_NOT_ADMITTED", "images": rows,
                  "tasks_old_prefix_byte_proof": prefix_proofs,
                  "tasks_after_sha256": hashlib.sha256(task_bytes).hexdigest(),
                  "engine_runs": 0, "image_edits": 0, "calls_per_asset": 1}, indent=2))
