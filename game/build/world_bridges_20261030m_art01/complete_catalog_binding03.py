"""Complete explicitly authorized RAW source hash fields; prove aggregate 15-key delta."""
from pathlib import Path
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

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def packed(v):return json.dumps(v,ensure_ascii=False,separators=(",",":"))
def parse(s):return json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',s,re.S)[1])

baseline=(HERE/"catalog_binding03_BEFORE.html").read_bytes()
initial=parse(baseline.decode("utf-8"))
before=HTML.read_bytes();text=before.decode("utf-8");data=parse(text)
cache_before=CACHE.read_bytes()
batch=data["resources"]["records"][-19:]
pending=[r for r in batch if r.get("phase")=="raw_selected"]
assert len(pending)==5 and all(r["currentBindingSHA256"]==OLD for r in pending)
assert sum(r.get("currentBindingSHA256")==NEW for r in batch)==10
for row in pending:
    replacement=copy.deepcopy(row);replacement["currentBindingSHA256"]=NEW
    assert text.count(packed(row))==1
    text=text.replace(packed(row),packed(replacement),1)
final=parse(text);final_batch=final["resources"]["records"][-19:]
chosen=[r for r in final_batch if r.get("phase") in {"raw_selected","processed_selected","game_selected"}]
assert len(chosen)==15 and all(r["currentBindingSHA256"]==NEW for r in chosen)
discarded=[r for r in final_batch if r.get("phase")=="raw_discarded"]
assert len(discarded)==4 and all("currentBindingSHA256" not in r and r["usageCount"]==0 for r in discarded)
restored=text
for row in chosen:
    restored_row=copy.deepcopy(row);restored_row["currentBindingSHA256"]=OLD
    assert restored.count(packed(row))==1
    restored=restored.replace(packed(row),packed(restored_row),1)
assert restored.encode("utf-8")==baseline
assert final["resources"]["records"][:5234]==initial["resources"]["records"][:5234]
assert final["resources"]["summary"]==initial["resources"]["summary"]
assert {k:v for k,v in final.items() if k!="resources"}=={k:v for k,v in initial.items() if k!="resources"}
binding=ROOT/"game/art/modules/world_bridges_20261030m/bridge_bindings.json"
assert sha(binding)==NEW
assert HTML.read_bytes()==before and CACHE.read_bytes()==cache_before
HTML.write_bytes(text.encode("utf-8"))
assert CACHE.read_bytes()==cache_before
proof={"status":"FINAL03_ALL15_SELECTED_CURRENT_BINDING_KEYS_EXACTLY_SYNCHRONIZED",
       "total_keys_changed_from_original_baseline":15,"raw_selected":5,"processed_selected":5,"game_selected":5,
       "only_key_changed":"currentBindingSHA256","old":OLD,"new":NEW,
       "old5234_records_exact":True,"non_resources_payload_exact":True,
       "all_HTML_bytes_except_15_equal_length_hash_fields_exact":True,
       "four_discarded_records_unchanged_without_binding":True,"summary_counts_unchanged":True,
       "cache_sha256_unchanged":sha(CACHE),"cache_writes":0,"PNG_reads_or_writes":0,"thumbnail_reads_or_writes":0,
       "image_decodes":0,"engine_calls":0,"source_binding_readonly_sha256":sha(binding),
       "historical_first10_receipt_retained_not_rewritten":True,
       "html_sha256":sha(HTML),"initial_baseline_html_sha256":hashlib.sha256(baseline).hexdigest(),
       "updated_paths":[r["diskPath"] for r in chosen]}
target=HERE/"catalog19_binding03_FINAL_PROOF.json";assert not target.exists()
target.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"updated_total":15,"proof_sha256":sha(target),"html_sha256":sha(HTML),"cache_sha256":sha(CACHE)}))
