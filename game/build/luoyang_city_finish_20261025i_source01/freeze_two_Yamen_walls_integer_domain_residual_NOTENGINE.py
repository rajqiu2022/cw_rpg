"""Root-approved scalar exactness fix, same fixed geometry and source guards."""
from pathlib import Path
import json,hashlib,copy
N=Path(__file__).resolve().parent;G=N.parents[1]
OLD=N/'street_edges_yamen02_local02_ROOT_READY';NEW=N/'street_edges_yamen02_local03_ROOT_READY'
assert not NEW.exists(),'NEW output only'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,w):
    b=p.read_bytes();assert sha(b)==w;return b
def pin(p,b):return {'path':'res://'+str(p.relative_to(G)).replace('\\','/'),'sha256':sha(b),'bytes':len(b)}
original=read(OLD/'check_two_yamen_walls_ROOT_READY.gd','e4977311c9f0d1d06641eb4ee514772f3c42dd782b45223235401b32b42f6b11')
old_input_raw=read(OLD/'input_ROOT_READY.json','b628059d455ea3c949b6dcc792e97d749e2e0e107ae257e3b583d5d57e6bf9bf')
project=read(OLD/'project.godot','a8e6c30c399665b4eebb42b989903f0fd5d688789da138a6ef7a8123907f028a')
old='''			var model: Dictionary=derived[String(lot.lot_id)];var domain: Array=lot.closed_domain_xyxy;var actual_bounds: Array=model.bounds
			if not check(domain==[ceili(actual_bounds[0]),ceili(actual_bounds[1]),floori(actual_bounds[2]),floori(actual_bounds[3])],"EXACT_CLOSED_NEW_DOMAIN:"+String(lot.lot_id)): finish({});return
'''
new='''			var model: Dictionary=derived[String(lot.lot_id)];var raw_domain: Array=lot.closed_domain_xyxy;var actual_bounds: Array=model.bounds
			var exact_domain: Array[int]=[ceili(actual_bounds[0]),ceili(actual_bounds[1]),floori(actual_bounds[2]),floori(actual_bounds[3])];var domain: Array[int]=[]
			if not check(raw_domain.size()==4,"EXACT_CLOSED_DOMAIN_FOUR_SCALARS:"+String(lot.lot_id)): finish({});return
			for domain_scalar: int in range(4):
				var declared_coordinate: float=float(raw_domain[domain_scalar])
				if not check(is_finite(declared_coordinate) and declared_coordinate==floor(declared_coordinate) and declared_coordinate==float(exact_domain[domain_scalar]),"EXACT_CLOSED_NEW_DOMAIN_INTEGER_SCALAR:"+String(lot.lot_id)+":"+str(domain_scalar)): finish({});return
				domain.append(int(declared_coordinate))
'''
text=original.decode('utf8');assert text.count(old)==1;text=text.replace(old,new)
cfg=json.loads(old_input_raw);new_cfg=copy.deepcopy(cfg)
new_cfg['output_root']=cfg['output_root'].replace('street_edges_yamen02_local02_ROOT_READY','street_edges_yamen02_local03_ROOT_READY')
input_raw=(json.dumps(new_cfg,ensure_ascii=False,indent=2)+'\n').encode('utf8')
mechanical=[('street_edges_yamen02_local02_ROOT_READY','street_edges_yamen02_local03_ROOT_READY'),('b628059d455ea3c949b6dcc792e97d749e2e0e107ae257e3b583d5d57e6bf9bf',sha(input_raw))]
for before,after in mechanical:assert before in text;text=text.replace(before,after)
undo=text
for before,after in reversed(mechanical):assert after in undo;undo=undo.replace(after,before)
assert undo.count(new)==1;undo=undo.replace(new,old);assert undo.encode()==original
restored_cfg=copy.deepcopy(new_cfg);restored_cfg['output_root']=cfg['output_root'];assert restored_cfg==cfg
assert (json.dumps(restored_cfg,ensure_ascii=False,indent=2)+'\n').encode()==old_input_raw
NEW.mkdir()
def write(name,b):
    if not isinstance(b,bytes):b=(json.dumps(b,ensure_ascii=False,indent=2)+'\n').encode('utf8')
    with (NEW/name).open('xb')as f:f.write(b)
    return pin(NEW/name,b)
sp=write('check_two_yamen_walls_ROOT_READY.gd',text.encode());ip=write('input_ROOT_READY.json',input_raw);pp=write('project.godot',project)
proof={'status':'ROOT_APPROVED_ONLY_JSON_INTEGER_DOMAIN_SCALARS_SOURCE_FIX_NOT_EXECUTED','parent':pin(OLD/'check_two_yamen_walls_ROOT_READY.gd',original),'candidate':sp,'one_functional_hunk':{'old':old,'new':new},'mechanical_path_inputSHA':mechanical,'whole_script_byte_inverse':True,'whole_input_byte_inverse':True,'input_only_output_root_changed':True,'author8C9D_and_shape_sourceguard_all_identical':True,'no_epsilon_or_coordinate_or_scale_change':True,'old_failure_kept':{'process':39680,'result_sha256':'f4dc78398c7ec833c62c92944a675d14ad837d43997656917eb8cbda8f83f74e','checks':170,'pixel_queries':0,'child_output_count':0},'original_all_A1_routes_NPCs_portals_strips_and_solids_component_credit_retained':True,'no_old_global_geometry_or_full_mask_raster':True,'engine_calls':0,'canonical_writes':0}
pr=write('integer_domain_single_hunk_whole_inverse_READY.json',proof)
handoff={'status':'ROOT_READY_TWO_YAMEN_DOMAIN_INTEGER_RESIDUAL_NOT_EXECUTED','script':sp,'input':ip,'project':pp,'proof':pr,'script_respath':'res://check_two_yamen_walls_ROOT_READY.gd','Root_only_run':True,'new_domain_pixel_queries_limit':5606,'only_named_Yamen_two_polygons':True}
print(json.dumps(write('handoff_ROOT_READY.json',handoff),ensure_ascii=False))
