"""Mechanical fresh-baseline Root26 backup plan from actual D9A8 deployment."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';P=S/'region_integration_20261027d01';O=S/'region_source_rebind_repair02';sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode();res=lambda p:'res://'+p.relative_to(G).as_posix()
def fixed(p,h):
 b=p.read_bytes();assert sha(b)==h;return json.loads(b)
def pin(p):b=p.read_bytes();return dict(path=res(p),sha256=sha(b),bytes=len(b))
scope_path=N/'source_rebinding02_BUILD/closure26/current_D9A8_exact26_scope_PREPARATION.json';scope=fixed(scope_path,'10c5ec0d991dd351f0f9510815be4d36286992afffb71adaa42e019f55cdc58f')
dep_path=P/'region_integration32_deployed_ROOT_ACTUAL.json';dep=fixed(dep_path,'d9a8a9b7ac8752f31e8d3a59d7d4d8bddbcbaa261711bef05c6c608f54e7967f')
back=fixed(P/'current_01656_backup32_ROOT_ACTUAL.json','5d406f8866427ace84600088b30748ec8bd3d30d8ed5bcd1b170316c11b882c1')
assert not O.exists();O.mkdir();prefix=res(O)+'/root_only_current26_backup/'
rows=[{**r,'backup':prefix+r['target'][6:]}for r in scope['targets']];assert len(rows)==26
written={r['target']:r for r in dep['targets']};absolute={str((G/p[6:]).resolve()).casefold():r for p,r in written.items()};facts={r['path']:{k:v for k,v in r.items()if k!='path'}for r in back['frozen2121_current_facts']}
for p in facts:
 key=str((G/p[6:]if p.startswith('res://')else Path(p)).resolve()).casefold()
 if key in absolute:
  r=absolute[key];facts[p]=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks'])
current=[]
for r in back['current37']:
 v={k:h for k,h in r.items()if k!='current'}
 if r['target']in written:v.update(sha256=written[r['target']]['sha256'],bytes=written[r['target']]['bytes'])
 current.append(v)
oldbacks=back['old737_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in back['new_backups']];assert len(oldbacks)==769
media=list(back['media_facts']);known={r['path']for r in media}
for r in dep['adopted_media_facts']:
 if r['path']not in known:media.append(r);known.add(r['path'])
assert len(media)==167
plan=dict(status='ROOT_ONLY_CURRENT_D9A8_CREATE_NEW26_BACKUP_PLAN_NOT_EXECUTED',scope=pin(scope_path),parent_deployment=pin(dep_path),current26=rows,current37=current,frozen2121_expected=facts,prior_save15=back['save15'],old769_backup_facts=oldbacks,media167=media,World54=back['World54_facts'],ui=back['ui'],Root_only_backup_prefix=prefix,expected_old_backup_total=769,expected_after_backup_total=795,media_timestamp_policy='FIXED_SHA_BYTES_CAPTURE_CURRENT_TICKS_NEVER_ROLLBACK',canonical_writes=0,engine_calls=0)
plan_path=O/'current_D9A8_backup26_ROOT_PLAN.json';plan_path.write_bytes(enc(plan))
parent=P/'backup_current_01656_32_ROOT_ONLY.py';raw=parent.read_bytes();text=raw.decode();edits=[]
for a,b in [('region_integration_20261027d01/current_01656_backup32_ROOT_PLAN.json','region_source_rebind_repair02/current_D9A8_backup26_ROOT_PLAN.json'),('CreateNew32','CreateNew26'),('root-authorized-backup32','root-authorized-backup26'),('root_authorized_backup32','root_authorized_backup26'),("plan['current32']","plan['current26']"),('current32=plan', 'current26=plan'),('old737_backup_facts','old769_backup_facts'),('737+len(rows)','769+len(rows)'),('media158','media167'),('fresh_media[:158]','fresh_media[:167]'),('fresh_media[158:]','fresh_media[167:]'),('CURRENT_01656_FULL32','CURRENT_D9A8_FULL26'),('CURRENT_01656_FRESH','CURRENT_D9A8_FRESH'),('NEW32_BACKUP','NEW26_BACKUP')]:
 assert a in text,a;count=text.count(a);text=text.replace(a,b);edits.append(dict(old=a,new=b,count=count))
inverse=text
for e in reversed(edits):assert inverse.count(e['new'])==e['count'];inverse=inverse.replace(e['new'],e['old'])
assert inverse.encode()==raw;compile(text,'backup_current_D9A8_26_ROOT_ONLY.py','exec')
tool=O/'backup_current_D9A8_26_ROOT_ONLY.py';tool.write_bytes(text.encode())
proof=O/'backup26_transport_inverse_NOT_EXECUTED.json';proof.write_bytes(enc(dict(parent=pin(parent),candidate=pin(tool),hunks=edits,whole_UTF8_inverse=True,executed=False)))
print(json.dumps({'scope':pin(scope_path),'plan':pin(plan_path),'tool':pin(tool),'inverse':pin(proof),'source_executed_backup':False}))
