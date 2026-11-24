"""Declare Root-admitted complete portrait triple on exact Market only."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent;GAME=ROOT.parent.parent
OUT=ROOT/"visual_transition_successor03";OUT.mkdir(exist_ok=True)
def sha(b):return hashlib.sha256(b).hexdigest()
def rp(p):return "res://"+str(p.relative_to(GAME)).replace("\\","/")
authority=ROOT.parent/"luoyang_city_full_rollout_20261022ap_root01/examiner_portrait_three_leaf_authorization_READY.json"
actual=ROOT.parent/"luoyang_city_full_rollout_20261022ap_qa01/isolate_examiner_portrait_ready01/ap_full_examiner_portrait_import_result_36012.json"
auth=json.loads(authority.read_text(encoding="utf-8"));report=json.loads(actual.read_text(encoding="utf-8"))
assert auth['approved_by_root'] is True and report['passed'] is True and report['checks']==59
assert sha(actual.read_bytes())==auth['actual_isolated_import_result_sha256']
pins={t['path']:t['after_sha256'] for t in auth['targets']}
assert len(pins)==3
for p,h in pins.items():
 assert report['source_first'][p]==h and report['source_final'][p]==h
 assert sha((GAME/p.removeprefix('res://')).read_bytes())==h
parent=ROOT/"visual_transition_successor02_retry2/environment_visual_transition_READY.gd"
old=parent.read_bytes();assert sha(old)=="c50dad4d92a505ab27b735dbec3016e1c60e975e795e218f0c2e376dfa8207b2"
data=old;edits=[]
def patch(a,b):
 global data
 a,b=a.encode(),b.encode();assert data.count(a)==1
 data=data.replace(a,b,1);edits.append({'old':a.decode(),'new':b.decode()})
declaration='const EXAMINER_SOURCES='+json.dumps(pins,separators=(',',':'))+'\n'
patch('const IDS=[',declaration+'const IDS=[')
patch('\tif id==&"ch4_s3_luoyang_market":\n\t\tfor p: String in data.facade_source_sha256:','\tif id==&"ch4_s3_luoyang_market":\n\t\tfor p: String in EXAMINER_SOURCES: out[p]=true\n\t\tfor p: String in data.facade_source_sha256:')
patch('\tif scene.scene_id==&"ch4_s3_luoyang_market":\n\t\tfor p: String in data.facade_source_sha256:','\tif scene.scene_id==&"ch4_s3_luoyang_market":\n\t\tfor p: String in EXAMINER_SOURCES: source_pins[p]=EXAMINER_SOURCES[p]\n\t\tfor p: String in data.facade_source_sha256:')
inverse=data
for e in reversed(edits):
 assert inverse.count(e['new'].encode())==1
 inverse=inverse.replace(e['new'].encode(),e['old'].encode(),1)
assert inverse==old
p=OUT/"environment_visual_transition_READY.gd";assert not p.exists();p.write_bytes(data)
receipt={'status':'NEW_BUILD_ONLY_EXPLICIT_SOURCE_DECLARATION_NO_RUNTIME_CREDIT','candidate':{'path':rp(p),'sha256':sha(data),'bytes':len(data)},'parent':{'path':rp(parent),'sha256':sha(old)},'whole_byte_inverse':True,'edits':edits,'portrait_declared_sources':pins,'source_first_final_actual59':{'path':rp(actual),'sha256':sha(actual.read_bytes())},'root_three_leaf_authority':{'path':rp(authority),'sha256':sha(authority.read_bytes())},'media_current_exact':True,'scope':'Market-only source_paths_for and install first/final3leaf; no other scene portrait declarations; Field exact examiner override remains A148 unchanged','two_shader_declarations_inherited':{'rect_shader':'8dab8ea0515d4cc94ff89595c287d2513cb3a8d47dcd36edb1d7ed74a796ae53','artisan_union_shader':'411bceeec31d10025ff17e21e36b416054425e916e04ee39e91038b709acda83'},'no_canonical_or_engine_write':True}
r=OUT/'handoff_READY.json';assert not r.exists();r.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'helper':receipt['candidate'],'receipt':{'path':rp(r),'sha256':sha(r.read_bytes())}},indent=2))
