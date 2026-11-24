"""Keep zero-output checker failure; count wires only on finite-Yamen branch."""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_DT_projection57976_source_callgraph_readonly.py');b=p.read_bytes()
assert hashlib.sha256(b).hexdigest()=='e7dcc95ec97a9cd4e2530c04ecfe1b98d5bc1c0debcc82a9204f0c3dc2d1b029'
s=b.decode();old="restore.count('_wire(')==4";new="restore[restore.index('var child: Dictionary=data.record.duplicate(true); var prior:'):].count('_wire(')==4"
assert s.count(old)==1;s=s.replace(old,new)
old='DT_projection57976_independent_source_callgraph_analysis_READY.json';new='DT_projection57976_retry1_independent_source_callgraph_analysis_READY.json'
assert s.count(old)==1;s=s.replace(old,new)
exec(compile(s,str(p),'exec'),{'__file__':str(p),'__name__':'__qa_readonly_retry1__'})
