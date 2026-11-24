"""Prepare only the two new path records. Never scan the asset inventory."""
from pathlib import Path
from urllib.parse import quote
from PIL import Image
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(name,value):
 with (OUT/name).open('x',encoding='utf-8') as f:json.dump(value,f,ensure_ascii=False,indent=2);f.write('\n')
def url(path):return '../'+quote(path,safe='/')
raw='assets/raw/environment_residual_20261031d/huashan_valley_backdrop_v1.png'
game='game/art/modules/environment_residual_20261031d/huashan_valley_backdrop_v1.png'
meta=raw.replace('.png','.meta.json')
controller='game/build/environment_residual_20261031d_system01/huashan_controller.gd'
consumer='game/build/environment_residual_20261031d_system01/huashan_environment.gd'
fitter='game/build/environment_residual_20261031d_system01/mountain_backdrop.gd'
html=ROOT/'docs/equipment-skill-catalog.html';cache=ROOT/'docs/assets/resources/thumbnail-index.json';reuse=ROOT/'docs/resource-reuse-index.md'
text=html.read_text(encoding='utf-8');match=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
data=json.loads(match[1]);assert len(data['resources']['records'])==5264
paths={r['diskPath'] for r in data['resources']['records']};assert raw not in paths and game not in paths
md=json.loads((ROOT/meta).read_bytes())
assert sha(ROOT/raw)==sha(ROOT/game)==md['sha256']=='fd08b4a0b2c0edcb892bdb806af5ac2eb1a7728db7399b1d472d7fa64ff95293'
assert (ROOT/raw).read_bytes()==(ROOT/game).read_bytes()
assert (ROOT/raw).stat().st_size==md['bytes']==3016352
with Image.open(ROOT/raw) as image:assert image.size==(1672,941) and image.mode=='RGB'
pins={p:sha(ROOT/p) for p in [raw,game,meta,controller,consumer,fitter]}
rows=[]
for path in [raw,game]:
 original=path==raw;token=hashlib.sha256(path.encode()).hexdigest()[:24]
 chain=[game,controller,consumer,fitter]
 uses=[{'label':p,'url':url(p)} for p in chain[(0 if original else 1):]]
 rows.append({'id':token,'name':'华山远谷山景 · '+('原图' if original else '工程原样副本'),
  'category':'map','categoryLabel':'地图组件','group':'31d环境续改 / '+('原图来源' if original else '当前原生运行图'),
  'path':path if original else 'res://'+path[5:],'diskPath':path,'url':url(path),
  'thumbnail':'assets/resources/map/'+token+'.webp','media':'image','size':[1672,941],'bytes':3016352,'format':'PNG','duration':None,
  'status':'referenced','statusLabel':'工程已接入 · 局部图待验','usage':uses,'usageCount':len(uses),
  'sceneIds':['openworld_huashan_forecourt'],'currentConsumers':chain[1:],'consumerChain':chain,'sourcePath':raw,'metadataPath':meta,
  'note':'本批仅1次内置生成；请求2048×1152，实际RGB1672×941，原字节保留不假称请求尺寸。model/provider/cost未由工具返回，未验证模型身份。RAW/game逐字节相同，无清边、留白、裁切、拉伸、重画或processed。新华山controller以严格SHA/尺寸Image.load及缓存ImageTexture采用完整不透明远山图，CanvasLayer -10整图等比cover，运行约1.148倍不改源像素；仅非可走背景，不裁总图充模块。工程已接入，正常图与全派ART尚待Root，不冒最终验收。'+(' RAW为工程副本来源，运行不直接读RAW。' if original else ''),
  'sha256':md['sha256'],'generation':{'backend':'builtin_image_gen','model':None,'modelIdentityVerified':False,'provider':None,'cost':None,'callsForThisRaw':1,'additionalGenerationForGameCopy':False,'requestedSize':[2048,1152],'actualSize':[1672,941]},
  'processing':{'localPixelProcessing':False,'rawGameByteExact':True,'processedFile':None},
  'runtimeLoad':'strict native Image.load + cached ImageTexture; not .import','phase':'raw_selected' if original else 'game_selected',
  'sourceMetadataAdoptionWasHistoricalPending':md['status']})
dump('catalog2_records_READY.json',rows)
dump('catalog2_plan_READY.json',{'status':'CANDIDATE_ONLY','baseline':{'html_sha256':sha(html),'cache_sha256':sha(cache),'reuse_sha256':sha(reuse),'old_records':5264},'protected_source_sha256':pins,'new_thumbnail_paths':['docs/'+r['thumbnail'] for r in rows],'PNG_writes':0,'engine_runs':0,'inventory_build_calls':0})
print(json.dumps({'records':2,'old_records':5264,'records_sha256':sha(OUT/'catalog2_records_READY.json'),'plan_sha256':sha(OUT/'catalog2_plan_READY.json'),'formal_writes':0}))
