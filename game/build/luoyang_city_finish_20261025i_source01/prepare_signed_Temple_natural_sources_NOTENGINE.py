"""Same fixed original Temple.source_paths expression, prospective signed-IID source head."""
from pathlib import Path
N=Path(__file__).resolve().parent
t=(N/'prepare_repair31_Temple_natural_source_expectation_NOTENGINE.py').read_text(encoding='utf8')
for a,b in [('repair31_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json','temple_signed_iid_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),('319fc714cb589608c9dc200d47d7e517abc534fc2e540073eee9f3f3b9044a98','12c4fe72c45a935cf317f9d9ffcafbc6dc0c46a780964644e247928805b8be72'),('repair31_Temple_natural_session_sources_READONLY.json','temple_signed_iid_repair01/expected_Temple_natural_sources_READONLY.json')]:
 assert a in t;t=t.replace(a,b)
marker='exec(compile(text,';assert t.count(marker)==1;t=t.replace(marker,'text=text.replace("NS+p.name","NS+p.relative_to(N).as_posix()")\n'+marker)
exec(compile(t,str(N/'prepare_signed_Temple_natural_sources_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_signed_Temple_natural_sources_DERIVED_NOTENGINE.py')})
