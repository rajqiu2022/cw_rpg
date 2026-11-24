"""Static only; exact new SOURCE_ONLY contract, no native image access."""
from pathlib import Path
import hashlib,json,re
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
D=QA/'proof_source_tuple_ROOT39_CANDIDATE_NOTREADY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
kp=D/'test_source_only_tuple_CANDIDATE_NOTREADY.gd';fp=D/'source_only_tuple_fixture_CANDIDATE_NOTREADY.json';pp=D/'project.godot'
assert sha(kp)=='cb6664d4a3df446a82ff47cbac23c31dddc85bf20a55b1e10eee112e38cadf39'
assert sha(fp)=='fbeac0b7323d459e85d6518fc6fc159ed0bfe712a756257784214d4f4bdab495'
assert sha(pp)=='a101a978a02e9b2164cd7b38f6836cbfc86b236ee76397e44ee707e6532fd19b'
key=kp.read_text(encoding='utf-8');f=rd(fp)
assert 'const READY=false'in key and f['ready']is False and f['limit_ms']==15000
assert '[autoload]'not in pp.read_text(encoding='utf-8')and not list(D.glob('*.png'))
facts=rd(Path(f['new_tuple_facts']['path']));assert len(facts['facts'])==3
assert f['new_tuple_facts']['sha256']=='19d3a71b39266c1baf97beb960f3e9987e1ea0e0e60c94ac2193961b6718d296'
raw=f['absolute_png'];ctex=f['absolute_ctex'];side=raw+'.import'
assert {Path(x['path']).as_posix()for x in facts['facts']}=={raw,side,ctex}
expected={'a186905d33e0dd148613c64a7f85bfb4a3cd734d040f9b937854ce605cadc4ed':30729,'0640e6c6584447940c6e961486a92809a0e9aaa4fd12b85f5ee55a7c636b14e6':1005,'93c55bdd37077b51b3eb835c57950d6f62ca81bad45ee3f3c4cbac3cea1505bb':888}
for row in facts['facts']:
    p=Path(row['path']);assert expected[row['sha256']]==row['bytes']==p.stat().st_size and sha(p)==row['sha256']
    assert f['source_sha256'][p.as_posix()]==row['sha256']
params_block=key.split('const PARAMS: Dictionary=',1)[1].split('\n}',1)[0]+'\n}'
params=json.loads(params_block);assert len(params)==23
text=Path(side).read_text(encoding='utf-8');sideparams={}
for line in text.split('[params]',1)[1].splitlines():
    if line.strip():a,b=line.split('=',1);sideparams[a]=json.loads(b)
assert params==sideparams and params['process/fix_alpha_border']is True and params['detect_3d/compress_to']==1 and params['mipmaps/generate']is False
assert 'raw.load(raw_path)'in key and key.count('ResourceLoader.load(')==1 and 'ResourceLoader.load(compiled_path,"",ResourceLoader.CACHE_MODE_IGNORE)'in key
assert key.index('image.get_size()==Vector2i(3072,2048) and not image.has_mipmaps()')<key.index('image.decompress()')<key.index('image.convert(Image.FORMAT_RGBA8)')<key.index('raw_bytes==imported_bytes')
assert key.count('sha(raw_bytes)')==1 and key.count('sha(imported_bytes)')==1 and '25165824'in key
assert 'raw.get_format()==imported.get_format()'not in key
for denied in ['save_png(','.resize(','.crop(','get_pixel(','.get_pixelv(','--import','SceneScript','source_paths(','resident_receipt(','load(SOURCE']:
    assert denied not in key
assert 'players_before==players_after' in key and 'after[path]==before[path]'in key and 'root.get_child_count()==0' in key and 'current_scene==null'in key
out=D/'independent_false_candidate_static_review_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'ROOT39_FALSE_SOURCE_ONLY_TUPLE_STATIC_NO_BLOCKER_NOT_RUN_NOT_RUNTIME_TEXTURE_ADMISSION','project_sha256':sha(pp),'key_sha256':sha(kp),'fixture_sha256':sha(fp),'checks':{'empty_project_noautoload':True,'READYfalse_and_blockers_preserved':True,'absolute3_existing_media_files_only':True,'fresh19D3_threeSHAbytes_exact':True,'53624_RGBA6E725_not_observed_expectation':True,'exact23_currentparams_detect1_fixalpha_true_no_old0_credit':True,'nativeformat_recorded_not_invented_equal':True,'size_mip_before_optional_decompress_then_convertRGBA8':True,'both25MiB_fullbytes_equal_and_independentSHA':True,'one_directPNG_CPUdecode_one_directctex_load_noPNGtexture_import_entry':True,'15s_whole_noPNG_or_sampling_or_resize':True,'FIRST_FINAL_threefiles_and15save_guard':True},'limits':['Requires Root newfreeze/explicitsingleexecution; candidatefalse cannot pixelverify.','Source-only newautoimporttuple, not historicaltuple proof or promotion/runtimeART.','No claim these media already pixelpassed; no loader/runtime/collector run performed.'],'operations':{'engine':0,'parse':0,'pixel_or_native_decode':0,'collector':0,'import':0,'Stage':0,'canonical_write':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'key_lines':len(key.splitlines())}))
