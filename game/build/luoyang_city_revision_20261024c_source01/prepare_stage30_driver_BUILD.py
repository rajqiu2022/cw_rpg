"""Thin exact30 successor to executed packed27 driver, unchanged8DE0 core."""
from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024c_source01/'
oldpath='res://build/luoyang_city_space_20261024b_source01/stage_C_packed27_NOTREADY.py'
old=(GAME/oldpath[6:]).read_bytes();assert hashlib.sha256(old).hexdigest()=='a1cd66653b73032d0d92369864b1fbd6af74c270dd75f053dee57209dee7b507'
text=old.decode();edits=[]
def change(a,b):
    global text
    assert text.count(a)==1,(a[:80],text.count(a));i=len(text[:text.index(a)].encode());text=text.replace(a,b,1);edits.append(dict(byte_offset_at_step=i,old=a,new=b))
change("PREFIX = 'res://build/luoyang_city_space_20261024b_source01/'","PREFIX = 'res://build/luoyang_city_revision_20261024c_source01/'")
start=text.index("        need(backup['count']");end=text.index("        need(backed == self.oldtargets",start)
change(text[start:end],'''        need(backup['status'] == 'ROOT_EXACT30_PREDEPLOY_FULL_OLD_BACKUP' and backup['passed'] is True
             and backup['count'] == len(backup['rows']) == 30
             and backup['scope_sha256'] == self.inputs[c['scope_input']]['sha256']
             and backup['root_protection_sha256'] == self.inputs[c['Root_protection_input']]['sha256'], 'ROOT_F55B_EXACT30_ROWS_SCHEMA')
        backed = {}
        for row in backup['rows']:
            p, h, bp = row['target'], row['old_sha256'], Path(row['backup']).resolve()
            need(p in self.oldtargets and p not in backed and h == self.oldtargets[p]
                 and Path(row['path']).resolve() == res(p).resolve()
                 and bp.is_relative_to(res(c['Root_backup_prefix']).resolve()), 'EXACT30_BACKUP_PATH_DOMAIN')
            b = self.read('res://' + bp.relative_to(M.ROOT).as_posix(), h)
            need(b == self.read(p, h) and len(b) == row['bytes'], 'EXACT30_FULL_OLD_BYTES')
            backed[p] = h
''')
for a,b in [
 ("len(self.oldtargets) == 27","len(self.oldtargets) == 30"),
 ("sum(p.endswith('.gd') for p in self.oldtargets) == 13","sum(p.endswith('.gd') for p in self.oldtargets) == 15"),
 ("len(self.codes) == 5","len(self.codes) == 7"),
 ("len(changed) == 3","len(changed) == 5"),
 ("len(prior['source_sha256']) == 127 and len(self.authority['source_sha256']) == 132","len(prior['source_sha256']) == 132 and len(self.authority['source_sha256']) == 139"),
 ("len(delta) == 1 and same(value, self.read_json_input(row['literal_candidate_input']))","len(delta) == 2 and {tuple(d['pointer']) for d in delta} == {('source_sha256','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'),('source_sha256','res://scripts/field/field_walkable_controller.gd')} and same(value, self.read_json_input(row['literal_candidate_input']))"),
 ("len(expected) == len(self.spec['pass_through_targets']) == 6","len(expected) == len(self.spec['pass_through_targets']) == 8"),
 ("len(self.targets) == 27","len(self.targets) == 30"),
 ("len(copies) == 14 and len(reconstruction) == 27","len(copies) == 15 and len(reconstruction) == 30"),
 ("target_count=14","target_count=15"),
 ("dict(patch_count=13,copy_count=14,total=27)","dict(patch_count=15,copy_count=15,total=30)"),
 ("targets=27,map_nodes=4","targets=30,map_nodes=4"),
 ("status='MARKET_DIALOGUE_EXACT27_STAGED_NOT_DEPLOYED'","status='YAMEN_COURTS_SCHOLAR_EXACT30_STAGED_NOT_DEPLOYED'")]:change(a,b)
needle="        self.binding = self.read_json_input(c['space_binding_input'])"
change(needle,"""        self.courts_binding = self.read_json_input(c['courts_binding_input'])
        need(self.courts_binding['ready'] is True and self.courts_binding['status'] == 'YAMEN_COURTS_SOURCE_BOUND_OVERLAY_READY'
             and len(self.courts_binding['required_source_sha256']) == 13, 'EXACT_READY_COURTS13_SOURCE_CONTRACT')
        self.binding = self.read_json_input(c['space_binding_input'])""")
# Diagnostic labels only, never gate widening.
for a,b in [('ROOT_EXACT27_EXTERNAL_LOCK_REQUIRED','ROOT_EXACT30_EXTERNAL_LOCK_REQUIRED'),('EXACT27_21GD15JSON','EXACT30_15GD15JSON'),('EXACT27_FULL_BACKUP_COVERAGE','EXACT30_FULL_BACKUP_COVERAGE'),('EXACT5_FUNCTION_OR_LITERAL_CODE_SUCCESSORS','EXACT7_FUNCTION_OR_LITERAL_CODE_SUCCESSORS'),('UNCHANGED10_MEMBERS_ONLY3_EDGES','UNCHANGED10_MEMBERS_ONLY5_EDGES'),('SEVEN_OTHER_OWNED_ROWS_EXACT','FIVE_OTHER_OWNED_ROWS_EXACT'),('OLD127_ALL_RETAINED_EXACT5_NEW','OLD132_ALL_RETAINED_EXACT7_NEW'),('CULTURE_EXACT_C_ONLY_TYPED_INVERSE','CULTURE_EXACT_C_FIELD_TYPED_INVERSE'),('EXACT5_CODE_PLUS_EXECUTION_PASSTHROUGH','EXACT7_CODE_PLUS_EXECUTION_PASSTHROUGH'),('EXACT27_TARGET_SET','EXACT30_TARGET_SET'),('STRICT_PATCH13_EXACT_COPY14','STRICT_PATCH15_EXACT_COPY15'),('INDEPENDENT_FORMAL805791_PLUS_EXACT27_DECLARATIONS','INDEPENDENT_FIXED_CURRENT24B_PLUS_EXACT30_DECLARATIONS')]:change(a,b)
compile(text,'stage_courts_scholar30_NOTREADY.py','exec')
inv=text.encode()
for e in reversed(edits):
    i=e['byte_offset_at_step'];a,b=e['old'].encode(),e['new'].encode();assert inv[i:i+len(b)]==b;inv=inv[:i]+a+inv[i+len(b):]
assert inv==old
path=HERE/'stage_courts_scholar30_NOTREADY.py'
with path.open('xb') as f:f.write(text.encode())
proof=dict(status='EXACT30_DRIVER_MECHANICAL_WHOLEBYTE_INVERSE_NOT_RUN',parent=dict(path=oldpath,sha256=hashlib.sha256(old).hexdigest()),candidate=dict(path=S+path.name,sha256=hashlib.sha256(text.encode()).hexdigest()),edits=edits,wholebyte_forward_inverse=True,core_8DE0_unchanged=True,engine_calls=0,Stage_calls=0,canonical_writes=0)
b=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();p=HERE/'stage30_driver_inverse_BUILD.json'
with p.open('xb') as f:f.write(b)
print(json.dumps(dict(driver=proof['candidate'],proof=dict(path=S+p.name,sha256=hashlib.sha256(b).hexdigest()))))
