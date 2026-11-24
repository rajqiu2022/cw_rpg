"""Root-only currentB78D visual27; three actual incremental bins, no geometry compiler/engine."""
import argparse,copy,hashlib,importlib.util,json
from pathlib import Path
GAME=Path(__file__).resolve().parents[2];PREFIX='res://build/luoyang_city_finish_20261025i_source01/'
CORE=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py'
assert hashlib.sha256(CORE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
sp=importlib.util.spec_from_file_location('fixed_source_core',CORE);M=importlib.util.module_from_spec(sp);sp.loader.exec_module(M);M.PREFIX=PREFIX
M.AUTHORITY_SHA='f120512a771d7e3e482b5befac0f39d44fb0abf794be0805fcd0fe4e638bb5bc'
M.EXACT_EOL_CANDIDATES={'res://scripts/autoload/scene_router.gd':('d25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc',13)}
# Router has the explicit Region dispatch successor; preserve its original thirteen CRLF bytes after patch transport.
need,same,sha,enc,res=M.need,M.same,M.digest,M.encode,M.res
EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
class VisualFinish27(M.Stage):
 def __init__(self,spec):
  need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT'and spec.get('blockers')==[],'ROOT_LOCKED_INPUT')
  super().__init__(spec)
  need(self.inputs['driver']['path']=='res://'+Path(__file__).resolve().relative_to(M.ROOT).as_posix()and self.inputs['driver']['sha256']==sha(Path(__file__).read_bytes()),'EXACT_DRIVER_PIN')
  self.bundle=self.read_json_input('candidates');self.scope=self.read_json_input('scope');self.backup=self.read_json_input('backup');self.parents={r['target']:r for r in self.scope['targets']}
  need(self.scope['count']==len(self.parents)==27 and self.scope['partition']==dict(GD=12,JSON=15,total=27),'EXACT27_12GD15JSON_SCOPE')
  need(self.backup['status']=='ROOT_CURRENT_B78D_FULL27_BACKUP_AND_FRESH_OBSERVATION'and self.backup['passed']is True and self.backup['total_backups']==849 and self.backup['external_save_changes']==[]and self.backup['canonical_writes']==0 and self.backup['scope']['sha256']==self.inputs['scope']['sha256'],'ROOT_ACTUAL_01656_BACKUP32')
  rows=self.backup['new_backups'];need(len(rows)==27 and {r['target']for r in rows}==set(self.parents),'ROOT_BACKUP32_EXACT_DOMAIN')
  need(len(self.backup['current37'])==37,'CURRENT37_NOOP_PAWN_G_AUTHORITY_PRESERVED')
  for r in self.backup['current37']:need(len(self.read(r['target'],r['sha256']))==r['bytes'],'CURRENT37_IMMUTABLE_PARENT')
  for r in rows:
   p=r['target'];parent=self.parents[p];need(r['backup'].startswith(PREFIX+'region_visual_finish_repair04/root_only_current27_backup/'),'ROOT_BACKUP32_FIXED_NAMESPACE')
   need(self.read(r['backup'],r['sha256'])==self.read(parent['immutable_old'],parent['old_sha256'])==self.read(p,parent['old_sha256']) and r['sha256']==parent['old_sha256'] and r['bytes']==parent['old_bytes'],'ROOT_FULL_BACKUP32_WHOLE_CURRENT_IMMUTABLE')
  prior=json.loads(self.read(self.bundle['execution']['parent']['path'],self.bundle['execution']['parent']['sha256']));need(len(prior['owned'])==len(self.authority['owned'])==10 and len(prior['source_sha256'])==294 and len(self.authority['source_sha256'])==299,'OWNED10_294_PLUS5_EQUALS299')
  changed=set(self.bundle['execution']['changed_existing_owned']);need(changed==set(self.spec['three_owned_targets'])and len(changed)==3,'ONLY_THREE_REAL_OWNED_EDGES')
  back=copy.deepcopy(self.authority)
  for p,old in prior['owned'].items():
   new=self.authority['owned'][p]
   if p not in changed:need(same(old,new),'OTHER_FIVE_OWNED_IDENTICAL');continue
   r=self.bundle['records'][p];edge=new['edges'][-1]
   need(len(new['edges'])==len(old['edges'])+1 and same(new['edges'][:-1],old['edges'])and edge['old_sha256']==old['current_sha256']==r['parent']['sha256']and edge['new_sha256']==new['current_sha256']==r['candidate']['sha256']and same(edge['replacements'],r['hunks']),'ONE_EXACT_EDGE_NO_SHORTCUT')
   back['owned'][p]=copy.deepcopy(old)
  extra={p:h for p,h in self.authority['source_sha256'].items()if p not in prior['source_sha256']};need(same(extra,self.bundle['execution']['extra'])and len(extra)==5 and all(self.authority['source_sha256'].get(p)==h for p,h in prior['source_sha256'].items()),'ALL_OLD294_FIXED_FIVE_NEW')
  back['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(back,prior)and enc(back)==self.read(self.bundle['execution']['parent']['path'],self.bundle['execution']['parent']['sha256']),'EXECUTION_FULL_TYPED_BYTE_INVERSE')
 def approved(self,path,historical):
  # Exact finite F120 traversal, not old range16. Core already validated every edge.
  row=self.authority.get('owned',{}).get(path)
  if row is None:return False
  current=row['current_sha256']
  if current==historical:return True
  frontier,visited=[current],set()
  for _ in range(len(row['edges'])):
   if not frontier:return False
   following=[]
   for h in frontier:
    if h in visited:continue
    visited.add(h)
    for edge in row['edges']:
     if edge['new_sha256']!=h:continue
     if edge['old_sha256']==historical:return True
     following.append(edge['old_sha256'])
   frontier=following
  return False
 def checked_candidate(self,p,r):
  before=self.read(r['parent']['path'],r['parent']['sha256']);after=self.read(r['candidate']['path'],r['candidate']['sha256']);need(len(before)==r['parent']['bytes']and len(after)==r['candidate']['bytes']and before!=after and r['parent']['sha256']==self.parents[p]['old_sha256'],'EXACT_CHANGED_CANDIDATE_BYTES');return before,after
 def add_target(self,p,pin):
  need(p in self.parents and pin['sha256']!=self.parents[p]['old_sha256'],'NO_EXTRA_OR_NOOP');self.target(p,self.parents[p]['old_sha256'],pin['path'],pin['sha256'])
 def source_fields(self,v,fields):
  result={}
  for ptr in fields:
   for p,h in M.pointer(v,ptr).items():need(p not in result,'DISJOINT_ORIGINAL_SOURCE_CLASSES');result[p]=h
  return result
 def verify_metadata(self,p,r):
  before,after=self.checked_candidate(p,r);old=json.loads(before);value=json.loads(after);rebuilt=copy.deepcopy(old);fields=r['source_fields'];oldset=self.source_fields(old,fields);newset=self.source_fields(value,fields);allowed=r['explicit_new_ordinary']
  need(set(oldset)<=set(newset)and same({p:newset[p]for p in set(newset)-set(oldset)},allowed)and same(allowed,{p:h for p,h in self.bundle['source_additions'].items()if p not in oldset and p not in r['forbidden_sources']}),'EXACT_DECLARED_ORDINARY_ADDITIONS_NO_REMOVAL')
  for ptr in fields:
   need(all(p not in M.pointer(old,ptr)or p in M.pointer(value,ptr)for p in M.pointer(old,ptr)),'ORIGINAL_CLASS_MEMBERSHIP_PRESERVED')
  for c in r['changes']:
   ptr=c['pointer'];holder=M.pointer(rebuilt,ptr[:-1]);key=ptr[-1];need((key in holder)==c['existed']and(not c['existed']or same(holder[key],c['old'])),'JSON_EXACT_FIXED_OLD_VALUE')
   need(any(ptr[:len(f)]==f and len(ptr)==len(f)+1 for f in fields),'SOURCE_FIELDS_ONLY_NO_NATIVE_OR_HEADER_CHANGE')
   path=ptr[-1];h=c['new'];need(M.valid_sha(h),'SOURCE_SHA')
   if c['existed']:
    need(path in self.parents and c['old']==self.parents[path]['old_sha256']and h==self.spec['declared_candidates'][path]['sha256'],'EXISTING_SOURCE_EXACT_CURRENT_TARGET')
    if path in self.authority['owned']:need(self.approved(path,c['old']),'ORIGINAL_APPROVED_CURRENT_PARENT_EDGE')
   else:
    need(allowed.get(path)==h,'ONLY_EXPLICIT_NEW_ORDINARY')
    if r.get('source_bundle'):need(ptr[0]=='legacy_source_sha256','NO_NEW_RUNTIME_AUTHORITY_CLASS')
   holder[key]=copy.deepcopy(c['new'])
  need(same(rebuilt,value),'ENUMERATED_ALL_METADATA_DIFFERENCES')
  back=copy.deepcopy(value)
  for c in reversed(r['changes']):
   holder=M.pointer(back,c['pointer'][:-1]);key=c['pointer'][-1]
   if c['existed']:holder[key]=copy.deepcopy(c['old'])
   else:del holder[key]
  need(same(back,old)and enc(back)==before,'FULL_TYPED_UTF8_METADATA_INVERSE')
  for ptr in r['protected_pointers']:need(same(M.pointer(value,ptr),M.pointer(old,ptr)),'PROTECTED_POINTER_UNCHANGED')
  for p0 in r['forbidden_sources']:need(p0 not in newset,'ORIGINAL_FORBIDDEN_SOURCE')
  self.add_target(p,r['candidate']);self.nodes[r['id']]=dict(path=r['candidate']['path'],sha256=r['candidate']['sha256'],value=value);self.proofs[r['id']]=dict(whole_typed_inverse=True,source_delta=r['changes'],old_classification_retained=True)
 def run(self,flush=True):
  need({g['id']for g in self.spec['required_gates']}==M.REQUIRED_GATES,'ALL_ORIGINAL_FIVE_GATES')
  for gate in self.spec['required_gates']:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
  publication=self.read_json_input('publication');need(publication['passed']is True and publication['complete']is True and len(publication['scenes'])==8 and publication['source_first']==publication['source_final'],'ROOT_COMPLETE_EIGHT_PUBLICATION')
  trial=self.read_json_input('trial');need(trial['root_authorized']is True and trial['actual_field_pass']is False and self.inputs['trial']['path']=='res://build/luoyang_regions_20261027d_source01/root_integration_scope08_AUTHORIZED.json'and self.inputs['trial']['sha256']=='9d064035022286b8337c430e635f72528e3975cce91e914f53a351ac5bd71919','ROOT08_SCOPE_IS_PERMISSION_NOT_RESULT')
  rebind=self.read_json_input('rebind');field=rebind['Field'];manifest=self.read_json_input('region_manifest')
  parent_manifest=json.loads(self.read(rebind['manifest']['parent']['path'],rebind['manifest']['parent']['sha256']));back_manifest=copy.deepcopy(manifest)
  need(parent_manifest['runtime_modules'][field['target']]==field['parent']['sha256']and manifest['runtime_modules'][field['target']]==field['candidate']['sha256'],'ONLY_EXACT_REGION_FIELD_MODULE_SUCCESSOR')
  back_manifest['runtime_modules'][field['target']]=parent_manifest['runtime_modules'][field['target']]
  delta=json.loads(self.read(rebind['publication']['path'],rebind['publication']['sha256']));need(delta['passed']is True and delta['errors']==[]and delta['geometry_compile_calls']==delta['Field_instances']==delta['PNG_decodes']==delta['canonical_writes']==0,'ROOT_ACTUAL_VISUAL_ONLY_DELTA')
  selected={r['id']:r for r in delta['components']};need(set(selected)=={'luoyang_civic_market_region_27d','luoyang_estate_region_27d','luoyang_temple_region_27d'},'EXACT_THREE_OUTDOOR_COMPONENTS')
  need(same(manifest['author'],rebind['author_candidate']),'EXACT_VISUAL_AUTHOR_BINDING');self.read(manifest['author']['path'],manifest['author']['sha256']);back_manifest['author']=parent_manifest['author']
  for ident,row in selected.items():
   binding={k:row[k]for k in ['path','sha256','bytes']};need(same(manifest['compiled_bindings'][ident],binding)and row['whole_typed_inverse']is True and row['positive_ground_unchanged']is True and row['npcs_interactions_unchanged']is True,'ACTUAL_INVERSE_GROUND_ACTORS_AREAS_RETAINED');back_manifest['compiled_bindings'][ident]=parent_manifest['compiled_bindings'][ident]
  need(same(back_manifest,parent_manifest),'ONLY_REGIONFIELD_AUTHOR_THREE_BINS_MANIFEST_DELTA')
  for p,h in manifest['runtime_modules'].items():need(p not in self.parents or p==field['target'],'NO_CONTROL_METADATA_MANIFEST_HASH_CYCLE');self.verify_leaf(p,h)
  for binding in manifest['compiled_bindings'].values():need(len(self.read(binding['path'],binding['sha256']))==binding['bytes'],'NINE_FIXED_BINS_SIX_INHERITED_THREE_ACTUAL_DELTAS')
  manifest_target=rebind['manifest']['target'];self.checked_candidate(manifest_target,{'parent':{'path':self.parents[manifest_target]['immutable_old'],'sha256':self.parents[manifest_target]['old_sha256'],'bytes':self.parents[manifest_target]['old_bytes']},'candidate':rebind['manifest']['candidate']});self.add_target(manifest_target,rebind['manifest']['candidate'])
  for p,r in self.bundle['records'].items():
   before,after=self.checked_candidate(p,r);f,v=before.decode(),after.decode()
   for h in r['hunks']:need(f.count(h['old'])==1,'UNIQUE_CODE_FORWARD');f=f.replace(h['old'],h['new'],1)
   for h in reversed(r['hunks']):need(v.count(h['new'])==1,'UNIQUE_CODE_REVERSE');v=v.replace(h['new'],h['old'],1)
   need(f.encode()==after and v.encode()==before,'CODE_FULL_BYTES_INVERSE');self.add_target(p,r['candidate'])
  for p,r in self.bundle['index_proofs'].items():
   on=self.read(self.bundle['records'][p]['candidate']['path'],self.bundle['records'][p]['candidate']['sha256']);off=self.read(r['disabled']['path'],r['disabled']['sha256']);need(off.count(r['disabled_literal'].encode())==1 and r['enabled_literal'].encode()not in off and off.replace(r['disabled_literal'].encode(),r['enabled_literal'].encode())==on,'ORIGINAL_SOLE_DISABLED_BOOL_INDEX_GATE')
  self.add_target(EX,self.bundle['execution']['candidate']);self.nodes['execution_final']=dict(path=self.bundle['execution']['candidate']['path'],sha256=self.bundle['execution']['candidate']['sha256'],value=self.authority)
  contract=self.bundle['contract'];before,after=self.checked_candidate(CT,contract);old=json.loads(before);value=json.loads(after);back=copy.deepcopy(value);raw=before
  need(set(contract['changes'])=={'res://scripts/autoload/scene_router.gd'},'ONLY_CT_ROUTER_ONE_LITERAL')
  for p,c in contract['changes'].items():
   need(old['source_sha256'][p]==c['old']and value['source_sha256'][p]==c['new']and raw.count(c['old'].encode())==1,'CONTRACT_SOURCE_FIXED_OLD');raw=raw.replace(c['old'].encode(),c['new'].encode(),1);back['source_sha256'][p]=c['old']
  need(same(back,old)and raw==after,'CONTRACT_TYPED_RAW_ONE_LITERAL_FULL_INVERSE');self.add_target(CT,contract['candidate']);self.nodes['runtime_contract_final']=dict(path=contract['candidate']['path'],sha256=contract['candidate']['sha256'],value=value)
  # These consumers do NOT accept EX historical pins. Verify every semantic source
  # against fixed DC81 expected data plus declared prospective targets, never observed SHA.
  parent_stage=self.read_json_input('parent_stage');fixed=dict(parent_stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'])
  for p,pin in self.spec['declared_candidates'].items():fixed[p]=pin['sha256']
  need(len(value['source_sha256'])==26,'CT_EXACT_ALL26_SOURCE_DOMAIN')
  for p,h in value['source_sha256'].items():need(fixed.get(p)==h,'CT_ALL26_EXACT_PROSPECTIVE_PIN:'+p);self.verify_leaf(p,h)
  temple=self.bundle['temple_binding'];tb=json.loads(self.read(temple['candidate']['path'],temple['candidate']['sha256']))
  old_tb=json.loads(self.read(temple['parent']['path'],temple['parent']['sha256']));parent_tb=json.loads(self.read(tb['parent_binding_path'],tb['parent_binding_sha256']))
  need(set(temple['changes'])=={CT,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd','res://scripts/autoload/scene_router.gd'},'TEMPLE_ONLY_CT_COORDINATOR_ROUTER_THREE_SOURCE_VALUES')
  reconstructed=json.loads(self.read(temple['parent']['path'],temple['parent']['sha256']));raw_tb=self.read(temple['parent']['path'],temple['parent']['sha256'])
  for p,c in temple['changes'].items():
   need(reconstructed['source_delta'][p]==c['old']and raw_tb.count((json.dumps(p)+': '+json.dumps(c['old'])).encode())==1,'TEMPLE_EXACT_OLD_SOURCE_LITERAL')
   reconstructed['source_delta'][p]=c['new'];raw_tb=raw_tb.replace((json.dumps(p)+': '+json.dumps(c['old'])).encode(),(json.dumps(p)+': '+json.dumps(c['new'])).encode(),1)
  need(same(reconstructed,tb)and raw_tb==self.read(temple['candidate']['path'],temple['candidate']['sha256']),'TEMPLE_ALL_OTHER_TYPED_BYTES_UNCHANGED')
  merged={**parent_tb['source_sha256'],**tb['source_delta']};need(len(merged)==196,'TEMPLE_EXACT196_MERGED_SOURCE_DOMAIN')
  for p,h in merged.items():need(fixed.get(p)==h,'TEMPLE_ALL196_EXACT_PROSPECTIVE_PIN:'+p);self.verify_leaf(p,h)
  for p,r in self.bundle['metadata'].items():self.verify_metadata(p,r)
  need(set(self.targets)==set(self.parents)and len(self.targets)==27,'EXACT27_NO_NOOP_TARGETS')
  for ident,r in self.bundle['maps'].items():
   old=json.loads(self.read(r['parent']['path'],r['parent']['sha256']));value=json.loads(self.read(r['candidate']['path'],r['candidate']['sha256']));expected=copy.deepcopy(old['source_sha256'])
   for p,t in self.targets.items():
    if p in expected:
     need(expected[p]==t['old_sha256'],'PINNED_CURRENT_01656_MAP_PARENT')
     if p in self.authority['owned']:need(self.approved(p,expected[p]),'MAP_EXISTING_ONE_REAL_EDGE')
     expected[p]=t['candidate_sha256']
   for p,h in r['explicit_additions'].items():need(p not in expected and M.valid_sha(h),'ONLY_DECLARED_NEW_MAP_KEYS');expected[p]=h
   need(same(expected,value['source_sha256'])and value['baseline_path']==old['baseline_path']and value['baseline_sha256']==old['baseline_sha256'],'INDEPENDENT_CURRENT_MAP_EXACT_DELTA_NO_HISTORY_REPROMOTION')
   for p,h in expected.items():self.verify_leaf(p,h)
   path,h=self.output('maps/'+value['scene_id']+'_true.json',enc(value));self.nodes[ident]=dict(path=path,sha256=h,value=value);self.proofs[ident]=dict(current_parent=r['parent'],count=len(expected),no_collector_or_current_expected_fill=True)
  for ident,pin in self.bundle['expected_family_maps'].items():
   v=json.loads(self.read(pin['path'],pin['sha256']));node='quarter_final'if ident=='expected_Family_sources'else'estate_final';need(same(v['source_sha256'],self.nodes[node]['value']['source_sha256']),'EXACT_NATURAL_FAMILY_FIRST_FINAL_MAP')
   for p,h in v['source_sha256'].items():self.verify_leaf(p,h)
   path,h=self.output('maps/'+ident+'.json',enc(v));self.nodes[ident]=dict(path=path,sha256=h,value=v)
  patch=['*** Begin Patch\n'];copies=[];reconstruction={}
  for p,r in self.targets.items():
   before=self.read(p,r['old_sha256']);after=self.read(r['candidate_path'],r['candidate_sha256'])
   if p.endswith('.gd'):part,proof=M.build_file_patch(res(p).as_posix(),before,after);patch.append(part);reconstruction[p]=proof
   else:copies.append({**r,'candidate_bytes':len(after),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION'});reconstruction[p]=dict(kind='ExactMechanicalByteCopy',whole_inverse=True,candidate_sha256=sha(after))
  need(len(copies)==15 and len(reconstruction)==27,'EXACT12_GD_PATCH15_JSON_COPY');patch.append('*** End Patch\n');pp,ph=self.output('canonical_deployment.apply_patch',''.join(patch).encode());cp,ch=self.output('canonical_byte_copy_plan.json',enc(dict(rows=copies,patch_copy_disjoint=True,union_exact_targets=True,no_GD_copy_or_native_write=True)))
  final={p:sha(res(p).read_bytes())for p in self.first};need(final==self.first,'SOURCE_FIRST_FINAL_SAME')
  receipt=dict(status='ROOT08_VISUAL_FINISH27_STAGED_NOT_DEPLOYED',targets=list(self.targets.values()),nodes=self.nodes,proofs=self.proofs,source_first=self.first,source_final=final,patch_path=pp,patch_sha256=ph,patch_reconstruction=reconstruction,byte_copy_plan=dict(path=cp,sha256=ch,target_count=15),target_partition=dict(patch_count=12,copy_count=15,total=27),source_baseline='CurrentB78D visual-only successor: three Root actual67124 bins, retire54 proxy+2 isolated render/body pairs, unchanged positive ground/actors/interactions, one genuineGate door relocated to existing west road, decorative underlay and ChineseHUD only. Six rooms and all passed gameplay components inherited. Old294 EX proofs all retained plus3 owned edges and2 ordinary=299; no compiler/import/engine rerun.',no_engine_import_collector_or_canonical_write=True)
  self.output('receipt.json',enc(receipt));need(not res(self.out).exists(),'NEW_STAGE_OUTPUT_ONLY')
  if flush:
   for p,b in self.outputs.items():
    dest=res(p);need(not dest.exists(),'PRESERVE_OLD_OUTPUT');dest.parent.mkdir(parents=True,exist_ok=True)
    with dest.open('xb')as f:f.write(b)
  return dict(output_root=self.out,targets=27,map_nodes=4,source_first_final_count=len(final),receipt_sha256=sha(self.outputs[self.out+'receipt.json']),flushed=flush)
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True);args=parser.parse_args();path=Path(args.input).resolve();raw=path.read_bytes();need(sha(raw)==args.input_sha256,'EXTERNAL_INPUT_LOCK');spec=json.loads(raw);spec['_locked_plan']=dict(path='res://'+path.relative_to(M.ROOT).as_posix(),sha256=args.input_sha256);print(json.dumps(VisualFinish27(spec).run()))
