"""Root-onlyCE38 exact32 one Garden wall retirement and exact original Garden-to-Estate cold lifecycle. Other C/Field/G/pawnshop functions unchanged; no engine or canonical writes."""
import argparse,copy,hashlib,importlib.util,json
from pathlib import Path
GAME=Path(__file__).resolve().parents[2];PREFIX='res://build/luoyang_city_finish_20261025i_source01/'
CORE=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py'
assert hashlib.sha256(CORE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
sp=importlib.util.spec_from_file_location('fixed_source_core',CORE);M=importlib.util.module_from_spec(sp);sp.loader.exec_module(M);M.PREFIX=PREFIX
M.AUTHORITY_SHA='f120512a771d7e3e482b5befac0f39d44fb0abf794be0805fcd0fe4e638bb5bc'
M.EXACT_EOL_CANDIDATES={'res://scripts/autoload/scene_router.gd':('2687a0d72d6bf34654894905b9caf2082c3fdf97e7db4633e518996569d2650c',13)}
# Router is an exact unchanged parent this epoch; no EOL transport is needed.
need,same,sha,enc,res=M.need,M.same,M.digest,M.encode,M.res
EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
class GardenEstate32(M.Stage):
 def __init__(self,spec):
  need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT'and spec.get('blockers')==[],'ROOT_LOCKED_INPUT')
  super().__init__(spec)
  need(self.inputs['driver']['path']=='res://'+Path(__file__).resolve().relative_to(M.ROOT).as_posix()and self.inputs['driver']['sha256']==sha(Path(__file__).read_bytes()),'EXACT_DRIVER_PIN')
  self.bundle=self.read_json_input('candidates');self.scope=self.read_json_input('scope');self.backup=self.read_json_input('backup');self.parents={r['target']:r for r in self.scope['targets']}
  need(self.scope['count']==len(self.parents)==32 and self.scope['partition']==dict(GD=18,JSON=14),'EXACT32_18GD14JSON_SCOPE')
  need(self.backup['status']=='ROOT_CURRENT_CE38_FULL32_BACKUP_AND_FRESH_OBSERVATION'and self.backup['passed']is True and self.backup['total_backups']==737 and self.backup['external_save_changes']==[]and self.backup['canonical_writes']==0 and self.backup['scope']['sha256']==self.inputs['scope']['sha256'],'ROOT_ACTUAL_CE38_BACKUP32')
  rows=self.backup['new_backups'];need(len(rows)==32 and {r['target']for r in rows}==set(self.parents),'ROOT_BACKUP32_EXACT_DOMAIN')
  need(len(self.backup['current37'])==37,'CURRENT37_NOOP_PAWN_G_AUTHORITY_PRESERVED')
  for r in self.backup['current37']:need(len(self.read(r['target'],r['sha256']))==r['bytes'],'CURRENT37_IMMUTABLE_PARENT')
  for r in rows:
   p=r['target'];parent=self.parents[p];need(r['backup'].startswith(PREFIX+'garden_estate_exit_repair_20261027c01/root_only_current32_backup/'),'ROOT_BACKUP32_FIXED_NAMESPACE')
   need(self.read(r['backup'],r['sha256'])==self.read(parent['immutable_old'],parent['old_sha256'])==self.read(p,parent['old_sha256']) and r['sha256']==parent['old_sha256'] and r['bytes']==parent['old_bytes'],'ROOT_FULL_BACKUP32_WHOLE_CURRENT_IMMUTABLE')
  prior=json.loads(self.read(self.bundle['execution']['parent']['path'],self.bundle['execution']['parent']['sha256']));need(len(prior['owned'])==len(self.authority['owned'])==10 and len(prior['source_sha256'])==270 and len(self.authority['source_sha256'])==277,'OWNED10_270_PLUS7_EQUALS277')
  changed=set(self.bundle['execution']['changed_existing_owned']);need(changed==set(self.spec['five_owned_targets'])and len(changed)==5,'ONLY_FIVE_REAL_OWNED_EDGES')
  back=copy.deepcopy(self.authority)
  for p,old in prior['owned'].items():
   new=self.authority['owned'][p]
   if p not in changed:need(same(old,new),'OTHER_FIVE_OWNED_IDENTICAL');continue
   r=self.bundle['records'][p];edge=new['edges'][-1]
   need(len(new['edges'])==len(old['edges'])+1 and same(new['edges'][:-1],old['edges'])and edge['old_sha256']==old['current_sha256']==r['parent']['sha256']and edge['new_sha256']==new['current_sha256']==r['candidate']['sha256']and same(edge['replacements'],r['hunks']),'ONE_EXACT_EDGE_NO_SHORTCUT')
   back['owned'][p]=copy.deepcopy(old)
  extra={p:h for p,h in self.authority['source_sha256'].items()if p not in prior['source_sha256']};need(same(extra,self.bundle['execution']['extra'])and len(extra)==7 and all(self.authority['source_sha256'].get(p)==h for p,h in prior['source_sha256'].items()),'ALL_OLD270_FIXED_SEVEN_NEW')
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
  need(set(oldset)<=set(newset)and same({p:newset[p]for p in set(newset)-set(oldset)},allowed)and same(allowed,self.bundle['source_additions_by_metadata'][r['id']]),'EXACT_DECLARED_ORDINARY_ADDITIONS_NO_REMOVAL')
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
  trial=self.read_json_input('trial');need(trial['admitted']is True and trial['permission_kind']=='TRIAL_PERMISSION_NOT_RESULT'and trial['actual_Field_pass']is False and self.inputs['trial']['path']==PREFIX+'finish8_ROOT_TRIAL_PERMISSION07.json'and self.inputs['trial']['sha256']=='439d2df41ab8767b19a76ae3d7a426e66b751f131d1df2783ac3bcb774d25b88','TRIAL_PERMISSION_NOT_RESULT')
  seal=self.read_json_input('seal');binding=json.loads(self.read(seal['binding']['path'],seal['binding']['sha256']));prior_binding=json.loads(self.read(seal['binding_inverse']['parent']['path'],seal['binding_inverse']['parent']['sha256']));market=binding['scenes']['ch4_s3_luoyang_market']
  finite=self.read_json_input('local_publication');need(finite['passed']is True and not finite['errors']and finite['whole_payload_inverse']is True and finite['whole_RGBA_inverse']is True and finite['retired_id']=='seven26c_garden_west_dry_outer_edge'and finite['source_first']==finite['source_final'],'EXACT_LOCAL_ONE_GARDEN_WALL_ACTUAL')
  id='luoyang_riverside_garden_20261022ap';row=binding['scenes'][id];need(row['trial']['path']==self.inputs['trial']['path']and row['trial']['sha256']==self.inputs['trial']['sha256']and row['required_source_sha256'].get(self.inputs['trial']['path'])==self.inputs['trial']['sha256']and row['payload']==finite['payload']and row['fingerprints']==finite['fingerprints'],'ROOT07_AND_GARDEN_PAYLOAD_BOUND')
  need(all(binding['scenes'][key]==prior_binding['scenes'][key]for key in binding['scenes']if key!=id),'OTHER_SEVEN_BIND_ROWS_IDENTICAL')
  for p,r in self.bundle['records'].items():
   before,after=self.checked_candidate(p,r);f,v=before.decode(),after.decode()
   for h in r['hunks']:need(f.count(h['old'])==1,'UNIQUE_CODE_FORWARD');f=f.replace(h['old'],h['new'],1)
   for h in reversed(r['hunks']):need(v.count(h['new'])==1,'UNIQUE_CODE_REVERSE');v=v.replace(h['new'],h['old'],1)
   need(f.encode()==after and v.encode()==before,'CODE_FULL_BYTES_INVERSE');self.add_target(p,r['candidate'])
  for p,r in self.bundle['index_proofs'].items():
   on=self.read(self.bundle['records'][p]['candidate']['path'],self.bundle['records'][p]['candidate']['sha256']);off=self.read(r['disabled']['path'],r['disabled']['sha256']);need(off.count(r['disabled_literal'].encode())==1 and r['enabled_literal'].encode()not in off and off.replace(r['disabled_literal'].encode(),r['enabled_literal'].encode())==on,'ORIGINAL_SOLE_DISABLED_BOOL_INDEX_GATE')
  self.add_target(EX,self.bundle['execution']['candidate']);self.nodes['execution_final']=dict(path=self.bundle['execution']['candidate']['path'],sha256=self.bundle['execution']['candidate']['sha256'],value=self.authority)
  contract=self.bundle['contract'];before,after=self.checked_candidate(CT,contract);old=json.loads(before);value=json.loads(after);back=copy.deepcopy(value);raw=before
  need(set(contract['changes'])=={'res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'},'ONLY_CT_FIELD_C_TWO_LITERALS')
  for p,c in contract['changes'].items():
   need(old['source_sha256'][p]==c['old']and value['source_sha256'][p]==c['new']and raw.count(c['old'].encode())==1,'CONTRACT_SOURCE_FIXED_OLD');raw=raw.replace(c['old'].encode(),c['new'].encode(),1);back['source_sha256'][p]=c['old']
  need(same(back,old)and raw==after,'CONTRACT_TYPED_RAW_TWO_LITERAL_FULL_INVERSE');self.add_target(CT,contract['candidate']);self.nodes['runtime_contract_final']=dict(path=contract['candidate']['path'],sha256=contract['candidate']['sha256'],value=value)
  # These consumers do NOT accept EX historical pins. Verify every semantic source
  # against fixed DC81 expected data plus declared prospective targets, never observed SHA.
  parent_stage=self.read_json_input('parent_stage');fixed=dict(parent_stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'])
  for p,pin in self.spec['declared_candidates'].items():fixed[p]=pin['sha256']
  need(len(value['source_sha256'])==26,'CT_EXACT_ALL26_SOURCE_DOMAIN')
  for p,h in value['source_sha256'].items():need(fixed.get(p)==h,'CT_ALL26_EXACT_PROSPECTIVE_PIN:'+p);self.verify_leaf(p,h)
  temple=self.bundle['temple_binding'];tb=json.loads(self.read(temple['candidate']['path'],temple['candidate']['sha256']))
  old_tb=json.loads(self.read(temple['parent']['path'],temple['parent']['sha256']));parent_tb=json.loads(self.read(tb['parent_binding_path'],tb['parent_binding_sha256']))
  need(set(temple['changes'])=={'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd',CT,'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'},'TEMPLE_ONLY_C_FIELD_CT_COORDINATOR_SOURCE_VALUES')
  reconstructed=json.loads(self.read(temple['parent']['path'],temple['parent']['sha256']));raw_tb=self.read(temple['parent']['path'],temple['parent']['sha256'])
  for p,c in temple['changes'].items():
   need(reconstructed['source_delta'][p]==c['old']and raw_tb.count((json.dumps(p)+': '+json.dumps(c['old'])).encode())==1,'TEMPLE_EXACT_OLD_SOURCE_LITERAL')
   reconstructed['source_delta'][p]=c['new'];raw_tb=raw_tb.replace((json.dumps(p)+': '+json.dumps(c['old'])).encode(),(json.dumps(p)+': '+json.dumps(c['new'])).encode(),1)
  need(same(reconstructed,tb)and raw_tb==self.read(temple['candidate']['path'],temple['candidate']['sha256']),'TEMPLE_ALL_OTHER_TYPED_BYTES_UNCHANGED')
  merged={**parent_tb['source_sha256'],**tb['source_delta']};need(len(merged)==196,'TEMPLE_EXACT196_MERGED_SOURCE_DOMAIN')
  for p,h in merged.items():need(fixed.get(p)==h,'TEMPLE_ALL196_EXACT_PROSPECTIVE_PIN:'+p);self.verify_leaf(p,h)
  for p,r in self.bundle['metadata'].items():self.verify_metadata(p,r)
  need(set(self.targets)==set(self.parents)and len(self.targets)==32,'EXACT32_NO_NOOP_TARGETS')
  for ident,r in self.bundle['maps'].items():
   old=json.loads(self.read(r['parent']['path'],r['parent']['sha256']));value=json.loads(self.read(r['candidate']['path'],r['candidate']['sha256']));expected=copy.deepcopy(old['source_sha256'])
   for p,t in self.targets.items():
    if p in expected:
     need(expected[p]==t['old_sha256'],'PINNED_CURRENT_CE38_MAP_PARENT')
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
  need(len(copies)==14 and len(reconstruction)==32,'EXACT18_GD_PATCH14_JSON_COPY');patch.append('*** End Patch\n');pp,ph=self.output('canonical_deployment.apply_patch',''.join(patch).encode());cp,ch=self.output('canonical_byte_copy_plan.json',enc(dict(rows=copies,patch_copy_disjoint=True,union_exact_targets=True,no_GD_copy_or_native_write=True)))
  final={p:sha(res(p).read_bytes())for p in self.first};need(final==self.first,'SOURCE_FIRST_FINAL_SAME')
  receipt=dict(status='GARDEN_ESTATE_SOURCE_EXACT32_STAGED_NOT_DEPLOYED',targets=list(self.targets.values()),nodes=self.nodes,proofs=self.proofs,source_first=self.first,source_final=final,patch_path=pp,patch_sha256=ph,patch_reconstruction=reconstruction,byte_copy_plan=dict(path=cp,sha256=ch,target_count=14),target_partition=dict(patch_count=18,copy_count=14,total=32),source_baseline='PinnedCE38 exact32 successor. Original270 proof values/all10owned edges retained plus7=277 with five real owned successors. Only Garden isolated wall visual/body/mask retirement and exact AP-managed Garden-to-Estate independent original Estate begin/finish. Other seven payloads, portals, NPCs, water/bridge, C/Field/G/pawnshop functions unchanged. Material only runtime/BIND headers; CT26/Temple196 include current Router exact prospective pins. Root07 is permission, not actual Field or whole-city ART result.',no_engine_import_collector_or_canonical_write=True)
  self.output('receipt.json',enc(receipt));need(not res(self.out).exists(),'NEW_STAGE_OUTPUT_ONLY')
  if flush:
   for p,b in self.outputs.items():
    dest=res(p);need(not dest.exists(),'PRESERVE_OLD_OUTPUT');dest.parent.mkdir(parents=True,exist_ok=True)
    with dest.open('xb')as f:f.write(b)
  return dict(output_root=self.out,targets=32,map_nodes=4,source_first_final_count=len(final),receipt_sha256=sha(self.outputs[self.out+'receipt.json']),flushed=flush)
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True);args=parser.parse_args();path=Path(args.input).resolve();raw=path.read_bytes();need(sha(raw)==args.input_sha256,'EXTERNAL_INPUT_LOCK');spec=json.loads(raw);spec['_locked_plan']=dict(path='res://'+path.relative_to(M.ROOT).as_posix(),sha256=args.input_sha256);print(json.dumps(GardenEstate32(spec).run()))
