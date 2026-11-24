"""BUILD-only exact current47CC domain and Root CreateNew32 backup plan. No backup run."""
from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/'
B=S+'prefetch_elder_patrol32_repair01/';O=N/'prefetch_elder_patrol32_repair01'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(pin):
    data=(G/pin['path'][6:]).read_bytes();assert sha(data)==pin['sha256'],pin;return data
def load(pin):return json.loads(read(pin))
def emit(name,data):
    p=O/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as f:f.write(data)
    return dict(path=B+name,sha256=sha(data),bytes=len(data))
DEP=dict(path=S+'Estate_wall_source_repair01/Estate_wall_source31_deployed_ROOT_ACTUAL.json',sha256='47cc68861ae8165dd1517cf77787165d4f48d708faa10e587a062c3193860583')
OLD=dict(path=S+'Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54')
BACK=dict(path=S+'Estate_wall_source_repair01/current_0860_backup31_ROOT_ACTUAL.json',sha256='ad48454d8798b51b1076fe1482f842373ed78cd2b96a29a7053caaa90c6a631e')
ELDER=dict(path='res://build/luoyang_city_finish_20261025i_art01/monks19_three_media_promoted_ROOT_ACTUAL.json',sha256='350408128265e5e408da64b6b5feaddc51e727de4d0c13f78cb906ae803a87a4')
WORLD=dict(path='res://build/luoyang_city_finish_20261025i_art01/world24d_heads01/world18_ingress04/world18_media54_promotion_ROOT_EXECUTED.json',sha256='c7e9baddb6c94a1b7cd0742041c147f29eb320902eae4e0fa2ea6f4fa191a2f3')
dep,old,back,elder,world=map(load,[DEP,OLD,BACK,ELDER,WORLD])
parents={r['target']:dict(path=r['candidate_path'],sha256=r['sha256'],bytes=r['bytes']) for r in dep['targets']}
LM='res://scripts/autoload/loading_manager.gd'
lm_sha='17d352ab9af088bb187e48efe7aa29de4720cacee2d8693301acd57fd5d9dde2'
lm_bytes=read(dict(path=LM,sha256=lm_sha))
lm_snapshot=emit('immutable_LM_17D352_before_prefetch.gd',lm_bytes)
parents[LM]=lm_snapshot
assert len(parents)==32 and sum(p.endswith('.gd') for p in parents)==18
scope=emit('current_47CC_exact32_scope_PREPARATION.json',enc(dict(status='CURRENT47CC_PREFETCH_ELDER_PATROL_EXACT32_PREPARATION',count=32,partition=dict(GD=18,JSON=14),parent_actual=DEP,parent_stage=dep['stage'],parent_descriptor=OLD,old_backups=492,targets=[dict(target=p,immutable_old=r['path'],old_sha256=r['sha256'],old_bytes=r['bytes'])for p,r in parents.items()],no_canonical_writes=True)))
frozen={r['path']:{k:v for k,v in r.items()if k!='path'} for r in back['frozen2121_current_facts']}
def key(p):return str(G/p[6:] if p.startswith('res://') else Path(p)).replace('\\','/').casefold()
lookup={key(p):p for p in frozen};current={r['target']:copy.deepcopy(r) for r in back['current36']}
for row in dep['targets']:
    fact=dict(exists=True,sha256=row['sha256'],bytes=row['bytes'],ticks=row['ticks'])
    if key(row['target']) in lookup:frozen[lookup[key(row['target'])]]=fact
    current[row['target']]=dict(target=row['target'],sha256=row['sha256'],bytes=row['bytes'],immutable_candidate=row['candidate_path'],current=fact)
assert key(LM) in lookup
lm_fact=frozen[lookup[key(LM)]];assert lm_fact['sha256']==lm_sha and lm_fact['bytes']==len(lm_bytes)
current[LM]=dict(target=LM,sha256=lm_sha,bytes=len(lm_bytes),immutable_candidate=lm_snapshot['path'],current=copy.deepcopy(lm_fact))
backs=copy.deepcopy(back['old461_backup_facts'])+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in back['new_backups']]
media=copy.deepcopy(back['media_facts'])
assert len(media)==125 and len(backs)==492 and len(current)==37 and len(frozen)==2121
assert elder['passed'] is True and len(elder['copied'])==3 and world['passed'] is True and len(world['written'])==54
media += [dict(group='city_media',**r) for r in elder['copied']]
world54=[dict(group='world_media',path=r['path'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks']) for r in world['written']]
plan=emit('current_47CC_backup32_ROOT_PLAN.json',enc(dict(status='ROOT_ONLY47CC_CREATE_NEW32_PLAN_NOT_EXECUTED',scope=scope,parent_deployment=DEP,current32=[dict(**r,backup=B+'root_only_current32_backup/'+r['target'][6:])for r in load(scope)['targets']],current37=list(current.values()),frozen2121_expected=frozen,save15_expected=back['save15'],old492_backup_facts=backs,media128=media,World54=world54,ui=back['ui'],Root_only_backup_prefix=B+'root_only_current32_backup/',expected_old_backup_total=492,expected_after_backup_total=524,canonical_writes=0,engine_calls=0)))
parent_path=S+'Estate_wall_source_repair01/backup_current_0860_31_ROOT_ONLY.py'
parent=read(dict(path=parent_path,sha256='4ac45ab8c5aa7dd83d345339bf36e772e4a9ae108b8d65d1713a96a37bd7ef35'))
text=parent.decode();changes=[]
for a,b in [('CreateNew31','CreateNew32'),('Estate_wall_source_repair01/current_0860_backup31_ROOT_PLAN.json','prefetch_elder_patrol32_repair01/current_47CC_backup32_ROOT_PLAN.json'),('--root-authorized-backup31','--root-authorized-backup32'),('root_authorized_backup31','root_authorized_backup32'),('current31','current32'),('current36','current37'),('old461','old492'),('media125','media128'),('NEW31_BACKUP_MUST_BE_ABSENT','NEW32_BACKUP_MUST_BE_ABSENT'),('ROOT_CURRENT_0860_FULL31_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT47CC_FULL32_BACKUP_AND_FRESH_OBSERVATION'),('ROOT_CURRENT_0860_FRESH_OBSERVATION_ONLY','ROOT_CURRENT47CC_FRESH_OBSERVATION_ONLY'),('461+len(rows)','492+len(rows)'),("plan['media128']+[plan['ui']]","plan['media128']+plan['World54']+[plan['ui']]")]:
    assert a in text,a;text=text.replace(a,b);changes.append(dict(old=a,new=b))
inverse=text
for row in reversed(changes):inverse=inverse.replace(row['new'],row['old'])
assert inverse.encode()==parent
compile(text,'backup_current_47CC_32_ROOT_ONLY.py','exec')
tool=emit('backup_current_47CC_32_ROOT_ONLY.py',text.encode())
proof=emit('backup32_tool_whole_inverse_NOT_EXECUTED.json',enc(dict(parent=dict(path=parent_path,sha256=sha(parent)),candidate=tool,hunks=changes,whole_byte_inverse=True,backup_calls=0,engine_calls=0,canonical_writes=0)))
print(json.dumps(dict(scope=scope,plan=plan,tool=tool,proof=proof)))
