from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 with (N/name).open('xb') as stream:stream.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
raw=(N/'overview_eight_fields10_ROOT_READY_input.json').read_bytes();assert sha(raw)=='eedc345d9567eb80bf64665833e753e0c889499def5afa7d76b9ef229239c982'
a=json.loads(raw);a['output_absolute']=(N/'overview_eight_fields11_ROOT_READY/output_ROOT_READY').as_posix()
ipin=emit('overview_eight_fields11_ROOT_READY_input.json',(json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode())
parent=(N/'overview_eight_fields10_ROOT_READY.gd').read_bytes();assert sha(parent)=='ee899f5860a4ae9c2b93afab3a4e0cda892a616131be1641bc76aeeaf149a344'
text=parent.decode();hunks=[]
def change(o,n):
 global text
 assert text.count(o)==1;text=text.replace(o,n);hunks.append({'old':o,'new':n})
change('const INPUT: String="'+NS+'overview_eight_fields10_ROOT_READY_input.json"\nconst INPUT_SHA: String="'+sha(raw)+'"\nconst SELF: String="'+NS+'overview_eight_fields10_ROOT_READY.gd"','const INPUT: String="'+ipin['path']+'"\nconst INPUT_SHA: String="'+ipin['sha256']+'"\nconst SELF: String="'+NS+'overview_eight_fields11_ROOT_READY.gd"')
change('ground.color=Color("8a8b78");ground.z_index=-30;world.add_child(ground)','ground.color=Color("8a8b78");ground.z_index=-1001;world.add_child(ground)')
back=text
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'])
assert back.encode()==parent
key=emit('overview_eight_fields11_ROOT_READY.gd',text.encode())
proof=emit('overview11_fallback_only_whole_inverse_READY.json',(json.dumps({'status':'ROOT_APPROVED_ONLY_FALLBACK_LAYER_BEHIND_REAL_BACKGROUND','key':key,'input':ipin,'parent_key_sha256':sha(parent),'hunks':hunks,'whole_byte_inverse':True,'semantic_change':'Only fallback visual ground z-30->-1001. True existing background z-1000, original118ground materials and candidate surfaces unchanged.','original10_wrong_display_preserved':True,'inherited_Estate_image':a['inherited_images']['luoyang_estate_riverside_20261021ai'],'old_parse_geometry_replay':False,'engine_calls':0,'canonical_writes':0},ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'key':key,'input':ipin,'proof':proof}))
