"""One fixed1150 native reframe from Root's ALREADY cleaned elder, no reclean.

Default read-only. Root reviews this exact successor before --apply. No engine,
import, canonical file writes, thresholding, alpha erasure, retries or ROI search.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
A = ROOT / "game/build/luoyang_city_finish_20261025i_art01"
RAW = ROOT / "assets/raw/luoyang_city_finish_20261025i/cave_keeper_elder_idle_v1.png"
CLEAN = A / "monks13_ROOT_ONLY_OUTPUT/elder86CB_external_alpha1_clean.png"
PADDED = A / "monks13_ROOT_ONLY_OUTPUT/elder86CB_clean_fullRGBA_padded1792.png"
FAIL = A / "monks13_ROOT_ONLY_OUTPUT/receipt.json"
PERMIT = A / "monks14_elder86CB_cleanup_permission_ROOT_ACTUAL.json"
OLD = ROOT / "game/art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png"
PINS = {
    RAW:"86cbb758e08e52c851abdd2714a5f7d7dddba88c9b07b74fa01c344de7b034d0",
    CLEAN:"b25cf1a8015ec07f87d3e8e949041dd4a5b5d13b9d212dd2da4a0a964c138a0a",
    PADDED:"dd590ee73c8ef80248556bacb3cb3a1e8b438fdd219c66a0030ca44d2b908554",
    FAIL:"4576a4b1d2f8edcdd12f408b670e983554fb1987306cf8d68350081c254ba6c5",
    PERMIT:"305cf67363f60f949dbe4caff39b552135e29fb670b4c5f61dd5d03fd016f201",
    OLD:"6268061eab18d2bf8c1ea0c13873f0d718feb82a119f00a67edf7c52bcb077ad",
}
ROI = (63,54,1213,1204)
OUT = A / "monks15_ROOT_ONLY_OUTPUT"

def sha(data):
    return hashlib.sha256(data).hexdigest()

def box(mask):
    yy,xx=np.where(mask)
    return None if not len(xx) else [int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--apply",action="store_true")
    args=p.parse_args()
    for path,expected in PINS.items():
        assert sha(path.read_bytes())==expected, "Fixed input drift: "+str(path)
    assert not OUT.exists(), "NEW output directory must remain ABSENT"
    prior=json.loads(FAIL.read_text(encoding="utf-8"))
    assert prior["passed"] is False and prior["native_A1_bbox"]==[45,4,108,156]
    permit=json.loads(PERMIT.read_text(encoding="utf-8"))
    assert permit["raw_sha256"]==PINS[RAW]
    assert permit["explicit_human_authorized_cleanup"] is True
    assert permit["explicit_human_authorized_padding"] is True
    assert permit["Root_authorized_compact_runtime_reframe"] is True
    clean=np.array(Image.open(CLEAN))
    padded=np.array(Image.open(PADDED))
    assert clean.shape==(1254,1254,4) and padded.shape==(1792,1792,4)
    assert np.array_equal(padded[269:1523,269:1523],clean)
    assert box(clean[:,:,3]>0)==[397,112,818,1146]
    old=np.array(Image.open(OLD))
    assert old.shape==(160,160,4)
    assert box(old[:,:,3]>0)==[52,6,110,154]
    assert box(old[:,:,3]>=8)==[54,8,108,152]
    x0,y0,x1,y1=ROI
    yy,xx=np.indices(clean.shape[:2])
    inside=(xx>=x0)&(xx<x1)&(yy>=y0)&(yy<y1)
    assert not bool((clean[:,:,3][~inside]>0).any())
    facts={
        "status":"READONLY_ONE_DERIVED_ROI_NOT_EXECUTED",
        "input_pins":{str(k):v for k,v in PINS.items()},
        "old_FAIL_preserved":True,
        "repeated_cleanup_or_padding_operations":0,
        "ROI_xyxy":list(ROI),"compact_size":[1150,1150],
        "derivation":"Observed previousLanczos A1 spreadabout2pixels eachend; targetoldA1height148 ->nominal144. L=ceil_even(1034*160/144)=1150. SourceA1centerY629 mapsnative80 ->top54. FixedbootX638 mapsnative80 ->left63.",
        "nominal_clean_A1_top":(112-y0)*160/1150,
        "nominal_clean_A1_bottom":(1146-y0)*160/1150,
        "nominal_core_height":1029*160/1150,
        "manual_source_core_boot":[638,1144],
        "manual_core_boot_native":[80,(1144-y0)*160/1150],
        "old_core_boot_bottom":152,
        "unchanged_outer_foot_convention":[80,154],
        "unchanged_T_scale":140/148,"unchanged_calibrate":False,
        "unchanged_body":[21.189189189189193,27.243243243243242],
        "PNG_writes":0,"engine_import_canonical_writes":0,
    }
    if not args.apply:
        print(json.dumps(facts,indent=2))
        return 0
    compact=clean[y0:y1,x0:x1].copy()
    assert compact.shape==(1150,1150,4)
    inv=np.zeros_like(clean)
    inv[y0:y1,x0:x1]=compact
    support=clean[:,:,3]>0
    assert np.array_equal(inv[support],clean[support])
    assert np.array_equal(inv[:,:,3],clean[:,:,3])
    full=clean.copy()
    full[y0:y1,x0:x1]=compact
    assert np.array_equal(full,clean)
    assert np.array_equal(compact,padded[y0+269:y1+269,x0+269:x1+269])
    image=Image.fromarray(compact).resize((160,160),Image.Resampling.LANCZOS)
    native=np.array(image)
    a1=box(native[:,:,3]>0)
    core=box(native[:,:,3]>=8)
    assert a1 is not None and core is not None
    checks={
        "strict160RGBA":native.shape==(160,160,4),
        "A1_no_canvas_edge_touch":a1[0]>0 and a1[1]>0 and a1[2]<160 and a1[3]<160,
        "original_A1_height_about148_not_relaxed":146<=a1[3]-a1[1]<=150,
        "original_A1_bottom_about154_not_relaxed":152<=a1[3]<=156,
        "visible_core_about_old144_Root141to145":141<=core[3]-core[1]<=145,
        "visible_boot_about_old152":abs((1144-y0)*160/1150-152)<0.5,
    }
    for path,expected in PINS.items():
        assert sha(path.read_bytes())==expected
    OUT.mkdir()
    artifacts={}
    for name,array in {"elder86CB_compact1150_before_Lanczos.png":compact,"cave_keeper_elder_idle_v1_runtime.png":native}.items():
        path=OUT/name
        with path.open("xb") as f:
            Image.fromarray(array).save(f,format="PNG")
        assert np.array_equal(np.array(Image.open(path)),array)
        artifacts[name]={"path":str(path),"sha256":sha(path.read_bytes()),"RGBA_sha256":sha(array.tobytes()),"size":[array.shape[1],array.shape[0]]}
    for path,expected in PINS.items():
        assert sha(path.read_bytes())==expected
    receipt={**facts,
        "status":"ROOT_EXECUTED_UNIQUE1150_FORMAT_METRIC_PASS_NEEDS_ART_VIEW" if all(checks.values()) else "ROOT_EXECUTED_UNIQUE1150_FORMAT_FAIL_RETAIN_STOP",
        "passed":all(checks.values()),"checks":checks,"native_A1_bbox":a1,"native_ge8_core_bbox":core,
        "all_subject_RGBA_inverse_before_normal_Lanczos":True,
        "completeRGBA_clean_padded_intermediates_unchanged":True,
        "outside_runtime_ROI_alpha_all0":True,
        "normal_Lanczos_separately_nonlossless":True,
        "all_input_pins_first_final_same":True,"PNG_writes":2,
        "artifacts":artifacts,"no_alpha_erase_threshold_or_ring_cleanup":True,
        "no_auto_retry_or_ROI_search":True,"actual_ART_view_required":True,
        "formal_or_NPC_binding":False}
    path=OUT/"receipt.json"
    with path.open("x",encoding="utf-8",newline="\n") as f:
        json.dump(receipt,f,indent=2)
        f.write("\n")
    print(json.dumps({"receipt":str(path),"sha256":sha(path.read_bytes()),"passed":receipt["passed"]},indent=2))
    return 0 if receipt["passed"] else 1

if __name__=="__main__":
    sys.exit(main())
