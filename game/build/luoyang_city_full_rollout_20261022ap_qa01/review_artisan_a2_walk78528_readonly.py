"""Independent isolated-import receipt/source audit only; never decodes images."""
import configparser,hashlib,json
from pathlib import Path
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
SYSTEM=GAME/'build/luoyang_city_full_rollout_20261022ap_system01';ISO=SYSTEM/'a2mi01'
P=ISO/'single_walk_import_result_78528.json';PREP=ISO/'prepared_READY.json'
OUT=QA/'artisan_a2_walk78528_independent_readonly_review_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def iso(p):return ISO/p[6:] if p.startswith('res://') else Path(p)
assert not OUT.exists()
assert sha(P)=='299fcadbe84424197f095d737ecdbca8740612779176578fbbb5ddf249de0b3f'
assert sha(PREP)=='bf52cdcdf321d6d8732501b95fd2e52cfec2d797c2716386df98b3ed55423f54'
assert (SYSTEM/'a2_single_walk_import_tools_epoch01/prepared_READY.json').read_bytes()==PREP.read_bytes()
r=json.loads(P.read_bytes());p=json.loads(PREP.read_bytes())
assert r['passed'] and r['failures']==[] and (r['checks'],r['elapsed_ms'],r['limit_ms'])==(94,131,30000)
assert r['prepared_sha256']==sha(PREP)
assert r['source_first']==r['source_final'] and len(r['source_first'])==20
for source,f in r['source_first'].items():
    q=iso(source);s=q.stat()
    assert f['exists'] and sha(q)==f['sha256'] and s.st_size==f['bytes'] and s.st_mtime_ns//1000000000==f['mtime'],source
assert len(p['protected_main_sources'])==14 and len(p['old_eight_main_source_facts'])==8
for source,f in p['protected_main_sources'].items():
    q=Path(source);s=q.stat()
    assert sha(q)==f['sha256'] and s.st_size==f['bytes'] and s.st_mtime_ns==f['mtime_ns'],source
for source,f in p['old_eight_main_source_facts'].items():assert p['protected_main_sources'][source]==f
assert len(r['rows'])==1
row=r['rows'][0];decl=p['textures'][0]
assert row['domain']=='artisan_a2' and row['promoted'] is False and row['size']==[3072,2048]
assert row['decoded_RGBA_sha256']==decl['decoded_RGBA_sha256']=='ba3713f65664983e9825187d722fe7d679fc604c2a5a07c6a403e597b4b366c1'
assert row['full_RGBA_exact'] and row['params23'] and row['mipmaps']==0 and row['detect_3d_compress_to']==0
assert row['png']==decl['png'] and row['sidecar']==decl['sidecar'] and row['compiled']==decl['compiled']
assert row['png_sha256']==decl['png_sha256']=='9d6edceee42e4d075f920fc1d1cffb388cb8ffc66b5c223084e671a70aff852c'
assert sha(iso(row['png']))==row['png_sha256']
assert sha(iso(row['sidecar']))==row['sidecar_sha256']=='b72003ea99c91ebe744bee65218c5d37f72ff87a3a28668cc7f576bcd430b7f2'
assert sha(iso(row['compiled']))==row['compiled_sha256']=='f583203a326a4750428a0a6689c7d35dadd749408eb051c8bb1d6200cb9293a8'
ini=configparser.ConfigParser(interpolation=None);ini.optionxform=str;ini.read(iso(row['sidecar']),encoding='utf-8')
actual_params={k:json.loads(v) for k,v in ini.items('params')}
assert len(actual_params)==23 and actual_params==p['exact_23_import_params']
assert ini.get('remap','importer')=='"texture"' and ini.get('deps','source_file')=='"'+row['png']+'"'
assert row['compiled'] in ini.get('remap','path') and row['compiled'] in ini.get('deps','dest_files')
assert p['promoted'] is False and r['production_promotions']==0
assert r['engine_import_calls_by_verifier']==r['geometry_Field_CPU_renderer_calls']==0
targets=[{'path':q,'currently_absent':not Path(q).exists()} for q in p['main_two_absent_targets']]
assert len(targets)==2 and all(x['currently_absent'] for x in targets)
out={'status':'INDEPENDENT_ISOLATED_A2_SINGLE_WALK_IMPORT_RECEIPT_ONLY_NOT_PROMOTED',
 'actual_result':{'path':'res://'+P.relative_to(GAME).as_posix(),'sha256':sha(P),'passed':True,'checks':94,'elapsed_ms':131},
 'Root_reported_natural_console_exit':0,'exit_credit_source':'Root actual78528 retained-process report in task; not inferred from passed flag.',
 'prepared':{'path':'res://'+PREP.relative_to(GAME).as_posix(),'sha256':sha(PREP)},
 'source_first_final_current_SHA_bytes_seconds_exact':20,
 'protected_main_original_SHA_bytes_mtime_ns_exact':14,'original_eight_old_facts_included_and_exact':8,
 'single_full_RGBA_params_verifier_row':row,'sidecar_params23_independently_parsed_exact':True,
 'PNG_RGBA_credit_boundary':'Actual frozen isolated verifier raw/imported/directctex fullRGBA proof only; QA hashes files and parses sidecar text, does not decode any image/ctex.',
 'two_main_targets_still_absent':targets,
 'next':'Root authorization plus exact two-leaf promotion only. Do not reimport PNG, revisit875/ABI/native/GPU, or claim runtime/wholeART/load credit.',
 'logs_boundary':'No claim of clean logs: only receipt/source audit here; Root captured log assessment separate.',
 'engine_runs_this_review':0,'import_calls':0,'PNG_ctex_decode':0,'ABI_runs':0,'geometry_replay':0,'collector_calls':0,'promotion_or_canonical_writes':0}
OUT.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review':str(OUT),'sha256':sha(OUT),'sourcefacts':20,'protected_main':14,'oldfacts':8,'main_promoted':False,'engine':0}))
