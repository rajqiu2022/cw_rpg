"""Exact static Temple.source_paths expression against this prospective24, no collector."""
from pathlib import Path
N=Path(__file__).resolve().parent
t=(N/'prepare_repair31_Temple_natural_source_expectation_NOTENGINE.py').read_text(encoding='utf-8')
for a,b in [('repair31_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json','culture_Router_pin_repair01/unified24_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),('319fc714cb589608c9dc200d47d7e517abc534fc2e540073eee9f3f3b9044a98','85ca1a489a550bde0b410888110c77f322ef6e9f0464a45c7e407fddc2aa4976'),('repair31_Temple_natural_session_sources_READONLY.json','culture_Router_pin_repair01/expected_Temple_natural_sources_READONLY.json')]:assert a in t,a;t=t.replace(a,b)
marker='exec(compile(text,'
assert t.count(marker)==1;t=t.replace(marker,'text=text.replace("NS+p.name","NS+p.relative_to(N).as_posix()")\n'+marker)
exec(compile(t,str(N/'prepare_culture_Router_pin24_Temple_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_culture_Router_pin24_Temple_DERIVED_NOTENGINE.py')})
