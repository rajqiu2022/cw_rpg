"""Register two missing native bank/understory components after first runtime image review."""
import json
import yaml
from miao_town_20261029f import RAW, STAGE, QUEUE, NAME, ROOT, COMMON
from build_redrock_town_20261028a import save, sha

details={
 'bank_shrub':('vegetation','苗风山城·溪岸石草丛','One complete LOW asymmetric group of3small cool gray creek-bank boulders with a few modest ferns, moss and grasses rooted tightly BETWEEN the stones, same elevated orthographic game camera. Low broad shape about2.5times wider than tall, boulders no taller than an adult knee, natural gray/moss green, no huge rock cliff, tree, water, bank strip, rectangular floor island, border or haze. Complete contact feet, small grounded vegetation/stone cluster for placing along the edge of a narrow creek, not a whole scenery.'),
 'moss_patch':('vegetation','苗风山城·林下苔草地被','One irregular SMALL LOW ground-cover patch, fine muted-green moss, a few tiny fern fronds and short wild grasses across a thin scattered layer of brown leaf litter, exact elevated orthographic game camera. Gently irregular organic footprint with REAL plant and leaf edges, not a rectangular tile or vignette, no detached fuzzy fog, tree, boulder, flower, water, background or large dirt mound. Patch lies almost flat to ground, around3times wider than its visible depth, sparse around edges so existing earth ground shows between individual leaves. Entire patch complete inside very generous transparent margin, restrained natural color, no bright neon green grass carpet.')}
m=json.loads((RAW/'manifest.json').read_text('utf-8'));q=yaml.safe_load((QUEUE/'tasks.yaml').read_text('utf-8'))
import gen_assets as renderer
renderer.TEMPLATES_DIR=QUEUE/'templates'
for key,(kind,label,detail) in details.items():
    assert not any(r['key']==key for r in m['assets']);prompt=COMMON+detail;p=QUEUE/(key+'.txt');p.write_text(prompt,'utf-8')
    assert renderer.render_template('native_alpha',{'asset_prompt':prompt},{})['prompt']==prompt.strip()
    m['assets'].append({'key':key,'kind':kind,'label':label,'id':NAME+'_'+key+'_v1','prompt':p.relative_to(ROOT).as_posix(),'prompt_sha256':sha(p),'transparent':True,'calls':0,'status':'REGISTERED','model':None,'provider':None,'cost':None,'fallback_used':False})
    q['tasks'].append({'id':NAME+'_'+key+'_v1','template':'native_alpha','skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'vars':{'asset_prompt':prompt}})
save(RAW/'manifest.json',m);(QUEUE/'tasks.yaml').write_text(yaml.safe_dump(q,allow_unicode=True,sort_keys=False),'utf-8')
save(STAGE/'bank-preflight.json',{'passed':True,'new_tasks':2,'cause':'first whole-city image too sparse and creek bank too geometric','existing_sources_preserved':True})
print('Registered2 native creek-bank / ground-cover components; no old image retry')
