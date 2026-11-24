"""Exact five-raw cleanup/format proposal; default dry. Root alone may execute after user permission."""
from pathlib import Path
import argparse,hashlib,json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];SELF=Path(__file__).resolve()
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
PLAN=OUT/'five_assets_precise_local_permission_DRYRUN_ONLY.json'
def sha(b):return hashlib.sha256(b).hexdigest()
SPECS=[
 dict(id='chinese_open_ironwork_v2',sha='ce9eb745773590cedda2ac448aa9fa6ab03af84cf50abe5a285608822b9ff475',kind='building',protect=[104,103,1601,844],pad=[128,16]),
 dict(id='pottery_kiln_house_v2',sha='6dcfd35123df03e5147411c820f6cbbc68dcab9eb8cad583763a067845cf983b',kind='building',protect=[101,119,1454,885],pad=[96,0]),
 dict(id='ordinary_kitchen_rear_body_v2',sha='1f65539478c6e042bbb3726f9a281679759168589b7eb4363dc3f93c52bda935',kind='building',protect=[163,106,1401,899],pad=[64,32]),
 dict(id='guard_young_bluegrey_walk4_v1',sha='012a7e75e954ca8d48d02f4ac04ae6282758623fc361c13441aeb17ad8fca5d7',kind='walk2x2',protects=[[153,15,572,600],[163,16,411,602],[153,14,602,591],[163,14,436,591]],xy=[[0,1],[77,0],[1,11],[79,10]],cell=825,origin=[99,99],head128_band_x_midpoints=[392.0,315.5,391.0,313.0],baseline128_bottoms=[590,591,580,581]),
 dict(id='guard_veteran_ochre_walk4_v1',sha='823cb3d18541f9fec36d87e4a75c8c4d073a63394d6d2fbe7242d088d27d35e9',kind='walk2x2',protects=[[139,9,556,618],[148,9,490,618],[133,1,570,608],[145,0,491,609]],xy=[[0,0],[45,1],[3,10],[47,10]],cell=825,origin=[99,99],head128_band_x_midpoints=[373.0,328.0,370.0,326.0],baseline128_bottoms=[608,607,598,598])
]
def masked_copy(arr,protect):
    h,w=arr.shape[:2];x0,y0,x1,y1=protect
    assert 0<=x0<x1<=w and 0<=y0<y1<=h
    outside=np.ones((h,w),dtype=bool);outside[y0:y1,x0:x1]=False
    selected=outside & (arr[:,:,3]>0)
    assert not np.any(arr[:,:,3][selected]>3)
    result=arr.copy();result[:,:,3][selected]=0
    yy,xx=np.nonzero(selected);aa=arr[yy,xx,3]
    inverse=result.copy();inverse[yy,xx,3]=aa
    assert np.array_equal(inverse,arr)
    assert np.array_equal(result[:,:,:3],arr[:,:,:3])
    assert np.array_equal(result[y0:y1,x0:x1],arr[y0:y1,x0:x1])
    return result,dict(protected_rect=protect,protected_RGBA_sha256=sha(arr[y0:y1,x0:x1].tobytes()),changed_alpha_count=int(selected.sum()),changed_by_old_alpha={str(v):int((aa==v).sum()) for v in (1,2,3)},changed_points_xy_old_alpha=np.column_stack((xx,yy,aa)).tolist())
def facts(arr):
    h,w=arr.shape[:2];bounds=Image.fromarray(arr).getchannel('A').getbbox();assert bounds
    x0,y0,x1,y1=bounds
    margins=[x0/w,y0/h,(w-x1)/w,(h-y1)/h]
    assert min(margins)>=.10
    return dict(size=[w,h],full_RGBA_sha256=sha(arr.tobytes()),complete_A1_bbox=list(bounds),complete_A1_size=[x1-x0,y1-y0],complete_A1_margin_fractions=margins,all_four_10percent=True)
def compute():
    rows=[];images=[]
    for spec in SPECS:
        path=ROOT/f'assets/raw/luoyang_city_finish_20261025i/{spec["id"]}.png';raw=path.read_bytes();st=path.stat()
        assert sha(raw)==spec['sha'];arr=np.array(Image.open(path).convert('RGBA'));h,w=arr.shape[:2]
        if spec['kind']=='building':
            clean,record=masked_copy(arr,spec['protect']);px,py=spec['pad']
            result=np.zeros((h+2*py,w+2*px,4),dtype=np.uint8);result[py:py+h,px:px+w]=clean
            assert np.array_equal(result[py:py+h,px:px+w],clean)
            details=dict(padding_each_left_top_right_bottom=[px,py,px,py],old_canvas_offset=[px,py],cleanup=record,proposed=facts(result),all_original_RGB_unchanged=True,all_protected_RGBA_unchanged=True,full_inverse_RGBA_proven=True,no_resize_crop_or_rotation=True)
        else:
            assert (w,h)==(1254,1254) and w%2==0 and h%2==0
            cw,ch=w//2,h//2;size=spec['cell'];ox,oy=spec['origin'];result=np.zeros((size,size*4,4),dtype=np.uint8)
            inverse=np.zeros_like(arr);frames=[]
            for i in range(4):
                sx=(i%2)*cw;sy=(i//2)*ch;cell=arr[sy:sy+ch,sx:sx+cw]
                clean,record=masked_copy(cell,spec['protects'][i]);dx,dy=spec['xy'][i];tx,ty=ox+dx,oy+dy
                assert 0<=tx<=size-cw and 0<=ty<=size-ch
                frame=result[:,i*size:(i+1)*size];frame[ty:ty+ch,tx:tx+cw]=clean
                pulled=frame[ty:ty+ch,tx:tx+cw].copy();assert np.array_equal(pulled,clean)
                for x,y,a in record['changed_points_xy_old_alpha']:pulled[y,x,3]=a
                inverse[sy:sy+ch,sx:sx+cw]=pulled
                frames.append(dict(index=i,original_cell_rect=[sx,sy,cw,ch],new_cell_size=[size,size],old_cell_new_origin=[tx,ty],integer_alignment_translation=[dx,dy],cleanup=record,proposed=facts(frame),head_anchor128_x=spec['head128_band_x_midpoints'][i]+tx,supporting_boot_baseline128_y=spec['baseline128_bottoms'][i]+ty))
            assert np.array_equal(inverse,arr)
            baselines={r['supporting_boot_baseline128_y'] for r in frames};assert len(baselines)==1
            heads=[r['head_anchor128_x'] for r in frames];assert max(heads)-min(heads)<=.5
            details=dict(source_equal_cell_size=[cw,ch],new_horizontal_strip_size=[size*4,size],frame_order='row-major original [0,1,2,3] -> horizontal [0,1,2,3]',frames=frames,full_output_RGBA_sha256=sha(result.tobytes()),complete_original_RGBA_recovered_after_inverse_alpha_ledger=True,only_integer_translation_and_new_transparent_canvas=True,no_resize_no_pose_edits_no_frame_duplicates=True,visible_gait_credit='Four limited observed poses: two contact/two lifted passing; arm swings reverse. Not8frames, not strict biomechanical lead-leg proof, not runtime adoption.')
        assert path.read_bytes()==raw and path.stat().st_mtime_ns==st.st_mtime_ns
        rows.append(dict(id=spec['id'],kind=spec['kind'],raw_path=str(path.relative_to(ROOT)).replace('\\','/'),raw_sha256=spec['sha'],raw_bytes=len(raw),raw_size=[w,h],raw_RGBA_sha256=sha(arr.tobytes()),details=details));images.append(result)
    return rows,images
def main():
    p=argparse.ArgumentParser();p.add_argument('--execute-user-authorized-plan-sha256');args=p.parse_args()
    rows,images=compute()
    if not args.execute_user_authorized_plan_sha256:
        report=dict(status='FIVE_EXACT_ASSET_LOCAL_PROCESSING_PERMISSION_PROPOSAL_DRYRUN_ONLY_NOT_EXECUTED',processor=dict(path=str(SELF.relative_to(ROOT)).replace('\\','/'),sha256=sha(SELF.read_bytes())),scope='Only listed3building+2walk RAW SHA; original files retained; no new idle or portraits included.',allowed_pixel_changes='Only explicitly listed original A=1..3 outside exact protected rectangles to alpha0, all RGB including alpha0 hiddenRGB preserved; actual changed point lists are frozen below. Transparent padding; for walk, exact whole627-square original cells copied with frozen integerX/Y offsets into825-square frames, then row-major4horizontal.',rows=rows,actual_processed_PNGs_written=0,raw_edits=0,no_generation=True,no_Godot=True,no_import=True,no_deployment=True,permission_status='AWAITING_USER_REPLY',current_future_guards='Even after source pixel processing, geometry/door/Family/Physics/art/runtime proof remain separate')
        with PLAN.open('xb') as f:f.write((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode())
        print(json.dumps(dict(status='DRYRUN_ONLY',plan=str(PLAN.relative_to(ROOT)).replace('\\','/'),sha256=sha(PLAN.read_bytes()),processor_sha256=sha(SELF.read_bytes()),summary=[dict(id=r['id'],kind=r['kind'],points=(r['details']['cleanup']['changed_alpha_count'] if r['kind']=='building' else sum(f['cleanup']['changed_alpha_count'] for f in r['details']['frames']))) for r in rows])))
        return
    # Root must have the user's explicit matching scope permission before using this path.
    frozen_raw=PLAN.read_bytes();assert sha(frozen_raw)==args.execute_user_authorized_plan_sha256.lower()
    frozen=json.loads(frozen_raw);assert frozen['processor']['sha256']==sha(SELF.read_bytes())
    assert frozen['rows']==rows
    destination=OUT/'processed_authorized_output';assert not destination.exists()
    destination.mkdir()
    outputs=[]
    for row,array in zip(rows,images):
        output=destination/(row['id']+'_local_authorized.png')
        with output.open('xb') as f:Image.fromarray(array).save(f,format='PNG')
        readback=np.array(Image.open(output).convert('RGBA'));assert np.array_equal(readback,array)
        outputs.append(dict(id=row['id'],path=str(output.relative_to(ROOT)).replace('\\','/'),sha256=sha(output.read_bytes()),RGBA_sha256=sha(readback.tobytes()),size=[readback.shape[1],readback.shape[0]]))
    final=dict(status='ROOT_EXECUTED_EXACT_USER_AUTHORIZED_FIVE_ASSET_PROCESSING_NO_IMPORT_OR_DEPLOYMENT',authorized_plan_sha256=sha(frozen_raw),outputs=outputs,raws_unchanged=True,all_protected_RGBA_unchanged=True,all_old_RGB_unchanged=True,full_inverse_RGBA_proven=True,no_generated_pixels=True)
    report=destination/'processing_receipt.json'
    with report.open('xb') as f:f.write((json.dumps(final,ensure_ascii=False,indent=2)+'\n').encode())
    print(json.dumps(dict(status=final['status'],report=str(report.relative_to(ROOT)).replace('\\','/'),sha256=sha(report.read_bytes()),outputs=outputs)))
if __name__=='__main__':main()
