"""Append only this batch's explicit PNG and RAW records; no inventory scan."""
from pathlib import Path
from collections import Counter
import copy, hashlib, json, re, sys
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).parent
sys.path.insert(0,str(ROOT/'scripts'))
import build_resource_gallery as gallery
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def rel(p):
    p=Path(p)
    return p.relative_to(ROOT).as_posix() if p.is_absolute() else p.as_posix()
def out(name,data):
    p=HERE/name
    assert not p.exists(),p
    p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
html=ROOT/'docs/equipment-skill-catalog.html'
cachefile=ROOT/'docs/assets/resources/thumbnail-index.json'
oldhtml=html.read_bytes(); oldcachebytes=cachefile.read_bytes()
text=oldhtml.decode('utf-8')
match=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
data=json.loads(match[1]); olddata=copy.deepcopy(data)
cache=json.loads(oldcachebytes); oldcache=copy.deepcopy(cache)
manifest=read(ROOT/'game/art/characters/pc_hd_20261102c/source.json')
plan=read(HERE/'formal_mipmap_install_plan.json')
assert all(sha(Path(r['target']))==r['after_sha256'] for r in plan['entries'])
protected={r['target']:sha(Path(r['target'])) for r in plan['entries']}
protected[str(ROOT/'scripts/build_resource_gallery.py')]=sha(ROOT/'scripts/build_resource_gallery.py')
protected[str(ROOT/'docs/resource-reuse-index.md')]=sha(ROOT/'docs/resource-reuse-index.md')
receipts=[]
for name in ['atlas_preparation_receipt.json','reuse_preparation_receipt.json','next_four_preparation_receipt.json']:
    for r in read(HERE/name):
        receipts.append((r,'game/build/npc_hd_20261106_candidate01/'+name))
assets=[]
for source,row in manifest['mappings'].items():
    atlas=row['atlas']; key=atlas.replace('res://','game/')
    role=Path(key).name.replace('_native_20261106.png','').replace('_idle_down_20261106.png','')
    role='carrier' if role.startswith('carrier_') else role
    receipt,receiptpath=next((r,p) for r,p in receipts if r['role']==role)
    assets.append((key,role,'runtime',receipt,receiptpath,source,row))
    raw=rel(receipt['raw'])
    if raw.startswith('assets/raw/npc_hd_20261106/') and not any(a[0]==raw for a in assets):
        assets.append((raw,role,'raw',receipt,receiptpath,source,row))
assert len([a for a in assets if a[2]=='runtime'])==15
assert len([a for a in assets if a[2]=='raw'])==8
existing={r['diskPath'] for r in data['resources']['records']}
rows=[]; updates={}; skipped=[]
for key,role,phase,receipt,receiptpath,source,mapping in assets:
    if key in existing:
        skipped.append(key)
        continue
    path=ROOT/key; digest=sha(path)
    if phase=='runtime': assert digest==mapping['atlas_sha256']
    else: assert digest==receipt['raw_sha256']
    thumb,size=gallery.thumbnail(path,'npc',cache,updates)
    uses=[{'label':'正式原生高清精确源映射','url':gallery.href(ROOT/'game/art/characters/pc_hd_20261102c/source.json')},{'label':'NPC visual adapter（原业务保持）','url':gallery.href(ROOT/'game/build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd')}]
    stage='正式动作贴图' if phase=='runtime' else '内置原始来源'
    note='2026-11-06 首批12族15atlas之一；8新生4复用，非全员/非独立四向。原生人体'+str(mapping['body_height'])+'px；仅主体外alpha1/透明补白/整数整帧对齐，无原图重采样，RGB与保护RGBA精同。原身份、帧语义、脚点、比例及业务保。Root visual03仅实际缩放首帧视觉有限接受，不冒全场景逐帧ART。'
    note+=' 正式15atlas采用mipmaps+HD子节点LOD采样，level0 RGBA精同，非模糊冒高清。' if phase=='runtime' else ' 本RAW为派生来源，不是引擎当前运行atlas；未知模型/成本不虚填。'
    rows.append({'id':hashlib.sha256(key.encode()).hexdigest()[:24],'name':role+' · '+stage,'category':'npc','categoryLabel':'NPC与角色','group':'原生高清首批20261106 / '+stage,'path':'res://'+key[5:] if key.startswith('game/') else key,'diskPath':key,'url':gallery.href(path),'thumbnail':thumb,'media':'image','size':size,'bytes':path.stat().st_size,'format':'PNG','duration':None,'status':'referenced','statusLabel':stage,'usage':uses,'usageCount':2,'sceneIds':[],'note':note,'sha256':digest,'sourcePath':rel(receipt['raw']),'metadataPath':receiptpath,'formalSourceSprite':source,'animation':{'frames':mapping['framecount'],'source_hframes':mapping['source_hframes'],'source_vframes':mapping['source_vframes'],'independent_four_directions_created':False},'processingReceipt':receiptpath})
resources=data['resources']; resources['records'].extend(rows)
for c in resources['categories']: c['count']=sum(r['category']==c['id'] for r in resources['records'])
resources['summary']={'total':len(resources['records']),'images':sum(r['media']=='image' for r in resources['records']),'audio':sum(r['media']=='audio' for r in resources['records']),'states':dict(Counter(r['status'] for r in resources['records']))}
assert resources['records'][:len(olddata['resources']['records'])]==olddata['resources']['records']
assert {k:v for k,v in data.items() if k!='resources'}=={k:v for k,v in olddata.items() if k!='resources'}
hits=list(re.finditer(r'"resources"\s*:\s*',match[1])); assert len(hits)==1
start=hits[0].end(); oldvalue,end=json.JSONDecoder().raw_decode(match[1],start)
assert oldvalue==olddata['resources']
newjson=match[1][:start]+json.dumps(resources,ensure_ascii=False,separators=(',',':'))+match[1][end:]
assert json.loads(newjson)==data
cache.update(updates)
assert all(cache[k]==v for k,v in oldcache.items())
assert html.read_bytes()==oldhtml and cachefile.read_bytes()==oldcachebytes
assert all(sha(Path(k))==v for k,v in protected.items())
for name,raw in [('gallery_before_formal15.html',oldhtml),('gallery_cache_before_formal15.json',oldcachebytes)]:
    p=HERE/name; assert not p.exists(); p.write_bytes(raw)
html.write_bytes((text[:match.start(1)]+newjson+text[match.end(1):]).encode('utf-8'))
cachefile.write_text(json.dumps(cache,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
out('gallery_formal15_records.json',rows)
out('gallery_formal15_receipt.json',{'status':'EXPLICIT_MEDIA_APPEND','added':len(rows),'skipped_existing':skipped,'before_total':olddata['resources']['summary']['total'],'after_total':resources['summary']['total'],'new_thumbnails':len(updates),'old_records_exact':True,'non_resources_exact':True,'old_cache_exact':True,'html_outside_resources_exact':True,'protected_sha256':protected,'inventory_scan_calls':0,'engine_calls':0,'imagegen_calls':0,'source_png_edits':0,'real_save_content_access':False})
print(json.dumps({'added':len(rows),'skipped':skipped,'total':resources['summary']['total'],'thumbnails':len(updates)}))
