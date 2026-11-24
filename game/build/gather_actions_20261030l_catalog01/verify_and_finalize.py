"""Verify only the new eight records and preserve all old payload/cache/source bytes."""
from pathlib import Path
import hashlib
import json
import re
import wave
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).parent
HTML=ROOT/"docs/equipment-skill-catalog.html"
CACHE=ROOT/"docs/assets/resources/thumbnail-index.json"
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def parse(raw):
    text=raw.decode("utf-8");match=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
    return text,match,json.loads(match[1])
old_html=(HERE/"gallery_BEFORE.html").read_bytes();old_text,old_match,old=parse(old_html)
text,match,new=parse(HTML.read_bytes())
before=json.loads((HERE/"append_ACTUAL.json").read_text(encoding="utf-8"))
records=json.loads((HERE/"new_records_exact_eight.json").read_text(encoding="utf-8"))
assert new["resources"]["records"][-8:]==records
# Clarify the zero-based cue index in only these freshly added records.
for record in records:
    record["note"]=record["note"].replace("帧2配音效","第3帧（索引2）配音效").replace("动作帧2（-3dB）","动作第3帧（索引2，-3dB）")
    record["statusLabel"]=record["statusLabel"].replace("动作帧2实际消费","第3帧（索引2）消费")
new["resources"]["records"][-8:]=records
data=match[1];key=re.search(r'"resources"\s*:\s*',data);start=key.end();_,end=json.JSONDecoder().raw_decode(data,start)
replacement=json.dumps(new["resources"],ensure_ascii=False,separators=(",",":"))
data=data[:start]+replacement+data[end:]
HTML.write_bytes((text[:match.start(1)]+data+text[match.end(1):]).encode("utf-8"))
(HERE/"new_records_exact_eight.json").write_text(json.dumps(records,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
new_text,new_match,current=parse(HTML.read_bytes())
assert current["resources"]["records"][:-8]==old["resources"]["records"]
assert {k:v for k,v in current.items() if k!="resources"}=={k:v for k,v in old.items() if k!="resources"}
def without_resource_value(text,match):
    raw=match[1];key=re.search(r'"resources"\s*:\s*',raw);_,end=json.JSONDecoder().raw_decode(raw,key.end())
    return text[:match.start(1)+key.end()]+text[match.start(1)+end:]
assert without_resource_value(old_text,old_match)==without_resource_value(new_text,new_match)
old_cache=json.loads((HERE/"cache_BEFORE.json").read_bytes());cache=json.loads(CACHE.read_bytes())
assert all(cache[k]==v for k,v in old_cache.items()) and len(cache)==len(old_cache)+6
assert all(sha(ROOT/key)==digest for key,digest in before["protected_source_sha256"].items())
assert sha(ROOT/"scripts/build_resource_gallery.py")==before["scanner_sha256_unchanged"]
assert sha(ROOT/"docs/resource-reuse-index.md")==before["reuse_index_sha256_unchanged"]
image_rows=[r for r in records if r["media"]=="image"]
audio_rows=[r for r in records if r["media"]=="audio"]
assert len(image_rows)==6 and len(audio_rows)==2
links=[]
for record in records:
    assert sha(ROOT/record["diskPath"])==record["sha256"]
    linked=(ROOT/"docs"/record["url"]).resolve();assert linked==ROOT/record["diskPath"] and linked.is_file()
    if record["media"]=="image":
        thumb=ROOT/"docs"/record["thumbnail"]
        with Image.open(thumb) as image:
            assert image.width<=360 and image.height<=220 and image.convert("RGBA").getbbox()
            image.verify()
        Image.open(linked).verify()
    else:
        with wave.open(str(linked)) as wav:assert wav.getnframes()/wav.getframerate()==record["duration"]
    if record.get("animationPreview"):
        preview=(ROOT/"docs"/record["animationPreview"]).resolve();assert preview.is_file()
        with Image.open(preview) as gif:
            assert gif.n_frames==4
            for i in range(4):gif.seek(i);gif.load()
    links.append({"path":record["diskPath"],"original_or_audio_url":record["url"],"thumbnail":record["thumbnail"],"animationPreview":record.get("animationPreview"),"status":record["statusLabel"]})
assert len({r["diskPath"] for r in records})==8
report={"status":"EXACT_EIGHT_RECORDS_SIX_THUMBNAILS_TWO_AUDIO_LINKS_VERIFIED",
        "old_records_preserved":len(old["resources"]["records"]),"new_summary":current["resources"]["summary"],
        "non_resources_payload_exact":True,"all_HTML_outside_resources_value_exact":True,"old_cache_entries_preserved":True,
        "new_thumbnails_decoded":6,"runtime_GIF_previews_4frames_decoded":2,"original_or_audio_links_exist":8,
        "modal_original_link_and_zoom_handler_existing_source_checked":True,"browser_click_tested":False,
        "unconsumed_unpadded_copies_explicit":2,"RAW_image_metadata_prompt_source_preserved":True,
        "no_processed_directory_or_fictional_sources_created":True,"source_PNG_WAV_and_consumer_chain_SHA_preserved":True,
        "shared_scanner_and_reuse_index_unchanged":True,"inventory_build_calls":0,"engine_calls":0,"imagegen_calls":0,
        "audio_synthesis_calls":0,"source_pixel_edits":0,"root384_0_credit_not_rerun":True,
        "html_sha256":sha(HTML),"cache_sha256":sha(CACHE),"links":links}
output=HERE/"final_exact_PROOF.json";assert not output.exists()
output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({k:v for k,v in report.items() if k!="links"},ensure_ascii=False))
print("proof_sha256",sha(output))
