"""Root-authorized exact four JSON foot fields, never int/float Array equality."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent;GAME=ROOT.parent.parent
OUT=ROOT/'exact_market_artisan_resident_candidate06';OUT.mkdir(exist_ok=True)
def sha(b):return hashlib.sha256(b).hexdigest()
def rp(p):return 'res://'+str(p.relative_to(GAME)).replace('\\','/')
parent=ROOT/'exact_market_artisan_resident_candidate05/Router_exact_market_artisan_resident_READY.gd'
old=parent.read_bytes();assert sha(old)=='c670bb2a7bb7d1abd8d1aba26987454fda4ef7eed4de8da5728e41077911086d'
before=b'\tif forward.get("source_foot")!=[1100,1860] or forward.get("target_foot")!=[2816,1740] or backward.get("source_foot")!=[2816,1740] or backward.get("target_foot")!=[1100,1860]: return {}\n'
assert old.count(before)==1
after='''\t# JSON stores numeric array components as floats. Validate only these four
\t# fixed author feet structurally, then compare exact native Vector2 values.
\tfor row: Dictionary in [forward,backward]:
\t\tfor key: String in ["source_foot","target_foot"]:
\t\t\tvar pair: Variant=row.get(key)
\t\t\tif not pair is Array or pair.size()!=2: return {}
\t\t\tfor scalar: Variant in pair:
\t\t\t\tif typeof(scalar) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(scalar)): return {}
\tif Vector2(forward.source_foot[0],forward.source_foot[1])!=Vector2(1100,1860) or Vector2(forward.target_foot[0],forward.target_foot[1])!=Vector2(2816,1740) or Vector2(backward.source_foot[0],backward.source_foot[1])!=Vector2(2816,1740) or Vector2(backward.target_foot[0],backward.target_foot[1])!=Vector2(1100,1860): return {}
'''.encode()
new=old.replace(before,after,1);assert new.replace(after,before,1)==old
p=OUT/'Router_exact_market_artisan_resident_READY.gd';assert not p.exists();p.write_bytes(new)
receipt={'status':'NEW_BUILD_ONLY_ROOT_AUTHORIZED_EXACT_FOUR_JSON_FOOT_FIELDS','candidate':{'path':rp(p),'sha256':sha(new),'bytes':len(new)},'parent':{'path':rp(parent),'sha256':sha(old)},'whole_byte_inverse':True,'old':before.decode(),'new':after.decode(),'cause':'JSON.parse_string numeric Array values are floats; comparing nested numeric Arrays against integer literals can refuse an otherwise exact frozen author header. This only normalizes the comparison representation of four already-hash-bound route feet.','finite_keys':['forward.source_foot','forward.target_foot','backward.source_foot','backward.target_foot'],'exact_values':[[1100,1860],[2816,1740],[2816,1740],[1100,1860]],'guards':['Array only','exactly2 components','each scalar TYPE_INT or TYPE_FLOAT only, bool/string rejected','finite each component','exact native Vector2 equality, no epsilon/nearest/observed-current authority'],'preserved':['all route IDs/kind/source/target uniqueness and header hash','all portal/body/NAV/position values','fresh full Market SHA and original identity/metadata','paired-memory success tail','all other route branches'],'runtime_credit':False,'engine_or_canonical_write':False}
r=OUT/'handoff_READY.json';assert not r.exists();r.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'candidate':receipt['candidate'],'receipt':{'path':rp(r),'sha256':sha(r.read_bytes())}},indent=2))
