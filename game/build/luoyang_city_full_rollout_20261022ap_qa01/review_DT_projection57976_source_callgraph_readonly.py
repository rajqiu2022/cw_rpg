"""Bound source-only interpretation of one measured aggregate DT span."""
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent
paths={'DT':'scripts/city/luoyang_district_life_20261016f.gd','geometry':'scripts/city/luoyang_district_life_geometry_20261016f.gd','B':'scripts/city/luoyang_precomputed_bundle_20261018r.gd','T':'build/luoyang_layout_quest_20261018t_layout_source01/layout_transform_retry2.gd','adapter':'build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/finite_adapter_READY.gd'}
expected={'DT':'39242c343d2e4981c2773b39fd79d84a451aab923a173a099eb8fb9b290acbe2','geometry':'c3203d99ad1c5d3de86ed04ee9fdb4672606c9669f47792cd1c500d2e9f5e133','B':'77dfc4987f21fa280c526cf62cb6c94316a40c4236fb1005761408859a0b8c16','T':'5bca446a4f08cc8375633383136cdf5b7e357f07acccbf4d3c1224d038a06e77','adapter':'999a687a1c6ed70a010e9b46c4c1fe4ce2a86b7cb2ca51b3a745c7e153a15e90'}
sources={};text={}
for k,p in paths.items():
    b=(ROOT/p).read_bytes();h=hashlib.sha256(b).hexdigest();assert h==expected[k];sources['res://'+p]=h;text[k]=b.decode()
def function(t,name):
    start=t.index('static func '+name+'(')if 'static func '+name+'('in t else t.index('func '+name+'(')
    end=t.find('\nstatic func ',start+1)
    if end<0:end=t.find('\nfunc ',start+1)
    return t[start:end if end>=0 else len(t)]
assert 'FileAccess.get_sha256(path)!=sha'in function(text['geometry'],'manifest')and 'JSON.parse_string(FileAccess.get_file_as_string(path))'in function(text['geometry'],'manifest')
assert 'var parent:=manifest(spec.parent_manifest.path,spec.parent_manifest.sha256)'in function(text['geometry'],'project')
assert 'var projected: Dictionary=original.duplicate(true)'in function(text['T'],'district_projection')
assert 'var expected: Dictionary=projected.parent.duplicate(true)'in text['DT']and 'G._c()._records.get(String(scene.scene_id),{}).duplicate(true)'in text['DT']
restore=function(text['B'],'restore_parent_record');mapping=function(text['adapter'],'_map_parent')
assert 'var child: Dictionary=data.record.duplicate(true); var prior: Dictionary=data.t_parent_record.duplicate(true)'in restore
assert 'current=mapped.current_t_record; child=mapped.frozen_t_record'in restore
assert 'var child: Dictionary=data.record.duplicate(true)'in mapping and 'var parent: Dictionary=_parents[domain].record.duplicate(true)'in mapping
assert mapping.count('parent.duplicate(true)')==4
assert restore.count('_wire(')==4 and function(text['DT'],'_same_wire').count('JSON.stringify(')==1
assert 'if not _same_wire(current,expected)'in text['DT']
layout=function(text['B'],'layout_author');assert 'yamen_layout_author(scene,finite_state)'in layout
assert '_binding.frozen_t_author.duplicate(true)'in function(text['adapter'],'yamen_layout_author')
out=QA/'DT_projection57976_independent_source_callgraph_analysis_READY.json'
r={'status':'SOURCE_ONLY_AGGREGATE_SPAN_OPTIMIZATION_TARGET_NOT_TIMED_SUBFUNCTION_PROOF','source_sha256':sources,'measured_aggregate_usec':2863942,'record_level_deepclone_expressions_on_finite_Yamen_path':11,'clone_expression_breakdown':{'T_projected_including_parent':1,'DT_expected_and_current':2,'B_child_and_prior':2,'adapter_child_and_parent':2,'adapter_four_parent_return_fields':4},'wire_conversions':{'B_four_whole_records':4,'DT_final_current_wire':1},'geometry_G_not_portal_G':True,'geometry_parent_manifest_hash_and_JSON_parse_synchronous':True,'finite_layout_author_uses_frozen_binding_clone_not_new_large_T_author_parse':True,'possible_scoped_implementation':['Avoid B initial child clone when a fully proven finite branch immediately overwrites child; preserve all failure gates and exact final record comparison.','Avoid manufacturing unused domain return copies, but keep independent current versus expected comparison and avoid mutable alias equivalence.','Consider parent-record reuse only with explicit same-call source-FIRST/token/domain/full identity provenance; no mtime cache or current-file hash fallback.'],'not_supported':['Attributing the entire aggregate span to JSON parse, one deep clone or one storage snapshot.','Claiming a measured or predicted numeric saving from this static analysis.','Removing complete inverse validation or sharing current/expected aliases such that a changed record compares to itself.','Cross-token/new-field broad cache freshness or bypassing original FIRST/FINAL.'],'receipt_and_portal_cost_excluded_from_this_measured_span':True,'parent_manifest_payload_parse_decode_or_geometry_replay':False,'engine_collector_canonical_write':False}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(hashlib.sha256(out.read_bytes()).hexdigest())
