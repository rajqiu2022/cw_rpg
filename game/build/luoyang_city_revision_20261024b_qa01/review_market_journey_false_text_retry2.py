"""Narrow audit correction only: assignment '=' must exclude equality '=='."""
from pathlib import Path
import re

previous = Path(__file__).with_name('review_market_journey_false_text_retry1.py')
source = previous.read_text(encoding='utf-8')
before = '    assert forbidden not in k, forbidden'
after = '''    if forbidden == '_player().position=':
        assert re.search(r'_player\(\)\.position\s*=(?!=)', k) is None
    else:
        assert forbidden not in k, forbidden'''
assert source.count(before) == 1
source = source.replace(before, after, 1)
source = source.replace('First shell-quoted Python one-liner SyntaxError before evaluation/output; retry1 uses saved script only. No test/fixture was modified.',
    'Initial shell quote SyntaxError produced0 outputs. Retry1 text audit falsely matched position== as assignment; before emit0 outputs. Retry2 fixes only audit predicate to exclude equality. No key/fixture modified.')
exec(compile(source, str(previous) + ':retry2', 'exec'))
