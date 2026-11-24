"""Only correct the preparer's duplicated-c fixture SHA transcription; zero outputs before it."""
from pathlib import Path

previous = Path(__file__).with_name('prepare_market_journey36_coordinate_version_successor_text.py')
source = previous.read_text(encoding='utf-8')
bad = '98aed550ea2313ed17c7c800845828e13bc9dfd85a06abccfe098ad9c1c398d88'
good = '98aed550ea2313ed17c7c800845828e13bc9dfd85a06abcfe098ad9c1c398d88'
assert source.count(bad) == 2
source = source.replace(bad,good)
source = source.replace("'production_changes':0,'QA_engine_calls':0}",
    "'retained_preparation_failure':'Initial preparer copied an extra c in the expected fixture digest, rejected before any output. Retry1 changes only that metadata transcription; original fixture/key untouched.', 'production_changes':0,'QA_engine_calls':0}")
exec(compile(source,str(previous)+':retry1','exec'))
