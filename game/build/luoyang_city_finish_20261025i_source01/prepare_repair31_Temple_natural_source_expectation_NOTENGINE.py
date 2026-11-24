"""Exact same approved Temple source expression, against frozen prospective current4160 delta."""
from pathlib import Path
N=Path(__file__).resolve().parent
text=(N/'prepare_Temple_natural_source_expectation_READONLY.py').read_text()
a="stagepath=NS+'outputs/root_finish8_exact32_stage01/receipt.json';sb=(G/stagepath[6:]).read_bytes();assert sha(sb)=='37d79bce73a637c46dd9790453650a48da79cc1a521c7436fbf07f326cb6ba33';stage=json.loads(sb)\nauthority=stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'];keys=set();selectors=[]"
b="""stagepath=NS+'repair31_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json';sb=(G/stagepath[6:]).read_bytes();assert sha(sb)=='319fc714cb589608c9dc200d47d7e517abc534fc2e540073eee9f3f3b9044a98';bundle=json.loads(sb)
map_pin=bundle['maps']['expected_ch4_s2_canal_docks_true']['candidate'];map_bytes=(G/map_pin['path'][6:]).read_bytes();assert sha(map_bytes)==map_pin['sha256'];authority=json.loads(map_bytes)['source_sha256'];prospective={r['target']:r['candidate']for r in bundle['targets']};keys=set();selectors=[]"""
assert a in text;text=text.replace(a,b)
a="assert p in authority,('NO_STAGE_AUTHORITY',p);b=(G/p[6:]).read_bytes();assert sha(b)==authority[p],p;return b"
b="assert p in authority,('NO_FIXED_PROSPECTIVE_AUTHORITY',p);pin=prospective.get(p,dict(path=p,sha256=authority[p]));b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256']==authority[p],p;return b"
assert a in text;text=text.replace(a,b)
text=text.replace("selector=['nodes','expected_ch4_s2_canal_docks_true','value','source_sha256']","selector=['maps','expected_ch4_s2_canal_docks_true','candidate'],independent_expected_map=map_pin")
text=text.replace("p=N/'expected_Temple_natural_session_sources_READONLY.json'","p=N/'repair31_Temple_natural_session_sources_READONLY.json'")
exec(compile(text,str(N/'prepare_repair31_Temple_natural_source_EXPECTATION_DERIVED.py'),'exec'),{'__file__':str(N/'prepare_repair31_Temple_natural_source_EXPECTATION_DERIVED.py')})
