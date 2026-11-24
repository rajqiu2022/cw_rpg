"""Only eleven new records. Default prepares candidates; never scans the inventory."""
from pathlib import Path
from urllib.parse import quote
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def dump(n,v):
 with (OUT/n).open('xb') as f:f.write(enc(v))
def local(p):return Path(p).relative_to(ROOT).as_posix()
def url(p):return '../'+quote(p,safe='/')
html=ROOT/'docs/equipment-skill-catalog.html';cache=ROOT/'docs/assets/resources/thumbnail-index.json'
raw_html=html.read_bytes();text=raw_html.decode();match=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
payload=json.loads(match[1]);old_paths={r['diskPath'] for r in payload['resources']['records']}
provenance=ROOT/'game/build/world_landmarks_20261031c/asset_provenance.json'
assets=json.loads(provenance.read_bytes());assert len(assets['assets'])==6 and assets['builtin_calls']==6
profiles='game/build/sect_repair_20261031c_system01/visual_profiles.json'
visuals='game/build/sect_repair_20261031c_system01/native_visuals.gd'
world='game/build/world_landmarks_20261031c/refinement.gd'
adoption=json.loads((ROOT/'game/build/sect_repair_20261031c_system01/adoption_data.json').read_bytes())
scene_ids=['openworld_wudang_gate','openworld_huashan_forecourt']
scenes=sorted({adoption['towns'][k]['scene'] for k in scene_ids})
labels={'cliff_front_v1':'完整灰岩前崖','cliff_left_v1':'完整灰岩左崖','cliff_right_v1':'完整灰岩右崖','lanxi_world_landmark_v1':'岚溪寨完整World地标','mountain_stair_12_v1':'十二级山阶V1拒稿','mountain_stair_12_v2':'十二级山阶V2'}
rows=[];pins={local(provenance):sha(provenance),profiles:sha(ROOT/profiles),visuals:sha(ROOT/visuals),world:sha(ROOT/world)}
for asset in assets['assets']:
 raw=local(asset['raw']);game=local(asset['path']);key=Path(raw).stem
 assert sha(ROOT/raw)==sha(ROOT/game)==asset['sha256'] and (ROOT/raw).read_bytes()==(ROOT/game).read_bytes()
 pins[raw]=asset['sha256'];pins[game]=asset['sha256']
 meta=Path(raw).with_suffix('.meta.json').as_posix();source_meta=json.loads((ROOT/meta).read_bytes());pins[meta]=sha(ROOT/meta)
 rejected=key=='mountain_stair_12_v1';landmark=key=='lanxi_world_landmark_v1'
 for path in [raw]+([] if rejected else [game]):
  assert path not in old_paths
  original=path==raw;token=hashlib.sha256(path.encode()).hexdigest()[:24]
  chain=[] if rejected else ([game,world] if landmark else [game,profiles,visuals])
  uses=[] if rejected else [{'label':p,'url':url(p)} for p in chain[(0 if original else 1):]]
  ids=[] if rejected else (['world_map_jianghu','world_map_jianghu_v15'] if landmark else scene_ids)
  note='本批共6次内置生成，各RAW一次；model/provider/cost未知null。RAW及game副本原字节精同，0清边/补白/裁切/缩放/重画，未生成processed。原alpha1及max254不归一；完整A1边距未重新授PASS。'
  if rejected:note+=' V1阶透视/比例拒稿未采用，只保RAW历史，不把现存game副本冒运行消费者。'
  else:note+=' 当前正式采用；通过严格SHA与尺寸校验后Image.load/create_from_image缓存原生ImageTexture消费，不经.import。'
  if landmark:note+=' World微缩地标不冒村内可走地图/新门户，原900,6000门脚保留。'
  elif not rejected:note+=' 两派既有真实坡段/物理沿用，新完整岩崖及V2踏面/栏杆仅按原生统一缩放注册；非全门派或新剧情美术终验。'
  if original and not rejected:note+=' RAW只作为工程原样副本来源，运行不直接读取RAW。'
  rows.append({'id':token,'name':labels[key]+(' · 原图' if original else ' · 工程原样副本'),
   'category':'map','categoryLabel':'地图组件','group':'31c环境修复 / '+('原图来源' if original else '当前原生运行图'),
   'path':path if original else 'res://'+path[5:],'diskPath':path,'url':url(path),
   'thumbnail':'assets/resources/map/'+token+'.webp','media':'image','size':asset['size'],'bytes':asset['bytes'],
   'format':'PNG','duration':None,'status':'rejected' if rejected else 'referenced',
   'statusLabel':'拒稿历史 · 未采用' if rejected else ('已采用原生来源' if original else '正式原生ImageTexture缓存消费'),
   'usage':uses,'usageCount':len(uses),'sceneIds':ids,'currentConsumers':chain[1:],
   'consumerChain':chain,'sourcePath':raw,'metadataPath':meta,'note':note,'sha256':asset['sha256'],
   'generation':{'backend':'builtin_image_gen','model':None,'provider':None,'cost':None,'callsForThisRaw':1,'additionalGenerationForGameCopy':False},
   'processing':{'localPixelProcessing':False,'rawGameByteExact':True,'processedFile':None},
   'runtimeLoad':'not adopted' if rejected else 'strict native Image.load + cached ImageTexture; not .import',
   'phase':'raw_discarded' if rejected else ('raw_selected' if original else 'game_selected'),
   'sourceMetadataAdoptionWasHistoricalPending':source_meta.get('adoption')})
assert len(rows)==11
dump('catalog11_records_READY.json',rows)
plan={'status':'CANDIDATE_ONLY_NOT_APPLIED_OR_THUMBNAILED','known_records':11,'raw':6,'adopted_game':5,'rejected_raw':1,
 'baseline':{'html_sha256':sha(html),'cache_sha256':sha(cache),'reuse_sha256':sha(ROOT/'docs/resource-reuse-index.md'),'old_records':len(payload['resources']['records'])},
 'protected_source_sha256':pins,'new_thumbnail_paths':['docs/'+r['thumbnail'] for r in rows],
 'append_only_resources':True,'preserve_all_old_records_nonresources_oldcache_and_thumbs':True,
 'PNG_writes':0,'engine_runs':0,'imagegen_calls':0,'inventory_build_calls':0}
dump('catalog11_plan_READY.json',plan)
reuse='''## 2026-10-31c 增量：两派原生山阶/岩崖与岚溪World地标

仅本批6张RAW/5张采用工程副本的11路径增量，不更新旧全库扫描快照。`environment_repair_20261031c` 的 mountain_stair_12_v1 为拒稿历史，未采用；V2山阶、front/left/right三完整灰岩崖由 `game/build/sect_repair_20261031c_system01/visual_profiles.json` → `native_visuals.gd` 在武当/华山原室外场景消费，原坡段/物理与业务保持。岚溪完整微缩地标由 `game/build/world_landmarks_20261031c/refinement.gd` 消费，原World门脚900,6000不改，不冒村内地图。

6次builtin原图均保，model/provider/cost未知null；RAW与工程PNG逐字节相同，无清边、留白、缩放、裁切、processed或像素重画。采用5图经严格SHA/尺寸检查后用Image.load及缓存ImageTexture读取原生图，非.import消费者；原A1/maxalpha254保留，不补授边距或整场景ART。出处为 `game/build/world_landmarks_20261031c/asset_provenance.json` 和六份RAW meta；本次图鉴登记不启动引擎、不复测，当前具体地图验收范围以Root31c记录为准。

'''
with (OUT/'reuse_increment_READY.txt').open('x',encoding='utf-8') as f:f.write(reuse)
print(json.dumps({'records':11,'old_records':plan['baseline']['old_records'],'records_sha256':sha(OUT/'catalog11_records_READY.json'),'plan_sha256':sha(OUT/'catalog11_plan_READY.json'),'no_formal_catalog_writes':True}))
