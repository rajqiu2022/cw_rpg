"""Audit-schema-only successor: C owner rows have source maps, not scene_path."""
from pathlib import Path
import hashlib
p=Path(__file__).with_name('prepare_yamen_performance08_ROOT32_TEXT_ONLY_NOTRUN.py')
assert hashlib.sha256(p.read_bytes()).hexdigest()=='0f0713bf6313c679e6f29dc3c1bddcc942e677c7f70c7fb51d53ada5aac18b4a'
t=p.read_text(encoding='utf-8')
a="    assert fixture['scene_path']==yamen['scene_path']and fixture['layout_path']==yamen['layout_path']"
b="    assert all(fixture[k]==old[k] and yamen['source_sha256'][fixture[k]]==old['expected_city_source_sha256'][fixture[k]] for k in ('scene_path','layout_path'))"
assert t.count(a)==1
exec(compile(t.replace(a,b,1),str(__file__)+'::text_only','exec'))
