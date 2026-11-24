"""Exactly describe all fourteen existing Estate Atlases, then one Estate seal.
The source bytes are authenticated against the fixed parent, not current-fill.
"""
from pathlib import Path
import json,hashlib,struct,re
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01'
sha=lambda data:hashlib.sha256(data).hexdigest();res=lambda p:'res://'+p.relative_to(G).as_posix()
def write(path,raw):
 assert not path.exists(),str(path);path.write_bytes(raw);return sha(raw)
parent=N/'terminal_family_cold_input02_NOTREADY.json';before=parent.read_bytes();assert sha(before)=='9bbbbe01d265765fe611c9c35dcbca2691fa349c8a98d107e59fc56a069a6402'
d=json.loads(before);logical='luoyang_estate_riverside_20261021ai';binding=next(row for row in d['bindings']if row['logical_id']==logical)
reader=(S/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8');scope={'struct':struct};exec(reader[reader.index('class FrozenVariant:'):reader.index('binding_pin=')],scope)
raw=(G/binding['payload']['path'][6:]).read_bytes();assert sha(raw)==binding['payload']['sha256'];payload=scope['FrozenVariant'](raw).value()
descriptors={}
for path in sorted({row['texture']for row in payload['effective_navigation']if row['texture'].endswith('.tres')}):
 raw=(G/path[6:]).read_bytes();expected=d['available_parent_sources'][path];assert sha(raw)==expected
 text=raw.decode('utf8');assert 'type="AtlasTexture"'in text
 atlas=re.findall(r'path="(res://[^"\r\n]+\.png)"',text);assert len(atlas)==1
 values=[float(v.strip())for v in re.search(r'region = Rect2\(([^)]+)\)',text)[1].split(',')];assert len(values)==4 and values[2]>0 and values[3]>0
 margin=re.search(r'margin = Rect2\(([^)]+)\)',text);margin=[float(v.strip())for v in margin[1].split(',')]if margin else [0,0,0,0];assert margin==[0,0,0,0]
 clip=re.search(r'filter_clip = (true|false)',text);clip=bool(clip and clip[1]=='true')
 descriptors[path]={'resource_sha256':expected,'atlas_source':atlas[0],'region':[[*values[:2]],[*values[2:]]],'margin':[[0,0],[0,0]],'filter_clip':clip,'texture_size_px':values[2:]}
assert len(descriptors)==14 and sum(row['filter_clip']for row in descriptors.values())==6
binding['atlas_textures']=descriptors
adapter0=N/'terminal_adapter04_family.gd';code=adapter0.read_bytes();assert sha(code)=='be1624766f03b3a22cd6828f22ed08edbec7c4229787368db1928fe28c7e608f'
start=code.index(b'static func family_texture_size(');end=code.index(b'\nstatic func family_parent_solids(',start)
replacement=b'''static func family_texture_size(path: String, pins: Dictionary, descriptions: Dictionary) -> Vector2:
	if path.ends_with(".png"): return png_size(path)
	var description: Dictionary = descriptions.get(path, {})
	if description.is_empty() or not path.ends_with(".tres") or pins.get(path) != description.get("resource_sha256"): return Vector2.ZERO
	var atlas: AtlasTexture = load(path) as AtlasTexture
	var dimensions: Vector2 = Core.vec(description.get("texture_size_px"))
	var atlas_path: String = String(description.get("atlas_source", ""))
	if atlas == null or atlas.atlas == null or not pins.has(atlas_path) or atlas.atlas != load(atlas_path): return Vector2.ZERO
	if atlas.region != Core.rect(description.get("region")) or atlas.margin != Core.rect(description.get("margin")) or atlas.filter_clip != description.get("filter_clip"): return Vector2.ZERO
	if atlas.region.size != dimensions or atlas.get_size() != dimensions or not dimensions.is_finite() or dimensions.x <= 0 or dimensions.y <= 0: return Vector2.ZERO
	return dimensions
'''
old_function=code[start:end];newcode=code[:start]+replacement+code[end:]
newcode=newcode.replace(b'family_texture_size(texture, declared_sources)',b'family_texture_size(texture, declared_sources, binding.get("atlas_textures", {}))')
adapter=N/'terminal_adapter05_estate_atlases.gd';write(adapter,newcode)
worker0=N/'terminal_family_cold_worker_NOTREADY.gd';wb=worker0.read_bytes();assert sha(wb)=='61ad9cb09643af24081354644dea1a763d382354a62f6286b5e44b4ac7771324'
worker=N/'terminal_estate_atlas_worker_ROOT_READY01.gd';worker_sha=write(worker,wb.replace(b'terminal_adapter04_family.gd',b'terminal_adapter05_estate_atlases.gd'))
modules=d['module_sources'];modules.pop(res(adapter0));modules[res(adapter)]=sha(newcode);modules.pop(res(worker0));modules[res(worker)]=worker_sha
d['bindings']=[binding];d['terminal_sources']={logical:d['terminal_sources'][logical]};d['root_authorized']=True;d['status']='ESTATE_ONLY_FIXED_14_ATLAS_DESCRIPTORS_ROOT_COMPILE_CANDIDATE';d['output_root']=res(N/'terminal_family_residual_output')
d['inherited_components']={'Temple':'118568 complete terminal; never reprojected here','Estate':'native/parent source shape-prefix evidence preserved from 118568; not whole PASS'}
inp=N/'terminal_estate_atlas_input_ROOT_READY01.json';data=(json.dumps(d,ensure_ascii=False,indent=2)+'\n').encode();input_sha=write(inp,data)
boot=(N/'terminal_family_cold_bootstrap02_NOTREADY.gd').read_text(encoding='utf8').replace('terminal_family_cold_input02_NOTREADY.json',inp.name).replace(sha(before),input_sha).replace(worker0.name,worker.name).replace(sha(wb),worker_sha)
bp=N/'terminal_estate_atlas_bootstrap_ROOT_READY01.gd';write(bp,boot.encode())
assert newcode.replace(b'family_texture_size(texture, declared_sources, binding.get("atlas_textures", {}))',b'family_texture_size(texture, declared_sources)').replace(replacement,old_function)==code
print(json.dumps({'input_sha256':input_sha,'worker_sha256':worker_sha,'bootstrap_sha256':sha(bp.read_bytes()),'adapter_sha256':sha(newcode),'atlas_count':len(descriptors),'original_false':8,'original_true':6,'all_margin_zero':True,'whole_inverse':True}))
