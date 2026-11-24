"""Independent read-only pixel comparison of actual elder1150 output; no files written."""
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image

R=Path(__file__).resolve().parents[3]
A=R/"game/build/luoyang_city_finish_20261025i_art01"
pins={
    R/"assets/raw/luoyang_city_finish_20261025i/cave_keeper_elder_idle_v1.png":"86cbb758e08e52c851abdd2714a5f7d7dddba88c9b07b74fa01c344de7b034d0",
    A/"monks13_ROOT_ONLY_OUTPUT/elder86CB_external_alpha1_clean.png":"b25cf1a8015ec07f87d3e8e949041dd4a5b5d13b9d212dd2da4a0a964c138a0a",
    A/"monks13_ROOT_ONLY_OUTPUT/elder86CB_clean_fullRGBA_padded1792.png":"dd590ee73c8ef80248556bacb3cb3a1e8b438fdd219c66a0030ca44d2b908554",
    A/"monks13_ROOT_ONLY_OUTPUT/elder86CB_compact1118_before_Lanczos.png":"e7a5903fb85403d3c29f6dca2d09e2bae08536508d9a6c9c6052fd464ec3c67a",
    A/"monks13_ROOT_ONLY_OUTPUT/cave_keeper_elder_idle_v1_runtime.png":"1c28942cdbf43ce8c6cffb28c498c66a87150afb53436a2d68f6deab766a3531",
    A/"monks13_ROOT_ONLY_OUTPUT/receipt.json":"4576a4b1d2f8edcdd12f408b670e983554fb1987306cf8d68350081c254ba6c5",
    A/"monks15_ROOT_ONLY_OUTPUT/receipt.json":"c578f4e5f207e918c5b809f002edcc768d942b953f188ce5ece6cbf293e6d571",
    A/"monks15_ROOT_ONLY_OUTPUT/elder86CB_compact1150_before_Lanczos.png":"8e2da857c9b3b7a626ae9859b02bcc14e605f308aa9d020f375d41e71c48cb0d",
    A/"monks15_ROOT_ONLY_OUTPUT/cave_keeper_elder_idle_v1_runtime.png":"e0f043d80a1f89f8e982cc07fdcabb3bf390b259490da4df6fec9bab969b2e67",
    R/"game/art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png":"6268061eab18d2bf8c1ea0c13873f0d718feb82a119f00a67edf7c52bcb077ad",
}
sha=lambda b:hashlib.sha256(b).hexdigest()
for p,w in pins.items(): assert sha(p.read_bytes())==w, str(p)
paths=list(pins)
raw=np.array(Image.open(paths[0]))
clean=np.array(Image.open(paths[1]))
pad=np.array(Image.open(paths[2]))
compact=np.array(Image.open(paths[7]))
native=np.array(Image.open(paths[8]))
old=np.array(Image.open(paths[9]))
yy,xx=np.indices(raw.shape[:2])
protected=(xx>=397)&(xx<828)&(yy>=104)&(yy<1154)
eligible=(~protected)&(raw[:,:,3]==1)
delta=np.any(raw!=clean,axis=2)
inside=(xx>=63)&(xx<1213)&(yy>=54)&(yy<1204)
inverse=np.zeros_like(clean)
inverse[54:1204,63:1213]=compact
support=clean[:,:,3]>0
normal=np.array(Image.fromarray(compact).resize((160,160),Image.Resampling.LANCZOS))
def box(image,t):
    y,x=np.where(image[:,:,3]>=t)
    return [int(x.min()),int(y.min()),int(x.max()+1),int(y.max()+1)]
checks={
    "all10fixedpins":True,
    "oldFAILandall4outputs_retained":json.loads(paths[5].read_text())["passed"] is False,
    "only1464externaloriginalalpha1_changed":int(delta.sum())==1464 and np.array_equal(delta,eligible),
    "allRGBincludinghiddenunchanged":np.array_equal(raw[:,:,:3],clean[:,:,:3]),
    "protected452550fullRGBAunchanged":int(protected.sum())==452550 and np.array_equal(raw[protected],clean[protected]),
    "allotheralphabytesunchanged":np.array_equal(raw[:,:,3][~eligible],clean[:,:,3][~eligible]),
    "fullRGBApadding_inverse":np.array_equal(pad[269:1523,269:1523],clean),
    "fullcompactROI_RGBA_exact":np.array_equal(compact,clean[54:1204,63:1213]),
    "fullcompactmatchespaddedROI":np.array_equal(compact,pad[323:1473,332:1482]),
    "outside_runtime_ROI_alpha0":not bool((clean[:,:,3][~inside]>0).any()),
    "subjectRGBA_inverse_before_resize":np.array_equal(inverse[support],clean[support]),
    "entirealpha_inverse_before_resize":np.array_equal(inverse[:,:,3],clean[:,:,3]),
    "native_exactnormal_Lanczos_no_post_erase":np.array_equal(native,normal),
    "native160_RGBA":native.shape==(160,160,4),
    "native_A1_exact":box(native,1)==[46,6,107,154],
    "native_core8_exact":box(native,8)==[48,8,105,152],
    "old_new_A1_height_same148":box(native,1)[3]-box(native,1)[1]==box(old,1)[3]-box(old,1)[1]==148,
    "old_new_visiblecore_height_same144":box(native,8)[3]-box(native,8)[1]==box(old,8)[3]-box(old,8)[1]==144,
    "old_new_visibleboot_bottom_same152":box(native,8)[3]==box(old,8)[3]==152,
    "old_new_outerfoot_bottom_same154":box(native,1)[3]==box(old,1)[3]==154,
}
for p,w in pins.items(): assert sha(p.read_bytes())==w
assert all(checks.values()),checks
print(json.dumps({"status":"INDEPENDENT_READONLY_PIXEL_QA_PASS_NO_IMAGE_WRITES", "checks":checks,"checks_count":len(checks),"failures":[],"native_png_sha256":pins[paths[8]],"native_RGBA_sha256":sha(native.tobytes()),"source_first_final_pins_same":True,"actual_A1":[46,6,107,154],"actual_core8":[48,8,105,152],"PNG_writes":0,"engine_calls":0,"import_or_canonical_writes":0},indent=2))
