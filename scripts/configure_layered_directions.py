"""Author frame sockets; source pixels are not changed."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'game/build/layered_actor_20261106_lab/manifest.json'
d=json.loads(p.read_text(encoding='utf-8'))
# Per frame: original hand center, thumb/index web, weapon rotation, foot datum.
poses={
 'idle_down':([(185,380),(185,376),(186,372),(185,381)],[(191,369),(191,365),(192,361),(191,370)],[0]*4,[256,730]),
 'idle_up':([(373,375),(373,375),(374,373),(375,376)],[(368,365),(368,365),(369,363),(370,366)],[0]*4,[256,733]),
 'walk_down':([(171,379),(167,379),(161,379),(170,379)],[(177,368),(173,368),(167,368),(176,368)],[0]*4,[256,732]),
 'walk_up':([(376,380),(355,329),(359,332),(356,325)],[(371,370),(350,319),(354,322),(351,315)],[0]*4,[256,732]),
 'attack_down':([(45,158),(139,37),(394,394),(78,367)],[(44,145),(143,25),(404,382),(78,352)],[-40,-30,125,-20],[256,754]),
 'attack_up':([(365,145),(325,47),(453,366),(413,383)],[(360,133),(318,35),(461,352),(420,368)],[20,-25,120,20],[256,731]),
 'hit':([(322,355),(305,368),(289,357),(281,355)],[(329,341),(312,353),(296,343),(288,341)],[20,30,24,18],[256,725]),
 'defeat':([(266,400),(260,563),(234,672),(386,651)],[(274,385),(267,548),(240,655),(392,638)],[20,40,90,90],[256,700]),
}
for key,(hands,webs,angles,foot) in poses.items():
    frames=[]
    for i in range(4):
        frames.append({'foot':foot,'hand_center':hands[i],'grip':webs[i], 'angle':angles[i],
          'weapon_z':0 if key.endswith('_up') else 3,
          'anchor_semantics':'thumb_index_web_below_guard',
          'weapon_grips':{'seven_star_sword':[512,1120],'jinhe_duanyue_blade':[512,1045]}})
    d['clips'][key]={'texture':key,'cell':[512,768],'seconds':.24 if key.startswith('idle') else .16 if key.startswith('walk') else .18,
      'loop':key.startswith(('idle','walk')), 'frames':frames}
    if key=='defeat':
        d['clips'][key]['texture']='defeat_v3'
d['clips']['attack']['loop']=False
d['allowed_directions']=['right','left_mirrored','down','up']
d['textures']=['idle','walk','attack','sword','blade','starfx','emberfx']+[k if k!='defeat' else 'defeat_v3' for k in poses]
d['coverage']={'idle':['right','left_mirrored','down','up'],'walk':['right','left_mirrored','down','up'],
 'attack':['right','left_mirrored','down','up'],'hit':['right','left_mirrored'],'defeat':['right','left_mirrored']}
d['limitations']=['Prototype only, no formal Player/Battle adoption.','Left is mirrored; independent left/right-handed art not authored.',
 'Four keyframes per clip; not a finished eight-frame gait or polished combat timing.','Hit/defeat are side-view only; front/back explicitly unavailable.']
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
