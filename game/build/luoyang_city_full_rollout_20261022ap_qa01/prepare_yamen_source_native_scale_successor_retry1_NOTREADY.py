"""Only correct the original preparation tool's mistyped 65-hex pin."""
from pathlib import Path
p=Path(__file__).with_name('prepare_yamen_source_native_scale_successor_NOTREADY.py')
before='e0495e4b9409ea8c3f13bd083c36d0eeeb6ba0b768fecc42e010d1593d17ae223'
after='e0495e4b9409ea8c3f13bd083c36d0eeb6ba0b768fecc42e010d1593d17ae223'
raw=p.read_text(encoding='utf-8')
assert len(before)==65 and len(after)==64 and raw.count(before)==1
new=raw.replace(before,after)
assert new.replace(after,before)==raw
exec(compile(new,str(p),'exec'),{'__file__':str(p),'__name__':'__main__'})
