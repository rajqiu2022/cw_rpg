"""Count/literal-contract successor of the admitted DF7D metadata compiler."""
from pathlib import Path
import json,hashlib,difflib
HERE=Path(__file__).resolve().parent;S='res://build/luoyang_city_space_20261024b_source01/'
sha=lambda b:hashlib.sha256(b).hexdigest()
before=(HERE/'stage_worker_facts35_NOTREADY.py').read_bytes();assert sha(before)=='df7d1dd09358671b2bc9dfd9c8116325ff17a07a23f65ebd6ca4d99a01c6ccad'
text=before.decode()
for a,b in [
 ("len(self.oldtargets) == 35","len(self.oldtargets) == 27"),
 ("sum(p.endswith('.gd') for p in self.oldtargets) == 20","sum(p.endswith('.gd') for p in self.oldtargets) == 13"),
 ("backup['count'] == len(backup['records']) == 35","backup['count'] == len(backup['records']) == 27"),
 ("len(self.codes) == 12","len(self.codes) == 5"),
 ("len(changed) == 7","len(changed) == 3"),
 ("len(prior['source_sha256']) == 118 and len(self.authority['source_sha256']) == 127","len(prior['source_sha256']) == 127 and len(self.authority['source_sha256']) == 132"),
 ("len(delta) == 2","len(delta) == 1"),
 ("len(expected) == len(self.spec['pass_through_targets']) == 13","len(expected) == len(self.spec['pass_through_targets']) == 6"),
 ("len(self.targets) == 35","len(self.targets) == 27"),
 ("len(copies) == 15 and len(reconstruction) == 35","len(copies) == 14 and len(reconstruction) == 27"),
 ("target_count=15","target_count=14"),
 ("dict(patch_count=20,copy_count=15,total=35)","dict(patch_count=13,copy_count=14,total=27)"),
 ("targets=35,map_nodes=4","targets=27,map_nodes=4")]:
    assert text.count(a)==1,(a,text.count(a));text=text.replace(a,b,1)
text=text.replace('EXACT35','EXACT27').replace('EXACT12_FUNCTION','EXACT5_FUNCTION').replace('EXACT12_CODE_PLUS','EXACT5_CODE_PLUS').replace('UNCHANGED10_MEMBERS_ONLY7','UNCHANGED10_MEMBERS_ONLY3').replace('THREE_OTHER_OWNED_ROWS_EXACT','SEVEN_OTHER_OWNED_ROWS_EXACT').replace('OLD118_ALL_RETAINED_EXACT9_NEW','OLD127_ALL_RETAINED_EXACT5_NEW').replace('CULTURE_EXACT_C_AND_FIELD_TYPED_INVERSE','CULTURE_EXACT_C_ONLY_TYPED_INVERSE').replace('STRICT_PATCH20_EXACT_COPY15','STRICT_PATCH13_EXACT_COPY14')
after=text.encode();compile(after,'packed27_compiler','exec')
a,b=before.decode().splitlines(keepends=True),text.splitlines(keepends=True);hunks=[]
for g in difflib.SequenceMatcher(None,a,b,autojunk=False).get_grouped_opcodes(3):hunks.append(dict(old=''.join(a[g[0][1]:g[-1][2]]),new=''.join(b[g[0][3]:g[-1][4]])))
f,i=before.decode(),text
for h in hunks:
    assert f.count(h['old'])==i.count(h['new'])==1;f=f.replace(h['old'],h['new'],1);i=i.replace(h['new'],h['old'],1)
assert f.encode()==after and i.encode()==before
name='stage_C_packed27_NOTREADY.py'
with (HERE/name).open('xb') as stream:stream.write(after)
value=dict(status='C_PACKED27_MECHANICAL_DRIVER_NOT_EXECUTED',parent=dict(path=S+'stage_worker_facts35_NOTREADY.py',sha256=sha(before)),candidate=dict(path=S+name,sha256=sha(after),bytes=len(after)),hunks=hunks,wholebyte_forward_inverse=True,
    changes=['27 existing/13GD14JSON','five code plus execution','three existing owned edges/127+5=132','one culture C scalar instead of two C/Field values'],core_8DE0_unchanged=True,Stage_calls=0,engine_calls=0,canonical_writes=0)
raw=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode();p='C_packed27_driver_inverse_NOT_STAGE.json'
with (HERE/p).open('xb') as stream:stream.write(raw)
print(json.dumps(dict(driver=value['candidate'],proof=dict(path=S+p,sha256=sha(raw),bytes=len(raw)))))
