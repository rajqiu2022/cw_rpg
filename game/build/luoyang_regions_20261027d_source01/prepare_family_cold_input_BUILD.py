"""Declare the two genuine Family/Temple source contexts, not new Region scenes."""
from pathlib import Path
import json,hashlib,struct,re
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';P=G/'build/luoyang_city_rectification_20261027d_system01'
sha=lambda data:hashlib.sha256(data).hexdigest();res=lambda path:'res://'+path.relative_to(G).as_posix()
def put(path,data):
 assert not path.exists();raw=(json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode();path.write_bytes(raw);return sha(raw)
seed=json.loads((N/'terminal_market_media04_input_NOTREADY.json').read_text(encoding='utf8'))
available=seed['available_parent_sources']
bpath=G/seed['binding']['path'][6:];raw=bpath.read_bytes();assert sha(raw)==seed['binding']['sha256'];binding=json.loads(raw)
reader=(S/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8');scope={'struct':struct};exec(reader[reader.index('class FrozenVariant:'):reader.index('binding_pin=')],scope)
def media(path,pins):
 assert path in available,path;pins[path]=available[path]
 if path.endswith(('.png','.jpg')):
  side=path+'.import';assert side in available,side
  raw=(G/side[6:]).read_bytes();assert sha(raw)==available[side]
  ctex=re.search(rb'path="(res://[^"\r\n]+\.ctex)"',raw)[1].decode();assert ctex in available,ctex
  pins[side]=available[side];pins[ctex]=available[ctex]
 elif path.endswith('.tres'):
  raw=(G/path[6:]).read_bytes();assert sha(raw)==available[path]
  textures=re.findall(rb'path="(res://[^"\r\n]+\.png)"',raw)
  assert len(textures)==1,path
  media(textures[0].decode(),pins)
bindings=[];sources={}
for logical in ['luoyang_estate_riverside_20261021ai','ch4_s4_ancient_temple']:
 row=binding['scenes'][logical];payload=row['payload'];data=scope['FrozenVariant']((G/payload['path'][6:]).read_bytes()).value()
 original=row['required_original_source_sha256'];scene=next(p for p in original if p.endswith(('/scene.res','/temple.tres')));layout=next(p for p in original if p.endswith(('/layout.res','/layout.tres')))
 assert available.get(scene)==original[scene] and available.get(layout)==original[layout]
 declaration={'logical_id':logical,'payload':payload,'source_scene_path':scene,'source_scene_sha256':original[scene],'source_layout_path':'' if logical=='ch4_s4_ancient_temple' else layout,'source_layout_sha256':'' if logical=='ch4_s4_ancient_temple' else original[layout]}
 pins={payload['path']:payload['sha256'],scene:original[scene],layout:original[layout]}
 for item in data['effective_navigation']:media(item['texture'],pins)
 if logical=='ch4_s4_ancient_temple':
  path='res://build/luoyang_city_finish_20261025i_source01/author_temple_source_compiled03_NOTREADY.json';pins[path]=available[path]
 # These are existing actor pictures. The full projector media capture retains
 # only actual used leaves in each terminal; no global source_pass(all lookup).
 bindings.append(declaration);sources[logical]=pins
worker=N/'terminal_family_cold_worker_NOTREADY.gd'
worker_parent=(N/'terminal_cold_compile_worker_NOTREADY.gd').read_bytes()
assert sha(worker_parent)=='2a634fe50a057ba7c5a795c9b3d46655a2a4a357de3d67e3721251708065e306'
assert worker_parent.count(b'/terminal_adapter.gd')==1
worker_bytes=worker_parent.replace(b'/terminal_adapter.gd',b'/terminal_adapter04_family.gd')
if worker.exists(): assert worker.read_bytes()==worker_bytes
else: worker.write_bytes(worker_bytes)
paths=[N/'region_compiler.gd',N/'terminal_adapter04_family.gd',worker,P/'logical_terminal_projector03_market_task_space.gd',P/'pure_family_portal_projection.gd']
modules={res(p):sha(p.read_bytes())for p in paths}
input={'root_authorized':False,'status':'GENUINE_ESTATE_TEMPLE_PURE_COLD_INPUTS','bindings':bindings,'terminal_sources':sources,'module_sources':modules,'available_parent_sources':available,'output_root':res(N/'terminal_family_cold_output'),'scope':'Two genuine source Scenes with exact parent/native and published geometry. No old Family/Temple prepare, no Region/Field, no pixel decode.'}
dest=N/'terminal_family_cold_input02_NOTREADY.json';input_sha=put(dest,input)
boot=(N/'terminal_market_media04_bootstrap_NOTREADY.gd').read_text(encoding='utf8').replace('terminal_market_media04_input_NOTREADY.json',dest.name).replace('3955871bfbd504d3bfd21fc417084d90166f0f564e7eea9d8398c1ce8c3dba6f',input_sha).replace('terminal_market_media04_worker_NOTREADY.gd','terminal_family_cold_worker_NOTREADY.gd').replace('51ee58aeb0917ce21260458585e4e6ed80769e899f203e3a77008bc19f45e7b4',modules[res(N/'terminal_family_cold_worker_NOTREADY.gd')])
out=N/'terminal_family_cold_bootstrap02_NOTREADY.gd';assert not out.exists();out.write_text(boot,encoding='utf8',newline='\n')
print(json.dumps({'input_sha256':input_sha,'bootstrap_sha256':sha(out.read_bytes()),'worker_sha256':modules[res(N/'terminal_family_cold_worker_NOTREADY.gd')],'counts':{k:len(v)for k,v in sources.items()}}))
