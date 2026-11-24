"""Offline QA for the regional/story local-music batch.

Only NEW QA reports are written; no game, sample, inference or engine writes.
"""
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from verify_wuxia_audio_loops import ROOT, record, sha, changes
from verify_wuxia_audio_trial import production_paths
from verify_wuxia_audio_trial import inspect_wav, inspect_mp3
from verify_wuxia_audio_loops import wav_observation
from verify_wuxia_original_continuous_v3 import continuity, intervals
import numpy as np
from scipy.io import wavfile

OUT = ROOT / "assets/processed/audio/wuxia_regional_story_bank_qa_20261010"
SNAPSHOT = OUT / "protection.json"
SEALED_BANK = OUT / "original_twenty_bank_sealed_files.json"
PRIOR = ROOT / "assets/processed/audio/wuxia_approved_local_loops_qa_20261009/protection.json"
RAW = ROOT / "assets/raw/audio/wuxia_regional_story_bank_20261010"
PROCESSED = ROOT / "assets/processed/audio/wuxia_regional_story_bank_20261010"

def save(name, value):
    path = OUT / name
    assert path.resolve().is_relative_to(OUT.resolve()) and path.suffix == ".json"
    if path.exists():
        raise RuntimeError("Preserve all existing QA results; use a NEW report name")
    OUT.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def snapshot():
    prior = json.loads(PRIOR.read_text(encoding="utf-8"))
    paths = {Path(r["path"]) for r in prior["protected_files"]}
    roots = [ROOT / "assets/raw/audio", ROOT / "assets/processed/audio", ROOT / "game/art/audio"]
    frozen = [d for root in roots for d in root.iterdir() if d.is_dir() and "20261010" not in d.name]
    paths.update(p for root in frozen for p in root.rglob("*") if p.is_file())
    paths.update(p for root in roots for p in root.iterdir() if p.is_file())
    paths.update(production_paths())
    paths.update(p for p in (ROOT / "scripts/audio").iterdir() if p.is_file() and p != Path(__file__) and "regional_story" not in p.name and "20261010" not in p.name)
    paths.add(PRIOR)
    # Snapshot the 15 existing player *paths*, including real absent tmp/bak states.
    player_paths = [Path(r["path"]) for r in prior["protected_files"] if "app_userdata" in r["path"]]
    assert len(player_paths) == 15
    value = {"scope": "REGIONAL_STORY_BGM_READONLY_PROTECTION", "created_utc": datetime.now(timezone.utc).isoformat(), "previous_protected_count": len(prior["protected_files"]), "current_production_path_count": len(production_paths()), "player_path_count": 15, "player_actual_existing_count": sum(p.is_file() for p in player_paths), "protected_files": [record(p) for p in sorted(paths)], "frozen_roots": sorted(set(prior["frozen_roots"] + [str(d.resolve()) for d in frozen])), "prior_snapshot": record(PRIOR), "prior_baseline_changes_before_this_new_snapshot": changes(prior["protected_files"]), "godot_started": False, "model_invocations_by_qa": 0}
    save("protection.json", value)
    return value

def protection():
    before = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    changed = changes(before["protected_files"])
    roots = [Path(p) for p in before["frozen_roots"]]
    actual = {str(p.resolve()) for root in roots for p in root.rglob("*") if p.is_file()}
    expected = {r["path"] for r in before["protected_files"] if any(Path(r["path"]).is_relative_to(root) for root in roots)}
    sealed_changes, sealed_count = [], 0
    if SEALED_BANK.exists():
        sealed = json.loads(SEALED_BANK.read_text(encoding="utf-8"))
        sealed_count = len(sealed["files"])
        sealed_changes = changes(sealed["files"])
    return {"protected_file_count": len(before["protected_files"]), "additional_original20_sealed_file_count": sealed_count, "sha_bytes_mtime_changes": changed, "original20_sealed_changes": sealed_changes, "added_frozen_paths": sorted(actual - expected), "removed_frozen_paths": sorted(expected - actual), "unchanged": not changed and not sealed_changes and actual == expected}

def seal_original_bank():
    manifest = json.loads((PROCESSED / "manifest.json").read_text(encoding="utf-8"))
    assert len(manifest["tracks"]) == len(manifest["loops"]) == 20 and all(t["generation_status"] == "COMPLETE" for t in manifest["tracks"])
    paths = {p for root in (RAW, PROCESSED) for p in root.rglob("*") if p.is_file()}
    paths.update(ROOT / "scripts/audio" / name for name in ("produce_wuxia_regional_story_bank_20261010.py", "wuxia_regional_story_bank_plan_20261010.json"))
    data = {"scope": "SEAL_EXISTING_ORIGINAL20_BEFORE_ROOT_AUTHORIZED_ALTS", "files": [record(p) for p in sorted(paths)], "new_group_outputs_may_be_added_later": True, "existing_original20_files_may_not_change": True, "original_manifest": record(PROCESSED / "manifest.json"), "old_audio_protection": protection()}
    assert data["old_audio_protection"]["unchanged"]
    save(SEALED_BANK.name, data)
    print(json.dumps({"sealed_files": len(data["files"]), "path": str(SEALED_BANK), "sha256": sha(SEALED_BANK)}))

def processed_internal_energy(path, analysis_end):
    original_record = record(path)
    rate, pcm = wavfile.read(path)
    assert rate == 44100 and pcm.dtype == np.int16 and pcm.ndim == 2 and pcm.shape[1] == 2
    audio = pcm.astype(np.float64) / 32768
    window, hop = round(.04 * rate), round(.01 * rate)
    power = np.mean(audio * audio, axis=1)
    cumulative = np.concatenate([[0.0], np.cumsum(power)])
    starts = np.arange(round(3 * rate), round(analysis_end * rate) - window + 1, hop)
    rms = np.sqrt(np.maximum(0, (cumulative[starts + window] - cumulative[starts]) / window))
    threshold = 10 ** (-45 / 20)
    quiet = intervals(rms < threshold, hop / rate, .15)
    for row in quiet:
        begin, end = round(row["start_seconds"] / .01), round(row["end_seconds"] / .01)
        section = rms[begin:end]
        row.update(start_seconds=row["start_seconds"] + 3, end_seconds=row["end_seconds"] + 3, minimum_window_rms=float(section.min()), peak_window_rms=float(section.max()), mean_window_rms=float(section.mean()))
    longest = max((r["duration_seconds"] for r in quiet), default=0)
    fraction = float(np.mean(rms < threshold))
    body_rms = float(np.sqrt(np.mean(power[round(3 * rate):round(analysis_end * rate)])))
    assert record(path) == original_record
    return {"processed_full_audio": original_record, "window_ms": 40, "hop_ms": 10, "threshold_dbfs": -45, "internal_body_start_seconds": 3, "internal_body_end_seconds": analysis_end, "excluded_opening_and_fixed_tail": True, "body_signal_rms": body_rms, "body_signal_rms_dbfs": float(20 * np.log10(body_rms)) if body_rms else None, "body_low_window_fraction": fraction, "low_intervals_at_least150ms": quiet, "max_internal_low_segment_seconds": longest, "body_peak_window_rms": float(rms.max()), "body_mean_window_rms": float(rms.mean()), "root_attention_only_not_quality_failure": longest >= 1 or fraction > .10}

def energy_scan():
    observations = []
    for meta_path in sorted(RAW.glob("*.meta.json")):
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        if meta.get("generation_status") != "COMPLETE" or not meta.get("processing"):
            continue
        output = next(r for r in meta["processing"]["outputs"] if r["path"].endswith("_audition.wav"))
        path = ROOT / output["path"]
        assert sha(path) == output["sha256"]
        observations.append({"id": meta["id"], "observation": processed_internal_energy(path, meta["analysis_end_seconds"])})
    print(json.dumps({"completed_full_tracks_scanned": len(observations), "attention_tracks": [r for r in observations if r["observation"]["root_attention_only_not_quality_failure"]], "all_track_max_internal_seconds": {r["id"]: r["observation"]["max_internal_low_segment_seconds"] for r in observations}}))

def verify(expected_count=20, report_name="twenty_tracks_offline.json"):
    before = protection()
    manifest_path = PROCESSED / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    files = {}
    def check(row):
        path = Path(row["path"])
        if not path.is_absolute():
            path = ROOT / path
        key = str(path.resolve())
        if key not in files:
            files[key] = record(path)
        assert files[key]["sha256"] == row["sha256"] and files[key]["bytes"] == row["size"], key
        return path
    plan = json.loads(check(manifest["plan"]).read_text(encoding="utf-8"))
    assert len(plan["tracks"]) == expected_count and len({t["id"] for t in plan["tracks"]}) == expected_count and len({t["seed"] for t in plan["tracks"]}) == expected_count
    assert plan["steps"] == 8 and plan["threads"] == 6 and plan["purpose"] == "PERSONAL_NONCOMMERCIAL_EVALUATION"
    assert manifest["game_integration"] == "NONE"
    check(manifest["production_script"])
    check(manifest["continuation_runner"])
    planned = {t["id"]: t for t in plan["tracks"]}
    assert len(manifest["tracks"]) == expected_count and {t["id"] for t in manifest["tracks"]} == set(planned)
    loops = {t["track"]["id"]: t for t in manifest["loops"]}
    assert len(loops) == expected_count and set(loops) == set(planned)
    results = []
    for number, meta in enumerate(manifest["tracks"], 1):
        result = {"id": meta["id"], "technical_pass": False, "audible_style_approval": False, "audible_loop_approval": False}
        try:
            target = planned[meta["id"]]
            assert all(meta[k] == target[k] for k in ("prompt", "seed", "seconds"))
            assert meta["generation_status"] == "COMPLETE" and meta["inference_exit_code"] == 0
            assert meta["model_revision"] == plan["model_revision"] and meta["runtime_revision"] == plan["runtime_revision"]
            assert meta["steps"] == 8 and meta["threads"] == 6
            command = meta["command"]
            for flag, value in (("--dit", "sm-music"), ("--decoder", "same-s"), ("--dit-precision", "fp32"), ("--decoder-precision", "w8a8"), ("--prompt", target["prompt"]), ("--seed", str(target["seed"])), ("--seconds", str(target["seconds"])), ("--steps", "8"), ("--threads", "6")):
                assert command[command.index(flag) + 1] == value
            for key in ("production_script", "frozen_float_wrapper", "frozen_io_helper", "continuation_runner", "plan_file", "runtime_preparation", "inference_log"):
                check(meta[key])
            if "preserved_original_bank_manifest" in meta:
                check(meta["preserved_original_bank_manifest"])
            assert len(meta["model_files"]) == 3
            for row in meta["model_files"] + meta["licenses"] + meta["raw_outputs"]:
                check(row)
            meta_path = RAW / (meta["id"] + ".meta.json")
            assert json.loads(meta_path.read_text(encoding="utf-8")) == meta
            processing = meta["processing"]
            raw_path = check(processing["source"])
            assert raw_path.resolve().is_relative_to(RAW.resolve())
            rate, raw = wavfile.read(raw_path)
            assert raw.dtype == np.float32 and rate == 44100 and raw.shape == (target["seconds"] * rate, 2)
            assert np.isfinite(raw).all() and np.any(raw)
            planar = np.ascontiguousarray(raw.T)
            rms = float(np.sqrt(np.mean(planar.astype(np.float64) ** 2)))
            peak = float(np.abs(raw).max())
            gain = min(10 ** (-22 / 20) / rms, 10 ** (-3 / 20) / peak)
            assert rms == processing["source_rms"] and peak == processing["source_peak"] and gain == processing["linear_gain"]
            assert processing["pcm_scale"] == 32767 and processing["quantization"] == "trunc_int16" and processing["edge_fade_frames"] == 662
            audition = planar * gain
            audition[:, :662] *= np.linspace(0, 1, 662, dtype=np.float32)
            audition[:, -662:] *= np.linspace(1, 0, 662, dtype=np.float32)
            preview = audition[:, :30 * rate].copy()
            assert processing["preview_frames"] == 30 * rate and processing["preview_end_fade_frames"] == 2205
            preview[:, -2205:] *= np.linspace(1, 0, 2205, dtype=np.float32)
            wavs, mp3s = [], []
            for output in processing["outputs"]:
                path = check(output)
                assert path.resolve().is_relative_to(PROCESSED.resolve())
                expected = preview if "first30s" in path.name else audition
                if path.suffix == ".wav":
                    out_rate, pcm = wavfile.read(path)
                    assert out_rate == rate and pcm.dtype == np.int16 and np.array_equal(pcm, (expected.T * 32767).astype(np.int16))
                    observation = inspect_wav(path)
                    assert observation["finite_nonzero_pass"] and observation["integer_full_scale_sample_count"] == 0 and max(observation["peak_per_channel"]) < 10 ** (-3 / 20)
                    wavs.append(observation)
                else:
                    observation = inspect_mp3(path)
                    assert observation["technical_decode_pass"] and observation["sample_rate_hz"] == rate and observation["channels"] == 2 and observation["decoded_frames"] == expected.shape[1]
                    mp3s.append(observation)
            assert len(wavs) == len(mp3s) == 2
            decoder_path = raw_path.with_suffix(".decoder.json")
            decoder = json.loads(decoder_path.read_text(encoding="utf-8"))
            assert decoder["frames"] == len(raw) and decoder["sample_rate"] == rate and decoder["raw_peak"] == peak and decoder["raw_rms"] == rms
            assert decoder["finite"] is True and decoder["export_clipping"] is False and decoder["samples_above_unity"] == int(np.count_nonzero(np.abs(raw) > 1))
            signal = inspect_wav(raw_path)
            quiet = continuity(raw_path)
            audition_path = ROOT / next(row["path"] for row in processing["outputs"] if row["path"].endswith("_audition.wav"))
            processed_energy = processed_internal_energy(audition_path, target["analysis_end_seconds"])
            result.update(metadata=record(meta_path), raw=signal, decoder=record(decoder_path), raw_low_energy_observations=quiet["low_energy_observations"], rms_window_seconds=.05, rms_hop_seconds=.01, processed_full_internal_energy=processed_energy, low_energy_is_observation_not_listening_approval=True, full_and_preview_pcm_exact=True, full_and_preview_wav=wavs, full_and_preview_mp3=mp3s)
            loop = loops[meta["id"]]
            assert loop["track"] == target
            assert json.loads((PROCESSED / (meta["id"] + ".loop.processing.json")).read_text(encoding="utf-8")) == loop
            check(loop["continuation_runner"])
            check(loop["selection_io_kernel"])
            if "loop_processing_kernel" in loop:
                check(loop["loop_processing_kernel"])
            if loop["status"] == "LOOP_PROCESSING_FAILED":
                result["loop_actual_failure_preserved"] = loop
                raise ValueError("Actual loop processing failed: " + loop["error"])
            assert check(loop["source"]).resolve() == raw_path.resolve()
            selected = loop["loop"]["selected"]
            start, end, overlap = [selected[k] for k in ("start_frame", "end_frame", "crossfade_frames")]
            assert 0 <= start < start + overlap < end - overlap < end <= loop["analysis_source_end_frame_exclusive"] == round(target["analysis_end_seconds"] * rate)
            assert overlap == round(target["crossfade_seconds"] * rate)
            weight = np.linspace(0, 1, overlap, dtype=np.float32)[:, None]
            joined = np.concatenate([raw[start + overlap:end - overlap], raw[end - overlap:end] * (1 - weight) + raw[start:start + overlap] * weight])
            loop_rms = float(np.sqrt(np.mean(np.ascontiguousarray(joined.T).astype(np.float64) ** 2)))
            loop_peak = float(np.abs(joined).max())
            loop_gain = min(10 ** (-22 / 20) / loop_rms, 10 ** (-3 / 20) / loop_peak)
            lp = loop["processing"]
            assert lp["linear_gain"] == loop_gain and lp["pre_gain_loop_rms"] == loop_rms and lp["pre_gain_loop_peak"] == loop_peak
            assert lp["quantization"] == "trunc_int16" and lp["pcm_scale"] == 32767 and lp["edge_silence_fade"] is False
            assert len(joined) == loop["loop"]["loop_frames"] and len(joined) / rate >= target["minimum_loop_seconds"]
            paths = [check(row) for row in loop["outputs"]]
            loop_path = next(p for p in paths if p.name.endswith("_loop.wav"))
            seam_path = next(p for p in paths if p.name.endswith("_seam10.wav"))
            lr, pcm = wavfile.read(loop_path)
            sr, seam = wavfile.read(seam_path)
            assert lr == sr == rate and pcm.dtype == seam.dtype == np.int16
            assert np.array_equal(pcm, (joined * loop_gain * 32767).astype(np.int16))
            assert np.array_equal(seam, np.concatenate([pcm[-5 * rate:], pcm[:5 * rate]]))
            assert np.array_equal(joined[0] - joined[-1], raw[start + overlap] - raw[start + overlap - 1])
            loop_wavs = [wav_observation(loop_path), wav_observation(seam_path)]
            assert all(w["finite_nonzero"] and w["integer_full_scale_samples"] == 0 and max(w["peak_per_channel"]) < 10 ** (-3 / 20) for w in loop_wavs)
            loop_mp3 = [inspect_mp3(p) for p in paths if p.suffix == ".mp3"]
            assert len(loop_mp3) == 2 and all(d["technical_decode_pass"] and d["sample_rate_hz"] == rate and d["channels"] == 2 and d["decoded_frames"] == (10 * rate if "seam10" in d["path"] else len(joined)) for d in loop_mp3)
            result.update(loop_selection=selected, loop_pcm_exact=True, seam_last5_plus_first5_pcm_exact=True, original_adjacent_source_boundary_preserved=True, loop_wav=loop_wavs, loop_mp3=loop_mp3, technical_pass=True)
        except Exception as error:
            result["error"] = repr(error)
        results.append(result)
        print("QA_TRACK", number, "/" + str(expected_count), meta["id"], "PASS" if result["technical_pass"] else result.get("error"), flush=True)
    group_path = ROOT / "assets/processed/audio/wuxia_regional_story_auditions_20261010/group_audition_manifest.json"
    groups = json.loads(group_path.read_text(encoding="utf-8")) if expected_count == 20 else {"groups": []}
    if expected_count == 20:
        assert check(groups["source_bank_manifest"]).resolve() == manifest_path.resolve()
        check(groups["plan"])
        check(groups["script"])
    assert len(groups["groups"]) == (4 if expected_count == 20 else 0)
    group_results = []
    all_group_ids = []
    replacements = {
        "city_bianzhou": ("bianzhou_alt_selected", "wuxia_regional_bianzhou_alt_20261010"),
        "village_night": ("village_night_alt_selected", "wuxia_regional_village_night_alt_20261010"),
        "outskirts_forest_xiangzhou": ("forest_alt_selected", "wuxia_regional_forest_alt_20261010"),
        "story_tension": ("story_tension_alt_selected", "wuxia_regional_story_tension_alt_20261010")}
    for group in groups["groups"]:
        chunks, offset = [], 0
        for index, entry in enumerate(group["sequence"]):
            source = check(entry["source"])
            expected_source = PROCESSED / (entry["id"] + "_audition.wav")
            if entry["id"] in replacements:
                flag, bank = replacements[entry["id"]]
                if groups.get(flag, False):
                    expected_source = ROOT / "assets/processed/audio" / bank / (entry["id"] + "_audition.wav")
            assert source.resolve() == expected_source.resolve()
            sr, samples = wavfile.read(source)
            assert sr == 44100 and samples.dtype == np.int16 and samples.shape[1] == 2
            assert entry["source_start_frame"] == 0 and entry["group_start_frame"] == offset
            end = entry["source_end_frame_exclusive"]
            assert end in (12 * sr, 15 * sr)
            chunks.append(samples[:end])
            offset += end
            assert entry["group_end_frame_exclusive"] == offset
            silence = sr if index + 1 < len(group["sequence"]) else 0
            assert entry["following_silence_frames"] == silence
            if silence:
                chunks.append(np.zeros((silence, 2), dtype=np.int16))
                offset += silence
            all_group_ids.append(entry["id"])
        expected = np.concatenate(chunks)
        assert len(expected) == group["frames"] == offset
        paths = [check(row) for row in group["outputs"]]
        wav = next(p for p in paths if p.suffix == ".wav")
        mp3 = next(p for p in paths if p.suffix == ".mp3")
        sr, actual = wavfile.read(wav)
        assert sr == 44100 and np.array_equal(actual, expected)
        wav_stats, mp3_stats = inspect_wav(wav), inspect_mp3(mp3)
        assert wav_stats["finite_nonzero_pass"] and wav_stats["integer_full_scale_sample_count"] == 0
        assert mp3_stats["technical_decode_pass"] and mp3_stats["decoded_frames"] == len(expected) and mp3_stats["channels"] == 2 and mp3_stats["sample_rate_hz"] == sr
        group_results.append({"id": group["id"], "source_snippets_and_one_second_gaps_pcm_exact": True, "wav": wav_stats, "mp3": mp3_stats, "navigation_gaps_are_intentional_not_music_quality": True})
    assert (len(all_group_ids) == 20 and set(all_group_ids) == set(planned)) if expected_count == 20 else not all_group_ids
    alt_checks, archive = [], []
    if expected_count == 20:
        assert not groups["bianzhou_alt_selected"] and not groups["village_night_alt_selected"] and groups["forest_alt_selected"] and groups["story_tension_alt_selected"]
        archive = [{"id": r["id"], "variant": "ORIGINAL20", "raw_sha256": r["raw"]["sha256"]} for r in results if "raw" in r]
        for name in ("bianzhou", "village_night", "forest", "story_tension"):
            path = ROOT / "assets/processed/audio" / ("wuxia_regional_" + name + "_alt_qa_20261010") / "one_alt_track_offline.json"
            alt = json.loads(path.read_text(encoding="utf-8"))
            assert alt["technical_pass"] and len(alt["tracks"]) == 1
            assert record(Path(alt["manifest"]["path"])) == alt["manifest"]
            assert not changes(alt["checked_files"])
            track = alt["tracks"][0]
            archive.append({"id": track["id"], "variant": name + "_ALT", "raw_sha256": track["raw"]["sha256"]})
            alt_checks.append({"name": name, "actual_qa_report": record(path), "all_recorded_source_output_model_sha_bytes_mtime_unchanged": True, "technical_pass": True, "processed_internal_energy": track["processed_full_internal_energy"], "selected_for_presentation": name in ("forest", "story_tension")})
        assert len(archive) == len({r["raw_sha256"] for r in archive}) == 24
    after = protection()
    report = {"scope": "TWENTY_REGIONAL_STORY_BGM_OFFLINE_QA_ONLY" if expected_count == 20 else "ONE_ROOT_AUTHORIZED_ALT_OFFLINE_QA_ONLY", "technical_pass": all(r["technical_pass"] for r in results) and before["unchanged"] and after["unchanged"], "manifest": record(manifest_path), "verifier_source": record(Path(__file__)), "checked_files": list(files.values()), "tracks": results, "group_manifest": record(group_path) if expected_count == 20 else None, "groups": group_results, "four_actual_alt_report_checks": alt_checks, "raw_archive": archive, "raw_archive_unique_file_shas": len({r["raw_sha256"] for r in archive}), "unique_sha_does_not_prove_different_musical_themes": True, "presentation_original_count": 18 if expected_count == 20 else None, "presentation_alt_count": 2 if expected_count == 20 else None, "protection_before": before, "protection_after": after, "listening_review": "LISTENING_PENDING", "audible_loop_approval": False, "persistent_godot_loop_flags_verified": False, "godot_started": False, "game_writes_by_qa": 0, "model_invocations_by_qa": 0, "commercial_qualification_claimed": False}
    save(report_name, report)
    return report

def main():
    global OUT, RAW, PROCESSED
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("snapshot", "protection", "verify", "energy", "seal-bank20"))
    parser.add_argument("--single-bank")
    args = parser.parse_args()
    if args.single_bank:
        bank = args.single_bank
        assert bank.startswith("wuxia_regional_") and bank.endswith("_alt_20261010") and "/" not in bank and "\\" not in bank and ".." not in bank
        assert args.mode not in ("snapshot", "seal-bank20"), "Reuse the fixed original old-audio protection"
        RAW = ROOT / "assets/raw/audio" / bank
        PROCESSED = ROOT / "assets/processed/audio" / bank
        OUT = ROOT / "assets/processed/audio" / (bank.removesuffix("_20261010") + "_qa_20261010")
    if args.mode == "snapshot":
        value = snapshot()
        print(json.dumps({"protected_files": len(value["protected_files"]), "production": value["current_production_path_count"], "players": value["player_path_count"], "player_existing": value["player_actual_existing_count"], "prior_changed_count": len(value["prior_baseline_changes_before_this_new_snapshot"]), "snapshot": str(SNAPSHOT), "sha256": sha(SNAPSHOT)}))
    elif args.mode == "seal-bank20":
        seal_original_bank()
    elif args.mode == "energy":
        energy_scan()
    elif args.mode == "verify":
        try:
            name = "one_alt_track_offline.json" if args.single_bank else "twenty_tracks_offline.json"
            value = verify(expected_count=1 if args.single_bank else 20, report_name=name)
        except Exception as error:
            save("twenty_tracks_offline_failed.json", {"technical_pass": False, "error": repr(error), "protection_after": protection()})
            raise
        report = OUT / name
        print(json.dumps({"technical_pass": value["technical_pass"], "report": str(report), "sha256": sha(report), "protected_unchanged": value["protection_after"]["unchanged"]}))
    else:
        value = protection()
        save("protection_final.json", value)
        print(json.dumps(value))

if __name__ == "__main__":
    main()
