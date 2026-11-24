"""Minimal independent offline QA for personal local Stable continuation.

Only NEW QA JSON is written. No inference, Godot, playback or asset edits.
"""
from __future__ import annotations
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from verify_wuxia_audio_loops import ROOT, record, sha, changes
import numpy as np
from scipy.io import wavfile
from verify_wuxia_audio_trial import inspect_wav, inspect_mp3, decoder_sidecar_checks
from verify_wuxia_original_continuous_v3 import continuity

OUT = ROOT / "assets/processed/audio/wuxia_stable_personal_continuation_qa_20261009"
SNAPSHOT = OUT / "protection.json"
PRIOR = ROOT / "assets/processed/audio/wuxia_original_continuous_v3_qa_20261009/protection.json"
EXTRA_ROOTS = [ROOT / p for p in (
    "assets/raw/audio/wuxia_audio_bank_v9_20261009",
    "assets/processed/audio/wuxia_audio_bank_v9_20261009",
    "assets/raw/audio/wuxia_original_continuous_v3_20261009",
    "assets/processed/audio/wuxia_original_continuous_v3_20261009",
    "assets/raw/audio/wuxia_original_body_analysis_v3_20261009")]

def save(name, value):
    path = OUT / name
    assert path.resolve().is_relative_to(OUT.resolve()) and path.suffix == ".json"
    if path.exists():
        raise RuntimeError("Preserve old reports; use a new filename")
    OUT.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def snapshot():
    prior = json.loads(PRIOR.read_text(encoding="utf-8"))
    assert not changes(prior["protected_files"]), "Previous protected sources changed"
    paths = {Path(r["path"]) for r in prior["protected_files"]}
    paths.update(p for directory in EXTRA_ROOTS for p in directory.rglob("*") if p.is_file())
    paths.update(ROOT / "scripts/audio" / name for name in (
        "compose_wuxia_original_continuous_v3.py", "wuxia_original_continuous_v3_score_20261009.json",
        "verify_wuxia_original_continuous_v3.py", "produce_wuxia_audio_bank_v9.py",
        "wuxia_audio_bank_v9_plan_20261009.json"))
    paths.update([PRIOR, ROOT / "assets/processed/audio/wuxia_original_continuous_v3_qa_20261009/v3_final_offline.json"])
    roots = sorted(set(prior["frozen_roots"] + [str(r.resolve()) for r in EXTRA_ROOTS if r.exists()]))
    value = {"scope": "LOCAL_STABLE_PERSONAL_CONTINUATION_PROTECTION", "created_utc": datetime.now(timezone.utc).isoformat(), "production_file_count": 279, "player_path_count": 15, "previous_protected_count": len(prior["protected_files"]), "protected_files": [record(p) for p in sorted(paths)], "frozen_roots": roots, "previous_snapshot": record(PRIOR), "model_inference_by_qa": False, "godot_started": False}
    # The exact 15 player paths include historically absent tmp/backup slots;
    # protect absence as an explicit state rather than requiring new files.
    assert all(r["exists"] or str(Path(r["path"])) in {r["path"] for r in prior["protected_files"] if not r["exists"]} for r in value["protected_files"])
    save("protection.json", value)
    return value

def protection():
    prior = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    changed = changes(prior["protected_files"])
    roots = [Path(r) for r in prior["frozen_roots"]]
    inventory = {str(p.resolve()) for root in roots for p in root.rglob("*") if p.is_file()}
    expected = {r["path"] for r in prior["protected_files"] if any(Path(r["path"]).is_relative_to(root) for root in roots)}
    return {"protected_file_count": len(prior["protected_files"]), "sha_bytes_mtime_changes": changed, "added_frozen_paths": sorted(inventory - expected), "removed_frozen_paths": sorted(expected - inventory), "unchanged": not changed and inventory == expected}

def verify(alt=False):
    before = protection()
    bank = "wuxia_stable_personal_journey_alt_20261009" if alt else "wuxia_stable_personal_continuation_20261009"
    directory = ROOT / "assets/processed/audio" / bank
    raw_directory = ROOT / "assets/raw/audio" / bank
    manifest_path = directory / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    checked = {}
    def check(row):
        path = Path(row["path"])
        path = path if path.is_absolute() else ROOT / path
        if str(path) not in checked:
            observed = record(path)
            assert observed["sha256"] == row["sha256"] and observed["bytes"] == row["size"], str(path)
            checked[str(path)] = observed
        else:
            assert checked[str(path)]["sha256"] == row["sha256"] and checked[str(path)]["bytes"] == row["size"]
        return path
    plan = json.loads(check(manifest["plan"]).read_text(encoding="utf-8"))
    check(manifest["production_script"])
    if alt:
        check(manifest["continuation_runner"])
    assert manifest["purpose"] == "PERSONAL_NONCOMMERCIAL_EVALUATION" and manifest["status"] == "LISTENING_PENDING"
    assert manifest["loop_processing"] == "NONE" and manifest["game_integration"] == "NONE"
    assert len(manifest["tracks"]) == len(plan["tracks"]) == (1 if alt else 3)
    planned = {r["id"]: r for r in plan["tracks"]}
    tracks = []
    for meta in manifest["tracks"]:
        intended = planned[meta["id"]]
        assert all(meta[key] == intended[key] for key in ("prompt", "seed", "seconds"))
        assert meta["generation_status"] == "COMPLETE" and meta["inference_exit_code"] == 0
        assert meta["runtime_revision"] == plan["runtime_revision"] and meta["model_revision"] == plan["model_revision"]
        assert meta["steps"] == 8 and meta["threads"] == 6
        command = meta["command"]
        for flag, value in (("--dit", "sm-music"), ("--decoder", "same-s"), ("--dit-precision", "fp32"), ("--decoder-precision", "w8a8"), ("--prompt", meta["prompt"]), ("--seed", str(meta["seed"])), ("--seconds", str(meta["seconds"])), ("--steps", "8"), ("--threads", "6")):
            assert command[command.index(flag) + 1] == value
        for key in ("production_script", "frozen_float_wrapper", "frozen_io_helper", "plan_file", "runtime_preparation", "inference_log"):
            check(meta[key])
        if alt:
            check(meta["continuation_runner"])
        assert len(meta["model_files"]) == 3
        for row in meta["model_files"] + meta["licenses"] + meta["raw_outputs"]:
            check(row)
        actual_meta = json.loads((raw_directory / (meta["id"] + ".meta.json")).read_text(encoding="utf-8"))
        assert actual_meta == meta
        processing = meta["processing"]
        path = check(processing["source"])
        rate, raw = wavfile.read(path)
        assert rate == 44100 and raw.dtype == np.float32 and raw.shape == (meta["seconds"] * rate, 2)
        assert np.isfinite(raw).all() and np.any(raw)
        planar = np.ascontiguousarray(raw.T)
        rms = float(np.sqrt(np.mean(planar.astype(np.float64) ** 2)))
        peak = float(np.abs(raw).max())
        gain = min(10 ** (-22 / 20) / rms, 10 ** (-3 / 20) / peak)
        assert rms == processing["source_rms"] and peak == processing["source_peak"] and gain == processing["linear_gain"]
        assert processing["quantization"] == "trunc_int16" and processing["pcm_scale"] == 32767
        assert processing["frames"] == len(raw) and processing["edge_fade_frames"] == 662
        audition = planar * gain
        edge = processing["edge_fade_frames"]
        audition[:, :edge] *= np.linspace(0, 1, edge, dtype=np.float32)
        audition[:, -edge:] *= np.linspace(1, 0, edge, dtype=np.float32)
        preview = audition[:, :processing["preview_frames"]].copy()
        assert processing["preview_frames"] == 30 * rate and processing["preview_end_fade_frames"] == 2205
        fade = processing["preview_end_fade_frames"]
        preview[:, -fade:] *= np.linspace(1, 0, fade, dtype=np.float32)
        wavs, mp3s = [], []
        for output in processing["outputs"]:
            file_path = check(output)
            expected = preview if "first30s" in file_path.name else audition
            if file_path.suffix == ".wav":
                output_rate, pcm = wavfile.read(file_path)
                assert output_rate == rate and pcm.dtype == np.int16
                reference = (expected.T * 32767).astype(np.int16)
                assert np.array_equal(pcm, reference)
                observation = inspect_wav(file_path)
                assert observation["finite_nonzero_pass"] and observation["integer_full_scale_sample_count"] == 0
                assert max(observation["peak_per_channel"]) < 10 ** (-3 / 20)
                observation["source_processing_max_pcm_difference_lsb"] = 0
                wavs.append(observation)
            else:
                observation = inspect_mp3(file_path)
                assert observation["technical_decode_pass"] and observation["channels"] == 2 and observation["sample_rate_hz"] == rate
                assert observation["decoded_frames"] == expected.shape[1]
                mp3s.append(observation)
        assert len(wavs) == len(mp3s) == 2
        signal = inspect_wav(path)
        assert signal["finite_nonzero_pass"]
        quiet = continuity(path)
        tracks.append({"id": meta["id"], "prompt": meta["prompt"], "seed": meta["seed"], "seconds": meta["seconds"], "metadata": record(raw_directory / (meta["id"] + ".meta.json")), "raw": signal, "raw_low_energy_observations": quiet["low_energy_observations"], "rms_windows_seconds": .05, "rms_hop_seconds": .01, "audition_and_preview_wav": wavs, "audition_and_preview_mp3": mp3s, "gain_fade_pcm_exact": True, "raw_above_unity_is_not_hard_clipping": True, "style_verdict": "LISTENING_PENDING"})
    sidecars = decoder_sidecar_checks([raw_directory])
    assert len(sidecars) == (1 if alt else 3) and all(r["fields_verified"] for r in sidecars)
    after = protection()
    assert before["unchanged"] and after["unchanged"]
    report = {"scope": "LOCAL_STABLE_PERSONAL_CONTINUATION_MINIMAL_OFFLINE_QA", "technical_pass": True, "manifest": record(manifest_path), "checked_source_output_and_model_files": list(checked.values()), "tracks": tracks, "decoder_sidecars": sidecars, "protection_before": before, "protection_after": after, "new_music_verdict": "LISTENING_PENDING", "loop_approval": False, "musical_style_or_professional_ear_approval": False, "model_invocations_by_qa": 0, "godot_started": False, "formal_adopted": False, "commercial_eligibility_claimed": False}
    if alt:
        previous = json.loads((ROOT / "assets/processed/audio/wuxia_stable_personal_continuation_qa_20261009/three_tracks_offline.json").read_text(encoding="utf-8"))
        old = next(t for t in previous["tracks"] if t["id"] == "jianghu_continuous_96s")
        report["scope"] = "ONE_AUTHORIZED_JOURNEY_ALT_MINIMAL_OFFLINE_QA"
        report["sealed_previous_journey_low_energy_observations"] = old["raw_low_energy_observations"]
        report["old_report_sha256"] = sha(ROOT / "assets/processed/audio/wuxia_stable_personal_continuation_qa_20261009/three_tracks_offline.json")
        report["continuity_numbers_are_not_listening_approval"] = True
        report["automatic_further_attempts_authorized"] = False
    save("one_journey_alt_offline.json" if alt else "three_tracks_offline.json", report)
    return report

def main():
    global OUT, SNAPSHOT
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("snapshot", "protection", "verify"))
    parser.add_argument("--alt", action="store_true")
    args = parser.parse_args()
    if args.alt:
        OUT = ROOT / "assets/processed/audio/wuxia_stable_personal_jianghu_alt_qa_20261009"
        SNAPSHOT = OUT / "protection.json"
        assert args.mode != "snapshot", "ALT protection is already fixed separately"
    if args.mode == "snapshot":
        value = snapshot()
        print(json.dumps({"protected_files": len(value["protected_files"]), "snapshot": str(SNAPSHOT), "sha256": sha(SNAPSHOT)}))
    elif args.mode == "verify":
        try:
            value = verify(alt=args.alt)
        except Exception as error:
            save("three_tracks_offline_failed.json", {"technical_pass": False, "error": repr(error), "protection_after": protection(), "new_music_verdict": "LISTENING_PENDING"})
            raise
        report_path = OUT / ("one_journey_alt_offline.json" if args.alt else "three_tracks_offline.json")
        print(json.dumps({"technical_pass": value["technical_pass"], "report": str(report_path), "sha256": sha(report_path), "protected_unchanged": value["protection_after"]["unchanged"]}))
    else:
        value = protection()
        save("protection_final.json", value)
        print(json.dumps(value))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
