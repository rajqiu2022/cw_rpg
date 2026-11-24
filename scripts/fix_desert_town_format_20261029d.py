"""Retain first failed import; fix only leading-zero serialization in private files."""
from desert_town_20261029d import PROJECT, SCENE, STAGE
from build_redrock_town_20261028a import save, sha

rows=[]
for rel,before,after in [('project.godot','Color(.6,.45,.25,1)','Color(0.6,0.45,0.25,1.0)'),
                        (SCENE,'Color(.12,.085,.04,.92)','Color(0.12,0.085,0.04,0.92)'),
                        (SCENE,'Vector2(.9,.9)','Vector2(0.9,0.9)')]:
    p=PROJECT/rel;old=p.read_text('utf-8');assert old.count(before)==1
    digest=sha(p);p.write_text(old.replace(before,after,1),'utf-8')
    rows.append({'path':rel,'before':digest,'after':sha(p),'replacement':[before,after]})
save(STAGE/'format-fix.json',{'first_import_exit':1,'cause':'Godot text constructor requires leading zero before fraction','changes':rows,'production_written':False})
