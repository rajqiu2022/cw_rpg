"""NEW proof only: historical declared pins -> exact existing remaps, no engine."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def disk(p): return GAME / p.removeprefix("res://")
def ref(p): return "res://" + p.relative_to(GAME).as_posix()
def load(p): return json.loads(p.read_text(encoding="utf-8-sig"))
def matches(obj, key, ptr=""):
    out=[]
    if isinstance(obj, dict):
        for k,v in obj.items():
            at=ptr+"/"+k.replace("~","~0").replace("/","~1")
            if k==key and isinstance(v,str) and re.fullmatch("[a-f0-9]{64}",v):out.append({"pointer":at,"declared_sha256":v})
            out += matches(v,key,at)
    elif isinstance(obj,list):
        for i,v in enumerate(obj):out += matches(v,key,ptr+"/"+str(i))
    return out

historical=[
 GAME/"data/maps/luoyang_precomputed_bundle_20261018r3"/s/"manifest.json"
 for s in ("ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s3_luoyang_market","ch4_s2_canal_docks")
]+[
 GAME/"data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/manifest.json",
 HERE/"artisan_revision2/author_READY.json",
 HERE/"artisan_revision4/author_READY.json",
 HERE/"artisan_revision4/publication/53624/result.json",
 GAME/"build/luoyang_city_full_rollout_20261022ap_qa01/artisan_revision4_native_art_probe_READY.json",
 GAME/"build/luoyang_city_full_rollout_20261022ap_qa01/artisan_revision2_art_probe/97020_2602/result.json",
 HERE/"manifest_seeds/quarter_seed.json",
 GAME/"data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json",
]
loaded=[(p,load(p)) for p in historical]
manifest=GAME/"data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json"
m=load(manifest)
frozen=m["legacy_source_sha256"]|m["runtime_authority_sha256"]|m["artifacts"]
assert len(frozen)==1572
rows=[]; new_leaves={}
for png,pin in frozen.items():
    imp=png+".import"
    if not disk(imp).is_file() or imp in frozen:continue
    text=disk(imp).read_text(encoding="utf-8")
    remaps=re.findall(r'^path(?:\.[^=]+)?="(res://[^"]+)"',text,re.M)
    assert len(remaps)==1 and 'source_file="'+png+'"' in text
    ctex=remaps[0]
    assert ctex not in frozen and 'dest_files=["'+ctex+'"]' in text
    assert sha(disk(png))==pin
    histories={}
    for leaf in (png,imp,ctex):
        expected=pin if leaf==png else sha(disk(leaf))
        records=[]
        for p,j in loaded:
            declared=matches(j,leaf)
            for found in declared:
                assert found["declared_sha256"]==expected,(leaf,ref(p),found)
                records.append({"record_path":ref(p),"record_sha256":sha(p),**found})
        assert records,("no independent historical pin",leaf)
        histories[leaf]=records
        if leaf!=png:new_leaves[leaf]=expected
    rows.append({"source_png":png,"already_fixed_png_sha256":pin,
      "existing_import_path":imp,"existing_import_sha256":sha(disk(imp)),
      "declared_compiled_path":ctex,"existing_compiled_sha256":sha(disk(ctex)),
      "exact_source_file_dest_files_and_remap_agree":True,"historical_declarations":histories})
assert len(rows)==7 and len(new_leaves)==14
out={"status":"HISTORICAL_DECLARED_PIN_AND_EXACT_EXISTING_REMAP_PROOF_ONLY",
 "scope":"No live collector or actual hash map used to derive expected; existing historical files independently pin every source/import/ctex. No engine/import/geometry/canonical writes.",
 "market_parent":{"path":ref(manifest),"sha256":sha(manifest),"frozen_merged_keys":1572},
 "causal_chain":"Quarter historical raw source closure retains seven PNGs; B.source_paths includes declared legacy keys; C._transition_sources expands every declared existing .import/remap, even raw historical non-rendered PNGs. Market omitted exactly these import double-leaves.",
 "historical_credit_limit":"97020 is prior actual media first/final observation only; its art rejection remains. No claim that raw smithy/forge remains rendered by final revision4.",
 "seven_rows":rows,"fourteen_existing_leaf_pins":new_leaves,
 "no_missing_or_mismatch":True,"fourteen_leaf_addition_only_requires_source_finalizer_and_Root_deployment":True}
target=HERE/"market_fourteen_import_historical_lineage_READY.json"
assert not target.exists()
target.write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")
print(json.dumps({"path":ref(target),"sha256":sha(target),"rows":len(rows),"leaves":len(new_leaves)}))
