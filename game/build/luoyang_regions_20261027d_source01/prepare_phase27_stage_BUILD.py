"""Small lifetime-specific derivative of reviewed strict source Stage26."""
from pathlib import Path
import argparse,copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';O=S/'region_phase_lifetime_repair03';C=N/'phase_lifetime03_BUILD/closure27';sha=lambda b:hashlib.sha256(b).hexdigest();res=lambda p:'res://'+p.relative_to(G).as_posix()
ap=argparse.ArgumentParser();ap.add_argument('--backup-sha256',required=True);a=ap.parse_args()
def pin(p):b=p.read_bytes();return dict(path=res(p),sha256=sha(b),bytes=len(b))
bundlepin=pin(C/'phase_lifetime27_all_candidates_NOT_STAGE.json');bundle=json.loads((C/'phase_lifetime27_all_candidates_NOT_STAGE.json').read_bytes());proof=json.loads((G/bundle['rebind']['path'][6:]).read_bytes())
parent=S/'stage_region_source_rebind26_ROOT_ONLY02.py';before=parent.read_bytes();text=before.decode();edits=[]
def change(x,y):
 global text
 assert text.count(x)==1,x[:110];text=text.replace(x,y,1);edits.append(dict(old=x,new=y))
change('class SourceRebind26(M.Stage):','class PhaseLifetime27(M.Stage):')
change("('8c70847f2827137615b6e5c0f1d30b6b91a8f2cb5c663d0a0725b6a856959202',13)","('fff398a42aa0dea09ed34eb96cc21106b4eb74913a4cf1ec23501df6d0450ba7',13)")
change("self.scope['count']==len(self.parents)==26 and self.scope['partition']==dict(GD=11,JSON=15,total=26)","self.scope['count']==len(self.parents)==27 and self.scope['partition']==dict(GD=12,JSON=15,total=27)")
change("'ROOT_CURRENT_D9A8_FULL26_BACKUP_AND_FRESH_OBSERVATION'","'ROOT_CURRENT_5FCE_FULL27_BACKUP_AND_FRESH_OBSERVATION'")
change("self.backup['total_backups']==795","self.backup['total_backups']==822")
change("len(rows)==26 and","len(rows)==27 and")
change("PREFIX+'region_source_rebind_repair02/root_only_current26_backup/'","PREFIX+'region_phase_lifetime_repair03/root_only_current27_backup/'")
change("len(prior['source_sha256'])==284 and len(self.authority['source_sha256'])==289","len(prior['source_sha256'])==289 and len(self.authority['source_sha256'])==294")
start=text.index("  rebind=self.read_json_input('rebind')");end=text.index("  for p,r in self.bundle['records'].items():",start)
oldblock=text[start:end]
newblock='''  rebind=self.read_json_input('rebind');field=rebind['Field'];manifest=self.read_json_input('region_manifest')
  parent_manifest=json.loads(self.read(rebind['manifest']['parent']['path'],rebind['manifest']['parent']['sha256']));back_manifest=copy.deepcopy(manifest)
  need(parent_manifest['runtime_modules'][field['target']]==field['parent']['sha256']and manifest['runtime_modules'][field['target']]==field['candidate']['sha256'],'ONLY_EXACT_REGION_FIELD_MODULE_SUCCESSOR')
  back_manifest['runtime_modules'][field['target']]=parent_manifest['runtime_modules'][field['target']];need(same(back_manifest,parent_manifest),'MANIFEST_ALL_OTHER_MODULES_BINS_AUTHOR_UNCHANGED')
  for p,h in manifest['runtime_modules'].items():need(p not in self.parents or p==field['target'],'NO_CONTROL_METADATA_MANIFEST_HASH_CYCLE');self.verify_leaf(p,h)
  for binding in manifest['compiled_bindings'].values():need(len(self.read(binding['path'],binding['sha256']))==binding['bytes'],'NINE_ORIGINAL_BINS_UNCHANGED')
  manifest_target=rebind['manifest']['target'];self.checked_candidate(manifest_target,{'parent':{'path':self.parents[manifest_target]['immutable_old'],'sha256':self.parents[manifest_target]['old_sha256'],'bytes':self.parents[manifest_target]['old_bytes']},'candidate':rebind['manifest']['candidate']});self.add_target(manifest_target,rebind['manifest']['candidate'])
'''
change(oldblock,newblock)
change("len(self.targets)==26","len(self.targets)==27")
change("len(reconstruction)==26","len(reconstruction)==27")
change("target_partition=dict(patch_count=11,copy_count=15,total=26)","target_partition=dict(patch_count=12,copy_count=15,total=27)")
change("targets=26,map_nodes=4","targets=27,map_nodes=4")
change('SourceRebind26(spec).run()','PhaseLifetime27(spec).run()')
change("status='ROOT08_IMMUTABLE_SOURCE_REBIND26_STAGED_NOT_DEPLOYED'","status='ROOT08_PHASE_OWNER_LIFETIME27_STAGED_NOT_DEPLOYED'")
start=text.index("source_baseline='");end=text.index("',no_engine_import_collector_or_canonical_write=True)",start)
change(text[start:end],"source_baseline='Current5FCE lifetime successor. RegionField strongly owns the exact phase Callable object after script/method validation; phase business, all nine compiled bins and source terminals unchanged. Router manifest SHA and strict CT/Temple/metadata heads only. Old289 proofs/ten owned retained plus3 real owned edges and2 ordinary=294. Gate credit inherited; no geometry/import/probe repeated.")
text=text.replace('EXACT26_11GD15JSON_SCOPE','EXACT27_12GD15JSON_SCOPE').replace('EXACT26_NO_NOOP_TARGETS','EXACT27_NO_NOOP_TARGETS').replace('EXACT11_GD_PATCH15_JSON_COPY','EXACT12_GD_PATCH15_JSON_COPY').replace('284_PLUS5_EQUALS289','289_PLUS5_EQUALS294').replace('OLD284_FIXED_FIVE_NEW','OLD289_FIXED_FIVE_NEW')
compile(text,'stage_region_phase_lifetime27_ROOT_ONLY.py','exec');driver=S/'stage_region_phase_lifetime27_ROOT_ONLY.py';assert not driver.exists();driver.write_bytes(text.encode())
prior=json.loads((S/'region_source_rebind_repair02/source_input_rebind26_ROOT_REVIEW03.json').read_bytes());spec=copy.deepcopy(prior);backup=O/'current_5FCE_backup27_ROOT_ACTUAL.json';assert sha(backup.read_bytes())==a.backup_sha256
replacement={'driver':pin(driver),'candidates':bundlepin,'scope':pin(C/'current_5FCE_exact27_scope_PREPARATION.json'),'backup':pin(backup),'execution':bundle['execution']['candidate'],'parent_stage':bundle['parent_stage'],'rebind':bundle['rebind'],'region_manifest':proof['manifest']['candidate']}
for row in spec['pinned_inputs']:
 if row['id']in replacement:row.update(replacement[row['id']])
ex=json.loads((G/bundle['execution']['candidate']['path'][6:]).read_bytes());spec['prospective_targets']=[]
for target,row in ex['owned'].items():
 edge=next(e for e in row['edges']if e['new_sha256']==row['current_sha256']);spec['prospective_targets'].append(dict(target=target,candidate_path=edge['new_snapshot'],sha256=edge['new_sha256']))
for row in bundle['targets']:
 if row['target']not in ex['owned']:spec['prospective_targets'].append(dict(target=row['target'],candidate_path=row['candidate']['path'],sha256=row['candidate']['sha256']))
spec['declared_candidates']={r['target']:r['candidate']for r in bundle['targets']};spec['output_root']='res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_phase_lifetime27_stage01/'
inp=O/'source_input_phase27_ROOT_REVIEW.json';assert not inp.exists();inp.write_bytes((json.dumps(spec,ensure_ascii=False,indent=2)+'\n').encode())
proofpath=O/'Stage27_transport_changes_NOT_EXECUTED.json';proofpath.write_bytes((json.dumps(dict(parent=pin(parent),candidate=pin(driver),literal_edits=edits,remaining_text_changes='labels and explicit294 proof counts only',executed=False),ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(driver=pin(driver),input=pin(inp),transport=pin(proofpath),Stage_executed=False)))
