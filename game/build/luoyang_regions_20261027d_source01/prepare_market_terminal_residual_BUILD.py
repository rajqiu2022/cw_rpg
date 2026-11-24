"""Only Market residual; preserve the actual Yamen terminal and failed run."""
from pathlib import Path
import json,hashlib,sys
third='--03' in sys.argv
N=Path(__file__).resolve().parent;G=N.parents[1]
sha=lambda raw:hashlib.sha256(raw).hexdigest()
def res(path):return 'res://'+path.relative_to(G).as_posix()
parent=N/'terminal_cold_compile_input_NOTREADY.json';raw=parent.read_bytes()
assert sha(raw)=='466c795a69c2bc36f17923b58580d1f19cc05f0c5dec565dfe2a21944c2f80c3'
d=json.loads(raw);d['bindings']=[x for x in d['bindings']if x['logical_id']=='ch4_s3_luoyang_market'];assert len(d['bindings'])==1
d['terminal_sources']={k:v for k,v in d['terminal_sources'].items()if k=='ch4_s3_luoyang_market'}
pins=d['terminal_sources']['ch4_s3_luoyang_market'];available=d['available_parent_sources']
for h in ['8f708341b9923e53d016aa2198900e2a8c93085e11b154b42b6c44ff4bc1ba6e','7e1f6b1dc4dd4d693438bd0f672657063b3f42c0092ad50028f3aa632b03d31f']:
 paths=[p for p,value in available.items()if value==h and p.endswith('.json')];assert len(paths)==1,(h,paths)
 pins[paths[0]]=h
paths=[p for p,value in available.items()if value=='003ec7f690ed9494f315132a4f3f6e16263ad3ca38ccb34392913ae07c5f4cdb'];assert len(paths)==1
pins[paths[0]]=available[paths[0]]
new_projector='res://build/luoyang_city_rectification_20261027d_system01/'+('logical_terminal_projector03_market_task_space.gd' if third else 'logical_terminal_projector02_market_space.gd')
projector_sha='819ecab34a6e5d4c57f4a5de562fcf710b63563aa22f85615a49bd779fae1d90' if third else '904e81e129e5394a1336dbb5ad65a37102cd2bcff94ed9e023875ea1d85fa03f'
assert sha((G/new_projector[6:]).read_bytes())==projector_sha
modules=d['module_sources'];modules.pop('res://build/luoyang_city_rectification_20261027d_system01/logical_terminal_projector.gd');modules[new_projector]=projector_sha
worker_name='terminal_market_residual03_worker_NOTREADY.gd' if third else 'terminal_market_residual_worker_NOTREADY.gd'
adapter_name='terminal_adapter03_market.gd' if third else 'terminal_adapter02_market.gd'
for before,after in [('terminal_adapter.gd',adapter_name),('terminal_cold_compile_worker_NOTREADY.gd',worker_name)]:
 old=N/before;new=N/after;modules.pop(res(old));modules[res(new)]=sha(new.read_bytes())
d['status']='ROOT_MARKET_RESIDUAL_NEW_SOURCE_PROJECTION_NOT_YAMEN_REPLAY'
d['output_root']='res://build/luoyang_regions_20261027d_source01/terminal_market_residual_output'
d['inherited_yamen_terminal']={'path':'res://build/luoyang_regions_20261027d_source01/terminal_cold_output/124012/ch4_s1_luoyang_yamen_terminal.bin','sha256':'287198326f64837ea87883a8a3c0866f5e59eec7cb9e4a22f5b25d1a093e8aac','bytes':425468}
dest=N/('terminal_market_residual03_input_NOTREADY.json' if third else 'terminal_market_residual_input_NOTREADY.json');assert not dest.exists();data=(json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode();dest.write_bytes(data)
old=N/'terminal_cold_compile_bootstrap_NOTREADY.gd';text=old.read_text(encoding='utf8')
text=text.replace(res(parent),res(dest)).replace(sha(raw),sha(data)).replace('terminal_cold_compile_worker_NOTREADY.gd',worker_name).replace('2a634fe50a057ba7c5a795c9b3d46655a2a4a357de3d67e3721251708065e306',modules[res(N/worker_name)])
boot=N/('terminal_market_residual03_bootstrap_NOTREADY.gd' if third else 'terminal_market_residual_bootstrap_NOTREADY.gd');assert not boot.exists();boot.write_text(text,encoding='utf8',newline='\n')
print(json.dumps({'input':res(dest),'input_sha256':sha(data),'worker':res(N/worker_name),'worker_sha256':modules[res(N/worker_name)],'bootstrap':res(boot),'bootstrap_sha256':sha(boot.read_bytes()),'adapter_sha256':modules[res(N/adapter_name)],'new_source_pins':{p:h for p,h in pins.items()if p in paths or h.startswith(('8f708','7e1f6'))}}))
