"""Only same-SHA/bytes editor reimport timestamp boundary; preserves failed backup01."""
from pathlib import Path
import json,hashlib,difflib
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'Field_EOF_adoption01/';O=N/'Field_EOF_adoption01';sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf8')
oldplan=(O/'current_E370_backup24plus2_ROOT_PLAN.json').read_bytes();assert sha(oldplan)=='fff44718760d0a974717862e90402943892b919c7d209637bd2334e0a9cd4b37';plan=json.loads(oldplan)
plan.update(media_timestamp_policy='FIXED_SHA_BYTES_REQUIRED_CAPTURE_CURRENT_TICKS_AT_ROOT_EXECUTION_NEVER_RESTORE_OLD_MTIME',original_failed_plan_preserved=dict(path=P+'current_E370_backup24plus2_ROOT_PLAN.json',sha256=sha(oldplan)),original_attempt_stopped_before_any_backup_or_canonical_write=True)
pb=enc(plan);dest=O/'current_E370_backup24plus2_ROOT_PLAN02.json';assert not dest.exists()
with dest.open('xb')as f:f.write(pb)
parent=(O/'backup_current_E370_24plus2_ROOT_ONLY.py').read_bytes();assert sha(parent)=='7c5697d3c676d1e9cf230e56cabdfb4ca7b254d857508e21e7a822f8db77f246';t=parent.decode()
t=t.replace('Field_EOF_adoption01/current_E370_backup24plus2_ROOT_PLAN.json','Field_EOF_adoption01/current_E370_backup24plus2_ROOT_PLAN02.json')
a=" protected=plan['old648_backup_facts']+plan['media149']+plan['World54']+[plan['ui']]"
b=""" fresh_media=[];media_tick_refreshes=[]
 for r in plan['media149']+plan['World54']:
  f=fact(r['path']);assert f.get('exists')is True and f['sha256']==r['sha256']and f['bytes']==r['bytes'],('PROTECTED_MEDIA_CONTENT_DRIFT_KEEP_AND_STOP',r['path'])
  if f['ticks']!=r['ticks']:media_tick_refreshes.append(dict(path=r['path'],old_ticks=r['ticks'],current_ticks=f['ticks'],SHA_bytes_identical=True))
  fresh_media.append(dict(path=r['path'],**f))
 protected=plan['old648_backup_facts']+fresh_media+[plan['ui']]"""
assert t.count(a)==1;t=t.replace(a,b)
a="media_facts=plan['media149'],ui=plan['ui']"
b="media_facts=fresh_media[:149],World54_facts=fresh_media[149:],media_tick_refreshes=media_tick_refreshes,media_content_changes=0,ui=plan['ui']"
assert t.count(a)==1;t=t.replace(a,b)
compile(t,'backup_current_E370_24plus2_ROOT_ONLY02.py','exec');d=O/'backup_current_E370_24plus2_ROOT_ONLY02.py';assert not d.exists()
with d.open('xb')as f:f.write(t.encode())
print(json.dumps(dict(plan=dict(path=P+dest.name,sha256=sha(pb)),tool=dict(path=P+d.name,sha256=sha(t.encode())),canonical_writes=0,engine_calls=0)))
