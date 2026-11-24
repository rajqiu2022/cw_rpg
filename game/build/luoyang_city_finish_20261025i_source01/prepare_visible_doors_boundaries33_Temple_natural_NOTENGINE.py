"""Original T.source_paths plus its exact new helper branch, static expression only."""
from pathlib import Path
N=Path(__file__).resolve().parent
text=(N/'prepare_Temple_natural_source_expectation_READONLY.py').read_text(encoding='utf8')
old="stagepath=NS+'outputs/root_finish8_exact32_stage01/receipt.json';sb=(G/stagepath[6:]).read_bytes();assert sha(sb)=='37d79bce73a637c46dd9790453650a48da79cc1a521c7436fbf07f326cb6ba33';stage=json.loads(sb)\nauthority=stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'];keys=set();selectors=[]"
new="""stagepath=NS+'visible_doors_boundaries33_repair01/unified33_READY02/unified32_all_candidates_and_inverse_NOT_STAGE.json';sb=(G/stagepath[6:]).read_bytes();assert sha(sb)=='7a774f70b33735ec1785920b05e0d9ad07ae89329f1d14aba9d06e3551e5478c';bundle=json.loads(sb)
map_pin=bundle['maps']['expected_ch4_s2_canal_docks_true']['candidate'];map_raw=(G/map_pin['path'][6:]).read_bytes();assert sha(map_raw)==map_pin['sha256'];authority=json.loads(map_raw)['source_sha256'];prospective={r['target']:r['candidate']for r in bundle['targets']};keys=set();selectors=[]"""
assert text.count(old)==1;text=text.replace(old,new)
old="assert p in authority,('NO_STAGE_AUTHORITY',p);b=(G/p[6:]).read_bytes();assert sha(b)==authority[p],p;return b"
new="assert p in authority,('NO_FIXED_PROSPECTIVE_AUTHORITY',p);pin=prospective.get(p,dict(path=p,sha256=authority[p]));b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256']==authority[p],p;return b"
assert text.count(old)==1;text=text.replace(old,new)
marker='# T._hash_sources hashes exactly returned paths:'
addition="""seal=json.loads((G/bundle['seal']['path'][6:]).read_bytes());assert sha((G/bundle['seal']['path'][6:]).read_bytes())==bundle['seal']['sha256']
door=seal['wing_helper'];assert tc['FINISH25I_DOORS']==door['path']and tc['FINISH25I_DOORS_SHA']==door['sha256'];fixed(door['path'])
add(*seal['wing_source_entrypoints']['temple'])
selectors.append(dict(path=T,sha256=authority[T],expression='new strict FINISH25I_DOORS path/SHA -> source_paths_for(exactTemple); helper SELF/meta/Atlas/shell3 + bell3 only; elder pair remains off'))
# T._hash_sources hashes exactly returned paths:"""
assert text.count(marker)==1;text=text.replace(marker,addition)
text=text.replace("selector=['nodes','expected_ch4_s2_canal_docks_true','value','source_sha256']","selector=['maps','expected_ch4_s2_canal_docks_true','candidate'],independent_expected_map=map_pin")
text=text.replace("p=N/'expected_Temple_natural_session_sources_READONLY.json'","p=N/'visible_doors_boundaries33_repair01/expected_Temple_natural_sources_READONLY.json'")
text=text.replace('NS+p.name','NS+p.relative_to(N).as_posix()')
exec(compile(text,str(N/'prepare_visible_doors_boundaries33_Temple_natural_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_visible_doors_boundaries33_Temple_natural_DERIVED_NOTENGINE.py')})
