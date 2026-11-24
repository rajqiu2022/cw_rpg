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
 ('assets/raw/luoyang_yihongyuan_20261029n/yihongyuan_exterior_v1.png','e80f44f0a1cc9779bb375d0f77a96131befe73b6ff98d28e7ae2356f047b57dd','candidate','原图保留 · 外围留白失败'),
 ('assets/processed/luoyang_yihongyuan_20261029n/yihongyuan_exterior_v1_padded.png','515f66cd72525ae60d1d1510a2664b35bca569e79ebda8d3383a68e316a581a6','candidate','授权清边留白 · 已导入候选'),
 ('game/art/maps/luoyang_yihongyuan_20261029n/yihongyuan_exterior_v1.png','515f66cd72525ae60d1d1510a2664b35bca569e79ebda8d3383a68e316a581a6','map','工程运行图 · 已导入待接线')]
assert not any(x['diskPath'] in {p[0] for p in paths} for x in resources['records']), 'Batch already appended; do not duplicate.'
note='Root内置局部牌匾edit1次，怡红院3简中字已实看。新生成canvas/体量改变，非旧楼像素精同；另手量门/地脚。RAW原样保留；processed仅框外399个alpha1去零并四边补32透明留白，原RGB和主体RGBA保留。Root已单图lossless导入/RGBA精核/3叶晋升，正式binding仍待；未宣称已接入内景或剧情。'
rows=[]
for key,digest,kind,label in paths:
    path=ROOT/key
    assert hashlib.sha256(path.read_bytes()).hexdigest()==digest
    thumb,size=gallery.thumbnail(path,kind,cache,new_cache)
    rows.append({'id':hashlib.sha256(key.encode()).hexdigest()[:24],'name':'怡红院 · 完整外观','category':kind,'categoryLabel':gallery.CATEGORIES[kind],'group':'洛阳 / 怡红院 / '+('工程图' if kind=='map' else ('原图' if '/raw/' in key else '授权派生')),'path':('res://'+key[5:] if key.startswith('game/') else key),'diskPath':key,'url':gallery.href(path),'thumbnail':thumb,'media':'image','size':size,'bytes':path.stat().st_size,'format':'PNG','duration':None,'status':'candidate','statusLabel':label,'usage':[],'usageCount':0,'sceneIds':[],'note':note,'sha256':digest,'sourcePath':paths[0][0],'generation':{'backend':'builtin_image_gen','model':None,'provider':None,'cost':None}})
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
