"""Root-approved sole Estate ordinary leaf shadow, without changing8DE0."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent;S='res://build/luoyang_city_revision_20261024e_source01/'
old=(HERE/'stage_market_blocks33_NOTREADY.py').read_bytes();assert hashlib.sha256(old).hexdigest()=='97f9b826ffe34e7e6fa9921b58c0c62a6c228d3a256b200a4cd592785fc1c956'
text=old.decode();edits=[]
def change(a,b):
    global text
    assert text.count(a)==1,(a[:80],text.count(a));i=len(text[:text.index(a)].encode());text=text.replace(a,b,1);edits.append(dict(byte_offset_at_step=i,old=a,new=b))
change("            shadow['registry_sha256'] = self.nodes['registry_final']['sha256']",'''            shadow['registry_sha256'] = self.nodes['registry_final']['sha256']
            estate_extra = self.group('blocks_Field_prewarm1')
            need(estate_extra == {'res://build/luoyang_loading_20261024e_perf01/candidate03/gate_source_prewarm02.gd':'03dec03dbfdd572042e566848d3231de56c1c45583fac4644cfccd99b3a81ed8'}
                 and not (set(estate_extra) & set(original['source_sha256'])), 'SOLE_ROOT_APPROVED_ESTATE_PERF03_ORDINARY_LEAF')
            shadow['source_sha256'].update(estate_extra)''')
change("            ordinary.update(kind='metadata',base_input=temp)\n            ordinary.pop('target'); ordinary.pop('old_sha256')",'''            ordinary.update(kind='metadata',base_input=temp)
            need(len(ordinary['source_fields']) == 1 and ordinary['source_fields'][0]['pointer'] == ['source_sha256']
                 and ordinary['source_fields'][0]['groups'] == ['blocks_Field_prewarm1'], 'SOLE_ESTATE_FIXED_SINGLE_GROUP_REQUEST')
            ordinary['source_fields'][0]['groups'] = [] # Original core sees its exact source-keyset shadow, no general new group permission.
            ordinary.pop('target'); ordinary.pop('old_sha256')''')
change("            need(set(value['source_sha256']) == set(original['source_sha256']), 'ESTATE_SOURCE_KEYSET_ENTIRELY_UNCHANGED')",'''            need(set(value['source_sha256']) == set(original['source_sha256']) | set(estate_extra)
                 and all(value['source_sha256'].get(p) == h for p,h in estate_extra.items()), 'ESTATE_ONLY_FIXED_PERF03_SOURCE_KEY_ADDITION')''')
change("            inverse['registry_sha256'] = original['registry_sha256']",'''            inverse['registry_sha256'] = original['registry_sha256']
            for p in estate_extra: del inverse['source_sha256'][p]''')
change("self.proofs[ident].update(whole_typed_inverse=True,exact_registry_scalar_successor=True,whole_serialized_parent_inverse=True)","self.proofs[ident].update(whole_typed_inverse=True,exact_registry_scalar_successor=True,whole_serialized_parent_inverse=True,exact_ordinary_source_addition=estate_extra)")
raw=text.encode();back=raw
for e in reversed(edits):
    i=e['byte_offset_at_step'];a,b=e['old'].encode(),e['new'].encode();assert back[i:i+len(b)]==b;back=back[:i]+a+back[i+len(b):]
assert back==old;compile(text,'stage_market_blocks33_Estate1_NOTREADY.py','exec')
dest=HERE/'stage_market_blocks33_Estate1_NOTREADY.py';assert not dest.exists()
with dest.open('xb') as stream:stream.write(raw)
proof=dict(status='SOLE_ESTATE_PERF03_LEAF_DRIVER_SUCCESSOR_NOT_RUN',parent=dict(path=S+'stage_market_blocks33_NOTREADY.py',sha256=hashlib.sha256(old).hexdigest()),candidate=dict(path=S+dest.name,sha256=hashlib.sha256(raw).hexdigest()),edits=edits,wholebyte_forward_inverse=True,unchanged8DE0=True,all_other_protected_pointers_unchanged=True,engine_calls=0,Stage_calls=0,canonical_writes=0)
b=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();p=HERE/'stage33_Estate1_driver_inverse_BUILD.json'
with p.open('xb') as stream:stream.write(b)
print(json.dumps(dict(driver=proof['candidate'],proof=dict(path=S+p.name,sha256=hashlib.sha256(b).hexdigest()))))
