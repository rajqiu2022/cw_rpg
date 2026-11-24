"""Literal transport of mature27 Stage, with exact three-bin visual delta gate."""
from pathlib import Path
import argparse,copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';O=S/'region_visual_finish_repair04';C=N/'visual_finish04_BUILD/closure27';sha=lambda b:hashlib.sha256(b).hexdigest();res=lambda p:'res://'+p.relative_to(G).as_posix()
ap=argparse.ArgumentParser();ap.add_argument('--backup-sha256',required=True);a=ap.parse_args()
def pin(p):b=p.read_bytes();return dict(path=res(p),sha256=sha(b),bytes=len(b))
bundlepin=pin(C/'visual27_all_candidates_NOT_STAGE.json');bundle=json.loads((C/'visual27_all_candidates_NOT_STAGE.json').read_bytes());proof=json.loads((G/bundle['rebind']['path'][6:]).read_bytes())
parent=S/'stage_region_phase_lifetime27_ROOT_ONLY.py';before=parent.read_bytes();text=before.decode();edits=[]
def change(x,y):
 global text
 assert text.count(x)==1,x[:100];text=text.replace(x,y,1);edits.append(dict(old=x,new=y))
change('Root-only currentD9A8 source rebind26; mature strict validation, no geometry/engine.','Root-only currentB78D visual27; three actual incremental bins, no geometry compiler/engine.')
change('class PhaseLifetime27(M.Stage):','class VisualFinish27(M.Stage):')
change("('fff398a42aa0dea09ed34eb96cc21106b4eb74913a4cf1ec23501df6d0450ba7',13)","('d25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc',13)")
change("'ROOT_CURRENT_5FCE_FULL27_BACKUP_AND_FRESH_OBSERVATION'","'ROOT_CURRENT_B78D_FULL27_BACKUP_AND_FRESH_OBSERVATION'")
change("self.backup['total_backups']==822","self.backup['total_backups']==849")
change("PREFIX+'region_phase_lifetime_repair03/root_only_current27_backup/'","PREFIX+'region_visual_finish_repair04/root_only_current27_backup/'")
change("len(prior['source_sha256'])==289 and len(self.authority['source_sha256'])==294","len(prior['source_sha256'])==294 and len(self.authority['source_sha256'])==299")
old="  back_manifest['runtime_modules'][field['target']]=parent_manifest['runtime_modules'][field['target']];need(same(back_manifest,parent_manifest),'MANIFEST_ALL_OTHER_MODULES_BINS_AUTHOR_UNCHANGED')"
new="""  back_manifest['runtime_modules'][field['target']]=parent_manifest['runtime_modules'][field['target']]
  delta=json.loads(self.read(rebind['publication']['path'],rebind['publication']['sha256']));need(delta['passed']is True and delta['errors']==[]and delta['geometry_compile_calls']==delta['Field_instances']==delta['PNG_decodes']==delta['canonical_writes']==0,'ROOT_ACTUAL_VISUAL_ONLY_DELTA')
  selected={r['id']:r for r in delta['components']};need(set(selected)=={'luoyang_civic_market_region_27d','luoyang_estate_region_27d','luoyang_temple_region_27d'},'EXACT_THREE_OUTDOOR_COMPONENTS')
  need(same(manifest['author'],rebind['author_candidate']),'EXACT_VISUAL_AUTHOR_BINDING');self.read(manifest['author']['path'],manifest['author']['sha256']);back_manifest['author']=parent_manifest['author']
  for ident,row in selected.items():
   binding={k:row[k]for k in ['path','sha256','bytes']};need(same(manifest['compiled_bindings'][ident],binding)and row['whole_typed_inverse']is True and row['positive_ground_unchanged']is True and row['npcs_interactions_unchanged']is True,'ACTUAL_INVERSE_GROUND_ACTORS_AREAS_RETAINED');back_manifest['compiled_bindings'][ident]=parent_manifest['compiled_bindings'][ident]
  need(same(back_manifest,parent_manifest),'ONLY_REGIONFIELD_AUTHOR_THREE_BINS_MANIFEST_DELTA')"""
change(old,new)
change("'NINE_ORIGINAL_BINS_UNCHANGED'","'NINE_FIXED_BINS_SIX_INHERITED_THREE_ACTUAL_DELTAS'")
change('PhaseLifetime27(spec).run()','VisualFinish27(spec).run()')
change("status='ROOT08_PHASE_OWNER_LIFETIME27_STAGED_NOT_DEPLOYED'","status='ROOT08_VISUAL_FINISH27_STAGED_NOT_DEPLOYED'")
start=text.index("source_baseline='");end=text.index("',no_engine_import_collector_or_canonical_write=True)",start)
change(text[start:end],"source_baseline='CurrentB78D visual-only successor: three Root actual67124 bins, retire54 proxy+2 isolated render/body pairs, unchanged positive ground/actors/interactions, one genuineGate door relocated to existing west road, decorative underlay and ChineseHUD only. Six rooms and all passed gameplay components inherited. Old294 EX proofs all retained plus3 owned edges and2 ordinary=299; no compiler/import/engine rerun.")
text=text.replace('OWNED10_289_PLUS5_EQUALS294','OWNED10_294_PLUS5_EQUALS299').replace('ALL_OLD289_FIXED_FIVE_NEW','ALL_OLD294_FIXED_FIVE_NEW')
compile(text,'stage_region_visual_finish27_ROOT_ONLY.py','exec');driver=S/'stage_region_visual_finish27_ROOT_ONLY.py';assert not driver.exists();driver.write_bytes(text.encode())
prior=json.loads((S/'region_phase_lifetime_repair03/source_input_phase27_ROOT_REVIEW.json').read_bytes());spec=copy.deepcopy(prior);backup=O/'current_B78D_backup27_ROOT_ACTUAL.json';assert sha(backup.read_bytes())==a.backup_sha256
replacement={'driver':pin(driver),'candidates':bundlepin,'scope':pin(C/'current_B78D_exact27_scope_PREPARATION.json'),'backup':pin(backup),'execution':bundle['execution']['candidate'],'parent_stage':bundle['parent_stage'],'rebind':bundle['rebind'],'region_manifest':proof['manifest']['candidate']}
for row in spec['pinned_inputs']:
 if row['id']in replacement:row.update(replacement[row['id']])
ex=json.loads((G/bundle['execution']['candidate']['path'][6:]).read_bytes());spec['prospective_targets']=[]
for target,row in ex['owned'].items():
 edge=next(e for e in row['edges']if e['new_sha256']==row['current_sha256']);spec['prospective_targets'].append(dict(target=target,candidate_path=edge['new_snapshot'],sha256=edge['new_sha256']))
for row in bundle['targets']:
 if row['target']not in ex['owned']:spec['prospective_targets'].append(dict(target=row['target'],candidate_path=row['candidate']['path'],sha256=row['candidate']['sha256']))
spec['declared_candidates']={r['target']:r['candidate']for r in bundle['targets']};spec['output_root']='res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_visual_finish27_stage01/'
inp=O/'source_input_visual27_ROOT_REVIEW.json';assert not inp.exists();inp.write_bytes((json.dumps(spec,ensure_ascii=False,indent=2)+'\n').encode())
proofpath=O/'Stage27_transport_changes_NOT_EXECUTED.json';proofpath.write_bytes((json.dumps(dict(parent=pin(parent),candidate=pin(driver),literal_edits=edits,remaining_text_changes='Two EX count labels only',executed=False),ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(driver=pin(driver),input=pin(inp),transport=pin(proofpath),Stage_executed=False)))
