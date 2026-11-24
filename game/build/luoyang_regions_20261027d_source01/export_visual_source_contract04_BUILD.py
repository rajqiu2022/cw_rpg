"""Independent exact Entry source union for the approved visual-only two views."""
from pathlib import Path
N=Path(__file__).resolve().parent
text=(N/'export_final_source_contract_BUILD.py').read_text(encoding='utf8')
old="raw = (G / pin['path'][6:]).read_bytes()"
new="raw = (N / 'visual_finish04_BUILD/region_runtime_manifest_visual_CANDIDATE.json').read_bytes() if pin['path'] == 'res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json' and pin['sha256'] == '749e8d4e3b60f87badc57fd46e21b7122da9804d1f270fe687a2cb5ddde77b3e' else (G / pin['path'][6:]).read_bytes()"
assert text.count(old)==1;text=text.replace(old,new,1)
text=text.replace('54976bb040827b1dfc4cff9103ef9c5d84841c57eec8790c803de48b3820cae6','749e8d4e3b60f87badc57fd46e21b7122da9804d1f270fe687a2cb5ddde77b3e').replace('final_bounded_source_contract_BUILD.json','final_views_source_contract04_BUILD.json')
text=text.replace("'new_geometry_validation': False, 'engine_calls': 0,","'new_geometry_validation': False, 'engine_calls': 0, 'views_only': True, 'functional_credit': '121140 gameplay and86968 Gate inherited, not replayed',")
exec(compile(text,str(N/'export_final_source_contract_BUILD.py'),'exec'),{'__file__':str(N/'export_final_source_contract_BUILD.py')})
