"""NEW review successor using actual index schema and full byte reconstruction.

Parent F500 review was prepared but not run. This is not a relaxed proof test:
reconstruct every index from its immutable parent, applying exact replacements
and sole formal bool, then require all final bytes equal the actual candidate.
"""
import hashlib
from pathlib import Path
p=Path(__file__).with_name('review_a2_stage_and_prepare_owner_sources_READY.py')
raw=p.read_bytes();assert hashlib.sha256(raw).hexdigest()=='f500562948aa0b6a1098a4cf5400da1bd975d8471fb23fe6bf77c50abd872746'
old='''            proof=actual['proofs'][ident]
            assert proof.get('whole_byte_inverse') is True or proof.get('whole_inverse') is True or proof.get('whole_parent_inverse') is True,('INDEX_INVERSE_PROOF_SCHEMA',ident,proof.keys())
            indices.append(ident)
'''
new='''            proof=actual['proofs'][ident]
            assert proof.get('disabled_to_enabled_sole_bool_whole_inverse') is True
            before=raw(inputs[n['base_input']]['path'],inputs[n['base_input']]['sha256'])
            disabled=before.decode()
            resolved=[]
            for h in n['replacements']:
                new=h['new']
                if isinstance(new,dict) and '$sha' in new:new=nodes[new['$sha']]['sha256']
                elif isinstance(new,dict) and '$pin' in new:new=inputs[new['$pin']]['sha256']
                assert isinstance(new,str) and disabled.count(h['old'])==1
                disabled=disabled.replace(h['old'],new,1);resolved.append((h['old'],new))
            assert sha(disabled.encode())==proof['disabled_sha256']
            assert disabled.count(n['disabled_literal'])==1
            enabled=disabled.replace(n['disabled_literal'],n['enabled_literal'],1)
            assert enabled.encode()==data
            inverse=disabled
            for old,new in reversed(resolved):
                assert inverse.count(new)==1;inverse=inverse.replace(new,old,1)
            assert inverse.encode()==before
            indices.append(ident)
'''
text=raw.decode();assert text.count(old)==1;text=text.replace(old,new,1)
assert text.count(new)==1 and text.replace(new,old,1).encode()==raw
exec(compile(text,str(p)+'#exact-index-byte-reconstruction','exec'),{'__file__':str(p),'__name__':'__main__'})
