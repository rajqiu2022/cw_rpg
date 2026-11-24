"""Native scene-scale lusheng craft rack, required by the approved central square identity."""
import json
import yaml
from miao_town_20261029f import RAW, STAGE, QUEUE, NAME, ROOT, COMMON
from build_redrock_town_20261028a import save, sha

prompt=COMMON+'''One complete practical LUSHENG BAMBOO MOUTH-ORGAN MAKER'S RACK AND SMALL WORK BENCH as ONE tightly grounded scene-prop group.3modest traditional multi-pipe bamboo lusheng instruments of different small sizes stand in a simple low wooden holding rack: each has6slender unequal-length upright bamboo pipes fitted to one small plain wooden windchest, a short side blowing mouthpiece, no strings, no piano keys, no huge theatrical fan of40pipes. At LEFT attached to the rack is a small weathered plain timber workbench with a hand plane, a couple of bamboo offcuts and a tiny cloth pouch. Human-scale craft station, tallest pipes around an adult head height, complete every pipe tip and all wooden feet inside broad transparent margin. Calm ordinary vernacular craft, not a shrine, ritual altar, weapon rack, musical performance stage or souvenir sign. No people, writing, drum, silver headdress, flags, floor island or background. Realistic painted game scene object, same warm wood/soft indigo cloth/cool natural light as Miao-inspired city. Whole group about1.4times wider than tall.'''
m=json.loads((RAW/'manifest.json').read_text('utf-8'));assert not any(r['key']=='lusheng_rack' for r in m['assets'])
p=QUEUE/'lusheng_rack.txt';p.write_text(prompt,'utf-8')
import gen_assets as renderer
renderer.TEMPLATES_DIR=QUEUE/'templates';assert renderer.render_template('native_alpha',{'asset_prompt':prompt},{})['prompt']==prompt.strip()
m['assets'].append({'key':'lusheng_rack','kind':'scene_prop','label':'苗风山城·芦笙制作架','id':NAME+'_lusheng_rack_v1','prompt':p.relative_to(ROOT).as_posix(),'prompt_sha256':sha(p),'transparent':True,'calls':0,'status':'REGISTERED','model':None,'provider':None,'cost':None,'fallback_used':False})
save(RAW/'manifest.json',m);q=yaml.safe_load((QUEUE/'tasks.yaml').read_text('utf-8'));q['tasks'].append({'id':NAME+'_lusheng_rack_v1','template':'native_alpha','skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'vars':{'asset_prompt':prompt}})
(QUEUE/'tasks.yaml').write_text(yaml.safe_dump(q,allow_unicode=True,sort_keys=False),'utf-8')
save(STAGE/'lusheng-preflight.json',{'passed':True,'registered_new_task':1,'scope':'approved square craft-scene prop, no new NPC identity or plot'})
print('Registered native lusheng craft rack,1call budget')
