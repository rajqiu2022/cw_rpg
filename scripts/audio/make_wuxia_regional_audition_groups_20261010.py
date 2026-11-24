"""Four convenience medleys from NEW complete audition PCM, no model/engine.

Copy exact first12/15-second PCM snippets; insert fixed one-second digital zeros.
Group boundaries are navigation gaps, not the quality of the underlying music.
"""
from pathlib import Path
import argparse
import json
import wave
import numpy as np
from produce_wuxia_stable_personal_continuation import ROOT, record, encode_mp3

BANK = ROOT / "assets/processed/audio/wuxia_regional_story_bank_20261010"
DEST = ROOT / "assets/processed/audio/wuxia_regional_story_auditions_20261010"
PLAN = ROOT / "scripts/audio/wuxia_regional_story_bank_plan_20261010.json"
SR = 44100


def main():
    if (DEST / "group_audition_manifest.json").exists():
        raise SystemExit("Existing grouped audition metadata preserved")
    ap = argparse.ArgumentParser()
    ap.add_argument("--bianzhou-alt", action="store_true", help="Explicitly select the ONE separately generated Bianzhou ALT for comparison; preserve bank20")
    ap.add_argument("--village-night-alt", action="store_true", help="Explicitly select the ONE separate night-village ALT; preserve bank20")
    ap.add_argument("--forest-alt", action="store_true", help="Explicitly select the ONE separate forest ALT; preserve bank20")
    ap.add_argument("--story-tension-alt", action="store_true", help="Explicitly select the ONE separate tension-story ALT; preserve bank20")
    args = ap.parse_args()
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    manifest = json.loads((BANK / "manifest.json").read_text(encoding="utf-8"))
    if len(manifest["tracks"]) != 20 or not all(t["generation_status"] == "COMPLETE" for t in manifest["tracks"]):
        raise ValueError("Twenty full candidates must be complete first")
    DEST.mkdir(parents=True, exist_ok=True)
    specifications = [
        ("regions", "六城镇串听", ("regional",), 12),
        ("villages_outskirts", "村庄与郊外串听", ("village", "outskirts"), 12),
        ("story", "四剧情情绪串听", ("story",), 15),
        ("battle", "五战斗类型串听", ("battle",), 12),
    ]
    groups = []
    for key, title, categories, seconds in specifications:
        wav = DEST / ("group_" + key + ".wav")
        mp3 = wav.with_suffix(".mp3")
        if wav.exists() or mp3.exists():
            raise ValueError("Existing medley preserved")
        tracks = [t for t in plan["tracks"] if t["category"] in categories]
        chunks, sequence, offset = [], [], 0
        for index, track in enumerate(tracks):
            source = BANK / (track["id"] + "_audition.wav")
            replacement = "ORIGINAL_BANK20"
            if args.bianzhou_alt and track["id"] == "city_bianzhou":
                source = ROOT / "assets/processed/audio/wuxia_regional_bianzhou_alt_20261010/city_bianzhou_audition.wav"
                replacement = "ONE_BIANZHOU_ALT_20261010"
            elif args.village_night_alt and track["id"] == "village_night":
                source = ROOT / "assets/processed/audio/wuxia_regional_village_night_alt_20261010/village_night_audition.wav"
                replacement = "ONE_VILLAGE_NIGHT_ALT_20261010"
            elif args.forest_alt and track["id"] == "outskirts_forest_xiangzhou":
                source = ROOT / "assets/processed/audio/wuxia_regional_forest_alt_20261010/outskirts_forest_xiangzhou_audition.wav"
                replacement = "ONE_FOREST_ALT_20261010"
            elif args.story_tension_alt and track["id"] == "story_tension":
                source = ROOT / "assets/processed/audio/wuxia_regional_story_tension_alt_20261010/story_tension_audition.wav"
                replacement = "ONE_STORY_TENSION_ALT_20261010"
            with wave.open(str(source), "rb") as stream:
                if stream.getnchannels() != 2 or stream.getsampwidth() != 2 or stream.getframerate() != SR:
                    raise ValueError("Unexpected audition PCM")
                pcm = np.frombuffer(stream.readframes(seconds * SR), dtype="<i2").reshape(-1, 2).copy()
            if pcm.shape != (seconds * SR, 2):
                raise ValueError("Insufficient exact source snippet")
            sequence.append({"id": track["id"], "title_zh": track["title_zh"],
                "source": record(source), "source_replacement": replacement,
                "source_start_frame": 0, "source_end_frame_exclusive": seconds * SR,
                "group_start_frame": offset, "group_start_seconds": offset / SR,
                "group_end_frame_exclusive": offset + seconds * SR,
                "following_silence_frames": SR if index + 1 < len(tracks) else 0})
            chunks.append(pcm)
            offset += seconds * SR
            if index + 1 < len(tracks):
                chunks.append(np.zeros((SR, 2), dtype="<i2"))
                offset += SR
        pcm = np.concatenate(chunks, axis=0)
        with wave.open(str(wav), "wb") as stream:
            stream.setparams((2, 2, SR, 0, "NONE", "not compressed"))
            stream.writeframes(pcm.tobytes())
        # Encode from the selected source PCM, not a second gain/fade remix.
        encode_mp3(mp3, np.ascontiguousarray(pcm.T.astype(np.float32) / 32768))
        groups.append({"id": key, "title_zh": title, "sample_rate": SR, "channels": 2,
            "frames": offset, "seconds": offset / SR, "sequence": sequence,
            "construction": "Exact source PCM snippets plus fixed 1s zero gaps; no new gain/fade/crossfade.",
            "mp3_input": "group PCM16 converted to float32 using /32768",
            "outputs": [record(wav), record(mp3)], "status": "LISTENING_PENDING"})
        print("GROUP_READY", key, offset / SR, flush=True)
    (DEST / "group_audition_manifest.json").write_text(json.dumps({
        "status": "LISTENING_PENDING", "purpose": "Convenience comparison only, not game music or loop",
        "presentation": "20 themes; original20 plus up to4 explicitly authorized separate ALT archives",
        "bianzhou_alt_selected": args.bianzhou_alt,
        "village_night_alt_selected": args.village_night_alt,
        "forest_alt_selected": args.forest_alt,
        "story_tension_alt_selected": args.story_tension_alt,
        "source_bank_manifest": record(BANK / "manifest.json"), "plan": record(PLAN),
        "script": record(Path(__file__)), "groups": groups}, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
