"""Future Root actual-stage byte review and independent owner-table recipe.

PREPARED ONLY. Do not run before Root gives the actual receipt SHA. This script
never imports a Stage or calls Godot/collectors. Unchanged source leaves inherit
fixed1292; changed values come only from the frozen plan and actual candidate
bytes. Per-room receipt dictionaries remain distinct from G's whole collector.
"""
import argparse,copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
OUT=S+'performance08_actual_independent_review/'
PRIOR=S+'a2_source_recipe08/actual_independent_review/owner_source_maps_READY.json'
PRIOR_SHA='12924be9ea2c6a081b4865354d40075caa10e3804ad6c942e972f0270bd5219a'
HAND=S+'performance05_dependencies/handoff_PRODUCTION_PROPOSAL.json'
HAND_SHA='2140f39a3c61f87f089256b670f941b11a925c9b30f300e63d56c55a8acec3c7'
HASH='res://scripts/city/luoyang_parallel_source_hash_20261017k.gd'
REG='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
DT='res://scripts/city/luoyang_district_life_20261016f.gd'
sha=lambda b:hashlib.sha256(b).hexdigest()
def raw(p,s):
    assert p.startswith('res://') and '..' not in p
    b=(G/p[6:]).read_bytes();assert sha(b)==s,('PIN_CHANGED',p);return b
def read(p,s):return json.loads(raw(p,s))
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def ptr(v,ks):
    for k in ks:v=v[k]
    return v
def restore(v,deltas):
    for d in reversed(deltas):
        obj,key=ptr(v,d['pointer'][:-1]),d['pointer'][-1]
        if d['existed']:obj[key]=d['old']
        else:del obj[key]
def merge(*maps):
    out={}
    for rows in maps:
        for p,s in rows.items():assert p not in out or out[p]==s,(p,out.get(p),s);out[p]=s
    return out

def main():
    ap=argparse.ArgumentParser()
    for arg in ['plan','plan-sha256','receipt','sha256']:ap.add_argument('--'+arg,required=True)
    args=ap.parse_args()
    assert args.plan.startswith(S+'performance') and args.plan.endswith('/source_input_ROOT_LOCKED.json')
    assert args.receipt==S+'outputs/root_performance05_source_stage01/receipt.json'
    assert not (G/OUT[6:]).exists()
    actual=read(args.receipt,args.sha256);plan=read(args.plan,args.plan_sha256)
    assert actual['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED' and actual['source_first']==actual['source_final']
    assert actual['source_first'][args.plan]==args.plan_sha256
    assert actual['target_partition']=={'patch_count':12,'copy_count':14,'total':26,'intersection_empty':True,'union_exact_targets':True}
    old=read(PRIOR,PRIOR_SHA);hand=read(HAND,HAND_SHA)
    inputs={r['id']:r for r in plan['pinned_inputs']};c=plan['performance_contract']
    request=read(inputs[c['scope_request_input']]['path'],inputs[c['scope_request_input']]['sha256'])
    targets={r['target']:r for r in actual['targets']}
    assert len(targets)==26 and set(targets)==set(plan['root_target_allowlist'])=={r['target'] for r in request['targets']}
    expected_old={r['target']:r['old_sha256'] for r in request['targets']}
    for p,r in targets.items():
        assert r['old_sha256']==expected_old[p] and r['old_sha256']!=r['candidate_sha256']
        raw(r['candidate_path'],r['candidate_sha256'])
    nodes=actual['nodes'];typed=[];indices=[]
    for n in plan['nodes']:
        ident=n['id'];v=nodes[ident];data=raw(v['path'],v['sha256'])
        if n['kind']=='metadata':
            prior=read(inputs[n['base_input']]['path'],inputs[n['base_input']]['sha256'])
            inv=copy.deepcopy(v['value']);restore(inv,actual['proofs'][ident]['source_delta'])
            assert same(inv,prior) and same(json.loads(data),v['value']),('WHOLE_TYPED_METADATA_INVERSE',ident)
            typed.append(ident)
        elif n['kind']=='index':
            proof=actual['proofs'][ident];assert proof['disabled_to_enabled_sole_bool_whole_inverse'] is True
            before=raw(inputs[n['base_input']]['path'],inputs[n['base_input']]['sha256']);disabled=before.decode();resolved=[]
            for h in n['replacements']:
                literal=h['new']
                if isinstance(literal,dict) and '$sha' in literal:literal=nodes[literal['$sha']]['sha256']
                elif isinstance(literal,dict) and '$pin' in literal:literal=inputs[literal['$pin']]['sha256']
                assert isinstance(literal,str) and disabled.count(h['old'])==1
                disabled=disabled.replace(h['old'],literal,1);resolved.append((h['old'],literal))
            assert sha(disabled.encode())==proof['disabled_sha256'] and disabled.count(n['disabled_literal'])==1
            assert disabled.replace(n['disabled_literal'],n['enabled_literal'],1).encode()==data
            inv=disabled
            for old_literal,new_literal in reversed(resolved):
                assert inv.count(new_literal)==1;inv=inv.replace(new_literal,old_literal,1)
            assert inv.encode()==before;indices.append(ident)
        elif n['kind']=='performance_frozen_node':
            assert v['sha256']==inputs[n['base_input']]['sha256'] and 'target' not in n
    for row in hand['consumers']:
        inv=raw(row['candidate']['path'],row['candidate']['sha256']).decode()
        for h in row['inverse_replacements']:
            assert inv.count(h['new'])==1;inv=inv.replace(h['new'],h['old'],1)
        assert inv.encode()==raw(row['parent_snapshot']['path'],row['parent_snapshot']['sha256'])
    def replace(values):
        out=copy.deepcopy(values)
        for p,r in targets.items():
            if p in out:
                assert out[p]==r['old_sha256'],('EXACT_INHERITED1292_OLD_VALUE',p,out[p],r['old_sha256'])
                out[p]=r['candidate_sha256']
        return out
    previous={r['id']:r for r in old['scenes']};scenes=[]
    for n in plan['nodes']:
        if n['kind']=='map':
            row=copy.deepcopy(previous[n['scene_id']]);src=copy.deepcopy(nodes[n['id']]['value']['source_sha256'])
            row.update(source_sha256=src,receipt_source_sha256=copy.deepcopy(src),recipe='Frozen AO source map recipe through unchanged imported validator; actual AP11 parents plus explicit26 source/header succession, nonowned hash setter and three owned promotion; no observed collector values')
            scenes.append(row)
    quarter=nodes['quarter_final']
    headerset=['res://scripts/city/luoyang_quarters_family_20261022ap.gd','res://scripts/city/luoyang_quarters_index_20261022ap.gd','res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json']
    for ident,native in quarter['value']['scenes'].items():
        row=copy.deepcopy(previous[ident]);headers=replace({p:row['source_sha256'][p] for p in headerset})
        row.update(source_sha256=merge(quarter['value']['source_sha256'],headers),receipt_source_sha256=copy.deepcopy(quarter['value']['source_sha256']),recipe='Fixed1292 Quarter native identities plus source-only manifest67proof/header succession; full collector versus receipt domains remain separate')
        assert row['scene_path']==native['scene_path'] and row['layout_path']==native['layout_path']
        scenes.append(row)
    ident='luoyang_estate_riverside_20261021ai';row=copy.deepcopy(previous[ident]);estate=nodes['estate_final']
    headers=replace({p:s for p,s in row['source_sha256'].items() if p not in row['receipt_source_sha256']})
    assert len(estate['value']['source_sha256'])==len(row['receipt_source_sha256'])==331
    row.update(source_sha256=merge(estate['value']['source_sha256'],headers),receipt_source_sha256=copy.deepcopy(estate['value']['source_sha256']),recipe='Fixed331 Estate source keys with exact B/DT and registry source successor; no shared groups or native changes')
    scenes.append(row)
    ident='ch4_s4_ancient_temple';row=copy.deepcopy(previous[ident])
    assert row['source_sha256'][HASH]=='80261e1bf9b34400c6aa99959d98502b648589fccf2138231f3907d9826d8b0b'
    src=merge(replace(row['source_sha256']),hand['new_proof_pins'])
    row.update(source_sha256=src,receipt_source_sha256=copy.deepcopy(src),recipe='Fixed1292 complete Temple source domain plus exact target/header replacement and four new execution proof declarations; direct hash binding changed one of189, not geometry')
    scenes.append(row)
    registry=nodes['registry_final']['value'];rooms=[]
    for original in old['rooms']:
        row=copy.deepcopy(original);src=merge(replace(row['source_sha256']),hand['new_proof_pins'])
        receipt=copy.deepcopy(registry['rooms'][row['id']]['source_sha256'])
        assert same(receipt,replace(row['receipt_source_sha256'])),('ONLY_DECLARED_ROOM_DT_RECEIPT_CHANGE',row['id'])
        assert set(receipt)==set(row['receipt_source_sha256']) and receipt[DT]==targets[DT]['candidate_sha256']
        row.update(source_sha256=src,receipt_source_sha256=receipt,recipe='Fixed1292 G-family complete collector plus precise target/header/four-proof successor; independent per-room receipt changes only canonical DT value, room native/return exact')
        rooms.append(row)
    assert len(scenes)==8 and len(rooms)==5
    oldunion=merge(*(r[f] for r in old['scenes']+old['rooms'] for f in ['source_sha256','receipt_source_sha256']))
    union=merge(*(r[f] for r in scenes+rooms for f in ['source_sha256','receipt_source_sha256']))
    changed=declared=inherited=0
    for p,s in union.items():
        if p in targets:assert targets[p]['candidate_sha256']==s;changed+=1
        elif p in actual['source_first']:assert actual['source_first'][p]==s;declared+=1
        else:assert oldunion.get(p)==s,('UNDECLARED_NEW_EXPECTATION',p);inherited+=1
    core=copy.deepcopy(old['core_source_sha256']);core.update({p:r['candidate_sha256'] for p,r in targets.items()})
    owner={'status':'ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS','actual_stage_receipt':{'path':args.receipt,'sha256':args.sha256},'core_source_sha256':core,'scenes':scenes,'rooms':rooms,'fixed_prior_owner_sha256':PRIOR_SHA,'expected_not_derived_from_live_collector_or_canonical_hash_crawl':True,'not_Field_or_runtime_credit':True,'metadata_fields_not_invented':'All1292 native scene/layout/worldsize values inherited. QA retains its frozen geometry/NPC/visual oracles; source-only performance successor has no new geometry.'}
    def emit(name,value):
        dest=G/(OUT+name)[6:];assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True)
        data=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
        with dest.open('xb') as f:f.write(data)
        return {'path':OUT+name,'sha256':sha(data)}
    desc=emit('owner_source_maps_READY.json',owner)
    review=emit('source_stage_review_READY.json',{'status':'INDEPENDENT26_BYTE_TYPED_FIXED1292_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT','actual_stage_receipt':owner['actual_stage_receipt'],'owner_source_maps':desc,'source_first_final_same':True,'actual_stage_source_count':len(actual['source_first']),'target_count':26,'partition':actual['target_partition'],'typed_inverse_nodes':typed,'index_byte_inverse_nodes':indices,'expected_union_count':len(union),'changed_target_leaves':changed,'matched_actual_stage_source_declarations':declared,'unchanged_inherited1292_leaves_not_rehashed':inherited,'scene_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])} for r in scenes},'room_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])} for r in rooms},'engine_collector_Stage_native_decode_calls':0})
    print(json.dumps({'owner':desc,'review':review}))
if __name__=='__main__':main()
