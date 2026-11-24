"""Configure only the new private project's media for exact lossless imports."""
import hashlib
import json
from desert_town_20261029d import PROJECT, ART, STAGE
from build_redrock_town_20261028a import save

def main():
    template=(PROJECT/'art/modules/redrock_city_life_20261029a/sandstone_paving.png.import').read_text('utf-8')
    import re
    template=re.sub(r'^uid=.*\n','',template,flags=re.M)
    for p in (PROJECT/ART).glob('*.png'):
        rel=p.relative_to(PROJECT).as_posix();res='res://'+rel
        dest='res://.godot/imported/'+p.name+'-'+hashlib.md5(res.encode()).hexdigest()+'.ctex'
        text=template.replace('res://art/modules/redrock_city_life_20261029a/sandstone_paving.png',res)
        text=text.replace('res://.godot/imported/sandstone_paving.png-8840eaad3d6a73404daf5c7c5402c636.ctex',dest)
        text=text.replace('process/fix_alpha_border=true','process/fix_alpha_border=false').replace('detect_3d/compress_to=1','detect_3d/compress_to=0')
        p.with_suffix('.png.import').write_text(text,'utf-8')
    save(STAGE/'import-configuration.json',{'lossless':True,'fix_alpha_border':False,'native_RGBA_expected_exact':True,'production_project_import':False})
    print('Configured 13 private images; lossless, no alpha-border normalization')

if __name__=='__main__':main()
