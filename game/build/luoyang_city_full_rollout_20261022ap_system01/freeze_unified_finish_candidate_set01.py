"""Fixed NEW handoff, source-only targets and exact byte-splice inverses."""
from pathlib import Path
import hashlib,json,difflib,base64
ROOT=Path(__file__).resolve().parent;GAME=ROOT.parent.parent
def sha(b):return hashlib.sha256(b).hexdigest()
def rp(p):return "res://"+str(p.relative_to(GAME)).replace("\\","/")
def row(path):
 b=path.read_bytes();return {"path":rp(path),"sha256":sha(b),"bytes":len(b)}
specs=[
 ('scripts/autoload/scene_router.gd','c3452fd4735cfed1d1bc2b12dbf689b09a46ca093f430ba3ee940241ff443de6','exact_market_artisan_resident_candidate03/Router_exact_market_artisan_resident_READY.gd','9d80b90198fa4b0a3a78c1f81e44e46d06a8e97503819cb2b39895398aecd1e3'),
 ('scripts/city/luoyang_resident_field_20261016.gd','f1730e461fe6328763cfd70c79b2bbc36c80a2afb7609c364fa7ea7af8acdd7f','exact_market_artisan_resident_candidate01_retry1/Resident_exact_market_artisan_READY.gd','faf38e53113431c77a85c3a4068437007c07aa85ef44fb37665704a66aa1e9b4'),
 ('scripts/field/field_walkable_controller.gd','24b5159b01470b571955f68a2762b9e979fc45703168e86cb8da157defea1179','Field_hero_exact_examiner_portrait_candidate_READY.gd','a148154e8db886f508755ab91e7852c6ebe1e168a44d17badad9f3cc267499df'),
 ('scripts/ui/field_primary_hud.gd','9232f5a427461b127178e16eef1851e7d3960592e0dccd852f79bd714000a8ab','visual_finish_candidates01_retry1/field_primary_hud_readability_READY.gd','b673121841860c0d7ca501eed9a9c792fe2364f8714f04955b8036f8cdf5487c'),
 ('scripts/city/luoyang_environment_layer_20261022ap.gd','9038c896e742d53b0ff4042c0977c8a5cd0713376b52bf29ed3543001154de59','visual_transition_successor03/environment_visual_transition_READY.gd','455aa5b2d2b170491f67294ea11cae8ec6c6e23806eb83563cbc49e6fe7f7983'),
 ('data/maps/luoyang_full_city_20261022ap/environment.json','5a9994d84b4a2adf6d8e02048fce236bd433d6b163b1aaec5cdb8ea992cbc98f','environment_compatible_stone_candidate01/environment_compatible_stone_READY.json','64a7efc81a2d37c588c4d63b302324ff9b2eb90cea932de543e85177e8a4afd2'),
]
targets=[]
for canonical,parent_sha,candidate,expected in specs:
 p=GAME/canonical;c=ROOT/candidate;a=p.read_bytes();b=c.read_bytes()
 assert sha(a)==parent_sha and sha(b)==expected
 # Byte offsets are over originals; reverse uses output offsets, exact bytes,
 # so repeated lines/EOLs cannot redirect a splice to a different occurrence.
 aa=a.splitlines(keepends=True);bb=b.splitlines(keepends=True)
 ax=[0];bx=[0]
 for v in aa:ax.append(ax[-1]+len(v))
 for v in bb:bx.append(bx[-1]+len(v))
 hunks=[]
 for tag,i,j,k,l in difflib.SequenceMatcher(a=aa,b=bb,autojunk=False).get_opcodes():
  if tag=='equal':continue
  hunks.append({'old_offset':ax[i],'new_offset':bx[k],'old_b64':base64.b64encode(a[ax[i]:ax[j]]).decode(),'new_b64':base64.b64encode(b[bx[k]:bx[l]]).decode()})
 forward=a
 for h in reversed(hunks):
  old,new=base64.b64decode(h['old_b64']),base64.b64decode(h['new_b64']);o=h['old_offset']
  assert forward[o:o+len(old)]==old;forward=forward[:o]+new+forward[o+len(old):]
 reverse=b
 for h in reversed(hunks):
  old,new=base64.b64decode(h['old_b64']),base64.b64decode(h['new_b64']);o=h['new_offset']
  assert reverse[o:o+len(new)]==new;reverse=reverse[:o]+old+reverse[o+len(new):]
 assert forward==b and reverse==a
 targets.append({'canonical':rp(p),'parent_sha256':parent_sha,'parent_bytes':len(a),'candidate':row(c),'whole_byte_inverse':True,'offset_byte_hunks':hunks})

shader_paths=[ROOT/'visual_transition_successor02_retry2/environment_rect_color_once_READY.gdshader',ROOT/'visual_transition_successor02_retry2/artisan_ground_union_exterior_READY.gdshader']
new_consumed=[row(p) for p in shader_paths]
authority=ROOT.parent/'luoyang_city_full_rollout_20261022ap_root01/examiner_portrait_three_leaf_authorization_READY.json'
portrait=json.loads(authority.read_text(encoding='utf-8'))
portrait_sources={t['path']:t['after_sha256'] for t in portrait['targets']}
for p,h in portrait_sources.items():assert sha((GAME/p.removeprefix('res://')).read_bytes())==h
proof_names=['exact_market_artisan_resident_candidate01_retry1/handoff_READY.json','exact_market_artisan_resident_candidate02/handoff_READY.json','exact_market_artisan_resident_candidate03/handoff_READY.json','visual_finish_candidates01_retry1/handoff_READY.json','Field_hero_exact_examiner_portrait_candidate_receipt_READY.json','environment_compatible_stone_candidate01/handoff_READY.json','visual_transition_successor02_retry2/handoff_READY.json','visual_transition_successor03/handoff_READY.json']
data={'status':'SYSTEM_FIXED_UNIFIED_NEW_CANDIDATES_NOT_DEPLOYED_NOT_SOURCE_CLOSED','canonical_target_count':len(targets),'targets':targets,'new_consumed_shader_leaves':new_consumed,'already_promoted_portrait_market_only':portrait_sources,'portrait_authority':row(authority),'docks_necessary_declared22_proof':{'path':'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/docks22_frozen_registry_lineage_retry1_READY.json','sha256':'2e2134ac6ae883e67636adbc751fedbcd3d1e8150d2b1c123ac889537c9147c1'},'execution_authority':'Root must create sole narrow 80A approval37 -> final owned-source successor; System did NOT issue approval or rederive 9C/old graph. Source finalizer may now prepare exact DAG only from fixed candidates/legitimate source declarations, no collector replay.','source_interfaces':{'ENV_all8':'source_paths_for(exact supported id) declares rect shader 8DAB; install pins first/final','ENV_Artisan_only':'also declares union shader411B; install pins first/final; original62native tiles/9sections/32union exterior segments','ENV_Market_only':'EXAMINER_SOURCES distinct three admitted PNG/import/ctex; source_paths_for and install pins; not sign/facade or8-scene media','Field_portrait_exact':'Market + spar_luoyang_examiner only points to same4FBA media after catalog defaults; same default portrait to spar preface/UI aspect-contain','Router_existing_worker':'complete retained Market receipt.sources hashes through original parallel pure-file SHA worker; 1 fresh additional pass before attach; old identity/C metadata/foot/resume/rollback preserved','resident_only_pair':'Market->Artisan and true authored reverse; no public return hit/no other new city support; original512MiB estimate gate'},'proof_chain':[row(ROOT/n) for n in proof_names],'known_actual_inherited_only':{'HUD_Field_parse':'Root36912 OS0/51checks0/1782ms, candidate A148/B673 only; no UI actual','portrait_import':'Root36012 OS0/59checks0, original complete1254 UI-only; three media promoted; no portrait UI actual','A_C_B_function':'do not replay original complete functional checks','E51956':'functional source/input through true pair passed; return11.203165s failed fixed10s; new resident actual performance remains','D108252':'pure1665 key domain actual/fixed equal,22 declarations omitted from Docks manifest expected; legitimate proof separately supplied'},'must_not_claim':['shader compilation or art pass','resident parse/performance or hit before actual','full city final acceptance','whole afterguardPASS when externaltasks changed'],'no_canonical_native_image_engine_or_save_writes':True}
p=ROOT/'unified_runtime_visual_finish_candidates_READY.json';assert not p.exists();p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'handoff':row(p),'targets':[{k:r[k] for k in ['canonical','candidate']} for r in targets],'shaders':new_consumed},indent=2))
