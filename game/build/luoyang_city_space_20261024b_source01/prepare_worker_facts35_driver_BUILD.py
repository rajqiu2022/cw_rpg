"""Finite mechanical successor of the admitted38B3 compiler; never Stage."""
from pathlib import Path
import json,hashlib,difflib
HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
parent=HERE/'stage_market_dialogue36_estate_registry02_NOTREADY.py';before=parent.read_bytes()
assert sha(before)=='38b3a19e5518a36f8a45e2d8a0fa3583abb6a98bed41c3c7bdf774c4c308ff2a'
text=before.decode('utf8')
for a,b in [
 ("len(self.oldtargets) == 36","len(self.oldtargets) == 35"),
 ("sum(p.endswith('.gd') for p in self.oldtargets) == 21","sum(p.endswith('.gd') for p in self.oldtargets) == 20"),
 ("backup['count'] == len(backup['records']) == 36","backup['count'] == len(backup['records']) == 35"),
 ("len(self.codes) == 13","len(self.codes) == 12"),
 ("len(prior['source_sha256']) == 109 and len(self.authority['source_sha256']) == 118","len(prior['source_sha256']) == 118 and len(self.authority['source_sha256']) == 127"),
 ("len(expected) == len(self.spec['pass_through_targets']) == 14","len(expected) == len(self.spec['pass_through_targets']) == 13"),
 ("len(self.targets) == 36","len(self.targets) == 35"),
 ("len(copies) == 15 and len(reconstruction) == 36","len(copies) == 15 and len(reconstruction) == 35"),
 ("dict(patch_count=21,copy_count=15,total=36)","dict(patch_count=20,copy_count=15,total=35)"),
 ("targets=36,map_nodes=4","targets=35,map_nodes=4")]:
    assert text.count(a)==1,a;text=text.replace(a,b,1)
text=text.replace('EXACT36','EXACT35').replace('EXACT13_FUNCTION','EXACT12_FUNCTION').replace('EXACT13_CODE_PLUS','EXACT12_CODE_PLUS').replace('OLD109_ALL_RETAINED','OLD118_ALL_RETAINED').replace('STRICT_PATCH21','STRICT_PATCH20')
start=text.index("        if kind == 'space_estate_dialogue':")
end=text.index("        if kind == 'space_finite_market':",start)
new='''        if kind == 'space_estate_registry':
            need(row['target'] == ESTATE and row['source_policy'] == 'estate_legacy', 'ONLY_ESTATE_EXACT_REGISTRY_SCALAR_SUCCESSOR')
            original = self.read_json_input(row['base_input'])
            shadow = copy.deepcopy(original)
            registry_ops = [op for op in row['operations'] if op['pointer'] == ['registry_sha256']]
            need(len(registry_ops) == 1 and registry_ops[0] == dict(op='set',pointer=['registry_sha256'],existed=True,
                 old=original['registry_sha256'],new={'$sha':'registry_final'})
                 and original['registry_sha256'] == original['source_sha256'][REGISTRY], 'ONLY_DECLARED_OLD_ESTATE_REGISTRY_SCALAR')
            shadow['registry_sha256'] = self.nodes['registry_final']['sha256']
            temp = '__fixed_Estate_registry_scalar_shadow'
            self.input_bytes[temp] = encode(shadow)
            self.inputs[temp] = dict(path=self.inputs[row['base_input']]['path'],sha256=sha(self.input_bytes[temp]))
            ordinary = copy.deepcopy(row)
            ordinary.update(kind='metadata',base_input=temp)
            ordinary.pop('target'); ordinary.pop('old_sha256')
            ordinary['operations'] = [op for op in ordinary['operations'] if op['pointer'] != ['registry_sha256']]
            ordinary['forbidden_source_paths'] = ordinary.get('forbidden_source_paths',[]) + [ESTATE]
            super().build_node(ordinary)
            value = self.nodes[ident]['value']
            need(set(value['source_sha256']) == set(original['source_sha256']), 'ESTATE_SOURCE_KEYSET_ENTIRELY_UNCHANGED')
            inverse = copy.deepcopy(value)
            for delta in reversed(self.proofs[ident]['source_delta']):
                holder = M.pointer(inverse,delta['pointer'][:-1]); key = delta['pointer'][-1]
                if delta['existed']: holder[key] = delta['old']
                else: del holder[key]
            need(same(inverse,shadow),'ESTATE_ORIGINAL_SOURCE_INVERSE')
            inverse['registry_sha256'] = original['registry_sha256']
            need(same(inverse,original) and encode(inverse) == self.input_bytes[row['base_input']], 'ESTATE_FULL_TYPED_SERIALIZED_PARENT_INVERSE')
            need(value['registry_path'] == REGISTRY and value['registry_sha256'] == value['source_sha256'][REGISTRY]
                 == self.nodes['registry_final']['sha256'], 'ESTATE_REGISTRY_THREE_EQUAL_SEMANTIC_GUARD')
            self.proofs[ident].update(whole_typed_inverse=True,exact_registry_scalar_successor=True,whole_serialized_parent_inverse=True)
            self.target(ESTATE,row['old_sha256'],self.nodes[ident]['path'],self.nodes[ident]['sha256'])
            del self.inputs[temp]; del self.input_bytes[temp]
            return
'''
text=text[:start]+new+text[end:]
after=text.encode('utf8');compile(after,'worker_facts35_compiler','exec')
rows=[]
a,b=before.decode('utf8').splitlines(keepends=True),text.splitlines(keepends=True)
for g in difflib.SequenceMatcher(None,a,b,autojunk=False).get_grouped_opcodes(3):rows.append(dict(old=''.join(a[g[0][1]:g[-1][2]]),new=''.join(b[g[0][3]:g[-1][4]])))
f,i=before.decode(),text
for r in rows:
    assert f.count(r['old'])==i.count(r['new'])==1;f=f.replace(r['old'],r['new'],1);i=i.replace(r['new'],r['old'],1)
assert f.encode()==after and i.encode()==before
dest=HERE/'stage_worker_facts35_NOTREADY.py'
with dest.open('xb') as stream:stream.write(after)
proof=dict(status='WORKER_FACTS35_MECHANICAL_DRIVER_NOT_EXECUTED',parent=dict(path=S+parent.name,sha256=sha(before)),candidate=dict(path=S+dest.name,sha256=sha(after),bytes=len(after)),hunks=rows,wholebyte_forward_inverse=True,
    only_changes=['35/20GD/15JSON partition','12code plus execution','118 to127 proof count','Estate original keyset now unchanged; retain exact registry scalar shadow and all protected pointers'],no_core_change=True,Stage_calls=0,engine_calls=0,canonical_writes=0)
p=HERE/'worker_facts35_driver_inverse_NOT_STAGE.json';raw=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode('utf8')
with p.open('xb') as stream:stream.write(raw)
print(json.dumps(dict(driver=proof['candidate'],proof=dict(path=S+p.name,sha256=sha(raw),bytes=len(raw)))))
