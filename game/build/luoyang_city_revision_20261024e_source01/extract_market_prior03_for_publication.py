"""Root actual CPU prior -> exact five-field source input; no engine."""
from pathlib import Path
import copy,hashlib,json
B=Path(__file__).resolve().parent
G=B.parents[1];SYS=G/'build/luoyang_city_blocks_20261024e_system01'
RESULT=B/'market_prior03_READY/output/result.json'
OUT=B/'market_prior03_admitted_source01'
def sha(raw):return hashlib.sha256(raw).hexdigest()
def read(path):
    raw=path.read_bytes();return raw,json.loads(raw)
def put(name,value):
    path=OUT/name;assert not path.exists();path.parent.mkdir(parents=True,exist_ok=True)
    raw=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode('utf8');path.write_bytes(raw)
    return dict(path=path.as_posix(),sha256=sha(raw),bytes=len(raw))
raw,actual=read(RESULT)
assert actual['passed'] is actual['complete'] is True and actual['failures']==0 and actual['checks']==1146
assert actual['PNG_decodes']==2 and actual['packet_decodes']==actual['PNG_outputs']==0
assert actual['source_first']==actual['source_final'] and actual['save_first']==actual['save_final']
p=actual['prior']
assert p['ready'] is True and p['parent_RGBA_sha256']=='2042da8017350c45ce4c6de5002931324c2bd62a024315c0ec3173f9c57242a8'
assert p['expected_child_RGBA_sha256']=='b6d6d0af0e2e03a7588a2f3561fd6c9aa4f821fe31265338ee79f0463305cb06'
assert (p['changed_pixels'],p['union_visited_pixels'],p['merged_domain_count'],p['local_parent_differences'])==(590860,1000516,27,0)
assert p['full_RGBA_inverse'] is True
fields=['ready','parent_RGBA_sha256','expected_child_RGBA_sha256','changed_pixels','union_visited_pixels']
prior={key:p[key] for key in fields}
priorref=put('independent_pixel_prior_READY_NOT_RUNTIME.json',prior)
a4raw,a4=read(SYS/'author_market_block04_NOTREADY.json')
a5raw,a5=read(SYS/'author_market_block05_NOTREADY.json')
assert sha(a4raw)=='697397f26fdf0b8c83d1cabbacd4c2a12ff235f455ae07b95522f2c01c5df318'
assert sha(a5raw)=='2c66f8988aee8255103fd0d223924e307f802529995b89135ad1fd7f3d9abad9'
inverse=copy.deepcopy(a5)
removed=inverse['npc_migrations'].pop()
assert removed['id']=='market_broker' and removed['old_foot_px']==[2060,1740] and removed['foot_px']==[2290,1660] and removed['distance_px']==65
note=inverse['runtime_input_freeze'].pop('author_successor')
assert inverse==a4 and (json.dumps(inverse,ensure_ascii=False,indent=2)+'\n').encode('utf8')==a4raw
forward=copy.deepcopy(a4);forward['npc_migrations'].append(removed);forward['runtime_input_freeze']['author_successor']=note
assert forward==a5 and (json.dumps(forward,ensure_ascii=False,indent=2)+'\n').encode('utf8')==a5raw
proof=put('actual_prior_and_author05_inheritance_READY_NOT_RUNTIME.json',dict(
 status='INDEPENDENT_PIXEL_PRIOR_ACTUAL_AND_NPC_ONLY_SOURCE_INHERITANCE_NOT_RUNTIME',passed=True,
 actual=dict(path=RESULT.as_posix(),sha256=sha(raw),checks=1146,failures=0,elapsed_ms=actual['elapsed_ms']),
 prior=priorref,extraction_fields=fields,wholetyped_projection_equal={key:prior[key]==p[key] for key in fields},
 publisher_input_contract='independent_prior.path/sha256 must pin this exact five-field doc; no future publisher actual used as expected',
 author04=dict(path=(SYS/'author_market_block04_NOTREADY.json').as_posix(),sha256=sha(a4raw)),
 author05=dict(path=(SYS/'author_market_block05_NOTREADY.json').as_posix(),sha256=sha(a5raw)),
 forward_inverse_whole_typed_and_UTF8_bytes=True,author05_changes=[dict(pointer=['npc_migrations',6],new=removed),dict(pointer=['runtime_input_freeze','author_successor'],new=note)],
 identical_geometry_and_visual_source_fields=True,prior04_inherited_no_second_PIP=True,
 preserved=dict(original01_parseFAIL=True,original02_domainFAIL=True,PNG_decodes_by_Source=0,engine_by_Source=0,packet_decodes=0,formal_writes=0),
 acceptance_scope='Pixel prior only. Broker05 NPC movement is not raster geometry and retains65 distance; publisher must audit final NPC/routes. No Field/Physics/ART/fullcity success.'))
print(json.dumps(dict(prior=priorref,proof=proof,result_sha256=sha(raw))))
