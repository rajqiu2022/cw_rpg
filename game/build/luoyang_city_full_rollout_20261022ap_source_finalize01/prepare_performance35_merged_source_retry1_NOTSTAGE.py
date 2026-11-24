"""NEW preparer successor; preserve first ALL22-absent assertion failure."""
import hashlib
from pathlib import Path
parent=Path(__file__).with_name('prepare_performance35_merged_source_NOTSTAGE.py')
raw=parent.read_bytes();assert hashlib.sha256(raw).hexdigest()=='58b9da495a3b5e3fae32a060e2beefcb0c010d77168a437983c62ba553473817'
old=b"('EXACT22','EXACT29'),('ALL22','ALL29'),('PATCH9_COPY13','PATCH15_COPY14')"
new=b"('EXACT22','EXACT29'),('PATCH9_COPY13','PATCH15_COPY14')"
assert raw.count(old)==1
program=raw.replace(old,new,1);assert program.replace(new,old,1)==raw
exec(compile(program,str(parent)+'::remove_absent_legacy_label_retry1','exec'),{'__file__':str(parent),'__name__':'__main__'})
