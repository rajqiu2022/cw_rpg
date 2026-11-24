"""Root approved Gate DESIGN04 + exact three DESIGN05 anchors, no automatic repair."""
from pathlib import Path
N=Path(__file__).resolve().parent
t=(N/'prepare_street_edges05_BUILD_ONLY.py').read_text(encoding='utf8')
t=t.replace("OUT=N/'street_edges05_BUILD02'","OUT=N/'street_edges05_FINAL_BUILD01'")
anchor="design=jsonfile(DESIGN,DESIGN_SHA);binding=jsonfile(BIND,BIND_SHA);axis=jsonfile(AXIS,AXIS_SHA)"
insert=anchor+'''
revision_path=G/'build/luoyang_city_finish_20261025i_art01/continuous_street_edge_three_revisions_DESIGN05_SOURCE_CANDIDATE.json'
revision_sha='bf41ca4fc11bc42d659d5fb949357418f2f6d6e4a5937807243591419e26bbcc'
revision=jsonfile(revision_path,revision_sha)
for change in revision['revised_lots']:
    lot=next(v for v in design['lots']if v['lot_id']==change['lot_id']);new=change['new_piece']
    assert lot['new_piece']['id']==change['retired_proposal_only']['id']
    lot['new_piece']={**new,'scale':new['uniform_scale']}
    lot['forbidden']=change['forbidden'];lot['protected_routes_source_design05']=change['protected_routes_personally_read']
    lot.pop('explicit_corner_contact',None)
design['revision05_authority']={'path':respath(revision_path),'sha256':revision_sha}
'''
assert t.count(anchor)==1;t=t.replace(anchor,insert)
t=t.replace("'parent_actual_root_label':'377B31; Root actual source deployment, not a new observed expectation'","'parent_actual_root_label':'Root signed31 deployed53b5956a004e62a2d91eeab685cc02c5d26dad896801e86e148349327ad72612; all frozen payloads/BIND26B8 identical'" )
t=t.replace("'design_authority':{'path':respath(DESIGN),'sha256':DESIGN_SHA}","'design_authority':{'path':respath(DESIGN),'sha256':DESIGN_SHA},'three_exact_revisions':design['revision05_authority']")
exec(compile(t,str(N/'prepare_street_edges05_final_design_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_street_edges05_final_design_DERIVED_NOTENGINE.py')})
