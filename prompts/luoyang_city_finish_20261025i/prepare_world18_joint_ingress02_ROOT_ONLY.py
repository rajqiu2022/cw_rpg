"""Freeze actual17 bridge outputs + actual1 accepted water receiver. No engine.

Default metadata only. Root's reviewed-SHA switch alone copies18 PNGs to a NEW
isolated project, never to canonical art/. Original rejected receiver excluded.
"""
from pathlib import Path
import argparse,hashlib,json,importlib.util
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];SELF=Path(__file__).resolve()
HELPER=SELF.with_name('prepare_world18_import_candidate01_ROOT_ONLY.py')
assert hashlib.sha256(HELPER.read_bytes()).hexdigest()=='6378dccdd0badb56d146cd5cbdc81febec8e02d682e709d09d6739816576e32b'
spec=importlib.util.spec_from_file_location('world18_common',HELPER);common=importlib.util.module_from_spec(spec);spec.loader.exec_module(common)
sha=common.sha;obj=common.obj;enc=common.enc;new=common.new;stat=common.stat
BASE=ROOT/'game/build/luoyang_city_finish_20261025i_art01/world24d_heads01'
OUT=BASE/'world18_ingress04';ISOLATE=OUT/'isolate_ROOT_PREPARED'
R17=BASE/'coherent18_01/project_ROOT_READY_05/coherent18_output/112968_1092042/result.json'
R1=BASE/'coherent18_01/water_receiver02_ROOT_READY_02/water_receiver02_output/112884_1163034/result.json'
P17='914add21d9d5f0d16cdf2f72ebbe33e0fee6bb08b732ca1616e44125cc18b95f'
P1='f1530acd718b054169dc288aff424fbcb583c08525008a5120d11090a2707b3c'
WATER='bf90b660f27990f206b86b351b78da3a4171af1123f3912542f8bb7758d94a00'
MANIFEST=OUT/'world18_joint_ingress_CANDIDATE.json'
COMPACT=OUT/'actual_joint_export_compact_receipt.json'

def fact(p):
    v=stat(p)
    if v['exists']:v['ticks']=str(v.pop('mtime_ns')//100+621355968000000000)
    return v
def res(p):return 'res://'+p.relative_to(ROOT/'game').as_posix()
def actuals():
    assert sha(R17)==P17 and sha(R1)==P1
    a=obj(R17);b=obj(R1)
    for j,n in [(a,18),(b,1)]:
        assert j['passed'] is True and j['elapsed_ms']<60000 and len(j['images'])==n and all(r['passed'] is True for r in j['checks'])
        assert j['sources_before']==j['sources_after']
        assert j['sources_before']['res://data/maps/world_map_v15_complete_v9c_source.json']==common.SOURCE_SHA
    c=b['water_composite02']
    assert c['dry_changed_pixels']==0 and c['outside_or_no_alpha_changed_pixels']==0 and c['all_chunk_alpha_bytes_old_exact'] is True
    assert c['all_visible_terrain_grass_shore_and_land_shadows_old_RGBA'] is True and c['no_additive_shadow'] is True and c['mask_randomness'] is False
    assert len(b['reused17'])==17 and b['images'][0]['sha256']==WATER
    return a,b

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--prepare-root-reviewed-script-sha256');args=ap.parse_args();prepare=bool(args.prepare_root_reviewed_script_sha256)
    if prepare:assert args.prepare_root_reviewed_script_sha256.lower()==sha(SELF)
    profile,params,profilepath=common.sources();schema=obj(common.SCHEMA);a,b=actuals();source=obj(common.SOURCE)
    for chunk in source['chunks']:
        p=chunk['walk_path'];assert a['sources_before'][p]==b['sources_before'][p]==source['asset_sha256'][p]
    expected=[(r['path'],r['source_size_px'],r) for r in schema['entries']]+[(schema['chunk']['path'],[1536,1024],schema['chunk'])]
    old17={r['relative_target']:r for r in a['images'][:17]};assert len(old17)==17
    reused={Path(r['path']).name:r for r in b['reused17']};rows=[];absent=[]
    for target,size,s in expected:
        rel=target.removeprefix('res://art/maps/world_bridge_shore_20261025i/')
        r=old17[rel] if rel.startswith('entities/') else b['images'][0]
        path=(R17.parent if rel.startswith('entities/') else R1.parent)/rel
        assert sha(path)==r['sha256'] and r['size']==size
        if rel.startswith('entities/'):
            assert reused[path.name]['sha256']==r['sha256'] and Path(reused[path.name]['path']).resolve()==path.resolve()
        with Image.open(path) as image:
            rgba=image.convert('RGBA');assert list(image.size)==size
            rgba_sha=hashlib.sha256(rgba.tobytes()).hexdigest();assert rgba_sha==r['RGBA_sha256']
            box=list(rgba.getchannel('A').getbbox())
        row={'domain':Path(target).stem,'source_path':path.relative_to(ROOT).as_posix(),'source_expected_sha256':r['sha256'],'png':target,'png_sha256':r['sha256'],'decoded_RGBA_sha256':rgba_sha,'source_size':size,'complete_A1_rect':box,'sidecar':target+'.import','compiled':'res://.godot/imported/'+Path(target).name+'-'+hashlib.md5(target.encode()).hexdigest()+'.ctex','actual_export_report_sha256':P17 if rel.startswith('entities/') else P1}
        for k in ['png','sidecar','compiled']:
            dst=common.absres(row[k]);assert not dst.exists(),dst;absent.append(str(dst.resolve()))
        rows.append(row)
    assert len(set(absent))==54 and rows[-1]['png_sha256']==WATER
    # Independent, full-pixel dry/shore boundary witness; reads only, no edits.
    oldpath=common.absres(schema['chunk']['old_path']);assert sha(oldpath)==schema['chunk']['old_sha256']
    old=np.array(Image.open(oldpath).convert('RGBA'));current=np.array(Image.open(R1.parent/'chunks/r1_c2_visual.png').convert('RGBA'))
    yy,xx=np.mgrid[0:1024,0:1536];sx=(xx+3072+.5).astype(np.float32);sy=(yy+1024+.5-.025*72.4077343935025).astype(np.float32)
    # Fixed actual RF is pinned in both actual reports.
    rfkey=next(p for p in b['sources_before'] if p.endswith('/derived_geometry/terrain_height.rf'))
    rfpath=common.absres(rfkey);assert sha(rfpath)==b['sources_before'][rfkey]
    rf=np.fromfile(rfpath,dtype='<f4').reshape(1025,1537)
    qx=sx/8;qy=sy/8;cx=np.floor(qx).astype(int);cy=np.floor(qy).astype(int);fx=qx-cx;fy=qy-cy
    aa=rf[cy,cx].astype(float);bb=rf[cy,cx+1].astype(float);ee=rf[cy+1,cx].astype(float);dd=rf[cy+1,cx+1].astype(float)
    bed=np.where(fx+fy<=1,aa+(bb-aa)*fx+(ee-aa)*fy,dd+(ee-dd)*(1-fx)+(bb-dd)*(1-fy))
    changed=np.any(old!=current,axis=2);dry=bed>=-.025
    assert np.count_nonzero(changed)==b['water_composite02']['changed_pixels']==100915 and not np.any(changed&dry)
    assert np.array_equal(old[:,:,3],current[:,:,3])
    witness={'status':'INDEPENDENT_FULL_PIXEL_READONLY_WITNESS','pixels':1572864,'changed_pixels':int(changed.sum()),'dry_pixels':int(dry.sum()),'dry_changed_pixels':int((changed&dry).sum()),'all_alpha_bytes_original_exact':True,'old_rgba_sha256':hashlib.sha256(old.tobytes()).hexdigest(),'new_rgba_sha256':hashlib.sha256(current.tobytes()).hexdigest(),'PNG_writes':0}
    compact={'passed':True,'source_sha256':common.SOURCE_SHA,'bridge_visual_count':17,'terrain_chunk_ids':['r1_c2'],'original17_physical_fields_unchanged':True,'all64_walks_unchanged':True,'coherent_original_shadow_footprint_owned':True,'capture_scope':'ACTUAL17_MEMBERS_PLUS_ACTUAL_WATER_ONLY_RECEIVER_NO_LAND_REPLACEMENT','actual_bridge_report':{'path':res(R17),'sha256':P17},'actual_water_report':{'path':res(R1),'sha256':P1},'rejected_old_receiver_adopted':False,'dry_RGBA_exact':True,'all_chunk_alpha_old_exact':True,'water_composite':b['water_composite02'],'independent_pixel_witness':witness,'export_rows':[{'path':r['png'],'sha256':r['png_sha256'],'RGBA_sha256':r['decoded_RGBA_sha256'],'size':r['source_size'],'actual_export_report_sha256':r['actual_export_report_sha256']} for r in rows],'Root_limited_ART_approval':'Root explicitly approved only water fine detail plus17 bridge bodies; straightbanks/common grass/wholeworld remain pending','ART_independent_view':'all17 exact member images and112884 original chunk personally viewed; finite local baseline only','formal_adopted':False}
    manifest={'status':'ACTUAL_JOINT18_MEDIA_INGRESS_NOT_IMPORTED_NOT_FORMAL','builder_sha256':sha(SELF),'compact_receipt_sha256':hashlib.sha256(enc(compact)).hexdigest(),'actual_reports':[compact['actual_bridge_report'],compact['actual_water_report']],'textures':rows,'main_54_targets':absent,'exact_23_import_params':params,'profile_path':str(profilepath),'profile_sha256':sha(profilepath),'verifier_template_sha256':common.VERIFY_SHA,'rejected_receiver_EXCLUDED':True,'formal_adopted':False}
    if not prepare:
        new(COMPACT,enc(compact));new(MANIFEST,enc(manifest))
        print(json.dumps({'status':manifest['status'],'manifest_sha256':sha(MANIFEST),'compact_sha256':sha(COMPACT),'builder_sha256':sha(SELF),'textures':18,'NEW_main_leaves_ABSENT':54,'pixel_witness':witness,'PNG_copy':0,'engine':0}));return
    assert obj(MANIFEST)==manifest and obj(COMPACT)==compact and not ISOLATE.exists()
    protected={str((ROOT/r['source_path']).resolve()):fact(ROOT/r['source_path']) for r in rows}
    for p in [SELF,HELPER,common.VERIFY,profilepath,common.SCHEMA,common.SOURCE,R17,R1,MANIFEST,COMPACT,oldpath,rfpath]:protected[str(p.resolve())]=fact(p)
    save_facts={str(Path(p).resolve()):fact(Path(p)) for p in profile['save_paths']}
    for p,v in save_facts.items():
        if v['exists']:protected[p]=v
    absent_saves=[p for p,v in save_facts.items() if not v['exists']]
    project=b'config_version=5\n\n[application]\nconfig/name="World joint18 exact import isolate"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\nrenderer/rendering_method.mobile="gl_compatibility"\n'
    new(ISOLATE/'project.godot',project)
    for r in rows:
        new(ISOLATE/r['png'][6:],(ROOT/r['source_path']).read_bytes())
        seed='[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\npath='+json.dumps(r['compiled'])+'\nmetadata={\n"vram_texture": false\n}\n\n[deps]\n\nsource_file='+json.dumps(r['png'])+'\ndest_files=['+json.dumps(r['compiled'])+']\n\n[params]\n'+'\n'.join(k+'='+json.dumps(v) for k,v in params.items())+'\n'
        new(ISOLATE/r['sidecar'][6:],seed.encode())
    prepared={'status':'EXACT_JOINT_WORLD18_ISOLATED_IMPORT_PREPARED','textures':rows,'project_sha256':hashlib.sha256(project).hexdigest(),'protected_main_sources':protected,'protected_absent_sources':absent_saves,'all15_save_facts':save_facts,'main_two_absent_targets':absent,'exact_23_import_params':params,'save_paths':profile['save_paths'],'production_promoted':False}
    pb=enc(prepared);new(ISOLATE/'prepared_READY.json',pb)
    script=common.VERIFY.read_text(encoding='utf-8').replace('EXACT_ONE_INNKEEPER_PORTRAIT_ISOLATED_IMPORT_PREPARED','EXACT_JOINT_WORLD18_ISOLATED_IMPORT_PREPARED').replace('spec.textures.size()==1','spec.textures.size()==18').replace('seen.size()==1','seen.size()==18')
    begin=script.index('const EXPECTED: Dictionary=');end=script.index('\nconst PARAMS:',begin)
    expect={r['domain']:{k:r[k] for k in ['png','png_sha256','decoded_RGBA_sha256','source_size','complete_A1_rect']} for r in rows}
    script=script[:begin]+'const EXPECTED: Dictionary='+json.dumps(expect,indent=2)+script[end:]
    anchor='raw.get_used_rect()==Rect2i(Vector2i.ZERO,size)';assert script.count(anchor)==1
    script=script.replace(anchor,'raw.get_used_rect()==Rect2i(int(EXPECTED[domain].complete_A1_rect[0]),int(EXPECTED[domain].complete_A1_rect[1]),int(EXPECTED[domain].complete_A1_rect[2])-int(EXPECTED[domain].complete_A1_rect[0]),int(EXPECTED[domain].complete_A1_rect[3])-int(EXPECTED[domain].complete_A1_rect[1]))')
    script=script.replace('innkeeper_portrait_import_result_','world_joint18_import_result_').replace('INNKEEPER_PORTRAIT_IMPORT','WORLD_JOINT18_IMPORT').replace('ONLY_ONE_ORIGINAL_OPAQUE_INNKEEPER_PORTRAIT_ISOLATED_FULL_RGBA_NOT_RUNTIME','EXACT_JOINT18_NATIVE_WORLD_EXPORTS_ISOLATED_FULL_RGBA_NOT_RUNTIME')
    script=script.replace('one original opaque innkeeper portrait','eighteen exact joint native world exports').replace('one original opaque portrait','eighteen exact joint native world exports').replace('Unique fixed portrait domain','Unique fixed native export domain').replace('Opaque source retains entire visible canvas; no trimming or alpha editing','Exact complete source A1 after fullRGBA verification')
    begin_absent='\n\tfor path: String in spec.main_two_absent_targets:\n'
    assert script.count(begin_absent)==1
    script=script.replace(begin_absent,'\n\tfor path: String in spec.protected_absent_sources:\n\t\tif not need(not FileAccess.file_exists(path),"Original absent save remains absent before verification"): return false\n'+begin_absent)
    end_absent='\n\tif spec is Dictionary:\n'
    assert script.count(end_absent)==1
    script=script.replace(end_absent,end_absent+'\t\tfor path: String in spec.protected_absent_sources:\n\t\t\tif not need(not FileAccess.file_exists(path),"Original absent save remains absent after verification"): passed=false\n')
    assert script.count('PENDING_PREPARED_SHA')==1 and script.count('const READY: bool=false')==1
    script=script.replace('PENDING_PREPARED_SHA',hashlib.sha256(pb).hexdigest()).replace('const READY: bool=false','const READY: bool=true')
    new(ISOLATE/'verify_READY.gd',script.encode())
    assert all(fact(Path(p))==v for p,v in protected.items()) and all(fact(Path(p))==v for p,v in save_facts.items()) and all(not Path(p).exists() for p in absent)
    result={'status':'ROOT_PREPARED_JOINT18_ISOLATE_NOT_RUN','prepared_sha256':hashlib.sha256(pb).hexdigest(),'verifier_sha256':hashlib.sha256(script.encode()).hexdigest(),'ingress_manifest_sha256':sha(MANIFEST),'compact_receipt_sha256':sha(COMPACT),'main54_ABSENT':True,'engine_calls':0,'canonical_writes':0,'isolate':str(ISOLATE)}
    new(ISOLATE/'preparation_receipt.json',enc(result));print(json.dumps(result))
if __name__=='__main__':main()
