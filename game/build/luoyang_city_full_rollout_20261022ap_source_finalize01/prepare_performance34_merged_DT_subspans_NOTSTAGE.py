"""NEW final DT passive subspan dependency descendant; no Stage/engine."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';P=S+'performance33_merged_code_dependencies/';O=S+'performance34_merged_DT_subspan_dependencies/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def read(path,s):return json.loads(fixed(path,s))
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
def ref(path,s):return {'path':path,'sha256':s}
def apply(raw,hs):
    out=raw
    for h in hs:
        a,b=h['old'].encode(),h['new'].encode();assert out.count(a)==1;out=out.replace(a,b,1)
    back=out
    for h in hs:
        a,b=h['old'].encode(),h['new'].encode();assert back.count(b)==1;back=back.replace(b,a,1)
    assert back==raw
    return out
oldproofp=P+'whole_code_and_binding_inverse_READY.json';oldproofs='dd23a47c22f2414d757e1313d2aef3c32666782d5e438374b41418b31ac2096c';oldproof=read(oldproofp,oldproofs)
oldhandp=P+'handoff_EXECUTION_AND_SCOPE_PROPOSAL.json';oldhands='828c57438ff1570dd81ecb4538813af67073b5fbe08b4be6dc958b2c208618c5';oldhand=read(oldhandp,oldhands)
sysp='res://build/luoyang_city_full_rollout_20261022ap_system01/district_projection_subspans_epoch01/wholebyte_inverse_and_scope_NOT_RUNTIME_READY.json';syss='4973b8f98d3966c9cd9c9a9778868bf850bc284eb354d1caed9d93b29055c811';sys=read(sysp,syss)
d=copy.deepcopy(oldproof['records']['DT']);oldraw=fixed(d['parent']['path'],d['parent']['sha256']);prior=fixed(d['candidate']['path'],d['candidate']['sha256'])
newref={k:sys['candidate'][k].lower()if k=='sha256'else sys['candidate'][k]for k in ['path','sha256']};newraw=fixed(newref['path'],newref['sha256'])
assert apply(prior,sys['relative_replacements'])==newraw and apply(oldraw,sys['direct_formal_replacements'])==newraw
d.update(candidate=newref,hunks=copy.deepcopy(sys['direct_formal_replacements']))
proof=copy.deepcopy(oldproof);proof['status']='AP14_MERGED_COMPONENT_REQUIRED_LITERAL_AND_PASSIVE_DT_SUBSPAN_WHOLE_INVERSES_NOT_STAGED';proof['records']['DT']=d
proof['new_functional_scope_only']+=' DT additionally has explicitly Root-requested passive scalar child spans only, with original outer clock/calls/reject expressions unchanged.'
proof['DT_relative_6F0A_whole_inverse']=True;proof['DT_direct_3924_whole_inverse']=True
proof['DT_passive_diagnostics_semantics']=copy.deepcopy(sys['diagnostics'])
proof['historical_33_proposal_not_overwritten']=ref(oldhandp,oldhands)
proofp=O+'whole_code_and_binding_inverse_READY.json';proofb=js(proof)
parentref=oldhand['execution_parent'];parentbytes=fixed(parentref['path'],parentref['sha256']);parent=json.loads(parentbytes)
proposal=copy.deepcopy(parent);edges=[]
for name in ['B','G','DT','Temple']:
    r=proof['records'][name];target=r['target'];assert parent['owned'][target]['current_sha256']==r['parent']['sha256']
    assert apply(fixed(r['parent']['path'],r['parent']['sha256']),r['hunks'])==fixed(r['candidate']['path'],r['candidate']['sha256'])
    edge={'path':target,'old_sha256':r['parent']['sha256'],'new_sha256':r['candidate']['sha256'],'old_snapshot':r['parent']['path'],'new_snapshot':r['candidate']['path'],'whole_inverse':True,'replacements':copy.deepcopy(r['hunks'])}
    proposal['owned'][target]['current_sha256']=r['candidate']['sha256'];proposal['owned'][target]['edges'].append(edge);edges.append(edge)
pins={r['candidate']['path']:r['candidate']['sha256']for r in proof['records'].values()};pins[proofp]=sha(proofb)
assert len(pins)==9 and not(set(pins)&set(parent['source_sha256']))
proposal['source_sha256'].update(pins)
back=copy.deepcopy(proposal)
for e in edges:back['owned'][e['path']]=copy.deepcopy(parent['owned'][e['path']])
for path in pins:back['source_sha256'].pop(path)
assert same(back,parent)and js(back)==parentbytes and len(proposal['owned'])==10 and len(proposal['source_sha256'])==80
ep=O+'execution_successor_PROPOSAL.json';eb=js(proposal)
hand=copy.deepcopy(oldhand)
hand.update(status='MERGED_AP14_EXACT29_FINAL_DT_SUBSPAN_EXECUTION_PROPOSAL_NOT_ROOT_AUTHORIZED_NOT_STAGED',execution_proposal=ref(ep,sha(eb)),new_proof_sources_exact9=pins,whole_inverse_proof=ref(proofp,sha(proofb)),
 DT_system_dual_whole_inverse=ref(sysp,syss),DT_final_candidate=newref,
 old_scope_description_limit='C431 scope DT literal-only reason and09C745 semantic description are historical preparation-stage text, NOT authority for passive subspans.29 paths/603853 old backups unchanged. Final Root execution/diagnostic document must separately approve this exact candidate and proposal before locking input.',
 sourceStage_engine_collector_formal_calls=0)
diff=''.join(difflib.unified_diff(oldraw.decode().splitlines(True),newraw.decode().splitlines(True),fromfile=d['parent']['path'],tofile=newref['path'])).encode()
hand['diffs']['DT_complete.diff']=ref(O+'DT_complete.diff',sha(diff))
files={'whole_code_and_binding_inverse_READY.json':proofb,'execution_successor_PROPOSAL.json':eb,'DT_complete.diff':diff,'handoff_EXECUTION_AND_SCOPE_PROPOSAL.json':js(hand)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({n:sha(b)for n,b in files.items()},indent=2))
