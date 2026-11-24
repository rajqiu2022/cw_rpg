import json,re
from sect_redesign_20261029j import ROOT,BASE,QUEUE,save,sha
m=json.loads((BASE/'manifest.json').read_text('utf-8'))
names={'wudang':'武当派 · 云山层台改造设计v2','mingwu':'茗雾山庄 · 茶谷曲院改造设计v2'}
for r in m['assets']:
    assert sha(ROOT/r['output'])==sha(__import__('pathlib').Path(r['source_path']))==r['sha256']
    r.update(name=names[r['key']],id='sect_redesign_20261029j_'+r['key'],review_note='设计修订候选，0游戏消费者；不是可试玩地图。')
m['items']={r['key']:r for r in m['assets']};save(BASE/'manifest.json',m)
catalog=ROOT/'docs/equipment-skill-catalog.html'
p=json.loads(re.search(r'<script id="catalogData" type="application/json">([\s\S]*?)</script>',catalog.read_text('utf-8'))[1])
save(BASE/'catalog-nonresources-before.json',{k:v for k,v in p.items() if k!='resources'})
