"""Emit a NEW apply_patch payload; no engine, PNG decode or packet access."""
import difflib
import hashlib
import json
from pathlib import Path

Q=Path(__file__).resolve().parent
G=Q.parents[1]
OLD=Q/'artisan_life_four_polygon_native_oracle01'
OUT=Q/'artisan_life_four_polygon_native_oracle_retry1'
ACT=G/'build/luoyang_city_full_rollout_20261022ap_root01/integration55/oracle_READY/output_READY/123924_88715/result.json'
def sha(b): return hashlib.sha256(b).hexdigest()
old=(OLD/'oracle_NOTREADY.gd').read_bytes()
assert sha(old)=='0fd2d3edc9c472426376e807ba0781d329170efb2f540d92b25d644f7d1f421f'
assert not OUT.exists()
actual=json.loads(ACT.read_text(encoding='utf-8-sig'))
assert actual['complete'] is False and actual['failure']=='FOUR_SOURCE_DERIVED_CLOSED_DOMAINS' and actual['PNG_decodes']==0
assert actual['checks']==42 and actual['elapsed_usec']==4886
assert all(v['sha256']==actual['source_final'][k] for k,v in actual['source_first'].items())
hunks=[
('var png_decodes: int=0\n','var png_decodes: int=0\nvar domain_diagnostics: Dictionary={}\n'),
('func inside_domain(x: int,y: int,closed: Array) -> bool:\n',
 '''func four_closed_domains_match(actual: Array,expected: Variant) -> bool:
\t# Only this fixed 4x4 JSON/native domain bridge admits numeric type spelling.
\t# No integer coercion, epsilon, storage normalization or polygon modification.
\tif actual.size()!=4 or not expected is Array or expected.size()!=4: return false
\tfor i: int in 4:
\t\tif not actual[i] is Array or not expected[i] is Array or actual[i].size()!=4 or expected[i].size()!=4: return false
\t\tfor j: int in 4:
\t\t\tvar fixed: Variant=expected[i][j]
\t\t\tif typeof(actual[i][j])!=TYPE_INT or typeof(fixed) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(fixed)): return false
\t\t\tif float(actual[i][j])!=float(fixed): return false
\treturn true
func inside_domain(x: int,y: int,closed: Array) -> bool:
'''),
('\tif not need(domains==input.domains_closed,"FOUR_SOURCE_DERIVED_CLOSED_DOMAINS"): return {}\n',
 '''\t# Preserve the native values BEFORE any domain comparison, even on failure.
\tdomain_diagnostics={"derived_native_polygons_before_domain_assert":readable.duplicate(true),"derived_native_closed_domains_before_domain_assert":domains.duplicate(true),"fixed_JSON_closed_domains_before_domain_assert":input.domains_closed.duplicate(true)}
\tif not need(four_closed_domains_match(domains,input.domains_closed),"FOUR_SOURCE_DERIVED_CLOSED_DOMAINS"): return {}
'''),
('\tvar final: Dictionary={}\n','\tresult.merge(domain_diagnostics,true)\n\tvar final: Dictionary={}\n'),
]
candidate=old
for before,after in hunks:
    a=before.encode();b=after.encode()
    assert candidate.count(a)==1
    candidate=candidate.replace(a,b,1)
inverse=candidate
for before,after in reversed(hunks):
    a=before.encode();b=after.encode()
    assert inverse.count(b)==1
    inverse=inverse.replace(b,a,1)
assert inverse==old
input_raw=(OLD/'input_NOTREADY.json').read_bytes()
project=(OLD/'project.godot').read_bytes()
assert sha(input_raw)=='d950cb216b5bb070ce8229d0e1c9ec0815e1e6dd43d92da05d790a26b057d95d'
assert json.loads(input_raw)['ready'] is False and b'const READY=false\n' in candidate
diff=''.join(difflib.unified_diff(old.decode().splitlines(True),candidate.decode().splitlines(True),fromfile='original_0FD2_oracle_NOTREADY.gd',tofile='retry1_oracle_NOTREADY.gd'))
proof={'status':'NEW_FOUR_BY_FOUR_DOMAIN_NUMERIC_BRIDGE_AND_PREFLIGHT_DIAGNOSTIC_NOT_EXECUTED','ready':False,
       'parent_script_sha256':sha(old),'candidate_script_sha256':sha(candidate),'complete_byte_inverse_sha256':sha(inverse),
       'input_sha256_unchanged':sha(input_raw),'project_godot_sha256_unchanged':sha(project),
       'source55_failure':{'path':str(ACT).replace('\\','/'),'sha256':sha(ACT.read_bytes()),'complete':False,'failure':actual['failure'],'checks':42,'elapsed_usec':4886,'PNG_decodes':0,'source_first_final_all9_same':True,'native_polygons_and_domains_not_recorded_in_original_failure':True},
       'hunks':[{'before':a,'after':b} for a,b in hunks],
       'comparison_scope':'Only four domains, each four native INT coordinates versus finite JSON INT/FLOAT; exact float numeric comparison. Source-derived coordinates are small integer image bounds, exactly representable as double. No int truncation, epsilon, generalized storage equality or normalization.',
       'diagnostics_before_assert':['all four native polygon point arrays','all four native closed domain arrays','unchanged fixed JSON domain arrays'],
       'unchanged':['READYfalse','all9 fixed source pins','allsource selection and original Vector2 expressions','declared expected domains','one fixed parent PNG decode only after domain success','8714 points/PIP bbox/black-only painting/wholeRGBA inverse','5second deadline','original source FIRSTFINAL checks','no packet/old27/route/collector/production writes'],
       'whole_function_body_inverse_except_listed_hunks':True,'old0FD2_and_Root55_failure_preserved':True,'engine_parse_PNGdecode_calls_by_QA':0,
       'runtime_cause_boundary':'The report proves only the aggregate domain comparison failed. JSON/native Array numeric type spelling is a source-level explanation, not an observed exact domain mismatch; the successor logs both before making the same fixed-domain assertion.',
       'next':'Root complete read and separate mechanical READY freeze/authorization before any unique native residual execution.'}
files={'oracle_NOTREADY.gd':candidate,'input_NOTREADY.json':input_raw,'project.godot':project,
       'complete_vs_0FD2.diff':diff.encode(),
       'whole_byte_inverse_and_scope_NOTREADY.json':(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode()}
handoff={'status':'FOUR_DOMAIN_NUMERIC_RETRY1_TEXT_ONLY_NOTREADY','ready':False,
         'project_path':str(OUT).replace('\\','/'),
         'files':{name:{'sha256':sha(raw),'bytes':len(raw)} for name,raw in files.items()},
         'candidate_lines':len(candidate.splitlines()),'actual55_failure_preserved':True,
         'only_changes':'Four exact inverse-listed hunks: diagnostic holder, fixed4x4 number comparator, native snapshots before assertion, merge snapshots on fail/success. Headers/input/output relative literals remain unchanged; the NEW project directory isolates outputs.',
         'not_claimed':'No domain match or newRGBA/count/native PASS; no geometry change or expected values obtained from observed nodes/packets/results.',
         'Root_only_next':'Read full key/input/diff, then separately authorize a NEW ready freeze. Do not run this false candidate.'}
files['handoff_NOTREADY.json']=(json.dumps(handoff,ensure_ascii=False,indent=2)+'\n').encode()
patch='*** Begin Patch\n'
for name,raw in files.items():
    patch+='*** Add File: '+str(OUT/name).replace('\\','/')+'\n'
    patch+=''.join('+'+line+'\n' for line in raw.decode().splitlines())
patch+='*** End Patch'
print(json.dumps({'patch':patch,'summary':{'script_sha256':sha(candidate),'input_sha256':sha(input_raw),'proof_sha256':sha(files['whole_byte_inverse_and_scope_NOTREADY.json']),'handoff_sha256':sha(files['handoff_NOTREADY.json']),'lines':len(candidate.splitlines()),'hunks':4,'inverse':inverse==old}}))
