"""Normal native format candidate. Default dry; Root alone executes after upstream permission.

Walk input MUST be the exact five-asset processor's adopted output receipt, never raw
2x2, never a local reimplementation of its unapproved alpha cleanup. No Godot.
"""
from pathlib import Path
import argparse, hashlib, json
import numpy as np
from PIL import Image, __version__ as PILLOW_VERSION
ROOT=Path(__file__).resolve().parents[2]
SELF=Path(__file__).resolve()
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
CAL=OUT/'two_soldier_family_visual_calibration01_CANDIDATE.json'
CAL_SHA='04b1b84d367deb35e100276793025b9807cae05cef10cd27650ebfe6f5b6376e'
PLAN=OUT/'five_assets_precise_local_permission_DRYRUN_ONLY.json'
PLAN_SHA='4c782b25e1d812e8e798ba1e98d491ed997aa01097099220929c2e6ee0eeaee5'
RECEIPT=OUT/'processed_authorized_output/processing_receipt.json'
def sha(b): return hashlib.sha256(b).hexdigest()
def read_rgba(p): return np.array(Image.open(p).convert('RGBA'))
def translated_exact(a,dx):
    """Whole-frame integer shift, rejecting even hidden RGB outside recoverable area."""
    h,w,c=a.shape
    assert c==4 and abs(dx)<w
    lost=a[:,-dx:] if dx>0 else a[:,:-dx] if dx<0 else a[:,:0]
    assert not np.any(lost), 'Refuse shift: discarded columns contain RGBA, including hidden RGB'
    b=np.zeros_like(a)
    if dx>0: b[:,dx:]=a[:,:w-dx]
    elif dx<0: b[:,:w+dx]=a[:,-dx:]
    else: b[:]=a
    inverse=np.zeros_like(a)
    if dx>0: inverse[:,:w-dx]=b[:,dx:]
    elif dx<0: inverse[:,-dx:]=b[:,:w+dx]
    else: inverse[:]=b
    assert np.array_equal(inverse,a)
    return b,{'integer_x_shift':dx,'discarded_column_count':abs(dx),'discarded_all_RGBA_zero':True,'whole_frame_inverse_RGBA_equal':True,'input_RGBA_sha256':sha(a.tobytes()),'translated_RGBA_sha256':sha(b.tobytes())}
def native160(a):
    assert a.shape[0]==a.shape[1]
    return np.array(Image.fromarray(a).resize((160,160),Image.Resampling.LANCZOS))
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--execute-reviewed-script-sha256')
    args=ap.parse_args()
    assert sha(CAL.read_bytes())==CAL_SHA and sha(PLAN.read_bytes())==PLAN_SHA
    calibration=json.loads(CAL.read_bytes()); plan=json.loads(PLAN.read_bytes())
    assert PILLOW_VERSION==calibration['Pillow_version'], 'Resample implementation changed; review anew'
    execute=bool(args.execute_reviewed_script_sha256)
    if execute: assert args.execute_reviewed_script_sha256.lower()==sha(SELF.read_bytes())
    receipt=None
    if RECEIPT.exists():
        receipt=json.loads(RECEIPT.read_bytes())
        assert receipt['authorized_plan_sha256']==PLAN_SHA
        assert receipt['status']=='ROOT_EXECUTED_EXACT_USER_AUTHORIZED_FIVE_ASSET_PROCESSING_NO_IMPORT_OR_DEPLOYMENT'
    if execute: assert receipt is not None, 'Walk cannot consume pending/unapproved raw'
    prepared=[]; rows=[]; originals=[]
    for fam in calibration['families']:
        family=fam['family']; fmt=fam['proposed_runtime_format_ONLY_NOT_WRITTEN']
        raw=ROOT/fam['raw_idle']['path']; oldbytes=raw.read_bytes(); st=raw.stat()
        assert sha(oldbytes)==fam['raw_idle']['sha256']
        a=read_rgba(raw); assert a.shape==(1254,1254,4)
        padded=np.zeros((1574,1574,4),dtype=np.uint8);padded[160:1414,160:1414]=a
        assert np.array_equal(padded[160:1414,160:1414],a)
        shifted,proof=translated_exact(padded,fmt['idle']['whole_frame_integer_x_shift'])
        idle=native160(shifted)
        assert sha(idle.tobytes())==fmt['idle']['proposed_full_RGBA_sha256']
        row={'family':family,'raw_idle_sha256':sha(oldbytes),'idle_padding_each_edge':160,'idle_original_full_RGBA_recovered':True,'idle_shift':proof,'idle_native_RGBA_sha256':sha(idle.tobytes()),'native_idle_core_rect':fam['explicit_visual_calibration_candidate']['native_idle_core_rect'],'native_walk_first_core_rect':fam['explicit_visual_calibration_candidate']['native_walk_first_core_rect'],'walk_input_status':'PENDING_FROZEN_UPSTREAM_OUTPUT_NOT_RECOMPUTED'}
        prepared.append((f'guard_{family}_idle_v1_runtime160.png',idle))
        if receipt is not None:
            identifier=f'guard_{family}_walk4_v1'
            entry=next(r for r in receipt['outputs'] if r['id']==identifier)
            pinned=next(r for r in plan['rows'] if r['id']==identifier)
            p=ROOT/entry['path'];assert p.parent==RECEIPT.parent
            assert sha(p.read_bytes())==entry['sha256']
            strip=read_rgba(p); assert strip.shape==(825,3300,4)
            assert sha(strip.tobytes())==entry['RGBA_sha256']==pinned['details']['full_output_RGBA_sha256']
            frames=[];proofs=[]
            for i in range(4):
                # Exact complete825-square frames, never subject bbox crops.
                a=strip[:,825*i:825*(i+1)].copy()
                assert sha(a.tobytes())==pinned['details']['frames'][i]['proposed']['full_RGBA_sha256']
                b,pr=translated_exact(a,fmt['walk']['post_frozen_plan_whole_frame_integer_x_shift'])
                n=native160(b)
                assert sha(n.tobytes())==fmt['walk']['per_frame_RGBA_sha256'][i]
                frames.append(n);proofs.append(pr)
            walk=np.concatenate(frames,axis=1)
            assert sha(walk.tobytes())==fmt['walk']['proposed_full_RGBA_sha256']
            prepared.append((f'guard_{family}_walk4_v1_runtime160.png',walk))
            row.update(walk_input_status='EXACT_FROZEN_AUTHORIZED_OUTPUT_CONSUMED',walk_input_file_sha256=entry['sha256'],walk_phase_shifts=proofs,walk_native_RGBA_sha256=sha(walk.tobytes()),walk_native_size=[640,160],walk_frame_order=[0,1,2,3])
        originals.append((raw,oldbytes,st.st_mtime_ns));rows.append(row)
    for p,b,t in originals: assert p.read_bytes()==b and p.stat().st_mtime_ns==t
    report={'status':'ROOT_NATIVE_FORMAT_EXECUTED' if execute else 'DRY_REVIEW_NO_PNG_WRITTEN','script_sha256':sha(SELF.read_bytes()),'calibration_sha256':CAL_SHA,'upstream_authorized_plan_sha256':PLAN_SHA,'Pillow_version':PILLOW_VERSION,'upstream_receipt_present':receipt is not None,'rows':rows,'normal_Lanczos_not_byte_inverse':True,'pre_resample_RGBA_integer_stage_inverse_exact':True,'no_idle_alpha_cleanup':True,'no_per_phase_scaling_or_pose_edits':True,'all_originals_unchanged':True,'no_Godot_or_import_or_consumer_binding':True,'no_body_speed_lane_cadence_changes':True}
    if execute:
        dest=OUT/'native_format_ROOT_EXECUTED';assert not dest.exists();dest.mkdir()
        outputs=[]
        for name,a in prepared:
            p=dest/name
            with p.open('xb') as f: Image.fromarray(a).save(f,format='PNG')
            assert np.array_equal(read_rgba(p),a)
            outputs.append({'path':str(p.relative_to(ROOT)).replace('\\','/'),'sha256':sha(p.read_bytes()),'RGBA_sha256':sha(a.tobytes()),'size':[a.shape[1],a.shape[0]]})
        report['outputs']=outputs
        with (dest/'format_receipt.json').open('xb') as f: f.write((json.dumps(report,indent=2)+'\n').encode())
    print(json.dumps(report,indent=2))
if __name__=='__main__': main()
