"""Only the exact scholar portrait line atop System's frozen functional Field."""
from pathlib import Path
import hashlib,json
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_revision_20261024c_source01/';Y='res://build/luoyang_yamen_courts_20261024c_system01/runtime02/'
def sha(b):return hashlib.sha256(b).hexdigest()
def checked(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h and b'tokens truncated' not in b;return b
def out(name,b):
    with (HERE/name).open('xb') as f:f.write(b)
    assert (HERE/name).read_bytes()==b
    return dict(path=S+name,sha256=sha(b),bytes=len(b))
pp=Y+'whole_byte_inverse_NOTREADY.json';ph='7421707e7a78ea98bafc3da6ba74931461be6a18be3f978651f9bb65e8cb77c3';proof=json.loads(checked(pp,ph));field=proof['candidates']['Field']
before=checked(field['candidate_path'],field['candidate_sha256']);assert field['candidate_sha256']=='3f7e60be3ffe2452e759b5b59634d371f80f05bbb0ea8aa0b70bd5bc89a1535b'
old='\t\t\tnpc.sprite_path = "res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png"\n'
new=old+'\t\t\tnpc.portrait_path = "res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png"\n'
assert before.count(old.encode())==1;after=before.replace(old.encode(),new.encode(),1)
assert after.count(new.encode())==1 and after.replace(new.encode(),old.encode(),1)==before
inverse=before.decode()
for h in reversed(field['replacements']):
    assert inverse.count(h['new'])==1;inverse=inverse.replace(h['new'],h['old'],1)
parent=checked('res://build/luoyang_city_space_20261024b_source01/worker_facts03/Field_CANDIDATE.gd',field['parent_sha256']);assert inverse.encode()==parent
receiptpath='res://build/luoyang_city_revision_20261024c_root01/scholar_portrait_three_actual.json';receipthash='6d520a7f4779895f5a87e12b24bf37fd7ca9e8d50baa0ab50d2c0efa998664c8';r=json.loads(checked(receiptpath,receipthash));assert r['passed'] and len(r['written'])==3 and not r['main_project_import'] and r['pixel_edits']==0
leaves={'res://'+Path(row['path']).resolve().relative_to(GAME).as_posix():row['sha256'] for row in r['written']}
assert leaves['res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png']=='ebd60b64edbcc061401a0fc1219d1f120a4f5d4e98db1ab1d129c81f845c2a74'
candidate=out('Field_courts_scholar_CANDIDATE.gd',after)
record=dict(status='EXACT_MARKET_SCHOLAR_PORTRAIT_OVER_SYSTEM_COURTS_FIELD_BUILD_ONLY',ready=False,target='res://scripts/field/field_walkable_controller.gd',parent=dict(path='res://build/luoyang_city_space_20261024b_source01/worker_facts03/Field_CANDIDATE.gd',sha256=field['parent_sha256']),System_functional_parent=dict(path=field['candidate_path'],sha256=field['candidate_sha256']),System_proof=dict(path=pp,sha256=ph),candidate=candidate,portrait_replacements=[dict(old=old,new=new)],combined_replacements=field['replacements']+[dict(old=old,new=new)],whole_byte_inverse_to_System=True,whole_byte_inverse_to_formal=True,media_actual=dict(path=receiptpath,sha256=receipthash),new_source_group=dict(id='Market_exact_scholar_portrait_24c',kind='explicit',leaves=leaves),source_domain='Market only; exact ID after its existing world-sprite override. Three ordinary sources, not runtime_authority. No existing portrait-family mapping or DP/UI change.',preserved=['All tasks/dialogues/choices/flags/rewards','Hero portrait and opening/rumor behavior','Sprite .82 scale, adult calibration, groundfoot/body','Original source guards and System Yamen lease hooks'],unresolved=['System mask/publisher/runtime binding actuals','Root source scope/backup/Stage and deployment approval','Real Field exact speaker/portrait display'],engine_calls=0,Stage_calls=0,canonical_writes=0)
b=(json.dumps(record,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();pr=out('Field_courts_scholar_wholebyte_inverse_NOTREADY.json',b)
print(json.dumps(dict(candidate=candidate,proof=pr,new_ordinary_Market_sources=3)))
