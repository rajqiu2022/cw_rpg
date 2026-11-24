"""Exact code/literal successors and seven existing-owned append-only edges."""
from pathlib import Path
import json,hashlib,copy,re,importlib.util
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_revision_20261024e_source01/'
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';DT='res://scripts/city/luoyang_district_life_20261016f.gd';FIELD='res://scripts/field/field_walkable_controller.gd';G='res://scripts/city/luoyang_assembled_interiors_20261016g.gd';ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd';ROUTER='res://scripts/autoload/scene_router.gd'
AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd';COORD='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';TEMPLE='res://scripts/city/luoyang_temple_assembly_20261016.gd'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),(p,sha(b));assert b'tokens truncated' not in b;return b
def load(p,h):return json.loads(read(p,h))
def exact(raw,a,b):
    a,b=a.encode(),b.encode();assert a!=b and raw.count(a)==1,(a,raw.count(a));return raw.replace(a,b,1)
def main():
    module_spec=importlib.util.spec_from_file_location('fixed_outer',HERE/'prepare_ordinary_outer01_BUILD.py');m=importlib.util.module_from_spec(module_spec);module_spec.loader.exec_module(m)
    scope=load(S+'exact33_existing_old_scope_PREPARATION.json','560df439ceb31b6e210ea79cef850fbfc96827ad5c4682a7fabfbd1c8be23671');parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256']) for r in scope['targets']}
    sealed=load(S+'runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json','ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad')
    ordinary=load(S+'ordinary_outer01_READY/whole_inverse_NOT_STAGE.json','26f9cd34b9c0aea9b782e267e3cf00ac279cea70cfe785a5055c331581d15618')
    env=load(S+'clean_ENV02_READY/whole_inverse_NOT_STAGE.json','ef8f18da6267c0e542c4e288310ae15c9675756ce22cb394b4461b94b5f1e04f')
    out=HERE/'dependencies33_READY';assert not out.exists();prefix=S+'dependencies33_READY/';prepared=[];records={}
    def output(name,b):
        prepared.append((name,b));return dict(path=prefix+name,sha256=sha(b),bytes=len(b))
    def record(p,name,candidate):
        a=read(parents[p]['path'],parents[p]['sha256'])
        b=next((data for filename,data in prepared if prefix+filename==candidate['path']),None)
        if b is None:b=read(candidate['path'],candidate['sha256'])
        assert sha(b)==candidate['sha256'];ops=m.hunks(a,b)
        assert b.endswith(b'\n')
        if p!=ROUTER:assert b'\r' not in b
        else:assert b.count(b'\r')==a.count(b'\r')==13
        records[p]=dict(name=name,parent=parents[p],candidate={**candidate,'bytes':len(b)},hunks=ops,wholebyte_forward_inverse=True)
    for kind,p in [('C',C),('DT',DT),('Field',FIELD),('G',G),('Router',ROUTER)]:record(p,kind,next(r['candidate'] for r in sealed['codes'] if r['kind']==kind))
    record(ENV,'ENV',env['candidate'])
    for p,name in [(AA,'AA'),(AC,'AC')]:record(p,name,ordinary['records'][p]['candidate'])
    original_raw=read(parents[CONTRACT]['path'],parents[CONTRACT]['sha256']);original=json.loads(original_raw);typed=copy.deepcopy(original);raw=original_raw;changes={}
    for p in [C,FIELD,ROUTER]:
        a=original['source_sha256'][p];b=records[p]['candidate']['sha256'];assert a==parents[p]['sha256'];raw=exact(raw,a,b);typed['source_sha256'][p]=b;changes[p]=dict(old_sha256=a,new_sha256=b)
    assert json.loads(raw)==typed;back=raw
    for r in reversed(list(changes.values())):back=exact(back,r['new_sha256'],r['old_sha256'])
    assert back==original_raw
    contract=output('runtime_contract_C_Field_Router_CANDIDATE.json',raw)
    a=read(parents[COORD]['path'],parents[COORD]['sha256']);coord=output('Coordinator_CANDIDATE.gd',exact(a,parents[CONTRACT]['sha256'],contract['sha256']));record(COORD,'Coordinator',coord)
    old_temple=read(parents[TEMPLE]['path'],parents[TEMPLE]['sha256']);text=old_temple.decode();bp=re.search(r'^const BIND_PATH="([^"]+)"',text,re.M).group(1);bh=re.search(r'^const BIND_SHA="([^"]+)"',text,re.M).group(1)
    old_bind_raw=read(bp,bh);old_bind=json.loads(old_bind_raw);binding=copy.deepcopy(old_bind);binding_changes={}
    refs={p:r['candidate']['sha256'] for p,r in records.items()};refs[CONTRACT]=contract['sha256']
    for p,a in old_bind['source_delta'].items():
        if p in refs:
            assert a==parents[p]['sha256'];binding['source_delta'][p]=refs[p];binding_changes[p]=dict(old_sha256=a,new_sha256=refs[p])
    helper='res://build/luoyang_loading_20261024e_perf01/candidate03/gate_source_prewarm02.gd';hh='03dec03dbfdd572042e566848d3231de56c1c45583fac4644cfccd99b3a81ed8';read(helper,hh)
    assert helper not in old_bind['source_delta'];binding['source_delta'][helper]=hh
    back=copy.deepcopy(binding)
    for p,r in binding_changes.items():back['source_delta'][p]=r['old_sha256']
    del back['source_delta'][helper];assert back==old_bind
    # The fixed Temple binding is mixed CRLF/LF. Preserve its entire original
    # byte representation, replacing exact path/value pairs and inserting one
    # ordinary key immediately inside source_delta; no broad serialization.
    bind_raw=old_bind_raw
    for p,r in binding_changes.items():bind_raw=exact(bind_raw,json.dumps(p)+': '+json.dumps(r['old_sha256']),json.dumps(p)+': '+json.dumps(r['new_sha256']))
    marker=b'  "source_delta": {\r\n';addition=('    '+json.dumps(helper)+': '+json.dumps(hh)+',\r\n').encode()
    assert bind_raw.count(marker)==1;bind_raw=bind_raw.replace(marker,marker+addition,1)
    assert json.loads(bind_raw)==binding
    rev=bind_raw.replace(marker+addition,marker,1)
    for p,r in reversed(list(binding_changes.items())):rev=exact(rev,json.dumps(p)+': '+json.dumps(r['new_sha256']),json.dumps(p)+': '+json.dumps(r['old_sha256']))
    assert rev==old_bind_raw
    bind=output('Temple_binding_ordinary_C_Field_Router_Coord_contract_CANDIDATE.json',bind_raw)
    temple=output('Temple_CANDIDATE.gd',exact(exact(old_temple,bp,bind['path']),bh,bind['sha256']));record(TEMPLE,'Temple',temple)
    original_raw=read(parents[EXEC]['path'],parents[EXEC]['sha256']);original=json.loads(original_raw);assert enc(original)==original_raw
    authority=copy.deepcopy(original);changed=[G,AC,DT,COORD,ROUTER,FIELD,TEMPLE]
    assert len(authority['owned'])==10 and len(authority['source_sha256'])==139 and C not in authority['owned'] and AA not in authority['owned'] and len(authority['owned'][TEMPLE]['edges'])==17
    for p in changed:
        row=authority['owned'][p];r=records[p];assert row['current_sha256']==r['parent']['sha256']
        snap=next(e['new_snapshot'] for e in row['edges'] if e['new_sha256']==row['current_sha256']);assert read(snap,row['current_sha256'])==read(r['parent']['path'],r['parent']['sha256'])
        row['edges'].append(dict(path=p,old_sha256=row['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snap,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));row['current_sha256']=r['candidate']['sha256'];authority['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
    for r in [contract,bind]:authority['source_sha256'][r['path']]=r['sha256']
    assert len(authority['source_sha256'])==148
    back=copy.deepcopy(authority)
    for p in changed:back['owned'][p]=copy.deepcopy(original['owned'][p])
    back['source_sha256']=copy.deepcopy(original['source_sha256']);assert back==original and enc(back)==original_raw
    assert all(authority['source_sha256'][p]==h for p,h in original['source_sha256'].items())
    execution=output('execution_successor_PREPARATION.json',enc(authority))
    # Exact fixed historical reachability remains bounded by16; do not infer
    # permission from frontier size, live source hashes, or current values.
    depths={}
    for p in changed:
        row=authority['owned'][p];depth={row['current_sha256']:0};front=[row['current_sha256']]
        for _ in range(16):
            nxt=[]
            for edge in row['edges']:
                if edge['new_sha256'] in front and edge['old_sha256'] not in depth:
                    depth[edge['old_sha256']]=depth[edge['new_sha256']]+1;nxt.append(edge['old_sha256'])
            front=nxt
        assert all(e['old_sha256'] in depth for e in row['edges']),(p,'NO_16_DEPTH_EXPANSION');depths[p]=max(depth.values())
    report=dict(status='EXACT33_TEN_CODES_SEVEN_EXISTING_OWNED_READY_FOR_ROOT_READ_NOT_STAGE',records=records,execution=dict(parent=parents[EXEC],candidate=execution,changed_existing_owned=changed,owned_count=10,prior_proof_count=139,new_proof_count=148,extra={p:h for p,h in authority['source_sha256'].items() if p not in original['source_sha256']},whole_typed_and_serialized_UTF8_inverse=True,other_three_owned_rows_unchanged=True,historical_reachable_maximum_depths=depths),contract=dict(target=CONTRACT,parent=parents[CONTRACT],candidate=contract,changed=changes,wholebyte_and_typed_inverse=True),temple_binding=dict(parent=dict(path=bp,sha256=bh),candidate=bind,changed=binding_changes,ordinary_additions={helper:hh},whole_typed_serialized_inverse=True),ordinary=dict(path=S+'ordinary_outer01_READY/whole_inverse_NOT_STAGE.json',sha256='26f9cd34b9c0aea9b782e267e3cf00ac279cea70cfe785a5055c331581d15618'),freeze=dict(path=S+'runtime_ready01/mechanical_ready_whole_inverse_NOT_STAGE.json',sha256='ab8800fb641ff707c9141fd185d02a5cb6205c47736e8dab4b1cc5c21aeaa8ad'),C_AA_nonowned=True,all_old139_keyvalues_and_edges_unchanged=True,engine_calls=0,Stage_calls=0,collector_calls=0,canonical_writes=0)
    pr=output('code_execution_whole_inverse_NOT_STAGE.json',enc(report));out.mkdir()
    for name,b in prepared:
        with (out/name).open('xb') as stream:stream.write(b)
        assert (out/name).read_bytes()==b
    print(json.dumps(dict(proof=pr,execution=execution,contract=contract,temple_binding=bind,codes=len(records),proof_leaves=148)))
if __name__=='__main__':main()
