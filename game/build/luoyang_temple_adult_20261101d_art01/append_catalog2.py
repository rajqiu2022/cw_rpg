"""Append only this RAW/runtime pair and two thumbnails; no inventory rebuild.
Same byte-preserving resources-splice as11b append_catalog4, candidate not adopted.
"""
from pathlib import Path
from collections import Counter
import ast,copy,hashlib,json,re,sys
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'scripts'))
import build_resource_gallery as gallery
sha=lambda b:hashlib.sha256(b).hexdigest()
def new_json(path,value):
    with path.open('x',encoding='utf-8',newline='\n') as stream:
        stream.write(json.dumps(value,ensure_ascii=False,indent=2)+'\n')

# Reuse only the established finite splice helpers, not the older script's body.
prior=ROOT/'game/build/luoyang_quality_20261101b_art01/append_catalog4.py'
prior_text=prior.read_text(encoding='utf-8-sig')
functions=[n for n in ast.parse(prior_text).body if isinstance(n,ast.FunctionDef) and n.name in ('parse','resources_span','member_spans','compact')]
assert len(functions)==4
exec(compile(ast.Module(body=functions,type_ignores=[]),str(prior),'exec'))

def main():
    result_path=HERE/'catalog2_append_ACTUAL.json'
    assert not result_path.exists(),'NEW_RUN_ONLY'
    metadata_path=ROOT/'assets/raw/city_navigation_20261101d/east_scripture_hall_v1.meta.json'
    metadata=json.loads(metadata_path.read_bytes())
    html=ROOT/'docs/equipment-skill-catalog.html'
    cache_path=ROOT/'docs/assets/resources/thumbnail-index.json'
    before_html=html.read_bytes();before_cache=cache_path.read_bytes()
    text,match,data=parse(before_html)
    old=copy.deepcopy(data);resources=data['resources'];records=resources['records']
    cache=json.loads(before_cache);updates={};rows=[]
    paths={r['diskPath'] for r in records};old_count=len(records)
    scanner_sha=sha((ROOT/'scripts/build_resource_gallery.py').read_bytes())
    for phase in ('raw','runtime'):
        key=metadata[phase+'_path'];path=ROOT/key
        assert key not in paths and key not in cache
        assert sha(path.read_bytes())==metadata[phase+'_sha256']
        token=sha(key.encode())[:24]
        expected='assets/resources/map/'+token+'.webp'
        assert not(ROOT/'docs'/expected).exists()
        thumb,size=gallery.thumbnail(path,'map',cache,updates)
        assert thumb==expected and size==metadata['actual_size' if phase=='raw' else 'runtime_size']
        with Image.open(ROOT/'docs'/thumb) as check:
            assert check.width<=360 and check.height<=220
            check.verify()
        links=[metadata['runtime_path']] if phase=='raw' else [metadata['processing_report'],HERE.relative_to(ROOT).as_posix()+'/fit_contract_READY.json']
        rows.append({
            'id':token,'name':'洛阳东经堂五间完整殿堂 · '+('原图' if phase=='raw' else '工程候选图'),
            'category':'map','categoryLabel':gallery.CATEGORIES['map'],
            'group':'洛阳 /11-01d /待拟合候选',
            'path':'res://'+key[5:] if key.startswith('game/') else key,
            'diskPath':key,'url':gallery.href(path),'thumbnail':thumb,
            'media':'image','size':size,'bytes':path.stat().st_size,'format':'PNG','duration':None,
            'status':'candidate','statusLabel':'候选 · 未正式采用/未实机ART',
            'usage':[{'label':v,'url':'../'+v} for v in links],'usageCount':len(links),
            'sceneIds':['ch4_s4_ancient_temple'],'currentConsumers':[],
            'consumerChain':[metadata['raw_path'],metadata['runtime_path']],
            'sourcePath':metadata['raw_path'],'metadataPath':metadata_path.relative_to(ROOT).as_posix(),
            'sha256':metadata[phase+'_sha256'],'phase':'raw_candidate' if phase=='raw' else 'game_candidate',
            'generation':{'backend':'builtin_image_gen','model':None,'provider':None,'cost':None,'modelIdentityVerified':False,'callsForThisRaw':1,'additionalGenerationForGameCopy':False,'requestedSize':metadata['requested_size'],'actualSize':metadata['actual_size']},
            'processing':metadata['deterministic_processing'],
            'note':'Root内置生成1次；RAW原字节保，仅保护框外alpha1清7291+四边64RGBA0，RGB/保护RGBA/alpha>1全同，无裁切拉伸重采样。五间身份已亲看；950宽时实际门高约144/台基较请求更宽，拟合与现役正常图待，不冒正式采用。'
        })
    assert len(rows)==len(updates)==2
    records.extend(rows)
    for category in resources['categories']:
        category['count']=sum(r['category']==category['id'] for r in records)
    resources['summary']={'total':len(records),'images':sum(r['media']=='image' for r in records),'audio':sum(r['media']=='audio' for r in records),'states':dict(Counter(r['status'] for r in records))}
    assert records[:-2]==old['resources']['records']
    assert {k:v for k,v in data.items() if k!='resources'}=={k:v for k,v in old.items() if k!='resources'}
    start,end=resources_span(match[1]);original=match[1][start:end];spans=member_spans(original);updated=original
    for name in sorted(('records','categories','summary'),key=lambda k:spans[k][0],reverse=True):
        left,right=spans[name]
        replacement=original[left:right][:-1]+','+','.join(compact(r) for r in rows)+']' if name=='records' else compact(resources[name])
        updated=updated[:left]+replacement+updated[right:]
    payload=match[1][:start]+updated+match[1][end:]
    new_html=(text[:match.start(1)]+payload+text[match.end(1):]).encode('utf-8')
    after_text,after_match,after_data=parse(new_html)
    assert after_data==data
    after_start,after_end=resources_span(after_match[1])
    assert text[:match.start(1)+start]+text[match.start(1)+end:]==after_text[:after_match.start(1)+after_start]+after_text[after_match.start(1)+after_end:]
    nleft,nright=member_spans(updated)['records'];oleft,oright=spans['records']
    assert updated[nleft:nright].startswith(original[oleft:oright-1]+',')
    cache_text=before_cache.decode('utf-8').rstrip();assert cache_text.endswith('}')
    new_cache=(cache_text[:-1].rstrip()+',\n'+',\n'.join('  '+json.dumps(k,ensure_ascii=False)+': '+json.dumps(v,ensure_ascii=False,indent=2).replace('\n','\n  ') for k,v in updates.items())+'\n}\n').encode('utf-8')
    assert json.loads(new_cache)=={**cache,**updates}
    assert html.read_bytes()==before_html and cache_path.read_bytes()==before_cache
    for name,raw in (('catalog2_gallery_BEFORE.html',before_html),('catalog2_cache_BEFORE.json',before_cache)):
        with(HERE/name).open('xb') as stream:stream.write(raw)
    html.write_bytes(new_html);cache_path.write_bytes(new_cache)
    assert parse(html.read_bytes())[2]==data and json.loads(cache_path.read_bytes())=={**cache,**updates}
    assert scanner_sha==sha((ROOT/'scripts/build_resource_gallery.py').read_bytes())
    new_json(HERE/'catalog2_records_ACTUAL.json',rows)
    result={'status':'EXACT_TWO_CANDIDATE_PATHS_APPENDED_NO_INVENTORY_SCAN','old_records':old_count,'new_records':old_count+2,'old_records_serialized_prefix_exact':True,'nonresources_and_outside_resources_exact':True,'old_cache_members_and_serialization_preserved':True,'shared_scanner_unchanged':True,'new_thumbnails':['docs/'+r['thumbnail'] for r in rows],'engine_runs':0,'inventory_builds':0,'consumer_scans':0,'PNG_asset_writes':0,'before_html_sha256':sha(before_html),'after_html_sha256':sha(html.read_bytes()),'before_cache_sha256':sha(before_cache),'after_cache_sha256':sha(cache_path.read_bytes())}
    new_json(result_path,result);print(json.dumps(result,ensure_ascii=False,indent=2))

if __name__=='__main__':main()
