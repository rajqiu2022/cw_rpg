"""Root-only finite current25g -> service/Garden candidate Stage. No engine/canonical writes."""
import argparse,copy,hashlib,importlib.util,json
from pathlib import Path
GAME=Path(__file__).resolve().parents[2]
PREFIX='res://build/luoyang_city_revision_20261025h_source01/'
CORE=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py'
assert hashlib.sha256(CORE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
sp=importlib.util.spec_from_file_location('fixed_source_core',CORE);M=importlib.util.module_from_spec(sp);sp.loader.exec_module(M);M.PREFIX=PREFIX
need,same,sha,enc,res=M.need,M.same,M.digest,M.encode,M.res
EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
Q='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
ESTATE='res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json'
GARDEN='luoyang_riverside_garden_20261022ap'
class Unified28(M.Stage):
 def __init__(self,spec):
  need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT'and spec.get('blockers')==[],'ROOT_FROZEN_READY_INPUT_REQUIRED')
  super().__init__(spec)
  need(self.inputs['driver']['path']=='res://'+Path(__file__).resolve().relative_to(M.ROOT).as_posix()and self.inputs['driver']['sha256']==sha(Path(__file__).read_bytes()),'EXACT_DRIVER_PIN')
  self.bundle=self.read_json_input('candidates');self.scope=self.read_json_input('scope');self.backup=self.read_json_input('backup');self.parents={r['target']:r for r in self.scope['targets']}
  need(self.scope['count']==len(self.parents)==28 and self.scope['partition']==dict(GD=14,JSON=14),'EXACT28_14_14_DOMAIN')
  need(self.backup['passed']is True and self.backup['status']=='ROOT_ACTUAL_EXACT28_WHOLE_OLD_FILES_BACKED_UP'and self.backup['source_scope_sha256']==self.inputs['scope']['sha256'],'ROOT_ACTUAL_FULL_OLD_BACKUP')
  need(len(self.backup['rows'])==28 and {r['target']for r in self.backup['rows']}==set(self.parents),'EXACT28_BACKUP_DOMAIN')
  prefix=res('res://build/luoyang_city_revision_20261025h_root01/exact28_old_backup/').resolve()
  for r in self.backup['rows']:
   p=r['target'];h=self.parents[p]['old_sha256'];bp=Path(r['backup']).resolve()
   need(bp.is_relative_to(prefix)and h==r['sha256']and r['bytes']==self.parents[p]['old_bytes'],'BACKUP_FIXED_PARENT_AND_PREFIX')
   raw=self.read('res://'+bp.relative_to(M.ROOT).as_posix(),h)
   need(len(raw)==r['bytes']and self.read(p,h)==raw,'BACKUP_WHOLE_OLD_BYTES')
  self.owned=self.read_json_input('owned');prior=json.loads(self.read(self.bundle['execution']['parent']['path'],self.bundle['execution']['parent']['sha256']))
  need(len(prior['owned'])==len(self.authority['owned'])==10 and len(prior['source_sha256'])==170 and len(self.authority['source_sha256'])==176,'OWNED10_170_PLUS6')
  changed=set(self.bundle['execution']['changed_existing_owned']);need(len(changed)==4,'ONLY_FOUR_EXISTING_OWNED_CHANGE')
  restored=copy.deepcopy(self.authority)
  for p,old in prior['owned'].items():
   new=self.authority['owned'][p]
   if p not in changed:need(same(new,old),'OTHER6_OWNED_WHOLE_TYPED_SAME');continue
   r=self.bundle['records'][p];edge=new['edges'][-1]
   need(len(new['edges'])==len(old['edges'])+1 and same(new['edges'][:-1],old['edges'])and edge['old_sha256']==old['current_sha256']==r['parent']['sha256']and edge['new_sha256']==new['current_sha256']==r['candidate']['sha256']and same(edge['replacements'],r['hunks']),'EXACT_ONE_EDGE_NO_SHORTCUT')
   restored['owned'][p]=copy.deepcopy(old)
  extra={p:h for p,h in self.authority['source_sha256'].items()if p not in prior['source_sha256']}
  need(same(extra,self.bundle['execution']['extra'])and len(extra)==6 and all(self.authority['source_sha256'].get(p)==h for p,h in prior['source_sha256'].items()),'OLD170_FIXED_EXACT6_NEW')
  restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior)and enc(restored)==self.read(self.bundle['execution']['parent']['path'],self.bundle['execution']['parent']['sha256']),'EXECUTION_WHOLE_TYPED_BYTE_INVERSE')
 def checked_candidate(self,row):
  before=self.read(row['parent']['path'],row['parent']['sha256']);after=self.read(row['candidate']['path'],row['candidate']['sha256'])
  need(len(before)==row['parent']['bytes']and len(after)==row['candidate']['bytes']and before!=after,'EXACT_LENGTH_CHANGED_ONLY')
  need(row['parent']['sha256']==self.parents[row['target']]['old_sha256']if 'target'in row else True,'EXACT_OLD_SCOPE')
  return before,after
 def add_target(self,p,pin):
  need(p in self.parents and self.parents[p]['old_sha256']!=pin['sha256'],'NO_UNPLANNED_OR_NOOP')
  self.target(p,self.parents[p]['old_sha256'],pin['path'],pin['sha256'])
 def source_fields(self,v,fields):
  result={}
  for ptr in fields:
   for p,h in M.pointer(v,ptr).items():need(p not in result,'DISJOINT_SOURCE_CLASSES');result[p]=h
  return result
 def verify_metadata(self,p,r):
  before,after=self.checked_candidate(dict(r,target=p));old=json.loads(before);value=json.loads(after);rebuilt=copy.deepcopy(old)
  fields=r['source_fields'];oldset=self.source_fields(old,fields);newset=self.source_fields(value,fields)
  need(set(oldset)<=set(newset),'NO_SOURCE_REMOVAL')
  allowednew={**self.bundle['source_additions']['new_execution_proof6']}
  if r['id']!='legacy_manifest_2':allowednew.update(self.bundle['source_additions']['services_flat2'])
  if r['id']in ['legacy_manifest_5','legacy_manifest_8','quarter_final','market_final','finite08_market']:allowednew.update(self.bundle['source_additions']['Garden_full47'])
  if p==ESTATE:need(set(oldset)==set(newset),'ESTATE_EXACT338_KEYS')
  need(all(p in allowednew and allowednew[p]==newset[p]for p in set(newset)-set(oldset)),'ONLY_EXPLICIT_NEW_ORDINARY_LEAVES')
  for change in r['changes']:
   ptr=change['pointer'];holder=M.pointer(rebuilt,ptr[:-1]);key=ptr[-1]
   need((key in holder)==change['existed']and(not change['existed']or same(holder[key],change['old'])),'JSON_EXACT_OLD_VALUE')
   is_source=any(ptr[:len(field)]==field and len(ptr)==len(field)+1 for field in fields)
   if is_source:
    path=ptr[-1];h=change['new'];need(M.valid_sha(h),'EXACT_SOURCE_SHA')
    if change['existed']:
     need(path in self.parents and change['old']==self.parents[path]['old_sha256']and h==self.spec['declared_candidates'][path]['sha256'],'SOURCE_EXISTING_FIXED_TARGET_ONLY')
     if path in self.authority['owned']:need(self.approved(path,change['old']),'ORIGINAL_APPROVED_CURRENT_PARENT_EDGE')
    else:
     need(path in allowednew and h==allowednew[path],'ONLY_APPROVED_ORDINARY_ADDITION')
     if r.get('source_bundle'):need(ptr[0]=='legacy_source_sha256','NEW_ORDINARY_NOT_RUNTIME_AUTHORITY')
   else:
    need(p==Q,'ONLY_EXACT_GARDEN_HEADER_NON_SOURCE_EXCEPTION')
    if ptr==['garden_river_successor']:
     need(not change['existed']and same(change['new'],self.spec['garden_declaration']),'EXACT_BINDING_DECLARATION')
    else:
     need(len(ptr)==3 and ptr[:2]==['scenes',GARDEN]and ptr[2]in ['scene_path','layout_path','packet_path'],'ONLY_GARDEN_THREE_ARTIFACT_PATHS')
     need(change['new']==self.spec['garden_scene_paths'][ptr[2]],'EXACT_PUBLISHED_NEW_NATIVE_PATH')
   holder[key]=copy.deepcopy(change['new'])
  need(same(rebuilt,value),'ALL_METADATA_CHANGES_ENUMERATED')
  back=copy.deepcopy(value)
  for c in reversed(r['changes']):
   holder=M.pointer(back,c['pointer'][:-1]);key=c['pointer'][-1]
   if c['existed']:holder[key]=copy.deepcopy(c['old'])
   else:del holder[key]
  need(same(back,old)and enc(back)==before,'METADATA_WHOLE_TYPED_SERIALIZED_BYTE_INVERSE')
  for protected in r['protected_pointers']:
   if p==Q and protected==['scenes']:need(same(value['scenes']['luoyang_artisan_residential_20261022ap'],old['scenes']['luoyang_artisan_residential_20261022ap']),'ARTISAN_WHOLE_ROW_UNCHANGED')
   else:need(same(M.pointer(value,protected),M.pointer(old,protected)),'PROTECTED_METADATA_POINTER')
  self.add_target(p,r['candidate']);self.nodes[r['id']]=dict(path=r['candidate']['path'],sha256=r['candidate']['sha256'],value=value);self.proofs[r['id']]=dict(whole_typed_inverse=True,source_delta=r['changes'],old_classification_retained=True)
 def run(self):
  gates=self.spec['required_gates'];need({g['id']for g in gates}==M.REQUIRED_GATES,'ALL_ORIGINAL_FIVE_GATES')
  for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
  report=self.read_json_input('garden_actual');need(report['passed']is True and report['published']is True and report['whole_typed_scene_layout_source_expression_match']is True,'NEW_GARDEN_SOURCE_STORAGE_PUBLICATION_GATE')
  trial=self.read_json_input('garden_trial');need(trial['approved_by_root']is True and trial['actual_Field_pass']is False,'ROOT_TRIAL_NOT_ACTUAL_FIELD_PASS')
  for p,r in self.bundle['records'].items():
   before,after=self.checked_candidate(dict(r,target=p));f,v=before.decode(),after.decode()
   for h in r['hunks']:need(f.count(h['old'])==1,'UNIQUE_CODE_FORWARD');f=f.replace(h['old'],h['new'],1)
   for h in reversed(r['hunks']):need(v.count(h['new'])==1,'UNIQUE_CODE_INVERSE');v=v.replace(h['new'],h['old'],1)
   need(f.encode()==after and v.encode()==before,'CODE_FULL_BYTE_INVERSE');self.add_target(p,r['candidate'])
  for p,r in self.bundle['index_proofs'].items():
   b=self.read(self.bundle['records'][p]['candidate']['path'],self.bundle['records'][p]['candidate']['sha256']);off=self.read(r['disabled']['path'],r['disabled']['sha256'])
   need(off.count(r['disabled_literal'].encode())==1 and r['enabled_literal'].encode()not in off and off.replace(r['disabled_literal'].encode(),r['enabled_literal'].encode())==b,'ORIGINAL_INDEX_SOLE_DISABLED_BOOL_GATE')
  self.add_target(EX,self.bundle['execution']['candidate']);self.nodes['execution_final']=dict(path=self.bundle['execution']['candidate']['path'],sha256=self.bundle['execution']['candidate']['sha256'],value=self.authority);self.proofs['execution_final']=dict(whole_typed_inverse=True)
  contract=self.bundle['contract'];before,after=self.checked_candidate(dict(contract,target=CT));old=json.loads(before);value=json.loads(after);back=copy.deepcopy(value)
  need(set(contract['changes'])=={'res://scripts/field/field_walkable_controller.gd'},'ONLY_FIELD_CONTRACT_VALUE')
  for p,c in contract['changes'].items():need(old['source_sha256'][p]==c['old']and value['source_sha256'][p]==c['new'],'CONTRACT_EXACT_VALUES');back['source_sha256'][p]=c['old']
  need(enc(back)==before,'CONTRACT_WHOLE_TYPED_BYTE_INVERSE');self.add_target(CT,contract['candidate']);self.nodes['runtime_contract_final']=dict(path=contract['candidate']['path'],sha256=contract['candidate']['sha256'],value=value);self.proofs['runtime_contract_final']=dict(whole_typed_inverse=True)
  for p,r in self.bundle['metadata'].items():self.verify_metadata(p,r)
  need(set(self.targets)==set(self.parents)and len(self.targets)==28,'EXACT28_NO_NOOP_TARGET_SET')
  for ident,row in self.bundle['maps'].items():
   old=json.loads(self.read(row['parent']['path'],row['parent']['sha256']));value=json.loads(self.read(row['candidate']['path'],row['candidate']['sha256']));expected=self.promote_owned(old['source_sha256'])
   for p,r in self.targets.items():
    if p in expected:need(old['source_sha256'][p]==r['old_sha256'],'EXACT_CURRENT25G_MAP_OLD_VALUE');expected[p]=r['candidate_sha256']
   additions=dict(self.bundle['source_additions']['new_execution_proof6'])
   if ident!='expected_ch4_s0_luoyang_gate_true':additions.update(self.bundle['source_additions']['services_flat2'])
   if ident=='expected_ch4_s3_luoyang_market_true':additions.update(self.bundle['source_additions']['Garden_full47'])
   for p,h in additions.items():need(p not in expected or expected[p]==h,'NO_UNAPPROVED_SOURCE_REPLACEMENT');expected[p]=h
   need(same(expected,value['source_sha256'])and value['baseline_path']==old['baseline_path']and value['baseline_sha256']==old['baseline_sha256'],'INDEPENDENT_CURRENT_MAP_PLUS_EXACT_DECLARED_DELTAS')
   for p,h in expected.items():self.verify_leaf(p,h)
   path,h=self.output('maps/'+value['scene_id']+'_true.json',enc(value));self.nodes[ident]=dict(path=path,sha256=h,value=value);self.proofs[ident]=dict(fixed_current_parent=row['parent'],count=len(expected),no_collector_or_current_expected_fill=True)
  family=json.loads(self.read(self.bundle['expected_Family_sources']['path'],self.bundle['expected_Family_sources']['sha256']));need(same(family['source_sha256'],self.nodes['quarter_final']['value']['source_sha256']),'INDEPENDENT_FAMILY_RECEIPT_FULL_DOMAIN')
  for p,h in family['source_sha256'].items():self.verify_leaf(p,h)
  fp,fh=self.output('maps/expected_Family_source_receipt.json',enc(family));self.nodes['expected_Family_sources']=dict(path=fp,sha256=fh,value=family)
  patch=['*** Begin Patch\n'];copies=[];reconstruction={}
  for p,r in self.targets.items():
   before=self.read(p,r['old_sha256']);after=self.read(r['candidate_path'],r['candidate_sha256'])
   if p.endswith('.gd'):
    part,proof=M._strict_lf_build_file_patch(res(p).as_posix(),before,after);patch.append(part);reconstruction[p]=proof
   else:
    copies.append({**r,'candidate_bytes':len(after),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION'});reconstruction[p]=dict(kind='ExactMechanicalByteCopy',whole_inverse=True,candidate_sha256=sha(after))
  need(len(copies)==14 and len(reconstruction)==28,'STRICT14_GD_PATCH14_JSON_COPY')
  patch.append('*** End Patch\n');pp,ph=self.output('canonical_deployment.apply_patch',''.join(patch).encode());cp,ch=self.output('canonical_byte_copy_plan.json',enc(dict(rows=copies,patch_copy_disjoint=True,union_exact_targets=True,no_GD_copy_or_native_write=True)))
  final={p:sha(res(p).read_bytes())for p in self.first};need(final==self.first,'SOURCE_FIRST_FINAL_SAME')
  receipt=dict(status='SERVICE_GARDEN_EXACT28_STAGED_NOT_DEPLOYED',targets=list(self.targets.values()),nodes=self.nodes,proofs=self.proofs,source_first=self.first,source_final=final,patch_path=pp,patch_sha256=ph,patch_reconstruction=reconstruction,byte_copy_plan=dict(path=cp,sha256=ch,target_count=14),target_partition=dict(patch_count=14,copy_count=14,total=28),source_baseline='Pinned current25g C972/7F2A only; new Garden56 native plus four scoped indoor services. No old AO promotion, no collector, no geometry replay.',no_engine_import_collector_or_canonical_write=True)
  self.output('receipt.json',enc(receipt));need(not res(self.out).exists(),'NEW_OUTPUT_ONLY')
  for p,b in self.outputs.items():
   dest=res(p);need(not dest.exists(),'PRESERVE_OLD_OUTPUTS');dest.parent.mkdir(parents=True,exist_ok=True)
   with dest.open('xb')as f:f.write(b)
  return dict(output_root=self.out,targets=28,map_nodes=4,receipt_sha256=sha(self.outputs[self.out+'receipt.json']))
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True);args=parser.parse_args();path=Path(args.input).resolve();raw=path.read_bytes();need(sha(raw)==args.input_sha256,'EXTERNAL_INPUT_LOCK');spec=json.loads(raw);spec['_locked_plan']=dict(path='res://'+path.relative_to(M.ROOT).as_posix(),sha256=args.input_sha256);print(json.dumps(Unified28(spec).run()))
