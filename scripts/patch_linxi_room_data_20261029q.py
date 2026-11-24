from linxi_entry_repair_20261029q import *
targets={
'game/data/maps/linxi_farmer_cottage_layout_v1.tres':[
('PackedVector2Array(0.170, 0.390, 0.830, 0.390, 0.860, 0.820, 0.565, 0.820, 0.565, 0.885, 0.435, 0.885, 0.435, 0.820, 0.140, 0.820)', 'PackedVector2Array(0.330, 0.360, 0.730, 0.360, 0.800, 0.700, 0.830, 0.820, 0.565, 0.820, 0.565, 0.885, 0.435, 0.885, 0.435, 0.820, 0.165, 0.820, 0.230, 0.550)'),
('"target_pos": Vector2(0.775, 0.500)','"target_pos": Vector2(0.835, 0.470)')],
'game/data/scenes/linxi_village_center.tres':[
('"npc_id": "shen_qinghe_recruit",\n\t\t"npc_name": "沈青禾",\n\t\t"pos": Vector2(0.820, 0.520)', '"npc_id": "shen_qinghe_recruit",\n\t\t"npc_name": "沈青禾",\n\t\t"pos": Vector2(0.735, 0.550)')]
}
rows=[]
for rel,edits in targets.items():
    p=ROOT/rel;raw=p.read_bytes();text=raw.decode().replace('\r\n','\n');new=text
    for old,replacement in edits:
        if new.count(old)==1:new=new.replace(old,replacement,1)
        else:assert new.count(replacement)==1,(rel,old)
    out=new.encode();backup=STAGE/'backup'/rel;backup.parent.mkdir(parents=True,exist_ok=True)
    if backup.exists():assert backup.read_bytes()==raw or raw==out
    else:backup.write_bytes(raw)
    rows.append({'path':rel,'original_sha256':sha(backup),'after_sha256':hashlib.sha256(out).hexdigest()});p.write_bytes(out)
save(STAGE/'data-changes.json',rows)
