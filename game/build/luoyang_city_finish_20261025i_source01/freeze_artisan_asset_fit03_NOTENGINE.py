"""Freeze Root-approved actual-size lot adaptation; no images or runtime writes."""
from pathlib import Path
import copy,hashlib,json
HERE=Path(__file__).resolve().parent
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    raw=p.read_bytes();assert sha(raw)==h,str(p)
    return json.loads(raw)
def put(n,v):
    raw=(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
    with (HERE/n).open('xb') as stream:stream.write(raw)
    return {'path':NS+n,'sha256':sha(raw),'bytes':len(raw)}
author=read(HERE/'author_artisan_residential_block02_NOTREADY.json','b3b0cb33062ba0cbfb638ac040f262fa020851ba24374a1c3d94cc1bb0173ae0')
fits=read(HERE/'three_new_modules_fit01_SOURCE_ONLY.json','79bf0a90f693f0b7471fd49218638ba5922e6ac36df8cf69d3184aba15ff8725')
measurement_path=HERE.parent/'luoyang_city_finish_20261025i_art01/manual_building_measurements01.json'
measurement=read(measurement_path,'0cee5e32ad7a81dfaf56806a08767222d3448b3576b85a81004198d47407d8b6')
assets={r['id']:r for r in measurement['rows']}
for n,row in enumerate(author['new_asset_lots']):
    fit=fits['rows'][n]
    row.update({'lot_xywh':fit['lot_xywh'],'foot_px':fit['proposed_foot_px'],
                'max_A1_size_px':[[760,430],[770,440],[606,390]][n],
                'uniform_source_expression':fit['uniform_source_expression'],'uniform_scale_float64':fit['uniform_float64'],
                'manual_source_measurement':{'path':'res://build/luoyang_city_finish_20261025i_art01/manual_building_measurements01.json','sha256':'0cee5e32ad7a81dfaf56806a08767222d3448b3576b85a81004198d47407d8b6'},
                'source_asset_measured_raw':copy.deepcopy(assets[fit['id']]),
                'source_derived_proposed_clean_subject_A1_world_xyxy_f32':fit['cleaned_subject_A1_world_xyxy_f32'],
                'door_or_workbay_world_size_f32':fit['opening_world_size_f32'],
                'final_texture_path':None,'processed_image_and_import_pins':None,
                'geometry_base_author_status':'MISSING_EXACT_VISIBLE_GROUND_BASES; DO_NOT_USE_ROOF_OR_ALPHA_BBOX',
                'local_processing_authorization_and_execution':'PENDING_ROOT_USER_PERMISSION; raw and old candidates retained',
                'independent_QA_prior_pass':False})
    row.pop('final_scale_anchor_status',None)
author['new_asset_fit_scope']='ROOT_APPROVED_SOURCE_SIZE_ADAPTATION_ONLY_NOT_IMAGE_CLEANUP_OR_GEOMETRY_PASS'
author['independent_source_fit_model']={'path':NS+'three_new_modules_fit01_SOURCE_ONLY.json','sha256':'79bf0a90f693f0b7471fd49218638ba5922e6ac36df8cf69d3184aba15ff8725','not_independent_QA_or_actual':True}
author['remaining_new_native_publication_blockers']=['User exact cleanup/padding permission and unchanged-subject derivative receipt','Full source visible ground base polygons for all3 (kiln/forge bodies separate)','Final3 raw/import/ctex ordinary source tuples','Independent QA new-domain primitive union + NPC34x30/approach48 + affected route controls','Root sole new native publication/whole-street overview']
pin=put('author_artisan_residential_block03_NOTREADY.json',author)
lotpin=put('art_three_complete_modules03_fitted_NOTREADY.json',{'status':'ROOT_APPROVED_SOURCE_FIT_LOTS_NOT_RESOURCE_OR_GEOMETRY_ADMISSION','ready':False,'author':pin,'three':author['new_asset_lots'],'source_fit_is_not_QA_prior':True})
print(json.dumps({'author':pin,'art_lots':lotpin},ensure_ascii=False))
