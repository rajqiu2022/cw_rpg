"""Only mechanical next head of Root-reviewed pawn exact25 Stage; no execution."""
from pathlib import Path
import json,hashlib,difflib,copy,importlib.util
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'pawnshop_collision_Gbinding_repair01/'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def raw(p):
    b=(GAME/p['path'][6:]).read_bytes();assert sha(b)==p['sha256'];return b
def load(p):return json.loads(raw(p))
def emit(path,b):
    p=GAME/path[6:];assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(b)
    return dict(path=path,sha256=sha(b),bytes=len(b))
bp=dict(path=P+'unified25_READY01/pawn_Gbinding25_all_candidates_and_inverse_NOT_STAGE.json',sha256='4e8f536f2517ff331f376bac871bd26a0d33cc87e29f5a7230a889d6b534ece4');b=load(bp)
parentpin=dict(path=S+'stage_pawn_collision_exact25_ROOT_ONLY.py',sha256='2d90170787ec56349257d61f9171f1534742115d9b665215150d547474911d38');parent=raw(parentpin);text=parent.decode()
changes=[
('Root-only current9C1245 exact25 pawn body successor. One exact-pawn Field hunk replaces local collider rows from the approved nine source bases. Other functions and native storage unchanged. No engine/canonical writes.','Root-only current6C01 exact25 pawn G receiver successor. Only two exact-pawn Field calls bind to existing ELEVEN_ROOMS public author_for_id/matches; original nine-base conversion and native storage unchanged. No engine/canonical writes.'),
('PawnCollision25','PawnGbinding25'),('ROOT_CURRENT9C1245_FULL25','ROOT_CURRENT6C01_FULL25'),("self.backup['total_backups']==539","self.backup['total_backups']==564"),('ROOT_ACTUAL9C1245_BACKUP25','ROOT_ACTUAL6C01_BACKUP25'),('pawnshop_collision_repair01/root_only_current25_backup/','pawnshop_collision_Gbinding_repair01/root_only_current25_backup/'),("len(prior['source_sha256'])==236 and len(self.authority['source_sha256'])==241","len(prior['source_sha256'])==241 and len(self.authority['source_sha256'])==246"),('OWNED10_236_PLUS5_EQUALS241','OWNED10_241_PLUS5_EQUALS246'),('ALL_OLD236_FIXED_FIVE_NEW','ALL_OLD241_FIXED_FIVE_NEW'),('PINNED_CURRENT9C1245_MAP_PARENT','PINNED_CURRENT6C01_MAP_PARENT'),('PAWN_LOCAL_COLLISION_EXACT25_STAGED_NOT_DEPLOYED','PAWN_G_RECEIVER_EXACT25_STAGED_NOT_DEPLOYED'),('50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0','2f0de4cd1346436e77992b9c76cf206c61d96354a7af27a27d7f0e8d8188032d'),('Pinned current9C1245/23C504 exact25 successor. All owned10 and old236 proof values/edges retained plus5=241 and exactly3 real Field/Coordinator/Temple successor edges. One exact-pawn Field local-blocker conversion hunk consumes approved G effective nine bases via the original collider constructor. Native Scene/layout/registry, G C96B/service4C83/author4405, C/ENV/Router/Family/finish runtime/BIND/exterior payloads/masks/media unchanged. CT26/Temple196 all prospective values checked; original22 partial deployment and its authorized backup differences preserved, not claimed as a completed pawn Field result.','Pinned current6C01/B804 exact25 successor. All owned10 and old241 proof values/edges retained plus5=246 and exactly3 Field/Coordinator/Temple successor edges. Only two exact-pawn Field calls change receiver to existing ELEVEN_ROOMS.author_for_id/matches; all nine-base conversion bytes and original collider constructor remain. Native Scene/layout/registry, G C96B/service4C83/author4405, C/ENV/Router/Family/finish runtime/BIND/exterior payloads/masks/media unchanged. CT26/Temple196 prospective checks retained. Original116020 compile FAIL and partial deployments preserved, not claimed as pawn Field completion.')]
for a,c in changes:assert a in text,a;text=text.replace(a,c)
a="classification['authorized_count']==22 and classification['other2099_no_difference_in_actual_report']is True and len(self.backup['differences'])==22,'ONLY_PREVIOUS_ROOT_DEPLOYED22_BACKUP_DIFFERENCES_PRESERVED'"
c="classification['authorized_count']==0 and classification['all2121_no_difference_in_actual_report']is True and self.backup['differences']==[],'CURRENT6C01_ZERO_EXTERNAL_DIFFERENCES_PRESERVED'"
assert text.count(a)==1;text=text.replace(a,c)
aa=parent.decode().splitlines(True);bb=text.splitlines(True);hs=[]
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==parent;compile(text,'stage_pawn_Gbinding_exact25_ROOT_ONLY.py','exec')
driver=emit(S+'stage_pawn_Gbinding_exact25_ROOT_ONLY.py',text.encode())
proof=emit(P+'Stage25_driver_whole_inverse_NOT_STAGE.json',enc(dict(parent=parentpin,candidate=driver,hunks=hs,whole_UTF8_inverse=True,original25_source_validation_functions_and_F120_unchanged=True,actual_current6C01_zero_difference_parent=True,Stage_calls=0,engine_calls=0,canonical_writes=0)))
pins=[dict(id='driver',**driver),dict(id='candidates',**bp),dict(id='scope',**b['scope']),dict(id='backup',**b['root_backup']),dict(id='execution',**b['execution']['candidate']),dict(id='authority_helper',**b['authority_helper']),dict(id='publication',**b['publication']),dict(id='parent_stage',**b['parent_stage']),dict(id='backup_classification',**b['backup_authorized22_classification']),dict(id='function_proof',**b['function_proof']),dict(id='code',**b['code_proof'])]
gates=[]
for i,g in enumerate(b['old_required_gates']):
    k='gate_'+str(i);pins.append(dict(id=k,**g['pin']));gates.append(dict(id=g['id'],input=k,pointer=g['pointer'],equals=g['equals']))
gates.append(dict(id='root_target_preauthorization',input='backup',pointer=['passed'],equals=True))
spec=dict(schema_version=1,status='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT',blockers=[],output_root=S+'outputs/root_pawn_G_receiver_exact25_stage01/',pinned_inputs=pins,authority_input='execution',authority_helper_input='authority_helper',prospective_targets=[dict(target=r['target'],candidate_path=r['candidate']['path'],sha256=r['candidate']['sha256'],bytes=r['candidate']['bytes'])for r in b['targets']],declared_candidates={r['target']:r['candidate']for r in b['targets']},five_owned_targets=b['execution']['changed_existing_owned'],required_gates=gates,source_groups=[],nodes=[])
t=(N/'prepare_pawn_collision25_stage_NOTENGINE.py').read_text(encoding='utf-8');tail=t[t.index('# Run only reviewed data/format expressions'):]
tail=tail.replace('source_input_pawn_collision25_ROOT_REVIEW.json','source_input_pawn_Gbinding25_ROOT_REVIEW.json').replace('PAWN_LOCAL_BODIES_EXACT25_DATA_PREFLIGHT_NOT_STAGE','PAWN_TWO_G_RECEIVERS_EXACT25_DATA_PREFLIGHT_NOT_STAGE')
exec(compile(tail,'unchanged_reviewed_exact25_data_preflight_not_Stage','exec'),globals())
