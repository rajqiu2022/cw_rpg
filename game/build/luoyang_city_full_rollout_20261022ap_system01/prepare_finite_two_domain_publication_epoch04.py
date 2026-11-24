"""NEW precise oracle-order successor, no execution. Preserve unexecuted03."""
from pathlib import Path
import copy, hashlib, json
ROOT=Path(__file__).resolve().parent
GAME=ROOT.parent.parent
OLD=ROOT/'finite_two_domain_publication_epoch03'
NEW=ROOT/'finite_two_domain_publication_epoch04'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def pin(p): return {'path':'res://'+p.relative_to(GAME).as_posix(),'sha256':sha(p),'bytes':p.stat().st_size}
def write(p,value):
    assert not p.exists()
    p.write_bytes((json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    return pin(p)
assert sha(OLD/'input_READY.json')=='044d933bba30484de5b82c083a7e3ed487a33a977945c04e990912b0430904db'
assert sha(OLD/'publisher_READY.gd')=='55b9c28203079a8943612df6a8076b45e7d0f5e335515dcdb49da30510591615'
NEW.mkdir(exist_ok=False)
data=json.loads((OLD/'input_READY.json').read_text(encoding='utf-8'))
parent=copy.deepcopy(data)
data['output_prefix']=data['output_prefix'].replace('epoch03/','epoch04/')
assert not (NEW/'output').exists()
assert dict(data,output_prefix=parent['output_prefix'])==parent
input_pin=write(NEW/'input_READY.json',data)
before=(OLD/'publisher_template_NOTEXEC.gd').read_bytes()
text=before.decode('utf-8')
assert text.count('finite_two_domain_publication_epoch03')==2
text=text.replace('finite_two_domain_publication_epoch03','finite_two_domain_publication_epoch04')
anchor='func parent_native(spec: Dictionary) -> Dictionary:'
added='''func exact_polygon_multiset(actual: Array[PackedVector2Array],expected: Array[PackedVector2Array]) -> bool:
	# Independent source oracle order need not equal original object ordinal.
	# Every complete typed polygon must match exactly, once; no epsilon/reorder
	# inside a polygon, no count loss, no current-data expected reconstruction.
	if actual.size()!=expected.size(): return false
	var used: Array[bool]=[]
	for index: int in expected.size(): used.append(false)
	for poly: PackedVector2Array in actual:
		var match_index: int=-1
		for index: int in expected.size():
			if not used[index] and api.equal(poly,expected[index]): match_index=index;break
		if match_index<0: return false
		used[match_index]=true
	return true
'''
assert text.count(anchor)==1
text=text.replace(anchor,added+anchor)
old='api.equal(native_solids(data.record),data.solids) and api.equal(data.solids,expected_native)'
new='api.equal(native_solids(data.record),data.solids) and exact_polygon_multiset(data.solids,expected_native)'
assert text.count(old)==1
text=text.replace(old,new)
inverse=text.replace(new,old,1).replace(added,'',1).replace('finite_two_domain_publication_epoch04','finite_two_domain_publication_epoch03')
assert inverse.encode('utf-8')==before
template=NEW/'publisher_template_NOTEXEC.gd'
template.write_bytes(text.encode('utf-8'))
ready_text=text.replace('const READY=false','const READY=true',1).replace('@INPUT_SHA@',input_pin['sha256'],1)
ready=NEW/'publisher_READY.gd'
ready.write_bytes(ready_text.encode('utf-8'))
assert ready.read_bytes().replace(b'const READY=true',b'const READY=false',1).replace(input_pin['sha256'].encode(),b'@INPUT_SHA@',1)==template.read_bytes()
handoff=json.loads((OLD/'handoff_READY.json').read_text(encoding='utf-8'))
handoff.update({'publisher':pin(ready),'input':input_pin,'template':pin(template),'preparation_builder':pin(Path(__file__)),
    'supersedes_unexecuted03_handoff':pin(OLD/'handoff_READY.json'),
    'exact_template_whole_byte_inverse_to03':True,
    'only_behavioral_delta':'Independent31/29native polygon oracle order uses exact one-to-one multiset. Original packet.solids still must exactly equal record-native order. No per-polygon vertex/order/type tolerance or numeric epsilon.',
    'input_delta_from03':'Only absentNEW04 output_prefix; all46 fixed sources/Root9AACE/D917 metadata, geometry,author,routepoints unchanged.',
    'mechanical_template_changes':['READYfalse->true','One INPUT_SHA token, exact byte inverse'],
    'ready_template_exact_whole_byte_inverse':True})
out=write(NEW/'handoff_READY.json',handoff)
print(json.dumps(out))
