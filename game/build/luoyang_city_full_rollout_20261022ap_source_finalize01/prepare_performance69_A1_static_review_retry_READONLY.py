"""NEW review-only successor: exact rational design identity, never GPU equality.

The preserved68 source checker failed its Python float-association equality and
wrote no output. Only that offline mathematical representation and NEW review
output filename change here; runtime candidates/hashes remain untouched.
"""
import hashlib
from pathlib import Path
parent=Path(__file__).with_name('prepare_performance68_A1_static_review_READONLY.py')
before=parent.read_bytes();assert hashlib.sha256(before).hexdigest()=='ae9610741e3a12b3c01f16bfac8c1cdd95695220e221a7c3bd15544436e89c68'
text=before.decode()
replacements=[
    ('import hashlib,json\n','import hashlib,json\nfrom fractions import Fraction\n'),
    ('local=[(point[i]-origin[i])/.25 for i in range(2)]','local=[(point[i]-origin[i])*4 for i in range(2)]'),
    ('return [local[i]/size[i]+origin[i]/(size[i]*.25)for i in range(2)]','return [Fraction(local[i],size[i])+Fraction(origin[i]*4,size[i])for i in range(2)]'),
    ("'analytic_phase_equal':True","'analytic_phase_equal':True,'exact_rational_design_calculation_not_GPU_equality':True,'preserved68_float_association_assertion_FAILURE_zero_outputs':True"),
    ('performance68_A1_047B_F1D0_independent_static_review_READY.json','performance69_A1_047B_F1D0_independent_static_review_READY.json')
]
for a,b in replacements:assert text.count(a)==1;text=text.replace(a,b,1)
inverse=text
for a,b in reversed(replacements):assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
assert inverse.encode()==before
exec(compile(text,str(parent),'exec'),{'__file__':str(parent),'__name__':'__static_review_retry69__'})
