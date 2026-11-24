"""Copy/guard/Router formatter: parameters only from the executed phase27 tools."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';O=S/'region_visual_finish_repair04';sha=lambda b:hashlib.sha256(b).hexdigest();res=lambda p:'res://'+p.relative_to(G).as_posix();proofs=[]
def pin(p):b=p.read_bytes();return dict(path=res(p),sha256=sha(b),bytes=len(b))
def emit(parent,dest,edits):
 raw=parent.read_bytes();text=raw.decode();steps=[]
 for a,b in edits:
  count=text.count(a);assert count>=1,(dest.name,a[:100]);text=text.replace(a,b);steps.append(dict(old=a,new=b,count=count))
 back=text
 for e in reversed(steps):assert back.count(e['new'])==e['count'];back=back.replace(e['new'],e['old'])
 assert back.encode()==raw;compile(text,str(dest),'exec');assert not dest.exists();dest.write_bytes(text.encode());proofs.append(dict(parent=pin(parent),candidate=pin(dest),hunks=steps,whole_UTF8_inverse=True,executed=False));return pin(dest)
common=[('region_phase_lifetime_repair03/current_5FCE_backup27_ROOT_ACTUAL.json','region_visual_finish_repair04/current_B78D_backup27_ROOT_ACTUAL.json'),('765e286c655194e33c06908bc98dcb1efed6c69d299684fff5545aff8a972dea','971ecd80919dc0852b91d86d930379a96d9319809977f1c5333a7e40f7822fb7'),('ROOT08_PHASE_OWNER_LIFETIME27_STAGED_NOT_DEPLOYED','ROOT08_VISUAL_FINISH27_STAGED_NOT_DEPLOYED'),("backup['old795_backup_facts']","backup['old822_backup_facts']")]
copy=emit(S/'copy_region_phase27_JSON15_after_GD12_ROOT_ONLY.py',S/'copy_region_visual27_JSON15_after_GD12_ROOT_ONLY.py',common+[
 ('Root-only Region/Gate exact JSON14 copy after GD18 patch; no engine or GD copy.','Root-only visual27 exact JSON15 copy after GD12 patch; no engine or GD copy.'),
 ('phase_lifetime03_BUILD/closure27/current_5FCE_exact27_scope_PREPARATION.json','visual_finish04_BUILD/closure27/current_B78D_exact27_scope_PREPARATION.json'),('4b23d7d1f2403029a431f5f83933fbe2b0face47e7d3ab19aabd63a2e1be8ada','49b335e90f028a0ccde6e945b04505cd1594c9a0e1c79e136c3e05bf3c677a9e'),("backup['total_backups']==822","backup['total_backups']==849"),('ROOT_REGION_PHASE27_DEPLOYED','ROOT_REGION_VISUAL27_DEPLOYED'),('ROOT_REGION_PHASE27_GD12','ROOT_REGION_VISUAL27_GD12'),('backup_count=822','backup_count=849'),('current_5FCE_backup_sha256=','current_B78D_backup_sha256='),('Root08_exact_phase_owner_lifetime=True','Root08_exact_visual_rectification=True')])
guard=emit(S/'guard_region_phase27_current2121_ROOT_ONLY.py',S/'guard_region_visual27_current2121_ROOT_ONLY.py',common+[
 ('phase_lifetime03_BUILD/closure27/phase_lifetime27_all_candidates_NOT_STAGE.json','visual_finish04_BUILD/closure27/visual27_all_candidates_NOT_STAGE.json'),('6b4ae21453bf07bb47b77dcebe1016dce26decc740fd61cb10342ad2ecbd335a','a401dae028095d30f1812024d54fb31be59e6bb401ab8d7edc1368215acb9d05'),('ROOT_REGION_PHASE27_DEPLOYED','ROOT_REGION_VISUAL27_DEPLOYED'),('old795_backups_exactticks','old822_backups_exactticks'),('ROOT_REGION_PHASE27_POST','ROOT_REGION_VISUAL27_POST'),('backups_total=822','backups_total=849')])
formatter=emit(S/'region_phase_lifetime_repair03/restore_Router13CRLF_after_apply_patch_ROOT_ONLY.py',O/'restore_Router13CRLF_after_apply_patch_ROOT_ONLY.py',[
 ('build/luoyang_regions_20261027d_source01/phase_lifetime03_BUILD/Router_phase_manifest_CANDIDATE.gd','build/luoyang_regions_20261027d_source01/visual_finish04_BUILD/Router_visual_manifest_CANDIDATE.gd'),('fff398a42aa0dea09ed34eb96cc21106b4eb74913a4cf1ec23501df6d0450ba7','d25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc'),("(GAME/'build/luoyang_city_finish_20261025i_source01/region_phase_lifetime_repair03').resolve()","(GAME/'build/luoyang_city_finish_20261025i_source01/region_visual_finish_repair04').resolve()")])
out=O/'copy_guard_Router27_transport_whole_inverse_NOT_EXECUTED.json';out.write_bytes((json.dumps(dict(transports=proofs,executed=False),ensure_ascii=False,indent=2)+'\n').encode());print(json.dumps(dict(copy=copy,guard=guard,formatter=formatter,inverse=pin(out))))
