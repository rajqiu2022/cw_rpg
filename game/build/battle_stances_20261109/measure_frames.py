from pathlib import Path
from hashlib import sha256
from PIL import Image
import json
path=Path("game/art/characters/battle_stances_20261109")
# Source pixel coordinates. A stance is anchored between the planted feet.
ready={
 "ready_sword": {"height":615, "foot":[565,1258],"near":[745,492],"far":[873,369],"grip":[751,489],"angle":34,
  "fingers":[[691,488],[714,466],[743,445],[756,446],[784,463],[788,475],[777,506],[755,529],[715,535],[693,524]]},
 "ready_blade":{"height":590, "foot":[606,1261],"near":[652,591],"far":[764,438],"grip":[657,586],"angle":111,
  "fingers":[[595,569],[619,554],[642,557],[679,568],[691,590],[692,611],[674,628],[632,627],[606,605]]},
 "ready_staff":{"height":616, "foot":[730,999],"near":[565,531],"far":[1083,243],"grip":[565,531],"angle":61,
  "fingers":[[526,522],[542,501],[570,497],[594,503],[606,519],[598,540],[574,563],[545,564],[527,548]],
  "far_fingers":[[1047,238],[1059,216],[1082,207],[1104,210],[1117,228],[1116,255],[1104,275],[1072,279],[1050,264]]},
 "ready_palm":{"height":607, "foot":[571,1234],"near":[709,326],"far":[1006,325]},
}
actions={
 "attack_fist": ("punch",655,[255,734],[[222,277],[260,250],[474,205],[247,239]],[[323,175],[323,175],[324,172],[323,176]]),
 "attack_palm": ("palm",650,[252,711],[[287,198],[369,176],[468,165],[278,200]],[[338,280],[337,281],[337,282],[344,281]]),
}
data={}
for key, desc in ready.items():
 file=path/(key+".png")
 im=Image.open(file)
 a=im.getchannel("A")
 ymin,ymax=a.point(lambda v:255 if v>=128 else 0).getbbox()[1::2]
 desc["source_scale"]=round(desc.pop("height")/(ymax-ymin),7)
 desc["region"]=[0,0,*im.size]
 data[key]={"file":file.name,"sha":sha256(file.read_bytes()).hexdigest(),"size":list(im.size),"frames":[desc]}
for key,(source,desired,foot,near,far) in actions.items():
 file=path/(source+".png")
 im=Image.open(file)
 w,h=im.size
 assert w%4==0
 cell=w//4
 alpha=im.getchannel("A")
 ymin,ymax=alpha.point(lambda v:255 if v>=128 else 0).getbbox()[1::2]
 data[key]={"file":file.name,"sha":sha256(file.read_bytes()).hexdigest(),"size":[w,h],
 "frames":[{"source_scale":round(desired/(ymax-ymin),7),"region":[i*cell,0,cell,h],"foot":foot,"near":near[i],"far":far[i]} for i in range(4)]}
(path/"combat_pose_frames.json").write_text(json.dumps(data,indent=2)+"\n",encoding="utf-8")