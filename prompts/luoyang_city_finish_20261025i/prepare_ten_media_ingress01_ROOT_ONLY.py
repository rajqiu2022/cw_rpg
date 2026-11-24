"""Freeze 10 NEW media inputs and source coordinates. Default only manifest, no PNG copy.

Root may prepare the isolated import project with the reviewed builder SHA. This never
copies any formal PNG/import/ctex and never starts Godot. Old dry plans remain untouched.
"""
from pathlib import Path
import argparse,hashlib,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];SELF=Path(__file__).resolve()
OUT=ROOT/'game/build/luoyang_city_finish_20261025i_art01'
MANIFEST=OUT/'ten_media_ingress01_CANDIDATE.json'
ISOLATE=OUT/'ten_media_isolate_ROOT_PREPARED'
RAW=ROOT/'assets/raw/luoyang_city_finish_20261025i'
RAW_PINS={
 'chinese_open_ironwork_v1':'9e6bc9235eb9bfe067f4b9d0b1e7fd1b8f71c8741a02049404d76d20c2e11d7a',
 'chinese_open_ironwork_v2':'ce9eb745773590cedda2ac448aa9fa6ab03af84cf50abe5a285608822b9ff475',
 'pottery_kiln_house_v2':'6dcfd35123df03e5147411c820f6cbbc68dcab9eb8cad583763a067845cf983b',
 'ordinary_kitchen_rear_body_v2':'1f65539478c6e042bbb3726f9a281679759168589b7eb4363dc3f93c52bda935',
 'guard_young_bluegrey_walk4_v1':'012a7e75e954ca8d48d02f4ac04ae6282758623fc361c13441aeb17ad8fca5d7',
 'guard_veteran_ochre_walk4_v1':'823cb3d18541f9fec36d87e4a75c8c4d073a63394d6d2fbe7242d088d27d35e9',
 'guard_young_bluegrey_portrait_v1':'da6e1b0d01bbdc7142c24cb65de68687f7f4e7289676b2a028ce4c6c0b5f6933',
 'guard_veteran_ochre_portrait_v1':'0cde54603cd07130b600961f12eefcddb7dd0e2692ee7b7555453cbccad8ab06',
 'guard_young_bluegrey_idle_v1':'73b0cb61630d97443605ed4434a16dd40c08ce573fd2363718a3dd05cb9f3a69',
 'guard_veteran_ochre_idle_v1':'73f138dedd4b4d84659e079becc3a7cd9d45bf51d6047673a71ba9fb58b7078d',
 'young_spear_sentry_portrait_v1':'6c62528350aca92de039e2eabd901519f0ad7f0da5f122536552472c05c3372e'}
RECEIPTS={
 'processing':('game/build/luoyang_city_finish_20261025i_art01/processed_authorized_output/processing_receipt.json','ad7f08d6032f87eea5203f6e5ad23a1faa70e6d0d358d696fa3c4c9d3f0a161e'),
 'native':('game/build/luoyang_city_finish_20261025i_art01/native_format_ROOT_EXECUTED/format_receipt.json','93607fa1616327ac8bf07aa75cd8f1d52d615ba1b7ea7f9dd03657b701718e71'),
 'pixel_QA':('game/build/luoyang_city_finish_20261025i_system01/qa_role_new/art_pixels01/independent_pixel_audit01_READY.json','cc82d48a')}
PROFILE=ROOT/'game/build/luoyang_city_revision_20261025h_qa01/portrait_import01/input02_ROOT_READY.json'
VERIFIER=ROOT/'game/build/luoyang_city_revision_20261025h_qa01/portrait_import01/verify_template02_NOTEXEC.gd'
VERIFIER_SHA='445a516cf0a5995f33a6f388f657ebe4fb08207761f86dba14f3608486a6798d'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def obj(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def new(p,b):
    assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as f:f.write(b)
def save(p,d):new(p,(json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode())
def image_fact(p):
    with Image.open(p) as im:
        rgba=im.convert('RGBA')
        return {'png_sha256':sha(p),'source_size':list(im.size),'decoded_RGBA_sha256':hashlib.sha256(rgba.tobytes()).hexdigest(),'complete_A1_rect':list(rgba.getchannel('A').getbbox()),'alpha_extrema':list(rgba.getchannel('A').getextrema()),'png_bytes':p.stat().st_size}
def stat(p):
    if not p.exists():return {'exists':False}
    s=p.stat();return {'exists':True,'sha256':sha(p),'bytes':s.st_size,'mtime_ns':s.st_mtime_ns}
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--prepare-root-reviewed-script-sha256');a=ap.parse_args()
    execute=bool(a.prepare_root_reviewed_script_sha256)
    if execute: assert a.prepare_root_reviewed_script_sha256.lower()==sha(SELF)
    rec={}
    for name,(rel,pin) in RECEIPTS.items():
        p=ROOT/rel;h=sha(p);assert h==pin if len(pin)==64 else h.startswith(pin)
        rec[name]={'path':rel,'sha256':h}
    proc=obj(ROOT/rec['processing']['path']);native=obj(ROOT/rec['native']['path'])
    assert proc['authorized_plan_sha256']=='4c782b25e1d812e8e798ba1e98d491ed997aa01097099220929c2e6ee0eeaee5'
    raw_rows=[]
    for ident,pin in RAW_PINS.items():
        p=RAW/(ident+'.png');assert sha(p)==pin
        status='FAIL_RAW_RETAINED_NOT_PROCESSED_NOT_INGRESS' if ident=='chinese_open_ironwork_v1' else 'RAW_PRESERVED'
        raw_rows.append({'id':ident,'path':p.relative_to(ROOT).as_posix(),'fixed_original_sha256':pin,**image_fact(p),'status':status})
    items=[]
    for r in proc['outputs'][:3]:
        items.append({'domain':r['id'],'source_path':r['path'],'source_expected_sha256':r['sha256'],'png':'res://art/modules/luoyang_city_finish_20261025i/'+r['id']+'.png','source_kind':'USER_AUTHORIZED_FIVE_PLAN_BUILDING_DERIVATIVE','raw_source_ids':[r['id']]})
    for r in native['outputs']:
        ident=Path(r['path']).name.replace('_runtime160.png','')
        items.append({'domain':ident+'_runtime160','source_path':r['path'],'source_expected_sha256':r['sha256'],'png':'res://art/characters/luoyang_city_finish_20261025i/'+Path(r['path']).name,'source_kind':'ROOT_NORMAL_NATIVE_FORMAT_NOT_NEW_IMAGE_EDIT','raw_source_ids':[ident]})
    for ident in ['guard_young_bluegrey_portrait_v1','guard_veteran_ochre_portrait_v1','young_spear_sentry_portrait_v1']:
        items.append({'domain':ident,'source_path':(RAW/(ident+'.png')).relative_to(ROOT).as_posix(),'source_expected_sha256':RAW_PINS[ident],'png':'res://art/characters/portraits/luoyang_city_finish_20261025i/'+ident+'.png','source_kind':'OPAQUE_RAW_ORIGINAL_BYTES_UNPROCESSED','raw_source_ids':[ident]})
    absent=[]
    for r in items:
        p=ROOT/r['source_path'];assert sha(p)==r['source_expected_sha256'];r.update(image_fact(p))
        assert r['png_sha256']==r['source_expected_sha256']
        r['sidecar']=r['png']+'.import'
        r['compiled']='res://.godot/imported/'+Path(r['png']).name+'-'+hashlib.md5(r['png'].encode()).hexdigest()+'.ctex'
        r['NEW_main_targets']={k:{'path':v,'fact':stat(ROOT/('game/'+v[6:]))} for k,v in [(k,r[k]) for k in ['png','sidecar','compiled']]}
        assert all(not f['fact']['exists'] for f in r['NEW_main_targets'].values())
        absent.extend(str((ROOT/('game/'+r[k][6:])).resolve()) for k in ['png','sidecar','compiled'])
    assert len(items)==10 and len(set(absent))==30
    oldprofile=obj(PROFILE);params=oldprofile['exact_23_import_params'];assert len(params)==23
    assert params['process/fix_alpha_border'] is False and params['detect_3d/compress_to']==0 and not params['mipmaps/generate']
    assert sha(VERIFIER)==VERIFIER_SHA
    inherited={'profile_input':{'path':PROFILE.relative_to(ROOT).as_posix(),'sha256':sha(PROFILE)},'verifier_template':{'path':VERIFIER.relative_to(ROOT).as_posix(),'sha256':sha(VERIFIER)},'exact_23_import_params':params,'save_paths':oldprofile['save_paths']}
    manifest={'status':'TEN_NEW_MEDIA_INGRESS_CANDIDATE_NOT_COPIED_NOT_IMPORTED','ready':False,'builder_sha256':sha(SELF),'authorization_status':'ROOT_REPORTED_USER_EXPLICIT_FIVE_IMAGE_SCOPE_AND_ACTUAL_RECEIPT_PRESERVED','permission_scope':'Exactly3building+2walk weak-alpha ledgers/padding/integeralignment. Twoidle only fullRGBA padding/normalformat, threeportraits originalopaque bytes. NOT all11raw locally processed.','receipts':rec,'raw_originals_11':raw_rows,'raw_originals_processed_by_five_plan_count':5,'textures':items,'main_30_targets':absent,'main_30_targets_all_ABSENT':True,'mature25h_isolate_recipe':inherited,'engine_calls':0,'PNG_copies_by_ART':0,'canonical_writes':0,'formal_adopted':False,'old_dry_files_not_modified':True}
    if not execute:
        save(MANIFEST,manifest)
        # Exact pixel-space declarations after transparent padding; NEVER canvas-fit.
        measures=obj(OUT/'manual_building_measurements01.json')
        grounds=obj(OUT/'manual_ground_contacts02.json')
        # Ground contract stays separately source-bound, no fake duplicate geometry.
        declaration=[]
        scales={'chinese_open_ironwork_v2':[760,1487],'pottery_kiln_house_v2':[170,297],'ordinary_kitchen_rear_body_v2':[145,294]}
        pads={'chinese_open_ironwork_v2':[128,16],'pottery_kiln_house_v2':[96,0],'ordinary_kitchen_rear_body_v2':[64,32]}
        for m in measures['rows']:
            ident=m['id'];r=next(x for x in items if x['domain']==ident);px,py=pads[ident]
            anchor=m['manual_threshold_front_anchor_raw'];door=m.get('conservative_visible_workbay_rect',m.get('conservative_closed_wooden_door_rect'))
            moved=lambda q:[q[0]+px,q[1]+py,q[2]+px,q[3]+py]
            declaration.append({'id':ident,'texture':r['png'],'source_size':r['source_size'],'source_PNG_sha256':r['png_sha256'],'source_RGBA_sha256':r['decoded_RGBA_sha256'],'raw_path':m['raw_path'],'raw_sha256':m['raw_sha256'],'old_canvas_offset_xy':[px,py],'raw_threshold_anchor_xy':anchor,'padded_threshold_anchor_xy':[anchor[0]+px,anchor[1]+py],'padded_subject_A1_xyxy':r['complete_A1_rect'],'padded_visible_door_or_bay_rect_xyxy':moved(door),'uniform_scale_numerator_denominator':scales[ident],'source_transform':'world_point = world_foot + (padded_point - padded_threshold_anchor)*uniform; Source uses authored f32. Old raw-point expression remains identical after both points addpadding.','ground_model_path':'game/build/luoyang_city_finish_20261025i_art01/manual_ground_contacts02.json','ground_model_sha256':sha(OUT/'manual_ground_contacts02.json'),'ground_polygons_transform':'Each original raw ground vertex adds exact old_canvas_offset_xy before source transform; no roof/A1 as solid.','new_portal':False,'physics_or_field_credit':False})
        save(OUT/'three_buildings_processed_source_declarations01_CANDIDATE.json',{'status':'EXACT_PROCESSED_PIXEL_COORDINATES_SOURCE_DECLARATION_NOT_FORMAL_OR_PHYSICS_PASS','ingress_manifest_sha256':sha(MANIFEST),'processing_receipt':rec['processing'],'rows':declaration})
        print(json.dumps({'status':manifest['status'],'manifest':MANIFEST.relative_to(ROOT).as_posix(),'manifest_sha256':sha(MANIFEST),'three_buildings_declarations_sha256':sha(OUT/'three_buildings_processed_source_declarations01_CANDIDATE.json'),'builder_sha256':sha(SELF),'textures':10,'main_targets_ABSENT':30,'engine':0,'PNG_copy':0}))
        return
    frozen=obj(MANIFEST)
    # Current expected data is independently reconstructed from upstream immutable receipts.
    assert manifest==frozen and not ISOLATE.exists()
    ISOLATE.mkdir()
    protected={str((ROOT/r['source_path']).resolve()):stat(ROOT/r['source_path']) for r in items}
    for rel in [SELF.relative_to(ROOT),MANIFEST.relative_to(ROOT),PROFILE.relative_to(ROOT),VERIFIER.relative_to(ROOT)]+[Path(r['path']) for r in rec.values()]:
        p=ROOT/rel;protected[str(p.resolve())]=stat(p)
    project=b'config_version=5\n\n[application]\nconfig/name="Luoyang25i exact10media import isolate"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\nrenderer/rendering_method.mobile="gl_compatibility"\n'
    new(ISOLATE/'project.godot',project)
    for r in items:
        new(ISOLATE/r['png'][6:],(ROOT/r['source_path']).read_bytes())
        seed='[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\npath='+json.dumps(r['compiled'])+'\nmetadata={\n"vram_texture": false\n}\n\n[deps]\n\nsource_file='+json.dumps(r['png'])+'\ndest_files=['+json.dumps(r['compiled'])+']\n\n[params]\n'+'\n'.join(k+'='+json.dumps(v) for k,v in params.items())+'\n'
        new(ISOLATE/r['sidecar'][6:],seed.encode())
    prepared={'status':'EXACT_TEN_MEDIA_ISOLATED_IMPORT_PREPARED','textures':items,'project_sha256':hashlib.sha256(project).hexdigest(),'protected_main_sources':protected,'main_two_absent_targets':absent,'exact_23_import_params':params,'save_paths':oldprofile['save_paths'],'production_promoted':False}
    preparedbytes=(json.dumps(prepared,ensure_ascii=False,indent=2)+'\n').encode();new(ISOLATE/'prepared_READY.json',preparedbytes)
    # Adapt mature verifier only for count, fixed A1 peritem and mixed alpha; keep fullRGBA oracle.
    verifier=VERIFIER.read_text(encoding='utf-8')
    verifier=verifier.replace('EXACT_ONE_INNKEEPER_PORTRAIT_ISOLATED_IMPORT_PREPARED','EXACT_TEN_MEDIA_ISOLATED_IMPORT_PREPARED').replace('spec.textures.size()==1','spec.textures.size()==10').replace('seen.size()==1','seen.size()==10')
    expected={r['domain']:{k:r[k] for k in ['png','png_sha256','decoded_RGBA_sha256','source_size','complete_A1_rect']} for r in items}
    begin=verifier.index('const EXPECTED: Dictionary=');end=verifier.index('\nconst PARAMS:',begin)
    verifier=verifier[:begin]+'const EXPECTED: Dictionary='+json.dumps(expected,indent=2)+verifier[end:]
    old='raw.get_used_rect()==Rect2i(Vector2i.ZERO,size)'
    assert verifier.count(old)==1
    verifier=verifier.replace(old,'raw.get_used_rect()==Rect2i(int(EXPECTED[domain].complete_A1_rect[0]),int(EXPECTED[domain].complete_A1_rect[1]),int(EXPECTED[domain].complete_A1_rect[2])-int(EXPECTED[domain].complete_A1_rect[0]),int(EXPECTED[domain].complete_A1_rect[3])-int(EXPECTED[domain].complete_A1_rect[1]))')
    verifier=verifier.replace('Opaque source retains entire visible canvas; no trimming or alpha editing','Exact fixed complete A1 with wholeRGBA oracle; transparent and opaque assets not conflated')
    verifier=verifier.replace('one original opaque innkeeper portrait','ten fixed mixed-alpha Luoyang25i media').replace('One original opaque innkeeper portrait','Ten fixed mixed-alpha Luoyang25i media').replace('ONE_ORIGINAL_OPAQUE_INNKEEPER_PORTRAIT','TEN_FIXED_MIXED_ALPHA_LUOYANG_MEDIA').replace('innkeeper_portrait_import_result_','ten_media_import_result_').replace('INNKEEPER_PORTRAIT_IMPORT','TEN_MEDIA_IMPORT')
    assert verifier.count('PENDING_PREPARED_SHA')==1 and verifier.count('const READY: bool=false')==1
    verifier=verifier.replace('PENDING_PREPARED_SHA',hashlib.sha256(preparedbytes).hexdigest()).replace('const READY: bool=false','const READY: bool=true')
    new(ISOLATE/'verify_READY.gd',verifier.encode())
    assert all(stat(Path(p))==v for p,v in protected.items()) and all(not Path(p).exists() for p in absent)
    result={'status':'ROOT_PREPARED_TEN_MEDIA_ISOLATE_NO_ENGINE_NO_MAIN_COPY','prepared_sha256':hashlib.sha256(preparedbytes).hexdigest(),'verifier_sha256':hashlib.sha256(verifier.encode()).hexdigest(),'ingress_manifest_sha256':sha(MANIFEST),'main30_ABSENT':True,'canonical_writes':0,'engine_calls':0,'isolate':str(ISOLATE),'root_commands':[['GODOT','--headless','--editor','--import','--path',str(ISOLATE),'--quit'],['GODOT','--headless','--path',str(ISOLATE),'--script','res://verify_READY.gd']]}
    save(ISOLATE/'preparation_receipt.json',result);print(json.dumps(result))
if __name__=='__main__':main()
