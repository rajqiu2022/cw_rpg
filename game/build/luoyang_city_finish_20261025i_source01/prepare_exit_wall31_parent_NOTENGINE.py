"""Current81C source-parent31 only. Content and final heads pending; no backup, Stage or engine."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'exit_wall_repair_20261027b01/'
sha=lambda b:hashlib.sha256(b).hexdigest()
def load(p,h):
 b=(GAME/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));return json.loads(b)
def pin(p,h):return dict(path=p,sha256=h)
parent=pin(S+'Field_EOF_adoption01/Field_EOF24_deployed_ROOT_ACTUAL.json','81c09142acfcf12c6e6db88c5b8b11ccfa0eb94b533602bc853d046d459a28e0');dep=load(**dict(p=parent['path'],h=parent['sha256']))
oldpin=pin(S+'seven_fields_layout_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','c7ac1d0d213c7db851f93157010aeb3672633b57a87e2335bc5e101e2e69102a');old=load(**dict(p=oldpin['path'],h=oldpin['sha256']))
gpin=pin(S+'artisan_return_guard_repair01/unified22_READY01/artisan_return22_all_candidates_and_inverse_NOT_STAGE.json','f057a8957154f052256d361e1e5bdfd021541b34d812780463c68061b7c0885f');g=load(**dict(p=gpin['path'],h=gpin['sha256']))
eofpin=pin(S+'Field_EOF_adoption01/unified24_READY01/Field_EOF24_all_candidates_and_inverse_NOT_STAGE.json','7a3f1a441af63c425aad230945fb9ec07dbbe2aa2a3607d3bcfc843111ece993');eof=load(**dict(p=eofpin['path'],h=eofpin['sha256']))
refs={r['target']:r['candidate']for r in old['targets']}
refs.update({r['target']:r['candidate']for r in g['targets']});refs.update({r['target']:r['candidate']for r in eof['targets']});refs[eof['adopted_Field']['target']]=eof['adopted_Field']['candidate']
rows=[]
for r in old['targets']:
 p=r['target'];c=refs[p];b=(GAME/c['path'][6:]).read_bytes();assert sha(b)==c['sha256']and len(b)==c['bytes']and (GAME/p[6:]).read_bytes()==b,p
 rows.append(dict(target=p,immutable_old=c['path'],old_sha256=c['sha256'],old_bytes=c['bytes'],backup=P+'root_only_current31_backup/'+p[6:]))
assert len(rows)==31 and sum(r['target'].endswith('.gd')for r in rows)==17
value=dict(status='CURRENT_81C_EXIT_LABEL_AND_MARKET_WALL_SCOPE_CONTENT_PENDING_NOT_SEALED',count=31,partition=dict(GD=17,JSON=14),parent_stage=dep['stage'],parent_deployment=parent,parent_descriptor=eofpin,strict_full31_descriptor=oldpin,intermediate_G_descriptor=gpin,targets=rows,content_pending=['Yamen_Artisan_effective_portal_rows_and_runtime_pair_literals','Market_four_adult_short_walls_geometry_local_mask'],all_candidates_must_have_single_final_LF_before_hash=True,Field_9CBB_algorithms_unchanged=True,pawn_G_and_Router_unchanged=True,no_Stage_or_backup_or_engine_calls=True)
raw=(json.dumps(value,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8');out=GAME/(P[6:]+'current_81C_exact31_scope_PREPARATION.json');assert not out.exists();out.parent.mkdir(parents=True,exist_ok=True)
with out.open('xb')as f:f.write(raw)
print(json.dumps(dict(path=P+out.name,sha256=sha(raw),bytes=len(raw),targets=len(rows))))
