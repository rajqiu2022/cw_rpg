from four_settlements_20261030e import *
import re
from PIL import ImageDraw
choices={}
for folder in ['building','prop','luoyang_assembled_20261016','luoyang_harbour_life_20261016','luoyang_docks_office_20261016h','veg','ground']:
 for p in (ROOT/'game/art/modules'/folder).glob('*.png'):
  if folder=='ground' or any(w in p.stem.lower() for w in ['linxi','cottage','inn','smith','warehouse','boat','ship','willow','net','quay','dock','pier','bridge','stall','roof','house','hall','tree','fence']):choices[p.stem]=p
for p in (ROOT/'game/art').rglob('*.png'):
 if any(w in p.stem.lower() for w in ['cargo_ship','ferry_boat','warehouse_v1','willow_v']):choices[p.stem]=p
rows=[];thumbs=[]
for key,p in sorted(choices.items()):
 im=Image.open(p).convert('RGBA');a=im.getchannel('A');bbox=a.getbbox();rows.append({'key':key,'path':p.relative_to(ROOT/'game').as_posix(),'size':list(im.size),'bbox':bbox})
 im.thumbnail((270,165));tile=Image.new('RGB',(300,205),(74,78,74));tile.paste(im,((300-im.width)//2,0),im);ImageDraw.Draw(tile).text((5,170),key[:45],fill='white');thumbs.append(tile)
for offset in range(0,len(thumbs),24):
 batch=thumbs[offset:offset+24];sheet=Image.new('RGB',(1200,205*((len(batch)+3)//4)),(74,78,74))
 for i,im in enumerate(batch):sheet.paste(im,((i%4)*300,(i//4)*205))
 sheet.save(STAGE/('existing-'+str(offset//24)+'.jpg'))
save(STAGE/'existing-media.json',rows)
print(json.dumps({'sheets':(len(rows)+23)//24,'images':len(rows),'keys':[r['key'] for r in rows]},ensure_ascii=False))
ids=['openworld_bailu_ferry','openworld_east_sea_port','linxi_tutorial','linxi_village_center','linxi_village_scrollmap','ch1_s2_qingfeng','ch2_s1_zhuwei_market']
out={}
for id in ids:
 p=ROOT/'game/data/scenes'/(id+'.tres');s=p.read_text('utf-8');maps=re.findall(r'res://data/maps/[^" ]+',s)
 out[id]={'scene':str(p.relative_to(ROOT)),'map':maps,'scene_sha':sha(p),'business_lines':[ln.strip() for ln in s.splitlines() if any(x in ln for x in ['npc_id','target_scene','action','pos_x','pos_y','player_spawn','on_enter','require_flag','trigger_zones','interactions','exits'])]}
 if maps:
  mp=ROOT/'game'/maps[0][6:];out[id]['map_lines']=[ln.strip() for ln in mp.read_text('utf-8').splitlines() if any(x in ln for x in ['portals','target_scene','action','destination_name','label','pos','size','require_flag'])]
save(STAGE/'business-audit.json',out)
