"""Same mature CreateNew27; currentB78D facts, no Source backup execution."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';P=S/'region_phase_lifetime_repair03';O=S/'region_visual_finish_repair04';sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode();res=lambda p:'res://'+p.relative_to(G).as_posix()
def pin(p):b=p.read_bytes();return dict(path=res(p),sha256=sha(b),bytes=len(b))
def fixed(p,h):b=p.read_bytes();assert sha(b)==h;return json.loads(b)
scope_path=N/'visual_finish04_BUILD/closure27/current_B78D_exact27_scope_PREPARATION.json';scope=fixed(scope_path,'49b335e90f028a0ccde6e945b04505cd1594c9a0e1c79e136c3e05bf3c677a9e')
dep_path=P/'region_phase27_deployed_ROOT_ACTUAL.json';dep=fixed(dep_path,'b78d8866036117ddbe0f09719a0cc8d15596a2eb7e467b238a13107b0d1e021b');back=fixed(P/'current_5FCE_backup27_ROOT_ACTUAL.json','765e286c655194e33c06908bc98dcb1efed6c69d299684fff5545aff8a972dea')
assert not O.exists();O.mkdir();prefix=res(O)+'/root_only_current27_backup/'
rows=[{**r,'backup':prefix+r['target'][6:]}for r in scope['targets']];assert len(rows)==27
written={r['target']:r for r in dep['targets']};absolute={str((G/p[6:]).resolve()).casefold():r for p,r in written.items()};facts={r['path']:{k:v for k,v in r.items()if k!='path'}for r in back['frozen2121_current_facts']}
for p in facts:
 key=str((G/p[6:]if p.startswith('res://')else Path(p)).resolve()).casefold()
 if key in absolute:r=absolute[key];facts[p]=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks'])
current=[]
for r in back['current37']:
 v={k:h for k,h in r.items()if k!='current'}
 if r['target']in written:v.update(sha256=written[r['target']]['sha256'],bytes=written[r['target']]['bytes'])
 current.append(v)
oldbacks=back['old795_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in back['new_backups']];assert len(oldbacks)==822
plan=dict(status='ROOT_ONLY_CURRENT_B78D_CREATE_NEW27_BACKUP_PLAN_NOT_EXECUTED',scope=pin(scope_path),parent_deployment=pin(dep_path),current27=rows,current37=current,frozen2121_expected=facts,prior_save15=back['save15'],old822_backup_facts=oldbacks,media167=back['media_facts'],World54=back['World54_facts'],ui=back['ui'],Root_only_backup_prefix=prefix,expected_old_backup_total=822,expected_after_backup_total=849,media_timestamp_policy='FIXED_SHA_BYTES_CAPTURE_CURRENT_TICKS_NEVER_ROLLBACK',canonical_writes=0,engine_calls=0)
plan_path=O/'current_B78D_backup27_ROOT_PLAN.json';plan_path.write_bytes(enc(plan))
parent=P/'backup_current_5FCE_27_ROOT_ONLY.py';raw=parent.read_bytes();text=raw.decode();edits=[]
for a,b in [('region_phase_lifetime_repair03/current_5FCE_backup27_ROOT_PLAN.json','region_visual_finish_repair04/current_B78D_backup27_ROOT_PLAN.json'),('old795_backup_facts','old822_backup_facts'),('795+len(rows)','822+len(rows)'),('CURRENT_5FCE','CURRENT_B78D')]:
 assert a in text;count=text.count(a);text=text.replace(a,b);edits.append(dict(old=a,new=b,count=count))
inverse=text
for e in reversed(edits):assert inverse.count(e['new'])==e['count'];inverse=inverse.replace(e['new'],e['old'])
assert inverse.encode()==raw;compile(text,'backup_current_B78D_27_ROOT_ONLY.py','exec')
tool=O/'backup_current_B78D_27_ROOT_ONLY.py';tool.write_bytes(text.encode());proof=O/'backup27_transport_inverse_NOT_EXECUTED.json';proof.write_bytes(enc(dict(parent=pin(parent),candidate=pin(tool),hunks=edits,whole_UTF8_inverse=True,executed=False)))
print(json.dumps(dict(scope=pin(scope_path),plan=pin(plan_path),tool=pin(tool),inverse=pin(proof),source_executed_backup=False)))
