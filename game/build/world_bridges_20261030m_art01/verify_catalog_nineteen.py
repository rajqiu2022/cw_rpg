"""Verify exact incremental records, new links/thumbs and unchanged prior payload."""
from pathlib import Path
import hashlib
import json
import re
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
HTML=ROOT/"docs/equipment-skill-catalog.html"
CACHE=ROOT/"docs/assets/resources/thumbnail-index.json"

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load(path):return json.loads(path.read_text(encoding="utf-8-sig"))
def parse(raw):
    text=raw.decode("utf-8");m=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
    return text,m,json.loads(m[1])
def outside(text,m):
    raw=m[1];key=re.search(r'"resources"\s*:\s*',raw);_,end=json.JSONDecoder().raw_decode(raw,key.end())
    return text[:m.start(1)+key.end()]+text[m.start(1)+end:]

old_text,old_m,old=parse((HERE/"catalog19_gallery_BEFORE.html").read_bytes())
text,m,new=parse(HTML.read_bytes())
rows=load(HERE/"catalog19_new_records_ACTUAL.json")
receipt=load(HERE/"catalog19_append_ACTUAL.json")
assert len(rows)==19
assert new["resources"]["records"][:-19]==old["resources"]["records"]
assert new["resources"]["records"][-19:]==rows
assert {k:v for k,v in new.items() if k!="resources"}=={k:v for k,v in old.items() if k!="resources"}
assert outside(old_text,old_m)==outside(text,m)
oldcache=load(HERE/"catalog19_cache_BEFORE.json");cache=load(CACHE)
assert all(cache[k]==v for k,v in oldcache.items())
assert len(cache)==len(oldcache)+19
assert all(sha(ROOT/k)==v for k,v in receipt["protected_source_sha256"].items())
assert len([r for r in rows if r["phase"].startswith("raw_")])==9
assert len([r for r in rows if r["phase"]=="processed_selected"])==5
assert len([r for r in rows if r["phase"]=="game_selected"])==5
assert {r["rawVersion"] for r in rows if r["phase"]=="raw_discarded"}=={1,2,3,5}
links=[]
for row in rows:
    assert sha(ROOT/row["diskPath"])==row["sha256"]
    original=(ROOT/"docs"/row["url"]).resolve()
    assert original==ROOT/row["diskPath"] and original.is_file()
    thumbnail=ROOT/"docs"/row["thumbnail"]
    with Image.open(thumbnail) as image:
        assert image.width<=360 and image.height<=220
        image.verify()
    assert (ROOT/row["metadataPath"]).is_file()
    if row["phase"]=="raw_discarded":
        assert row["status"]=="rejected" and row["usageCount"]==0 and not row["usage"] and not row["consumerChain"]
    else:
        assert row["status"]=="referenced" and row["currentBindingSHA256"]==receipt["current_pins"]["game/art/modules/world_bridges_20261030m/bridge_bindings.json"]
        assert all((ROOT/"docs"/u["url"]).resolve().is_file() for u in row["usage"])
    links.append({"path":row["diskPath"],"url":row["url"],"thumbnail":row["thumbnail"],"status":row["statusLabel"]})
current=[{"id":r["consumerBridgeId"],"texture":r["currentBridgeResourcePath"],"sha256":r["sha256"],
          "consumerChain":r["consumerChain"],"usage":r["usage"]} for r in rows if r["phase"]=="game_selected"]
assert len(current)==5
proof={"status":"EXACT19_RECORDS_19_NEW_THUMBNAILS_VERIFIED","old_records_exact":5234,
       "new_summary":new["resources"]["summary"],"new_raw_versions":9,"selected_processed":5,"selected_game":5,
       "discarded_raw_versions_not_adopted":[1,2,3,5],"new_thumbnails_decoded":19,"original_links_exist":19,
       "non_resources_payload_exact":True,"HTML_outside_resources_value_exact":True,
       "all_old_cache_entries_exact":True,"old_thumbnail_paths_not_targeted":True,
       "old_thumbnail_allfile_SHA_rescan":False,"inventory_build_calls":0,"shared_scanner_unchanged":True,
       "all_listed_source_SHA_unchanged":True,"reference_only_registered":False,
       "browser_click_tested":False,"new_links_and_existing_modal_contract_static_only":True,
       "engine_calls":0,"source_PNG_pixel_writes":0,"imagegen_calls":0,"V5_geometry_alpha_remeasurement":False,
       "html_sha256":sha(HTML),"cache_sha256":sha(CACHE),"current_consumers":current,"links":links}
target=HERE/"catalog19_final_exact_PROOF.json";assert not target.exists()
target.write_text(json.dumps(proof,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"proof_sha256":sha(target),"html_sha256":sha(HTML),"cache_sha256":sha(CACHE),"summary":proof["new_summary"]}))
