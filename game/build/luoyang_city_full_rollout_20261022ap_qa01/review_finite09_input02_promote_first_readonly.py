"""Independent pure JSON real-order check, no imported compiler or writes except NEW QA report."""
import copy,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
S=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
OUT=Path(__file__).with_name('finite09_input02_independent_promote_first_review_READY.json')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):
    assert p.startswith('res://');v=(ROOT/p[6:]).resolve();assert v.is_relative_to(ROOT);return v
def load(p):return json.loads(p.read_bytes())
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
old=S/'finite09_input01_ROOT_LOCKED.json';new=S/'finite09_input02_ROOT_LOCKED.json'
assert sha(old)=='498fc80eeedb9e443631b3e01d196491acacda5101eadc15fe0b9f5cd22d21cb'
assert sha(new)=='eaed904ce017d9e801b51165e0be2598c8646df53c5938d91eba54b36e908972'
a,b=load(old),load(new);back=copy.deepcopy(b)
auth=load(S/'finite_adapter_production08/execution_successor_PROPOSAL.json')
assert sha(S/'finite_adapter_production08/execution_successor_PROPOSAL.json')=='c668a0be6bc051237857dc4d2822308077a808a800f51a27f04f8b75c75f8405'
owned=auth['owned'];pins={r['id']:r for r in b['pinned_inputs']}
def promote(d):
    d=copy.deepcopy(d)
    for p,oldsha in list(d['source_sha256'].items()):
        if p not in owned:continue
        row=owned[p];seen={row['current_sha256']};front=list(seen)
        while front:
            at=front.pop()
            for edge in row['edges']:
                if edge['new_sha256']==at and edge['old_sha256'] not in seen:
                    seen.add(edge['old_sha256']);front.append(edge['old_sha256'])
        assert oldsha in seen,('source history not authority-reachable',p)
        d['source_sha256'][p]=row['current_sha256']
    return d
def value(x):
    if isinstance(x,dict) and set(x)=={'$owned'}:return owned[x['$owned']]['current_sha256']
    if isinstance(x,dict) and set(x)=={'$pin'}:return pins[x['$pin']]['sha256']
    # Final generated node hashes are deliberately symbolic here, not taken
    # from a stage/collector observation. Both recipes must agree exactly.
    if isinstance(x,dict) and '$sha' in x:return {'FIXED_NODE_SHA_SYMBOL':x['$sha'],'variant':x.get('variant')}
    if isinstance(x,dict):return {k:value(v) for k,v in x.items()}
    if isinstance(x,list):return [value(v) for v in x]
    return x
def change(d,ops):
    d=copy.deepcopy(d)
    for op in ops:
        holder=d
        for key in op['pointer'][:-1]:holder=holder[key]
        k=op['pointer'][-1];assert (k in holder)==op['existed']
        if k in holder:assert same(holder[k],op['old']),('true order old mismatch',op['pointer'])
        if op['op']=='remove':del holder[k]
        else:assert op['op']=='set';holder[k]=value(op['new'])
    return d
rows=[]
for i,row in enumerate(a['nodes']):
    if row['kind']!='map':continue
    nxt=b['nodes'][i];assert nxt['id']==row['id']
    removed=[op for op in row['operations'] if op['pointer'][1] in owned]
    expected=[op for op in row['operations'] if op['pointer'][1] not in owned]
    assert same(nxt['operations'],expected)
    seed=pins[row['base_input']];p=res(seed['path']);assert sha(p)==seed['sha256']
    raw={'source_sha256':load(p)['source_sha256']}
    for op in removed:
        path=op['pointer'][1]
        assert op['op']=='set' and op['existed'] is True
        assert raw['source_sha256'][path]==op['old']
        assert value(op['new'])==owned[path]['current_sha256']
    intended=promote(change(raw,row['operations']))
    corrected_real_order=change(promote(raw),nxt['operations'])
    assert same(intended,corrected_real_order)
    rows.append({'scene_id':row['scene_id'],'removed_redundant_owned_sets':len(removed),'baseline_sha256':seed['sha256'],'all_nonowned_operations_and_groups_unchanged':same(row['groups'],nxt['groups']),'pre_group_complete_typed_dictionary_equal':True})
    back['nodes'][i]['operations']=copy.deepcopy(row['operations'])
assert [r['removed_redundant_owned_sets'] for r in rows]==[4,4,5,5]
assert sum(r['removed_redundant_owned_sets'] for r in rows)==18
assert b['output_root'].endswith('/outputs/root_finite09_two_domain_stage02/')
back['output_root']=a['output_root']
assert 'finite09_actual01_failure_preserved' in back;del back['finite09_actual01_failure_preserved']
assert same(back,a),'No other input changes'
assert not res(b['output_root']).exists() and not OUT.exists()
report={'status':'INDEPENDENT_REAL_PROMOTE_FIRST_JSON_REVIEW_NOT_STAGE_ACTUAL','input_path':'res://'+new.relative_to(ROOT).as_posix(),'input_sha256':sha(new),'unchanged_tool_scope_code_native_and_all_other_input_typed_inverse':True,'maps':rows,'only18_owned_sets_removed':True,'nonowned_C_Fade_Resident_operations_not_deleted':True,'all_groups_unchanged_so_equal_final_maps_inherit_same_merge':True,'observed_09_stage01_failure_preserved_not_relabelled':True,'compiler_runs':0,'engine_runs':0,'collector_calls':0,'native_or_PNG_decode':0,'canonical_writes':0}
OUT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review_path':'res://'+OUT.relative_to(ROOT).as_posix(),'review_sha256':sha(OUT),'maps':4,'redundant_ops':18,'compiler_run':False}))
