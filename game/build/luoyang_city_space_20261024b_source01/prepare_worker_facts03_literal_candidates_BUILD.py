"""One functional artifact-facts hunk, otherwise exact dependency literals only."""
from pathlib import Path
import json
import hashlib
import difflib
GAME=Path(__file__).resolve().parents[2]
HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/'
OUT=HERE/'worker_facts03';OUT.mkdir(exist_ok=False)
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=(GAME/p[6:]).read_bytes();assert h is None or sha(b)==h;assert b'tokens truncated' not in b;return b
def output(name,b):
    with (OUT/name).open('xb') as stream:stream.write(b)
    return dict(path=S+'worker_facts03/'+name,sha256=sha(b),bytes=len(b))
def exact(raw,a,b):
    a,b=a.encode('utf8'),b.encode('utf8');assert a!=b and raw.count(a)==1,(a,raw.count(a));return raw.replace(a,b,1)
def hunks(a,b):
    left,right=a.decode('utf8').splitlines(keepends=True),b.decode('utf8').splitlines(keepends=True)
    for context in [3,6,12,24,48,96,max(len(left),len(right))]:
        rows=[dict(old=''.join(left[g[0][1]:g[-1][2]]),new=''.join(right[g[0][3]:g[-1][4]])) for g in difflib.SequenceMatcher(None,left,right,autojunk=False).get_grouped_opcodes(context)]
        f,i=a.decode('utf8'),b.decode('utf8');ok=True
        for r in rows:
            if f.count(r['old'])!=1 or i.count(r['new'])!=1:ok=False;break
            f=f.replace(r['old'],r['new'],1);i=i.replace(r['new'],r['old'],1)
        if ok and f.encode('utf8')==b and i.encode('utf8')==a:return rows
    raise AssertionError('BYTE_INVERSE')
base=S+'runtime_READY02/'
records={}
def finish(key,parent,parent_sha,b):
    a=read(parent,parent_sha);candidate=output(key+'_CANDIDATE.gd',b)
    records[key]=dict(parent=dict(path=parent,sha256=parent_sha,bytes=len(a)),candidate=candidate,hunks=hunks(a,b),wholebyte_forward_inverse=True)
    return candidate
oldruntime=base+'market_space_runtime_READY.gd';oldruntime_sha='077101d2c4f45b7d4ab02767260de2ae931f84a6c0d6066966f38f814d64aac9'
raw=read(S+'market_space_runtime_artifact_facts_successor03_CANDIDATE.gd','1d80d1fe5e2a19f32ecaaddf695168dac86cb11cf39d8f6ab85b8bb4afaa8cdd')
raw=exact(raw,oldruntime,S+'worker_facts03/runtime_CANDIDATE.gd')
runtime=finish('runtime',oldruntime,oldruntime_sha,raw)
oldadapter=base+'finite_adapter_READY.gd';oldadapter_sha='f0729ad23d17a05ad20173cd2217d2022a44c1f2f562d03b688e4e0b17582c55'
raw=read(oldadapter,oldadapter_sha)
for a,b in [(oldruntime,runtime['path']),(oldruntime_sha,runtime['sha256']),(oldadapter,S+'worker_facts03/adapter_CANDIDATE.gd')]:raw=exact(raw,a,b)
adapter=finish('adapter',oldadapter,oldadapter_sha,raw)
parents={
 'C':(base+'C_READY.gd','953e0512985a2b2c552ef1dac633efe87a80ad8e3a44bd8e5f3843830e3dc650'),
 'DT':(base+'DT_READY.gd','e7ae449a4252eb6294669ce7a9de93985f7b879dbac2cbfeb3a0131e2de87f2b'),
 'Fade':(base+'Fade_READY.gd','f97a498ee1fda59c7bc2c54c1df7624209d9ddbd4149c2e458c16f696ec54616'),
 'B':(base+'B_READY.gd','3f37b2427b1102e0cbec1796e2cbf557c75a7a9e23f913ce3fd577fb4fbbf880'),
 'G':(base+'G_scope_dialog_sources_READY.gd','66e81fe56206f5b52400a5e41f8c3114bbc10f01fb9d5758cc07dc6fe58b6905'),
 'Field':(base+'Field_READY.gd','4cc7015c8e2bbbcf3c3da47bc9d7505d5714a6697c318275257104f4fd259801'),
 'ENV':(base+'ENV_READY.gd','9ebdee2fafd73fa9cdc6568cc0f9afdcd97ba8d586a86ebb95ca8804a6b2e177'),
 'ground':(base+'ground_READY.gd','43df4613fa07edb9f66c00d598005062d50ec1c17d1e430eebe9df3ceec23524')}
for key in ['C','DT','Fade','B','G','Field','ENV','ground']:
    parent,h=parents[key];raw=read(parent,h)
    if oldadapter.encode() in raw:
        raw=exact(raw,oldadapter,adapter['path']);raw=exact(raw,oldadapter_sha,adapter['sha256'])
    if oldruntime.encode() in raw:
        raw=exact(raw,oldruntime,runtime['path']);raw=exact(raw,oldruntime_sha,runtime['sha256'])
    if key=='B':
        fade=records['Fade']['candidate'];oldfade=parents['Fade']
        for a,b in [('var current_before: String="ad42f13efa29cef61f9a24125e1bdcc9c08003fd0336023ae44026dc1097d526"','var current_before: String="'+oldfade[1]+'"'),
                    (oldfade[1],fade['sha256']),(oldfade[0],fade['path'])]:
            # The newly written current_before is not the next SHA literal.
            if a==oldfade[1]:a='var next: String="'+a+'"';b='var next: String="'+b+'"'
            raw=exact(raw,a,b)
    finish(key,parent,h,raw)
oldbinding=json.loads(read(base+'market_space_binding_READY.json','003ec7f690ed9494f315132a4f3f6e16263ad3ca38ccb34392913ae07c5f4cdb'))
old=json.loads(read('res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/adapter_binding_READY.json','dc21bb2a5e8d4e1af6944d6a6fe6c864caf29702e4b17b44063ed2369f53ecff'))
before={**old['shared_source_sha256'],**old['domains']['market']['source_sha256'],**oldbinding['source_sha256']}
assert all(r['path'] not in before for r in oldbinding['artifacts'].values())
after=dict(before)
for r in oldbinding['artifacts'].values():after[r['path']]=r['sha256']
assert set(after)-set(before)=={r['path'] for r in oldbinding['artifacts'].values()}
report=dict(status='EXACT_PUBLISHED_FOUR_ARTIFACTS_SAME_TOKEN_FACTS_BUILD_NOT_RUNTIME',ready=False,records=records,
    definite_failure_gate='adapter.validate_packet_worker first stream_sha AND context.facts[new_packet_path] equality',
    before_new_packet_fact_present=False,after_four_exact_binding_artifact_facts_present=True,
    no_native_inverse_or_geometry_changed=True,no_binding_or_media_change=True,unknown_later_gates_not_claimed_passed=True,
    sole_functional_change='runtime.effective_domain exact four fixed artifact rows, conflicting existing facts reject',
    source_collector_calls=0,engine_calls=0,canonical_writes=0)
proof=output('literal_candidates_and_four_facts_inverse_BUILD.json',(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode('utf8'))
print(json.dumps(dict(proof=proof,candidates={k:v['candidate'] for k,v in records.items()})))
