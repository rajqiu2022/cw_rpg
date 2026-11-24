"""Correct sample pitch maps from independent measurements; preserve first attempt.

Uses the frozen original score and sample renderer, with a NEW verified source map.
No music-generation model, no changes to first audio, score, source or MIDI files.
"""
from pathlib import Path
import argparse
import concurrent.futures
import hashlib
import importlib.util
import json
import subprocess
import urllib.request
import urllib.parse

ROOT=Path(__file__).resolve().parents[2]
RAW=ROOT/"assets/raw/audio/wuxia_original_trial_v2_20261009"
OUT=ROOT/"assets/processed/audio/wuxia_original_trial_v2_20261009"
OLD_RAW=ROOT/"assets/raw/audio/wuxia_original_trial_20261009"
KERNEL=Path(__file__).with_name("compose_wuxia_original_trial.py")
spec=importlib.util.spec_from_file_location("frozen_original_composer",KERNEL)
composer=importlib.util.module_from_spec(spec);spec.loader.exec_module(composer)
NEW=[
    {"id":"dan_low_F#2","repo_path":"Chordophones/Zithers/Dan Tranh/Normal/F#2_mf_1.wav","style":"pluck","expected_measured_midi":54},
    {"id":"dan_low_G#2","repo_path":"Chordophones/Zithers/Dan Tranh/Normal/G#2_mf_1.wav","style":"pluck","expected_measured_midi":56},
    {"id":"dan_low_b2","repo_path":"Chordophones/Zithers/Dan Tranh/Normal/b2_mf_1.wav","style":"pluck","expected_measured_midi":59},
    {"id":"dan_trem_low_B2","repo_path":"Chordophones/Zithers/Dan Tranh/Tremolo/B2_Trem_1.wav","style":"tremolo","expected_measured_midi":59},
    {"id":"dan_trem_low_C#3","repo_path":"Chordophones/Zithers/Dan Tranh/Tremolo/C#3_Trem_1.wav","style":"tremolo","expected_measured_midi":61}
]


def prepare():
    RAW.mkdir(parents=True,exist_ok=True)
    tree=subprocess.check_output(["git","-C",str(composer.VCSL),"ls-tree","-r","-z","HEAD"])
    hashes={entry.split(b"\t",1)[1].decode():entry.split(b"\t",1)[0].split()[2].decode() for entry in tree.split(b"\0") if entry}
    def fetch(item):
        path=RAW/"samples/vcsl"/item["repo_path"];path.parent.mkdir(parents=True,exist_ok=True)
        if not path.exists():
            with urllib.request.urlopen(composer.BASE+urllib.parse.quote(item["repo_path"]),timeout=60) as r:data=r.read()
            got=hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
            if got!=hashes[item["repo_path"]]:raise ValueError("Official blob mismatch")
            path.write_bytes(data)
        data=path.read_bytes();blob=hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
        if blob!=hashes[item["repo_path"]]:raise ValueError("Existing blob changed")
        return {**item,**composer.info(path),"git_blob_sha1":blob,"url":composer.BASE+urllib.parse.quote(item["repo_path"]),
                "instrument":"dan_tranh","actual_instrument":"Vietnamese đàn tranh zither","license":"CC0-1.0","pitch_measurement_status":"PENDING_INDEPENDENT_QA"}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:records=list(pool.map(fetch,NEW))
    target=RAW/"new_sample_sources_v2_pending_pitch.json"
    target.write_text(json.dumps({"records":records,"source_commit":composer.REV},indent=2,ensure_ascii=False),encoding="utf-8")
    print("NEW5_SAMPLES_READY",sum(x["size"] for x in records),flush=True)


def render(pitch_map_path):
    pitch_map=json.loads(pitch_map_path.read_text(encoding="utf-8"))
    # Independent QA supplies an explicit sample-id keyed measured mapping.
    rows=pitch_map["records"]
    mapped={r["sample_id"]:r for r in rows}
    old=json.loads((OLD_RAW/"sample_sources.json").read_text(encoding="utf-8"))
    new=json.loads((RAW/"new_sample_sources_v2_pending_pitch.json").read_text(encoding="utf-8"))["records"]
    corrected=[]
    for row in old["records"]+new:
        item=dict(row)
        if item["instrument"]=="dan_tranh":
            measured=mapped[item["id"]]
            if measured["source_sha256"]!=item["sha256"]:raise ValueError("QA pitch map source SHA mismatch")
            item["legacy_declared_root_midi"]=item.get("root_midi")
            item["root_midi"]=measured["root_midi"]
            item["estimated_midi_float"]=measured["estimated_midi_float"]
            item["pitch_measurement_status"]="INDEPENDENT_MULTIPLE_WINDOW_QA"
            item["pitch_analysis"]=measured
        corrected.append(item)
    RAW.mkdir(parents=True,exist_ok=True)
    updated={**old,"records":corrected,"correction":"VCSL note-name octave convention differs; use independently measured actual MIDI/f0. Original map/first render preserved.",
             "independent_pitch_map":composer.info(pitch_map_path),"first_source_manifest":composer.info(OLD_RAW/"sample_sources.json")}
    (RAW/"sample_sources.json").write_text(json.dumps(updated,indent=2,ensure_ascii=False),encoding="utf-8")
    composer.RAW=RAW;composer.OUT=OUT
    composer.render()
    manifest_path=OUT/"manifest.json";manifest=json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["production_script_v2"]=composer.info(Path(__file__))
    manifest["frozen_render_kernel"]=composer.info(KERNEL)
    manifest["independent_sample_pitch_map"]=composer.info(pitch_map_path)
    manifest["preserved_first_attempt"]="assets/raw/audio/wuxia_original_trial_20261009 + assets/processed/audio/wuxia_original_trial_20261009; unchanged first failure/score/audio"
    manifest["correction_scope"]="Measured sample root/tuning, and five low-register samples to avoid large pitch transposition; same original score, no new melody or model"
    manifest_path.write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding="utf-8")


def main():
    parser=argparse.ArgumentParser();parser.add_argument("--prepare-new-samples",action="store_true");parser.add_argument("--pitch-map",type=Path);args=parser.parse_args()
    if args.prepare_new_samples:prepare()
    elif args.pitch_map:render(args.pitch_map.resolve())
    else:raise SystemExit("Supply independent verified --pitch-map; rendering without actual source-pitch evidence is refused")


if __name__=="__main__":main()
