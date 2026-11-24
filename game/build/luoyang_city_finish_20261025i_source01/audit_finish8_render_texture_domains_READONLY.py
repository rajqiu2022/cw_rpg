"""Fixed payload selector + source-pipeline audit, not Godot/packet/geometry execution."""
from pathlib import Path
import json,hashlib,struct
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h;return b
class FrozenVariant:
 def __init__(self,b):self.b=b;self.p=0
 def take(self,fmt):
  size=struct.calcsize(fmt);v=struct.unpack_from(fmt,self.b,self.p);self.p+=size;return v
 def string(self):
  size=self.take('<I')[0];v=self.b[self.p:self.p+size].rstrip(b'\0').decode();self.p+=(size+3)//4*4;return v
 def value(self):
  header=self.take('<I')[0];t=header&65535;wide=bool(header&65536);assert header&~131071==0,(header,self.p)
  if t==0:return None
  if t==1:return bool(self.take('<I')[0])
  if t==2:return self.take('<q'if wide else'<i')[0]
  if t==3:return self.take('<d'if wide else'<f')[0]
  if t in [4,21]:return self.string()
  counts={5:2,7:4,9:3,11:6,12:4,14:4,15:4,16:6,17:9,18:12,19:16,20:4}
  if t in counts:return self.take('<'+('f'if t==20 or not wide else'd')*counts[t])
  if t in [6,8,10,13]:return self.take('<'+'i'*{6:2,8:4,10:3,13:4}[t])
  if t==27:
   count=self.take('<I')[0]&0x7fffffff;v={}
   for _ in range(count):key=self.value();v[key]=self.value()
   return v
  if t==28:
   if wide:
    builtin=self.take('<I')[0];assert builtin in [1,2,3,4,5,6,7,8,20,21,27,28,29,30,31,32,33,34,35,36,37,38],('UNSUPPORTED_TYPED_ARRAY',builtin,self.p)
   return[self.value()for _ in range(self.take('<I')[0]&0x7fffffff)]
  if t==29:
   n=self.take('<I')[0];v=self.b[self.p:self.p+n];self.p+=(n+3)//4*4;return v
  if t in [30,31,32,33,35,36,37,38]:
   n=self.take('<I')[0];fmt={30:'i',31:'q',32:'f',33:'d',35:('dd'if wide else'ff'),36:('ddd'if wide else'fff'),37:'ffff',38:('dddd'if wide else'ffff')}[t];return[self.take('<'+fmt)for _ in range(n)]
  if t==34:return[self.string()for _ in range(self.take('<I')[0])]
  raise AssertionError(('UNSUPPORTED_FIXED_PAYLOAD_SELECTOR_TYPE',t,self.p))
binding_pin=dict(path=S+'gate_texture_repair01/closure_READY01/finish8_binding_READY.json',sha256='5098755c3df66ab173522547692526ad50761835d81a9e1ebfab1ba8aadf04f4')
binding=json.loads(read(**dict(p=binding_pin['path'],h=binding_pin['sha256'])));rows={}
for id,row in binding['scenes'].items():
 raw=read(row['payload']['path'],row['payload']['sha256']);v=FrozenVariant(raw);data=v.value();assert v.p==len(raw)and isinstance(data,dict)
 parent=data['parent_navigation'];effective=data['effective_navigation'];patches=data['visual_patches'];additions=data['visual_additions'];retired=data['visual_retired']
 assert isinstance(parent,list)and isinstance(effective,list)and len({r['id']for r in effective})==len(effective)
 pp={r['id']:r for r in parent};changed={r['id']:r for r in patches};retired_ids={r['id']for r in retired};render=[]
 for r in parent:
  if r['id']in retired_ids:continue
  if r['id']in changed:assert r==changed[r['id']]['before'];render.append(changed[r['id']]['after'])
  else:render.append(r)
 render.extend(additions)
 # Parent-navigation projection is exactly the published complete table. Task
 # visibility may remove existing rows, never synthesize a new texture here.
 assert render==effective,id
 texture_ids={}
 for r in effective:
  path=r.get('texture','')
  if path:texture_ids.setdefault(path,[]).append(r['id'])
 rows[id]=dict(payload=row['payload'],parent_navigation_rows=len(parent),effective_navigation_rows=len(effective),unique_navigation_texture_paths=len(texture_ids),texture_to_nav_ids=texture_ids,project_render_on_parent_navigation_exactly_effective_navigation=True,old_task_render_changes='Existing row filters only; same original material path, or row removed. No added texture.',district_identity_guard=id in ['ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market'],Temple_identity_guard=id=='ch4_s4_ancient_temple',render_only_guarded_suffixes=[])
market='ch4_s3_luoyang_market';ground='res://art/modules/luoyang_shore_market_20261020ae/decal_market_cross_street_stall_wear_patch_v1.png'
authority=json.loads(read(S+'repair31_READY03/maps/ch4_s3_luoyang_market_true.json','1b4db5e0892a4e27b841b7a576f15f9f6a62077554295064baba4b068cc4a923'))['source_sha256']
manifest_path='res://data/maps/luoyang_market_ground_20261020ae/manifest.json';manifest=json.loads(read(manifest_path,authority[manifest_path]));assert len(manifest['overlays'])==1 and len(manifest['textures'])==1 and ground not in rows[market]['texture_to_nav_ids']
assert manifest['overlays'][0]['id']=='market_ground_ae_cross_street_wear_v1'and manifest['overlays'][0]['texture']==ground
rows[market]['render_only_guarded_suffixes']=[dict(id=manifest['overlays'][0]['id'],texture=ground,source_sha256=authority[ground],producer='MARKET_GROUND.prepare -> DT._market_ground.textures -> DT._textures; render -> D296.render_with_ground ->25g.render_with_ground appends one full unchanged source material',cold_finish_cache_contains_path=False,known_strict_matcher_rejection=True,ground_manifest=dict(path=manifest_path,sha256=authority[manifest_path]))]
selectors=[]
for p in ['res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/city/luoyang_market_ground_20261020ae.gd','res://scripts/city/luoyang_city_tasks_20261016.gd','res://scripts/city/luoyang_temple_task_adapter_20261016.gd','res://scripts/city/luoyang_quarters_native_geometry_20261022ap.gd']:
 assert p in authority;read(p,authority[p]);selectors.append(dict(path=p,sha256=authority[p]))
report=dict(status='READONLY_FIXED_EIGHT_PAYLOAD_AND_RENDER_PIPELINE_TEXTURE_DOMAIN_AUDIT',passed=True,binding=binding_pin,scenes=rows,source_selectors=selectors,conclusion='Only guarded render-only material is the old Market AE decal. All eight full navigation projections carry their texture paths. Gate ImageTexture/Atlas uses its existing exact Gate bridge. Garden bridge layers remain in its full native visual rows; NG water/shore, Harbour water and ENV purpose nodes use separate constructors, not this prop guard. Family three scenes do not enter district/Temple texture_matches guard.',limitations=['Source-expression/preflight diagnosis, not actual Field identity observations or proof of runtime readiness.','No new source authority is obtained by reading current files: all script values are fixed Market2027 source expectations.','No geometry/raster/PNG/ResourceLoader or packet read. Payload binary selector is not a re-publication or independent geometry validation.'],engine_calls=0,collector_calls=0,packet_decodes=0,PNG_decodes=0,canonical_writes=0)
out=N/'remaining8_render_texture_domains_READONLY.json';assert not out.exists();raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
with out.open('xb')as f:f.write(raw)
print(json.dumps(dict(path=S+out.name,sha256=sha(raw),scenes={id:dict(nav=r['effective_navigation_rows'],textures=r['unique_navigation_texture_paths'],guarded_render_only=r['render_only_guarded_suffixes'])for id,r in rows.items()})))
