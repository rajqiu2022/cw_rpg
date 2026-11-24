"""Supplement only the nine historically declared actor-media leaves."""
from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1]
sha=lambda raw:hashlib.sha256(raw).hexdigest()
res=lambda path:'res://'+path.relative_to(G).as_posix()
parent=N/'terminal_market_residual03_input_NOTREADY.json';raw=parent.read_bytes();assert sha(raw)=='720ef10b9f9e3bdb6c2984f575e14b7c22976b58acb576d929f83cb5a84d17ac'
d=json.loads(raw)
report=G/'build/luoyang_city_rectification_20261027d_system01/market_final_actor_media_READONLY.json';rb=report.read_bytes();assert sha(rb)=='d2a8312ec0adef210baf73a969cffdc9c4aa83d2c6fe2dab36455850b28f99cf'
e=json.loads(rb);history=e['history'];assert sha((G/history['path'][6:]).read_bytes())==history['sha256']
extra={}
for missing in e['missing']:
 for path,value in missing['historical_tuple'].items():
  assert path not in d['available_parent_sources'];d['available_parent_sources'][path]=value;extra[path]=value
assert len(extra)==9
d['historical_media_supplement']={'source':history,'read_only_report':{'path':res(report),'sha256':sha(rb)},'exact_nine_old_declared_leaves':extra,'is_current_observation_authority':False}
d['final_actor_media_paths']=sorted({row.get(key,'')for row in e['actors']for key in ['sprite_path','portrait_path','walk_sprite_path']}-{''})
assert len(d['final_actor_media_paths'])==e['unique_media_count']==21
worker=N/'terminal_market_media04_worker_NOTREADY.gd';worker_sha=sha(worker.read_bytes())
modules=d['module_sources'];modules.pop(res(N/'terminal_market_residual03_worker_NOTREADY.gd'));modules[res(worker)]=worker_sha
modules[res(report)]=sha(rb)
d['status']='MARKET_MEDIA_SEAL_ONLY_EXISTING_GEOMETRY_MIGRATION_PREFIX_INHERITED'
d['inherited_component_actual']={'result':'res://build/luoyang_regions_20261027d_source01/terminal_market_residual_output/56564/result.json','components':'Complete native8/Task1/DG10 positions through DT/Space/DE191/finish, 71 complete owner solids and render transforms; whole run remained FAIL at actor-media authority.'}
dest=N/'terminal_market_media04_input_NOTREADY.json';assert not dest.exists();data=(json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode();dest.write_bytes(data)
boot0=N/'terminal_market_residual03_bootstrap_NOTREADY.gd';text=boot0.read_text(encoding='utf8').replace(res(parent),res(dest)).replace(sha(raw),sha(data)).replace('terminal_market_residual03_worker_NOTREADY.gd',worker.name).replace('aa9174fffe6b4a0bfb52687a2088f6ed3ebfd0e7898581fdf8218b86548a6bad',worker_sha)
boot=N/'terminal_market_media04_bootstrap_NOTREADY.gd';assert not boot.exists();boot.write_text(text,encoding='utf8',newline='\n')
print(json.dumps({'input':res(dest),'input_sha256':sha(data),'worker':res(worker),'worker_sha256':worker_sha,'bootstrap':res(boot),'bootstrap_sha256':sha(boot.read_bytes()),'all_media':len(d['final_actor_media_paths']),'supplement':len(extra),'projector_changed':False,'adapter_changed':False}))
