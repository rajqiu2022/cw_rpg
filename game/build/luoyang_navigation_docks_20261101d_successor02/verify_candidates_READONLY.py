"""Read-only virtual application checks; never imports an engine or writes files."""
from pathlib import Path
import hashlib,json
TASK=Path(__file__).resolve().parent
GAME=TASK.parents[1]
def need(v,s):
 if not v:raise ValueError(s)
def sha(b):return hashlib.sha256(b).hexdigest()
def disk(p):return (GAME/p.removeprefix('res://')).read_bytes()
report=json.loads((TASK/'candidate_closure_READY.json').read_bytes())
applied={r['res_path']:disk(r['candidate'])for r in report['actual_targets']}
def virtual(p):return applied.get(p,disk(p))
for row in report['actual_targets']:
 need((sha(disk(row['res_path'])),len(disk(row['res_path'])))==(row['before_sha256'],row['before_bytes']),('FRESH_CANONICAL_UNCHANGED',row['res_path']))
 candidate_bytes=applied[row['res_path']]
 need((sha(candidate_bytes),len(candidate_bytes))==(row['after_sha256'],row['after_bytes']),('CANDIDATE_HASH',row['res_path']))
results=[]
for p in ['res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json',
          'res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json',
          'res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json']:
 v=json.loads(virtual(p));count=0;bad=[]
 for domain in ('legacy_source_sha256','runtime_authority_sha256','artifacts','source_sha256'):
  for source,expected in v.get(domain,{}).items():
   count+=1;actual=sha(virtual(source))
   if actual!=expected:bad.append({'path':source,'expected':expected,'actual':actual,'domain':domain})
 need(not bad,('ALL_SELECTED_EXPECTED_PINS_MATCH_VIRTUAL_APPLICATION',p,bad))
 results.append({'manifest':p,'all_top_expected_source_pins':count,'mismatches':bad})
expath='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
old=json.loads(disk(expath));ex=json.loads(virtual(expath));ac='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
need(set(ex['owned'])==set(old['owned']),'EX_OWNED_SET_EXACT')
for p,row in ex['owned'].items():
 if p!=ac:need(row==old['owned'][p],('ALL_OTHER_OWNED_ROWS_INCLUDING_ROUTER_EXACT',p))
need(ex['owned'][ac]['edges'][:-1]==old['owned'][ac]['edges'],'ALL_PREVIOUS_AC_EDGES_EXACT')
edge=ex['owned'][ac]['edges'][-1];text=virtual(edge['new_snapshot']).decode()
need(edge['new_snapshot'].startswith('res://build/luoyang_'),'ORIGINAL_EX_SNAPSHOT_PREFIX')
for h in edge['replacements']:
 need(text.count(h['new'])==1,'ORIGINAL_EX_UNIQUE_INVERSE_REPLACEMENT');text=text.replace(h['new'],h['old'])
need(text.encode()==disk(ac) and sha(text.encode())==edge['old_sha256'],'ORIGINAL_EX_WHOLE_BYTE_INVERSE')
for proof_name in ('C_11c_to_fixed_FINISH_C_inverse_READY.json','AA_11d_to_fixed_FINISH_AA_inverse_READY.json'):
 proof=json.loads((TASK/proof_name).read_bytes());value=virtual(proof['path'])
 need(sha(value)==proof['current_sha256'],('LAYER_CURRENT_EXACT',proof_name))
 for h in reversed(proof['hunks']):
  at=h['new_offset'];new=h['new'].encode();need(value[at:at+len(new)]==new,('LAYER_EXACT_SLICE',proof_name));value=value[:at]+h['old'].encode()+value[at+len(new):]
 need(sha(value)==proof['parent_sha256'],('LAYER_FULL_FIXED_PARENT',proof_name))
base=json.loads(disk('res://build/city_navigation_20261101d_candidate01/source_pins_READY.json'))
need(len(base['source_pins'])==96 and not set(applied)&set(base['source_pins']),'ALL96_NO_TARGET_OVERLAP')
for path,h in report['new_runtime_sources'].items():need(sha(virtual(path))==h,('ALL_NEW_RUNTIME_LEAF_PINS',path))
print(json.dumps({'passed':True,'actual_old_targets':len(applied),'virtual_expected_audits':results,'exact_fixed_C_and_AA_inverse_layers':True,'original_EX_last_AC_edge_inverse':True,'full_Router_row_and_OTHER_OWNED_rows_exact':True,'frozen96_no_overlap':True,'new_runtime_leaf_count':len(report['new_runtime_sources']),'canonical_writes':0,'engine_runs':0},indent=2))
