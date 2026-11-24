"""Enumerate exact candidate EOL without Stage import/run or candidate edits."""
import hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def raw(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def fact(b):
    try:b.decode('utf-8');utf8=True
    except UnicodeDecodeError:utf8=False
    return {'bytes':len(b),'sha256':sha(b),'CRLF_count':b.count(b'\r\n'),'LF_count':b.count(b'\n'),'bare_CR_count':b.count(b'\r')-b.count(b'\r\n'),'bare_LF_count':b.count(b'\n')-b.count(b'\r\n'),'final_LF':b.endswith(b'\n'),'UTF8_BOM':b.startswith(b'\xef\xbb\xbf'),'valid_UTF8':utf8,'passes_strict_candidate_domain':bool(b)and b.endswith(b'\n')and b'\r'not in b and not b.startswith(b'\xef\xbb\xbf')and utf8}
planp=S+'performance35_merged_source_recipe/source_input_ROOT_LOCKED.json';plans='e90077daf5c95a22559b6fd82ceff31cf9974cc42be0021e4bbf2e5b1e654d6b';plan=json.loads(raw(planp,plans));pins={r['id']:r for r in plan['pinned_inputs']}
rows=[]
for r in plan['pass_through_targets']:
    if not r['target'].endswith('.gd'):continue
    b=raw(r['candidate_path'],r['candidate_sha256'])
    rows.append({'target':r['target'],'candidate_path':r['candidate_path'],'kind':'frozen_pass_through_GD','candidate':fact(b),'CR_containing_line_ordinals':[i+1 for i,line in enumerate(b.split(b'\n'))if b'\r'in line]})
for n in plan['nodes']:
    if n['kind']!='index':continue
    r=pins[n['base_input']];b=raw(r['path'],r['sha256']);text=b.decode()
    # Hash literal substitutions are exactly64 ASCII hex chars. The sole
    # bool disable/enable is transient and restores original true. No Stage
    # is needed to prove these future eight candidates' EOL unchanged.
    for h in n['replacements']:
        if h['old']=='const FORMAL_ENABLED=true':
            assert h['new']=='const FORMAL_ENABLED=false'
        else:
            assert len(h['old'])==64 and all(c in '0123456789abcdef'for c in h['old'])and isinstance(h['new'],dict)
        assert text.count(h['old'])==1
    assert n['disabled_literal']=='const FORMAL_ENABLED=false'and n['enabled_literal']=='const FORMAL_ENABLED=true'
    rows.append({'target':n['target'],'kind':'future_generated_index_EOLequivalent_to_fixed_parent','base':r,'parent_bytes':fact(b),'candidate_EOL_identity_proven_from_ASCII_only_literal_replacements':True,'candidate_final_SHA_not_invented':'Metadata final hashes were buffered and never emitted by failed Stage; no need to reconstruct them for EOL identification.'})
assert len(rows)==15
bad=[r for r in rows if not r.get('candidate',r.get('parent_bytes'))['passes_strict_candidate_domain']]
out={'status':'READONLY_EXACT15_STAGE35_CANDIDATE_EOL_IDENTIFICATION_NOT_STAGE_OR_FIX','input':{'path':planp,'sha256':plans},'rows':rows,'failed_candidate_count':len(bad),'failed_targets':[r['target']for r in bad],
 'old_fail_preserved':'Root session95129 trueexit1 at strict patch domain; no Stage outputs or formal edits. This analysis never imports Stage.',
 'apply_patch_history':'Root prior exact_two_eol_format_authorization_READY.json records actual CRLF insertion normalized to LF. Therefore do not claim literal CRLF apply_patch preservation; no new probe executed here.',
 'no_automatic_candidate_normalization':True,'engine_Stage_collector_media_hash_candidate_or_formal_writes':0}
dest=H/'performance37_stage35_candidate_EOL_READONLY.json';assert not dest.exists();blob=(json.dumps(out,ensure_ascii=False,indent=2)+'\n').encode();dest.write_bytes(blob)
print(json.dumps({'report_sha256':sha(blob),'failed':[{'target':r['target'],'candidate':r.get('candidate',r.get('parent_bytes'))}for r in bad]},indent=2))
