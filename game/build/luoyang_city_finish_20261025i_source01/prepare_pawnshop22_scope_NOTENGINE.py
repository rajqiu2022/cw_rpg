"""Prepare only the approved pawnshop 22-target old scope and Root backup transport."""
from pathlib import Path
import json, hashlib

G = Path(__file__).resolve().parents[2]
S = G / 'build/luoyang_city_finish_20261025i_source01'
N = S / 'pawnshop_only_repair01'
R = 'res://build/luoyang_city_finish_20261025i_source01/'
BASE = S / 'prefetch_elder_patrol32_repair01/current_47CC_backup32_ROOT_PLAN.json'
DESC = S / 'Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'
GP = 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
GOLD = R + 'runtime_READY01/G_READY.gd'
GSHA = 'bea30e25f412025d79ada89b282385198471b19f0811a5b97a01cd1a810c6064'

def sha(b): return hashlib.sha256(b).hexdigest()
def res(p): return G / p[6:]
def emit(p, value):
    raw = (json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False)+'\n').encode('utf-8')
    p.parent.mkdir(parents=True, exist_ok=True)
    if p.exists(): assert p.read_bytes()==raw
    else:
        with p.open('xb') as f: f.write(raw)
    return {'path':'res://'+p.relative_to(G).as_posix(),'sha256':sha(raw),'bytes':len(raw)}

base = json.loads(BASE.read_text(encoding='utf-8'))
desc = json.loads(DESC.read_text(encoding='utf-8'))
rows = []
for record in desc['targets']:
    p = record['target']
    if p not in desc['metadata'] and p not in desc['index_proofs'] and not p.endswith('/execution_successor.json'): continue
    c = record['candidate']; raw = res(p).read_bytes()
    assert raw == res(c['path']).read_bytes() and sha(raw) == c['sha256'] and len(raw) == c['bytes'], p
    rows.append(dict(target=p, immutable_old=c['path'], old_sha256=c['sha256'], old_bytes=c['bytes'], backup=R+'pawnshop_only_repair01/root_only_current22_backup/'+p[6:]))
raw = res(GP).read_bytes()
assert raw == res(GOLD).read_bytes() and sha(raw) == GSHA
rows.append(dict(target=GP, immutable_old=GOLD, old_sha256=GSHA, old_bytes=len(raw), backup=R+'pawnshop_only_repair01/root_only_current22_backup/'+GP[6:]))
assert len(rows) == 22 and len({r['target'] for r in rows}) == 22
assert sum(r['target'].endswith('.gd') for r in rows)==9
assert sum(r['target'].endswith('.json') for r in rows)==13
scope = emit(N/'current_47CC_exact22_scope_PREPARATION.json', dict(status='PAWN_ONLY_22_OLD_TARGETS_READONLY_PINNED_NOT_BACKED_UP', parent_deployment=base['parent_deployment'], targets=rows, expected_count=22, functional_scope=['G pawn exact route and same author view','NEW pawn services helper','NEW pawn author'], excluded_paused_batches=['prefetch','elder','patrol','World'], canonical_writes=0, engine_calls=0, Stage_calls=0))
plan = dict(status='ROOT_ONLY_CREATE_NEW22_BACKUP_PLAN_NOT_EXECUTED', scope=scope, parent_deployment=base['parent_deployment'], current22=rows, current37=base['current37'], frozen2121_expected=base['frozen2121_expected'], save15_expected=base['save15_expected'], old492_backup_facts=base['old492_backup_facts'], media128=base['media128'], World54=base['World54'], ui=base['ui'], Root_only_backup_prefix=R+'pawnshop_only_repair01/root_only_current22_backup/', expected_old_backup_total=492, expected_after_backup_total=514, canonical_writes=0, engine_calls=0)
planref=emit(N/'current_47CC_backup22_ROOT_PLAN.json',plan)
old=S/'prefetch_elder_patrol32_repair01/backup_current_47CC_32_ROOT_ONLY.py'
text=old.read_text(encoding='utf-8')
changes=[('CreateNew32','CreateNew22'),('prefetch_elder_patrol32_repair01/current_47CC_backup32_ROOT_PLAN.json','pawnshop_only_repair01/current_47CC_backup22_ROOT_PLAN.json'),('backup32','backup22'),('BACKUP32','BACKUP22'),("plan['current32']","plan['current22']"),('current32=plan[\'current22\']','current22=plan[\'current22\']'),('NEW32','NEW22'),('FULL32','FULL22')]
new=text
for a,b in changes:
    new=new.replace(a,b)
assert 'current32' not in new and 'backup32' not in new
tool=N/'backup_current_47CC_22_ROOT_ONLY.py'
if tool.exists(): assert tool.read_bytes()==new.encode('utf-8')
else:
    with tool.open('xb') as f:f.write(new.encode('utf-8'))
import difflib
aa=text.splitlines(keepends=True);bb=new.splitlines(keepends=True)
hunks=[dict(old=''.join(aa[a:b]),new=''.join(bb[c:d])) for tag,a,b,c,d in difflib.SequenceMatcher(a=aa,b=bb,autojunk=False).get_opcodes() if tag!='equal']
forward=text
for h in hunks:
    assert forward.count(h['old'])==1
    forward=forward.replace(h['old'],h['new'],1)
assert forward==new
back=new
for h in reversed(hunks):
    assert back.count(h['new'])==1
    back=back.replace(h['new'],h['old'],1)
assert back==text
proof=emit(N/'backup22_tool_whole_inverse_NOT_EXECUTED.json',dict(parent={'path':'res://'+old.relative_to(G).as_posix(),'sha256':sha(old.read_bytes())},candidate={'path':'res://'+tool.relative_to(G).as_posix(),'sha256':sha(tool.read_bytes())}, hunks=hunks,whole_UTF8_inverse=True,logic_changes='Only scope count and new output paths; original guard/CreateNew implementation preserved.',execution_calls=0))
print(json.dumps(dict(scope=scope,plan=planref,tool={'path':'res://'+tool.relative_to(G).as_posix(),'sha256':sha(tool.read_bytes())},proof=proof)))
