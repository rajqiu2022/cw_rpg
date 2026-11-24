"""Declare two cold terminals from the fixed parent Stage, not observed values.
Reads small source metadata/PNG headers only. Root alone runs the Godot worker.
"""
from pathlib import Path
import json,hashlib,struct,re
N=Path(__file__).resolve().parent;G=N.parents[1]
S=G/'build/luoyang_city_finish_20261025i_source01'
sha=lambda raw:hashlib.sha256(raw).hexdigest()
def read_res(path):return (G/path[6:]).read_bytes()
stage_path='res://build/luoyang_city_finish_20261025i_source01/outputs/root_garden_estate_exact32_stage02/receipt.json'
stage_sha='956f16b0321dc8b29415ec390d4a1ba113aa4db27cd4b85e7fc57df5d00ca1c3'
raw=read_res(stage_path);assert sha(raw)==stage_sha
stage=json.loads(raw);available=stage['source_final'].copy()
for target in stage['targets']:available[target['target']]=target['candidate_sha256']
binding_path='res://build/luoyang_city_finish_20261025i_source01/garden_estate_exit_repair_20261027c01/closure_READY01/finish8_binding_READY.json'
binding_sha='2b1c0e0a34321812d9c190f8a2dc6675f46b29782a9cc5afd576d06c93727e10'
raw=read_res(binding_path);assert sha(raw)==binding_sha;binding=json.loads(raw)
reader=(S/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8')
scope={'struct':struct};exec(reader[reader.index('class FrozenVariant:'):reader.index('binding_pin=')],scope)
def media(path,pins):
 assert path in available,path
 pins[path]=available[path]
 if path.endswith('.png'):
  side=path+'.import';assert side in available,side
  raw=read_res(side);assert sha(raw)==available[side]
  match=re.search(r'path="(res://[^"\r\n]+\.ctex)"',raw.decode('utf8'));assert match,side
  ctex=match[1];assert ctex in available,ctex
  pins[side]=available[side];pins[ctex]=available[ctex]
bindings=[];sources={}
for logical in ['ch4_s1_luoyang_yamen','ch4_s3_luoyang_market']:
 row=binding['scenes'][logical];payload=row['payload'];raw=read_res(payload['path']);assert sha(raw)==payload['sha256']
 data=scope['FrozenVariant'](raw).value()
 original=row['required_original_source_sha256']
 scene=next(p for p in original if p.endswith('/scene.res'))
 layout=next(p for p in original if p.endswith('/layout.res'))
 declaration={'logical_id':logical,'payload':payload,'source_scene_path':scene,'source_scene_sha256':original[scene],'source_layout_path':layout,'source_layout_sha256':original[layout]}
 pins={payload['path']:payload['sha256'],scene:original[scene],layout:original[layout]}
 for path in ['res://data/maps/luoyang_district_life_20261016f/author.json','res://build/luoyang_city_blocks_20261024e_system01/author_market_block07_paper_foot_NOTREADY.json']:
  assert path in available,path;pins[path]=available[path]
 for item in data['effective_navigation']:media(item['texture'],pins)
 sources[logical]=pins;bindings.append(declaration)
module_paths=[
 'res://build/luoyang_regions_20261027d_source01/terminal_adapter.gd',
 'res://build/luoyang_regions_20261027d_source01/region_compiler.gd',
 'res://build/luoyang_regions_20261027d_source01/terminal_cold_compile_worker_NOTREADY.gd',
 'res://build/luoyang_city_rectification_20261027d_system01/logical_terminal_projector.gd',
 'res://build/luoyang_city_rectification_20261027d_system01/pure_portal_projection.gd']
# Newly authored code declarations, not a runtime or QA observed expectation.
modules={p:sha(read_res(p))for p in module_paths}
assert modules[module_paths[-2]]=='ce4bb7f2452e911d2e929db245f37a1b211fd7e3d74df0d1b794d37e494cd7fb'
assert modules[module_paths[-1]]=='a7f7a767be5808d5df64e348487b3eb0fdd1c08596604cd2337b7fc375bc1e8c'
input={'root_authorized':False,'status':'BUILD_ROOT_COLD_TERMINAL_COMPILE_ONLY','parent_stage':{'path':stage_path,'sha256':stage_sha},'binding':{'path':binding_path,'sha256':binding_sha},'bindings':bindings,'terminal_sources':sources,'module_sources':modules,'available_parent_sources':available,'output_root':'res://build/luoyang_regions_20261027d_source01/terminal_cold_output','scope':'Two pinned source Scene/Layout resources plus exact parent payloads; pure NPC/portal projection, PNG dimensions from headers only; no Field/legacy prepare/old full collector.'}
dest=N/'terminal_cold_compile_input_NOTREADY.json';assert not dest.exists()
raw=(json.dumps(input,ensure_ascii=False,indent=2)+'\n').encode('utf8');dest.write_bytes(raw)
bootstrap=N/'terminal_cold_compile_bootstrap_NOTREADY.gd';old=bootstrap.read_bytes();new=old.replace(b'PENDING_INPUT_SHA',sha(raw).encode()).replace(b'PENDING_WORKER_SHA',modules[module_paths[2]].encode())
assert old!=new and b'PENDING_' not in new;bootstrap.write_bytes(new)
print(json.dumps({'input':str(dest),'input_sha256':sha(raw),'worker_sha256':modules[module_paths[2]],'bootstrap_sha256':sha(new),'terminal_source_counts':{k:len(v)for k,v in sources.items()},'runtime_parent_source_list':'Only selected consumed pins copied to terminal; available_parent_sources is lookup-only, not source_pass(all).'}))
