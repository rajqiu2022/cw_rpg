"""Mechanical prior CreateNew backup recipe. This preparation never copies targets."""
from pathlib import Path
import copy, hashlib, json
N=Path(__file__).resolve().parent;G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/'
B=S+'visible_doors_boundaries33_repair01/';O=N/'visible_doors_boundaries33_repair01'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def load(pin):
    b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return json.loads(b)
scopepin=dict(path=B+'closure_READY01/current_signed31_exact33_scope_PREPARATION.json',sha256='0bf33b2c8c103d44a1db7e7056bb56b049a0327f0c9d62087848172c97397efa')
scope=load(scopepin);assert scope['count']==33 and scope['partition']==dict(GD=18,JSON=15)
dep_pin=scope['parent_actual'];dep=load(dep_pin)
backup_pin=dict(path=S+'temple_signed_iid_repair01/current_377B_backup31_ROOT_ACTUAL.json',sha256='8e8f484f0f9b0531969b4e227b5f71abd818dc4935fd568890ad79501bb76026')
backup=load(backup_pin)
guardpin=dict(path=S+'temple_signed_iid_repair01/post_D2_signed15_current2121_ROOT_ACTUAL.json',sha256='66307060238f37d9c965ea051faafddbb71759881d3cfe457044962eb7a57a94')
guard=load(guardpin)
assert dep['passed'] and guard['passed'] and guard['differences']==[] and backup['total_backups']==403
frozen={r['path']:{k:v for k,v in r.items()if k!='path'}for r in backup['frozen2121_current_facts']}
def key(p):return str(G/p[6:]if p.startswith('res://')else Path(p)).replace('\\','/').casefold()
lookup={key(p):p for p in frozen};assert len(lookup)==2121
current={r['target']:copy.deepcopy(r)for r in backup['current34']}
for r in dep['targets']:
    f=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks'])
    p=lookup.get(key(r['target']))
    if p is not None:frozen[p]=f
    current[r['target']]=dict(target=r['target'],sha256=r['sha256'],bytes=r['bytes'],immutable_candidate=r['candidate_path'],current=f)
assert len(current)==34
old=copy.deepcopy(backup['old372_backup_facts'])
old.extend(dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in backup['new_backups'])
assert len(old)==403
media=copy.deepcopy(backup['media_facts']);assert len(media)==116
def fresh_declared(pin):
    p=G/pin['path'][6:];a=p.stat();raw=p.read_bytes();z=p.stat()
    assert (a.st_size,a.st_mtime_ns)==(z.st_size,z.st_mtime_ns) and sha(raw)==pin['sha256'] and len(raw)==pin['bytes']
    return dict(path=pin['path'],exists=True,sha256=pin['sha256'],bytes=pin['bytes'],ticks=str(z.st_mtime_ns//100+621355968000000000))
promotions=[dict(path='res://build/luoyang_city_finish_20261025i_system01/qa_role_new/yamen_boundaries_mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json',sha256='22bc906dbfcedab8bea8e0ceab83e29d7a0f23f6068686e96dbba6247ed961ff'),dict(path='res://build/luoyang_city_finish_20261025i_system01/qa_role_new/monk_portraits2_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json',sha256='5edf8edbb346cc856273e75bb63f296276ff23ef415f67de2998b71bd40ff42f')]
extra=[dict(path=S+'street_edges_yamen02_local03_ROOT_READY/output_ROOT_READY/30628/ch4_s1_luoyang_yamen/walk_overlay.png',sha256='d9832dfae426f786a8823c4767d4e47ff5cc2df1a582f0360a34d344420b7a4c',bytes=31325)]
for pin in promotions:
    v=load(pin);assert v['passed']
    extra.extend({k:r[k]for k in ['path','sha256','bytes']}for r in v['written'])
assert len(extra)==9
known={r['path']for r in media};assert not known.intersection(r['path']for r in extra)
media.extend(fresh_declared(r)for r in extra);assert len(media)==125
rows=[]
for r in scope['targets']:
    row=copy.deepcopy(r);row.update(kind='GD'if r['target'].endswith('.gd')else'JSON',backup=B+'root_only_current33_backup/'+r['target'][6:]);rows.append(row)
plan=dict(status='ROOT_ONLY_CREATE_NEW33_FROM_ACTUAL_SIGNED31_PLAN_NOT_EXECUTED',scope=scopepin,parent_deployment=dep_pin,parent_guard=guardpin,current33=rows,current34=list(current.values()),frozen2121_expected=frozen,save15_expected=backup['save15'],old403_backup_facts=old,media125=media,ui=backup['ui'],Root_only_backup_prefix=B+'root_only_current33_backup/',expected_old_backup_total=403,expected_after_backup_total=436,authorized_tasks_successor=dict(disposition='KEEP_ROOT_AUTHORIZED_APPEND_AND_REFERENCE_BINDING; report any 2121 tasks diff explicitly, never restore the older parent fact',original_prefix='786954B',actual_chain=['7E01B7BB','F1C19EE1','790177B'],not_runtime_source_backfill=True),canonical_writes=0,engine_calls=0,save_writes=0)
parent=(N/'temple_signed_iid_repair01/backup_current_377B_31_ROOT_ONLY.py').read_bytes();text=parent.decode();changes=[]
for a,b in [
    ('CreateNew31','CreateNew33'),
    ('temple_signed_iid_repair01/current_377B_backup31_ROOT_PLAN.json','visible_doors_boundaries33_repair01/current_signed31_backup33_ROOT_PLAN.json'),
    ('--root-authorized-backup31','--root-authorized-backup33'),
    ('root_authorized_backup31','root_authorized_backup33'),
    ('current31','current33'),('old372','old403'),('media116','media125'),
    ('NEW31_BACKUP_MUST_BE_ABSENT','NEW33_BACKUP_MUST_BE_ABSENT'),
    ('ROOT_CURRENT_377B_FULL31_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_SIGNED31_FULL33_BACKUP_AND_FRESH_OBSERVATION'),
    ('ROOT_CURRENT_377B_FRESH_OBSERVATION_ONLY','ROOT_CURRENT_SIGNED31_FRESH_OBSERVATION_ONLY'),
    ('372+len(rows)','403+len(rows)'),
]:
    assert a in text,a;text=text.replace(a,b);changes.append(dict(old=a,new=b))
back=text
for h in reversed(changes):back=back.replace(h['new'],h['old'])
assert back.encode()==parent
compile(text,'backup_current_signed31_33_ROOT_ONLY.py','exec')
for name,raw in [('current_signed31_backup33_ROOT_PLAN.json',enc(plan)),('backup_current_signed31_33_ROOT_ONLY.py',text.encode()),('backup_tool_mechanical_inverse_NOT_EXECUTED.json',enc(dict(status='ROOT_ONLY_TOOL_NOT_EXECUTED',parent=dict(path=S+'temple_signed_iid_repair01/backup_current_377B_31_ROOT_ONLY.py',sha256=sha(parent)),candidate_sha256=sha(text.encode()),changes=changes,whole_byte_inverse=True,backup_copy_calls=0,canonical_writes=0)))]:
    dest=O/name;assert not dest.exists()
    with dest.open('xb')as stream:stream.write(raw)
    print(name,sha(raw),len(raw))
