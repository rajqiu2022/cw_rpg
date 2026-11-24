"""Seal the single Root-passed visual delta with the existing27 DAG template."""
from pathlib import Path
import copy, hashlib, json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';O=N/'visual_finish04_BUILD'
sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode();res=lambda p:'res://'+p.relative_to(G).as_posix()
def pin(p):
 b=p.read_bytes();return dict(path=res(p),sha256=sha(b),bytes=len(b))
def fixed(p,h):
 b=p.read_bytes();assert sha(b)==h,str(p);return json.loads(b)
def create(p,b):
 assert not p.exists(),str(p);p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b);return pin(p)
manifest_path=N/'region_runtime_manifest_BUILD.json';manifest=fixed(manifest_path,'85c16eb0506e60bb3b0310218bb942beafd90840f447b503d5e231de43be6023')
proof=fixed(O/'visual_Field_whole_inverse_BUILD.json','4a69d30b20938f725fbe4180a6dfb7da3a877b36ad4257141b002484a946d53c')
publication_path=O/'output/67124/result.json';publication=json.loads(publication_path.read_bytes());assert publication['passed'] and not publication['errors']
expected={'luoyang_civic_market_region_27d':('a957555a0d2910ccd5cbfdeae9bc89b1a942f6fc23aa160264f2fb7ac0687d5f',350616,0),'luoyang_estate_region_27d':('07d64efe26073bc666d04916d2539c7e3b63ed2d5526068f413f823f527a4e22',98804,32),'luoyang_temple_region_27d':('70b37efd015a4b3f297036aabc20fae9ed4c1c9db7641e4417ed32f7cf2f4948',81080,24)}
bins=[]
for row in publication['components']:
 h,n,retired=expected[row['id']];assert row['sha256']==h and row['bytes']==n and row['retired_render']==row['retired_bodies']==retired and row['whole_typed_inverse'] and row['positive_ground_unchanged'] and row['npcs_interactions_unchanged']
 binding={k:row[k]for k in ['path','sha256','bytes']};assert pin(G/binding['path'][6:])==binding
 manifest['compiled_bindings'][row['id']]=binding;bins.append(binding)
assert len(bins)==3
manifest['author']=proof['author'];field_target=res(N/'region_field.gd');assert manifest['runtime_modules'][field_target]==proof['parent_Field']['sha256']
manifest['runtime_modules'][field_target]=proof['candidate_Field']['sha256']
manifest_pin=create(O/'region_runtime_manifest_visual_CANDIDATE.json',enc(manifest))
router=G/'scripts/autoload/scene_router.gd';rr=router.read_bytes();assert sha(rr)=='fff398a42aa0dea09ed34eb96cc21106b4eb74913a4cf1ec23501df6d0450ba7';old_sha=pin(manifest_path)['sha256'];assert rr.count(old_sha.encode())==1
router_pin=create(O/'Router_visual_manifest_CANDIDATE.gd',rr.replace(old_sha.encode(),manifest_pin['sha256'].encode(),1))
assert (G/router_pin['path'][6:]).read_bytes().count(b'\r\n')==13
rebind=dict(Field=dict(target=field_target,parent=proof['parent_Field'],candidate=proof['candidate_Field'],hunks=proof['hunks']),manifest=dict(target=res(manifest_path),parent=pin(manifest_path),candidate=manifest_pin),Router=dict(parent=pin(router),candidate=router_pin),author_candidate=proof['author'],compiled_candidates=bins,publication=pin(publication_path),visual_Field_proof=pin(O/'visual_Field_whole_inverse_BUILD.json'),no_geometry_recompile=True,canonical_writes=0)
rebind_pin=create(O/'visual_source_seal_BUILD.json',enc(rebind))
stage_path=S/'outputs/root_region_phase_lifetime27_stage01/receipt.json';stage_pin=pin(stage_path)
old_descriptor=N/'phase_lifetime03_BUILD/closure27/phase_lifetime27_all_candidates_NOT_STAGE.json';assert pin(old_descriptor)['sha256']=='6b4ae21453bf07bb47b77dcebe1016dce26decc740fd61cb10342ad2ecbd335a'
text=(N/'prepare_rebinding26_BUILD.py').read_text(encoding='utf8')
def change(a,b):
 global text
 assert text.count(a)==1,a[:100];text=text.replace(a,b,1)
change("O=N/'source_rebinding02_BUILD';U=O/'closure26'","O=N/'visual_finish04_BUILD';U=O/'closure27'")
change("'res://build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01/unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'",repr(res(old_descriptor)))
change("'ddb955b71625acc92f02d23a896f9f5f306062ee623248a485b1be2e7ef29a47'",repr(pin(old_descriptor)['sha256']))
change('root_region_integration_exact32_stage02/receipt.json','root_region_phase_lifetime27_stage01/receipt.json')
change('e569f5d85b4679175ff70a1f314d4eff3d8c4b8426471595b07539607a5376c5',stage_pin['sha256'])
change("rebindpin=pin(O/'source_rebinding_whole_binary_inverse_BUILD.json');rebind=load(rebindpin)","rebindpin=pin(O/'visual_source_seal_BUILD.json');rebind=load(rebindpin)")
change("assert rebind['manifest_candidate']['sha256']=='77c638a7d229a6dfd2437b9b9374c15af68232899690d2d7dda52e17c44327ff'","assert rebind['manifest']['candidate']['sha256']=="+repr(manifest_pin['sha256']))
change("record(R,'Router_READY.gd',read(rebind['Router']['candidate']))","record(R,'Router_READY.gd',read(rebind['Router']['candidate']))\nRF=rebind['Field']['target'];record(RF,'RegionField_READY.gd',read(rebind['Field']['candidate']))")
change("len(prior['source_sha256'])==284","len(prior['source_sha256'])==294")
change("len(ex['source_sha256'])==289","len(ex['source_sha256'])==299")
change('old_proof_count=284,new_proof_count=289','old_proof_count=294,new_proof_count=299')
change("manifest_target=rebind['manifest_target'];manifest_parent=emit('manifest_parent_5497.json',read(rebind['parent_manifest']));parents[manifest_target]=manifest_parent;refs[manifest_target]=rebind['manifest_candidate'];data[refs[manifest_target]['path']]=read(refs[manifest_target])","manifest_target=rebind['manifest']['target'];refs[manifest_target]=rebind['manifest']['candidate'];data[refs[manifest_target]['path']]=read(refs[manifest_target])")
start=text.index('ordinary={**extra,');end=text.index('\ndef at(value,ptr):',start)
text=text[:start]+"ordinary={**extra,rebind['author_candidate']['path']:rebind['author_candidate']['sha256']}\nfor row in rebind['compiled_candidates']:ordinary[row['path']]=row['sha256']\n"+text[end:]
change("meta('estate_final');meta('quarter_final')","meta('estate_final');index('ap_execution_index');meta('quarter_final')")
change("'legacy_index_4','ap_execution_index','ap_quarter_index'","'legacy_index_4','ap_quarter_index'")
change('len(records)==11 and len(metadata)==12 and len(refs)==26','len(records)==12 and len(metadata)==12 and len(refs)==27')
change("out=emit('source_rebind26_all_candidates_NOT_STAGE.json'","out=emit('visual27_all_candidates_NOT_STAGE.json'")
text=text.replace('GD=11,JSON=15,total=26','GD=12,JSON=15,total=27').replace('count=26','count=27').replace("'count':26","'count':27").replace('current_D9A8_exact26_scope_PREPARATION.json','current_B78D_exact27_scope_PREPARATION.json').replace('CURRENT_D9A8_SOURCE_REBIND26_NOT_STAGE','CURRENT_B78D_VISUAL27_NOT_STAGE').replace('ROOT_BACKUP_EXACT_CHANGED26_PREPARATION','ROOT_BACKUP_EXACT_CHANGED27_PREPARATION').replace('runtime_Field_BIND_and_geometry_unchanged=True','legacy_Field_BIND_business_unchanged=True')
compile(text,'visual27_closure_DERIVED_BUILD.py','exec');exec(compile(text,str(N/'visual27_closure_DERIVED_BUILD.py'),'exec'),{'__file__':str(N/'visual27_closure_DERIVED_BUILD.py')})
print(json.dumps(dict(seal=rebind_pin,manifest=manifest_pin,Router=router_pin,publication=pin(publication_path))))
