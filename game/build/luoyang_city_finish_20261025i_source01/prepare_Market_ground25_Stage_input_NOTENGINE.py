from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def emit(name,b):
 p=N/name;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=S+name,sha256=sha(b),bytes=len(b))
parent=(N/'stage_gate_portal_repair31_ROOT_ONLY.py').read_bytes();t=parent.decode();hunks=[]
def change(a,b):
 global t
 assert t.count(a)==1,(a,t.count(a));t=t.replace(a,b,1);hunks.append(dict(old=a,new=b))
change('class Repair31(M.Stage):','class Market25(M.Stage):')
start=t.index("  need(self.scope['count']==len(self.parents)==31");end=t.index('  prior=json.loads',start);old=t[start:end]
new="""  need(self.scope['count']==len(self.parents)==25 and self.scope['partition']==dict(GD=11,JSON=14),'EXACT25_11GD14JSON_SCOPE')
  need(self.backup['status']=='ROOT_CURRENT5D6C_FULL25_BACKUP_AND_FRESH_OBSERVATION'and self.backup['passed']is True and self.backup['total_backups']==265 and self.backup['external_save_changes']==[]and self.backup['canonical_writes']==0 and self.backup['scope']['sha256']==self.inputs['scope']['sha256'],'ROOT_ACTUAL_CURRENT5D6C_BACKUP25')
  rows=self.backup['new_backups'];need(len(rows)==25 and {r['target']for r in rows}==set(self.parents),'ROOT_BACKUP25_EXACT_DOMAIN')
  current={r['target']:r for r in self.backup['current32']};need(len(current)==32,'CURRENT32_SCOPE_WITH_NOOP_CONSUMERS_PRESERVED')
  for p,r in current.items():need(len(self.read(p,r['sha256']))==r['bytes'],'ROOT_CURRENT5D6C_ALL32_EXACT')
  for r in rows:
   p=r['target'];parent=self.parents[p];need(r['backup'].startswith(PREFIX+'market_ground_texture_repair02/root_only_current25_backup/'),'ROOT_BACKUP25_FIXED_NAMESPACE')
   b=self.read(r['backup'],r['sha256']);need(len(b)==r['bytes']==parent['old_bytes']and r['sha256']==parent['old_sha256']and b==self.read(parent['immutable_old'],parent['old_sha256'])==self.read(p,parent['old_sha256']),'ROOT_BACKUP25_WHOLE_IMMUTABLE_CURRENT_PARENT')
"""
change(old,new)
for a,b in [
("len(prior['source_sha256'])==183 and len(self.authority['source_sha256'])==189,'OWNED10_183_PLUS6'","len(prior['source_sha256'])==189 and len(self.authority['source_sha256'])==194,'OWNED10_189_PLUS5'"),
("len(changed)==4,'ONLY_FOUR_REAL_OWNED_EDGES'","len(changed)==3,'ONLY_THREE_REAL_OWNED_EDGES'"),
("'OTHER_SIX_OWNED_IDENTICAL'","'OTHER_SEVEN_OWNED_IDENTICAL'"),('len(extra)==6 and all','len(extra)==5 and all'),("'ALL_OLD183_FIXED_SIX_NEW'","'ALL_OLD189_FIXED_FIVE_NEW'"),
("set(contract['changes'])=={'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd'},'ONLY_C_FIELD_TWO_CONTRACT_VALUES'","set(contract['changes'])=={'res://scripts/field/field_walkable_controller.gd'},'ONLY_FIELD_ONE_CONTRACT_VALUE'"),
("len(self.targets)==31,'EXACT31_NO_NOOP_TARGETS'","len(self.targets)==25,'EXACT25_NO_NOOP_TARGETS'"),
("'PINNED_CURRENT4160_MAP_PARENT'","'PINNED_CURRENT5D6C_MAP_PARENT'"),
("len(reconstruction)==31,'EXACT17_GD_PATCH14_JSON_COPY'","len(reconstruction)==25,'EXACT11_GD_PATCH14_JSON_COPY'"),
("status='GATE_TEXTURE_MARKET_PORTAL_EXACT31_STAGED_NOT_DEPLOYED'","status='MARKET_AE_TEXTURE_EXACT25_STAGED_NOT_DEPLOYED'"),
('dict(patch_count=17,copy_count=14,total=31)','dict(patch_count=11,copy_count=14,total=25)'),
('Pinned current4160/37D7 exact increment. Old OWNED10/proof183 retained+6, depth16, no shortcut. No old AO repromotion. Geometry/masks unchanged.','Pinned current5D6C/275C exact increment. Old OWNED10/proof189 retained+5, depth16, no shortcut. Only exact Market AE Field bridge. Geometry/masks/runtime unchanged.'),
('targets=31,map_nodes=4','targets=25,map_nodes=4'),('Repair31(spec).run()','Market25(spec).run()')]:change(a,b)
back=t
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==parent;compile(t,'stage_Market_ground25_ROOT_ONLY.py','exec');driver=emit('stage_Market_ground25_ROOT_ONLY.py',t.encode());proof=emit('market_ground_texture_repair02/Stage25_driver_exact_adaptation_inverse.json',enc(dict(parent_sha256=sha(parent),driver=driver,hunks=hunks,whole_byte_inverse=True,all_original_five_gates_approved_classification_depth16_retained=True,Stage_calls=0,engine_calls=0)))
text=(N/'prepare_repair31_stage_input_NOTENGINE.py').read_text()
for a,b in [('repair31_READY02','market_ground25_READY01'),('7b50bec8b6f34f3f93dd050f35c10776013e2ebebdc8383824ca60176e05bf39','c699076933993a1fbdc89981b2d606260318dc764b543b85a45ea9c56dc395a4'),('stage_gate_portal_repair31_ROOT_ONLY.py','stage_Market_ground25_ROOT_ONLY.py'),('root_gate_texture_market_portal_exact31_stage01/','root_Market_AE_texture_exact25_stage01/'),('len(targets)==31','len(targets)==25'),('len(patchproof)==17','len(patchproof)==11'),('EXACT31_OFFLINE','EXACT25_OFFLINE'),('count=31,partition=dict(GD=17,JSON=14)','count=25,partition=dict(GD=11,JSON=14)'),('all31_fullbytes_inverse','all25_fullbytes_inverse'),('source_input_gate_portal_repair31_ROOT_REVIEW.json','source_input_Market_ground25_ROOT_REVIEW.json'),('finite_preStage31_declaration_audit_READONLY.json','finite_preStage25_declaration_audit_READONLY.json')]:assert a in text,a;text=text.replace(a,b)
print('DRIVER',json.dumps(dict(driver=driver,proof=proof)))
exec(compile(text,str(N/'prepare_Market_ground25_stage_input_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_Market_ground25_stage_input_DERIVED_NOTENGINE.py')})
