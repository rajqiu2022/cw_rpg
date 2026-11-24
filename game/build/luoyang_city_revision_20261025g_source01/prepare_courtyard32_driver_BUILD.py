"""Finite reviewed driver specialization; AST and byte inverse only, never imports Stage."""
from pathlib import Path
import ast,hashlib,json,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261025g_source01/'
parent='res://build/luoyang_city_revision_20261024e_source01/stage_docks_frontages31_residual03_NOTREADY.py'
a=(GAME/parent[6:]).read_bytes();assert hashlib.sha256(a).hexdigest()=='2abfa7b51959c52cc7dafd840c6e22049de2e13ace72e68cd45e56b89822ceb6'
s=a.decode()
changes=[
('exact31 Docks','exact32 Courtyard45'),
("PREFIX='res://build/luoyang_city_revision_20261024e_source01/'",'PREFIX='+repr(S)),
('DocksFrontageStage','Courtyard45Stage'),("spec['docks_contract']","spec['courtyard_contract']"),
('ROOT31_EXACT_LOCK_REQUIRED','ROOT32_EXACT_LOCK_REQUIRED'),
("len(self.oldtargets)==31","len(self.oldtargets)==32"),("sum(p.endswith('.gd') for p in self.oldtargets)==16","sum(p.endswith('.gd') for p in self.oldtargets)==17"),
('EXACT31_16GD15JSON_DOMAIN','EXACT32_17GD15JSON_DOMAIN'),
('EXACT31_CURRENT_FE154_PARENT_BACKED_UP_NO_CANONICAL_WRITES','EXACT32_CURRENT9876_PARENT_BACKED_UP_NO_CANONICAL_WRITES'),
("len(backup['targets'])==31","len(backup['targets'])==32"),('ROOT_745E_ACTUAL_SCHEMA','ROOT_207A_ACTUAL_SCHEMA'),
('EXACT31_BACKUP','EXACT32_BACKUP'),('EXACT31_FULL','EXACT32_FULL'),
("len(self.codes)==8","len(self.codes)==9"),('EXACT8_APPROVED_FUNCTIONAL_AND_LITERAL_SUCCESSORS','EXACT9_APPROVED_FUNCTIONAL_AND_LITERAL_SUCCESSORS'),
("len(prior['source_sha256'])==154 and len(self.authority['source_sha256'])==162","len(prior['source_sha256'])==162 and len(self.authority['source_sha256'])==170"),
('OLD154_EXACT8_NEW_PROOF_LEAVES','OLD162_EXACT8_NEW_PROOF_LEAVES'),
("len(self.parent_maps['expected_ch4_s3_luoyang_market_true'])==1862","len(self.parent_maps['expected_ch4_s3_luoyang_market_true'])==1877"),
('FIXED_FE154','FIXED_9876'),('FE154_','CURRENT9876_'),('31_TARGET_VALUES','32_TARGET_VALUES'),('31_DELTAS','32_DELTAS'),
("len(self.spec['pass_through_targets'])==9","len(self.spec['pass_through_targets'])==10"),('EXACT8_CODE_PLUS_EXEC_PASSTHROUGH','EXACT9_CODE_PLUS_EXEC_PASSTHROUGH'),
("len(self.targets)==31","len(self.targets)==32"),('EXACT31_TARGET_SET','EXACT32_TARGET_SET'),
("len(reconstruction)==31","len(reconstruction)==32"),('STRICT16_GD_PATCH_EXACT15_JSON_COPY','STRICT17_GD_PATCH_EXACT15_JSON_COPY'),
('DOCKS_FRONTAGES_EXACT31_STAGED_NOT_DEPLOYED','MARKET_COURTYARD45_EXACT32_STAGED_NOT_DEPLOYED'),
('patch_count=16,copy_count=15,total=31','patch_count=17,copy_count=15,total=32'),('targets=31,map_nodes=4','targets=32,map_nodes=4')]
for old,new in changes:
    assert old in s,old
    s=s.replace(old,new)
ast.parse(s)
b=s.encode();dest=HERE/'stage_courtyard45_exact32_ROOT_ONLY.py'
with dest.open('xb') as out:out.write(b)
rows=[];al=a.decode().splitlines(keepends=True);bl=s.splitlines(keepends=True)
for tag,i,j,k,l in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_opcodes():
    if tag!='equal':rows.append(dict(old_offset=len(''.join(al[:i]).encode()),new_offset=len(''.join(bl[:k]).encode()),old=''.join(al[i:j]),new=''.join(bl[k:l])))
f,v=a,b
for r in reversed(rows):
    x,y=r['old'].encode(),r['new'].encode();i,j=r['old_offset'],r['new_offset'];assert f[i:i+len(x)]==x and v[j:j+len(y)]==y;f=f[:i]+y+f[i+len(x):];v=v[:j]+x+v[j+len(y):]
assert f==b and v==a
proof=dict(status='COURTYARD45_EXACT32_DRIVER_WHOLE_BYTE_INVERSE_NOT_EXECUTED',parent=dict(path=parent,sha256=hashlib.sha256(a).hexdigest()),driver=dict(path=S+dest.name,sha256=hashlib.sha256(b).hexdigest()),offset_byte_patch=rows,whole_forward_inverse=True,original8DE0_core_unchanged=True,original5gates_4AO_model_current_parent_permission_and_EstateRegistry_gates_unchanged=True,Stage_imports=0,Stage_executions=0,canonical_writes=0)
p=HERE/'courtyard32_driver_whole_inverse_NOT_EXECUTED.json'
with p.open('xb') as out:out.write((json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(driver=proof['driver'],proof=dict(path=S+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest()))))
