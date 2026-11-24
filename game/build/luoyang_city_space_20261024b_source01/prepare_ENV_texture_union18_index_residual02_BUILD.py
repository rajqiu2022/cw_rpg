"""Sole six index disabled intermediates and receipt label; no Stage import/run."""
from pathlib import Path
import json,hashlib,copy
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return b
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def out(name,b):
    with (HERE/name).open('xb') as f:f.write(b)
    assert (HERE/name).read_bytes()==b
    return dict(path=S+name,sha256=sha(b),bytes=len(b))
dp=S+'stage_ENV_texture_union18_ROOT_READY.py';dh='1afbb7ab2264f6d4aac7806d2b3385f7084143fc244fc88e28f45146a7bba06a';d=read(dp,dh)
a=b"status='ENV_TEXTURE_UNION_EXACT18_STAGED_NOT_DEPLOYED'";b=b"status='MARKET_DIALOGUE_EXACT18_STAGED_NOT_DEPLOYED'";assert d.count(a)==1
newd=d.replace(a,b,1);assert newd.replace(b,a,1)==d;compile(newd,'stage_ENV_texture_union18_residual02_ROOT_READY.py','exec')
dr=out('stage_ENV_texture_union18_residual02_ROOT_READY.py',newd)
ip=S+'source_input_ENV_texture_union18_ROOT_READY.json';ih='08aee7302473f39dd4e23a6c0796d1efc82400d1a4605206332a3318cc1a4e71';old=json.loads(read(ip,ih));v=copy.deepcopy(old);changes=[]
pins={r['id']:r for r in old['pinned_inputs']}
for i,n in enumerate(v['nodes']):
    if n['kind']!='index':continue
    pin=pins[n['base_input']];base=read(pin['path'],pin['sha256']).decode('utf8')
    on,off=n['enabled_literal'],n['disabled_literal'];assert base.count(on)==1 and off not in base and off.count('false')==1 and off.replace('false','true')==on
    assert not any(h['old']==on for h in n['replacements'])
    n['replacements'].append(dict(old=on,new=off));changes.append(dict(pointer=['nodes',i,'replacements'],id=n['id'],added=dict(old=on,new=off),physical_current_enabled_unique=True))
assert len(changes)==6
v['required_generator']=dict(path=dr['path'],sha256=dr['sha256']);v['output_root']=S+'outputs/root_ENV_texture_union_exact18_stage02/'
inverse=copy.deepcopy(v)
for c in changes:
    h=inverse['nodes'][c['pointer'][1]]['replacements'];assert h[-1]==c['added'];h.pop()
for k in ['required_generator','output_root']:inverse[k]=copy.deepcopy(old[k])
assert inverse==old and enc(inverse)==read(ip,ih)
ir=out('source_input_ENV_texture_union18_residual02_ROOT_READY.json',enc(v))
pr=out('ENV_texture_union18_index_residual02_inverse_BUILD.json',enc(dict(status='INDEX_SOLE_DISABLED_BOOL_RESIDUAL_BUILD_NOT_EXECUTED',parent_driver=dict(path=dp,sha256=dh),driver=dr,driver_single_literal=dict(old=a.decode(),new=b.decode()),driver_whole_byte_inverse=True,parent_input=dict(path=ip,sha256=ih),input=ir,index_deltas=changes,input_other_changed_fields=['required_generator','output_root'],input_whole_typed_and_serialized_inverse=True,core8DE0_unchanged=True,old_actual_FAIL_preserved=True,Stage_calls=0,engine_calls=0,canonical_writes=0)))
print(json.dumps(dict(driver=dr,input=ir,proof=pr,index_bool_intermediates=6)))
