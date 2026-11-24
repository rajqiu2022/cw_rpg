"""Exact JSON integer-domain schema only; no geometry or expected-value edits."""
from pathlib import Path
import copy,hashlib,json
B=Path(__file__).resolve().parent;OLD=B/'market_prior02_READY';NEW=B/'market_prior03_READY'
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(name,h):
    raw=(OLD/name).read_bytes();assert sha(raw)==h;return raw
def put(name,raw):
    p=NEW/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
    return dict(path=p.as_posix(),sha256=sha(raw),bytes=len(raw))
of=fixed('fixture_READY.json','3a8a771001fc8fb2fa975f6b9e959536dcf5069ce13018251b2edd91ae0edfad')
f=json.loads(of);oldf=copy.deepcopy(f);f['output_path']=(NEW/'output/result.json').as_posix()
fixture=put('fixture_READY.json',(json.dumps(f,ensure_ascii=True,indent=2)+'\n').encode('ascii'))
inverse=copy.deepcopy(f);inverse['output_path']=oldf['output_path']
assert (json.dumps(inverse,ensure_ascii=True,indent=2)+'\n').encode('ascii')==of
old=fixed('oracle_READY.gd','102e6c7e318bcb78074063894be2f40a128fe45bbf198e5d26581d7c9613e92a')
anchor=b'func derive_domains(before: Array,after: Array,model: Dictionary) -> Array:\n'
helper='''func exact_integer_domain(actual: Rect2i,raw: Variant,label: String) -> bool:
	var values: Array=[actual.position.x,actual.position.y,actual.end.x,actual.end.y]
	if not raw is Array or raw.size()!=4:
		diagnostics.append({"domain_rejection":label,"actual":values,"expected":raw,"reason":"four-component JSON array required"})
		return false
	for i: int in range(4):
		var value: Variant=raw[i]
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or float(value)<-2147483648.0 or float(value)>2147483647.0 or float(value)!=float(int(value)) or int(value)!=values[i]:
			diagnostics.append({"domain_rejection":label,"component":i,"actual":values,"expected":raw,"native_type":typeof(values[i]),"JSON_type":typeof(value),"reason":"finite exact int32 scalar equality, no tolerance"})
			return false
	return true
'''.encode('utf8')
ops=[(anchor,helper+anchor),
 (b'if not check([r.position.x,r.position.y,r.end.x,r.end.y]==e,"Unmerged exact f32-domain:"+str(i)): return []',b'if not check(exact_integer_domain(r,e,"raw:"+str(i)),"Unmerged exact f32-domain:"+str(i)): return []'),
 (b'if not check([r.position.x,r.position.y,r.end.x,r.end.y]==e,"Exact merged closure:"+str(i)): return []',b'if not check(exact_integer_domain(r,e,"merged:"+str(i)),"Exact merged closure:"+str(i)): return []'),
 ((OLD/'fixture_READY.json').as_posix().encode(),fixture['path'].encode()),(sha(of).encode(),fixture['sha256'].encode())]
key=old
for a,b in ops:assert key.count(a)==1;key=key.replace(a,b,1)
back=key
for a,b in reversed(ops):assert back.count(b)==1;back=back.replace(b,a,1)
assert back==old
k=put('oracle_READY.gd',key);p=put('project.godot',(OLD/'project.godot').read_bytes())
model=json.loads((B/'market_prior01_NOTREADY/independent_f32_model_NOT_PIP.json').read_bytes())
assert model['raw_half_open_domains'][0]==[159,566,938,742]
# Native bits already passed02; this derives the first integer bounds solely
# from those fixed source points and exact integer arithmetic, not actual pixel.
points=model['before37'][0]['polygons'][0]
import math
low=[min(p[i] for p in points) for i in range(2)];high=[max(p[i] for p in points) for i in range(2)]
first=[math.floor(low[0])-1,math.floor(low[1])-1,math.ceil(high[0])+2,math.ceil(high[1])+2]
assert first==model['raw_half_open_domains'][0]
proof=put('integer_domain_whole_inverse_NOT_RUN.json',(json.dumps(dict(status='DOMAIN_JSON_INT32_SCHEMA_RESIDUAL_NOT_RUN',key=k,fixture=fixture,project=p,
 key_replacements=[dict(before=a.decode(),after=b.decode()) for a,b in ops],wholebyte_inverse=True,fixture_only_new_output=True,
 source_model_unchanged_sha256='9f5a7707f8c92e18b6cb3516dbf2dcc9c471811ec0a4134d456fd23ec341fda5',
 prior02_observed='1053checks/native25+37+43 bits passed; first raw-domain aggregate Array equality rejected; actual individual values/types were not recorded. Pixel/packet decode0.',
 first_domain_source_derivation=dict(minimum=low,maximum=high,expected=first,formula='floor(min)-1 to ceil(max)+2 half-open; integer width=ceil(max)-floor(min)+3'),
 evidence_boundary='Geometry and original integer formula imply the same domain0 as model; no observed individual-type claim. This successor explicitly validates JSON finite integral int32 and exact four component values; if any real math mismatch remains, it records actual/expected/types and refuses.',
 no_geometry_changes=True,no_domain_order_or_value_changes=True,no_epsilon=True,no_actual_expected_fill=True,raw_domains=62,merged_domains=27,union_visited_pixels=1000516,
 engine_calls=0),ensure_ascii=True,indent=2)+'\n').encode('ascii'))
print(json.dumps(dict(key=k,fixture=fixture,project=p,proof=proof)))
