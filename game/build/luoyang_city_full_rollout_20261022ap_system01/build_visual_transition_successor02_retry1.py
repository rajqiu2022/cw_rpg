"""Preserve first builder's list/dict failure and its two partial shader leaves."""
from pathlib import Path
path = Path(__file__).with_name("build_visual_transition_successor02.py")
code = path.read_text(encoding="utf-8")
old = 'OUT = ROOT / "visual_transition_successor02"'
assert code.count(old) == 1
code = code.replace(old, 'OUT = ROOT / "visual_transition_successor02_retry1"')
old = 'scene=author["scenes"]["luoyang_artisan_residential_20261022ap"]'
assert code.count(old) == 1
code = code.replace(old, 'scene=next(s for s in author["scenes"] if s["id"]=="luoyang_artisan_residential_20261022ap")')
exec(compile(code, str(path), "exec"), {"__file__":str(path),"__name__":"__main__"})
