"""Reuse final Root32 transport, only exact changed26/current795 parameters."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';O=S/'region_source_rebind_repair02';sha=lambda b:hashlib.sha256(b).hexdigest();res=lambda p:'res://'+p.relative_to(G).as_posix();proofs=[]
def pin(p):b=p.read_bytes();return dict(path=res(p),sha256=sha(b),bytes=len(b))
def emit(parent,dest,edits):
 raw=parent.read_bytes();text=raw.decode();steps=[]
 for a,b in edits:
  count=text.count(a);assert count>=1,(dest.name,a[:100]);text=text.replace(a,b);steps.append(dict(old=a,new=b,count=count))
 back=text
 for e in reversed(steps):assert back.count(e['new'])==e['count'],(dest.name,e['new'][:100]);back=back.replace(e['new'],e['old'])
 assert back.encode()==raw;compile(text,str(dest),'exec');assert not dest.exists();dest.write_bytes(text.encode());proofs.append(dict(parent=pin(parent),candidate=pin(dest),hunks=steps,whole_UTF8_inverse=True,executed=False));return pin(dest)
common=[
 ('region_integration_20261027d01/current_01656_backup32_ROOT_ACTUAL.json','region_source_rebind_repair02/current_D9A8_backup26_ROOT_ACTUAL.json'),
 ('5d406f8866427ace84600088b30748ec8bd3d30d8ed5bcd1b170316c11b882c1','35a5b2269ddc6897d1e7689506bf353ca7988a9eed5a6b1f7142bbd637769048'),
 ("stage['status']=='ROOT08_REGION_GATE_EXACT32_STAGED_NOT_DEPLOYED'","stage['status']=='ROOT08_IMMUTABLE_SOURCE_REBIND26_STAGED_NOT_DEPLOYED'"),
 ('dict(patch_count=18,copy_count=14,total=32)','dict(patch_count=11,copy_count=15,total=26)'),
 ("backup['old737_backup_facts']","backup['old769_backup_facts']"),
]
copy=emit(S/'copy_region_integration32_JSON14_after_GD18_ROOT_ONLY02.py',S/'copy_region_source_rebind26_JSON15_after_GD11_ROOT_ONLY.py',common+[
 ('region_integration_20261027d01/current_01656_exact32_scope_PREPARATION.json','../luoyang_regions_20261027d_source01/source_rebinding02_BUILD/closure26/current_D9A8_exact26_scope_PREPARATION.json'),
 ("scope=load(S+'../luoyang_regions_20261027d_source01/source_rebinding02_BUILD/closure26/current_D9A8_exact26_scope_PREPARATION.json'", "scope=load('res://build/luoyang_regions_20261027d_source01/source_rebinding02_BUILD/closure26/current_D9A8_exact26_scope_PREPARATION.json'"),
 ('1db5759bfd8ae094f8f5a7b623a55927d285d1f63cdccb378a811ddb49732494','10c5ec0d991dd351f0f9510815be4d36286992afffb71adaa42e019f55cdc58f'),
 ("backup['total_backups']==769","backup['total_backups']==795"),
 ("len(plan['rows'])==14","len(plan['rows'])==15"),("len(targets)==32","len(targets)==26"),
 ("'ROOT_REGION_INTEGRATION32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'","'ROOT_REGION_SOURCE_REBIND26_DEPLOYED_GD11_PATCH_JSON15_EXACTCOPY'"),
 ("'ROOT_REGION_INTEGRATION32_GD18_NEW_JSON14_OLD_PREFLIGHT_ONLY'","'ROOT_REGION_SOURCE_REBIND26_GD11_NEW_JSON15_OLD_PREFLIGHT_ONLY'"),
 ('target_count=32','target_count=26'),('JSON14_written=written','JSON15_written=written'),('backup_count=769','backup_count=795'),('targets=32','targets=26'),('current_01656_backup_sha256=','current_D9A8_backup_sha256='),('Root08_Region_and_Gate_exact_integration=True','Root08_source_only_immutable_key_rebind=True'),
])
guard=emit(S/'guard_region_integration32_current2121_ROOT_ONLY.py',S/'guard_region_source_rebind26_current2121_ROOT_ONLY.py',common+[
 ("S+'region_integration_20261027d01/unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'","'res://build/luoyang_regions_20261027d_source01/source_rebinding02_BUILD/closure26/source_rebind26_all_candidates_NOT_STAGE.json'"),
 ('ddb955b71625acc92f02d23a896f9f5f306062ee623248a485b1be2e7ef29a47','5b9cabaa211abcf1c1cf1b5a2ddc1115dcb02eb5764983dadfbc74ac7ed0a77e'),
 ("dep['status']=='ROOT_REGION_INTEGRATION32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'","dep['status']=='ROOT_REGION_SOURCE_REBIND26_DEPLOYED_GD11_PATCH_JSON15_EXACTCOPY'"),
 ("len(dep['JSON14_written'])==14","len(dep['JSON15_written'])==15"),("len(st)==32","len(st)==26"),
 ("'exact32'","'exact26'"),("'old737_backups_exactticks'","'old769_backups_exactticks'"),("'old212_media_SHA_bytes_run_ticks'","'old221_media_SHA_bytes_run_ticks'"),
 ("status='ROOT_REGION_INTEGRATION32_POST_CURRENT2121_READONLY_GUARD'","status='ROOT_REGION_SOURCE_REBIND26_POST_CURRENT2121_READONLY_GUARD'"),('backups_total=769','backups_total=795'),('authorized_targets=32','authorized_targets=26'),
])
formatter=emit(S/'region_integration_20261027d01/restore_Router13CRLF_after_apply_patch_ROOT_ONLY.py',O/'restore_Router13CRLF_after_apply_patch_ROOT_ONLY.py',[
 ('build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01/closure_READY01/Router_READY.gd','build/luoyang_regions_20261027d_source01/source_rebinding02_BUILD/Router_manifest_source_rebind_CANDIDATE.gd'),
 ('eddb274e6c09d573879234ba7b303b490ffccd33dff2c91d329e46e0c52840f4','8c70847f2827137615b6e5c0f1d30b6b91a8f2cb5c663d0a0725b6a856959202'),
 ("(GAME/'build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01').resolve()","(GAME/'build/luoyang_city_finish_20261025i_source01/region_source_rebind_repair02').resolve()"),
])
out=O/'copy_guard_Router26_transport_whole_inverse_NOT_EXECUTED.json';assert not out.exists();out.write_bytes((json.dumps(dict(transports=proofs,executed=False),ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(copy=copy,guard=guard,formatter=formatter,whole_inverse=pin(out))))
