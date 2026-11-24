"""One NEW receiver-only successor; no engine, PNG or canonical write by ART."""
from pathlib import Path
import argparse,hashlib,json,math
import numpy as np
ROOT=Path(__file__).resolve().parents[2];SELF=Path(__file__).resolve()
BASE=ROOT/'game/build/luoyang_city_finish_20261025i_art01/world24d_heads01/coherent18_01'
PARENT=BASE/'project_ROOT_READY_05'
ACTUAL=PARENT/'coherent18_output/112968_1092042/result.json'
ACTUAL_SHA='914add21d9d5f0d16cdf2f72ebbe33e0fee6bb08b732ca1616e44125cc18b95f'
FUNCTIONS=BASE/'water_receiver02_functions_NOTREADY.gdpart'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def new(p,b):
    assert not p.exists(),p;p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as h:h.write(b)
def resolve(p):return ROOT/('game/'+p[6:]) if p.startswith('res://') else Path(p)
def fact(p):
    s=p.stat();return {'sha256':sha(p),'bytes':s.st_size,'ticks':str(s.st_mtime_ns//100+621355968000000000)}
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--root-reviewed-builder-sha256');a=ap.parse_args();ready=bool(a.root_reviewed_builder_sha256)
    if ready:assert a.root_reviewed_builder_sha256.lower()==sha(SELF)
    label='ROOT_READY' if ready else 'NOTREADY';project=BASE/('water_receiver02_'+label+'_02')
    assert not project.exists() and sha(ACTUAL)==ACTUAL_SHA
    actual=read(ACTUAL);assert actual['passed'] and len(actual['images'])==18
    oldf=read(PARENT/'input_export18_ROOT_READY.json');h=read(PARENT/'export18_handoff.json')
    assert h['builder_sha256']=='d50a4c6231db40fdeca1909035ac7237e5603124baefa9b25c92cc07bd954791'
    assert sha(PARENT/'export_coherent18.gd')==h['script_sha256'] and sha(PARENT/'input_export18_ROOT_READY.json')==h['fixture_sha256']
    f=json.loads(json.dumps(oldf));f['ready']=ready;f['shore_heads_author']['ready']=ready
    f['output_prefix']='res://water_receiver02_output/';f['status']='WATER_ONLY_RECEIVER_ART_SUCCESSOR_NOT_FORMAL'
    f['export18']['scope']='ONE_NEW_WATER_ONLY_RECEIVER_17_OLD_MEMBER_OUTPUTS_REUSED_NOT_RERENDERED_NO_LAND_MATERIAL_CHANGE'
    p=np.array(f['bridge']['source_passage'],float);delta=p[1]-p[0];length=float(np.linalg.norm(delta));axis=delta/length;side=np.array([-axis[1],axis[0]])
    center=np.array(f['bridge']['center_px'],float);rx=length*.625;ry=length*.25
    ext=np.sqrt((side*rx)**2+(axis*ry)**2);lo=center-ext;hi=center+ext
    outer=oldf['export18']['mask_outer_source_rect'];assert np.all(lo>=outer[:2]) and np.all(hi<=np.array(outer[:2])+outer[2:])
    reused=[]
    for r in actual['images'][:17]:
        path=ACTUAL.parent/r['relative_target'];assert sha(path)==r['sha256'];f['source_pins'][str(path.resolve())]=r['sha256']
        reused.append({'path':str(path.resolve()),'sha256':r['sha256'],'size':r['size'],'target_relative_path':r['relative_target'],'status':'REUSE_112968_ORIGINAL_MEMBER_OUTPUT_NOT_RERENDERED'})
    f['source_pins'][str(ACTUAL.resolve())]=ACTUAL_SHA
    f['source_pins'][str((PARENT/'export_coherent18.gd').resolve())]=h['script_sha256']
    f['source_pins'][str((PARENT/'input_export18_ROOT_READY.json').resolve())]=h['fixture_sha256']
    protected={str(resolve(k).resolve()):fact(resolve(k)) for k in f['source_pins']}
    for k,v in f['source_pins'].items():assert sha(resolve(k))==v,k
    for name in ['shore_heads_author01_NOTREADY.gd','original_plane_caster.gd']:
        f['source_pins'][str((project/name).resolve())]=sha(PARENT/name)
    f['water_receiver02']={'center_source_px':center.tolist(),'passage_axis_unit':axis.tolist(),'original_sourcepassage_length_px':length,'lateral_radius_px':rx,'passage_radius_px':ry,'radii_formula':'lateral=originalpassage_length*.625;along=originalpassage_length*.25','ellipse_rho_inner':.45,'ellipse_rho_outer':1.,'source_ellipse_AABB':[*lo.tolist(),*(hi-lo).tolist()],'contained_in_original_caster_exclusion_mask':True,'RF_depth_gate_m':.005,'mask_randomness':False,'all_old_dry_land_RGBA_preserved':True,'prior18_technical_pass_ART_FAIL_retained':{'path':str(ACTUAL.resolve()),'sha256':ACTUAL_SHA},'reused17':reused,'new_adoptable_outputs':1,'pending':'shore material/straight river shape remain pending; not part of this finite water-only baseline'}
    fb=enc(f);inputname='input_water_receiver02_'+label+'.json'
    before=(PARENT/'export_coherent18.gd').read_text(encoding='utf-8');script=before
    start=script.index('func _bounded_composite(');end=script.index('func _execute() -> bool:',start)
    oldsegment=script[start:end];script=script[:start]+FUNCTIONS.read_text(encoding='utf-8')+'\n'+script[end:]
    oldloop='\tfor row: Dictionary in f.export18.targets:\n\t\tif not await _export_member(row): return false\n'
    assert script.count(oldloop)==1;script=script.replace(oldloop,'\tresult.reused17=f.water_receiver02.reused17 # No member captures in this successor.\n')
    assert script.count('result.images.size()==18')==1;script=script.replace('result.images.size()==18','result.images.size()==1').replace('EXACT_17_MEMBER_PLUS_ONE_CHUNK_EXPORT_SET','EXACT_ONE_RECEIVER_ONLY_NO_17_RERENDER')
    script=script.replace('const READY=true','const READY='+str(ready).lower(),1)
    script=script.replace('const INPUT="res://input_export18_ROOT_READY.json"','const INPUT="res://'+inputname+'"',1)
    script=script.replace('const INPUT_SHA="'+h['fixture_sha256']+'"','const INPUT_SHA="'+hashlib.sha256(fb).hexdigest()+'"',1)
    new(project/'project.godot',(PARENT/'project.godot').read_bytes());new(project/inputname,fb);new(project/'export_water_receiver02.gd',script.encode())
    for name in ['shore_heads_author01_NOTREADY.gd','member_projection02.gd','wood_member_uv02.gdshader','original_plane_caster.gd']:new(project/name,(PARENT/name).read_bytes())
    # Exact one-hunk whole old source inverse; no manually claimed inverse.
    prefix=0
    while prefix<min(len(before),len(script)) and before[prefix]==script[prefix]:prefix+=1
    tail=0
    while tail<min(len(before),len(script))-prefix and before[-1-tail]==script[-1-tail]:tail+=1
    be=len(before)-tail;se=len(script)-tail
    restored=script[:prefix]+before[prefix:be]+script[se:]
    assert restored==before
    inverse={'old_start':prefix,'old_end':be,'new_start':prefix,'new_end':se,'old_text':before[prefix:be],'new_text':script[prefix:se],'restored_sha256':hashlib.sha256(restored.encode()).hexdigest(),'byte_exact':True}
    # Independent CPU boundary prior, not actual image/render evidence. All
    # possible changed pixels are inside the sourcepassage ellipse AND wetRF.
    yy,xx=np.mgrid[0:1024,0:1536]
    sx=(xx+3072+.5).astype(np.float32);sy=(yy+1024+.5-.025*72.4077343935025).astype(np.float32)
    dx=sx-np.float32(center[0]);dy=sy-np.float32(center[1])
    rho=np.sqrt(((dx*side[0]+dy*side[1])/rx)**2+((dx*axis[0]+dy*axis[1])/ry)**2)
    qx=sx/np.float32(8);qy=sy/np.float32(8);cx=np.clip(np.floor(qx).astype(int),0,1535);cy=np.clip(np.floor(qy).astype(int),0,1023);fx=qx-cx;fy=qy-cy
    rf=np.fromfile(resolve(f['height_rf']['path']),dtype='<f4').reshape(1025,1537)
    aa=rf[cy,cx].astype(float);bb=rf[cy,cx+1].astype(float);ee=rf[cy+1,cx].astype(float);dd=rf[cy+1,cx+1].astype(float)
    bed=np.where(fx+fy<=1,aa+(bb-aa)*fx+(ee-aa)*fy,dd+(ee-dd)*(1-fx)+(bb-dd)*(1-fy))
    permitted=(rho<1)&(bed<=-.030);dry=bed>=-.025
    assert not np.any(permitted&dry)
    prior={'status':'CPU_BOUNDARY_PRIOR_NOT_RENDER_OR_IMAGE_PASS','total_pixels':1536*1024,'dry_pixels':int(dry.sum()),'potential_changed_pixels_before_nativealpha':int(permitted.sum()),'dry_potential_changed_pixels':int((permitted&dry).sum()),'source_ellipse_inside_old_caster_filter_rect':True,'old_RGBA_bypass_outside_alpha_or_ellipse_or_RFwet':True,'no_random_shape_or_scope_expansion':True}
    receipt={'status':'ROOT_READY_NOT_RUN' if ready else 'NOTREADY_NOT_RUN','builder_sha256':sha(SELF),'functions_sha256':sha(FUNCTIONS),'key_sha256':sha(project/'export_water_receiver02.gd'),'fixture_sha256':hashlib.sha256(fb).hexdigest(),'parent_script_sha256':h['script_sha256'],'parent_actual_report_sha256':ACTUAL_SHA,'source_whole_inverse':inverse,'old_replaced_function_segment':oldsegment,'old_member_capture_loop':oldloop,'new_scope':'only one new nativewater×fixedpassageellipse receiver; exact17old outputs reused; oldground/RFdryRGBA retained','protected_before':protected,'ellipse':f['water_receiver02'],'independent_CPU_boundary_prior':prior,'Root_only':True,'engine_calls':0,'PNG_write':0,'canonical_write':0,'whole_original_17_images_not_rerendered':True,'whole_old_parent_text_inverse_retained':True}
    for k,v in protected.items():assert fact(Path(k))==v,k
    new(project/'water_receiver02_handoff.json',enc(receipt))
    print(json.dumps({k:v for k,v in receipt.items() if k in ['status','builder_sha256','functions_sha256','key_sha256','fixture_sha256','parent_script_sha256']}));print(json.dumps({'project':str(project),'source_ellipse_AABB':f['water_receiver02']['source_ellipse_AABB'],'reused17':len(reused),'newPNG_expected':1,'engine':0}))
if __name__=='__main__':main()
