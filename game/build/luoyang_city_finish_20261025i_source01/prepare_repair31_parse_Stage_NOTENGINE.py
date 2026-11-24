from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def write(name,b):
 p=N/name;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=NS+name,sha256=sha(b),bytes=len(b))
bundle=json.loads((N/'repair31_READY02/unified32_all_candidates_and_inverse_NOT_STAGE.json').read_bytes())
code=json.loads((G/bundle['code_proof']['path'][6:]).read_bytes())
seal=json.loads((G/bundle['seal']['path'][6:]).read_bytes())
pins=[seal['runtime']]+[r['candidate']for r in code['records'].values()]
assert len(pins)==10 and len({p['path']for p in pins})==10
oldspec=json.loads((N/'parse12_ROOT_READY/input_ROOT_READY.json').read_bytes())
P=NS+'gate_texture_repair01/parse10_ROOT_READY/'
spec=dict(status='ROOT_ONLY_REPAIR10_GD_PARSE_NO_BUSINESS',ready=True,scripts=pins,save_paths=oldspec['save_paths'],source_proof=bundle['code_proof'],base_paths=[r['target']for r in bundle['targets']],output_prefix=P+'output/')
ip=write('gate_texture_repair01/parse10_ROOT_READY/input_ROOT_READY.json',enc(spec))
parent=(N/'parse12_ROOT_READY/parse_ROOT_READY.gd').read_bytes();t=parent.decode();changes=[]
def sub(a,b):
 global t
 assert t.count(a)==1,(a,t.count(a));t=t.replace(a,b,1);changes.append(dict(old=a,new=b))
sub(oldspec.get('unused','res://build/luoyang_city_finish_20261025i_source01/parse12_ROOT_READY/input_ROOT_READY.json'),ip['path'])
sub(sha((N/'parse12_ROOT_READY/input_ROOT_READY.json').read_bytes()),ip['sha256'])
sub('raw.get("scripts",[]).size()==12','raw.get("scripts",[]).size()==10')
sub('EXACT_TWELVE_SCRIPTS_FIFTEEN_SAVE_FACTS','EXACT_TEN_SCRIPTS_FIFTEEN_SAVE_FACTS')
sub('collect all12 results.','collect all10 results.')
sub('rows.size()==12,"ALL_TWELVE_RESULTS_WITHOUT_EARLY_BREAK"','rows.size()==10,"ALL_TEN_RESULTS_WITHOUT_EARLY_BREAK"')
back=t
for h in reversed(changes):back=back.replace(h['new'],h['old'],1)
assert back.encode()==parent
key=write('gate_texture_repair01/parse10_ROOT_READY/parse_ROOT_READY.gd',t.encode())
parseproof=write('gate_texture_repair01/parse10_ROOT_READY/mechanical_whole_inverse_READY.json',enc(dict(input=ip,key=key,hunks=changes,parent_sha256=sha(parent),whole_byte_inverse=True,engine_calls=0,canonical_writes=0)))
print('PARSE',json.dumps(dict(key=key,input=ip,proof=parseproof)))

# Only current4160 parent/superset backup/count adaptations. All original gates remain.
parent=(N/'stage_finish8_exact32_ROOT_ONLY.py').read_bytes();t=parent.decode();changes=[]
sub('"""Root-only finite current25h -> eight exteriors source Stage; no engine/canonical writes."""','"""Root-only current4160 Gate texture / Market portal exact31 source successor; no engine/canonical writes."""')
sub("class Unified32(M.Stage):","class Repair31(M.Stage):")
start=t.index("  need(self.scope['count']==len(self.parents)==32")
end=t.index("  prior=json.loads",start)
old=t[start:end]
new="""  need(self.scope['count']==len(self.parents)==31 and self.scope['partition']==dict(GD=17,JSON=14),'EXACT31_17GD14JSON_SCOPE')
  need(self.backup['status']=='ROOT_CURRENT4160_FULL32_BACKUP_AND_FRESH_OBSERVATION'and self.backup['passed']is True and self.backup['total_backups']==240 and self.backup['unexpected32_code_drift']==[]and self.backup['external_save_changes']==[]and self.backup['canonical_writes']==0,'ROOT_ACTUAL_CURRENT4160_BACKUP')
  rows=self.backup['new_backups'];domain={r['target']for r in rows}
  need(len(rows)==len(domain)==32 and domain-set(self.parents)=={self.scope['excluded_noop_G']}and set(self.parents)<=domain,'ROOT_BACKUP32_EXACT31_PLUS_NOOP_G_SUPERSET')
  current={r['target']:r for r in self.backup['current32']}
  for r in rows:
   p=r['target'];parent=self.parents.get(p);need(r['backup'].startswith(PREFIX+'gate_texture_repair01/root_only_current32_backup/'),'ROOT_BACKUP_FIXED_NAMESPACE')
   b=self.read(r['backup'],r['sha256']);need(len(b)==r['bytes']and b==self.read(p,r['sha256'])and current[p]['sha256']==r['sha256']and current[p]['bytes']==r['bytes'],'ROOT_FULL_BACKUP_CURRENT_4160')
   if parent:need(r['sha256']==parent['old_sha256']and len(b)==parent['old_bytes']and b==self.read(parent['immutable_old'],parent['old_sha256']),'ROOT_FULL_BACKUP_IMMUTABLE_PARENT')
"""
sub(old,new)
sub("len(prior['source_sha256'])==176 and len(self.authority['source_sha256'])==183,'OWNED10_176_PLUS7'","len(prior['source_sha256'])==183 and len(self.authority['source_sha256'])==189,'OWNED10_183_PLUS6'")
sub("len(changed)==5,'ONLY_FIVE_REAL_OWNED_EDGES'","len(changed)==4,'ONLY_FOUR_REAL_OWNED_EDGES'")
sub("'OTHER_FIVE_OWNED_IDENTICAL'","'OTHER_SIX_OWNED_IDENTICAL'")
sub("len(extra)==7 and all", "len(extra)==6 and all")
sub("'ALL_OLD176_FIXED_SEVEN_NEW'","'ALL_OLD183_FIXED_SIX_NEW'")
sub("len(self.targets)==32,'EXACT32_NO_NOOP_TARGETS'","len(self.targets)==31,'EXACT31_NO_NOOP_TARGETS'")
sub("'PINNED_CURRENT25H_MAP_PARENT'","'PINNED_CURRENT4160_MAP_PARENT'")
sub("len(reconstruction)==32,'EXACT18_GD_PATCH14_JSON_COPY'","len(reconstruction)==31,'EXACT17_GD_PATCH14_JSON_COPY'")
sub("status='EIGHT_EXTERIORS_EXACT32_STAGED_NOT_DEPLOYED'","status='GATE_TEXTURE_MARKET_PORTAL_EXACT31_STAGED_NOT_DEPLOYED'")
sub("dict(patch_count=18,copy_count=14,total=32)","dict(patch_count=17,copy_count=14,total=31)")
sub("Pinned current25h EBE0/7761 exact increment. Old OWNED10/proof176 retained+7, depth16, no shortcut. No old AO repromotion.","Pinned current4160/37D7 exact increment. Old OWNED10/proof183 retained+6, depth16, no shortcut. No old AO repromotion. Geometry/masks unchanged.")
sub("targets=32,map_nodes=4","targets=31,map_nodes=4")
sub("Unified32(spec).run()","Repair31(spec).run()")
back=t
for h in reversed(changes):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==parent
compile(t,'stage_gate_portal_repair31_ROOT_ONLY.py','exec')
driver=write('stage_gate_portal_repair31_ROOT_ONLY.py',t.encode())
dp=write('gate_texture_repair01/Stage31_driver_exact_adaptation_inverse.json',enc(dict(parent_sha256=sha(parent),candidate=driver,hunks=changes,whole_byte_inverse=True,all_original_source_metadata_approved_five_gates_and_depth16_preserved=True,Stage_calls=0)))

# Reuse the already reviewed complete finite offline preflight; no Stage.run invocation.
parent=(N/'prepare_finish8_stage_input32_NOTENGINE.py').read_text();t=parent
replacements={
 "unified32_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json":"repair31_READY02/unified32_all_candidates_and_inverse_NOT_STAGE.json",
 'be3aa94f1b6eae760888803076f80062ad4a25b3aabb349ea46e43e223099254':'7b50bec8b6f34f3f93dd050f35c10776013e2ebebdc8383824ca60176e05bf39',
 'stage_finish8_exact32_ROOT_ONLY.py':'stage_gate_portal_repair31_ROOT_ONLY.py',
 'root_finish8_exact32_stage01/':'root_gate_texture_market_portal_exact31_stage01/',
 'len(targets)==32':'len(targets)==31','len(patchproof)==18':'len(patchproof)==17',
 'EXACT32_OFFLINE':'EXACT31_OFFLINE','count=32,partition=dict(GD=18,JSON=14)':'count=31,partition=dict(GD=17,JSON=14)',
 'all32_fullbytes_inverse':'all31_fullbytes_inverse',
 'source_input_finish8_exact32_ROOT_REVIEW.json':'source_input_gate_portal_repair31_ROOT_REVIEW.json',
 'finite_preStage32_declaration_audit_READONLY.json':'finite_preStage31_declaration_audit_READONLY.json'}
for a,b in replacements.items():assert a in t,a;t=t.replace(a,b)
write('prepare_repair31_stage_input_NOTENGINE.py',t.encode())
print('DRIVER',json.dumps(dict(driver=driver,proof=dp)))
