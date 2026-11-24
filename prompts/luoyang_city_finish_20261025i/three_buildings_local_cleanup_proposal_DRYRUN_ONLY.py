"""Prepare one precise user-permission request, in memory only. Never emits processed PNGs."""
from pathlib import Path
import hashlib, json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(b):return hashlib.sha256(b).hexdigest()
SPECS=[
 ('chinese_open_ironwork_v2','ce9eb745773590cedda2ac448aa9fa6ab03af84cf50abe5a285608822b9ff475',[104,103,1601,844],[128,16]),
 ('pottery_kiln_house_v2','6dcfd35123df03e5147411c820f6cbbc68dcab9eb8cad583763a067845cf983b',[101,119,1454,885],[96,0]),
 ('ordinary_kitchen_rear_body_v2','1f65539478c6e042bbb3726f9a281679759168589b7eb4363dc3f93c52bda935',[163,106,1401,899],[64,32])
]
rows=[]
for ident,expected,protect,pad in SPECS:
    path=ROOT/f'assets/raw/luoyang_city_finish_20261025i/{ident}.png'
    raw=path.read_bytes();stat=path.stat();assert sha(raw)==expected
    im=Image.open(path).convert('RGBA');before=np.array(im);h,w=before.shape[:2]
    x0,y0,x1,y1=protect
    outside=np.ones((h,w),dtype=bool);outside[y0:y1,x0:x1]=False
    changed=outside & (before[:,:,3]>0)
    assert not np.any(before[:,:,3][changed]>3)
    memory=before.copy();memory[:,:,3][changed]=0
    assert np.array_equal(memory[:,:,:3],before[:,:,:3])
    assert np.array_equal(memory[y0:y1,x0:x1],before[y0:y1,x0:x1])
    assert np.array_equal(memory[:,:,3][~changed],before[:,:,3][~changed])
    yy,xx=np.nonzero(changed)
    old_alpha=before[yy,xx,3]
    # Independently reversible alpha list; no RGB or protected pixel ever changes.
    restored=memory.copy();restored[yy,xx,3]=old_alpha
    assert np.array_equal(restored,before)
    px,py=pad;derived=np.zeros((h+2*py,w+2*px,4),dtype=np.uint8)
    derived[py:py+h,px:px+w]=memory
    bound=Image.fromarray(derived).getchannel('A').getbbox();a,b,c,d=bound
    W,H=w+2*px,h+2*py
    assert min(a/W,b/H,(W-c)/W,(H-d)/H)>=.10
    assert np.array_equal(derived[py:py+h,px:px+w],memory)
    ledger=np.column_stack((xx,yy,old_alpha)).astype('<u4').tobytes()
    rows.append(dict(id=ident,raw_path=str(path.relative_to(ROOT)).replace('\\','/'),raw_sha256=expected,raw_bytes=len(raw),raw_size=[w,h],raw_RGBA_sha256=sha(before.tobytes()),protected_rect_halfopen=protect,protected_RGBA_sha256=sha(before[y0:y1,x0:x1].tobytes()),outside_weak_alpha_rule='ONLY A=1..3 outside protected rectangle; retain every RGB byte including hidden alpha0 RGB',changed_alpha_count=int(changed.sum()),changed_by_old_alpha={str(v):int((old_alpha==v).sum()) for v in (1,2,3)},changed_coordinate_alpha_ledger_SHA256=sha(ledger),padding_each_left_top_right_bottom=[px,py,px,py],proposed_size=[W,H],old_canvas_offset=[px,py],proposed_A1_bbox=list(bound),proposed_A1_margin_fractions=[a/W,b/H,(W-c)/W,(H-d)/H],proposed_full_RGBA_sha256=sha(derived.tobytes()),proposed_full_A1_ratio=(c-a)/(d-b),preserve_originals=True,all_original_RGB_unchanged=True,all_protected_RGBA_unchanged=True,all_other_original_RGBA_unchanged=True,alpha_inverse_restores_all_original_RGBA=True,no_resize_no_rotation_no_crop_no_restyle=True,not_executed=True))
    assert path.read_bytes()==raw and path.stat().st_mtime_ns==stat.st_mtime_ns
report=dict(status='ONE_PRECISE_THREE_NEW_IMAGES_LOCAL_CLEANUP_PERMISSION_PROPOSAL_NOT_EXECUTED',required_permission='Only the exact three listed raw images; set their specified external A=1..3 pixels to alpha0 while retaining all RGB/protected RGBA, add the specified transparent padding, original files retained. No person or other image scope.',rows=rows,actual_processed_PNGs_written=0,actual_raw_edits=0,Godot_calls=0,automatic_execution_path=False,door_or_placement_admission=False,remaining='Kitchen adult door ratio still does not fit old560x330 lot; needs explicit Source redesign/role decision. No cleanup can fix geometry.',model=None,provider=None,cost=None)
path=OUT/'three_buildings_precise_cleanup_permission_DRYRUN_ONLY.json'
with path.open('xb') as f:f.write((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(report=str(path.relative_to(ROOT)).replace('\\','/'),sha256=sha(path.read_bytes()),rows=[{k:r[k] for k in ('id','changed_alpha_count','changed_by_old_alpha','proposed_size','proposed_A1_bbox','proposed_full_A1_ratio')} for r in rows],executed=False)))
