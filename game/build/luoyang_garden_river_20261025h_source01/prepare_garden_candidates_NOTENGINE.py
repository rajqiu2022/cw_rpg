"""Mechanical new-namespace author and immutable parent capture. No engine/import."""
from pathlib import Path
from PIL import Image
import copy, hashlib, json

GAME = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
RES = 'res://build/luoyang_garden_river_20261025h_source01/'
PARENT = 'res://build/luoyang_city_full_rollout_20261022ap_system01/garden_revision4/shore_landing_retry2/'
STAGE = 'res://build/luoyang_city_revision_20261025g_source01/outputs/root_market_courtyard45_exact32_stage02/receipt.json'
STAGE_SHA = 'c972f71442cc6573d8e55a92bf0ce875039879be651dd30e3fd32df585d97396'
PNG = 'res://art/modules/world_map_v13/bridge_stone_eastwest_v1.png'
BRIDGE = {
 PNG:'da0447906b4dddfa819cfdccd6dd9fe0a7c18be6e15dca9995661f01b46739be',
 PNG+'.import':'13bdd18c366a6fc48d6751757d39433ade962e6422b24be23dd667a5b62248ef',
 'res://.godot/imported/bridge_stone_eastwest_v1.png-0998f3b4f19020d7c304ba512c851a24.ctex':'48d14a4b8a21ee51cf37dfeafd6e895be263e4355ab5f89a83f39d733fadb5a4'
}
def path(p):
 assert p.startswith('res://') and '..' not in p
 return GAME / p[6:]
def sha(b): return hashlib.sha256(b).hexdigest()
def read(p, expected=None):
 b=path(p).read_bytes()
 if expected: assert sha(b)==expected.lower(), p
 return b
def write(name, b):
 p=OUT/name
 assert not p.exists(), p
 p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb') as f: f.write(b)
 return {'path':RES+name,'sha256':sha(b),'bytes':len(b)}
def dump(name,v): return write(name,(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())

def main():
 stage=json.loads(read(STAGE,STAGE_SHA))
 fixed=stage['source_first']
 parent_bytes=read(PARENT+'author_READY.json','937320f2e24d159e0dc5b023d72222be4118fb4e6d90e9558fa3cfba4ae55dfe')
 author=json.loads(parent_bytes)
 before=copy.deepcopy(author)
 donor_path='res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision4/author_READY.json'
 donor=json.loads(read(donor_path,fixed[donor_path]))
 tea=copy.deepcopy(donor['assets']['woodwork_chinese_v3'])
 assert tea['door_lower_px']==163 and tea['used_rect']==[4,17,1029,645]
 tea['provenance']='Complete existing two-storey shell reused as riverside tea-house exterior only; no new room or interaction.'
 author['status']='SOURCE_BOUND_GARDEN_RIVER_CANDIDATE_NOT_RUNTIME'
 author['assets'].pop('bridge')
 author['assets']['tea_house']=tea
 for p,h in BRIDGE.items(): read(p,h); author['source_sha256'][p]=h
 for p,h in fixed.items():
  if p==tea['texture'] or p==tea['texture']+'.import' or ('north_market_front.png-' in p and p.endswith('.ctex')):
   read(p,h); author['source_sha256'][p]=h
 im=Image.open(path(PNG)).convert('RGBA')
 assert im.size==(1774,887)
 alpha=im.getchannel('A')
 assert alpha.getbbox()==(0,0,1761,800)
 # Full closed source deck, not merely four vertices. No source pixel edit.
 deck=[48,298,1670,224]
 extrema=alpha.crop((48,298,1719,523)).getextrema()
 assert extrema[0]>=250
 author['assets']['stone_bridge']={
  'texture':PNG,'source_size':[1774,887],'used_rect':[0,0,1761,800],
  'ground_anchor':[887,443.5],
  'solid_rects':[[200,276,1374,22],[200,522,1374,120]],
  'support_rects':[deck],
  'source_full_deck_alpha_min':extrema[0],
  'source_deck_measurement':'Manual visible stone deck; every closed source pixel alpha>=250; Root geometric/visible validation remains required.'
 }
 data=author['scenes'][0]
 assert data['scene_id']=='luoyang_riverside_garden_20261022ap'
 data.pop('scenic_bridge_no_walk_support')
 data['river_bridge_walk_support']=True
 data['water_polygons']=[[[1248,0],[1824,0],[1824,700],[1940,820],[2072,960],[2096,1080],[2180,1180],[2090,1360],[2000,1480],[1240,1472],[1184,1432],[1168,1300],[992,1250],[936,1100],[1056,960],[1248,800]]]
 placements=[]
 for row in data['placements']:
  if row['id']=='ap_curved_bridge_scenic': continue
  if row['id']=='ap_river_pavilion': row['foot']=[760,760]
  placements.append(row)
 placements += [
  {'id':'garden_stone_bridge_walkable_25h','asset':'stone_bridge','foot':[1536,1000],'width':1232.7,'uniform_scale':0.7,'ground_layer_only':True,'purpose':'Complete unchanged bridge image below actors; source front rail is an exact original-canvas native AtlasTexture foreground row.'},
  {'id':'garden_riverside_tea_house_25h','asset':'tea_house','foot':[2520,650],'width':820,'purpose':'Complete two-storey riverside tea-house exterior, no new room entrance or service claim.'}
 ]
 data['placements']=placements
 data['ground_sections']=[r for r in data['ground_sections'] if r['id'] not in ['ap_garden_north_walk','ap_pavilion_forecourt']]
 data['ground_sections'] += [
  {'id':'garden_west_pavilion_court_25h','asset':'stone','rect':[384,640,768,512],'tile_size':[384,256],'z':-20,'clip_textures':{}},
  {'id':'garden_east_tea_court_25h','asset':'stone','rect':[2304,640,384,512],'tile_size':[384,256],'z':-20,'clip_textures':{}},
  {'id':'garden_bridge_west_approach_25h','asset':'stone','rect':[768,896,384,256],'tile_size':[384,256],'z':-20,'clip_textures':{}},
  {'id':'garden_bridge_east_approach_25h','asset':'stone','rect':[1920,896,384,256],'tile_size':[384,256],'z':-20,'clip_textures':{}}
 ]
 # These paths are proposals to be checked against this Garden's new body/mask.
 data['routes']=[
  {'id':'public_riverside','points':[[256,1680],[2816,1680],[2816,1740]]},
  {'id':'public_garden_loop','points':[[576,1664],[576,976],[880,976],[2192,976],[2496,976],[2496,1664],[576,1664]]},
  {'id':'pavilion_approach','points':[[576,976],[760,976],[760,760]]},
  {'id':'tea_house_forecourt','points':[[2496,976],[2520,976],[2520,720]]},
  {'id':'west_shore_view','points':[[768,1664],[768,1420],[1056,1420],[1056,1390]]},
  {'id':'east_shore_view','points':[[2496,1664],[2496,1480],[2496,1420]]}
 ]
 author['adult_doors'].append({'placement_id':'garden_riverside_tea_house_25h','asset_id':'tea_house','source_clear_height_px':163,'source_A1_width_px':1029,'minimum_world_clear':128,'portal_exemption':False})
 author['native_root']=RES+'publication01/output/native/'
 author['bridge_contract']={
  'visual_polygon':data['water_polygons'][0], 'deck_source_rect':deck,
  'source_size':[1774,887],'bridge_center':[1536,1000],'uniform_scale':0.7,
  'front_region_source_rect':[200,522,1374,208],
  'front_region_depth_source_y':680,
  'raw_png':{'path':PNG,'sha256':BRIDGE[PNG]},
  'minimum_body_center_clearance':128,
  'water_physics':'Exact water polygon minus visible closed deck, same pieces for mask and native bodies. Visual water stays continuous beneath whole bridge.',
  'raw_import_direct_texture_validation':'Existing imported tuple must preserve full alpha and RGBA for every raw alpha>=250 pixel; record all whole RGBA hashes separately, never claim full equality when hidden RGB differs.',
  'candidate_only':True
 }
 author['root_scenic_bridge_successor']={'historical_parent_only':before['root_scenic_bridge_successor'],'not_inherited_as_traversable_credit':True}
 author['scope']='25h Garden only: north river bay, one real bridge, moved complete pavilion and one complete two-storey tea-house exterior. Original southern route/two reciprocal portals/four original NPCs remain.'
 parent_leaves={}
 for p in ['res://scripts/city/luoyang_quarters_family_20261022ap.gd','res://scripts/city/luoyang_quarters_native_geometry_20261022ap.gd']:
  parent_leaves[p]=write('parents/'+Path(p).name,read(p,fixed[p]))
 author_doc=dump('author_river_bridge_NOTREADY.json',author)
 delta={k:{'old':before.get(k),'new':author.get(k)} for k in author.keys()|before.keys() if before.get(k)!=author.get(k)}
 inverse=copy.deepcopy(author)
 for k,d in delta.items():
  if k in before: inverse[k]=d['old']
  else: inverse.pop(k,None)
 assert inverse==before
 proof=dump('author_source_delta_and_parent_capture_NOT_RUNTIME.json',{
  'status':'AUTHOR_FULL_TYPED_INVERSE_TRUE_NOT_NATIVE_OR_PIXEL_PRIOR','author':author_doc,
  'parent_author':{'path':PARENT+'author_READY.json','sha256':sha(parent_bytes)},
  'parent_stage':{'path':STAGE,'sha256':STAGE_SHA},'delta':delta,'whole_typed_inverse':inverse==before,
  'new_bridge_exact_source_alpha':{'closed_rect':deck,'pixels':1671*225,'alpha_min':extrema[0],'alpha_max':extrema[1]},
  'formal_parent_captures':parent_leaves,'engine':0,'canonical_writes':0})
 print(json.dumps({'author':author_doc,'proof':proof,'engine':0}))

if __name__=='__main__': main()
