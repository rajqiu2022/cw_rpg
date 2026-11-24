"""Freeze one bounded native export key. Never runs Godot or writes artwork.

Root alone may build the READY sibling after reviewing this builder's SHA.
The old original chunk is a GPU composite's outside owner, not a shadow overlay.
"""
from pathlib import Path
import argparse, hashlib, json, math, itertools
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'game/build/luoyang_city_finish_20261025i_art01/world24d_heads01'
PARENT=BASE/'project_ROOT_READY'
OUT=BASE/'coherent18_01'
SOURCE=ROOT/'game/data/maps/world_map_v15_complete_v9c_source.json'
SOURCE_SHA='85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f'
REPORT_SHA='cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851'
APPROVED_PNG=BASE/'project_ROOT_READY/shore_heads01_output/27588_969151/PNG_bridge_heads_shore01.png'
APPROVED_SHA='da3a506eb6644d37aa5d94b728d1e6a7ef7302fab50a21f5617eecd2810305cb'
TEMPLATE=OUT/'export_execute01_NOTREADY.gdpart'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def resolve(p):return ROOT/('game/'+p[6:]) if p.startswith('res://') else Path(p)
def new(p,b):
    assert not p.exists(),p
    p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as h:h.write(b)
def fact(p):
    t=p.stat();return {'sha256':sha(p),'bytes':t.st_size,'ticks':str(t.st_mtime_ns//100+621355968000000000)}
def corners(lo,hi):return np.array(list(itertools.product(*zip(lo,hi))),dtype=np.float64)
def inverse(a,b):
    # One bounded replacement is an exact inverse, not an expensive text diff
    # over ten MB of repeated caster dictionaries. Whole unchanged tails kept.
    start=0
    while start<min(len(a),len(b)) and a[start]==b[start]:start+=1
    tail=0
    while tail<min(len(a),len(b))-start and a[len(a)-1-tail]==b[len(b)-1-tail]:tail+=1
    ae=len(a)-tail;be=len(b)-tail
    edits=[dict(old_start=start,old_end=ae,new_start=start,new_end=be,old=a[start:ae],new=b[start:be])]
    r=b
    for x in reversed(edits):
        assert r[x['new_start']:x['new_end']]==x['new']
        r=r[:x['new_start']]+x['old']+r[x['new_end']:]
    assert r==a
    return {'restores_parent_bytes':True,'changes':edits,'parent_sha256':hashlib.sha256(a.encode()).hexdigest(),'child_sha256':hashlib.sha256(b.encode()).hexdigest()}

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--root-reviewed-builder-sha256');args=ap.parse_args()
    ready=bool(args.root_reviewed_builder_sha256)
    if ready:assert args.root_reviewed_builder_sha256.lower()==sha(Path(__file__))
    label='ROOT_READY' if ready else 'NOTREADY';project=OUT/('project_'+label+'_05')
    assert not project.exists()
    assert sha(SOURCE)==SOURCE_SHA and sha(APPROVED_PNG)==APPROVED_SHA
    source=read(SOURCE);reportpath=resolve(source['capture']['capture_report']['path'])
    assert sha(reportpath)==REPORT_SHA
    report=read(reportpath);whole=report['worlds']['primary']
    f=read(PARENT/'input_shore_heads01_ROOT_READY.json')
    assert sha(PARENT/'input_shore_heads01_ROOT_READY.json')=='70182b0060879e2f82aa96b852c9868bd5c6a05887425aae7b3f4a24f89b9572'
    assert sha(PARENT/'source_successor_and_whole_inverse.json')=='6fb8749c2cc37fead5fd95afb47202a783280b53c5b15ec644db9f05160e1a11'
    expected_parent={'project.godot':'d92e36d4cbdef6815e4a7d1dfcd5d5ae7f36aa3b745352917bd6df0e5e67f9aa','sample_shore_heads01.gd':'424626f3c100e5b274ba7993ef0d4ecd2c460bc1d38af0a15810d8e4e6eae7ad','input_shore_heads01_ROOT_READY.json':'70182b0060879e2f82aa96b852c9868bd5c6a05887425aae7b3f4a24f89b9572','shore_heads_author01_NOTREADY.gd':'615efa0e8a6a29487ad56c51688c0f497228fbfed021b53be9d109dc5874ab23','member_projection02.gd':'7a66176634c7b437a2670267241d4c439e0d3c633cfca9664f0f9d62e9c7994b','wood_member_uv02.gdshader':'0f8aec3bc845c807983187b0e9c3be9361f31f351743c37d4ff184d4133d36e9'}
    originalfixture=json.loads(json.dumps(f));oldscript=(PARENT/'sample_shore_heads01.gd').read_text(encoding='utf-8')
    pins=dict(f['source_pins'])
    pins[source['capture']['capture_report']['path']]=REPORT_SHA
    pins[str(APPROVED_PNG.resolve())]=APPROVED_SHA
    for filename,pin in expected_parent.items():
        assert sha(PARENT/filename)==pin
        pins[str((PARENT/filename).resolve())]=pin
    pins[str((PARENT/'source_successor_and_whole_inverse.json').resolve())]='6fb8749c2cc37fead5fd95afb47202a783280b53c5b15ec644db9f05160e1a11'
    mask=[3104,1168,1088,816];feather=64
    rf=np.fromfile(resolve(f['height_rf']['path']),dtype='<f4')
    ymin=float(rf.min());ymax=float(rf.max())
    # Godot's YXZ Euler order: DirectionalLight rays are negative local Z.
    rx,ry=map(math.radians,[-55,-34]);ray=np.array([-math.sin(ry)*math.cos(rx),math.sin(rx),-math.cos(ry)*math.cos(rx)])
    assert ray[1]<0
    bounds={}
    for row in whole['coverage']['caster_bounds_evidence']:
        b=row['actual_used_index_bounds_m'];key=row['prototype']
        if key in bounds:assert bounds[key]==b
        bounds[key]=b
    def influence(points):
        # All possible receivers have h>=globalRFmin. Both direct-view body and
        # the full light segment down to minRF are bounded; PCF/bias margin64px.
        t=np.maximum(0.,(points[:,1]-min(ymin,-.025))/(-ray[1]))
        allp=np.concatenate([points,points+t[:,None]*ray],axis=0)
        xy=np.stack([6144+allp[:,0]*102.4,4096+(allp[:,2]-allp[:,1])*72.4077343935025],axis=1)
        lo=xy.min(0)-64;hi=xy.max(0)+64
        hit=bool(np.all(hi>=mask[:2]) and np.all(lo<=np.array(mask[:2])+mask[2:]))
        return dict(conservative_source_rect=[*lo.tolist(),*(hi-lo).tolist()],retained=hit,PCF_bias_margin_px=64)
    casters=[]
    for r in whole['casters']:
        r=json.loads(json.dumps(r));key=r['kind']+str(r['pose'])
        if r['caster_recipe'].startswith('NEW actual RGBA'):
            logical=np.array(r['logical_canvas_px'],dtype=np.float32);uv=np.array(r['actual_foot_uv'],dtype=np.float32);bb=np.array(r['basis_columns'],dtype=np.float32).T
            pp=[]
            for u,v in [(0,0),(1,0),(0,1),(1,1)]:
                # Reconstruct in f32 exactly like the unchanged plane helper.
                screen=np.array([(u-float(uv[0]))*float(logical[0]),(float(uv[1])-v)*float(logical[1])],dtype=np.float32)
                sx=np.float32(float(screen[0])/102.4);sy=np.float32(float(screen[1])/102.4)
                pp.append(bb[:,0]*sx+bb[:,1]*sy)
            packed=np.array(pp,dtype='<f4')
            vertex_sha=hashlib.sha256(packed.tobytes()).hexdigest()
            assert vertex_sha==r['native_stored_vertex_sha256'],r['id']
            r['offline_original_plane_vertex_byte_exact_sha256']=vertex_sha
            local=packed.astype(float);r['local_conservative_bounds']=[local.min(0).tolist(),local.max(0).tolist()]
            pins[r['actual_sourcebody_path']]=r['actual_sourcebody_sha256']
        else:
            r['local_conservative_bounds']=bounds[key];local=corners(*bounds[key])
        mat=np.array(r['transform']['basis_columns']).T;origin=np.array(r['transform']['origin'])
        points=local@mat.T+origin
        r['local_export_influence']=influence(points);casters.append(r)
        pins[r['actual_draw_mesh_path']]=r['actual_draw_mesh_sha256']
    assert len(casters)==2578
    bridges=[]
    for r in source['objects']:
        if 'actual_draw_geometry_path' not in r:continue
        row={k:r[k] for k in ['id','role','actual_draw_geometry_path','actual_draw_geometry_sha256','actual_used_world_bounds_m']}
        row['local_export_influence']=influence(corners(*r['actual_used_world_bounds_m']))
        row['target_bridge01']=r['id'].startswith('bridge_01_');bridges.append(row)
        pins[r['actual_draw_geometry_path']]=r['actual_draw_geometry_sha256']
    targets=[]
    for r in f['bridge']['parts']:
        original=next(x for x in source['objects'] if x['id']==r['id'])
        targets.append({'id':r['id'],'camera':original['sourcebody_camera'],'original_record':original,'target_relative_path':'entities/'+r['id']+'.png'})
    assert len(targets)==17
    chunk=next(x for x in source['chunks'] if x['id']=='r1_c2')
    pins[chunk['visual_path']]=source['asset_sha256'][chunk['visual_path']]
    planehelper=ROOT/'game/scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd'
    plane_pin=report['cached_inputs_sha256']['res://scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd']
    assert plane_pin=='d2d3795942aa452a18abc006d45bcde44749ccad276a7ec16e0f897604611290' and sha(planehelper)==plane_pin
    pins[str(planehelper.resolve())]=plane_pin
    f['ready']=ready;f['shore_heads_author']['ready']=ready
    f['status']='COHERENT18_BOUNDED_NATIVE_EXPORT_NOT_FORMAL'
    f['output_prefix']='res://coherent18_output/'
    f['deadline_ms']=60000
    f['source_pins']=pins
    f['export18']={'mask_outer_source_rect':mask,'feather_px':feather,'inner_rect':[3168,1232,960,688],
      'mask_formula':'mx=smoothstep(0,64,min(x-3104,4192-x));my=smoothstep(0,64,min(y-1168,1984-y));m=mx*my;outside=0;inner=1',
      'old_chunk_path':chunk['visual_path'],'old_chunk_sha256':pins[chunk['visual_path']],
      'chunk_logical_rect':[3072,1024,1536,1024],'overscan_rect':[2976,928,1728,1216],'native_canvas':[3456,2432],
      'whole_camera':whole['camera'],'targets':targets,'casters_all2578':casters,'bridges_all93':bridges,
      'RF_global_min_m':ymin,'RF_global_max_m':ymax,'light_ray':ray.tolist(),
      'caster_filter':'immutable actual used-index prototype bounds / actual4 plane vertices; exact original transform; whole ray to globalRFmin; screen footprint plus64px bias/PCF margin; include if intersects finite mask',
      'new_head_owner':'bridge_01_deck: original225x418/sourcebody_camera, both endbeams included, >=4px alpha border checked; reject rather than crop if not fit',
      'shadow_owner':'new native terrain/water only inside mask, original chunk only outside. All bridge sprites have shadow OFF; all native casters SHADOWS_ONLY; never oldshadow+newshadow additive',
      'scope':'17 original canvas sprite exports +1 bounded composite r1c2 only; NOT old wholeworld shadow atlas equivalence; no walk/other63chunk modification'}
    for path,pin in pins.items():assert sha(resolve(path))==pin.lower(),path
    protected={str(resolve(p).resolve()):fact(resolve(p)) for p in pins}
    # These two copied code consumers must be checked at both ends of the
    # actual export too, not merely their immutable original sources. They do
    # not yet exist in this NEW project; copy their pinned bytes below.
    pins[str((project/'shore_heads_author01_NOTREADY.gd').resolve())]=expected_parent['shore_heads_author01_NOTREADY.gd']
    pins[str((project/'original_plane_caster.gd').resolve())]=plane_pin
    fixturebytes=enc(f);inputname='input_export18_'+label+'.json'
    script=oldscript[:oldscript.index('func _execute() -> bool:')]+TEMPLATE.read_text(encoding='utf-8')
    script=script.replace('const READY=true','const READY='+str(ready).lower(),1)
    script=script.replace('const INPUT="res://input_shore_heads01_ROOT_READY.json"','const INPUT="res://'+inputname+'"',1)
    script=script.replace('const INPUT_SHA="70182b0060879e2f82aa96b852c9868bd5c6a05887425aae7b3f4a24f89b9572"','const INPUT_SHA="'+hashlib.sha256(fixturebytes).hexdigest()+'"',1)
    new(project/'project.godot',(PARENT/'project.godot').read_bytes())
    new(project/inputname,fixturebytes);new(project/'export_coherent18.gd',script.encode())
    for filename in ['shore_heads_author01_NOTREADY.gd','member_projection02.gd','wood_member_uv02.gdshader']:
        new(project/filename,(PARENT/filename).read_bytes())
    new(project/'original_plane_caster.gd',planehelper.read_bytes())
    protected[str(TEMPLATE.resolve())]=fact(TEMPLATE);protected[str(Path(__file__).resolve())]=fact(Path(__file__))
    retained_c=[r for r in casters if r['local_export_influence']['retained']]
    handoff={'status':'READY_NOT_RUN' if ready else 'NOTREADY_NOT_RUN','project':str(project.resolve()),'builder_sha256':sha(Path(__file__)),'template_sha256':sha(TEMPLATE),
      'script_sha256':sha(project/'export_coherent18.gd'),'fixture_sha256':hashlib.sha256(fixturebytes).hexdigest(),
      'sample_parent_whole_inverse':inverse(oldscript,script),'fixture_parent_whole_inverse':inverse(enc(originalfixture).decode(),fixturebytes.decode()),
      'retained_casters':len(retained_c),'discarded_casters':2578-len(retained_c),
      'retained_native_caster_meshes':sorted({r['actual_draw_mesh_path'] for r in retained_c if not r['caster_recipe'].startswith('NEW')}),
      'retained_other_bridges':len([r for r in bridges if r['local_export_influence']['retained'] and not r['target_bridge01']]),
      'targets':18,'whole_filter_source_matrices_frozen':2578,'protected_before':protected,
      'root_only_next':'Review key and run exactly once; no sample rerender. Only after actual report/ART/import/source closure may resolver02 adopt18.',
      'actual_calls':{'engine':0,'PNG_write':0,'production_write':0}}
    for p,v in protected.items():assert fact(Path(p))==v,p
    new(project/'export18_handoff.json',enc(handoff))
    print(json.dumps({k:v for k,v in handoff.items() if k in ['status','project','script_sha256','fixture_sha256','retained_casters','discarded_casters','retained_other_bridges','builder_sha256','template_sha256']}))
if __name__=='__main__':main()
