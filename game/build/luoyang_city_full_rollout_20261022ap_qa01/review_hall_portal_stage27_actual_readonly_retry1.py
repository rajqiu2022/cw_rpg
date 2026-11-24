"""NEW reader-only successor: support existing index $pin as well as $sha.
Original reader's KeyError('$sha') is retained; it emitted no review artifact.
No producer/spec/runtime expectation is changed.
"""
from pathlib import Path
original=Path(__file__).with_name('review_hall_portal_stage27_actual_readonly.py')
source=original.read_text(encoding='utf-8')
old="new=change['new'];new=r['nodes'][new['$sha']]['sha256'] if isinstance(new,dict) else new"
new="new=change['new'];new=(r['nodes'][new['$sha']]['sha256'] if '$sha' in new else pins[new['$pin']]['sha256']) if isinstance(new,dict) else new"
assert source.count(old)==1
source=source.replace(old,new)
exec(compile(source,str(original)+'[retry1_index_pin_selector_only]','exec'))
