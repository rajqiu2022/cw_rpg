"""NEW QA-only source-arithmetic successor; never parses/runs Godot."""
import hashlib
import json
import struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OLD=ROOT/'tests/test_luoyang_ap_yamen_three_low_props_SOURCE_PENDING_20261023.gd'
NEW=ROOT/'tests/test_luoyang_ap_yamen_three_low_props_SOURCE_SCALE_PENDING_20261023.gd'
OUT=Path(__file__).with_name('yamen_source_native_scale_successor_NOTREADY.json')
def sha(b):return hashlib.sha256(b).hexdigest()
def f32(x):return struct.unpack('<f',struct.pack('<f',x))[0]
raw=OLD.read_bytes()
assert sha(raw)=='e0495e4b9409ea8c3f13bd083c36d0eeeb6ba0b768fecc42e010d1593d17ae223'
before=b'sprite.scale == Vector2.ONE * .12'
after=b'sprite.scale == _point(row.native_scale)'
assert raw.count(before)==1 and after not in raw
new=raw.replace(before,after)
assert new.replace(after,before)==raw
assert not NEW.exists() and not OUT.exists()
scale=[f32(f32(dim*.12)/dim) for dim in [1536,1024]]
assert scale==[0.12000000476837158,0.11999999731779099]
assert scale[0]!=f32(.12) and scale[1]==f32(.12)
result={
 'status':'SOURCE_ARITHMETIC_QA_SUCCESSOR_NOTREADY_NOT_ACTUAL',
 'original_script':{'path':'res://'+OLD.relative_to(ROOT).as_posix(),'sha256':sha(raw)},
 'new_script':{'path':'res://'+NEW.relative_to(ROOT).as_posix(),'sha256':sha(new)},
 'exact_single_replacement':{'old':before.decode(),'new':after.decode()},
 'whole_byte_inverse':True,
 'source_formula':'Publisher source uniform scalar .12 produces Vector2(1536,1024)*.12 with f32 components; Field divides those stored components by each complete source texture dimension and stores Sprite2D.scale as Vector2 f32.',
 'required_native_scale_fixture':scale,
 'original_uniform_source_scale':.12,
 'does_not_admit_nonuniform_author_scale_or_epsilon':True,
 'unchanged':'Default entry/three negative controls/seven finite INPUT paths/actor-local assertions/60s/0.3px/sources/saves/timing/<=2pictures are byte-identical.',
 'final_owner_ready':False,'engines':0,'parses':0,'canonical_writes':0
}
NEW.write_bytes(new)
OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'script_sha256':sha(new),'proof_sha256':sha(OUT.read_bytes()),'ready':False}))
