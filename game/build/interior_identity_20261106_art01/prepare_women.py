"""Archive builtin originals; prepare isolated 4-cell atlases without resampling."""
import hashlib
import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image

O = Path(__file__).resolve().parent
R = O.parents[2]
G = Path("C:/Users/rajqiu/.codex/generated_images/019ff02b-0e55-70f3-82bb-5e5410641bf8")
RAW = R / "assets/raw/interior_identity_20261106"
OUT = O / "processed"
ROWS = {
    "musician": "70dfa6c3-dcb5-4871-821b-cb27523ca6d1",
    "singer": "309d71a7-9876-4db4-ab60-172f662c3b5d",
    "tea_attendant": "b69b4c6f-46fc-4224-98bb-ad933e211662",
    "receptionist": "e53dc3a7-6de3-429e-ab92-534dbc88d18e",
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def record(path, value):
    data = (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    if path.exists():
        assert path.read_bytes() == data, path
    else:
        path.write_bytes(data)


def prepare(role, generation_id, specification):
    source = G / f"exec-{generation_id}.png"
    raw = RAW / f"{role}_idle_v1.png"
    if not raw.exists():
        shutil.copyfile(source, raw)
    assert sha(raw) == sha(source), raw
    prompt = R / f"prompts/interior_identity_20261106/{role}_idle.txt"
    assert sha(prompt) == specification["prompt_sha256"], prompt
    with Image.open(raw) as image:
        assert image.mode == "RGBA", (role, image.mode)
        rgba = np.asarray(image)
    h, w = rgba.shape[:2]
    edges = [round(w * i / 4) for i in range(5)]
    frames = []
    for i, (x0, x1) in enumerate(zip(edges, edges[1:])):
        original = rgba[:, x0:x1]
        y, x = np.where(original[:, :, 3] >= 24)
        xlo, ylo, xhi, yhi = int(x.min()), int(y.min()), int(x.max()) + 1, int(y.max()) + 1
        assert 0 < xlo < xhi < x1 - x0 and 0 < ylo < yhi < h, (role, i)
        body_height = yhi - ylo
        assert body_height >= 320, (role, i, body_height)
        # Use visible sole support, not the canvas center. For the seated atlas
        # the bottom alpha band is below its stool, where the shoes land.
        band = max(3, round(3 * body_height / (95 if role == "musician" else 128)))
        _, support_x = np.where(original[yhi - band:yhi, :, 3] >= 24)
        foot = (round((int(support_x.min()) + int(support_x.max())) / 2), yhi)
        a, b = max(0, xlo - 24), max(0, ylo - 24)
        c, d = min(x1 - x0, xhi + 24), min(h, yhi + 24)
        outside = np.ones(original.shape[:2], dtype=bool)
        outside[b:d, a:c] = False
        clear = outside & (original[:, :, 3] == 1)
        tile = original.copy()
        tile[:, :, 3][clear] = 0
        facts = {
            "frame": i, "source_partition_xyxy": [x0, 0, x1, h],
            "body_box_alpha24_xyxy": [xlo, ylo, xhi, yhi],
            "body_height": body_height, "source_foot": list(foot),
            "support_band": band, "protected_rect_xyxy": [a, b, c, d],
            "exterior_alpha1_cleared": int(clear.sum()),
            "exterior_alpha_gt1_preserved": int((outside & (original[:, :, 3] > 1)).sum()),
        }
        frames.append((tile, original, clear, foot, facts))
    # Align whole unchanged frame rectangles to one integer anchor. Only add
    # transparent black space, including an inter-frame gutter for sampling.
    ax = max(foot[0] for _, _, _, foot, _ in frames) + 32
    ay = max(foot[1] for _, _, _, foot, _ in frames) + 32
    cw = ax + max(tile.shape[1] - foot[0] for tile, _, _, foot, _ in frames) + 32
    ch = ay + max(tile.shape[0] - foot[1] for tile, _, _, foot, _ in frames) + 32
    assert 4 * cw <= 4096 and ch <= 4096
    atlas = np.zeros((ch, 4 * cw, 4), dtype=np.uint8)
    for tile, original, clear, (fx, fy), facts in frames:
        dx, dy = ax - fx, ay - fy
        x = facts["frame"] * cw + dx
        target = atlas[dy:dy + h, x:x + tile.shape[1]]
        target[:] = tile
        assert np.array_equal(target[:, :, :3], original[:, :, :3])
        assert np.array_equal(target[~clear], original[~clear])
        assert (target[:, :, 3][clear] == 0).all()
        facts.update({"cell_translation": [dx, dy], "cell_foot": [ax, ay]})
    candidate = OUT / f"{role}_idle_native_candidate.png"
    if not candidate.exists():
        Image.fromarray(atlas).save(candidate)
    with Image.open(candidate) as decoded:
        assert decoded.mode == "RGBA" and np.array_equal(np.asarray(decoded), atlas)
    result = {
        "role": role, "source": str(raw), "generated_path": str(source),
        "source_sha256": sha(raw), "source_size": [w, h],
        "candidate": str(candidate), "candidate_sha256": sha(candidate),
        "candidate_size": [4 * cw, ch], "grid": [4, 1],
        "cell": [cw, ch], "cell_foot": [ax, ay],
        "body_height": min(f[-1]["body_height"] for f in frames),
        "frames": [f[-1] for f in frames],
        "prompt": str(prompt), "prompt_sha256": sha(prompt),
        "style_references": specification["references"],
        "generation_backend": "builtin_image_gen", "generation_calls": 1,
        "model": None, "model_version": None, "cost": None,
        "all_original_rgb_exact": True, "protected_rgba_exact": True,
        "all_alpha_gt1_exact": True, "padding_rgba": [0, 0, 0, 0],
        "resampled": False, "formal_adoption": False,
    }
    record(raw.with_suffix(".provenance.json"), result)
    return result


if __name__ == "__main__":
    specifications = json.loads((O / "women_dry_run.json").read_text(encoding="utf-8"))["reports"]
    results = [prepare(role, guid, spec) for (role, guid), spec in zip(ROWS.items(), specifications, strict=True)]
    record(O / "women_processing_receipt.json", results)
    for row in results:
        print(row["role"], row["source_size"], row["candidate_size"],
              row["cell"], row["cell_foot"], row["body_height"],
              sum(f["exterior_alpha1_cleared"] for f in row["frames"]))
