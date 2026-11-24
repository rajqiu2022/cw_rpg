"""Additional native components, one built-in call per distinct asset."""
from four_settlements_20261030e import *
COMMON='Use case: stylized-concept. One complete isolated native module for a semi-realistic hand-painted 2.5D Chinese wuxia RPG, elevated south-facing orthographic view with slight right depth, verticals vertical. Crisp believable natural daylight, genuine transparent alpha0 background, at least20percent empty margin all sides. Complete object, no people/text/UI, no surrounding scenery or ground island, no asset sheet. Ordinary adult door proportions. Specification: '
SPECS={
 'wood_pier':('木渡栈台','A wide rectangular LOW wooden ferry landing platform, long axis horizontal east-west, visible upper deck occupies most of object, weathered timber planks with fine grain, four stout low mooring posts at back edge and two end corners, NO railing at front edge or ends, four short support piles underneath. Width12metres, depth3metres, deck rise0.5metre, no stairs/boats/water/ropes spanning the deck. Deck top strictly one continuous walkable surface. Preserve a straight horizontal front deck edge.'),
 'willow':('临水柳树','One mature graceful Chinese weeping willow, irregular spreading pale muted-green drooping foliage with visible branching gaps, slender twisting grey-brown trunk visible down to roots, height6metres width5metres. No water, soil island or grass bed. Restrained realistic leaves, no blurred painted mass.'),
 'ferry_boat':('带篷渡船','One complete small traditional Chinese wooden passenger ferry boat seen from above/front-right, long hull horizontal east-west, warm dark timber hull with visible planks, modest curved woven-bamboo canopy over central third, open seats at both ends, one long wooden oar resting along side. Width7metres, no sail/mast/people/cargo/water/ground. Whole bow and stern visible.'),
 'repair_shed':('海埠修帆作棚','One open-sided coastal boat-repair shed, broad low weathered timber frame with pale woven reed-and-canvas pitched canopy, back wall only partial salt-grey plank boards. Three front structural posts, workbench at back holding coiled rope, folded pale canvas sail and wooden pulley. A fishing net hangs at left rear. One believable single workshop structure, width6metres height3metres, no ship, water, people, letters or ground island.')}
def prepare():
 p=RAW/'manifest.json';m=json.loads(p.read_text('utf-8'));q=STAGE/'production'
 (q/'templates/native.yaml').write_text(yaml.safe_dump({'prompt_template':'{asset_prompt}','size':'1536x1024','quality':'high','background':'transparent'}),'utf-8')
 import gen_assets as renderer
 renderer.TEMPLATES_DIR=q/'templates'
 for key,(label,detail) in SPECS.items():
  assert not any(r['key']==key for r in m['assets']);prompt=COMMON+detail
  assert renderer.render_template('native',{'asset_prompt':prompt},{})['prompt']==prompt.strip()
  f=q/(key+'.txt');f.write_text(prompt,'utf-8');m['assets'].append({'key':key,'kind':'component','label':label,'prompt':f.relative_to(ROOT).as_posix(),'prompt_sha256':sha(f),'calls':0,'status':'REGISTERED','backend':'builtin_image_gen','fallback_used':False})
 save(p,m)
if __name__=='__main__':prepare()
