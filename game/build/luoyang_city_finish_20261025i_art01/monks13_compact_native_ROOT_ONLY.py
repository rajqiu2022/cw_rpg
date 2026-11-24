"""Root-only elder86CB formatting. Default is read-only. NO engine/import.

--apply requires a separately pinned explicit user-permission receipt. Never run
the apply mode while permission is pending. Only NEW BUILD output paths are used.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
RAW = ROOT / "assets/raw/luoyang_city_finish_20261025i/cave_keeper_elder_idle_v1.png"
RAW_SHA = "86cbb758e08e52c851abdd2714a5f7d7dddba88c9b07b74fa01c344de7b034d0"
OUT = ROOT / "game/build/luoyang_city_finish_20261025i_art01/monks13_ROOT_ONLY_OUTPUT"
FILES = {
    "clean":"elder86CB_external_alpha1_clean.png",
    "padded":"elder86CB_clean_fullRGBA_padded1792.png",
    "compact":"elder86CB_compact1118_before_Lanczos.png",
    "native":"cave_keeper_elder_idle_v1_runtime.png",
    "receipt":"receipt.json",
}
PROTECT = (397,104,828,1154)  # exclusive, manually frozen around full subject
ROI = (79,70,1197,1188)      # exclusive square1118, native framing only
PAD = 269
NATIVE = (160,160)
EXPECTED_CLEAN_A1 = [397,112,818,1146]
EXPECTED_ELIGIBLE = 1464


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def bbox(mask: np.ndarray) -> list[int] | None:
    yy, xx = np.where(mask)
    return None if not len(xx) else [int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--permission-json", type=Path)
    parser.add_argument("--permission-sha256")
    args = parser.parse_args()
    raw_bytes = RAW.read_bytes()
    assert sha(raw_bytes) == RAW_SHA, "Wrong fixed RAW; stop, never rebase"
    raw_image = Image.open(RAW)
    assert raw_image.mode == "RGBA" and raw_image.size == (1254,1254)
    source = np.array(raw_image, dtype=np.uint8)
    yy, xx = np.indices(source.shape[:2])
    protected = (xx>=PROTECT[0]) & (xx<PROTECT[2]) & (yy>=PROTECT[1]) & (yy<PROTECT[3])
    eligible = (~protected) & (source[:,:,3] == 1)
    assert int(protected.sum()) == 452550
    assert int(eligible.sum()) == EXPECTED_ELIGIBLE
    assert bool((protected | (source[:,:,3] < 2)).all())
    retained_support = (source[:,:,3] > 0) & (~eligible)
    assert bbox(retained_support) == EXPECTED_CLEAN_A1
    x0,y0,x1,y1 = ROI
    inside_roi = (xx>=x0) & (xx<x1) & (yy>=y0) & (yy<y1)
    assert not bool((retained_support & (~inside_roi)).any())
    assert not OUT.exists(), "Fixed output directory must be NEW/ABSENT; no overwrite"
    facts = {
        "status":"READONLY_FIXED_PLAN_NO_PIXEL_OPERATION",
        "raw_path":str(RAW), "raw_sha256":RAW_SHA,
        "protected_rect_xyxy":list(PROTECT), "protected_pixels":int(protected.sum()),
        "eligible_only_external_original_alpha1":int(eligible.sum()),
        "after_authorized_cleanup_support_bbox_derived_only":EXPECTED_CLEAN_A1,
        "compact_source_ROI_xyxy":list(ROI), "compact_size":[1118,1118],
        "normal_resize_factor":160/1118,
        "nominal_A1_height":1034*160/1118,
        "nominal_A1_bottom":(1146-70)*160/1118,
        "manual_core_boot_anchor_in_source":[638,1144],
        "manual_core_boot_in_native_nominal":[80.0,(1144-70)*160/1118],
        "native_anchor_integer_convention":[80,154],
        "original_owner_scale_kept":140/148,
        "original_calibrate_kept":False,
        "original_body_kept":[21.189189189189193,27.243243243243242],
        "permission_received_by_script":False,
        "PNG_writes":0, "Godot_calls":0, "import_or_canonical_writes":0,
    }
    if not args.apply:
        assert args.permission_json is None and args.permission_sha256 is None
        assert sha(RAW.read_bytes()) == RAW_SHA
        print(json.dumps(facts,indent=2))
        return 0

    # Hard permission gate precedes ALL array mutation, padding, crop and resize.
    assert args.permission_json is not None and args.permission_sha256 is not None
    assert len(args.permission_sha256) == 64
    permission_bytes = args.permission_json.read_bytes()
    assert sha(permission_bytes) == args.permission_sha256.lower()
    permit = json.loads(permission_bytes)
    assert permit.get("raw_sha256", "").lower() == RAW_SHA
    assert permit.get("scope") == "elder86CB_only_external_alpha1_and_padding"
    assert permit.get("explicit_human_authorized_cleanup") is True
    assert permit.get("explicit_human_authorized_padding") is True
    assert permit.get("Root_authorized_compact_runtime_reframe") is True
    assert isinstance(permit.get("human_answer_verbatim"), str) and permit["human_answer_verbatim"].strip()
    assert permit.get("no_other_raw_or_prior_permission_reuse") is True
    # A padding-only reply is NOT enough for this particular compact route.

    clean = source.copy()
    clean[:,:,3][eligible] = 0
    assert np.array_equal(clean[:,:,:3], source[:,:,:3]), "AllRGB, includinghiddenRGB, must survive cleanup"
    assert np.array_equal(clean[protected], source[protected])
    assert np.array_equal(clean[:,:,3][~eligible], source[:,:,3][~eligible])
    changed = np.any(clean != source,axis=2)
    assert np.array_equal(changed,eligible)
    assert bbox(clean[:,:,3]>0) == EXPECTED_CLEAN_A1

    padded = np.zeros((1792,1792,4),dtype=np.uint8)
    padded[PAD:PAD+1254,PAD:PAD+1254] = clean
    assert np.array_equal(padded[PAD:PAD+1254,PAD:PAD+1254],clean)
    assert not bool(padded[:PAD].any()) and not bool(padded[PAD+1254:].any())
    assert not bool(padded[:,:PAD].any()) and not bool(padded[:,PAD+1254:].any())

    # Runtime-only reframe discards alpha0 outside; it is not an erasure edit.
    # All source/clean/padded hiddenRGB remains separately preserved above.
    outside_roi = ~inside_roi
    assert not bool((clean[:,:,3][outside_roi] != 0).any())
    compact = clean[y0:y1,x0:x1].copy()
    assert compact.shape == (1118,1118,4)
    support = clean[:,:,3] > 0
    subject_inverse = np.zeros_like(clean)
    subject_inverse[y0:y1,x0:x1] = compact
    assert np.array_equal(subject_inverse[support],clean[support])
    assert np.array_equal(subject_inverse[:,:,3],clean[:,:,3])
    # WholeRGBA inverse, including transparentRGB, uses retained clean outside.
    full_inverse = clean.copy()
    full_inverse[y0:y1,x0:x1] = compact
    assert np.array_equal(full_inverse,clean)
    assert np.array_equal(compact,padded[y0+PAD:y1+PAD,x0+PAD:x1+PAD])

    # Normal interpolation is separately named, NOT a lossless pixel-inverse.
    native_image = Image.fromarray(compact).resize(NATIVE,Image.Resampling.LANCZOS)
    native = np.array(native_image)
    a1 = bbox(native[:,:,3]>0)
    core8 = bbox(native[:,:,3]>=8)
    assert native_image.mode == "RGBA" and native_image.size == NATIVE
    # Frozen limited visual acceptance, not a geometry epsilon or auto-search.
    assert a1 is not None and core8 is not None
    native_checks = {
        "strict160canvas":native.shape == (160,160,4),
        "subject_no_runtime_edge_touch":a1[0]>0 and a1[1]>0 and a1[2]<160 and a1[3]<160,
        "A1_height_about148":146 <= a1[3]-a1[1] <= 150,
        "A1_bottom_about_old154":152 <= a1[3] <= 156,
        "manual_ground_anchor_about_old154":abs((1144-70)*160/1118-154)<0.5,
        "core_complete_inside_A1":a1[0]<=core8[0]<core8[2]<=a1[2] and a1[1]<=core8[1]<core8[3]<=a1[3],
    }
    assert sha(RAW.read_bytes()) == RAW_SHA
    OUT.mkdir()  # exclusive NEW directory, no parents or canonical paths touched
    arrays = {"clean":clean,"padded":padded,"compact":compact,"native":native}
    artifacts = {}
    for key, array in arrays.items():
        path = OUT / FILES[key]
        with path.open("xb") as stream:
            Image.fromarray(array).save(stream,format="PNG")
        decoded = np.array(Image.open(path))
        assert np.array_equal(decoded,array)
        artifacts[key] = {"path":str(path),"sha256":sha(path.read_bytes()),"RGBA_sha256":sha(array.tobytes()),"size":[array.shape[1],array.shape[0]]}
    assert sha(RAW.read_bytes()) == RAW_SHA
    receipt = {
        **facts, "status":"ROOT_EXECUTED_COMPACT_FORMAT_PASSED_PENDING_ART_VIEW" if all(native_checks.values()) else "ROOT_EXECUTED_FORMAT_VISUAL_METRIC_FAIL_RETAIN_NO_AUTO_ADJUST",
        "passed":all(native_checks.values()),
        "permission_received_by_script":True,"permission_path":str(args.permission_json),"permission_sha256":args.permission_sha256.lower(),
        "source_and_RAW_unchanged":True,"allRGB_cleanup_unchanged":True,"protected_fullRGBA_unchanged":True,
        "only1464alpha1_changed":True,"fullRGBA_padding_inverse":True,"all_nonzero_subject_inverse_before_Lanczos":True,
        "discarded_runtime_ROI_outside_alpha_all0":True,"discarded_transparentRGB_not_zeroed_in_original_or_intermediates":True,
        "normal_Lanczos_not_lossless_inverse":True,
        "native_A1_bbox":a1,"native_core_ge8_bbox":core8,"native_checks":native_checks,
        "artifacts":artifacts,"PNG_writes":4,"actual_art_view_required":True,
        "no_automatic_retry_or_ROI_search":True,"current_formal_or_body_binding":False,
    }
    with (OUT / FILES["receipt"]).open("x",encoding="utf-8",newline="\n") as stream:
        json.dump(receipt,stream,indent=2)
        stream.write("\n")
    print(json.dumps({"receipt":str(OUT/FILES["receipt"]),"receipt_sha256":sha((OUT/FILES["receipt"]).read_bytes()),"passed":receipt["passed"]},indent=2))
    return 0 if receipt["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
