"""Small fixed-payload owner catalog for ART/27d authoring; no Godot/PNG/QA replay."""
from pathlib import Path
import json,hashlib,struct
N=Path(__file__).resolve().parent;G=N.parents[1]
S=G/'build/luoyang_city_finish_20261025i_source01'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def read(path,want):
 p=G/path[6:] if path.startswith('res://') else Path(path)
 raw=p.read_bytes();assert sha(raw)==want.lower(),(str(p),sha(raw));return raw
binding_path='res://build/luoyang_city_finish_20261025i_source01/garden_estate_exit_repair_20261027c01/closure_READY01/finish8_binding_READY.json'
binding_sha='2b1c0e0a34321812d9c190f8a2dc6675f46b29782a9cc5afd576d06c93727e10'
binding=json.loads(read(binding_path,binding_sha))
reader=(S/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8')
scope={'struct':struct};exec(reader[reader.index('class FrozenVariant:'):reader.index('binding_pin=')],scope)
scenes={}
for ident in ['ch4_s1_luoyang_yamen','ch4_s3_luoyang_market','luoyang_estate_riverside_20261021ai','ch4_s4_ancient_temple']:
 row=binding['scenes'][ident];payload=row['payload'];raw=read(payload['path'],payload['sha256']);decoder=scope['FrozenVariant'](raw);data=decoder.value();assert decoder.p==len(raw)
 size=row['world_size_px'];owners=[]
 for item in data['effective_navigation']:
  pos=item.get('pos');foot=item.get('world_foot_px')
  if foot is None and 'depth_sort_foot_y'in item and pos is not None:foot=[pos[0]*size[0],item['depth_sort_foot_y']*size[1]]
  owners.append(dict(id=item['id'],texture=item.get('texture'),world_foot_px=foot,source_pos_uv=pos,render_size_px=item.get('render_size_px'),scale=item.get('scale'),centered=item.get('centered',True),metadata={k:v for k,v in item.items()if k not in ['id','texture','pos','scale','centered']and not isinstance(v,bytes)}))
 scenes[ident]=dict(payload=payload,world_size_px=size,owners=owners,solid_count=len(data['effective_solids']),portal_target_changes=data.get('portal_after',[]),npc_migrations=data.get('npc_migrations',[]),new_NPCs=data.get('new_NPCs',[]),required_original_sources=row['required_original_source_sha256'],notes='NPC migrations/new_NPCs are NOT a complete terminal NPC list; System source projector supplies that list. Portal_after is changed targets only, not the complete original portal list.')
result=dict(status='BUILD_SOURCE_PAYLOAD_OWNER_CATALOG_NOT_GEOMETRY_VALIDATION',binding=dict(path=binding_path,sha256=binding_sha),scenes=scenes,engine_calls=0,PNG_decodes=0,canonical_writes=0)
dest=N/'legacy_layout_owner_catalog01_BUILD.json';assert not dest.exists();raw=(json.dumps(result,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
with dest.open('xb')as f:f.write(raw)
print(json.dumps(dict(path='res://'+dest.relative_to(G).as_posix(),sha256=sha(raw),owners={k:len(v['owners'])for k,v in scenes.items()})))
