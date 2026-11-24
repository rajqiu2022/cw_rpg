"""Root-authorized two-path resources-only append; existing thumbnail helper only."""
from pathlib import Path
from collections import Counter
import copy,hashlib,json,re,sys
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'scripts'))
import build_resource_gallery as gallery
HTML=ROOT/'docs/equipment-skill-catalog.html'
CACHE=ROOT/'docs/assets/resources/thumbnail-index.json'
REUSE=ROOT/'docs/resource-reuse-index.md'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def enc(v):return json.dumps(v,ensure_ascii=False,separators=(',',':'))
def dump(name,v):
 with (OUT/name).open('x',encoding='utf-8') as f:json.dump(v,f,ensure_ascii=False,indent=2);f.write('\n')
def parse(b):
 text=b.decode('utf-8');m=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
 assert m
 return text,m,json.loads(m[1])
def resource_span(raw):
 matches=list(re.finditer(r'"resources"\s*:\s*',raw));assert len(matches)==1
 start=matches[0].end();_,end=json.JSONDecoder().raw_decode(raw,start)
 return start,end
def member_spans(raw):
 decoder=json.JSONDecoder();i=1;spans={}
 while True:
  while raw[i].isspace() or raw[i]==',':i+=1
  if raw[i]=='}':return spans
  key,end=decoder.raw_decode(raw,i);i=end
  while raw[i].isspace():i+=1
  assert raw[i]==':';i+=1
  while raw[i].isspace():i+=1
  start=i;_,i=decoder.raw_decode(raw,i);spans[key]=(start,i)
plan=json.loads((OUT/'catalog2_plan_READY.json').read_bytes())
rows=json.loads((OUT/'catalog2_records_READY.json').read_bytes());assert len(rows)==2
before_html=HTML.read_bytes();before_cache=CACHE.read_bytes();before_reuse=REUSE.read_bytes()
for name,path in [('html',HTML),('cache',CACHE),('reuse',REUSE)]:assert sha(path)==plan['baseline'][name+'_sha256']
text,m,data=parse(before_html);old=copy.deepcopy(data);resources=data['resources']
assert len(resources['records'])==plan['baseline']['old_records']==5264
paths=[r['diskPath'] for r in rows];assert len(set(paths))==2
assert not set(paths)&{r['diskPath'] for r in resources['records']}
cache=json.loads(before_cache);updates={};assert not set(paths)&set(cache)
for path,digest in plan['protected_source_sha256'].items():assert sha(ROOT/path)==digest,path
scanner_before=sha(ROOT/'scripts/build_resource_gallery.py')
for row in rows:
 path=ROOT/row['diskPath'];assert sha(path)==row['sha256'] and path.stat().st_size==row['bytes']
 destination=ROOT/('docs/'+row['thumbnail'])
 assert not destination.exists(),'Refuse an existing thumbnail; keep any earlier attempt.'
 thumb,size=gallery.thumbnail(path,'map',cache,updates)
 assert thumb==row['thumbnail'] and size==row['size']
 with Image.open(destination) as image:
  assert image.width<=360 and image.height<=220
  image.verify()
 assert row['phase']!='raw_discarded' or (not row['usage'] and not row['currentConsumers'])
resources['records'].extend(rows)
for category in resources['categories']:category['count']=sum(r['category']==category['id'] for r in resources['records'])
resources['summary']={'total':len(resources['records']),'images':sum(r['media']=='image' for r in resources['records']),
 'audio':sum(r['media']=='audio' for r in resources['records']),'states':dict(Counter(r['status'] for r in resources['records']))}
assert resources['records'][:-2]==old['resources']['records']
assert {k:v for k,v in data.items() if k!='resources'}=={k:v for k,v in old.items() if k!='resources'}
start,end=resource_span(m[1]);old_resource_raw=m[1][start:end];spans=member_spans(old_resource_raw)
new_resource_raw=old_resource_raw
for key in sorted(['records','categories','summary'],key=lambda k:spans[k][0],reverse=True):
 a,b=spans[key]
 if key=='records':
  old_array=old_resource_raw[a:b];assert old_array.endswith(']')
  value=old_array[:-1]+','+','.join(enc(r) for r in rows)+']'
 else:value=enc(resources[key])
 new_resource_raw=new_resource_raw[:a]+value+new_resource_raw[b:]
new_raw=m[1][:start]+new_resource_raw+m[1][end:]
new_html=(text[:m.start(1)]+new_raw+text[m.end(1):]).encode('utf-8')
after_text,after_match,after_data=parse(new_html);assert after_data==data
a,b=resource_span(after_match[1])
assert text[:m.start(1)+start]+text[m.start(1)+end:]==after_text[:after_match.start(1)+a]+after_text[after_match.start(1)+b:]
new_spans=member_spans(new_resource_raw);x,y=new_spans['records'];old_x,old_y=spans['records']
assert new_resource_raw[x:y].startswith(old_resource_raw[old_x:old_y-1]+',')
assert len(updates)==2
cache_after={**cache,**updates};assert {k:v for k,v in cache_after.items() if k not in paths}==cache
cache_text=before_cache.decode().rstrip();assert cache_text.endswith('}')
new_cache=(cache_text[:-1].rstrip()+',\n'+',\n'.join('  '+json.dumps(k,ensure_ascii=False)+': '+json.dumps(v,ensure_ascii=False,indent=2).replace('\n','\n  ') for k,v in updates.items())+'\n}\n').encode()
assert json.loads(new_cache)==cache_after
increment=(OUT/'reuse_increment_READY.txt').read_bytes()
assert b'environment_residual_20261031d' not in before_reuse
separator=b'\r\n\r\n' if b'\r\n' in before_reuse else b'\n\n'
cut=before_reuse.index(separator)+len(separator)
if separator==b'\r\n\r\n':increment=increment.replace(b'\r\n',b'\n').replace(b'\n',b'\r\n')
new_reuse=before_reuse[:cut]+increment+before_reuse[cut:]
assert new_reuse[:cut]+new_reuse[cut+len(increment):]==before_reuse
for path,digest in plan['protected_source_sha256'].items():assert sha(ROOT/path)==digest,path
assert scanner_before==sha(ROOT/'scripts/build_resource_gallery.py')
assert HTML.read_bytes()==before_html and CACHE.read_bytes()==before_cache and REUSE.read_bytes()==before_reuse
for name,raw in [('catalog2_gallery_BEFORE.html',before_html),('catalog2_cache_BEFORE.json',before_cache),('catalog2_reuse_BEFORE.md',before_reuse)]:
 with (OUT/name).open('xb') as f:f.write(raw)
HTML.write_bytes(new_html);CACHE.write_bytes(new_cache);REUSE.write_bytes(new_reuse)
assert parse(HTML.read_bytes())[2]==after_data
assert json.loads(CACHE.read_bytes())==cache_after
proof={'status':'ROOT_AUTHORIZED_EXACT2_RESOURCES_APPEND_COMPLETE','before_records':5264,'after_records':5266,
 'new_raw_records':1,'new_adopted_game_records':1,
 'old_5264_records_semantically_and_serialized_prefix_exact':True,'nonresources_payload_and_HTML_outside_resources_exact':True,
 'old_cache_entries_exact':True,'new_thumbnails':2,'new_thumbnail_paths':['docs/'+r['thumbnail'] for r in rows],
 'reuse_only_new_section_original_bytes_reversible':True,'protected_source_sha256':plan['protected_source_sha256'],
 'scanner_sha256_unchanged':scanner_before,'source_PNG_pixel_writes':0,'engine_runs':0,'imagegen_calls':0,'inventory_build_calls':0,
 'first_attempt_history':None,
 'html_sha256':sha(HTML),'cache_sha256':sha(CACHE),'reuse_sha256':sha(REUSE)}
dump('catalog2_append_ACTUAL.json',proof)
print(json.dumps(proof,ensure_ascii=False))
