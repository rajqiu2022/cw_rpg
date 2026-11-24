"""Exact 4201 minus two terminal LF ->9CBB, currentE370 24-write scope. No canonical writes."""
from pathlib import Path
import json,hashlib,difflib
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'Field_EOF_adoption01/';O=N/'Field_EOF_adoption01';F='res://scripts/field/field_walkable_controller.gd'
sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def load(p,h):
 b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
def emit(name,b):
 p=O/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=P+name,sha256=sha(b),bytes=len(b))
dep_pin=dict(path=S+'artisan_return_guard_repair01/Artisan_effective_return22_deployed_ROOT_ACTUAL.json',sha256='e370f06d790cbe1723cf7284998bc2d170fa68f4b757ff5ed929681b4f2e1aa8');dep=load(dep_pin['path'],dep_pin['sha256'])
headpin=dict(path=S+'artisan_return_guard_repair01/unified22_READY01/artisan_return22_all_candidates_and_inverse_NOT_STAGE.json',sha256='f057a8957154f052256d361e1e5bdfd021541b34d812780463c68061b7c0885f');head=load(headpin['path'],headpin['sha256'])
strictpin=dict(path=S+'seven_fields_layout_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='c7ac1d0d213c7db851f93157010aeb3672633b57a87e2335bc5e101e2e69102a');strict=load(strictpin['path'],strictpin['sha256'])
base=load(S+'artisan_return_guard_repair01/current_2B86_backup22_ROOT_PLAN.json','cd613316c4962afdd8df49b0302925c0fbd44b4d75d8567a322784e08ffc2057');back=load(S+'artisan_return_guard_repair01/current_2B86_backup22_ROOT_ACTUAL.json','2a6c3794c3d175a0c2a98a4ce650abf340408a2782f86a131256ea620cd6fbea')
refs={r['target']:r['candidate']for r in strict['targets']};refs.update({r['target']:r['candidate']for r in head['targets']})
locked=refs[F];old=(GAME/locked['path'][6:]).read_bytes();assert sha(old)==locked['sha256']=='4201a29c4791e099300ec5841bca0e9a7a1571bb71e6ccd74bf8cd8d9598e3aa' and old.endswith(b'\n\n\n')and not old.endswith(b'\n\n\n\n')
new=old[:-2];assert sha(new)=='9cbb187a586eade1326090b2ef81bd69bd352e621d3acfc5ace1e72c4283ec4a'and len(new)==270267 and (GAME/F[6:]).read_bytes()==new
adoptpin=emit('Field_editor_saved_singleLF.gd',new)
aa=old.decode().splitlines(True);bb=new.decode().splitlines(True);hs=[]
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(12):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
assert len(hs)==1 and old.decode().count(hs[0]['old'])==new.decode().count(hs[0]['new'])==1 and old.decode().replace(hs[0]['old'],hs[0]['new']).encode()==new and new.decode().replace(hs[0]['new'],hs[0]['old']).encode()==old
adoption=dict(target=F,parent=locked,candidate=adoptpin,hunks=hs,only_removed_final_two_ASCII_LF=True,code_and_all_other_bytes_identical=True,canonical_already_at_candidate=True,canonical_writes=0)
adoptproof=emit('Field_exact_EOF_adoption_whole_inverse_NOT_STAGE.json',enc(adoption))
selected=set(head['metadata'])|set(head['index_proofs'])|{'res://data/maps/luoyang_full_city_20261022ap/execution_successor.json','res://data/luoyang_culture_integration_20261019x/runtime_contract.json','res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd'}
rows=[]
for p in refs:
 if p not in selected:continue
 c=refs[p];b=(GAME/c['path'][6:]).read_bytes();assert sha(b)==c['sha256']and len(b)==c['bytes'];rows.append(dict(target=p,immutable_old=c['path'],old_sha256=c['sha256'],old_bytes=c['bytes'],backup=P+'root_only_current24_backup/'+p[6:]))
assert len(rows)==24 and F not in selected and sum(r['target'].endswith('.gd')for r in rows)==10
scope=emit('current_E370_exact24_scope_PREPARATION.json',enc(dict(status='CURRENT_E370_EXACT24_WRITES_PLUS_ALREADY_SAVED_FIELD_ADOPTION',expected_count=24,count=24,partition=dict(GD=10,JSON=14),parent_stage=dep['stage'],parent_deployment=dep_pin,parent_descriptor=headpin,strict_parent_descriptor=strictpin,targets=rows,adopted_Field=adoption,adoption_proof=adoptproof,runtime_hash_algorithms_unchanged=True,canonical_writes=0,engine_calls=0)))
facts={r['path']:{k:v for k,v in r.items()if k!='path'}for r in back['frozen2121_current_facts']};written={r['target']:r for r in dep['targets']};absolute={str((GAME/p[6:]).resolve()).casefold():r for p,r in written.items()}
for p in facts:
 key=str((GAME/p[6:]if p.startswith('res://')else Path(p)).resolve()).casefold()
 if key in absolute:
  r=absolute[key];facts[p]=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks'])
 if key==str((GAME/F[6:]).resolve()).casefold():facts[p]=dict(exists=True,sha256=adoptpin['sha256'],bytes=adoptpin['bytes'],ticks=str((GAME/F[6:]).stat().st_mtime_ns//100+621355968000000000))
current=[]
for r in base['current37']:
 r=dict(r);r.pop('current',None)
 if r['target']in written:
  w=written[r['target']];r.update(sha256=w['sha256'],bytes=w['bytes'])
 if r['target']==F:r.update(sha256=adoptpin['sha256'],bytes=adoptpin['bytes'])
 current.append(r)
oldbacks=base['old626_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in back['new_backups']];assert len(oldbacks)==648
extras=[dict(target=F,immutable_old=adoptpin['path'],old_sha256=adoptpin['sha256'],old_bytes=adoptpin['bytes'],backup=P+'root_only_current24_backup/adopted_Field_current_9CBB.gd'),dict(target=locked['path'],immutable_old=locked['path'],old_sha256=locked['sha256'],old_bytes=locked['bytes'],backup=P+'root_only_current24_backup/locked_Field_original_4201.gd')]
plan=emit('current_E370_backup24plus2_ROOT_PLAN.json',enc(dict(status='ROOT_ONLY_CURRENT_E370_24_TARGETS_PLUS_TWO_FIELD_BACKUPS',scope=scope,parent_deployment=dep_pin,current24=rows,adoption_backup_sources=extras,current37=current,frozen2121_expected=facts,prior_save15=back['save15'],save_baseline_policy='CAPTURE_AT_ROOT_EXECUTION_PRESERVE_CURRENT_USER_SAVE_NOT_YESTERDAY',old648_backup_facts=oldbacks,media149=base['media149'],World54=base['World54'],ui=base['ui'],Root_only_backup_prefix=P+'root_only_current24_backup/',expected_old_backup_total=648,expected_after_backup_total=674,canonical_writes=0,engine_calls=0)))
parent=(N/'artisan_return_guard_repair01/backup_current_2B86_22_ROOT_ONLY.py').read_bytes();t=parent.decode()
for a,b in [('CreateNew22','CreateNew24 plus2 Field snapshots'),('artisan_return_guard_repair01/current_2B86_backup22_ROOT_PLAN.json','Field_EOF_adoption01/current_E370_backup24plus2_ROOT_PLAN.json'),('backup22','backup24'),('current22','current24'),('old626_backup_facts','old648_backup_facts'),('626+len(rows)','648+len(rows)'),('NEW22','NEW24'),('CURRENT_2B86_FULL22','CURRENT_E370_FULL24_PLUS2_FIELD'),('CURRENT_2B86_FRESH','CURRENT_E370_FRESH')]:assert a in t,a;t=t.replace(a,b)
a="saves={p:fact(p)for p in plan['save15_expected']};savechanges=[dict(path=p,old=plan['save15_expected'][p],current=f)for p,f in saves.items()if f!=plan['save15_expected'][p]]"
b="saves={p:fact(p)for p in plan['prior_save15']};savechanges=[];prior_save_differences=[dict(path=p,prior=plan['prior_save15'][p],current=f,disposition='PRESERVED_CURRENT_USER_SAVE_FRESH_BASELINE')for p,f in saves.items()if f!=plan['prior_save15'][p]]"
assert a in t;t=t.replace(a,b)
t=t.replace("for r in plan['current24']:","for r in plan['current24']+plan['adoption_backup_sources']:")
t=t.replace("new_backups=rows,total_backups=648+len(rows)","new_backups=rows[:24],adoption_backups=rows[24:],prior_save_differences=prior_save_differences,total_backups=648+len(rows)")
assert 'adoption_backups=rows[24:]'in t;compile(t,'backup_current_E370_24plus2_ROOT_ONLY.py','exec');tool=emit('backup_current_E370_24plus2_ROOT_ONLY.py',t.encode())
print(json.dumps(dict(scope=scope,plan=plan,tool=tool,adoption=adoptproof,Field_snapshot=adoptpin)))
