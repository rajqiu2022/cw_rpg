"""Independent source-only review. Does not import/run any compiler."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
S=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
OUT=Path(__file__).with_name('finite09_source_dag_independent_static_review_READY.json')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):
    assert p.startswith('res://')
    v=(ROOT/p[6:]).resolve();assert v.is_relative_to(ROOT);return v
def load(p):return json.loads(p.read_bytes())
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def fact(p):return {'path':'res://'+p.relative_to(ROOT).as_posix(),'sha256':sha(p)}
old=S/'finite08_input01_ROOT_LOCKED.json';new=S/'finite09_input01_ROOT_LOCKED.json'
assert sha(old)=='18fd1b4f97de05a28612fa206c402e84dc0ede6deec9b7b9c60ca74e5aca850e'
assert sha(new)=='498fc80eeedb9e443631b3e01d196491acacda5101eadc15fe0b9f5cd22d21cb'
a,b=load(old),load(new);back=copy.deepcopy(b)
registry='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
assert b['root_target_allowlist']==a['root_target_allowlist']+[registry]
assert b['nodes'][1]['target']==registry
assert b['nodes'][1]['old_sha256']=='69602933f93d6c0ede6feb2a8e3c1f355a224017bb59c638440135e42e7634f6'
del back['nodes'][1]['target'];del back['nodes'][1]['old_sha256']
assert same(back['nodes'][1],a['nodes'][1])
for idx,domain,ctex in [(24,'yamen','83913bd6be2721f8f618ce44eb12f575'),(26,'market','5a109c3389acd4d8723a967a01d33772')]:
    assert b['nodes'][idx]['runtime_media_roots'][:-1]==a['nodes'][idx]['runtime_media_roots']
    assert b['nodes'][idx]['runtime_media_roots'][-1]=={'path':'res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/output/'+domain+'/walk.png','compiled_paths':['res://.godot/imported/walk.png-'+ctex+'.ctex']}
    back['nodes'][idx]['runtime_media_roots']=copy.deepcopy(a['nodes'][idx]['runtime_media_roots'])
assert b['finite08_contract']['canonical_target_count']==29
assert b['repair_epoch_contract']['exact28_new_scope'] is False and b['repair_epoch_contract']['exact29_new_scope'] is True
assert b['output_root'].endswith('/outputs/root_finite09_two_domain_stage01/')
for key in ['root_target_allowlist','finite08_contract','repair_epoch_contract','output_root','root_lock_scope','required_generator']:
    back[key]=copy.deepcopy(a[key])
assert len(a['pinned_inputs'])==len(b['pinned_inputs'])==47
for idx in [41,43,46]:
    assert b['pinned_inputs'][idx]['id']==a['pinned_inputs'][idx]['id']
    back['pinned_inputs'][idx]=copy.deepcopy(a['pinned_inputs'][idx])
assert len(b['finite09_changes_from_unexecuted18FD'])==5
del back['finite09_changes_from_unexecuted18FD']
assert same(back,a), 'Whole typed inverse: no unreviewed input changes'

tool=S/'stage_finite09_READY.py';wrap=S/'stage_finite09_scope01_READY.py'
assert sha(tool)=='b8d88ade54c74554cd76e8a3aa2e0a1ce72b8fb55519c526bf4d15d33f393b52'
assert sha(wrap)=='4b03f35031ac978ffba7dfba25e2dea104f080e502adbbdeef1b5c3ad90ba0fb'
proof=load(S/'finite09_tool_review/exact_successor_to1177_READY.json')
assert len(proof['explicit_replacements'])==12
text=tool.read_text(encoding='utf-8')
block=text.split('    def _fixed_runtime_buffer',1)[1].split('    def build_node',1)[0]
assert "allowed={d['runtime_manifest_path'] for d in self.binding['domains'].values()}" in block
assert "path not in allowed or path not in self.outputs:return None" in block
assert "['finite08_market','finite08_yamen']" in block and 'sha(raw)==expected' in block
assert 'super().verify_leaf(path,expected)' in block and 'super().leaf_bytes(path,expected)' in block
for row in reversed(proof['explicit_replacements']):
    assert text.count(row['new'])==row['count']
    text=text.replace(row['new'],row['old'])
assert text.encode()==(S/'stage_finite08_READY.py').read_bytes(), 'Whole byte inverse to unchanged1177'
wrapper=wrap.read_text(encoding='utf-8')
for x,y in [
 ('stage_finite09_READY.py','stage_finite08_READY.py'),
 ('b8d88ade54c74554cd76e8a3aa2e0a1ce72b8fb55519c526bf4d15d33f393b52','1177be57d7b656f825e695ee8be56e635b7915beaf4ef8b50f44c3422658c11f'),
 ('root_target_scope29_READY.json','root_target_scope_READY.json'),
 ('3e4ba399141dabddd35952064ddb46c540f52a57313f9332ec2306f1683a765a','44cfe6d81a6aff79431def1a3026199219f0a63083931de636577efa633841a0'),
 ('FRESH29','FRESH28'),("get('target_count')==29","get('target_count')==28"),
 ('1eade019a011914021f4dae7c0aaa426b0b647ac19cd5564d72bf8828cb4a8d0','15f54447d64b4cb4048654aec64e9a1a634c36468358822818b335a634e2b672'),
 ('EXACT29','EXACT28')]:
    assert x in wrapper;wrapper=wrapper.replace(x,y)
assert wrapper.encode()==(S/'stage_finite08_scope01_READY.py').read_bytes()
sources=[]
for row in b['pinned_inputs']:
    p=res(row['path']);assert sha(p)==row['sha256'];sources.append(fact(p))
scope=load(res(b['pinned_inputs'][43]['path']))
assert scope['approved_by_root'] is True and scope['target_count']==29
assert [r['target'] for r in scope['targets']]==b['root_target_allowlist']
for row in scope['targets']:
    p=Path(row['backup_path']).resolve();assert p.is_relative_to(ROOT)
    assert sha(p)==row['backup_sha256']==row['old_sha256'] and p.stat().st_size==row['old_bytes']
    assert sha(res(row['target']))==row['old_sha256']
assert not res(b['output_root']).exists()
assert not OUT.exists()
result={'status':'INDEPENDENT_FINITE09_STATIC_DAG_REVIEW_NOT_STAGE_ACTUAL','input':fact(new),'tool':fact(tool),'wrapper':fact(wrap),'whole_input_typed_inverse_to18FD_except_declared_changes':True,'whole_tool_byte_inverse_to1177':True,'whole_wrapper_byte_inverse_toCD84':True,'registry_exact29th_target_five_old_operations_preserved':True,'only_two_completed_binding_runtime_buffers_full_sha':True,'root29_backups_current_and_original_pinned_inputs':sources,'pinned_inputs_count':47,'canonical_target_count':29,'production_code_binding_execution_native_bytes_unchanged_from08':True,'explicit_existing_two_walk_remap_only':True,'finite_manifests_remain_independent_parent_immutable_and_external_index_last':True,'known_static_blockers_resolved':['REGISTRY_CHANGED_WITHOUT_CANONICAL_TARGET','NEW_FINITE_HEADER_UNRECOGNIZED_BY_VERIFY_LEAF'],'not_claims': ['No stage output or generated final hash observed','No canonical deployment','No runtime admission, Field, geometry, GPU, or performance pass'],'stage_runs':0,'engine_runs':0,'collector_calls':0,'native_or_PNG_decode':0,'canonical_writes':0}
OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review':fact(OUT),'static_blockers':0,'stage_executed':False}))
