"""Verify one saved native design and resource-only catalogue sync; record milestone."""
import json
import re
from pathlib import Path
from PIL import Image
from miao_town_design_20261029e import ROOT, RAW, STAGE, NAME
from build_redrock_town_20261028a import save, sha

def main():
    m=json.loads((RAW/'manifest.json').read_text('utf-8'));r=m['items']['miao']
    assert r['calls']==1 and sha(ROOT/r['output'])==r['sha256']==sha(Path(r['source_path']))
    assert sha(ROOT/r['prompt'])==r['prompt_sha256']
    html=(ROOT/'docs/equipment-skill-catalog.html').read_text('utf-8')
    data=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',html)[1])
    before=json.loads((STAGE/'catalog-nonresources-before.json').read_text('utf-8'))
    assert {k:v for k,v in data.items() if k!='resources'}==before
    rows=[x for x in data['resources']['records'] if NAME in x['diskPath']]
    assert len(rows)==1;row=rows[0]
    assert row['category']=='design' and row['usageCount']==0 and row['group'].startswith('苗族风情山城')
    thumb=ROOT/'docs'/row['thumbnail']
    with Image.open(thumb) as im:im.load();thumb_size=list(im.size)
    protected=json.loads((STAGE/'protected-before.json').read_text('utf-8'));changed=[]
    for p in protected:
        path=Path(p['path'])
        if (sha(path),path.stat().st_size,path.stat().st_mtime_ns)!=(p['sha256'],p['bytes'],p['mtime_ns']):changed.append(p['path'])
    assert not changed,changed
    report={'passed':True,'native_copy_exact':True,'native_size':r['size'],'native_mode':r['mode'],'builtin_calls':1,
        'prompt_exact':True,'design_records':1,'thumbnail':row['thumbnail'],'thumbnail_size':thumb_size,
        'nonresources_payload_exact':True,'protected_SHA_bytes_mtime_exact':len(protected),'protected_changes':changed,
        'gallery':data['resources']['summary'],'game_consumers':0,'game_files_written':0,'editor_controlled':False,
        'cultural_references':'staging/references.json','visual_limitation':'actual image has 3 bridges versus 2 planned; geometry/navigation not tested'}
    save(STAGE/'verification.json',report)
    summary=f'2026-10-29e苗族风情山城总规已存：`miao_town_design_20261029e/miao_masterplan_overview_v1.png`，内置1次/1586×992 RGB/原图与prompt SHA保；山口/临溪街市/芦笙坪/蜡染绣坊/吊脚民巷/梯田粮院六区，依山木楼与短阶，官方雷山建筑及苗族手艺资料参考。仅设计候选/0game消费者，不裁总图充模块，不造正式ID/剧情；实际3桥比计划多1，后续尺寸/桥头高差/精灵序列待。图鉴{data["resources"]["summary"]["total"]}条/+1设计缩略，非resources同；6保护含沙漠C37F/赤岩B92D精ticks同，0引擎/进程控制。详docs/miao-town-design-20261029e.md。'
    for rel,marker in [('AGENTS.md','## 📍 一句话现状'),('docs/current-progress.md','# 当前工作进展（快照）'),('docs/agents/producer-memory.md','# Producer Memory'),('docs/agents/art-memory.md','# Art Memory')]:
        path=ROOT/rel;old=path.read_text('utf-8');assert old.count(marker)==1
        path.write_text(old.replace(marker,marker+'\n\n'+summary,1),'utf-8')
    print(json.dumps(report,ensure_ascii=False))

if __name__=='__main__':main()
