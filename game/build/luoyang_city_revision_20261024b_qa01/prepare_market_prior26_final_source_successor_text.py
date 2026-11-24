"""NEW false fixture/key source-pin successor only; no raster/model replay."""
from pathlib import Path
import hashlib,json,copy,difflib
Q=Path(__file__).resolve().parent;GAME=Q.parent.parent
SRC=GAME/'build/luoyang_city_space_20261024b_source01'
old=Q/'market_mask_prior26_NOTREADY';new=Q/'market_mask_prior26_final_source_NOTREADY'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p,h): assert sha(p)==h;return json.loads(p.read_bytes())
def emit(p,v):
    assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    p.write_bytes((json.dumps(v,ensure_ascii=True,indent=2)+'\n').encode('ascii'))
    return sha(p)
oa=SRC/'author_space_delta_rect_domains_successor01_NOTREADY.json'
na=SRC/'author_space_delta_threshold_return_successor02_NOTREADY.json'
oi=SRC/'publication_input_rect_domains_successor01_NOTREADY.json'
ni=SRC/'publication_input_threshold_return_successor02_NOTREADY.json'
a=read(oa,'462e0578dbc701e0d10be721773b6986c61c5c46561e4f0842d440b1e7d15a70')
b=read(na,'28b2f8126417d0d4af4c804702652347bbc7ed9cdd5f20d2fe6a8401fa54813d')
inp=read(ni,'3933bd579cb6ec98e540c914d3bd9248d0b32580ff7f101721a1c5ee729583a8')
same_fields=['assets','complete_buildings','native_object_moves','retire_closed_stall_ids','low_wall_asset','low_wall_components','changed_mask_domains_closed','runtime_district','district_assets','district_current_frozen']
assert all(a[k]==b[k] for k in same_fields)
assert inp['pixel_visit_budget']==147805
fx=read(old/'fixture_NOTREADY.json','c399b173825456fedb677c41c6b9a63bc4289eb0cfb4369f84ba9b58f0ec1b60')
original=copy.deepcopy(fx)
oldgeom=SRC/'market_replan_geometry_CANDIDATE.gd'
newgeom=SRC/'market_replan_geometry_threshold_return_successor02_CANDIDATE.gd'
assert sha(newgeom)=='56d87b7ae25cf37902718819c5daa4f3b61863ddd89513e8fb9e9be892b72584'
new.mkdir(parents=True,exist_ok=True)
project=new/'project.godot';assert not project.exists();project.write_bytes((old/'project.godot').read_bytes())
for prior,current in [(oa,na),(oi,ni),(oldgeom,newgeom),(old/'project.godot',project)]:
    assert fx['source_sha256'].pop(prior.as_posix())==sha(prior)
    fx['source_sha256'][current.as_posix()]=sha(current)
fx['author_absolute_path']=na.as_posix()
fx['status']='INDEPENDENT26_DOMAIN_FINAL_THRESHOLD_RETURN_SOURCE_ORACLE_NOTREADY'
fx['blockers']=['Root must read/approve one bounded no-autoload oracle; current author28B2/input3933 source pins fixed. No agent has run it. Native PIP childRGBA/count remain unknown until old-local0diff proof.']
fxsha=emit(new/'fixture_NOTREADY.json',fx)
restored=copy.deepcopy(fx)
for prior,current in reversed([(oa,na),(oi,ni),(oldgeom,newgeom),(old/'project.godot',project)]):
    assert restored['source_sha256'].pop(current.as_posix())==sha(current)
    restored['source_sha256'][prior.as_posix()]=sha(prior)
for k in ['status','blockers','author_absolute_path']: restored[k]=original[k]
assert restored==original
okey=old/'oracle_NOTREADY.gd'
assert sha(okey)=='2c90445bf7a67584999fe548233f364c4278c7ef4e2f2b480f2e930630dbfd5e'
source=okey.read_bytes()
ops=[((old/'fixture_NOTREADY.json').as_posix().encode(),(new/'fixture_NOTREADY.json').as_posix().encode()),(sha(old/'fixture_NOTREADY.json').encode(),fxsha.encode()),((old/'output_NOTREADY').as_posix().encode(),(new/'output_NOTREADY').as_posix().encode())]
for before,after in ops: assert source.count(before)==1;source=source.replace(before,after,1)
inverse=source
for before,after in reversed(ops): assert inverse.count(after)==1;inverse=inverse.replace(after,before,1)
assert inverse==okey.read_bytes()
key=new/'oracle_NOTREADY.gd';assert not key.exists();key.write_bytes(source)
diff=new/'complete_vs_prior_source_NOTREADY.diff';diff.write_bytes(''.join(difflib.unified_diff(okey.read_text().splitlines(True),source.decode().splitlines(True),fromfile=str(okey),tofile=str(key))).encode())
proof={'status':'FINAL_SOURCE_PINS_ONLY_HARDFALSE_NOTRUN','key_sha256':sha(key),'fixture_sha256':fxsha,'project_sha256':sha(project),'source_author':sha(na),'source_input':sha(ni),'source_geometry_provenance_only_not_executed':sha(newgeom),'same_pixel_source_fields_wholetyped':same_fields,'independent_f32_model_unchanged':fx['source_sha256'][fx['independent_f32_model_absolute_path']],'26closed_domains_union':147805,'key_exact3literal_wholebyte_inverse':True,'fixture_only4smallsource_leaf_pathSHA_replacements_status_blockers_authorpath':True,'no_native_math_PIP_PNG_or_engine_run':True,'source_guard_count':len(fx['source_sha256']),'limits':'30s fixed no-autoload/4PNGreads/noPNGoutput/zero81E9packetdecode/5newplinthalpha+negative,2door,4threshold-return localbody controls, no oldroute/fullraster or runtimecredit','prior_RGBA_and_changed':'UNKNOWN until Root executes once; no futurepublisher output consulted','next':'ROOT reads complete key then may mechanicalfreeze bool/path/fixtureSHA/output and readiness only; QA never launches.'}
proofsha=emit(new/'source_successor_whole_inverse_NOTREADY.json',proof)
print('KEY',sha(key),'FIXTURE',fxsha,'PROJECT',sha(project),'PROOF',proofsha)
