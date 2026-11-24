"""Decode one immutable compiled Variant for the ART residual; no projection."""
from pathlib import Path
import hashlib, json, struct
N = Path(__file__).resolve().parent
S = N.parent / 'luoyang_city_finish_20261025i_source01'
source = (S / 'audit_finish8_render_texture_domains_READONLY.py').read_text(encoding='utf8')
scope = {'struct': struct}
exec(source[source.index('class FrozenVariant:'):source.index('binding_pin=')], scope)
path = N / 'civic_compile_output/21844/civic_region.bin'
raw = path.read_bytes()
assert hashlib.sha256(raw).hexdigest() == 'bfa4d8cb35c2811de7d700cc2603d88eabbd8d7a1ad9e6946796742ded93b3d9'
decoder = scope['FrozenVariant'](raw)
compiled = decoder.value()
assert decoder.p == len(raw) and len(compiled['render']) == 108 and len(compiled['solids']) == 131
compiled.pop('solid_cells')
compiled['READONLY_parent_sha256'] = hashlib.sha256(raw).hexdigest()
compiled['READONLY_not_recompiled_no_Field'] = True
out = N / 'civic_parent_BFA4_decoded_READONLY.json'
assert not out.exists()
out.write_bytes((json.dumps(compiled, ensure_ascii=False, indent=2, allow_nan=False) + '\n').encode())
print(json.dumps({'path': str(out), 'sha256': hashlib.sha256(out.read_bytes()).hexdigest()}))
