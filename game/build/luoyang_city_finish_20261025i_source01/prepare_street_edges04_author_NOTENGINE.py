"""Root approved exact four-wall batch: Gate DESIGN04, east DESIGN05, west DESIGN06."""
from pathlib import Path
N=Path(__file__).resolve().parent
t=(N/'prepare_street_edges05_final_design_NOTENGINE.py').read_text(encoding='utf8')
# Reuse only the reviewed original projection implementation, not its old emitted artifacts.
t=t.replace("t=t.replace(\"OUT=N/'street_edges05_BUILD02'\",\"OUT=N/'street_edges05_FINAL_BUILD01'\")","t=t.replace(\"OUT=N/'street_edges05_BUILD02'\",\"OUT=N/'street_edges04_BUILD01'\")")
anchor="design['revision05_authority']={'path':respath(revision_path),'sha256':revision_sha}"
insert=anchor+'''
west_path=G/'build/luoyang_city_finish_20261025i_art01/yamen_west_wall_unique_scale_DESIGN06_BUILD_ONLY.json'
west_sha='527af86986e4e3962901077463d1e8cca9d60a5333c1d55c3b02f8ee2a70184c'
west=jsonfile(west_path,west_sha)['one_delta']
west_lot=next(v for v in design['lots']if v['lot_id']==west['lot_id'])
assert west_lot['new_piece']['foot_px']==west['foot_px'] and west_lot['new_piece']['scale']==west['uniform_scale_before']
west_lot['new_piece']['scale']=west['uniform_scale_after']
design['lots']=[v for v in design['lots']if v['lot_id']!='EDGE04_MARKET_INN_BACK_SERVICE_COMPOUND']
design['revision06_authority']={'path':respath(west_path),'sha256':west_sha}
'''
assert t.count(anchor)==1;t=t.replace(anchor,insert)
marker="exec(compile(t,str(N/'prepare_street_edges05_final_design_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_street_edges05_final_design_DERIVED_NOTENGINE.py')})"
replacement='''t=t.replace("'new_rows':5,'new_ground_polygons':5", "'new_rows':4,'new_ground_polygons':4")
t=t.replace("'three_exact_revisions':design['revision05_authority']", "'three_exact_revisions':design['revision05_authority'],'west_exact_revision06':design['revision06_authority'],'Inn_new_return_abandoned_by_Root':True")
t=t.replace("'all_5_fixed_anchors_no_auto_repair':True", "'all_4_fixed_anchors_no_auto_repair':True,'Inn_rejection_retained_not_published':True")
'''+marker
assert t.count(marker)==1;t=t.replace(marker,replacement)
exec(compile(t,str(N/'prepare_street_edges04_author_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_street_edges04_author_DERIVED_NOTENGINE.py')})
