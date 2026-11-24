"""Preserve initial preparer zero-output assertion failure; literal-space typo only."""
from pathlib import Path
import hashlib
p=Path(__file__).with_name('prepare_current_eight_native_ratio_fixture_text.py')
assert hashlib.sha256(p.read_bytes()).hexdigest()=='3cb2cec00f5ec3f5e78ab9244fae2f6699c53be4039cb6ad7e8e237ac2c9259b'
text=p.read_text(encoding='utf-8')
before="assert 'const LIFE_READY=true' in family.replace(' ','')"
after="assert 'constLIFE_READY=true' in family.replace(' ','')"
assert text.count(before)==1
exec(compile(text.replace(before,after,1),str(p)+'::retry1_literal_only','exec'))
