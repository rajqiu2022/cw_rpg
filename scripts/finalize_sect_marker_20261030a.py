from sect_completion_20261030a import *
base=ROOT/'game/build/three_towns_world_20261029j_system01'
p=ROOT/'game/build/sect_completion_20261030a_system01/sect_field.gd'
mp=base/'native_sources.json';rp=base/'town_registry.gd'
backup=STAGE/'marker-before';backup.mkdir(exist_ok=False)
for f in [p,mp,rp]:shutil.copy2(f,backup/f.name)
old='\t\tfor visual in zone.get_children():\n\t\t\tif visual is CanvasItem and not visual is CollisionShape2D and not visual is CollisionPolygon2D:visual.position.y-=height'
new='\t\t# Keep the collision at ground coordinates; persist the projected arrow anchor through bob animation.\n\t\tzone.configure_marker(zone.position,_world_size,Vector2(0,-height))'
s=p.read_text('utf-8');assert old in s;s=s.replace(old,new);p.write_text(s,'utf-8')
(ROOT/'scripts/templates'/NAME/'sect_field.gd').write_text(s,'utf-8')
before=sha(mp);j=json.loads(mp.read_text('utf-8'));j['sources']['res://build/sect_completion_20261030a_system01/sect_field.gd']=sha(p);save(mp,j)
s=rp.read_text('utf-8');assert before in s;rp.write_text(s.replace(before,sha(mp)),'utf-8')
