"""Only exact Estate registry-shadow transport and NEW failed-epoch successor."""
from pathlib import Path
import json
import hashlib
import difflib

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[2]
S='res://build/luoyang_city_space_20261024b_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(name):return (HERE/name).read_bytes()
def encode(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def output(name,b):
    with (HERE/name).open('xb') as stream:stream.write(b)
    return dict(path=S+name,sha256=sha(b),bytes=len(b))
old_driver=read('stage_market_dialogue36_NOTREADY.py')
assert sha(old_driver)=='e3031fb4a2d8c79b0c9b6fbe6305b38ebb3b5d25f9c41e1ff3cc40b1bddf6b81'
driver=read('stage_market_dialogue36_estate_registry02_NOTREADY.py')
compile(driver,'finite_estate_registry_residual02','exec')
changes=[]
a,b=old_driver.decode('utf8').splitlines(keepends=True),driver.decode('utf8').splitlines(keepends=True)
for group in difflib.SequenceMatcher(None,a,b,autojunk=False).get_grouped_opcodes(3):
    changes.append(dict(old=''.join(a[group[0][1]:group[-1][2]]),new=''.join(b[group[0][3]:group[-1][4]])))
forward,inverse=old_driver.decode('utf8'),driver.decode('utf8')
for h in changes:
    assert forward.count(h['old'])==inverse.count(h['new'])==1
    forward=forward.replace(h['old'],h['new'],1);inverse=inverse.replace(h['new'],h['old'],1)
assert forward.encode('utf8')==driver and inverse.encode('utf8')==old_driver
oldinput=read('source_input36_ROOT_READY.json')
assert sha(oldinput)=='2120cd6fea46caf9e3bfd81f0bf21ed803cc36e360d0d68763833d461af0f43b'
value=json.loads(oldinput);old=json.loads(oldinput)
value['required_generator']=dict(path=S+'stage_market_dialogue36_estate_registry02_NOTREADY.py',sha256=sha(driver))
value['output_root']=S+'outputs/root_market_dialogue_exact36_stage02/'
restored=json.loads(encode(value))
restored['required_generator']=old['required_generator'];restored['output_root']=old['output_root']
assert restored==old and encode(restored)==oldinput
out=output('source_input36_estate_registry02_ROOT_READY.json',encode(value))
proof=dict(status='ONLY_ESTATE_REGISTRY_SCALAR_PROTECTED_SHADOW_RESIDUAL_NOT_EXECUTED',
    driver=dict(parent=dict(path=S+'stage_market_dialogue36_NOTREADY.py',sha256=sha(old_driver)),candidate=dict(path=S+'stage_market_dialogue36_estate_registry02_NOTREADY.py',sha256=sha(driver),bytes=len(driver)),hunks=changes,wholebyte_forward_inverse=True),
    input=dict(parent=dict(path=S+'source_input36_ROOT_READY.json',sha256=sha(oldinput)),candidate=out,
               only_changed_fields=['required_generator','output_root'],ordered_typed_and_UTF8_inverse=True),
    original_E303_2120_and_Root_stage01_FAILURE_preserved=True,
    original_Estate_protected_pointers_all_preserved=True,
    registry_scalar_only_fixed_generated_header_then_full_original_inverse=True,
    no_other_nodes_groups_or_36_targets_changed=True,Stage_calls=0,engine_calls=0,canonical_writes=0)
p=output('estate_registry_residual02_complete_inverse_NOT_STAGE.json',encode(proof))
print(json.dumps(dict(driver=proof['driver']['candidate'],input=out,proof=p)))
