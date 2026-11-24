"""Independent read-only final DAG check. Never imports or runs the stager."""
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
S = ROOT / 'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
OUT = Path(__file__).with_name('artisan_a2_final_source07_input08_independent_static_review_READY.json')
def digest(b): return hashlib.sha256(b).hexdigest()
def path(p):
    assert p.startswith('res://')
    q = (ROOT / p[6:]).resolve()
    assert q.is_relative_to(ROOT)
    return q
def load(p): return json.loads(p.read_bytes())
def equal(a,b):
    if type(a) is not type(b): return False
    if isinstance(a,dict): return a.keys()==b.keys() and all(equal(a[k],b[k]) for k in a)
    if isinstance(a,list): return len(a)==len(b) and all(equal(x,y) for x,y in zip(a,b))
    return a==b
def at(v,ks):
    for k in ks: v=v[k]
    return v

specpath=S/'a2_source_recipe08/source_input_ROOT_LOCKED.json'
toolpath=S/'stage_a2_source07_READY.py'
assert digest(specpath.read_bytes())=='7481f547419cda9282ae6cb9566421353d21e09c0a23b45ecd6bb919242fa23a'
assert digest(toolpath.read_bytes())=='6dd7ff3b39841461d1c6573bbd60230e8afce578dbfdc271c7604e71e0152920'
spec=load(specpath)
pins={r['id']:r for r in spec['pinned_inputs']}
assert len(pins)==len(spec['pinned_inputs'])==51
first={}
for r in pins.values():
    b=path(r['path']).read_bytes(); assert digest(b)==r['sha256']; first[r['path']]=digest(b)
def inp(k): return load(path(pins[k]['path']))
authority=inp(spec['authority_input'])
scope=inp('a2_root_scope');request=inp('a2_scope_request')
targets={r['target']:r for r in request['targets']}
assert len(targets)==28 and set(targets)==set(spec['root_target_allowlist'])
declared=[r['target'] for r in spec['pass_through_targets']]+[r['target'] for r in spec['nodes'] if 'target' in r]
assert len(declared)==len(set(declared))==28 and set(declared)==set(targets)
assert sum(p.endswith('.gd') for p in declared)==14 and sum(p.endswith('.json') for p in declared)==14
for p,r in targets.items():
    assert digest(path(p).read_bytes())==r['old_sha256']
    assert path(p).read_bytes()==path(r['old_snapshot']).read_bytes()
assert {r['target']:r['old_sha256'] for r in scope['targets']}=={p:r['old_sha256'] for p,r in targets.items()}
for r in scope['targets']:
    b=Path(r['backup_path']).read_bytes();assert digest(b)==r['backup_sha256']==r['old_sha256']
for r in spec['prospective_targets']:
    assert digest(path(r['candidate_path']).read_bytes())==r['sha256']
for r in spec['pass_through_targets']:
    assert digest(path(r['candidate_path']).read_bytes())==r['candidate_sha256']

nodes={r['id']:r for r in spec['nodes']}; groups={r['id']:r for r in spec['source_groups']}
assert len(nodes)==27 and len(groups)==48
seen=set(); visiting=set(); edges=[]
def refs(v):
    if isinstance(v,dict):
        if '$sha' in v: yield ('n',v['$sha'])
        for x in v.values(): yield from refs(x)
    elif isinstance(v,list):
        for x in v: yield from refs(x)
def walk(kind,ident):
    key=(kind,ident)
    assert key not in visiting,('cycle',key)
    if key in seen:return
    visiting.add(key)
    row=(nodes if kind=='n' else groups)[ident]
    deps=list(refs(row))
    if kind=='g':
        deps += [('g',g) for g in row.get('groups',[])]
        if row['kind']=='node_dictionary':deps.append(('n',row['node']))
    else:
        deps += [('g',g) for g in row.get('groups',[])]
        for f in row.get('source_fields',[]):deps += [('g',g) for g in f.get('groups',[])]
        deps += [('g',g) for g in row.get('source_bundle',{}).get('groups',[])]
    for d in deps: edges.append([key,d]);walk(*d)
    visiting.remove(key);seen.add(key)
for ident in nodes:walk('n',ident)

def promote(v):
    out=copy.deepcopy(v)
    for p in out:
        if p in authority['owned']:out[p]=authority['owned'][p]['current_sha256']
    return out
def val(v):
    if isinstance(v,dict):
        if '$sha' in v:return '@node:'+v['$sha']+(':'+v['variant'] if 'variant'in v else '')
        if set(v)=={'$pin'}:return pins[v['$pin']]['sha256']
        if set(v)=={'$owned'}:return authority['owned'][v['$owned']]['current_sha256']
        return {k:val(x) for k,x in v.items()}
    if isinstance(v,list):return [val(x) for x in v]
    return v
oldpointers=0
for row in spec['nodes']:
    if row['kind']=='a2_frozen_node':
        assert row['id'] in ('registry_final','ap_environment_index') and 'target' not in row
        assert pins[row['base_input']]['sha256']==row['immutable_sha256']
        continue
    if row['kind']=='index':
        text=path(pins[row['base_input']]['path']).read_text(encoding='utf-8')
        for h in row['replacements']:
            assert text.count(h['old'])==1,(row['id'],h['old'])
            text=text.replace(h['old'],str(val(h['new'])),1)
        continue
    value=inp(row['base_input'])
    if row['kind']=='map':value={'source_sha256':promote(value['source_sha256'])}
    for op in row.get('operations',[])+row.get('a2_geometry_declaration_operations',[]):
        holder=at(value,op['pointer'][:-1]);k=op['pointer'][-1]
        assert (k in holder)==op['existed'],(row['id'],op)
        assert k not in holder or equal(holder[k],op['old']),(row['id'],op['pointer'])
        if op['op']=='remove':del holder[k]
        else:holder[k]=val(op['new'])
        oldpointers+=1

q=nodes['quarter_final'];qbase=inp(q['base_input']);binding=inp('a2_binding')
ops=q['a2_geometry_declaration_operations']
assert len(ops)==4
for field,suffix,op in zip(('scene_path','layout_path','packet_path'),('scene.res','layout.res','packet.bin'),ops):
    assert op['pointer']==['scenes','luoyang_artisan_residential_20261022ap',field]
    assert op['old']==qbase['scenes']['luoyang_artisan_residential_20261022ap'][field]
    assert op['new']==binding['child'][suffix]['path']
assert ops[3]['pointer']==['a2_artisan_successor'] and not ops[3]['existed']
lineage=inp('docks22_lineage')['source_sha256'];g=next(r for r in spec['source_groups'] if r['id']=='unified_docks22')
expected=copy.deepcopy(lineage);family='res://scripts/city/luoyang_quarters_family_20261022ap.gd'
expected[family]='58e6d986ce26142ca2c3a852bae4ede3e01a28892ebe594512d3106c59b2204f'
assert equal(val(g['leaves']),expected) and len(expected)==22
y=nodes['finite08_yamen'];yb=inp(y['base_input'])
assert pins[y['base_input']]['sha256']=='ed4cee9e730f96af624354dd08ad6d8875259ba38827fc96df0c493da44c1794'
assert y['source_bundle']['new_source_routes'][0]['destination']==['runtime_authority_sha256']
bad=[p for p in yb['legacy_source_sha256'] if p.startswith('res://data/maps/luoyang_layout_bundle_20261018t_retry2/')]
assert not bad
assert ['mask_sha256'] in y['protected_pointers'] and ['parent_publication'] in y['protected_pointers']
a2=groups['a2_declared_native_material_proofs']['leaves']
for p,s in binding['source_sha256'].items():assert a2[p]==s,(p,'binding leaf omitted')
walk='res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/output_crossings6/native/walk.png'
for p,s in [(walk+'.import','b72003ea99c91ebe744bee65218c5d37f72ff87a3a28668cc7f576bcd430b7f2'),('res://.godot/imported/walk.png-aa86f43aaf14f1c61fc40a8827e9e3f1.ctex','f583203a326a4750428a0a6689c7d35dadd749408eb051c8bb1d6200cb9293a8')]:
    assert a2[p]==s and digest(path(p).read_bytes())==s
assert equal(inp('a2_mask_promotion_actual'),spec['a2_contract']['mask_promotion_gate']['equals'])
tool=toolpath.read_text(encoding='utf-8')
for literal in ['OLD57_UNCHANGED_PLUS_EXACT6','GARDEN_ALL_PATHS_CONNECTIONS_SEED_UNCHANGED','A2_DECLARATION_WHOLE_TYPED_INVERSE','ALL_OUTPUTS_BUFFERED_UNTIL_PREFLIGHT_PASSED','PATCH14_COPY14_EXACT_DISJOINT_UNION28']:
    assert literal in tool
assert "if __name__=='__main__':main()" in tool
assert all(digest(path(p).read_bytes())==s for p,s in first.items())
result={'status':'INDEPENDENT_FINAL_A2_DAG_STATIC_REVIEW_NOT_STAGE_OR_RUNTIME','input':{'path':'res://'+specpath.relative_to(ROOT).as_posix(),'sha256':digest(specpath.read_bytes())},'stager':{'path':'res://'+toolpath.relative_to(ROOT).as_posix(),'sha256':digest(toolpath.read_bytes())},'pinned_inputs_first_final_current_exact':len(first),'exact_Root_scope_targets':28,'partition':{'GD_patch':14,'generated_JSON_bytecopy':14},'fixed_old_pointer_and_index_literal_checks':oldpointers,'acyclic_node_group_pairs':len(seen),'dependency_edges':len(edges),'frozen_noop_registry_and_ENVindex_not_targets':True,'Docks22_only_Family_explicit_successor':True,'Yamen_ED4C_sourceclass_and_fixed_native_mask_parent_protected':True,'Quarter_exact_Artisan_three_paths_plus_one_binding_only':True,'Root15_actual_two_media_now_present_exact':True,'media_readonly_review_83F2_ABSENT_scope':'historical pre-promotion only','old_native_geometry_publication_ART_and_04_execution_review':'inherited frozen receipts, not rerun','static_findings':[],'limits':{'stager_import_or_execution':False,'engine_parse_import_GPU':False,'PNG_ctex_native_decode':False,'geometry_or_collector':False,'canonical_write':False,'actual_stage_or_Field_pass_credit':False},'next':'Root only actual stage; independently review its output before final Field key owner lock.'}
assert not OUT.exists()
OUT.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'path':str(OUT),'sha256':digest(OUT.read_bytes()),'old_pointer_checks':oldpointers}))
