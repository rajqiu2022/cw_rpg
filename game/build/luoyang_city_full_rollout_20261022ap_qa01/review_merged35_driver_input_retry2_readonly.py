from pathlib import Path

base = Path(__file__).with_name('review_merged35_driver_input_readonly.py')
source = base.read_text(encoding='utf-8')
wrong = '2a35f74bb0ce56a38b45e66619dde08dc12eefef9b17eb84c2070174238d455b1'
correct = '2A35F74BB0CE56A38B45E66619DDE08DC12EEFE9B17EB84C2070174238D455B1'.lower()
assert len(correct) == 64 and source.count(wrong) == 1
source = source.replace(wrong, correct)
exec(compile(source, str(base), 'exec'), {'__file__': str(base), '__name__': '__main__'})
