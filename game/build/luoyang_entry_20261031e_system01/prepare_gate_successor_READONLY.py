"""Two-source candidate only; emits apply_patch files, never writes canonical paths."""
from pathlib import Path
import hashlib,json,difflib,sys
N=Path(__file__).resolve().parent;R=N.parents[2]
G='game/data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'
I='game/scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
E='game/data/maps/luoyang_full_city_20261022ap/execution_successor.json'
sha=lambda b:hashlib.sha256(b).hexdigest()
old=(R/G).read_bytes();index=(R/I).read_bytes();ex=json.loads((R/E).read_bytes());before=json.loads(old);after=old
expected_before='fedaaf361548f7a2ab5d5ec539f148747cb1fc1f8f291db1a62f5c57ee4f7e04'
assert sha(old)==expected_before
changes=[]
for path in ['res://build/luoyang_regions_20261027d_source01/region_field.gd','res://build/luoyang_regions_20261027d_source01/region_entry.gd','res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json']:
 previous=before['legacy_source_sha256'][path];current=sha((R/'game'/path[6:]).read_bytes());assert previous!=current
 a=(json.dumps(path)+': '+json.dumps(previous)).encode();b=(json.dumps(path)+': '+json.dumps(current)).encode();assert after.count(a)==1
 after=after.replace(a,b,1);changes.append({'path':path,'old_sha256':previous,'new_sha256':current})
missing={p:h for p,h in ex['source_sha256'].items()if p not in before['legacy_source_sha256'] and p not in before['runtime_authority_sha256'] and p not in before['artifacts']}
assert len(missing)==9
for path,digest in missing.items():
 assert path.startswith('res://build/luoyang_')and path.endswith('/scene_router.gd') and sha((R/'game'/path[6:]).read_bytes())==digest
text=after.decode();marker='  "legacy_source_sha256": ';start=text.index(marker)+len(marker);_,used=json.JSONDecoder().raw_decode(text[start:]);end=start+used-1
assert text[end]=='}'
head=text[:end].rstrip();addition=''.join(',\n    '+json.dumps(p)+': '+json.dumps(h)for p,h in missing.items());after=(head+addition+'\n  '+text[end:]).encode()
new=json.loads(after);assert set(new['legacy_source_sha256'])==set(before['legacy_source_sha256'])|set(missing)
for p,h in before['legacy_source_sha256'].items():assert new['legacy_source_sha256'][p]==next((x['new_sha256']for x in changes if x['path']==p),h)
assert {k:v for k,v in new.items()if k!='legacy_source_sha256'}=={k:v for k,v in before.items()if k!='legacy_source_sha256'}
assert index.count(expected_before.encode())==1;nextindex=index.replace(expected_before.encode(),sha(after).encode(),1)
targets=[(G,old,after),(I,index,nextindex)]
def diff(a,b,target):return ''.join(difflib.unified_diff(a.decode().splitlines(True),b.decode().splitlines(True),fromfile='a/'+target,tofile='b/'+target,n=3))
def applytext(a,b,target):
 lines=diff(a,b,target).splitlines();return '\n'.join(['*** Update File: '+target]+['@@'if line.startswith('@@')else line for line in lines[2:]])+'\n'
forward='*** Begin Patch\n'+''.join(applytext(a,b,p)for p,a,b in targets)+'*** End Patch\n'
inverse='*** Begin Patch\n'+''.join(applytext(b,a,p)for p,a,b in targets)+'*** End Patch\n'
receipt={'status':'TWO_SOURCE_CANDIDATE_ONLY_AWAITING_ACTUAL_GATE_DIFF_PROBE','before_Gate_sha256':sha(old),'before_Index_sha256':sha(index),'targets':[{'target':p,'before_sha256':sha(a),'after_sha256':sha(b),'before_bytes':len(a),'after_bytes':len(b),'candidate_kind':'exact forward apply_patch plus inverse; full old source remains canonical read-only'}for p,a,b in targets],'three_exact_pin_replacements':changes,'nine_exact_approved_snapshot_additions':missing,'legacy_keys_before':len(before['legacy_source_sha256']),'legacy_keys_after':len(new['legacy_source_sha256']),'all_other_fields_bytes_unchanged':True,'strict_describe_and_collector_unchanged':True,'new_Region_Router_EX_Authority_writes':0,'engine_runs':0,'save_API_calls':0,'forward_sha256':sha(forward.encode()),'inverse_sha256':sha(inverse.encode())}
outputs={'Gate_and_index_FORWARD.apply_patch':forward,'Gate_and_index_INVERSE.apply_patch':inverse,'receipt_READY.json':json.dumps(receipt,ensure_ascii=False,indent=2)+'\n','gate_index_READY.gd':nextindex.decode()}
print('*** Begin Patch')
for name,data in outputs.items():
 print('*** Add File: '+(N/name).as_posix())
 for line in data.splitlines():print('+'+line)
print('*** End Patch')
