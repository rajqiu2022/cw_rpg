from lanxi_revision_20261030l import *
from collections import Counter
from datetime import datetime
pack=json.loads((GAME/'art/modules/miao_terrain_20261029i/resource-pack.json').read_text('utf-8'))
paths=set();retired=set()
for family,keys in pack['reused_asset_keys'].items():
 for row in json.loads((GAME/'art/modules'/family/'resource-pack.json').read_text('utf-8'))['assets']:
  target=paths if row['key'] in keys else (retired if family=='miao_town_20261029f' and row['key']=='terrace' else None)
  if target is not None:
   target.update(row[k] for k in ['source','processed','parent_source','output'] if row.get(k))
p=ROOT/'docs/equipment-skill-catalog.html';text=p.read_text('utf-8');m=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S);data=json.loads(m[1]);before=json.loads(m[1]);changed=[]
scene=pack['scene'];url='../game/'+scene[6:]
for row in data['resources']['records']:
 if row['diskPath'] not in paths|retired:continue
 # Replace this scene's historical label while preserving every other consumer.
 row['usage']=[u for u in row['usage'] if not u['label'].startswith(scene)]
 if row['diskPath'] in paths:
  row['usage'].append({'label':scene+'（岚溪寨30l正式版）','url':url})
  row['status']='referenced';row['statusLabel']='岚溪寨正式版 · 当前复用' if row['diskPath'].startswith('game/') else '岚溪寨正式版 · 原生来源'
  row['note']='30l当前：建筑完整不透明，只显示0.42半透明主角；88处变形立面撤下，166段完整等比苔石坡岸；5屋3陈设让开边界。四阶实走、原World/木楼前厅往返已验证。0新图/0PNG改写。docs/changes/lanxi-occlusion-and-banks-20261030l.md。历史：'+row['note']
 else:
  row['status']='candidate';row['statusLabel']='岚溪寨30l已停用 · 历史组件保留'
  row['note']='30l岚溪寨不再用此图投影长条薄墙，改用完整苔石坡岸；其他历史场景引用保留。'+row['note']
 row['usageCount']=len(row['usage']);changed.append(row['diskPath'])
 if 'openworld_lanxi_zhai' not in row['sceneIds'] and row['diskPath'] in paths:row['sceneIds'].append('openworld_lanxi_zhai')
 assert (ROOT/'docs'/row['thumbnail']).is_file(),row['thumbnail']
resources=data['resources'];resources['summary']['states']=dict(Counter(r['status'] for r in resources['records']));resources['generatedAt']=datetime.now().strftime('%Y-%m-%d %H:%M +08:00')
assert {k:v for k,v in data.items() if k!='resources'}=={k:v for k,v in before.items() if k!='resources'}
for old,new in zip(before['resources']['records'],resources['records']):
 if old['diskPath'] not in changed:assert old==new
payload=json.dumps(data,ensure_ascii=False,separators=(',',':'))
p.write_text(text[:m.start(1)]+payload+text[m.end(1):],'utf-8')
save(STAGE/'catalog-update.json',{'changed':changed,'count':len(changed),'total':len(resources['records']),'all_other_records_exact':True,'nonresources_exact':True,'thumbnail_files_unchanged':True,'html_outside_data_exact':True})
print('catalog',len(resources['records']),'updated',len(changed))
