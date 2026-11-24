"""Author explicit visible surfaces, not a collision or geometry oracle."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def pin(p):
 b=p.read_bytes();return {'path':'res://'+p.relative_to(G).as_posix(),'sha256':sha(b),'bytes':len(b)}
def rect(id,r,role='court_stone',tint=(1,1,1,1),**kw):return dict(id=id,rect_xywh=r,texture_role=role,tint_rgba=list(tint),repeat_period_px=[220,160],shoulder_px=14,contrast=.72,**kw)
def path(id,p,width=144,role='road_earth',tint=(1.15,1.12,1.03,1),**kw):return dict(id=id,polyline_px=p,width_px=width,texture_role=role,tint_rgba=list(tint),repeat_period_px=[240,240],shoulder_px=18,contrast=.67,**kw)
scenes={
 'ch4_s0_luoyang_gate':[
  path('main_gate_ritual_axis',[[1536,1040],[1536,1950]],312,'court_stone',(1.10,1.05,.96,1)),
  rect('west_inspection_front_court',[270,1320,760,480],tint=(1.04,1.01,.94,1)),
  rect('east_inspection_front_court',[2060,1320,780,480],tint=(1.04,1.01,.94,1)),
  path('west_waiting_service_shoulder',[[300,1480],[300,1800],[650,1800]],128),
  path('east_provision_service_shoulder',[[2030,1490],[2030,1320],[2660,1320]],128),
 ],
 'ch4_s1_luoyang_yamen':[
  path('yamen_retained_main_axis',[[1536,720],[1536,1740]],300,'court_stone',(1.08,1.03,.96,1)),
  rect('west_runner_archive_court',[330,650,750,500],tint=(1.05,1.02,.95,1)),
  rect('east_documents_court',[2200,650,700,510],tint=(1.05,1.02,.95,1)),
  path('west_public_side_alley',[[120,1240],[220,1240],[220,1180],[550,1180]],144),
  path('west_archive_route_surface',[[846,750],[846,680],[590,680]],128,'road_gravel'),
  path('east_archive_route_surface',[[2224,800],[2224,680],[2664,680]],128,'road_gravel'),
 ],
 'luoyang_artisan_residential_20261022ap':[
  rect('craft_main_working_street',[180,1190,2730,220],tint=(1.09,1.05,.95,1)),
  path('craft_east_entry',[[2816,1740],[2860,1740],[2860,1280]],176,'road_gravel'),
  rect('central_well_household_court',[1180,940,700,248],tint=(1.02,1.02,.94,1)),
  rect('woodcutting_swept_work_floor',[350,1180,540,280],'road_earth',(1.24,1.14,.94,1)),
  rect('dye_rinse_wet_court',[1940,1180,690,260],'road_stone',(.87,.94,.94,1)),
  rect('forge_open_work_front',[224,1780,795,244],'road_gravel',(1.11,1.03,.91,1)),
  rect('pottery_damp_clay_front',[1880,1770,860,254],'road_earth',(1.28,1.10,.89,1)),
  path('kitchen_household_approach',[[1100,540],[1536,540],[1536,470]],128),
  path('west_residential_lane',[[1100,1280],[1100,540],[590,540]],144,'road_gravel'),
  path('east_residential_lane',[[2040,1280],[2040,540],[2460,540]],144,'road_gravel'),
 ],
 'ch4_s4_ancient_temple':[
  path('temple_south_soil_loop',[[212.5,1225],[212.5,1200],[960,1200],[1725,1200],[1725,1225]],128,'road_gravel',(1.15,1.15,1.02,1)),
  path('temple_herb_bamboo_shoulder',[[912.5,1157.5],[212.5,1157.5],[212.5,925]],112),
  path('temple_bell_court_link',[[1150,775],[1350,775],[1650,775]],128),
 ],
 'ch4_s3_luoyang_market':[
  rect('inn_service_work_court',[180,640,770,232],tint=(1.06,1.01,.90,1)),
  path('inn_delivery_earth_shoulder',[[200,800],[560,800],[950,800]],96),
 ],
 'luoyang_estate_riverside_20261021ai':[
  rect('family_ancestral_quiet_court',[320,1730,750,170],tint=(1.08,1.07,1.00,1)),
  rect('servants_kitchen_wash_court',[2180,1660,680,160],'road_stone',(.98,1.02,.96,1)),
  path('servants_service_lane',[[2140,1820],[2460,1820],[2860,1820]],144,'road_gravel'),
 ],
 'luoyang_riverside_garden_20261022ap':[
  path('west_garden_soft_path',[[520,1520],[760,1420],[860,1260],[1000,1160]],144,'road_gravel',(1.15,1.16,.99,1)),
  path('east_garden_soft_path',[[2280,1120],[2440,1180],[2680,1340],[2780,1520]],144,'road_gravel',(1.15,1.16,.99,1)),
 ],
 'ch4_s2_canal_docks':[
  rect('booking_desk_work_court',[1040,1160,380,250],'road_stone',(.99,1.03,.97,1)),
  rect('packing_gallery_work_court',[1530,1680,650,240],'road_stone',(.99,1.03,.97,1)),
  rect('short_storage_work_court',[2280,1580,400,300],'road_gravel',(1.09,1.06,.92,1)),
  path('continuous_cargo_service_road',[[1180,1300],[1430,1300],[1430,1910],[2400,1910],[2400,1780]],144,'road_gravel',(1.10,1.08,.95,1)),
 ],
}
stage=json.loads((G/'build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json').read_text(encoding='utf8'))
authority={}
for key,node in stage['nodes'].items():
 if key.startswith('expected_'):
  for p,h in node['value']['source_sha256'].items():
   assert p not in authority or authority[p]==h;authority[p]=h
env=json.loads((G/'data/maps/luoyang_full_city_20261022ap/environment.json').read_text(encoding='utf8'))
textures={}
for role in ['court_stone','road_stone','road_earth','road_gravel']:
 p=env['assets'][role]['texture'];assert p in authority
 textures[role]={'path':p,'sha256':authority[p],'source_size':env['assets'][role]['source_size']}
value={'status':'VISIBLE_EIGHT_FIELDS_SURFACE_SOURCE_AUTHOR_NOT_GPU_OR_NAV_PASS','ready':False,'factory':pin(N/'city_purpose_surface01_NOTREADY.gd'),'shader':pin(N/'city_purpose_surface01_NOTREADY.gdshader'),'textures':textures,'scenes':scenes,'node_z_index':-3,'world_periodic_UV_no_canvas_fit':True,'all_materials_existing_imported_no_new_PNG':True,'changes_support_collision_or_mask':False,'old_25f_material_outside_new_domain_preserved':True,'new_purpose_is_drawn_by_factory_not_only_rect_labels':True}
raw=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
out=N/'eight_fields_purpose_surface01_NOTREADY.json'
with out.open('xb') as stream:stream.write(raw)
print(json.dumps({'path':'res://build/luoyang_city_finish_20261025i_source01/'+out.name,'sha256':sha(raw),'bytes':len(raw),'row_counts':{k:len(v) for k,v in scenes.items()}}))
