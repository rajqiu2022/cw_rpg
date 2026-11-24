"""Exact new-domain subset diagnostic from approved parent solids, not an engine test."""
from pathlib import Path
import hashlib,json,struct
N=Path(__file__).resolve().parent;G=N.parents[1];OUT=N/'street_edges04_local01_NOTREADY'
def h(b):return hashlib.sha256(b).hexdigest()
def load(path,want):
    b=path.read_bytes();assert h(b)==want;return b
author_path=N/'street_edges04_BUILD01/author_five_street_edges01_NOTREADY.json'
author=json.loads(load(author_path,'e44e15872d1f5a4305cd5d21086e6ed54a6e1bca7e2f961806d7ec99570d54e5'))
fixture_path=OUT/'input_NOTREADY.json';fixture=json.loads(load(fixture_path,'92507a41674ed0148ce45ef8e3c8a289b95a8701fc8c8b1f9a07fc2817352c37'))
t=(N/'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8');scope={'struct':struct}
exec(t[t.index('class FrozenVariant:'):t.index('binding_pin=')],scope)
parents={sid:scope['FrozenVariant'](load(G/cfg['payload']['path'][6:],cfg['payload']['sha256'])).value() for sid,cfg in fixture['scenes'].items()}
def box(p):return [min(v[0] for v in p),min(v[1] for v in p),max(v[0] for v in p),max(v[1] for v in p)]
rows=[]
for lot in author['lots']:
    ground=lot['new_ground_polygon_world_f32'];bounds=box(ground);candidates=[]
    parent=parents[lot['scene_id']]
    for index,poly in enumerate(parent['effective_solids']):
        b=box(poly)
        if max(b[0],bounds[0])>min(b[2],bounds[2]) or max(b[1],bounds[1])>min(b[3],bounds[3]):continue
        rectangle=len(poly)==4 and set((p[0],p[1]) for p in poly)=={(b[0],b[1]),(b[2],b[1]),(b[2],b[3]),(b[0],b[3])}
        contained=rectangle and all(b[0]<=p[0]<=b[2] and b[1]<=p[1]<=b[3] for p in ground)
        candidates.append({'original_solid_index':index,'old_points_px':poly,'old_rect_xyxy':b,'new_true_base_fully_inside_original_rect':contained,'old_row_id':parent['parent_navigation'][index]['id'] if index<len(parent['parent_navigation']) else None})
    rows.append({'lot_id':lot['lot_id'],'scene_id':lot['scene_id'],'ground_points':ground,'new_domain':lot['closed_domain_xyxy'],'parent_payload':fixture['scenes'][lot['scene_id']]['payload'],'original_solid_AABB_intersections':candidates,'decision':'REJECT_FIXED_ANCHOR_ORIGINAL_WATER_BODY_OCCUPIED_NO_AUTO_MOVE' if any(x['new_true_base_fully_inside_original_rect'] for x in candidates) else 'NO_ORIGINAL_SOLID_AABB_INTERSECTION_COMPONENT_ONLY'})
report={'status':'SOURCE_STATIC_EXACT_NEW_BASE_SUBSET_DIAGNOSTIC_NOT_ENGINE_FAIL','rows':rows,'known_rejected_ids':[r['lot_id'] for r in rows if r['decision'].startswith('REJECT')],'original_A1_route_NPC_component_report_preserved':'res://build/luoyang_city_finish_20261025i_source01/street_edges04_local01_NOTREADY/static_preflight_READONLY.json','component_pass_is_not_full_land_support_admission':True,'Root_decision_before_READY_required':True,'CPU_script_ready':False,'no_engine_mask_raster_or_pixel_queries':True,'old_river_geometry_NPCs_portals_unchanged':True,'no_automatic_anchor_search_or_scale_changes':True,'canonical_writes':0}
raw=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode('utf8');target=OUT/'original_water_support_conflicts_READONLY.json'
with target.open('xb') as f:f.write(raw)
print(json.dumps({'path':'res://'+str(target.relative_to(G)).replace('\\','/'),'sha256':h(raw),'bytes':len(raw),'rejected':report['known_rejected_ids']}))
