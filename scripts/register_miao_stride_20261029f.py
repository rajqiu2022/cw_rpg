"""One targeted native stride successor; retain both weak-phase source atlases."""
import json
import yaml
from miao_town_20261029f import RAW, STAGE, QUEUE, NAME, ROOT
from build_redrock_town_20261028a import save, sha

prompt='''Use case: stylized-concept
Create ONE NEW map WALK CYCLE atlas using the two supplied character atlases ONLY as identity/clothing/style references. Do NOT copy their repeated same-stride poses. They have a known error: all walking columns use essentially the SAME open-leg pose. Correct that failure here.
Layout EXACT4COLUMNS by2ROWS, exactly8FULL BODY figures, one per equal cell, full transparent alpha0 square/landscape canvas, large empty gaps, no grid/text/labels. Top row is the ordinary indigo-headcloth MALE craft worker in reference1. Bottom row is the ordinary bun/embroidered-jacket/pleated-skirt FEMALE craft worker in reference2. SAME identity and clothes as references, no jewelry/hairstyle changes, same elevated orthographic2.5D camera, all figures face screen RIGHT in true profile. Body size and floor baseline equal within each row. Figures fill about65%cell height, not cropped.
Each row is a TRUE FOUR-PHASE RIGHTWARD WALK CYCLE, all4poses visibly different:
COLUMN1 CONTACT A: one foot FAR FORWARD to the RIGHT, the other FAR BACK LEFT, two planted feet clearly separated. NEAR arm swung BACK LEFT, far arm forward right.
COLUMN2 PASSING A: the two legs come CLOSE TOGETHER DIRECTLY UNDER THE HIPS, feet nearly SAME X, supporting leg vertical, other knee bent subtly; silhouette NARROW at the feet. Arms pass almost vertically beside body.
COLUMN3 CONTACT B: opposite contact to column1: the OTHER foot far forward right, with the NEAR ARM now swung FORWARD RIGHT and far arm BACK LEFT. Clear reversal of leg overlap and arm swing from column1. Do not reuse column1 pose.
COLUMN4 PASSING B: again legs CLOSE UNDER HIPS, supporting leg vertical and opposite foot heel lifts behind, NARROW silhouette at feet; opposite passing leg to column2, arms near vertical. DO NOT DRAW WIDE OPEN LEGS IN COLUMN2 OR4.
All heads and shoulders stay at nearly the same height, no jumping/lunging. This must visually alternate WIDE CONTACT, NARROW PASSING, OPPOSITE WIDE CONTACT, OPPOSITE NARROW PASSING. It is an animation atlas, not4nearly identical walking illustrations. Ordinary calm walking, no weapon/tool/extra props. Transparent background with no floor, shadow blob, landscape, text or extra figures. All feet/hands/skirts intact inside cells. Preserve realistic painted map style, no thick outlines.
'''
m=json.loads((RAW/'manifest.json').read_text('utf-8'));assert not any(r['key']=='side_stride' for r in m['assets'])
p=QUEUE/'side_stride.txt';p.write_text(prompt,'utf-8')
import gen_assets as renderer
renderer.TEMPLATES_DIR=QUEUE/'templates';assert renderer.render_template('native_alpha',{'asset_prompt':prompt},{})['prompt']==prompt.strip()
m['assets'].append({'key':'side_stride','kind':'npc_walk','label':'苗风山城·双居民侧向四相步态后继','id':NAME+'_side_stride_v2','prompt':p.relative_to(ROOT).as_posix(),'prompt_sha256':sha(p),'transparent':True,'calls':0,'status':'REGISTERED','model':None,'provider':None,'cost':None,'fallback_used':False})
for r in m['assets']:
    if r['key'] in ['man_walk','woman_walk']:r['animation_limitation']='侧向3跨步重复偏强，保原图；上下动态未授优质步态，巡行使用独立侧向四相后继，左向运行时镜像。'
save(RAW/'manifest.json',m)
q=json.loads('{}') if False else yaml.safe_load((QUEUE/'tasks.yaml').read_text('utf-8'))
q['tasks'].append({'id':NAME+'_side_stride_v2','template':'native_alpha','skip':True,'execution_backend':'builtin_image_gen','attempt_budget':1,'retries_allowed':False,'cli_fallback_allowed':False,'vars':{'asset_prompt':prompt}})
(QUEUE/'tasks.yaml').write_text(yaml.safe_dump(q,allow_unicode=True,sort_keys=False),'utf-8')
save(STAGE/'stride-preflight.json',{'passed':True,'registered_new_task':1,'cause':'Both native4x4 sheets repeat wide-contact profile poses','old_sources_preserved':True,'scope':'Only visible side walking cycle, no repeat of architecture generation'})
print('Registered one dual-identity side-stride successor; original phase limitations retained')
