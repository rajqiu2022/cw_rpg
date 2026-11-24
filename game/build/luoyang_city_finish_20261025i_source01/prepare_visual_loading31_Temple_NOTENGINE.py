"""Same approved static Temple natural-source expression; no collector or engine."""
from pathlib import Path
N=Path(__file__).resolve().parent
t=(N/'prepare_culture_Router_pin24_Temple_NOTENGINE.py').read_text(encoding='utf-8')
for a,b in [
 ('culture_Router_pin_repair01/unified24_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','family_visual_material_loading_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),
 ('85ca1a489a550bde0b410888110c77f322ef6e9f0464a45c7e407fddc2aa4976','75ce628d299b772f95f05065b9cb6490106130b2aaac1e26205ebe4b5f0c78ea'),
 ('culture_Router_pin_repair01/expected_Temple_natural_sources_READONLY.json','family_visual_material_loading_repair01/expected_Temple_natural_sources_READONLY.json'),
]:assert a in t,a;t=t.replace(a,b)
exec(compile(t,str(N/'prepare_visual_loading31_Temple_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_visual_loading31_Temple_DERIVED_NOTENGINE.py')})
