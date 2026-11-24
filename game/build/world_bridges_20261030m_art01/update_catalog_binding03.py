"""Replace only currentBindingSHA256 in authorized newly-added selected rows."""
from pathlib import Path
import argparse
import copy
import hashlib
import json
import re

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
HTML=ROOT/"docs/equipment-skill-catalog.html"
CACHE=ROOT/"docs/assets/resources/thumbnail-index.json"
OLD="9a5a767a8a71c80b25d44d4630e2fa4d714a446141edc4aa8592435ca3f3082e"
NEW="dccaea8832790ec437081d586be308c30133acbb592adc9ea113073b27df691d"
PINS={"game/art/modules/world_bridges_20261030m/bridge_bindings.json":NEW,
      "game/build/world_bridges_20261030m_system01/bridge_visual_patch.gd":"9462ec326bdf445dfa0f514b18767b0e043931539560b1615e4d754bfff2342d",
      "game/scripts/world/world_v15_visible_stream_20261018r.gd":"2a7bc5badced3c22b0727ccdca918c38a30d8f4437a56438bdb7c5002f324622"}

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def parse(text):
    match=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
    return json.loads(match[1])
def packed(value):return json.dumps(value,ensure_ascii=False,separators=(",",":"))

parser=argparse.ArgumentParser()
parser.add_argument("--include-raw",action="store_true",help="Use only after Root explicitly authorizes the five raw-selected indirect consumer fields")
args=parser.parse_args()
phases={"game_selected","processed_selected"}
if args.include_raw:phases.add("raw_selected")
for key,pin in PINS.items():assert sha(ROOT/key)==pin
cache_before=CACHE.read_bytes();before=HTML.read_bytes();text=before.decode("utf-8")
old=parse(text);rows=old["resources"]["records"]
assert len(rows)==5253
batch=rows[-19:]
selected=[r for r in batch if r.get("phase") in phases]
assert len(selected)==(15 if args.include_raw else 10)
assert OLD not in cache_before.decode("utf-8").lower()
expected=copy.deepcopy(old);updated=[];new_text=text
for row in selected:
    assert row["currentBindingSHA256"]==OLD
    assert row["diskPath"].startswith(("game/art/modules/world_bridges_20261030m/","assets/processed/world_bridges_20261030m/","assets/raw/world_bridges_20261030m/"))
    replacement=copy.deepcopy(row);replacement["currentBindingSHA256"]=NEW
    a=packed(row);b=packed(replacement)
    assert new_text.count(a)==1
    new_text=new_text.replace(a,b,1)
    item=next(r for r in expected["resources"]["records"][-19:] if r["diskPath"]==row["diskPath"])
    item["currentBindingSHA256"]=NEW
    updated.append({"path":row["diskPath"],"phase":row["phase"],"old":OLD,"new":NEW})
actual=parse(new_text)
assert actual==expected
assert actual["resources"]["records"][:5234]==old["resources"]["records"][:5234]
assert {k:v for k,v in actual.items() if k!="resources"}=={k:v for k,v in old.items() if k!="resources"}
restored=new_text
for row in selected:
    changed=copy.deepcopy(row);changed["currentBindingSHA256"]=NEW
    assert restored.count(packed(changed))==1
    restored=restored.replace(packed(changed),packed(row),1)
assert restored.encode("utf-8")==before
assert len(new_text.encode("utf-8"))==len(before)
assert HTML.read_bytes()==before and CACHE.read_bytes()==cache_before
backup=HERE/"catalog_binding03_BEFORE.html";assert not backup.exists();backup.write_bytes(before)
HTML.write_bytes(new_text.encode("utf-8"))
assert HTML.read_bytes()==new_text.encode("utf-8") and CACHE.read_bytes()==cache_before
for key,pin in PINS.items():assert sha(ROOT/key)==pin
untouched_raw=[r["diskPath"] for r in actual["resources"]["records"][-19:] if r.get("phase")=="raw_selected" and r.get("currentBindingSHA256")==OLD]
proof={"status":"ONLY_AUTHORIZED_CURRENT_BINDING_FIELDS_UPDATED_FINAL03","updated_records":len(updated),
       "updated":updated,"old5234_records_exact":True,"non_resources_payload_exact":True,
       "all_HTML_bytes_except_listed_equal_length_hash_fields_exact":True,
       "summary_counts_no_change":actual["resources"]["summary"]==old["resources"]["summary"],
       "cache_sha256_unchanged":sha(CACHE),"cache_or_thumbnail_writes":0,"PNG_reads_or_writes":0,
       "image_decodes":0,"engine_calls":0,"current_source_pins_readonly_verified":PINS,
       "unmodified_raw_selected_old_binding_fields":untouched_raw,
       "historical_receipts_not_rewritten":True,"html_sha256":sha(HTML),"before_html_sha256":hashlib.sha256(before).hexdigest()}
target=HERE/"catalog19_binding03_PROOF.json";assert not target.exists()
target.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"updated_records":len(updated),"unmodified_raw_fields":len(untouched_raw),"proof_sha256":sha(target),"html_sha256":sha(HTML),"cache_sha256":sha(CACHE)}))
