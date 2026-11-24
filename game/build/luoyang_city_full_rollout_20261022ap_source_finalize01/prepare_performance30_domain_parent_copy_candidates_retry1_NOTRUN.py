"""NEW exact EOL recipe correction; original assertion FAIL preserved, zero outputs."""
import hashlib
from pathlib import Path
parent=Path(__file__).with_name('prepare_performance30_domain_parent_copy_candidates_NOTRUN.py')
raw=parent.read_bytes()
assert hashlib.sha256(raw).hexdigest()=='20b50d0878eacb4e908551568f6f4d7c87be2d6ad31bc776934c3c8737a92f10'
old=b'# Every original control-flow line keeps its original CRLF. Only new lines use\n# the same existing CRLF; no global normalization or formatting is performed.\ndef a(s):return s.replace(\'\\n\',\'\\r\\n\')\n'
new=b'# Actual fixed999A and9D5B sources are pure LF. Preserve those exact bytes;\n# this corrects only the failed preparer assumption, never candidate normalization.\ndef a(s):return s\n'
assert raw.count(old)==1
program=raw.replace(old,new,1)
assert program.replace(new,old,1)==raw
exec(compile(program,str(parent)+'::exact_LF_recipe_retry1','exec'),{'__file__':str(parent),'__name__':'__main__'})
