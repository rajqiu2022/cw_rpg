"""Only Router syntax and its strict source-literal dependency successors."""
from pathlib import Path
import json,hashlib,copy,importlib.util
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024e_source01/';N='res://build/luoyang_city_blocks_20261024e_system01/'
ROUTER='res://scripts/autoload/scene_router.gd';CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';COORD='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';TEMPLE='res://scripts/city/luoyang_temple_assembly_20261016.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),(p,sha(b));return b
def exact(b,a,c):
    a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1;return b.replace(a,c,1)
def main():
    module_spec=importlib.util.spec_from_file_location('fixed_outer',HERE/'prepare_ordinary_outer01_BUILD.py');m=importlib.util.module_from_spec(module_spec);module_spec.loader.exec_module(m)
    parentproof=S+'dependencies33_READY/code_execution_whole_inverse_NOT_STAGE.json';parent_sha='d6b4c0afcaac7f8f29ca8c15b7412abafa90ad7418c4106a8d113622c715913e';prior=json.loads(read(parentproof,parent_sha));proof=copy.deepcopy(prior)
    router_proof=N+'Router04_parse_receiver_exact_inverse_BUILD.json';router_pin='87fa3fbf37f0be1633d329d35265a1bd111e5ff7fb3fff1fb15d0362a410d8da';rp=json.loads(read(router_proof,router_pin));rb=read(rp['candidate']['path'],rp['candidate']['sha256']);oldr=prior['records'][ROUTER];assert rp['parent']['sha256']==oldr['candidate']['sha256'] and rb.count(b'\r')==13
    assert exact(read(rp['parent']['path'],rp['parent']['sha256']),rp['replacements'][0]['old'],rp['replacements'][0]['new'])==rb
    out=HERE/'Router_receiver_residual02_READY';assert not out.exists();prefix=S+'Router_receiver_residual02_READY/';prepared=[]
    def output(name,b):
        prepared.append((name,b));return dict(path=prefix+name,sha256=sha(b),bytes=len(b))
    def record(p,candidate,b):
        parent=prior['records'][p]['parent'];a=read(parent['path'],parent['sha256']);ops=m.hunks(a,b);proof['records'][p]=dict(name=prior['records'][p]['name'],parent=parent,candidate=candidate,hunks=ops,wholebyte_forward_inverse=True)
    record(ROUTER,rp['candidate'],rb)
    old_contract=prior['contract']['candidate'];ocb=read(old_contract['path'],old_contract['sha256']);cb=exact(ocb,oldr['candidate']['sha256'],rp['candidate']['sha256']);ct=output('runtime_contract_C_Field_Router_CANDIDATE.json',cb)
    assert json.loads(cb)['source_sha256'][ROUTER]==rp['candidate']['sha256'];proof['contract']['candidate']=ct;proof['contract']['changed'][ROUTER]['new_sha256']=rp['candidate']['sha256']
    old_coord=prior['records'][COORD]['candidate'];coordb=exact(read(old_coord['path'],old_coord['sha256']),old_contract['sha256'],ct['sha256']);coord=output('Coordinator_CANDIDATE.gd',coordb);record(COORD,coord,coordb)
    old_bind=prior['temple_binding']['candidate'];bb=read(old_bind['path'],old_bind['sha256']);binding=json.loads(bb);changed={ROUTER:(oldr['candidate']['sha256'],rp['candidate']['sha256']),COORD:(old_coord['sha256'],coord['sha256']),CONTRACT:(old_contract['sha256'],ct['sha256'])}
    for p,(a,b) in changed.items():
        assert binding['source_delta'][p]==a;bb=exact(bb,json.dumps(p)+': '+json.dumps(a),json.dumps(p)+': '+json.dumps(b));binding['source_delta'][p]=b;proof['temple_binding']['changed'][p]['new_sha256']=b
    assert json.loads(bb)==binding;bind=output('Temple_binding_C_Field_Router_Coord_contract_CANDIDATE.json',bb);proof['temple_binding']['candidate']=bind
    oldt=prior['records'][TEMPLE]['candidate'];tb=exact(exact(read(oldt['path'],oldt['sha256']),old_bind['path'],bind['path']),old_bind['sha256'],bind['sha256']);temple=output('Temple_CANDIDATE.gd',tb);record(TEMPLE,temple,tb)
    ep=prior['execution']['parent'];eraw=read(ep['path'],ep['sha256']);original=json.loads(eraw);authority=copy.deepcopy(original)
    for p in prior['execution']['changed_existing_owned']:
        row=authority['owned'][p];r=proof['records'][p];snap=next(e['new_snapshot'] for e in row['edges'] if e['new_sha256']==row['current_sha256'])
        row['edges'].append(dict(path=p,old_sha256=row['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snap,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));row['current_sha256']=r['candidate']['sha256'];authority['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
    for r in [ct,bind]:authority['source_sha256'][r['path']]=r['sha256']
    assert len(authority['owned'])==10 and len(authority['source_sha256'])==148 and all(authority['source_sha256'][p]==h for p,h in original['source_sha256'].items())
    back=copy.deepcopy(authority)
    for p in prior['execution']['changed_existing_owned']:back['owned'][p]=copy.deepcopy(original['owned'][p])
    back['source_sha256']=copy.deepcopy(original['source_sha256']);assert back==original and enc(back)==eraw
    execution=output('execution_successor_PREPARATION.json',enc(authority));proof['execution']['candidate']=execution;proof['execution']['extra']={p:h for p,h in authority['source_sha256'].items() if p not in original['source_sha256']}
    proof['status']='ROUTER_RECEIVER_SYNTAX_ONLY_EXACT_SOURCE_RESIDUAL_NOT_STAGE';proof['residual_parent']=dict(path=parentproof,sha256=parent_sha);proof['residual_router_inverse']=dict(path=router_proof,sha256=router_pin);proof['unchanged_code_candidates']=[p for p in proof['records'] if p not in [ROUTER,COORD,TEMPLE]]
    # Strict full forward and the original core's forward-ordered inverse both
    # pass for these disjoint small hunks; no replacement-order relaxation.
    for p,r in proof['records'].items():
        a=read(r['parent']['path'],r['parent']['sha256']);b=next((raw for name,raw in prepared if prefix+name==r['candidate']['path']),None)
        if b is None:b=read(r['candidate']['path'],r['candidate']['sha256'])
        m.inverse(a,b,r['hunks']);back=b
        for h in r['hunks']:back=exact(back,h['new'],h['old'])
        assert back==a
    pr=output('code_execution_whole_inverse_NOT_STAGE.json',enc(proof));out.mkdir()
    for name,b in prepared:
        with (out/name).open('xb') as stream:stream.write(b)
        assert (out/name).read_bytes()==b
    print(json.dumps(dict(proof=pr,execution=execution,router=rp['candidate'],contract=ct,Coordinator=coord,Temple=temple)))
if __name__=='__main__':main()
