"""Read-only four soldier RAW core/anchors + proposed native160 visual calibration. No PNG written."""
from pathlib import Path
import hashlib,importlib.util,json
import numpy as np
from PIL import Image,__version__ as PIL_VERSION
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
def sha(b):return hashlib.sha256(b).hexdigest()
tracked={}
def read(path):
    raw=path.read_bytes();st=path.stat();tracked[str(path)]=(raw,st.st_mtime_ns);return raw
def bbox(mask):
    yy,xx=np.nonzero(mask)
    return [int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1] if len(xx) else None
def metric(arr,head_roi=None):
    alpha=arr[:,:,3];labels,n=ndimage.label(alpha>=128,np.ones((3,3),dtype=np.uint8));counts=np.bincount(labels.ravel());counts[0]=0;main=labels==int(counts.argmax())
    core=bbox(main);a1=bbox(alpha>0)
    output=dict(full_A1_bbox=a1,explicit_family_core_definition='largest8-connected component of alpha>=128 for measurement ONLY; never erase any image pixels',core_bbox=core,core_size=[core[2]-core[0],core[3]-core[1]],core_area=int(main.sum()),boot_support_baseline_exclusive_y=core[3],body_core_top_y=core[1])
    if head_roi:
        x0,y0,x1,y1=head_roi;hb=bbox(main[y0:y1,x0:x1]);assert hb
        hbox=[hb[0]+x0,hb[1]+y0,hb[2]+x0,hb[3]+y0]
        output.update(head_measurement_roi=head_roi,head_core_bbox=hbox,head_mid_x=(hbox[0]+hbox[2])/2)
    return output
def translate_blank_only(arr,dx):
    # Whole-frame integerX shift only through proven all-RGBA-zero columns. Reversible.
    assert dx<=0
    remove=-dx
    assert not np.any(arr[:,:remove])
    result=np.zeros_like(arr);result[:,:arr.shape[1]-remove]=arr[:,remove:]
    inverse=np.zeros_like(arr);inverse[:,remove:]=result[:,:arr.shape[1]-remove]
    assert np.array_equal(inverse,arr)
    return result
processor=ROOT/'prompts/luoyang_city_finish_20261025i/five_assets_local_processor_ROOT_ONLY.py'
assert sha(read(processor))=='7ba8a1586628c9814447c1658e425c8cbbfbc6c9d86d921d1c42089d5fcfcf28'
spec=importlib.util.spec_from_file_location('frozen5_dry_math_only',processor);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
frozen_path=OUT/'five_assets_precise_local_permission_DRYRUN_ONLY.json';frozen_raw=read(frozen_path);assert sha(frozen_raw)=='4c782b25e1d812e8e798ba1e98d491ed997aa01097099220929c2e6ee0eeaee5'
frozen=json.loads(frozen_raw)
families=[]
family_specs=[
 dict(id='young_bluegrey',idle='guard_young_bluegrey_idle_v1',walk='guard_young_bluegrey_walk4_v1',idle_sha='73b0cb61630d97443605ed4434a16dd40c08ce573fd2363718a3dd05cb9f3a69',walk_sha='012a7e75e954ca8d48d02f4ac04ae6282758623fc361c13441aeb17ad8fca5d7',idle_head_roi=[500,80,760,300],walk_post_shift_x=-79,npc_ids=['harbour_life_gate_patrol_west','harbour_life_gate_patrol_east','district_life_market_patrol']),
 dict(id='veteran_ochre',idle='guard_veteran_ochre_idle_v1',walk='guard_veteran_ochre_walk4_v1',idle_sha='73f138dedd4b4d84659e079becc3a7cd9d45bf51d6047673a71ba9fb58b7078d',walk_sha='823cb3d18541f9fec36d87e4a75c8c4d073a63394d6d2fbe7242d088d27d35e9',idle_head_roi=[500,60,760,280],walk_post_shift_x=-60,npc_ids=['harbour_life_docks_quay_patrol','district_life_yamen_west_patrol'])
]
for fs in family_specs:
    idle_path=ROOT/f'assets/raw/luoyang_city_finish_20261025i/{fs["idle"]}.png';walk_path=ROOT/f'assets/raw/luoyang_city_finish_20261025i/{fs["walk"]}.png'
    assert sha(read(idle_path))==fs['idle_sha'] and sha(read(walk_path))==fs['walk_sha']
    idle=np.array(Image.open(idle_path).convert('RGBA'));walk=np.array(Image.open(walk_path).convert('RGBA'))
    idle_metric=metric(idle,fs['idle_head_roi']);raw_frames=[];native_frames=[];translated_frames=[]
    recipe=next(r for r in module.SPECS if r['id']==fs['walk']);locked=next(r for r in frozen['rows'] if r['id']==fs['walk'])
    for i in range(4):
        sx=(i%2)*627;sy=(i//2)*627;cell=walk[sy:sy+627,sx:sx+627];raw_frames.append(metric(cell,[0,0,627,100]))
        clean,cleanup=module.masked_copy(cell,recipe['protects'][i])
        assert cleanup==locked['details']['frames'][i]['cleanup']
        x,y=locked['details']['frames'][i]['old_cell_new_origin'];frame=np.zeros((825,825,4),dtype=np.uint8);frame[y:y+627,x:x+627]=clean
        assert sha(frame.tobytes())==locked['details']['frames'][i]['proposed']['full_RGBA_sha256']
        shifted=translate_blank_only(frame,fs['walk_post_shift_x']);translated_frames.append(shifted)
        native=np.array(Image.fromarray(shifted).resize((160,160),Image.Resampling.LANCZOS));native_frames.append(native)
    # Idle only whole-canvas transparent padding, no alpha deletion or pixel edit. Not part of5image scope.
    padded_idle=np.zeros((1574,1574,4),dtype=np.uint8);padded_idle[160:1414,160:1414]=idle
    idle_head_x=idle_metric['head_mid_x']+160;idle_dx=int(round(787-idle_head_x))
    if idle_dx<=0:
        shifted_idle=translate_blank_only(padded_idle,idle_dx)
    else:
        assert not np.any(padded_idle[:,-idle_dx:]);shifted_idle=np.zeros_like(padded_idle);shifted_idle[:,idle_dx:]=padded_idle[:,:-idle_dx]
        inverse=np.zeros_like(padded_idle);inverse[:,:-idle_dx]=shifted_idle[:,idle_dx:];assert np.array_equal(inverse,padded_idle)
    native_idle=np.array(Image.fromarray(shifted_idle).resize((160,160),Image.Resampling.LANCZOS))
    # Nativehead ROIs are transformed authored source bands, not whole-body X extents.
    ir=fs['idle_head_roi'];native_idle_head=[max(0,int((ir[0]+160+idle_dx)*160/1574)-1),max(0,int((ir[1]+160)*160/1574)-1),min(160,int(np.ceil((ir[2]+160+idle_dx)*160/1574))+1),min(160,int(np.ceil((ir[3]+160)*160/1574))+1)]
    ni=metric(native_idle,native_idle_head)
    nf=[]
    for i,n in enumerate(native_frames):
        tx,ty=locked['details']['frames'][i]['old_cell_new_origin'];tx+=fs['walk_post_shift_x']
        head_roi=[max(0,int(tx*160/825)-1),max(0,int(ty*160/825)-1),min(160,int(np.ceil((tx+627)*160/825))+1),min(160,int(np.ceil((ty+100)*160/825))+1)]
        nf.append(metric(n,head_roi))
    idle_h=ni['core_size'][1];walk_h=nf[0]['core_size'][1]
    idle_scale=140/idle_h;walk_scale=140/walk_h
    legacy_idle140_core_if_A1=140*idle_h/(ni['full_A1_bbox'][3]-ni['full_A1_bbox'][1]);legacy_walk140_core_if_A1=140*walk_h/(nf[0]['full_A1_bbox'][3]-nf[0]['full_A1_bbox'][1])
    families.append(dict(family=fs['id'],npc_ids=fs['npc_ids'],raw_idle=dict(path=str(idle_path.relative_to(ROOT)).replace('\\','/'),sha256=fs['idle_sha'],size=[1254,1254],measurements=idle_metric),raw_walk=dict(path=str(walk_path.relative_to(ROOT)).replace('\\','/'),sha256=fs['walk_sha'],size=[1254,1254],equal_cell_size=[627,627],measurements_by_phase=raw_frames),proposed_runtime_format_ONLY_NOT_WRITTEN=dict(idle=dict(size=[160,160],method='Whole original1254RGBA +transparent160peredge ->1574square, optional whole-frame integerX through blankRGBA columns, uniform160Lanczos. No alpha cleanup.',padding=[160,160,160,160],whole_frame_integer_x_shift=idle_dx,raw_original_RGBA_preserved_in_pre_resize_stage=True,normal_resample_not_claimed_byte_inverse=True,proposed_full_RGBA_sha256=sha(native_idle.tobytes()),measurements=ni),walk=dict(size=[640,160],frame_size=[160,160],frame_count=4,method='Only after5imagepermission: exact frozen4c782cleanup/825square integer alignment, then same whole-frame blank-RGBA-column X shift for all phases, then each complete825square ->160square uniformLanczos, four row-major phases to horizontal. No per-phase rescaling/no pose editing.',post_frozen_plan_whole_frame_integer_x_shift=fs['walk_post_shift_x'],post_shift_blank_RGBA_inverse_proven=True,proposed_full_RGBA_sha256=sha(np.concatenate(native_frames,axis=1).tobytes()),per_frame_RGBA_sha256=[sha(n.tobytes()) for n in native_frames],measurements_by_phase=nf)),explicit_visual_calibration_candidate=dict(native_idle_core_rect=ni['core_bbox'],native_walk_first_core_rect=nf[0]['core_bbox'],idle_scale_expression=f'140.0/{idle_h}.0',walk_scale_expression=f'140.0/{walk_h}.0',idle_sprite_scale_after_visual_only=idle_scale,walk_sprite_scale_after_visual_only=walk_scale,idle_observed_core_height=140.0,walk_observed_core_heights=[r['core_size'][1]*walk_scale for r in nf],walk_support_baseline_y_by_phase=[r['boot_support_baseline_exclusive_y'] for r in nf],walk_head_x_by_phase=[r['head_mid_x'] for r in nf],idle_head_x=ni['head_mid_x'],legacy_A1_default_native_idle_core_height=legacy_idle140_core_if_A1,legacy_A1_default_native_walk_core_height=legacy_walk140_core_if_A1,consumer_implementation_requirement='New exact family/texture/path source-bound authored coreRect only. ExistingNPCNode._visible_bounds otherwise uses first-cell Image.get_used_rect including faintA1. Root/System must explicitly preload/register only theseNEWtextureIDs coreRect in the existingcache or equivalent finite metadata hook; do NOT globally replace alpha threshold, do NOT use sprite_scale to fix art.',physical_guards=dict(native_frame_size=[160,160],NPC_export_sprite_scale=1.0,calibrate_adult_body=True,body_size_source_expressions=['160.0*1.0*.14','160.0*1.0*.18'],body_offset_y_expression='160.0*1.0*.12',body_size=[22.4,28.8],body_offset_y=19.2,ground_collider_center_y=0.0,walk_frame_seconds=0.12,no_change=['Actor position/authorfoot','movement speed','lane','patrolaxis/distance','physics shape','sprite_scale physical seed','per-frame cadence']))))
npc_path=ROOT/'game/scripts/field/npc_node.gd';field_path=ROOT/'game/scripts/field/field_walkable_controller.gd'
sources=[dict(path=str(p.relative_to(ROOT)).replace('\\','/'),sha256=sha(read(p))) for p in (npc_path,field_path)]
report=dict(status='TWO_SOLDIER_FAMILY_CORE_VISUAL_CALIBRATION_CANDIDATE_READONLY_NOT_FORMATTED_NOT_BOUND',version=1,Pillow_version=PIL_VERSION,core_measurement='Source-bound exact family alpha>=128largestcomponent measurements, not a new global transparency rule or pixel-processing permission.',current_NPCNode_static_facts=['_visible_bounds() caches first square cell get_used_rect, so faint fullA1 can change scale/name/foot.','_apply_sprite_scale() starts exported sprite_scale then applies140/visibleheight if calibrated.','Field life_ground_anchored flags already setcalibrate=true/sprite_scale=1 before_ready; native frame160 establishes22.4x28.8 body independent of visualscale.','_sync_ground_anchor and get_depth_sort_y share the same calibratedbounds foot; a late visualY-onlypatch without correspondingfinitecore contract would desynchronize depth.','Raw1254square cannot directly serve walk: automatic hframes wouldbe1.825-highmotherstrip directly changes physicalbody; never bind it without native160format.'],current_code_sources=sources,frozen_five_image_plan=dict(path=str(frozen_path.relative_to(ROOT)).replace('\\','/'),sha256=sha(frozen_raw),still_pending_user_permission=True),families=families,no_PNG_written=True,no_weak_alpha_deleted_from_actual_images=True,no_Godot=True,no_import=True,no_production_or_save_writes=True,remaining='Root reviews exact proposed normalformat/core-cache hookup; first5image local permission still needed, extra2idle wholepadding is separately declared. ActualnativePNG/import/hframe/physicalbody/visualheight and movement/turn/dialogue must be verified in future limitedField test, not credited here.')
for path,(raw,ticks) in tracked.items():assert Path(path).read_bytes()==raw and Path(path).stat().st_mtime_ns==ticks
out=OUT/'two_soldier_family_visual_calibration01_CANDIDATE.json'
with out.open('xb') as f:f.write((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(report=str(out.relative_to(ROOT)).replace('\\','/'),sha256=sha(out.read_bytes()),families=[dict(family=f['family'],calibration=f['explicit_visual_calibration_candidate']) for f in families]),ensure_ascii=False))
