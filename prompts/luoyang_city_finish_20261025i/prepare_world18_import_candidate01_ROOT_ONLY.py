"""Static preflight now; future exact18 manifest/import preparation by Root only.

No engine. Default writes nothing. Actual exports and their fixed Root-supplied
SHA are mandatory: this never fills missing pixels, guessed hashes or approval.
"""
from pathlib import Path
import argparse,hashlib,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];SELF=Path(__file__).resolve()
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01/world24d_heads01/world18_ingress01'
BASE=OUT.parent
SCHEMA=BASE/'approved_visual_manifest_SCHEMA_NOTREADY.json'
OLD_MANIFEST=ROOT/'game/build/luoyang_city_finish_20261025i_art01/ten_media_ingress01_CANDIDATE.json'
OLD_SHA='a94d4cbb8d14cd6921be335e42c74b6a27ad0325ff9d6c11b0ee3dbe466ccffc'
VERIFY=ROOT/'game/build/luoyang_city_revision_20261025h_qa01/portrait_import01/verify_template02_NOTEXEC.gd'
VERIFY_SHA='445a516cf0a5995f33a6f388f657ebe4fb08207761f86dba14f3608486a6798d'
SOURCE=ROOT/'game/data/maps/world_map_v15_complete_v9c_source.json'
SOURCE_SHA='85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def obj(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def new(p,b):
    assert not p.exists(),p
    p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as h:h.write(b)
def absres(p):return ROOT/('game/'+p[6:]) if p.startswith('res://') else Path(p)
def stat(p):
    if not p.exists():return {'exists':False}
    s=p.stat();return {'exists':True,'sha256':sha(p),'bytes':s.st_size,'mtime_ns':s.st_mtime_ns}
def sources():
    assert sha(OLD_MANIFEST)==OLD_SHA and sha(VERIFY)==VERIFY_SHA and sha(SOURCE)==SOURCE_SHA
    inherited=obj(OLD_MANIFEST)['mature25h_isolate_recipe'];profile=ROOT/inherited['profile_input']['path']
    assert sha(profile)==inherited['profile_input']['sha256']
    p=obj(profile);params=p['exact_23_import_params']
    assert params==inherited['exact_23_import_params'] and len(params)==23
    assert params['process/fix_alpha_border'] is False and params['detect_3d/compress_to']==0 and params['mipmaps/generate'] is False
    return p,params,profile
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--actual-export-report');ap.add_argument('--actual-export-report-sha256');ap.add_argument('--freeze-ingress',action='store_true');ap.add_argument('--prepare-root-reviewed-script-sha256');a=ap.parse_args()
    profile,params,profilepath=sources();schema=obj(SCHEMA)
    assert schema['approved'] is False and len(schema['entries'])==17
    expected=[(r['path'],r['source_size_px'],r) for r in schema['entries']]+[(schema['chunk']['path'],[1536,1024],schema['chunk'])]
    absent=[]
    for p,_,_ in expected:
        compiled='res://.godot/imported/'+Path(p).name+'-'+hashlib.md5(p.encode()).hexdigest()+'.ctex'
        for q in [p,p+'.import',compiled]:
            assert not absres(q).exists(),q;absent.append(str(absres(q).resolve()))
    assert len(set(absent))==54
    if not a.actual_export_report:
        assert not a.freeze_ingress and not a.prepare_root_reviewed_script_sha256
        print(json.dumps({'status':'STATIC_ONLY_18_OUTPUTS_MISSING_EXPECTED_NOT_ASSUMED','builder_sha256':sha(SELF),'mature_verifier_sha256':VERIFY_SHA,'main54_ABSENT':True,'params23':True,'PNG_copies':0,'engine':0,'actual_export_required':True}));return
    report=Path(a.actual_export_report).resolve();assert a.actual_export_report_sha256 and sha(report)==a.actual_export_report_sha256.lower()
    actual=obj(report)
    assert actual['passed'] is True and actual['elapsed_ms']<60000 and len(actual['images'])==18
    assert all(r['passed'] is True for r in actual['checks'])
    assert actual['sources_before']==actual['sources_after'] and actual['sources_before']['res://data/maps/world_map_v15_complete_v9c_source.json']==SOURCE_SHA
    source=obj(SOURCE)
    for c in source['chunks']:
        p=c['walk_path'];assert actual['sources_before'][p]==source['asset_sha256'][p]
    c=actual['composite'];assert c['outside_RGBA_exact'] is True and c['inner_RGBA_new_native_exact'] is True and c['new_inside_replaces_old_inside_not_overlay'] is True and c['changed_pixels']>0
    assert c['mask_outer_source_rect']==[3104,1168,1088,816] and c['mask_inner_source_rect']==[3168,1232,960,688] and c['mask_feather_px']==64
    assert c['no_additive_shadow'] is True and c['limited_local_camera_not_old_wholeworld_shadow_atlas_equivalence'] is True
    byrel={r['relative_target']:r for r in actual['images']};assert len(byrel)==18
    rows=[]
    for target,size,s in expected:
        relative=target.removeprefix('res://art/maps/world_bridge_shore_20261025i/');r=byrel[relative]
        p=report.parent/relative;assert p.exists() and sha(p)==r['sha256'] and r['size']==size
        with Image.open(p) as im:
            rgba=im.convert('RGBA');assert list(im.size)==size
            rgba_sha=hashlib.sha256(rgba.tobytes()).hexdigest();assert rgba_sha==r['RGBA_sha256']
            box=list(rgba.getchannel('A').getbbox())
        if relative.startswith('entities/'):
            original=next(o for o in source['objects'] if o['id']+'.png'==Path(target).name)
            assert r['original_runtime_record']==original and r['original_camera']==original['sourcebody_camera']
            assert r['shadow_ownership']=='OFF in transparent sprite; actual new cast only in chunk receiver'
        rows.append({'domain':Path(target).stem,'source_path':p.relative_to(ROOT).as_posix(),'source_expected_sha256':r['sha256'],'png':target,'png_sha256':r['sha256'],'decoded_RGBA_sha256':rgba_sha,'source_size':size,'complete_A1_rect':box,'sidecar':target+'.import','compiled':'res://.godot/imported/'+Path(target).name+'-'+hashlib.md5(target.encode()).hexdigest()+'.ctex'})
    compact={'passed':True,'source_sha256':SOURCE_SHA,'bridge_visual_count':17,'terrain_chunk_ids':['r1_c2'],'original17_physical_fields_unchanged':True,'all64_walks_unchanged':True,'coherent_original_shadow_footprint_owned':True,
      'capture_scope':'BOUNDED_NATIVE_RECEIVER_REPLACEMENT_NOT_WHOLE_SHADOW_ATLAS_EQUIVALENCE','mask_outer_source_rect':c['mask_outer_source_rect'],'mask_inner_source_rect':c['mask_inner_source_rect'],'mask_feather_px':64,'outside_RGBA_exact':True,'inner_RGBA_new_native_exact':True,'no_additive_shadow':True,'whole_changed_footprint':{k:c[k] for k in ['changed_pixels','changed_local_bbox','outside_pixels','inner_pixels','transition_pixels']},'actual_export_report':{'path':report.relative_to(ROOT).as_posix(),'sha256':sha(report)},'actual_elapsed_ms':actual['elapsed_ms'],'export_rows':[{'path':r['png'],'sha256':r['png_sha256'],'RGBA_sha256':r['decoded_RGBA_sha256'],'size':r['source_size']} for r in rows],'ART_approval':False,'formal_adopted':False}
    manifest={'status':'ACTUAL_18_NATIVE_EXPORTS_FROZEN_NOT_ART_APPROVED_NOT_IMPORTED','builder_sha256':sha(SELF),'actual_export_report':compact['actual_export_report'],'compact_export_receipt_sha256':hashlib.sha256(enc(compact)).hexdigest(),'textures':rows,'main_54_targets':absent,'exact_23_import_params':params,'profile_path':str(profilepath),'profile_sha256':sha(profilepath),'verifier_sha256':VERIFY_SHA,'formal_approved':False}
    if a.freeze_ingress:
        assert not a.prepare_root_reviewed_script_sha256
        new(OUT/'actual_export_compact_receipt.json',enc(compact));new(OUT/'world18_ingress_CANDIDATE.json',enc(manifest));print(json.dumps({'status':manifest['status'],'manifest_sha256':sha(OUT/'world18_ingress_CANDIDATE.json'),'compact_receipt_sha256':sha(OUT/'actual_export_compact_receipt.json'),'engine':0,'PNG_copy':0}));return
    assert a.prepare_root_reviewed_script_sha256 and a.prepare_root_reviewed_script_sha256.lower()==sha(SELF)
    assert obj(OUT/'world18_ingress_CANDIDATE.json')==manifest and obj(OUT/'actual_export_compact_receipt.json')==compact
    isolate=OUT/'isolate_ROOT_PREPARED';assert not isolate.exists()
    protected={str((ROOT/r['source_path']).resolve()):stat(ROOT/r['source_path']) for r in rows}
    for p in [SELF,VERIFY,profilepath,report,OUT/'world18_ingress_CANDIDATE.json',OUT/'actual_export_compact_receipt.json',SCHEMA,SOURCE]:protected[str(p.resolve())]=stat(p)
    project=b'config_version=5\n\n[application]\nconfig/name="World coherent18 exact import isolate"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\nrenderer/rendering_method.mobile="gl_compatibility"\n'
    new(isolate/'project.godot',project)
    for r in rows:
        new(isolate/r['png'][6:],(ROOT/r['source_path']).read_bytes())
        seed='[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\npath='+json.dumps(r['compiled'])+'\nmetadata={\n"vram_texture": false\n}\n\n[deps]\n\nsource_file='+json.dumps(r['png'])+'\ndest_files=['+json.dumps(r['compiled'])+']\n\n[params]\n'+'\n'.join(k+'='+json.dumps(v) for k,v in params.items())+'\n'
        new(isolate/r['sidecar'][6:],seed.encode())
    prepared={'status':'EXACT_WORLD18_ISOLATED_IMPORT_PREPARED','textures':rows,'project_sha256':hashlib.sha256(project).hexdigest(),'protected_main_sources':protected,'main_two_absent_targets':absent,'exact_23_import_params':params,'save_paths':profile['save_paths'],'production_promoted':False}
    pb=enc(prepared);new(isolate/'prepared_READY.json',pb)
    script=VERIFY.read_text(encoding='utf-8').replace('EXACT_ONE_INNKEEPER_PORTRAIT_ISOLATED_IMPORT_PREPARED','EXACT_WORLD18_ISOLATED_IMPORT_PREPARED').replace('spec.textures.size()==1','spec.textures.size()==18').replace('seen.size()==1','seen.size()==18')
    expected_dict={r['domain']:{k:r[k] for k in ['png','png_sha256','decoded_RGBA_sha256','source_size','complete_A1_rect']} for r in rows}
    begin=script.index('const EXPECTED: Dictionary=');end=script.index('\nconst PARAMS:',begin)
    script=script[:begin]+'const EXPECTED: Dictionary='+json.dumps(expected_dict,indent=2)+script[end:]
    anchor='raw.get_used_rect()==Rect2i(Vector2i.ZERO,size)';assert script.count(anchor)==1
    script=script.replace(anchor,'raw.get_used_rect()==Rect2i(int(EXPECTED[domain].complete_A1_rect[0]),int(EXPECTED[domain].complete_A1_rect[1]),int(EXPECTED[domain].complete_A1_rect[2])-int(EXPECTED[domain].complete_A1_rect[0]),int(EXPECTED[domain].complete_A1_rect[3])-int(EXPECTED[domain].complete_A1_rect[1]))')
    script=script.replace('innkeeper_portrait_import_result_','world_coherent18_import_result_').replace('INNKEEPER_PORTRAIT_IMPORT','WORLD_COHERENT18_IMPORT')
    script=script.replace('ONLY_ONE_ORIGINAL_OPAQUE_INNKEEPER_PORTRAIT_ISOLATED_FULL_RGBA_NOT_RUNTIME','EXACT_18_NATIVE_WORLD_EXPORTS_ISOLATED_FULL_RGBA_NOT_RUNTIME')
    script=script.replace('one original opaque innkeeper portrait','eighteen fixed native world exports').replace('one original opaque portrait','eighteen fixed native world exports').replace('Unique fixed portrait domain','Unique fixed native export domain').replace('Opaque source retains entire visible canvas; no trimming or alpha editing','Exact predeclared complete A1; fullRGBA preserves all hidden pixels')
    assert script.count('PENDING_PREPARED_SHA')==1 and script.count('const READY: bool=false')==1
    script=script.replace('PENDING_PREPARED_SHA',hashlib.sha256(pb).hexdigest()).replace('const READY: bool=false','const READY: bool=true')
    new(isolate/'verify_READY.gd',script.encode())
    assert all(stat(Path(p))==v for p,v in protected.items()) and all(not Path(p).exists() for p in absent)
    receipt={'status':'ROOT_PREPARED_18_ISOLATE_NOT_RUN','prepared_sha256':hashlib.sha256(pb).hexdigest(),'verifier_sha256':hashlib.sha256(script.encode()).hexdigest(),'ingress_sha256':sha(OUT/'world18_ingress_CANDIDATE.json'),'main54_ABSENT':True,'engine_calls':0,'canonical_writes':0}
    new(isolate/'preparation_receipt.json',enc(receipt));print(json.dumps(receipt))
if __name__=='__main__':main()
