"""Create an exact-parent visual-only successor. No Godot/imagegen/PNG editing.

Default emits NOTREADY project. Root review can emit a separate ROOT_READY sibling;
never edit/reuse old24d project or results. Whole-old byte inverse is frozen for both.
"""
from pathlib import Path
import argparse,hashlib,json,difflib,math
import numpy as np
ROOT=Path(__file__).resolve().parents[2];SELF=Path(__file__).resolve()
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01/world24d_heads01'
OLD=ROOT/'game/build/world_water_bridge_20261024d_system01/native_sample01/project'
PARENT_SHA='2362787b85a58bbc51e2941fd3ab53bac9d5a1256d63afdaba43cb7f7a30e8bc'
SAMPLE_SHA='42b05721b36c0057cf921719b8eef5ba4222674083fdce4da955472dd98938e9'
SOURCE=ROOT/'game/data/maps/world_map_v15_complete_v9c_source.json'
SOURCE_SHA='85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f'
MANIFEST=ROOT/'game/art/maps/world_map_v15_complete_v9c/art_contract.json'
MANIFEST_SHA='1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a'
HELPER=OUT/'shore_heads_author01_NOTREADY.gd'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rawsha(b):return hashlib.sha256(b).hexdigest()
def parse(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def new(p,b):
    assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as f:f.write(b)
def save(p,v):new(p,(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
def fact(p):
    s=p.stat();return {'sha256':sha(p),'bytes':s.st_size,'ticks':str(s.st_mtime_ns//100+621355968000000000)}
def resolved(p):return ROOT/('game/'+p[6:]) if p.startswith('res://') else Path(p)
def inverse_report(before,after):
    a=before.decode();b=after.decode();changes=[]
    for tag,i,j,k,l in difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes():
        if tag!='equal':changes.append({'old_start':i,'old_end':j,'new_start':k,'new_end':l,'old_text':a[i:j],'new_text':b[k:l]})
    restored=b
    for row in reversed(changes):
        assert restored[row['new_start']:row['new_end']]==row['new_text']
        restored=restored[:row['new_start']]+row['old_text']+restored[row['new_end']:]
    assert restored.encode()==before
    return {'parent_sha256':rawsha(before),'child_sha256':rawsha(after),'old_whole_byte_inverse':True,'restored_parent_sha256':rawsha(restored.encode()),'changes':changes}
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--root-reviewed-builder-sha256');args=ap.parse_args()
    ready=bool(args.root_reviewed_builder_sha256)
    if ready:assert args.root_reviewed_builder_sha256.lower()==sha(SELF)
    label='ROOT_READY' if ready else 'NOTREADY';project=OUT/('project_'+label)
    assert not project.exists()
    parent=OLD/'input_candidate02_ROOT_READY.json';sample=OLD/'sample_candidate03_ROOT_READY.gd'
    assert sha(parent)==PARENT_SHA and sha(sample)==SAMPLE_SHA and sha(SOURCE)==SOURCE_SHA and sha(MANIFEST)==MANIFEST_SHA
    f=parse(parent);source=parse(SOURCE)
    pins={**f['source_pins'],'res://data/maps/world_map_v15_complete_v9c_source.json':SOURCE_SHA,'res://art/maps/world_map_v15_complete_v9c/art_contract.json':MANIFEST_SHA}
    walks=[]
    for r in source['chunks']:
        p=r['walk_path'];assert p in source['asset_sha256'];pin=source['asset_sha256'][p]
        assert sha(resolved(p))==pin;pins[p]=pin;walks.append({'path':p,'sha256':pin})
    assert len(walks)==64
    # Same fixed sourcepassage and17 members. No rewritten physical record.
    for p,pin in pins.items():assert sha(resolved(p))==pin.lower()
    protected={str(resolved(p).resolve()):fact(resolved(p)) for p in pins}
    for p in [parent,sample,HELPER,SELF,OLD/'wood_member_uv02.gdshader',OLD/'member_projection02.gd',OLD/'project.godot']:
        protected[str(p.resolve())]=fact(p)
    for r in f['new_art'].values():
        if isinstance(r,dict) and 'path' in r:
            p=Path(r['path']);assert sha(p)==r['sha256'];protected[str(p.resolve())]=fact(p)
    axis=np.array(f['bridge']['axis_source'],dtype=float);axis/=np.linalg.norm(axis)
    lateral=np.array([-axis[1],axis[0]]);poly=np.array(f['bridge']['deck_polygon'])
    north=(poly[3]+poly[0])/2;south=(poly[2]+poly[1])/2
    patches=[]
    for name,center,sign in [('north',north,-1),('south',south,1)]:
        for side in [-1,1]:
            c=center+lateral*side*96+axis*sign*10
            patches.append({'id':f'{name}_footing_{side}','center_px':c.tolist(),'radii_px':[34,32],'tangent_unit':axis.tolist(),'purpose':'drymud/stone footing beside original sourcepassage, never a raised support'})
    for ident,c,r,t in [('west_north',[3130,1510],[96,25],[.97,-.2431049156]),('east_north',[3680,1415],[84,22],[.95,-.3122498999]),('east_south',[3810,1685],[72,27],[.96,-.28])]:
        t=np.array(t,dtype=float);t/=np.linalg.norm(t)
        patches.append({'id':'shore_'+ident,'center_px':c,'radii_px':r,'tangent_unit':t.tolist(),'purpose':'interrupted actualRF dry-bank material cluster, no new long uniform strip'})
    rf=resolved(f['height_rf']['path']);assert sha(rf)==f['height_rf']['sha256']
    heights=np.fromfile(rf,dtype='<f4').reshape(1025,1537)
    def bed(x,y):
        qx,qy=x/8,y/8;cx,cy=math.floor(qx),math.floor(qy);fx,fy=qx-cx,qy-cy
        a,b,e,d=[float(v) for v in [heights[cy,cx],heights[cy,cx+1],heights[cy+1,cx],heights[cy+1,cx+1]]]
        return a+(b-a)*fx+(e-a)*fy if fx+fy<=1 else d+(e-d)*(1-fx)+(b-d)*(1-fy)
    for row in patches:
        row['read_only_RF_height_at_center_m']=bed(*row['center_px'])
        row['RF_dry_above_water_m']=row['read_only_RF_height_at_center_m']+.025
        assert row['RF_dry_above_water_m']>0
    author={'ready':ready,'status':'FINITE_VISUAL_ONLY_TWO_HEADS_SEVEN_PATCH_AUTHOR_NOT_RENDERED','ppm_x':102.4,'ppm_source_z':72.4077343935025,'bridge_center_source_px':f['bridge']['center_px'],'bridge_axis_source_unit':axis.tolist(),'bridge_lateral_source_unit':lateral.tolist(),'deck_polygon_source_px':f['bridge']['deck_polygon'],'sourcepassage_untouched':f['bridge']['source_passage'],'terrain_patches':patches,'visual_endbeam_top_m':-.008,'visual_endbeam_bottom_m':-.09,'no_new_physical_support':True,'road_gate':'Full effect zero in source corridor abs(lateral)<=70 ANDabs(along)<=278; softoutside to92/306; plus actualroadweight exclusion','terrain_gate':'Original frozenRF h>=-.025 anddryheightfade .10...18; no displacement/texturefile/mask change','additional_mud_mix_max':.28,'additional_stone_mix_max':.06,'old_wood_water_material_parameters_unchanged':True,'does_not_claim_fullriver_ribbon_geometry_solved':True}
    fixture=json.loads(parent.read_bytes());fixture['ready']=ready
    fixture['status']='ROOT_REVIEWED_FINITE_SHORE_HEADS_SUCCESSOR_NOT_FORMAL' if ready else 'FINITE_SHORE_HEADS_SOURCE_AUTHOR_NOTREADY_NOT_FORMAL'
    fixture['output_prefix']='res://shore_heads01_output/'
    fixture['source_pins']=pins
    for p in [parent,sample]:fixture['source_pins'][str(p.resolve())]=sha(p)
    helper_copy=project/'shore_heads_author01_NOTREADY.gd'
    fixture['source_pins'][str(helper_copy.resolve())]=sha(HELPER)
    fixture['shore_heads_author']=author
    fixture_bytes=(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode()
    inputname='input_shore_heads01_'+label+'.json'
    script=sample.read_text(encoding='utf-8')
    swaps=[('const READY=true','const READY='+str(ready).lower()),('const INPUT="res://input_candidate02_ROOT_READY.json"','const INPUT="res://'+inputname+'"'),('const INPUT_SHA="'+PARENT_SHA+'"','const INPUT_SHA="'+rawsha(fixture_bytes)+'"'),('var before_camera: Transform3D','var before_camera: Transform3D\nvar shore_fix: RefCounted'),('\treturn rows\n','\tif shore_fix!=null: rows["VisualOnlyHeadsAndFiniteShore25i"]=shore_fix.geometry()\n\treturn rows\n'),('\tif not _materials(): return false\n','\tif not _materials(): return false\n\tvar shore_script: GDScript=load("res://shore_heads_author01_NOTREADY.gd") as GDScript\n\tif not _ok(shore_script!=null and shore_script.can_instantiate(),"SOURCE_BOUND_SHORE_AUTHOR_SCRIPT"): return false\n\tshore_fix=shore_script.new()\n\tvar shore_result: Dictionary=shore_fix.apply_visual(world,terrain_new,members,f,Callable(self,"_ok"))\n\tif not _ok(not shore_result.is_empty(),"FINITE_SHORE_AND_HEADS_AUTHOR_APPLIED"): return false\n\tresult.shore_heads_author=shore_result\n'),('PNG_material_candidate02.png','PNG_bridge_heads_shore01.png')]
    for old,newtext in swaps:assert script.count(old)==1;script=script.replace(old,newtext)
    scriptbytes=script.encode()
    sample_inv=inverse_report(sample.read_bytes(),scriptbytes);fixture_inv=inverse_report(parent.read_bytes(),fixture_bytes)
    assert fixture['bridge']==f['bridge'] and fixture['new_art']==f['new_art'] and fixture['material']==f['material'] and fixture['camera']==f['camera']
    # Native project text/files are NEW, no model import, no artwork copy.
    new(project/'project.godot',(OLD/'project.godot').read_bytes())
    new(project/inputname,fixture_bytes);new(project/'sample_shore_heads01.gd',scriptbytes)
    for filename in ['wood_member_uv02.gdshader','member_projection02.gd']:new(project/filename,(OLD/filename).read_bytes())
    new(helper_copy,HELPER.read_bytes())
    record={'status':'ROOT_READY_SOURCE_CANDIDATE_NOT_RUN' if ready else 'NOTREADY_SOURCE_CANDIDATE_NOT_RUN','builder_sha256':sha(SELF),'project':str(project.resolve()),'script':str((project/'sample_shore_heads01.gd').resolve()),'script_sha256':rawsha(scriptbytes),'fixture_sha256':rawsha(fixture_bytes),'author_helper_sha256':sha(HELPER),'parent_sample':sample.relative_to(ROOT).as_posix(),'parent_sample_sha256':SAMPLE_SHA,'parent_fixture_sha256':PARENT_SHA,'sample_whole_byte_inverse':sample_inv,'fixture_whole_byte_inverse':fixture_inv,'new_author':author,'protected_before':protected,'64_original_walks':walks,'original17_physical_members_and_passage_same':True,'candidate_consumer':'ONLY NEW isolated sample_shore_heads01.gd->_materials oldaccepted03 thenapply_visual helper; same originalcamera1candidatePNG. NOT Field/worldstream consumer.','formal_current_consumer':'world_map_jianghu.tres->world_map_jianghu_layout_v15.tres/background_sets/world_map_jianghu_v15_streamed.tres->world_v15_visible_stream_20261018r.gd->Field; still oldv9c textures andr1c2_visual.png. This code is not reached there.','formal_admission_remaining':['Root sourcecode review + oneactualoriginalcamera finitecandidateART/independentphysicalnochange guards','coherentbounded r1c2visual/shadow and17bridgevisual exportset; no pastedoverlay/64wholerecapture','NEW ordinaryvisualoverride author/sourceclosure/isolatedimport thenexactrenderonlyFieldsourceentry; physicalsource/64walk/routes/portalsthroughthecurrentimmutableparent, no alias oldwholecapture'],'no_root_large_implementation_needed_for_candidate':'Afterreview Root may use this builder --root-reviewed-builder-sha256 <frozenSHA> to create NEWROOT_READY sibling. Root onlylaunch onecandidate; no handedit required.','current_calls':{'Godot':0,'imagegen':0,'PNG_write':0,'import':0,'formal_write':0}}
    for p,v in protected.items():assert fact(Path(p))==v
    save(project/'source_successor_and_whole_inverse.json',record)
    print(json.dumps({'project':str(project),'status':record['status'],'handoff_sha256':sha(project/'source_successor_and_whole_inverse.json'),'script_sha256':rawsha(scriptbytes),'fixture_sha256':rawsha(fixture_bytes),'helper_sha256':sha(HELPER),'builder_sha256':sha(SELF),'protected':len(protected),'walks':len(walks),'engine':0,'PNG_write':0}))
if __name__=='__main__':main()
