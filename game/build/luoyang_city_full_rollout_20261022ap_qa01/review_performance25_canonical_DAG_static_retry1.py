"""Keep zero-output old-schema failure; bind actual CEA7 authorization schema."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_performance25_canonical_DAG_static.py');b=p.read_bytes()
assert hashlib.sha256(b).hexdigest()=='c75a26e604b84610b5ee7f1df137f5f78bda3686022dde2ef7695752c8538222'
s=b.decode();old="and not root['stage_execution_authorized']and not root['formal_deployment_authorized']";new="and root['status']=='ROOT_APPROVES_MINIMAL_AP13_CANONICAL_B_ONLY_SOURCE_PREPARATION_NOT_STAGE_OR_DEPLOYMENT'and root['stage_or_engine_or_formal_write_authorized']is False"
assert s.count(old)==1;s=s.replace(old,new)
old='performance25_driverB717_input706C_independent_DAG_static_review_READY.json';new='performance25_driverB717_input706C_retry1_independent_DAG_static_review_READY.json'
assert s.count(old)==1;s=s.replace(old,new)
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__qa_readonly_retry1__'})
