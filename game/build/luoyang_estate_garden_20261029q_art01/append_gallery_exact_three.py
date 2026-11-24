"""Append exactly this batch's three gallery paths; no inventory/source scan."""
from pathlib import Path
import sys, json, re, hashlib, copy
from collections import Counter
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'scripts'))
import build_resource_gallery as gallery

HERE=Path(__file__).parent
HTML=ROOT/'docs/equipment-skill-catalog.html'
CACHE=ROOT/'docs/assets/resources/thumbnail-index.json'
old_html=HTML.read_bytes()
text=old_html.decode('utf-8')
match=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
assert match
raw=match[1]
payload=json.loads(raw)
before=copy.deepcopy(payload)
resources=payload['resources']
previous=copy.deepcopy(resources)
cache=json.loads(CACHE.read_text(encoding='utf-8'))
old_cache=copy.deepcopy(cache)
new_cache={}
paths=[
 ('assets/raw/luoyang_estate_garden_20261029q/lotus_pond_v1.png','c4347b60b8ce552362a3ff05b30f203a0d80a7a96c34842a0213dad2a9fb6cd2','candidate','原图保留 · 外围留白失败'),
 ('assets/processed/luoyang_estate_garden_20261029q/lotus_pond_v1_padded.png','96c1e18804c0032a836ac1dce1af934e5a3349cf83d4dd3b159845da2347838b','candidate','授权清边留白 · 当前候选'),
 ('game/art/modules/luoyang_estate_garden_20261029q/lotus_pond_v1.png','96c1e18804c0032a836ac1dce1af934e5a3349cf83d4dd3b159845da2347838b','map','工程图 · 当前园林候选')]
assert not any(x['diskPath'] in {p[0] for p in paths} for x in resources['records']), 'Batch already appended; do not duplicate.'
note='Root内置原生石岸荷塘1次，透明水外圈曾显示灰绿RGB，逐点核实圈外alpha0，不冒可见雾并停止重生。原PNG保留；processed仅保护框外1924个alpha1清理+四边128透明留白，原RGB/主体RGBA/maxA254保。后园单侧荷塘与花木园路仍是当前候选，最终透明叠地、真实水碰撞与正常镜头需本批Godot检查；不得据导入/资源存在宣称整园已好。'
rows=[]
for key,digest,kind,label in paths:
    path=ROOT/key
    assert hashlib.sha256(path.read_bytes()).hexdigest()==digest
    thumb,size=gallery.thumbnail(path,kind,cache,new_cache)
    rows.append({'id':hashlib.sha256(key.encode()).hexdigest()[:24],'name':'洛阳宅园 · 石岸荷塘','category':kind,'categoryLabel':gallery.CATEGORIES[kind],'group':'洛阳 / 宅园石岸荷塘 / '+('工程图' if kind=='map' else ('原图' if '/raw/' in key else '授权派生')),'path':('res://'+key[5:] if key.startswith('game/') else key),'diskPath':key,'url':gallery.href(path),'thumbnail':thumb,'media':'image','size':size,'bytes':path.stat().st_size,'format':'PNG','duration':None,'status':'candidate','statusLabel':label,'usage':[],'usageCount':0,'sceneIds':[],'note':note,'sha256':digest,'sourcePath':paths[0][0],'generation':{'backend':'builtin_image_gen','model':None,'provider':None,'cost':None}})
resources['records'].extend(rows)
for c in resources['categories']:
    c['count']=sum(r['category']==c['id'] for r in resources['records'])
resources['summary']={'total':len(resources['records']),'images':sum(r['media']=='image' for r in resources['records']),'audio':sum(r['media']=='audio' for r in resources['records']),'states':dict(Counter(r['status'] for r in resources['records']))}
assert resources['records'][:-3]==previous['records']
assert {k:v for k,v in payload.items() if k!='resources'}=={k:v for k,v in before.items() if k!='resources'}
resource_keys=list(re.finditer(r'"resources"\s*:\s*',raw))
assert len(resource_keys)==1
start=resource_keys[0].end()
old_value,end=json.JSONDecoder().raw_decode(raw,start)
assert old_value==previous
new_raw=raw[:start]+json.dumps(resources,ensure_ascii=False,separators=(',',':'))+raw[end:]
assert json.loads(new_raw)==payload
new_text=text[:match.start(1)]+new_raw+text[match.end(1):]
assert new_text[:match.start(1)]==text[:match.start(1)]
assert new_text.endswith(text[match.end(1):])
backup=HERE/'gallery_before_exact_three.html'
assert not backup.exists()
backup.write_bytes(old_html)
(HERE/'gallery_cache_before_exact_three.json').write_bytes(CACHE.read_bytes())
cache.update(new_cache)
assert {k:v for k,v in cache.items() if k not in new_cache}=={k:v for k,v in old_cache.items() if k not in new_cache}
assert set(new_cache)=={p[0] for p in paths}
CACHE.write_text(json.dumps(cache,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
HTML.write_bytes(new_text.encode('utf-8'))
receipt={'status':'EXACT_THREE_GALLERY_PATHS_APPENDED_NO_INVENTORY_SCAN','old_total':previous['summary']['total'],'new_summary':resources['summary'],'paths':[p[0] for p in paths],'old_records_preserved':True,'non_resources_payload_equal':True,'html_outside_catalogData_preserved':True,'old_cache_entries_preserved':True,'new_thumbnail_paths':[v['thumbnail'] for v in new_cache.values()],'engine_calls':0,'inventory_build_calls':0,'source_or_asset_png_writes':0}
(HERE/'gallery_exact_three_actual.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(HERE/'gallery_three_records.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt,ensure_ascii=False))
