"""Audit actual reported fullRGBA proof, never repeat decode or engine."""
from pathlib import Path
import hashlib,json,re
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
D=QA/'proof_source_tuple_ROOT39_READY';R=GAME/'build/luoyang_city_full_rollout_20261022ap_root01/integration39'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def locate(path):return D/path[6:] if path.startswith('res://') else Path(path)
rp=D/'output/117100_84/result.json';assert sha(rp)=='7477cdb2826f96d0d915bf51ab5da534f1fb24729e0d2f1c145c776c645dccc7'
r=rd(rp)
assert r['complete']is True and r['checks']==73 and r['failures']==[] and r['elapsed_ms']==157 and r['limit_ms']==15000
assert r['import_calls']==r['collector_Field_Scene_geometry_calls']==r['screenshots']==0 and not r['canonical_write'] and not r['runtime_ART_admission']
assert r['source_first']==r['source_final'] and len(r['source_first'])==8
assert r['players_before']==r['players_after'] and len(r['players_before'])==15
assert len(r['rows'])==2
native,tuple_row=r['rows']
state={'compressed':False,'format':5,'mipmaps':False,'size':[3072,2048]}
assert native['raw_then_compiled']==[state,state] and native['native_format_equality_not_a_frozen53624_contract']
assert tuple_row['native_states']==[state,state] and tuple_row['full_RGBA_exact'] and tuple_row['RGBA_sha256']=='6e72541153449e571516c340838794ff44fdf96dfc8b601b93733b3d4ff4c6da'
assert tuple_row['size']==[3072,2048] and tuple_row['mipmaps']==0 and tuple_row['exact_params23'] and tuple_row['detect_3d_compress_to']==1 and tuple_row['fix_alpha_border']is True
assert tuple_row['new_import_calls']==0 and tuple_row['runtime_texture_promotion']is False
bp=R/'proof_autoimport_tuple_before_retry1.json';ap=R/'proof_tuple_after_exactfacts.json'
assert sha(bp)=='19d3a71b39266c1baf97beb960f3e9987e1ea0e0e60c94ac2193961b6718d296'
assert sha(ap)=='2d30691c5ceaf6b4b5657c445d147d13985c30edef24dbf0d882f25d207bec05'
b,a=rd(bp),rd(ap)
assert a['passed'] and a['new_imports']==0 and a['before_sha256']==sha(bp)and a['facts']==b['facts']
assert len(a['facts'])==3
for row in a['facts']:
    p=Path(row['path']);assert sha(p)==row['sha256'] and p.stat().st_size==row['bytes']
assert tuple_row['raw_sha256']==a['facts'][0]['sha256']=='a186905d33e0dd148613c64a7f85bfb4a3cd734d040f9b937854ce605cadc4ed'
assert tuple_row['sidecar_sha256']==a['facts'][1]['sha256']=='0640e6c6584447940c6e961486a92809a0e9aaa4fd12b85f5ee55a7c636b14e6'
assert tuple_row['compiled_sha256']==a['facts'][2]['sha256']=='93c55bdd37077b51b3eb835c57950d6f62ca81bad45ee3f3c4cbac3cea1505bb'
for path,row in r['source_final'].items():
    p=locate(path);assert p.exists()==row['exists']
    if row['exists']:assert sha(p)==row['sha256'] and p.stat().st_size==row['bytes']
for path,row in r['players_after'].items():
    p=Path(path);assert p.exists()==row['exists']
    if row['exists']:assert sha(p)==row['sha256'] and p.stat().st_size==row['bytes']
pp=R/'proof_tuple_once_process_receipt.json';pr=rd(pp)
assert sha(pp)=='7aa11d6bfc7434dc3395578e5dcaf6d1c58c1d3822d9e367788d64224017cbf8'
assert pr['actual_natural_console_exit_code']==0 and pr['exit_code_from_retained_process_WaitForExit'] and not pr['process_stopped_by_tool'] and pr['headless']
assert Path(pr['project']).resolve()==D.resolve()and pr['elapsed_wall_ms']==1073
kp=D/'test_source_only_tuple_ROOT39_READY.gd'
assert sha(kp)==pr['script_sha256']==pr['script_after_sha256']=='6a5523abb258e34f96a66119e66be32512065a1c052e6b91ade8f60e3eba9a26'
ep,op=R/'proof_tuple_once_stderr.log',R/'proof_tuple_once_stdout.log'
assert sha(ep)==pr['stderr_sha256']=='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'and ep.stat().st_size==0
assert sha(op)==pr['stdout_sha256']
gp,gb=R/'final_guard.json',R/'guard_before.json';g,gbefore=rd(gp),rd(gb)
assert sha(gp)=='c304f1565e47ef22902916baaef6847b27d643575fd8288e5107d396cae0b81d'
assert g['passed'] and g['checked']==g['exact_unchanged']==2118 and g['authorized_change_count']==g['unexpected_change_count']==g['save_change_count']==0 and g['save_count']==15
assert g['facts']==gbefore['facts']
out=QA/'proof_tuple39_117100_SOURCE_ONLY_two_leaf_evidence_independent_review_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'ROOT39_ACTUAL_NEW_SOURCE_ONLY_TWO_LEAF_PIXEL_EVIDENCE_NO_RUNTIME_TEXTURE_ADMISSION','report':{'path':str(rp),'sha256':sha(rp)},'checks':{'complete':True,'checks':73,'failures':0,'verifier_ms':157,'global_limit_ms':15000,'native_raw_compiled_observed_formats':[5,5],'native_compressed':[False,False],'size':[3072,2048],'mipmaps':0,'full_RGBA_each_bytes':25165824,'both_full_data_equal_independent53624_SHA':'6e72541153449e571516c340838794ff44fdf96dfc8b601b93733b3d4ff4c6da','23currentparams_fixalpha_true_detect1_unchanged':True,'0imports_Field_Scene_collector_screenshots':True},'guard':{'8source_first_final_and_current_SHAbytes_exact':True,'new3facts_before_after_exactticks_same':True,'before_facts_sha256':sha(bp),'after_facts_sha256':sha(ap),'15save_FIRSTFINAL_currentSHAbytes_exact':True,'Root39_2118facts_exactticks_same':True,'Root39_final_guard_sha256':sha(gp)},'process':{'receipt_sha256':sha(pp),'true_console_exit':0,'elapsed_wall_ms':1073,'stderr_bytes':0,'ERROR':0,'WARNING':0,'SCRIPT_ERROR':0,'scope_only_clean':True},'two_source_leaves_proposed_for_Root_admission':[{'path':tuple_row['source']+'.import','sha256':tuple_row['sidecar_sha256'],'bytes':1005},{'path':tuple_row['compiled'],'sha256':tuple_row['compiled_sha256'],'bytes':888}],'boundaries':['NEW independentSOURCE_ONLY evidence for two currently existing autoimportleaves; the rawPNG alone is historical53624.','Rowlegacylabel HISTORICAL_PROOF_TUPLE refers to proofasset, never prior admission/oldtuple declaration for the two newleaves.','No borrowed olddetect0/fixalphafalse 2D import credit. Currentdetect1/fixalphatrue are frozen exactly, not modified.','No runtimeTexture/ART/Field/Market entry or loadingperformance credit; Root38FAIL not changed.','No source declaration or B/C strict-equality change performed by QA; Root must explicitly admit/source-close separately.'],'operations':{'engine':0,'decode_repeated':0,'collector':0,'import':0,'Stage':0,'canonical_write':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'source_only':True,'no_runtime_texture_credit':True}))
