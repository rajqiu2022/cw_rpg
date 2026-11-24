"""Narrow specialization of mature Stage; builds only, never executes Stage."""
from pathlib import Path
import argparse,copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';O=S/'region_source_rebind_repair02';C=N/'source_rebinding02_BUILD/closure26'
ap=argparse.ArgumentParser();ap.add_argument('--backup-sha256',required=True);a=ap.parse_args()
sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode();res=lambda p:'res://'+p.relative_to(G).as_posix()
def pin(p):b=p.read_bytes();return dict(path=res(p),sha256=sha(b),bytes=len(b))
bundlepin=pin(C/'source_rebind26_all_candidates_NOT_STAGE.json');bundle=json.loads((C/'source_rebind26_all_candidates_NOT_STAGE.json').read_bytes())
parent=S/'stage_region_integration32_ROOT_ONLY.py';text=parent.read_text(encoding='utf8')
def change(x,y):
 global text
 assert text.count(x)==1,x[:110];text=text.replace(x,y,1)
change('class RegionIntegration32(M.Stage):','class SourceRebind26(M.Stage):')
change("M.EXACT_EOL_CANDIDATES={'res://scripts/autoload/scene_router.gd':('eddb274e6c09d573879234ba7b303b490ffccd33dff2c91d329e46e0c52840f4',13)}", "M.EXACT_EOL_CANDIDATES={'res://scripts/autoload/scene_router.gd':('8c70847f2827137615b6e5c0f1d30b6b91a8f2cb5c663d0a0725b6a856959202',13)}")
change("self.scope['count']==len(self.parents)==32 and self.scope['partition']==dict(GD=18,JSON=14)","self.scope['count']==len(self.parents)==26 and self.scope['partition']==dict(GD=11,JSON=15,total=26)")
change("self.backup['status']=='ROOT_CURRENT_01656_FULL32_BACKUP_AND_FRESH_OBSERVATION'", "self.backup['status']=='ROOT_CURRENT_D9A8_FULL26_BACKUP_AND_FRESH_OBSERVATION'")
change("self.backup['total_backups']==769", "self.backup['total_backups']==795")
change("len(rows)==32 and", "len(rows)==26 and")
change("PREFIX+'region_integration_20261027d01/root_only_current32_backup/'", "PREFIX+'region_source_rebind_repair02/root_only_current26_backup/'")
change("len(prior['source_sha256'])==277 and len(self.authority['source_sha256'])==284", "len(prior['source_sha256'])==284 and len(self.authority['source_sha256'])==289")
change("changed==set(self.spec['five_owned_targets'])and len(changed)==5", "changed==set(self.spec['three_owned_targets'])and len(changed)==3")
change("len(extra)==7 and", "len(extra)==5 and")
change("same(allowed,self.bundle['source_additions_by_metadata'][r['id']])", "same(allowed,{p:h for p,h in self.bundle['source_additions'].items()if p not in oldset and p not in r['forbidden_sources']})")
start=text.index("  seal=self.read_json_input('seal');");end=text.index("  for p,r in self.bundle['records'].items():",start)
text=text[:start]+'''  rebind=self.read_json_input('rebind')
  need(rebind['changed_terminals']==2 and rebind['unchanged_terminals']==2 and rebind['compiled_source_only_successors']==9 and len(rebind['proofs'])==11,'EXACT_ELEVEN_SOURCE_ONLY_BIN_TRANSPORTS')
  for proof in rebind['proofs']:
   raw=self.read(proof['parent']['path'],proof['parent']['sha256']);rebuilt=raw
   for edit in proof['changes']:
    old=bytes.fromhex(edit['old_atom_hex']);new=bytes.fromhex(edit['new_atom_hex']);need(rebuilt.count(old)==1 and new not in rebuilt,'UNIQUE_PACKED_STRING_SOURCE_KEY');rebuilt=rebuilt.replace(old,new,1)
   after=self.read(proof['candidate']['path'],proof['candidate']['sha256']);need(rebuilt==after,'ONLY_SOURCE_KEY_BINARY_REPLACEMENTS')
   for edit in reversed(proof['changes']):
    old=bytes.fromhex(edit['old_atom_hex']);new=bytes.fromhex(edit['new_atom_hex']);need(rebuilt.count(new)==1,'UNIQUE_BINARY_INVERSE');rebuilt=rebuilt.replace(new,old,1)
   need(rebuilt==raw,'WHOLE_BINARY_INVERSE_ALL_GEOMETRY_TASKS_ORIGINAL')
  manifest=self.read_json_input('region_manifest');old_manifest=json.loads(self.read(rebind['parent_manifest']['path'],rebind['parent_manifest']['sha256']))
  back_manifest=copy.deepcopy(manifest);back_manifest['author']=old_manifest['author'];back_manifest['compiled_bindings']=old_manifest['compiled_bindings'];need(same(back_manifest,old_manifest),'MANIFEST_ONLY_AUTHOR_AND_NINE_SOURCE_BINDINGS')
  author=json.loads(self.read(manifest['author']['path'],manifest['author']['sha256']));old_author=json.loads(self.read(rebind['author_parent']['path'],rebind['author_parent']['sha256']));back_author=copy.deepcopy(author);back_author['terminal_bindings']=old_author['terminal_bindings'];need(same(back_author,old_author),'AUTHOR_ONLY_TWO_TERMINAL_BINDINGS')
  for binding in rebind['immutable_source_bindings']:need(len(self.read(binding['new'],binding['sha256']))==binding['bytes'],'EXACT_ORIGINAL_IMMUTABLE_FAMILY_BYTES')
  for p,h in manifest['runtime_modules'].items():need(p not in self.parents,'NO_REGION_CANONICAL_HASH_CYCLE');self.verify_leaf(p,h)
  for binding in manifest['compiled_bindings'].values():need(len(self.read(binding['path'],binding['sha256']))==binding['bytes'],'EXACT_SOURCE_REBOUND_BIN')
  manifest_target=rebind['manifest_target'];self.checked_candidate(manifest_target,{'parent':self.parents[manifest_target],'candidate':rebind['manifest_candidate']});self.add_target(manifest_target,rebind['manifest_candidate'])
''' +text[end:]
change("set(contract['changes'])=={'res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/autoload/scene_router.gd'}", "set(contract['changes'])=={'res://scripts/autoload/scene_router.gd'}")
change("set(temple['changes'])=={'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd',CT,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd','res://scripts/autoload/scene_router.gd'}", "set(temple['changes'])=={CT,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd','res://scripts/autoload/scene_router.gd'}")
change("set(self.targets)==set(self.parents)and len(self.targets)==32", "set(self.targets)==set(self.parents)and len(self.targets)==26")
change("len(copies)==14 and len(reconstruction)==32", "len(copies)==15 and len(reconstruction)==26")
change("target_count=14", "target_count=15")
change("target_partition=dict(patch_count=18,copy_count=14,total=32)", "target_partition=dict(patch_count=11,copy_count=15,total=26)")
change("targets=32,map_nodes=4", "targets=26,map_nodes=4")
change("RegionIntegration32(spec).run()", "SourceRebind26(spec).run()")
change("status='ROOT08_REGION_GATE_EXACT32_STAGED_NOT_DEPLOYED'", "status='ROOT08_IMMUTABLE_SOURCE_REBIND26_STAGED_NOT_DEPLOYED'")
start=text.index("source_baseline='");end=text.index("',no_engine_import_collector_or_canonical_write=True)",start)
text=text[:start]+"source_baseline='Current D9A8 source-only successor. Eleven binary source-key transports preserve all geometry, actors, doors and tasks. Router one manifest SHA plus exact CT/Coordinator/Temple and existing metadata pointers only; old284 proofs and ten owned domains retained with3 real owned edges and2 ordinary leaves=289. Gate actual86968 admission inherited, not repeated."+text[end:]
text=text.replace('277_PLUS7_EQUALS284','284_PLUS5_EQUALS289').replace('OLD277_FIXED_SEVEN_NEW','OLD284_FIXED_FIVE_NEW').replace('ONLY_FIVE_REAL_OWNED_EDGES','ONLY_THREE_REAL_OWNED_EDGES').replace('EXACT32_18GD14JSON_SCOPE','EXACT26_11GD15JSON_SCOPE').replace('EXACT32_NO_NOOP_TARGETS','EXACT26_NO_NOOP_TARGETS').replace('EXACT18_GD_PATCH14_JSON_COPY','EXACT11_GD_PATCH15_JSON_COPY').replace('ONLY_CT_FIELD_C_ROUTER_THREE_LITERALS','ONLY_CT_ROUTER_ONE_LITERAL').replace('CONTRACT_TYPED_RAW_THREE_LITERAL_FULL_INVERSE','CONTRACT_TYPED_RAW_ONE_LITERAL_FULL_INVERSE').replace('TEMPLE_ONLY_C_FIELD_CT_COORDINATOR_ROUTER_FIVE_SOURCE_VALUES','TEMPLE_ONLY_CT_COORDINATOR_ROUTER_THREE_SOURCE_VALUES')
text='"""Root-only currentD9A8 source rebind26; mature strict validation, no geometry/engine."""\n'+text.split('\n',1)[1]
compile(text,'stage_region_source_rebind26_ROOT_ONLY.py','exec');driver=S/'stage_region_source_rebind26_ROOT_ONLY.py';assert not driver.exists();driver.write_bytes(text.encode())
prior=json.loads((S/'region_integration_20261027d01/source_input_region32_ROOT_REVIEW02.json').read_bytes());spec=copy.deepcopy(prior)
backup=O/'current_D9A8_backup26_ROOT_ACTUAL.json';assert sha(backup.read_bytes())==a.backup_sha256
keep={'driver','candidates','scope','backup','execution','authority_helper','publication','trial','parent_stage','gate_0','gate_1','gate_2','gate_3'}
replacement={'driver':pin(driver),'candidates':bundlepin,'scope':pin(C/'current_D9A8_exact26_scope_PREPARATION.json'),'backup':pin(backup),'execution':bundle['execution']['candidate'],'parent_stage':bundle['parent_stage']}
spec['pinned_inputs']=[{**r,**replacement.get(r['id'],{})}for r in prior['pinned_inputs']if r['id']in keep]
spec['pinned_inputs'] += [{'id':'rebind',**bundle['rebind']},{'id':'region_manifest',**json.loads((N/'source_rebinding02_BUILD/source_rebinding_whole_binary_inverse_BUILD.json').read_bytes())['manifest_candidate']}]
ex=json.loads((G/bundle['execution']['candidate']['path'][6:]).read_bytes());spec['prospective_targets']=[]
for target,row in ex['owned'].items():
 edge=next(e for e in row['edges']if e['new_sha256']==row['current_sha256']);spec['prospective_targets'].append(dict(target=target,candidate_path=edge['new_snapshot'],sha256=edge['new_sha256']))
for row in bundle['targets']:
 if row['target']not in ex['owned']:spec['prospective_targets'].append(dict(target=row['target'],candidate_path=row['candidate']['path'],sha256=row['candidate']['sha256']))
spec['declared_candidates']={r['target']:r['candidate']for r in bundle['targets']};spec.pop('five_owned_targets',None);spec['three_owned_targets']=bundle['execution']['changed_existing_owned'];spec['output_root']='res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_source_rebind26_stage01/'
inp=O/'source_input_rebind26_ROOT_REVIEW.json';assert not inp.exists();inp.write_bytes(enc(spec))
print(json.dumps({'driver':pin(driver),'input':pin(inp),'Stage_executed':False}))
