"""Preserve first assertion-refused BUILD; use the actual existing legacy field."""
from pathlib import Path
parent=Path(__file__).with_name('prepare_finite_AP_header2_BUILD.py')
text=parent.read_text(encoding='utf8')
for a,b in [
    ("OUT=HERE/'finite_AP_header2_candidate01'","OUT=HERE/'finite_AP_header2_candidate02'"),
    ("v['runtime_authority_sha256'][AP]","v['legacy_source_sha256'][AP]"),
    ("candidate['runtime_authority_sha256'][AP]","candidate['legacy_source_sha256'][AP]"),
    ("inverse['runtime_authority_sha256'][AP]","inverse['legacy_source_sha256'][AP]"),
    ("sole_pointer=['runtime_authority_sha256',AP]","sole_pointer=['legacy_source_sha256',AP]")
]:
    assert text.count(a)==1,a
    text=text.replace(a,b)
exec(compile(text,str(parent)+'::existing_legacy_field_residual02','exec'))
