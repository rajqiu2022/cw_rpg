"""Pure symbolic source-recipe review. Does not import or instantiate Stage.

Generated metadata SHA values use conspicuous synthetic tokens; no candidate
expected source maps, native bytes or engine/collector results are emitted.
Checks actual promote-owned-first order, exact old pointers, group conflicts,
dependency order and prospective declarations without reading media leaves.
"""
import copy
import hashlib
import json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(p,s):
    b=(G/p[6:]).read_bytes();assert sha(b)==s,('PIN_CHANGED',p);return b
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def ptr(v,ks):
    for k in ks:v=v[k]
    return v
p=S+'a2_source_recipe07/source_input_PENDING_PROMOTION.json'
spec=json.loads(fixed(p,'d87dddd72b05fc6fd025e3c9052ab0f1aa999aca916e789c15693aa84072b64a'))
inputs={r['id']:r for r in spec['pinned_inputs']}
data={}
def jsinput(i):
    if i not in data:data[i]=json.loads(fixed(inputs[i]['path'],inputs[i]['sha256']))
    return data[i]
authority=jsinput(spec['authority_input'])
groups={r['id']:r for r in spec['source_groups']}
nodes={};groupstack=set();counts=[];checks={'exact_old_pointers':0,'source_group_merges':0,'source_group_instances':0}
EXTERNAL={'res://scripts/city/luoyang_full_city_index_20261022ap.gd','res://scripts/city/luoyang_environment_index_20261022ap.gd','res://scripts/city/luoyang_execution_index_20261022ap.gd','res://scripts/city/luoyang_quarters_index_20261022ap.gd'}
def val(v):
    if isinstance(v,dict) and '$sha' in v:return nodes[v['$sha']]['sha256']
    if isinstance(v,dict) and set(v)=={'$pin'}:return inputs[v['$pin']]['sha256']
    if isinstance(v,dict) and set(v)=={'$owned'}:return authority['owned'][v['$owned']]['current_sha256']
    if isinstance(v,dict):return {k:val(x) for k,x in v.items()}
    if isinstance(v,list):return [val(x) for x in v]
    return v
def approved(p,s):
    row=authority['owned'][p];todo=[row['current_sha256']];seen=set()
    while todo:
        x=todo.pop()
        if x==s:return True
        if x in seen:continue
        seen.add(x);todo += [e['old_sha256'] for e in row['edges'] if e['new_sha256']==x]
    return False
def promote(v):
    out=copy.deepcopy(v)
    for p,s in v.items():
        if p in authority['owned']:
            assert approved(p,s),('MISSING_OWNED_EDGE',p,s)
            out[p]=authority['owned'][p]['current_sha256']
    return out
def merge(into,add):
    checks['source_group_merges']+=1
    for p,s in add.items():
        if p in into and into[p]!=s:
            assert p in authority['owned'] and approved(p,into[p]) and s==authority['owned'][p]['current_sha256'],('UNDECLARED_EXISTING_SOURCE_REPLACEMENT',p,into[p],s)
        into[p]=s
def group(i):
    assert i not in groupstack,('GROUP_CYCLE',i)
    groupstack.add(i);r=groups[i];checks['source_group_instances']+=1
    if r['kind']=='explicit':v=val(r['leaves'])
    elif r['kind']=='input_dictionary':v=copy.deepcopy(ptr(jsinput(r['input']),r['pointer']))
    elif r['kind']=='node_dictionary':v=copy.deepcopy(ptr(nodes[r['node']]['value'],r['pointer']))
    elif r['kind']=='union':
        v={}
        for child in r['groups']:merge(v,group(child))
    else:raise AssertionError(r['kind'])
    if r.get('promote_owned') is True:v=promote(v)
    groupstack.remove(i);return v
def change(v,ops):
    for op in ops:
        holder,key=ptr(v,op['pointer'][:-1]),op['pointer'][-1]
        assert (key in holder)==op['existed'],('OLD_EXISTS',op['pointer'])
        assert not op['existed'] or same(holder[key],op['old']),('EXACT_OLD_VALUE',op['pointer'],holder.get(key),op['old'])
        checks['exact_old_pointers']+=1
        if op['op']=='remove':del holder[key]
        else:holder[key]=val(op['new'])

for r in spec['nodes']:
    ident,kind=r['id'],r['kind']
    if kind=='a2_frozen_node':
        nodes[ident]={'sha256':inputs[r['base_input']]['sha256'],'value':jsinput(r['base_input']) if ident=='registry_final' else None};continue
    if kind=='index':
        # New index SHA is a symbolic dependency token, not a claimed digest.
        raw=fixed(inputs[r['base_input']]['path'],inputs[r['base_input']]['sha256']).decode()
        for h in r['replacements']:
            assert raw.count(h['old'])==1,('INDEX_OLD_NOT_UNIQUE',ident,h['old'])
            raw=raw.replace(h['old'],val(h['new']),1)
        nodes[ident]={'sha256':'SYMBOLIC_SHA:'+ident,'value':None};continue
    if kind=='map':
        original=jsinput(r['base_input']);v={'source_sha256':promote(original['source_sha256'])}
        change(v,r['operations'])
        for child in r['groups']:merge(v['source_sha256'],group(child))
        for p in r.get('remove_after_merge',[]):v['source_sha256'].pop(p,None)
        counts.append({'id':ident,'source_count_before_declared_retire':len(v['source_sha256'])})
        nodes[ident]={'sha256':'SYMBOLIC_SHA:'+ident,'value':v};continue
    original=jsinput(r['base_input']);v=copy.deepcopy(original)
    change(v,r.get('operations',[]))
    if kind=='a2_contract':
        assert same(v,jsinput(r['literal_candidate_input']))
        nodes[ident]={'sha256':inputs[r['literal_candidate_input']]['sha256'],'value':v};continue
    assert kind in ['metadata','a2_quarter'],kind
    forbidden=set(EXTERNAL)
    if r['source_policy']=='quarter':forbidden={'res://scripts/city/luoyang_full_city_index_20261022ap.gd','res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd','res://scripts/city/luoyang_quarters_index_20261022ap.gd'}
    forbidden.update(r.get('forbidden_source_paths',[]));forbidden.add(r.get('target'))
    for f in r.get('source_fields',[]):
        holder,key=ptr(v,f['pointer'][:-1]),f['pointer'][-1]
        updated=promote(holder[key]) if f.get('promote_owned') is True else copy.deepcopy(holder[key])
        for child in f.get('groups',[]):merge(updated,{p:s for p,s in group(child).items() if p not in forbidden})
        assert not set(updated)&forbidden,('FORBIDDEN_SOURCE',ident)
        holder[key]=updated
    if r.get('source_bundle'):
        bundle=r['source_bundle'];fields=bundle['fields'];updated=[promote(ptr(v,k)) for k in fields]
        for child in bundle['groups']:
            for p,s in group(child).items():
                if p in forbidden:continue
                existing=[i for i,x in enumerate(updated) if p in x]
                assert len(existing)<=1,('SOURCE_CLASSES_NOT_DISJOINT',ident,p)
                if existing:merge(updated[existing[0]],{p:s})
                else:
                    destination=bundle['default_destination']
                    for route in bundle.get('new_source_routes',[]):
                        if p.startswith(route['prefix']):destination=route['destination'];break
                    updated[fields.index(destination)][p]=s
        for ks,values in zip(fields,updated):
            assert not set(values)&forbidden,('BUNDLE_FORBIDDEN',ident)
            ptr(v,ks[:-1])[ks[-1]]=values
    for ks in r.get('protected_pointers',[]):assert same(ptr(v,ks),ptr(original,ks)),('PROTECTED_POINTER',ident,ks)
    if kind=='a2_quarter':change(v,r['a2_geometry_declaration_operations'])
    nodes[ident]={'sha256':'SYMBOLIC_SHA:'+ident,'value':v}

report={'status':'PURE_SYMBOLIC_A2_RECIPE_ORDER_AND_OLD_POINTERS_NOT_STAGE_OR_EXPECTED_DIGESTS','input':{'path':p,'sha256':'d87dddd72b05fc6fd025e3c9052ab0f1aa999aca916e789c15693aa84072b64a'},'all_nodes_in_source_dependency_order':True,'all_exact_old_values_checked_in_actual_promote_then_operation_order':True,'source_groups_no_undeclared_existing_replacement':True,'counts_only_not_expected_SHA_maps':counts,'checks':checks,'symbolic_metadata_SHA_tokens_not_exported_as_expected_values':True,'engine_Stage_import_native_decode_collector_or_canonical_writes':0}
out=H/'a2_source_recipe07'/'symbolic_order_and_oldpointer_review_READY.json'
assert not out.exists()
b=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f:f.write(b)
print(json.dumps({'review':S+'a2_source_recipe07/symbolic_order_and_oldpointer_review_READY.json','sha256':sha(b),'checks':checks,'counts':counts}))
