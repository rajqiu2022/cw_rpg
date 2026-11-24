"""Finite declared execution graph only; no Stage, runtime or canonical access."""
from pathlib import Path
import json,hashlib,collections
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024c_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
p='res://scripts/city/luoyang_temple_assembly_20261016.gd';base='3a033cc56525997ee3b7d96b87d08f19f6088accba8d35b183641ffd886f2827'
row=load(S+'code_dependencies30_READY/execution_successor_PREPARATION.json','9e7b5166bcc8e93a69d2e5f136fe339635001ae17215383f19b6427bebd3475f')['owned'][p]
def distance(start,end):
    queue=collections.deque([(start,[])]);seen=set()
    while queue:
        node,chain=queue.popleft()
        if node==end:return chain
        if node in seen:continue
        seen.add(node)
        for e in row['edges']:
            if e['new_sha256']==node:queue.append((e['old_sha256'],chain+[dict(old_sha256=e['old_sha256'],new_sha256=e['new_sha256'],old_snapshot=e['old_snapshot'],new_snapshot=e['new_snapshot'])]))
    return None
current_chain=distance(row['current_sha256'],base)
prior=row['edges'][-1]['old_sha256'];prior_chain=distance(prior,base)
def exact_original_approved(start,historical):
    frontier,visited=[start],set()
    for _ in range(16):
        following=[]
        for h in frontier:
            if h==historical:return True
            if h in visited:continue
            visited.add(h);following.extend(e['old_sha256'] for e in row['edges'] if e['new_sha256']==h)
        frontier=following
    return False
v=dict(status='FIXED_TEMPLE_BASELINE_DEPTH_READONLY_NOT_AUTHORITY',path=p,baseline_sha256=base,current_sha256=row['current_sha256'],prior_formal_sha256=prior,
 current_shortest_edges=len(current_chain),prior_shortest_edges=len(prior_chain),original_range16_accepts_prior=exact_original_approved(prior,base),original_range16_accepts_current=exact_original_approved(row['current_sha256'],base),
 range16_checks_distances=list(range(16)),chain_current_back_to_original=current_chain,
 cause='All complete old/new snapshot edges exist, but the exact oldest fixed Docks/Market AO baseline is outside the original bounded traversal after one new Temple edge.',
 proposed_only='Preserve all edges and range16. One separately Root-approved complete-byte historical shortcut from the exact oldest snapshot to the already-deployed prior formal snapshot can shorten this one bounded path; no membership/source-key expansion.',
 Stage_calls=0,engine_calls=0,collector_calls=0,canonical_reads=0,canonical_writes=0)
b=(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode();out=HERE/'temple_fixed_depth_cause_READONLY.json'
with out.open('xb') as f:f.write(b)
print(json.dumps(dict(path=S+out.name,sha256=sha(b),current_depth=len(current_chain),prior_depth=len(prior_chain),range16_prior=v['original_range16_accepts_prior'],range16_current=v['original_range16_accepts_current'])))
