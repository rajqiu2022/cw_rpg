"""Preserve pre-emit retry1 TypeError; only avoid local owner-name shadowing."""
from pathlib import Path
parent=Path(__file__).with_name('review_a2_stage_and_prepare_owner_sources_retry1_READY.py')
original=parent.read_bytes();text=original.decode()
old='''            for old,new in reversed(resolved):
                assert inverse.count(new)==1;inverse=inverse.replace(new,old,1)
'''
new='''            for literal_old,literal_new in reversed(resolved):
                assert inverse.count(literal_new)==1;inverse=inverse.replace(literal_new,literal_old,1)
'''
assert text.count(old)==1;text=text.replace(old,new,1)
assert text.replace(new,old,1).encode()==original
exec(compile(text,str(parent)+'#local-index-literal-names-only','exec'),{'__file__':str(parent),'__name__':'__main__'})
