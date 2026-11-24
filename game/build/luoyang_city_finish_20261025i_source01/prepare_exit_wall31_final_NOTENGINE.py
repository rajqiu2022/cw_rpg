"""Existing31 Stage transport for the approved two portals/four Market walls; never executes Stage."""
from pathlib import Path
import hashlib,json,difflib
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'exit_wall_repair_20261027b01/';O=N/'exit_wall_repair_20261027b01'
sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def raw(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return b
def load(pin):return json.loads(raw(pin))
def emit(p,b):
 d=G/p[6:];assert not d.exists();d.parent.mkdir(parents=True,exist_ok=True)
 with d.open('xb')as f:f.write(b)
 return dict(path=p,sha256=sha(b),bytes=len(b))
bp=dict(path=P+'unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256=sha((O/'unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json').read_bytes()));bundle=load(bp);seal=load(bundle['seal'])
parentpin=dict(path=S+'stage_seven_fields31_ROOT_ONLY.py',sha256='');parent=(N/'stage_seven_fields31_ROOT_ONLY.py').read_bytes();parentpin['sha256']=sha(parent);t=parent.decode('utf8')
for x,y in [
 ('Root-only DFCF exact31 seven-field layout and Market single-patrol data successor. C/Field/Router and pawnshop algorithms unchanged. No engine/canonical writes.','Root-only81C exact31 two Chinese portal labels/spacing and four adult Market walls. Unchanged C/Field/Router/pawnshop algorithms; no engine or canonical writes.'),
 ('SevenField31','ExitWall31'),('ROOT_CURRENT_DFCF_FULL31_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_81C_FULL31_BACKUP_AND_FRESH_OBSERVATION'),("self.backup['total_backups']==626","self.backup['total_backups']==705"),('ROOT_ACTUAL_DFCF_BACKUP31','ROOT_ACTUAL_81C_BACKUP31'),('seven_fields_layout_repair01/root_only_current31_backup/','exit_wall_repair_20261027b01/root_only_current31_backup/'),
 ("len(prior['source_sha256'])==252 and len(self.authority['source_sha256'])==258","len(prior['source_sha256'])==264 and len(self.authority['source_sha256'])==270"),('OWNED10_252_PLUS6_EQUALS258','OWNED10_264_PLUS6_EQUALS270'),('ALL_OLD252_FIXED_SIX_NEW','ALL_OLD264_FIXED_SIX_NEW'),
 ('finish8_ROOT_TRIAL_PERMISSION05.json','finish8_ROOT_TRIAL_PERMISSION06.json'),('772cff2bc2c3199df2026427dd3f2bc7a022b9bb090a1bda7a9be46ed0d1b581','56504f0f82c0f371d4179e4ecffb4dcd210d2a8f445f7de2f48e29ee7595048e'),('PINNED_CURRENT_DFCF_MAP_PARENT','PINNED_CURRENT_81C_MAP_PARENT'),('SEVEN_FIELDS_LAYOUT_SOURCE_EXACT31_STAGED_NOT_DEPLOYED','EXIT_WALL_SOURCE_EXACT31_STAGED_NOT_DEPLOYED')]:
 assert x in t,x;t=t.replace(x,y)
x=t.index("  finite=self.read_json_input('seven_publication')");y=t.index("  for p,r in self.bundle['records'].items():",x)
t=t[:x]+'''  finite=self.read_json_input('local_publication');need(finite['passed']is True and not finite['errors']and finite['checks']==18544 and len(finite['components'])==3 and finite['source_first']==finite['source_final'],'EXACT_LOCAL_TWO_PORTALS_FOUR_WALLS_ACTUAL')
  for id,result in finite['components'].items():
   row=binding['scenes'][id];need(row['trial']['path']==self.inputs['trial']['path']and row['trial']['sha256']==self.inputs['trial']['sha256']and row['required_source_sha256'].get(self.inputs['trial']['path'])==self.inputs['trial']['sha256']and row['payload']==result['payload']and row['fingerprints']==result['fingerprints'],'ROOT06_AND_LOCAL_PAYLOAD_BOUND:'+id)
  need(all(binding['scenes'][id]==prior_binding['scenes'][id]for id in binding['scenes']if id not in finite['components']),'OTHER_FIVE_BIND_ROWS_IDENTICAL')
''' +t[y:]
x="Pinned DFCF exact31 successor. All owned10/old252 values and edges retained plus6 proofs=258 and4 real owned edges. Seven-field content and existing-purpose data, strict Artisan appended-ID material handling and Market single patrol migration only. All C/Field/Router and pawnshop algorithms unchanged. Runtime only SELF/BIND headers; CT26/Temple196 prospective checks retained. Finite source-publication credit is not actual Field or whole-city ART pass."
y="Pinned81C exact31 successor. Original264 proof values/all10owned edges retained plus6=270 with four real owned successors. Only Yamen/Artisan portal labels and Yamen120700 reciprocal arrival, four Market adult walls/local mask; Artisan material only whole-payload SHA and source headers. C/Field/Router/G/pawnshop/other five scene functions unchanged. CT26/Temple196 prospective checks remain exact. Root06 is permission, not actual Field or whole-city ART result."
assert x in t;t=t.replace(x,y)
compile(t,'stage_exit_wall31_ROOT_ONLY.py','exec');driver=emit(S+'stage_exit_wall31_ROOT_ONLY.py',t.encode('utf8'))
hs=[]
for z in difflib.SequenceMatcher(None,parent.decode().splitlines(True),t.splitlines(True),autojunk=False).get_grouped_opcodes(2):
 aa=parent.decode().splitlines(True);bb=t.splitlines(True);hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=t
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==t and v.encode()==parent
proof=emit(P+'Stage31_transport_whole_inverse_NOT_STAGE.json',enc(dict(parent=parentpin,candidate=driver,hunks=hs,whole_UTF8_inverse=True,Stage_calls=0,engine_calls=0)))
pins=[dict(id='driver',**driver),dict(id='candidates',**bp),dict(id='scope',**bundle['scope']),dict(id='backup',**bundle['root_backup']),dict(id='code',**bundle['code_proof']),dict(id='execution',**bundle['execution']['candidate']),dict(id='authority_helper',**bundle['authority_helper']),dict(id='publication',**bundle['publication']),dict(id='trial',**bundle['trial']),dict(id='parent_stage',**bundle['parent_stage']),dict(id='seal',**bundle['seal']),dict(id='local_publication',**seal['Portal_wall_publication'])]
gates=[]
for i,g in enumerate(bundle['old_required_gates']):
 k='gate_'+str(i);pins.append(dict(id=k,**g['pin']));gates.append(dict(id=g['id'],input=k,pointer=g['pointer'],equals=g['equals']))
gates.append(dict(id='root_target_preauthorization',input='trial',pointer=['admitted'],equals=True))
spec=dict(schema_version=1,status='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT',blockers=[],output_root=S+'outputs/root_exit_wall_exact31_stage01/',pinned_inputs=pins,authority_input='execution',authority_helper_input='authority_helper',prospective_targets=[dict(target=r['target'],candidate_path=r['candidate']['path'],sha256=r['candidate']['sha256'],bytes=r['candidate']['bytes'])for r in bundle['targets']],declared_candidates={r['target']:r['candidate']for r in bundle['targets']},five_owned_targets=bundle['execution']['changed_existing_owned'],required_gates=gates,source_groups=[],nodes=[])
# Reuse the existing exact prospective-value preflight, with fixed parent/source declarations, not a collector.
fixed=dict(load(bundle['parent_stage'])['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256']);fixed.update({r['target']:r['candidate']['sha256']for r in bundle['targets']})
ct=load(bundle['contract']['candidate'])['source_sha256'];tb=load(bundle['temple_binding']['candidate']);base=load(dict(path=tb['parent_binding_path'],sha256=tb['parent_binding_sha256']));ts={**base['source_sha256'],**tb['source_delta']};assert len(ct)==26 and len(ts)==196
for table in [ct,ts]:
 for p,h in table.items():assert fixed[p]==h,(p,h,fixed.get(p))
inp=emit(P+'source_input_exit_wall31_ROOT_REVIEW.json',enc(spec));print(json.dumps(dict(driver=driver,input=inp,proof=proof,descriptor=bp,maps={k:r['count']for k,r in bundle['maps'].items()})))
