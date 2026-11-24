"""Read-only audit of actual four identity edits. Propose idle whole-canvas padding in memory only."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(b):return hashlib.sha256(b).hexdigest()
SPECS=[
 ('guard_young_bluegrey_portrait_v1','da6e1b0d01bbdc7142c24cb65de68687f7f4e7289676b2a028ce4c6c0b5f6933','guard_young_bluegrey_walk4_v1.png','012a7e75e954ca8d48d02f4ac04ae6282758623fc361c13441aeb17ad8fca5d7','portrait','guard_young_bluegrey_portrait_v1_edit.txt'),
 ('guard_veteran_ochre_portrait_v1','0cde54603cd07130b600961f12eefcddb7dd0e2692ee7b7555453cbccad8ab06','guard_veteran_ochre_walk4_v1.png','823cb3d18541f9fec36d87e4a75c8c4d073a63394d6d2fbe7242d088d27d35e9','portrait','guard_veteran_ochre_portrait_v1_edit.txt'),
 ('guard_young_bluegrey_idle_v1','73b0cb61630d97443605ed4434a16dd40c08ce573fd2363718a3dd05cb9f3a69','guard_young_bluegrey_walk4_v1.png','012a7e75e954ca8d48d02f4ac04ae6282758623fc361c13441aeb17ad8fca5d7','idle','guard_young_bluegrey_idle_v1_edit.txt'),
 ('guard_veteran_ochre_idle_v1','73f138dedd4b4d84659e079becc3a7cd9d45bf51d6047673a71ba9fb58b7078d','guard_veteran_ochre_walk4_v1.png','823cb3d18541f9fec36d87e4a75c8c4d073a63394d6d2fbe7242d088d27d35e9','idle','guard_veteran_ochre_idle_v1_edit.txt')
]
rows=[]
for ident,expected,ref,refsha,kind,prompt in SPECS:
    path=ROOT/f'assets/raw/luoyang_city_finish_20261025i/{ident}.png';raw=path.read_bytes();stat=path.stat();assert sha(raw)==expected
    refpath=path.parent/ref;assert sha(refpath.read_bytes())==refsha
    im=Image.open(path).convert('RGBA');arr=np.array(im);w,h=im.size
    boxes={str(t):im.getchannel('A').point(lambda a:255 if a>=t else 0).getbbox() for t in (1,4,16,128,250,255)}
    if kind=='portrait':
        assert im.size==(1254,1254) and im.getchannel('A').getextrema()==(255,255)
        state=dict(opaque_square_pass=True,no_transparent_margin_requirement_for_opaque_portrait=True,visual='Actual same-family cap/age/face/armor/colors consistent; ordinary natural skin, not fallback protagonist. Portrait has no polearm/weapon addition. Finite local portrait/style acceptance only, not runtime dialogue binding.')
    else:
        x0,y0,x1,y1=boxes['1'];assert boxes['128']
        visible=boxes['128'];body_h=visible[3]-visible[1]
        padded=np.zeros((h+320,w+320,4),dtype=np.uint8);padded[160:160+h,160:160+w]=arr
        assert np.array_equal(padded[160:160+h,160:160+w],arr)
        bounds=Image.fromarray(padded).getchannel('A').getbbox();a,b,c,d=bounds;W,H=w+320,h+320
        margins=[a/W,b/H,(W-c)/W,(H-d)/H];assert min(margins)>=.10
        proposed=dict(kind='WHOLE_CANVAS_LOSSLESS_PADDING_ONLY_SEPARATE_FROM_FIVE_ASSET_SCOPE',each_left_top_right_bottom=[160,160,160,160],size=[W,H],old_canvas_offset=[160,160],every_original_RGBA_byte_unchanged=True,alpha_deletions=0,RBG_edits=0,crop=0,resize=0,proposed_A1_bbox=list(bounds),proposed_A1_margin_fractions=margins,proposed_full_RGBA_sha256=sha(padded.tobytes()),proposed_visible_body_height_alpha128=body_h,body_pixels_after_uniform_whole_frame_to160=body_h*160/H,Sprite_visual_scale_needed_to_display_body140=140/(body_h*160/H),not_executed=True)
        state=dict(raw_complete_A1_margin_pass=all([x0>=w*.1,y0>=h*.1,w-x1>=w*.1,h-y1>=h*.1]),visible_body_alpha128_size=[visible[2]-visible[0],body_h],visual='Actual true neutral frontal idle: both boots grounded, arms relaxed, same cap/armor/colors and sheathed waist dao; no spear, no frozen walking lunge. Finite same-person visual acceptance only; complete raw A1 margins fail.',whole_padding_option=proposed,warning='Whole-padding preserves all original weak-alpha points too. A160pixel whole-frame format would show about105pixel visible body, not140; System must explicitly use independent visual calibration, or a NEW separately permitted idle cleanup plan. Do not claim old5image permission includes these2idles.')
    row=dict(id=ident,task_id='luoyang_20261025i_'+prompt.removesuffix('.txt'),raw_path=str(path.relative_to(ROOT)).replace('\\','/'),raw_sha256=expected,raw_bytes=len(raw),raw_size=[w,h],raw_RGBA_sha256=sha(arr.tobytes()),alpha_extrema=im.getchannel('A').getextrema(),bounds_by_alpha=boxes,identity_reference=dict(path=str(refpath.relative_to(ROOT)).replace('\\','/'),sha256=refsha),prompt=dict(path='prompts/luoyang_city_finish_20261025i/'+prompt,sha256=sha((ROOT/'prompts/luoyang_city_finish_20261025i'/prompt).read_bytes())),generation_tool='builtin_image_gen',mode='identity_preserving_image_edit',actual_call_provenance='Root reported one true builtin EDIT per asset; this audit does not invent external model/provider/usage/cost',model=None,provider=None,cost=None,local_image_edits=0,no_Godot_or_import_or_runtime_credit=True,review=state)
    rows.append(row);assert path.read_bytes()==raw and path.stat().st_mtime_ns==stat.st_mtime_ns
report=dict(status='FOUR_NEW_IDENTITY_EDITS_READONLY_VISUAL_AND_PIXEL_AUDIT_NO_LOCAL_PROCESSING',source_rows=rows,source_images_unchanged=True,processed_PNGs_written=0,new_idle_permission_not_inferred=True,Root_only_future_processing=True)
path=OUT/'four_identity_edits_actual_READONLY.json'
with path.open('xb') as f:f.write((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(passed_readonly=True,report=str(path.relative_to(ROOT)).replace('\\','/'),sha256=sha(path.read_bytes()),summary=[dict(id=r['id'],alpha=r['alpha_extrema'],A1=r['bounds_by_alpha']['1']) for r in rows])))
