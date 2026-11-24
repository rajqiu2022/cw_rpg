"""Exact schema correction: author.scenes is an Array with scene_id keys."""
from pathlib import Path
path=Path(__file__).with_name("build_visual_transition_successor02.py")
code=path.read_text(encoding="utf-8")
for old,new in [
    ('OUT = ROOT / "visual_transition_successor02"','OUT = ROOT / "visual_transition_successor02_retry2"'),
    ('scene=author["scenes"]["luoyang_artisan_residential_20261022ap"]','scene=next(s for s in author["scenes"] if s["scene_id"]=="luoyang_artisan_residential_20261022ap")'),
]:
    assert code.count(old)==1
    code=code.replace(old,new)
exec(compile(code,str(path),"exec"),{"__file__":str(path),"__name__":"__main__"})
