"""Read completed records, text sidecars and exact small artifact hashes only.
No image/ctex decode, engine, import, NAV, packet, promotion or production write.
"""
import hashlib
import json
from pathlib import Path

Q=Path(__file__).resolve().parent;G=Q.parents[1];W=G.parent
R=G/'build/luoyang_city_full_rollout_20261022ap_root01'
S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
I=W/'assets/staging/luoyang_life_scholar_isolated_import_20261024ap98'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=p.read_bytes()
    if h:assert sha(b)==h.lower(),str(p)
    return b
def load(p,h=None):return json.loads(read(p,h))
def ref(p):return {'path':str(p).replace('\\','/'),'sha256':sha(p.read_bytes()),'bytes':p.stat().st_size}
def respath(base,p):
    assert p.startswith('res://') and '..' not in p
    return base/p[6:]
def log_check(folder,receipt_name,stdout_name,stderr_name,exit_field):
    pp=folder/receipt_name;proc=load(pp)
    assert proc[exit_field]==0
    out=read(folder/stdout_name);err=read(folder/stderr_name)
    assert sha(out)==proc['stdout_sha256'] and sha(err)==proc['stderr_sha256']
    lines=err.decode('utf-8-sig').splitlines()
    return proc,{'receipt':ref(pp),'natural_exit':0,'errors':sum(x.startswith('ERROR:') for x in lines),'warnings':sum(x.startswith('WARNING:') for x in lines),'script_errors':sum('SCRIPT ERROR:' in x for x in lines),'stderr':ref(folder/stderr_name)}

# ROOT60 only the completed native-render report and guard, not native decoding.
r60p=R/'integration60/artisan_native_READY/output/23504_2645/result.json'
r60=load(r60p,'2b51a6ca2c55fd86733991bb2619b2f8c6cadfb2e193e877745f12feb449b850')
assert r60['complete'] and r60['checks']==916 and r60['failures']==0 and r60['elapsed_ms']==2543
assert r60['source_before']==r60['source_after'] and len(r60['source_before'])==84
assert r60['players_before']==r60['players_after'] and len(r60['players_before'])==15
newrows=[x for x in r60['records'] if x['kind']=='NEW_PROP_NATIVE_RENDER_AND_AUTHORED_FOOT']
spec=load(G/'build/luoyang_city_full_rollout_20261022ap_system01/artisan_life_delta_publication_epoch01/author_delta_NOTREADY.json','03f0a7fd0b71b2657fa783b253d86001813897f0f16e44793f866d09cce7a9f4')
assert len(newrows)==4
for row,source in zip(newrows,spec['placements']):
    assert row['no_geometry_calculation'] is True and row['row']['id']==source['id'] and row['row']['texture']==source['texture']
    for key in row['author_visual_only']:assert row['author_visual_only'][key]==source[key]
cams=[x for x in r60['records'] if x['kind']=='ALL_CAMERA_OPERANDS_BEFORE_ASSERT']
images=[x for x in r60['records'] if x['kind']=='PURE_NATIVE_VISIBLE_COMPARISON']
assert [x['label'] for x in cams]==['old132','new136'] and len(images)==2
for cam,image,count in zip(cams,images,[132,136]):
    assert cam['effective']=='(2112.0, 1508.0)' and cam['requested']=='(2816.0, 1740.0)' and cam['zoom']=='(1.0, 1.0)' and cam['viewport']=='(1920, 1080)'
    assert cam['smoothing'] is False and cam['limits']==[0,0,3072,2048]
    assert image['native_visuals']==count and image['ENV_water_Field_Player_NPC_HUD_omitted'] is True and image['no_packet_mask_Physics_geometry_collector_import'] is True
    read(respath(G,image['path']),image['sha256'])
assert images[0]['sha256']!=images[1]['sha256'] and images[0]['RGBA_sha256']!=images[1]['RGBA_sha256']
proc60,log60=log_check(R/'integration60','native_comparison_actual_process_receipt.json','native_comparison_actual_stdout.log','native_comparison_actual_stderr.log','actual_natural_console_exit_code')
assert proc60['exit_code_from_retained_process_WaitForExit'] is True and log60['errors']==9 and log60['warnings']==1 and log60['script_errors']==0
guardbefore=load(R/'integration60/guard_before.json');guardafter=load(R/'integration60/final_guard.json','af187ff4db4710c68ba596b35261346a0d57c8a73e9dd1d7ce654ee59bfc57ce')
assert guardbefore['passed'] and guardafter['passed'] and guardbefore['facts']==guardafter['facts'] and guardafter['checked']==guardafter['exact_unchanged']==2118
assert guardafter['save_count']==15 and guardafter['save_change_count']==guardafter['authorized_change_count']==guardafter['unexpected_change_count']==0
tb=load(R/'integration60/source_only_three_facts_before.json');ta=load(R/'integration60/source_only_three_facts_after.json');assert tb['facts']==ta['facts'] and len(tb['facts'])==3

# ROOT61 independent declared fullRGBA priors + actual external-isolate records.
planp=S/'performance98_life_walk_scholar_two_png_import_NOTRUN/import_plan_prior_bound_NOTREADY.json'
originalplan=load(planp,'ebc36d07aa4c7d7203faf468bbcd241e1ce769c4436e76eaa02325549df42e82')
preparedp=I/'prepared_READY.json';prepared=load(preparedp,'1ff1c4f67643183cfa379a8040316a8dd0cdcbf4f0fd89574893f89c0b851188')
irp=I/'life_walk_scholar_import_result_5336.json';imp=load(irp,'6946b4f81533d6a1221fc9a202acffa68f38f7d593b6a37fc1f19da0e47a243c')
assert imp['passed'] and imp['checks']==146 and imp['elapsed_ms']==141 and imp['failures']==[] and imp['production_promotions']==0
assert imp['engine_import_calls_by_verifier']==imp['geometry_Field_CPU_renderer_calls']==0
assert imp['source_first']==imp['source_final'] and len(imp['source_first'])==19
assert imp['prepared_sha256']==sha(preparedp.read_bytes())
walkprior=load(respath(G,originalplan['independent_walk_prior']['path']),originalplan['independent_walk_prior']['sha256'])
scholarprior=load(respath(G,originalplan['independent_scholar_prior']['path']),originalplan['independent_scholar_prior']['sha256'])
assert originalplan['textures'][0]['decoded_RGBA_sha256']==walkprior['expected_child_RGBA_sha256']
assert originalplan['textures'][1]['decoded_RGBA_sha256']==scholarprior['raw_RGBA_sha256']
assert len(originalplan['exact_23_import_params'])==23 and prepared['exact_23_import_params']==originalplan['exact_23_import_params']
assert len(imp['rows'])==2
def sidecar_sections(raw):
    current=None;out={};pending=None;buffer=[]
    for line in raw.decode('utf-8-sig').splitlines():
        line=line.strip()
        if not line:continue
        if pending is not None:
            buffer.append(line)
            if line=='}':out[current][pending]=''.join(buffer);pending=None;buffer=[]
            continue
        if line.startswith('[') and line.endswith(']'):current=line[1:-1];out[current]={};continue
        key,val=line.split('=',1)
        if val=='{':
            assert current=='remap' and key=='metadata'
            pending=key;buffer=['{']
        else:out[current][key]=val
    assert pending is None
    return out
sources_for_plan=[]
for actual,declared in zip(imp['rows'],originalplan['textures']):
    for k in ['domain','png','png_sha256','decoded_RGBA_sha256','sidecar','compiled']:assert actual[k]==declared[k]
    assert actual['size']==declared['source_size'] and actual['full_RGBA_exact'] is True and actual['params23'] is True
    assert actual['mipmaps']==0 and actual['detect_3d_compress_to']==0 and actual['raw_format_after_RGBA_conversion']==5 and actual['promoted'] is False
    assert actual['compiled']=='res://.godot/imported/'+Path(actual['png']).name+'-'+hashlib.md5(actual['png'].encode()).hexdigest()+'.ctex'
    png=respath(I,actual['png']);side=respath(I,actual['sidecar']);compiled=respath(I,actual['compiled'])
    read(png,actual['png_sha256']);sidebytes=read(side,actual['sidecar_sha256']);read(compiled,actual['compiled_sha256'])
    sections=sidecar_sections(sidebytes)
    params={k:json.loads(v) for k,v in sections['params'].items()}
    assert len(params)==23 and params==originalplan['exact_23_import_params']
    assert sections['remap']['importer']=='"texture"' and sections['remap']['type']=='"CompressedTexture2D"'
    assert json.loads(sections['remap']['metadata'])=={'vram_texture':False}
    assert json.loads(sections['remap']['path'])==actual['compiled'] and json.loads(sections['deps']['source_file'])==actual['png']
    assert json.loads(sections['deps']['dest_files'])==[actual['compiled']] and not any(x.startswith('path.') for x in sections['remap'])
    # Sidecar/ctex first; an absent main PNG is introduced only after both exist.
    for role in ['sidecar','compiled','png']:
        target=actual[role]
        if target not in declared['expected_absent_main_targets']:continue
        source=respath(I,target);dest=respath(G,target)
        assert not dest.exists(),str(dest)
        raw=source.read_bytes()
        sources_for_plan.append({'sequence':len(sources_for_plan)+1,'domain':actual['domain'],'role':role,'source':str(source).replace('\\','/'),'target':str(dest).replace('\\','/'),'target_res_path':target,'source_sha256':sha(raw),'source_bytes':len(raw),'old_target_sha256':'ABSENT','old_target_exists':False})
assert len(sources_for_plan)==5 and len({x['target'] for x in sources_for_plan})==5
assert {x['target'] for x in sources_for_plan}==set(prepared['main_five_absent_targets'])
assert imp['rows'][1]['alpha_used_rect_after_full_RGBA']=='[P: (57, 24), S: (47, 120)]'
for path,fact in prepared['protected_main_sources'].items():
    p=Path(path);assert sha(p.read_bytes())==fact['sha256'] and p.stat().st_size==fact['bytes'] and p.stat().st_mtime_ns==fact['mtime_ns']
procimport,logimport=log_check(R/'integration61','external_import_actual_process_receipt.json','external_import_actual_stdout.log','external_import_actual_stderr.log','actual_natural_console_exit_code')
procverify,logverify=log_check(R/'integration61','external_verify_actual_process_receipt.json','external_verify_actual_stdout.log','external_verify_actual_stderr.log','actual_natural_console_exit_code')
assert procimport['retained_process_WaitForExit'] and procverify['retained_process_WaitForExit'] and procimport['main_promotion'] is False and procverify['main_promotion'] is False
assert logimport['errors']==logimport['warnings']==logimport['script_errors']==0
assert logverify['errors']==0 and logverify['warnings']==2 and logverify['script_errors']==0

review60={'status':'ROOT60_NATIVE_FOUR_PROP_COMPARISON_LIMITED_TECHNICAL_REVIEW_NO_ART_OR_FIELD_ADMISSION',
          'actual':ref(r60p),'functional_complete':True,'checks':916,'elapsed_ms':2543,'source_facts_before_after':84,'player_saves_before_after':15,
          'four_source_author_visual_rows_exact':True,'native_counts':[132,136],'original_camera':{'requested':[2816,1740],'effective':[2112,1508],'zoom':1,'size':[1920,1080]},
          'two_images_hash_only_not_opened_by_this_review':[{k:x[k] for k in ['label','path','sha256','RGBA_sha256','native_visuals']} for x in images],
          'different_image_hashes_only_not_whole_ART_PASS':True,'no_ENV_water_Player_NPC_HUD_or_Field':True,
          'process':log60,'guard60_before':ref(R/'integration60/guard_before.json'),'guard60_after':ref(R/'integration60/final_guard.json'),
          '2118_all_fact_and15save_exactticks_same':True,'threeproof_same':True,
          'nonclean_boundary':'Natural exit0 but9ERROR/1WARN WASAPI/Texture/RID/RenderingServer exit messages. No clean/whole-city ART, Field, ghost or collision credit.',
          'QA_engine_image_decode_NAV_or_packet_calls':0}
review61={'status':'ROOT61_TWO_PNG_FULL_RGBA_TECHNICAL_ADMISSION_MAIN_FIVE_STILL_ABSENT_NOT_RUNTIME',
          'actual':ref(irp),'passed':True,'checks':146,'elapsed_ms':141,'source_first_final_facts':19,
          'Source98_fixed_prior_plan':ref(planp),'independent_walk_prior':originalplan['independent_walk_prior'],'independent_scholar_prior':originalplan['independent_scholar_prior'],
          'two_rows':imp['rows'],'exact23_sidecar_params_rechecked_without_texture_decode':True,
          'full_RGBA_and_mip0_raw_import_directctex_credit':'From fixed one Root verifier actual. QA compared unchanged pre-import priors/report/template and text sidecars; no repeated pixel decode.',
          'protected_main10_SHA_bytes_mtime_ns_current_same':True,'main_five_absent_current':prepared['main_five_absent_targets'],
          'retained_import_process':logimport,'retained_verifier_process':logverify,
          'nonclean':'Import stderr empty; verifier2rawImage export warnings,0ERROR/0SCRIPT; do not call combined workflow warning-free.',
          'Root61_full2118_postguard_credit_claimed':False,'Root60_guard_credit_not_borrowed_as61_after':True,
          'promotion_or_NPC_Field_ART_binding_not_granted_by_this_review':True,'QA_engine_import_decode_NAV_packet_production_writes':0}
plan={'status':'EXACT_FIVE_NEW_LEAF_MECHANICAL_PROMOTION_PLAN_AWAIT_ROOT_AUTHORIZATION_NOT_EXECUTED',
      'execution_authorized':False,'ready_for_Root_scope_review':True,'target_count':5,'targets':sources_for_plan,
      'basis_actual_verifier':ref(irp),'basis_import_process':logimport['receipt'],'basis_verify_process':logverify['receipt'],
      'basis_prepared':ref(preparedp),'fixed_independent_walk_RGBA':walkprior['expected_child_RGBA_sha256'],'fixed_independent_scholar_RGBA':scholarprior['raw_RGBA_sha256'],
      'protected_main_sources':prepared['protected_main_sources'],
      'strict_protocol':[
        'Root must first capture a fresh guard and separately authorize this exact ordered5target plan/hash while every target is ABSENT. Neither this plan nor isolated import authorizes execution.',
        'Before ANY write, verify all5target absences, all five isolated source SHA/bytes and the10protected main sources SHA/bytes/mtime_ns; if anything differs, stop before writing. No late authority or old-file overwrite.',
        'Copy only the listed whole bytes in sequence using exclusive CreateNew/xb. For each domain .import then .ctex; scholar PNG last. Existing Root59 walkPNG is protected and MUST NOT be rewritten.',
        'No Godot import/reimport/editor restart, image decode/edit/resave, parameter rewrite, UID-cache copying, source-code readiness or NPC binding changes. Keep editor/user processes untouched.',
        'After each copy require exact expected SHA/bytes. On editor race or CreateNew failure stop and report already-written subset; do not overwrite/delete/retry unseen leaves or promote extra .godot files.',
        'Finally require all5target SHA/bytes exact, all10protected sources SHA/bytes/mtime_ns exact and Root fresh-scope/save15 guard; report actual result. Source runtime closure/Family136/31 or scholar identity binding requires a separate authorized successor.'
      ],'promotion_executed_by_QA':False,'whole_city_ART_or_Field_or_new_NPC_runtime_credit':False}
files={'artisan_ROOT60_native_comparison_actual_readonly_review_READY.json':review60,
       'life_walk_scholar_ROOT61_isolated_import_actual_readonly_review_READY.json':review61,
       'life_walk_scholar_exact_five_leaf_promotion_plan_NOT_EXECUTED.json':plan}
patch='*** Begin Patch\n'
for name,value in files.items():
    p=Q/name;assert not p.exists();txt=json.dumps(value,ensure_ascii=False,indent=2)+'\n'
    patch+='*** Add File: '+str(p).replace('\\','/')+'\n'+''.join('+'+x+'\n' for x in txt.splitlines())
patch+='*** End Patch'
print(json.dumps({'patch':patch,'summary':{'Root60_checks':916,'Root60_native_only':True,'Root61_checks':146,'Root61_exit_import_verify':[0,0],'fullRGBA_priors_match':True,'main5_ABSENT':True,'protected10same':True,'promotion_plan_roles':[x['role'] for x in sources_for_plan],'promotion_executed':False,'engine_or_decode_by_QA':0}}))
