"""Distinguish observed A/C ART rejection from static Garden/Estate edge risk."""
from pathlib import Path
path=Path(__file__).with_name('audit_masterplan_remaining_three_gaps01.py')
code=path.read_text(encoding='utf-8')
for old,new in [
 ('Root已明确A/C及Garden/宅园地面硬边是有限艺术缺口。','Root实际A/C地面硬边已拒；本条Garden/宅园为固定作者矩形铺装的静态衔接风险，不冒称已实看本批两图或已作新增ART结论。'),
 ("'masterplan_remaining_three_gaps_readonly_READY.json'","'masterplan_remaining_three_gaps_readonly_v2_READY.json'"),
]:
 assert code.count(old)==1
 code=code.replace(old,new)
exec(compile(code,str(path),'exec'),{'__file__':str(path),'__name__':'__main__'})
