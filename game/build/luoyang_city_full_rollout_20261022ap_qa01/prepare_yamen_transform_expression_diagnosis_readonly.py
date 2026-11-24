"""Pure source expressions and competing numeric models; not runtime truth."""
import hashlib,json,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).resolve().parent
P=QA/'wall_yamen_independent_recipe07_BOUND05_SOURCE_FROZEN_RETRY1_NOT_ACTUAL.json'
ORACLE=ROOT/'tests/helpers/yamen_low_props_source_expression_oracle_PREPARATION_ONLY_20261023.gd'
OUT=QA/'yamen_transform_source_expression_diagnosis_PREPARATION_ONLY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def f(x):return struct.unpack('<f',struct.pack('<f',x))[0]
assert sha(P)=='448c148ed5a15aaf4b1acbf6472afd6f94fe1ea2bdb654717dd59a5a56b4f947'
rows=json.loads(P.read_bytes())['Yamen']['independent_new_visuals']
fixture=json.loads((QA/'yamen_three_low_props_classification_fixture_READY.json').read_bytes())
models=[]
for row in rows:
    full=row['full_source_size_px']
    a=[f(d*.12) for d in full];b=[f(d*f(.12)) for d in full]
    sa=[f(a[i]/full[i]) for i in range(2)];sb=[f(b[i]/full[i]) for i in range(2)]
    current=next(x for x in fixture['props'] if x['id']==row['id'])
    assert current['native_scale']==sa
    models.append({'id':row['id'],'source_texture':row['texture'],'source_size':full,'source_anchor':row['source_ground_anchor_px'],'source_foot':row['foot_px'],'source_uniform_scalar':.12,'current_Python_double_scalar_model':{'render_size':a,'scale':sa},'alternative_scalar_converted_to_real_t_first_model':{'render_size':b,'scale':sb},'not_observed_sprite_values':True})
assert not OUT.exists()
v={'status':'SOURCE_EXPRESSION_DIAGNOSIS_PREPARATION_ONLY_NOT_PROVEN_RUNTIME_CAUSE','fixed_author_source':{'path':'res://'+P.relative_to(ROOT).as_posix(),'sha256':sha(P)},'oracle_candidate':{'path':'res://'+ORACLE.relative_to(ROOT).as_posix(),'sha256':sha(ORACLE)},'models':models,'fixed_source_chain':{'publisher':'add_prop Vector2(source_size)*float(uniform_scale); render_entry (foot+(.5-foot_uv)*render_size)/SIZE','Field':'_norm_to_screen constructs Vector2(v.x*_screen_size.x,v.y*_screen_size.y); Sprite2D.scale constructs Vector2(render_size.x/texture_width,render_size.y/texture_height)'},'diagnosis_boundary':'Original aggregate assertion recorded no live texture/size/scale/position. The competing scalar model explains a possible x-scale mismatch, but cannot prove which aggregate clause failed. No actual value is used to form expected.','proposed_next_assertion_design':'Evaluate this pure native Vector2 expected expression from frozen448C author in the next separately approved remaining key; record all live actual and independent expected fields before separate exact clauses. No epsilon, no producer API, no visual/source geometry mutation.','Root_OS_exit_code_boundary':{'Yamen113324':None,'A1_114648':None,'reason':'Root did not retain Process.ExitCode; own processes ended. Result.complete/failed is not an OS code.'},'old_whole_FAIL_preserved':True,'engine_runs':0,'parse_runs':0,'collector_calls':0,'native_or_PNG_decode':0,'canonical_writes':0}
OUT.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'diagnosis_sha256':sha(OUT),'oracle_sha256':sha(ORACLE),'engine_runs':0}))
