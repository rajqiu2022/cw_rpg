"""Continuous mirrored UV sampling of existing native ground; no raster edits."""
import shutil
from redrock_desert_complete_20261028d import STAGE,PROJECT,ART

shader=PROJECT/ART/'ground.gdshader';archive=STAGE/'before-ground-refinement.gdshader';assert not archive.exists();shutil.copyfile(shader,archive)
text=shader.read_text('utf-8')
needle='varying vec2 p;'
assert needle in text
text=text.replace(needle,needle+'\nvec2 fold_uv(vec2 uv){return abs(fract(uv)*2.-1.);}\n',1)
for old,new in [
 ('vec3 a=texture(earth_tex,p/1450.).rgb;', 'vec3 a=mix(texture(earth_tex,fold_uv(p/1450.)).rgb,texture(earth_tex,fold_uv(p/2670.+vec2(.31,.27))).rgb,.4);'),
 ('vec3 b=texture(rock_tex,p/1850.).rgb;', 'vec3 b=texture(rock_tex,fold_uv(p/1850.)).rgb;'),
 ('texture(earth_tex,p/1450.+vec2(.31,.27)).rgb', 'texture(earth_tex,fold_uv(p/1450.+vec2(.31,.27))).rgb')]:
    assert old in text,old;text=text.replace(old,new,1)
shader.write_text(text,'utf-8')
print('Only ground sampling shader changed; native images/geometry untouched')
