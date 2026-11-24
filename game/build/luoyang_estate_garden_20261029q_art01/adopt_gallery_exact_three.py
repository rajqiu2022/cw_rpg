"""Update only three existing 29q gallery rows; no asset/source inventory or rendering."""
from pathlib import Path
import json,re,copy,hashlib
from collections import Counter
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).parent
HTML=ROOT/'docs/equipment-skill-catalog.html'
raw_html=HTML.read_bytes()
text=raw_html.decode('utf-8')
match=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
assert match
raw=match[1]
payload=json.loads(raw)
before=copy.deepcopy(payload)
resources=payload['resources']
paths={
 'assets/raw/luoyang_estate_garden_20261029q/lotus_pond_v1.png',
 'assets/processed/luoyang_estate_garden_20261029q/lotus_pond_v1_padded.png',
 'game/art/modules/luoyang_estate_garden_20261029q/lotus_pond_v1.png'}
consumer='game/build/luoyang_estate_garden_20261029q_system01/output/128248/luoyang_estate_region_27d.bin'
manifest='game/build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
assert hashlib.sha256((ROOT/consumer).read_bytes()).hexdigest()=='26918ba3c0198f1dcf74dcacf41c24ff2a0eeaf4b7c58964f45db4ea089daf8c'
assert hashlib.sha256((ROOT/manifest).read_bytes()).hexdigest()=='1954dd35e261c00b8551a95b93d9e67bf7d254a4cb108d7bf47cf387cddf2d8d'
targets=[r for r in resources['records'] if r['diskPath'] in paths]
assert len(targets)==3
note='本批Root内置原生1次，RAW不足留白失败保留；派生仅主体框外1924个alpha1清理及四边128透明补白，原RGB/主体RGBA/maxA254保。已正式由Estate26918BA3/manifest1954DD35消费。Root唯一35156自然0、178检查0失败、1046INPUT，已亲看池塘透明叠地无可见halo，花木/草地/曲路可见；仅交付本后园池景与通路，不授全城ART或参考密度。RAW/processed为正式工程图的来源追溯，不表示引擎直接载入RAW。'
for row in targets:
    row.update(category='map',categoryLabel='地图组件',status='referenced',
        statusLabel=('原图保留 · 正式派生来源' if '/raw/' in row['diskPath'] else ('授权派生 · 后园正式采用' if '/processed/' in row['diskPath'] else '后园正式采用 · 池景与通路局部验收')),
        usage=[{'label':'宅园后园 · 正式Estate26918BA3','url':'../'+consumer}],usageCount=1,
        sceneIds=['luoyang_estate_region_27d'],note=note,
        formalConsumerSha256='26918ba3c0198f1dcf74dcacf41c24ff2a0eeaf4b7c58964f45db4ea089daf8c',
        formalManifestSha256='1954dd35e261c00b8551a95b93d9e67bf7d254a4cb108d7bf47cf387cddf2d8d')
old_other=[r for r in before['resources']['records'] if r['diskPath'] not in paths]
new_other=[r for r in resources['records'] if r['diskPath'] not in paths]
assert old_other==new_other
for category in resources['categories']:
    category['count']=sum(r['category']==category['id'] for r in resources['records'])
resources['summary']={'total':len(resources['records']),'images':sum(r['media']=='image' for r in resources['records']),'audio':sum(r['media']=='audio' for r in resources['records']),'states':dict(Counter(r['status'] for r in resources['records']))}
assert {k:v for k,v in before.items() if k!='resources'}=={k:v for k,v in payload.items() if k!='resources'}
keys=list(re.finditer(r'"resources"\s*:\s*',raw));assert len(keys)==1
start=keys[0].end();old,end=json.JSONDecoder().raw_decode(raw,start)
assert old==before['resources']
new_raw=raw[:start]+json.dumps(resources,ensure_ascii=False,separators=(',',':'))+raw[end:]
assert json.loads(new_raw)==payload
result=text[:match.start(1)]+new_raw+text[match.end(1):]
assert result[:match.start(1)]==text[:match.start(1)] and result.endswith(text[match.end(1):])
backup=HERE/'gallery_before_adoption_three.html'
assert not backup.exists()
backup.write_bytes(raw_html)
HTML.write_bytes(result.encode('utf-8'))
(HERE/'gallery_three_records.json').write_text(json.dumps(targets,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
receipt={'status':'EXACT_THREE_EXISTING_ROWS_FORMAL_ESTATE_CONSUMER_UPDATED','paths':sorted(paths),'consumer':consumer,'consumer_sha256':'26918ba3c0198f1dcf74dcacf41c24ff2a0eeaf4b7c58964f45db4ea089daf8c','manifest_sha256':'1954dd35e261c00b8551a95b93d9e67bf7d254a4cb108d7bf47cf387cddf2d8d','other_records_preserved':True,'other_record_count':len(old_other),'non_resources_unchanged':True,'html_outside_catalogData_unchanged':True,'old_total':before['resources']['summary']['total'],'new_summary':resources['summary'],'cache_thumbnail_writes':0,'asset_writes':0,'source_scan_calls':0,'engine_calls':0}
(HERE/'gallery_adoption_exact_three_ACTUAL.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt,ensure_ascii=False))
