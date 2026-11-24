"""Reuse the narrow26 closure with only actual phase-owner and header changes."""
from pathlib import Path
import hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01'
text=(N/'prepare_rebinding26_BUILD.py').read_text(encoding='utf8')
def change(a,b):
 global text
 assert text.count(a)==1,a[:100];text=text.replace(a,b,1)
change("O=N/'source_rebinding02_BUILD';U=O/'closure26'","O=N/'phase_lifetime03_BUILD';U=O/'closure27'")
change("'res://build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01/unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'","'res://build/luoyang_regions_20261027d_source01/source_rebinding02_BUILD/closure26_META03/source_rebind26_all_candidates_NOT_STAGE.json'")
change("'ddb955b71625acc92f02d23a896f9f5f306062ee623248a485b1be2e7ef29a47'","'01811684c804753c8c4b80fee62d7a9a16c51310e9dadbb869c644eaa355c622'")
change("root_region_integration_exact32_stage02/receipt.json","root_region_source_rebind26_stage03/receipt.json")
change("e569f5d85b4679175ff70a1f314d4eff3d8c4b8426471595b07539607a5376c5","ebeb133b25c8e6d8d27f1b571b5f4ebaf7a53acb6594c4ffa78bfceacefcb513")
change("rebindpin=pin(O/'source_rebinding_whole_binary_inverse_BUILD.json');rebind=load(rebindpin)","rebindpin=pin(O/'phase_owner_strong_reference_whole_inverse_BUILD.json');rebind=load(rebindpin)")
change("assert rebind['manifest_candidate']['sha256']=='77c638a7d229a6dfd2437b9b9374c15af68232899690d2d7dda52e17c44327ff'","assert rebind['manifest']['candidate']['sha256']=='85c16eb0506e60bb3b0310218bb942beafd90840f447b503d5e231de43be6023'")
change("record(R,'Router_READY.gd',read(rebind['Router']['candidate']))", "record(R,'Router_READY.gd',read(rebind['Router']['candidate']))\nRF=rebind['Field']['target'];rfraw=read(rebind['Field']['parent']);parents[RF]=emit('region_field_parent_C893.gd',rfraw);record(RF,'RegionField_READY.gd',read(rebind['Field']['candidate']))")
change("len(prior['source_sha256'])==284","len(prior['source_sha256'])==289")
change("len(ex['source_sha256'])==289","len(ex['source_sha256'])==294")
change("old_proof_count=284,new_proof_count=289","old_proof_count=289,new_proof_count=294")
change("manifest_target=rebind['manifest_target'];manifest_parent=emit('manifest_parent_5497.json',read(rebind['parent_manifest']));parents[manifest_target]=manifest_parent;refs[manifest_target]=rebind['manifest_candidate'];data[refs[manifest_target]['path']]=read(refs[manifest_target])", "manifest_target=rebind['manifest']['target'];manifest_parent=emit('manifest_parent_77C6.json',read(rebind['manifest']['parent']));parents[manifest_target]=manifest_parent;refs[manifest_target]=rebind['manifest']['candidate'];data[refs[manifest_target]['path']]=read(refs[manifest_target])")
start=text.index("ordinary={**extra,");end=text.index('\ndef at(value,ptr):',start)
text=text[:start]+"ordinary=dict(extra)"+text[end:]
change("meta('estate_final');meta('quarter_final')","meta('estate_final');index('ap_execution_index');meta('quarter_final')")
change("'legacy_index_4','ap_execution_index','ap_quarter_index'","'legacy_index_4','ap_quarter_index'")
change("len(records)==11 and len(metadata)==12 and len(refs)==26","len(records)==12 and len(metadata)==12 and len(refs)==27")
change("out=emit('source_rebind26_all_candidates_NOT_STAGE.json'","out=emit('phase_lifetime27_all_candidates_NOT_STAGE.json'")
text=text.replace('GD=11,JSON=15,total=26','GD=12,JSON=15,total=27').replace("count=26","count=27").replace("'count':26","'count':27").replace('current_D9A8_exact26_scope_PREPARATION.json','current_5FCE_exact27_scope_PREPARATION.json').replace('CURRENT_D9A8_SOURCE_REBIND26_NOT_STAGE','CURRENT_5FCE_PHASE_LIFETIME27_NOT_STAGE').replace('ROOT_BACKUP_EXACT_CHANGED26_PREPARATION','ROOT_BACKUP_EXACT_CHANGED27_PREPARATION')
compile(text,'phase27_closure_DERIVED_BUILD.py','exec');exec(compile(text,str(N/'phase27_closure_DERIVED_BUILD.py'),'exec'),{'__file__':str(N/'phase27_closure_DERIVED_BUILD.py')})
