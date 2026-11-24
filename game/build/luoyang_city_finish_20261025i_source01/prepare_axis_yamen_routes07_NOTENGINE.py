"""Drop only two unsafe approach prefixes; exact old true-eave routes own the starts."""
from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
p=N/'author_gate_yamen_axis06_source_routes_NOTREADY.json';oldraw=p.read_bytes();assert sha(oldraw)=='5a2ce95457fb4f6da36929b877735aea40878309e25a9042a0e33cf930092946'
old=json.loads(oldraw);new=copy.deepcopy(old);scene=new['scenes'][1];assert scene['scene_id']=='ch4_s1_luoyang_yamen'
routes={'west_archive_front':[[846,750],[846,680],[590,680]],'east_runner_house_front':[[2224,800],[2224,680],[2664,680]]};journal=[]
for i,row in enumerate(scene['new_source_routes']):
 if row['id'] in routes:
  journal.append({'pointer':['scenes',1,'new_source_routes',i,'points_px'],'old':row['points_px'],'new':routes[row['id']]});row['points_px']=routes[row['id']]
assert len(journal)==2
back=copy.deepcopy(new)
for r in journal:
 node=back
 for k in r['pointer'][:-1]:node=node[k]
 assert node[r['pointer'][-1]]==r['new'];node[r['pointer'][-1]]=r['old']
assert back==old and (json.dumps(back,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()==oldraw
raw=(json.dumps(new,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();p2=N/'author_gate_yamen_axis07_yamen_route_starts_NOTREADY.json'
with p2.open('xb') as stream:stream.write(raw)
lo=0
while lo<min(len(raw),len(oldraw)) and raw[lo]==oldraw[lo]:lo+=1
tail=0
while tail<min(len(raw),len(oldraw))-lo and raw[-1-tail]==oldraw[-1-tail]:tail+=1
before=oldraw[lo:len(oldraw)-tail];after=raw[lo:len(raw)-tail]
assert oldraw[:lo]+after+oldraw[len(oldraw)-tail:]==raw and raw[:lo]+before+raw[len(raw)-tail:]==oldraw
proof={'status':'YAMEN_TWO_ROUTE_PREFIXES_ONLY_EXACT_TYPED_WHOLE_BYTE_INVERSE','old':{'path':NS+p.name,'sha256':sha(oldraw)},'new':{'path':NS+p2.name,'sha256':sha(raw)},'journal':journal,'byte_patch':{'offset':lo,'old_hex':before.hex(),'new_hex':after.hex()},'whole_forward_inverse_verified':True,'geometry_Gate_all_routes_NPC_and_masks_unchanged':True,
 'source_rejected_old_wall_ids':['v11_yamen_west_north_780','v11_yamen_east_north_940'],
 'inherited_to_start':{'path':'res://build/luoyang_yamen_courts_20261024c_system01/author_courts_NOTREADY.json','sha256':'51582b8d281876b08989acef6d16e9216022bad34640cb7bf1c872f0cc2cf429','west_route_id':'west_true_eave_side_alley','east_route_id':'east_true_eave_side_alley','no_old_route_replay':True},'independent_QA_runtime_Physics_or_ART_credit':False}
b=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode();pp=N/'axis_yamen_route07_whole_inverse_BUILD.json'
with pp.open('xb') as stream:stream.write(b)
print(json.dumps({'author':proof['new'],'proof':{'path':NS+pp.name,'sha256':sha(b)}}))
