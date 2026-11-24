"""Nine small dependency records and execution authority inverse, not a Stage."""
from pathlib import Path
import copy
import hashlib
import json

Q=Path(__file__).resolve().parent
G=Q.parents[1]
D=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance57_market_receipt_dependencies'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def res(v): return G/v[6:]
def strict(a,b):
    if type(a) is not type(b): return False
    if isinstance(a,dict): return list(a)==list(b) and all(strict(a[k],b[k]) for k in a)
    if isinstance(a,list): return len(a)==len(b) and all(strict(x,y) for x,y in zip(a,b))
    return a==b
hp=D/'handoff_EXECUTION_PROPOSAL_READY_NOT_STAGED.json'
pp=D/'whole_code_binding_contract_inverse_READY.json'
ep=D/'execution_successor_PROPOSAL.json'
assert sha(hp)=='e12394b9f9f47524f5118c3fb4ddad9a38306d042289eaddbe9f830a7398d953'
assert sha(pp)=='ccca37c590d293e9ef57ceec648d395bdd25458818b57ab7d5e55159073656c9'
assert sha(ep)=='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3'
h,p,e=rd(hp),rd(pp),rd(ep)
assert list(p['records'])==['adapter','C','DT','Fade','B','runtime_contract','Coordinator','temple_binding','Temple']
facts={}
for name,row in p['records'].items():
    oldpath,newpath=res(row['parent']['path']),res(row['candidate']['path'])
    old,new=oldpath.read_bytes(),newpath.read_bytes()
    assert len(old)<1048576 and len(new)<1048576
    assert sha(oldpath)==row['parent']['sha256'] and sha(newpath)==row['candidate']['sha256']
    forward=old
    for change in row['hunks']:
        a,b=change['old'].encode(),change['new'].encode()
        assert forward.count(a)==1
        forward=forward.replace(a,b)
    assert forward==new
    back=new
    for change in reversed(row['hunks']):
        a,b=change['old'].encode(),change['new'].encode()
        assert back.count(b)==1
        back=back.replace(b,a)
    assert back==old
    if 'target' in row: assert sha(res(row['target']))==row['parent']['sha256']
    facts[name]={'old':sha(oldpath),'new':sha(newpath),'hunks':len(row['hunks']),'bytes':len(new),'CRLF':new.count(b'\r\n'),'finalLF':new.endswith(b'\n')}
assert facts['adapter']['finalLF'] is False and facts['adapter']['CRLF']==0
assert facts['adapter']['new']=='cf2aa3da4f8dbafd30d48d9310d69d7eacb9f17d25e47ce02ca221835eff3736'
for name in ['C','DT','Fade']:
    row=p['records'][name]
    assert len(row['hunks'])==1 and 'const FINITE_ADAPTER_SHA :=' in row['hunks'][0]['old']
    assert 'cf2aa3da' in row['hunks'][0]['new']
# The culture JSON has exactly one leaf changed, not a new consumer exception.
row=p['records']['runtime_contract']
oldc,newc=rd(res(row['parent']['path'])),rd(res(row['candidate']['path']))
path='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'
assert set(oldc['source_sha256'])==set(newc['source_sha256'])
assert [k for k in oldc['source_sha256'] if oldc['source_sha256'][k]!=newc['source_sha256'][k]]==[path]
undo=copy.deepcopy(newc);undo['source_sha256'][path]=oldc['source_sha256'][path]
assert strict(undo,oldc)
# Exact three source_delta values; full byte inverse above also preserves all inherited binding fields/EOL.
row=p['records']['temple_binding']
oldt,newt=rd(res(row['parent']['path'])),rd(res(row['candidate']['path']))
tk=[k for k in oldt['source_delta'] if oldt['source_delta'][k]!=newt['source_delta'][k]]
assert set(tk)=={path,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd','res://data/luoyang_culture_integration_20261019x/runtime_contract.json'}
undo=copy.deepcopy(newt)
for k in tk: undo['source_delta'][k]=oldt['source_delta'][k]
assert strict(undo,oldt)
assert facts['temple_binding']['CRLF']==res(row['parent']['path']).read_bytes().count(b'\r\n')
# Closed execution authority: preserve full prior row history, append only four declared edges and ten pins.
old_ep=res(h['execution_parent']['path'])
assert sha(old_ep)==h['execution_parent']['sha256']=='bf043ab07d6ecb2c713607753e3ab2c67621923456ed44e7ab3393d9d3e9ed0d'
oe=rd(old_ep)
assert list(e['owned'])==list(oe['owned']) and len(e['owned'])==10
assert len(oe['source_sha256'])==85 and len(e['source_sha256'])==95
assert all(e['source_sha256'].get(k)==v for k,v in oe['source_sha256'].items())
added={k:v for k,v in e['source_sha256'].items() if k not in oe['source_sha256']}
assert added==h['new_exact10_proof_pins'] and len(added)==10
for path,digest in added.items():
    assert res(path).stat().st_size<1048576 and sha(res(path))==digest
undo=copy.deepcopy(e)
changed=[]
for row in h['owned_changed_exactly4']:
    path=row['path'];changed.append(path)
    before,after=oe['owned'][path],e['owned'][path]
    assert after['current_sha256']==row['new_sha256'] and before['current_sha256']==row['old_sha256']
    assert len(after['edges'])==len(before['edges'])+1 and strict(after['edges'][:-1],before['edges'])
    assert strict(after['edges'][-1],row)
    undo['owned'][path]=copy.deepcopy(before)
assert len(set(changed))==4
for path in oe['owned']:
    if path not in changed: assert strict(e['owned'][path],oe['owned'][path])
for path in added: del undo['source_sha256'][path]
assert strict(undo,oe)
assert (json.dumps(undo,ensure_ascii=False,indent=2)+'\n').encode()==old_ep.read_bytes()
B=res(p['records']['B']['candidate']['path']).read_text(encoding='utf-8')
gate=B[B.index('static func ao_fade_source_matches('):B.index('static func aa_packet_valid(')]
for value in ['finite_previous in history','last_published in history','delta.get("current_before_sha256")==last_published','delta.get("new_sha256")==next','delta.get("candidate_path")==candidate','config.legacy_source_sha256.get(path)==next']:
    assert value in gate
assert 'var last_published: String="58462561e7db2b3f26fd6e5a55b891fc85002d86c51228a771f354b3ca9311a8"' in gate
assert 'proof.get("scene")!=scene' in gate and 'FileAccess.get_sha256(path)!=next' in gate
out=Q/'performance57_nine_record_four_owned95pins_static_admission_NOT_STAGED.json'
assert not out.exists()
out.write_text(json.dumps({
    'status':'STATIC_NO_BLOCKER_NINE_RECORD_DEPENDENCIES_FOUR_OWNED_APPEND_ONLY_EXACT95PINS_NOT_STAGE',
    'pins':{'handoff':sha(hp),'joint_inverse':sha(pp),'execution':sha(ep),'execution_parent':sha(old_ep)},
    'record_byte_forward_inverse':facts,
    'semantic':{'adapter_CF2A_previously_independently_approved_market_only_logic':True,
        'C_DT_Fade_only_adapter_SHA_literal':True,'B_only_adapter_literal_and_strict_Fade_provenance_successor':True,
        'Fade_history_preserves_first_older_previous_finite_previous_and_requires_last5846':True,
        'same_scene_token_proof_currentSHA_candidateSHA_next_delta_and_legacy_checks_preserved':True,
        'culture_contract_only_C_leaf_typed_and_byte_inverse':True,'Coordinator_only_contract_SHA':True,
        'Temple_binding_exact3_source_delta_other_wholetyped_and_bytes_inverse':True,'Temple_only_binding_path_SHA':True,
        'no_StringName_hunk_no_DT_controlflow_or_geometric_change':True},
    'execution':{'same10_members':True,'exact4_append_edges_old_history_all_preserved':True,'other6_whole_same':True,
        'old85pins_same_exact10_new_to95':True,'whole_orderedtyped_and_serialized_UTF8_inverse':True,
        'candidate_and_all10_newproof_current_smallSHA_exact':True},
    'boundary':['No static blocker to final exact30 driver/input preparation; final DAG still requires its own audit',
        'Not Stage, deployment, parser or Market entrance approval','Adapter no-finalLF requires explicit original lossless transport',
        'Prior runtime/ART failures preserved; no big media or collector reads'],
    'operations':{'engine':0,'parse':0,'packet_decode':0,'collector':0,'Stage':0,'canonical':0}
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'static_blocker':False}))
