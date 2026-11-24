from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
p=N/'temple_native_builder01_NOTREADY.gd';raw=p.read_bytes();assert hashlib.sha256(raw).hexdigest()=='dd1eb1dd573c01be8a1147c449abd809cd5b6be2bdf6a69dcf8bc512ed41396e'
old=raw.decode('utf8')
a='\t\tvar points: PackedVector2Array=polygon(base.ground_polygon_px,Vector2.ONE/SIZE)\n'
b='\t\tvar points: PackedVector2Array=polygon(base.ground_polygon_px)\n\t\tfor i: int in range(points.size()): points[i]=points[i]/SIZE\n'
assert old.count(a)==1
text=old.replace(a,b);out=N/'temple_native_builder02_direct_UV_NOTREADY.gd';data=text.encode('utf8')
with out.open('xb') as stream:stream.write(data)
assert text.replace(b,a)==old
print(json.dumps({'path':'res://build/luoyang_city_finish_20261025i_source01/'+out.name,'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'parent_sha256':hashlib.sha256(raw).hexdigest(),'one_hunk_full_byte_inverse':True,'exact_source_contract':'UV=Vector2(sourcePoint)/SIZE, not multiplication by rounded Vector2.ONE/SIZE; final world=UV*Vector2(1920,1280)'}))
