"""NEW byte-exact publisher preparation; preserve unexecuted epoch02 and failures.

Fixes only preparation Dictionary/node API, solid-vs-visual count, original
JSON scalar types in clerk inverse, complete source-NPC impact checks, and
generated-file EOL preservation. No Godot/native or PNG decode.
"""
from pathlib import Path
import hashlib
root=Path(__file__).resolve().parent
original=root/'prepare_finite_two_domain_publication_epoch02.py'
before=original.read_bytes()
assert hashlib.sha256(before).hexdigest()=='5081891c9b7de22b7a92d269739ecd137b8960a86d9a0d8da02c14b3442a42ea'
old_template=root/'finite_two_domain_publication_epoch02/publisher_template_NOTEXEC.gd'
template_bytes=old_template.read_bytes()
assert hashlib.sha256(template_bytes).hexdigest()=='948518352e52f065daef6e5f535a89329dc8a0743579654b6b03c0fe4eb7e52c'
epoch=root/'finite_two_domain_publication_epoch03'
epoch.mkdir(exist_ok=False)
template=template_bytes.decode('utf-8')
assert template.count('finite_two_domain_publication_epoch02')==2
template=template.replace('finite_two_domain_publication_epoch02','finite_two_domain_publication_epoch03')
old='\tvar altered: Dictionary=clerk.apply_clerk_foot(config.district_author)'
new='\tvar original_clerk_pair: Array=[]\n\tfor row: Dictionary in config.district_author.districts[spec.scene_id].crowd:\n\t\tif row.id=="yamen_clerk": original_clerk_pair=row.foot_px.duplicate()\n\tvar altered: Dictionary=clerk.apply_clerk_foot(config.district_author)'
assert template.count(old)==1
template=template.replace(old,new)
old='clerk.inverse_clerk_foot(altered,[1260,1500])'
assert template.count(old)==1
template=template.replace(old,'clerk.inverse_clerk_foot(altered,original_clerk_pair)')
old='\tvar finite_paths: Array=proposal.static_routes.duplicate(true)'
new='\tif not require(api.equal(parent.packet.record.gameplay_slots.npcs,spec.source_native_npc_stations),"YAMEN_EXACT_THREE_NATIVE_SOURCE_NPC_ANCHORS"): return {}\n\tvar finite_paths: Array=proposal.static_routes.duplicate(true)\n\tfor row: Dictionary in spec.source_native_npc_stations:\n\t\tfinite_paths.append({"id":"unchanged_native_source_npc_anchor:"+String(row.source_id),"npc":true,"points_px":[row.foot_px,row.foot_px],"source_foot_only_not_actor_spawn_or_visibility_claim":true})'
assert template.count(old)==1
template=template.replace(old,new)
new_template=epoch/'publisher_template_NOTEXEC.gd'
new_template.write_bytes(template.encode('utf-8'))
text=before.decode('utf-8')
changes=[
    ("EPOCH=ROOT/'finite_two_domain_publication_epoch02'","EPOCH=ROOT/'finite_two_domain_publication_epoch03'"),
    ("finite_two_domain_publication_epoch02/output/","finite_two_domain_publication_epoch03/output/"),
    ("    assert res(p) in declared_stage['source_final'] or any(res(p)==r.get('path') for r in declared_stage.get('nodes',[])) or p.exists()", "    declared_node=declared_stage['nodes']['expected_'+scene+'_true']\n    assert declared_node['path']==res(p) and declared_node['sha256']==sha(p)\n    assert declared_node['value']==load(p)"),
    ("('ch4_s3_luoyang_market',44,32)","('ch4_s3_luoyang_market',44,31)"),
    ("yamen['local_mask_domains_px']=domains", "yamen['local_mask_domains_px']=domains\nyamen['source_native_npc_stations']=copy.deepcopy(load(path(native_parent['path']))['record']['gameplay_slots']['npcs'])\nassert len(yamen['source_native_npc_stations'])==3"),
    ("ready.write_text(text,encoding='utf-8')", "ready.write_bytes(text.encode('utf-8'))\nassert ready.read_bytes().replace(b'const READY=true',b'const READY=false',1).replace(input_pin['sha256'].encode(),b'@INPUT_SHA@',1)==template.read_bytes()"),
    ("'whole_city_art_pass':False}", "'whole_city_art_pass':False,'ready_template_exact_whole_byte_inverse':True,'prior_unexecuted_epoch02_handoff':pin(ROOT/'finite_two_domain_publication_epoch02/handoff_READY.json')}")
]
for old,new in changes:
    assert text.count(old)==1,old
    text=text.replace(old,new)
exec(compile(text,str(original),'exec'),{'__file__':str(Path(__file__)),'__name__':'__main__'})
assert original.read_bytes()==before and old_template.read_bytes()==template_bytes
