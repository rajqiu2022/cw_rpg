"""NEW empty noautoload project and false candidate only. No engine/import/pixel read."""
from pathlib import Path
import hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
D=QA/'proof_source_tuple_ROOT39_CANDIDATE_NOTREADY'
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def emit(name,b):
    p=D/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(b)
    return{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size}
facts_path=ROOT/'integration39/proof_autoimport_tuple_before_retry1.json';before=ROOT/'integration39/guard_before.json'
assert sha(facts_path)=='19d3a71b39266c1baf97beb960f3e9987e1ea0e0e60c94ac2193961b6718d296'
assert sha(before)=='2831090632f6a78926171f238bc377ca45295abe2ce76cf619f2e84c85df499d'
facts=rd(facts_path);assert len(facts['facts'])==3 and facts['new_source_leaf_count']==2
assert facts['before_guard_sha256']==sha(before)and facts['raw_png_already_independently_declared']and facts['not_runtime_texture_promotion']and not facts['old_import_credit_borrowed']
media={Path(x['path']).as_posix():x['sha256']for x in facts['facts']}
for row in facts['facts']:
    p=Path(row['path']);assert sha(p)==row['sha256']and p.stat().st_size==row['bytes']
publication=GAME/'build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision4/publication/53624/result.json'
assert sha(publication)=='09301b55d1ea22c94d1dd35096597c87cfe691dba6e04e26b35e3db7c612b575'
proof=rd(publication)['walk_candidate']
assert proof['sha256']=='a186905d33e0dd148613c64a7f85bfb4a3cd734d040f9b937854ce605cadc4ed'
assert proof['rgba_sha256']=='6e72541153449e571516c340838794ff44fdf96dfc8b601b93733b3d4ff4c6da'
raw=(GAME/proof['path'][6:]).as_posix();ctex=(GAME/'.godot/imported/walk.png-eb63fda1eba65c60ad6a24b15599ec76.ctex').as_posix()
assert set(media)=={raw,raw+'.import',ctex}
project=emit('project.godot',b'config_version=5\n\n[application]\nconfig/name="AP Proof Tuple SOURCE_ONLY ReadOnly"\n\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
template=QA/'source_only_proof_tuple_TEMPLATE_NOTREADY.gd'
guard=dict(media);guard['res://project.godot']=project['sha256']
for p in [facts_path,before,publication]:guard[p.as_posix()]=sha(p)
fixture={'status':'ROOT39_SOURCE_ONLY_TUPLE_CANDIDATE_NOTREADY_NOT_RUN','ready':False,'blockers':['Root must read full key/project/fixture, authorize exactly one run and mechanically freeze successor; no run or import permitted by this candidate.'],'limit_ms':15000,'absolute_png':raw,'absolute_ctex':ctex,'source_sha256':guard,'expected_size':[3072,2048],'canonical_RGBA_bytes':25165824,'canonical_RGBA_sha256':proof['rgba_sha256'],'root_fresh_guard':{'path':str(before),'sha256':sha(before)},'new_tuple_facts':{'path':str(facts_path),'sha256':sha(facts_path)},'fixed_prior_RGBA_declaration':{'path':str(publication),'sha256':sha(publication),'pointer':['walk_candidate']},'contract':{'SOURCE_ONLY_existing_proof_asset':True,'not_runtime_texture_promotion':True,'no_borrowed_old_import_credit':True,'media_existing_files_exactly3':facts['facts'],'exact23params':{'process/fix_alpha_border':True,'detect_3d/compress_to':1,'compress/mode':0,'mipmaps/generate':False,'other19':'All exact predeclared PARAMS in key; sidecar entireSHA fixed in three facts.'},'representation':'Record both native formats/compression/mips; first require original3072x2048/mip0, decompress in-memory if needed then standardconvert RGBA8. No nativeformat equality invented. Both full25,165,824B data must equal and eachSHA==53624declared6E725.','no_new_import_or_source_write':True,'no_resize_crop_filter_PNGsave':True,'no_autoload_Field_Scene_geometry_collector':True,'headless_empty_project_existing_absolute3reads':True,'main15save_readonly_beforeafter':True,'mtime_precision':'Godotmtime is seconds; Root39 externalbefore/after ticks remain separate.'}}
fp=emit('source_only_tuple_fixture_CANDIDATE_NOTREADY.json',(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode())
body=template.read_bytes();new=body
for a,b in [('PENDING_FIXTURE_PATH','res://source_only_tuple_fixture_CANDIDATE_NOTREADY.json'),('PENDING_FIXTURE_SHA',fp['sha256'])]:
    assert new.count(a.encode())==1;new=new.replace(a.encode(),b.encode(),1)
assert b'const READY=false'in new
kp=emit('test_source_only_tuple_CANDIDATE_NOTREADY.gd',new)
handoff=emit('handoff_CANDIDATE_NOTREADY_NOT_RUN.json',(json.dumps({'status':'ROOT39_EMPTY_PROJECT_SOURCE_ONLY_TUPLE_CANDIDATE_READY_FALSE','project':project,'key':kp,'fixture':fp,'template_sha256':sha(template),'read_paths_absolute':list(media),'independent_fixed_RGBA':proof['rgba_sha256'],'23params_current_proofonly_detect1_fixalpha_true':True,'nativeformats_recorded_not_assumed_equal':True,'no_Godot_or_pixeldecode_executed':True,'new_runtime_or_ART_credit':False,'newsourceonlyleaf_admission_still_pending_actual':True,'Root_only_future_command_not_authorized':'Godot --headless --path <this NEW project> --script res://<futureREADYkey>; no --editor or --import','15s_wholebudget':True,'screenshots':0,'collector':0,'import':0,'canonical_write':0},ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'project':project,'key':kp,'fixture':fp,'handoff':handoff}))
