"""Minimal offline continuity observations for the final original-music retry.

The human rejected V2 as disconnected. Numbers cannot approve musical style.
No model, game, Godot, playback, sample editing or note-renderer reproduction.
"""
from __future__ import annotations
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import numpy as np
from scipy.io import wavfile
import av
from verify_wuxia_audio_loops import ROOT, record, sha, changes, preservation

OUT = ROOT / "assets/processed/audio/wuxia_original_continuous_v3_qa_20261009"
SNAPSHOT = OUT / "protection.json"
V2_REPORT = ROOT / "assets/processed/audio/wuxia_original_qa_20261009/original_v2_two_tracks_offline.json"
OLD_SNAPSHOT = ROOT / "assets/processed/audio/wuxia_audio_loop_qa_20261009/protection.json"
FROZEN_ROOTS = [ROOT / p for p in (
    "assets/raw/audio/wuxia_ai_trial_20261009", "assets/raw/audio/wuxia_sfx_ai_trial_20261009",
    "assets/raw/audio/wuxia_original_samples_20261009", "assets/raw/audio/wuxia_original_trial_20261009",
    "assets/raw/audio/wuxia_original_trial_v2_20261009", "assets/processed/audio/wuxia_original_trial_20261009",
    "assets/processed/audio/wuxia_original_trial_v2_20261009", "assets/processed/audio/wuxia_original_qa_20261009")]

def save(name: str, value: dict) -> None:
    path = OUT / name
    assert path.resolve().is_relative_to(OUT.resolve()) and path.suffix == ".json"
    OUT.mkdir(parents=True, exist_ok=True)
    if path.exists():
        raise RuntimeError("Existing continuity reports are frozen; choose a NEW filename")
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def snapshot() -> dict:
    assert preservation()["unchanged"]
    old = json.loads(OLD_SNAPSHOT.read_text(encoding="utf-8"))
    paths = {Path(r["path"]) for key in ("production_files", "player_files", "first_batch_files") for r in old[key]}
    paths.update(p for root in FROZEN_ROOTS for p in root.rglob("*") if p.is_file())
    paths.update(ROOT / "scripts/audio" / name for name in ("compose_wuxia_original_trial.py", "compose_wuxia_original_trial_v2.py", "wuxia_original_trial_score_20261009.json", "verify_wuxia_original_trial.py", "verify_wuxia_audio_loops.py"))
    paths.update([V2_REPORT, OLD_SNAPSHOT])
    data = {"schema": 1, "created_utc": datetime.now(timezone.utc).isoformat(), "protected_files": [record(p) for p in sorted(paths)], "production_file_count": len(old["production_files"]), "player_path_count": len(old["player_files"]), "first_batch_original_file_count": len(old["first_batch_files"]), "frozen_roots": [str(p) for p in FROZEN_ROOTS], "source_pitch_map_sha256": sha(ROOT / "assets/processed/audio/wuxia_original_qa_20261009/dan_tranh_source_pitch19_map.json"), "user_v2_verdict": "USER_REJECTED_DISCONNECTED_INTERMITTENT_MUSIC", "godot_started": False, "model_invocations": 0}
    save("protection.json", data)
    return data

def protection() -> dict:
    old = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    changed = changes(old["protected_files"])
    actual = {str(p.resolve()) for root in FROZEN_ROOTS for p in root.rglob("*") if p.is_file()}
    prior = {r["path"] for r in old["protected_files"] if any(Path(r["path"]).is_relative_to(root) for root in FROZEN_ROOTS)}
    return {"protected_file_count": len(old["protected_files"]), "sha_bytes_mtime_changes": changed, "frozen_root_added_paths": sorted(actual - prior), "frozen_root_removed_paths": sorted(prior - actual), "unchanged": not changed and actual == prior}

def decode(path: Path) -> tuple[int, np.ndarray]:
    if path.suffix.lower() == ".wav":
        rate, samples = wavfile.read(path)
        if np.issubdtype(samples.dtype, np.integer):
            audio = samples.astype(np.float64) / max(abs(np.iinfo(samples.dtype).min), np.iinfo(samples.dtype).max)
        else:
            audio = samples.astype(np.float64)
        if audio.ndim == 1:
            audio = audio[:, None]
        return rate, audio
    with av.open(str(path)) as container:
        frames = list(container.decode(audio=0))
        assert frames
        rate = frames[0].sample_rate
        samples = np.concatenate([frame.to_ndarray() for frame in frames], axis=1).T
        return rate, samples.astype(np.float64)

def intervals(mask: np.ndarray, hop_seconds: float, minimum_seconds: float = .15) -> list[dict]:
    padded = np.concatenate([[False], mask, [False]])
    boundaries = np.flatnonzero(padded[1:] != padded[:-1])
    return [{"start_seconds": float(start * hop_seconds), "end_seconds": float(end * hop_seconds), "duration_seconds": float((end - start) * hop_seconds)} for start, end in zip(boundaries[::2], boundaries[1::2]) if (end - start) * hop_seconds >= minimum_seconds]

def continuity(path: Path) -> dict:
    rate, audio = decode(path)
    assert len(audio) and np.isfinite(audio).all()
    power = np.mean(audio * audio, axis=1)
    window, hop = max(1, round(.05 * rate)), max(1, round(.01 * rate))
    cumulative = np.concatenate([[0.0], np.cumsum(power)])
    starts = np.arange(0, max(1, len(audio) - window + 1), hop)
    stops = np.minimum(starts + window, len(audio))
    rms = np.sqrt(np.maximum(0, (cumulative[stops] - cumulative[starts]) / (stops - starts)))
    thresholds = {"absolute_minus60_dbfs": 10 ** (-60 / 20), "absolute_minus45_dbfs": 10 ** (-45 / 20), "relative_minus25_from_peak_rms": float(rms.max()) * 10 ** (-25 / 20), "relative_minus35_from_peak_rms": float(rms.max()) * 10 ** (-35 / 20)}
    low_observations = {}
    for label, threshold in thresholds.items():
        ranges = intervals(rms < threshold, hop / rate)
        low_observations[label] = {"linear_rms_threshold": threshold, "fraction_of_windows_below": float(np.mean(rms < threshold)), "intervals_at_least_150ms": ranges, "longest_interval_seconds": max((r["duration_seconds"] for r in ranges), default=0)}
    return {**record(path), "sample_rate_hz": rate, "channels": audio.shape[1], "frames": len(audio), "duration_seconds": len(audio) / rate, "finite": True, "nonzero": bool(np.any(audio)), "peak": float(np.abs(audio).max()), "rms": float(np.sqrt(power.mean())), "dc_per_channel": audio.mean(axis=0).tolist(), "rms_window_ms": 50, "rms_hop_ms": 10, "rms_timeline": rms.tolist(), "low_energy_observations": low_observations, "thresholds_are_diagnostics_not_style_or_continuity_approval": True, "intended_rests_and_final_tail_must_be_considered": True}

def lead_coverage(metadata: dict, observed: dict) -> dict:
    rate = observed["sample_rate_hz"]
    events = metadata["track"]["events"]
    rendered = metadata["sample_render_events"]
    leads = [r for r in rendered if events[r["event_index"]]["instrument"] == "dizi"]
    count = np.zeros(observed["frames"] + 1, dtype=np.int32)
    for event in leads:
        start = event["start_frame"]
        end = min(observed["frames"], start + event["rendered_frames"])
        count[start] += 1
        count[end] -= 1
    count = np.cumsum(count[:-1])
    musical_frames = min(len(count), round(metadata["musical_seconds"] * rate))
    timeline = np.asarray(observed["rms_timeline"])
    starts = np.arange(len(timeline)) * round(.01 * rate)
    active = count[np.minimum(starts, len(count) - 1)] > 0
    low = timeline < 10 ** (-45 / 20)
    return {"lead_event_count": len(leads), "rendered_event_coverage_fraction_of_musical_section": float(np.mean(count[:musical_frames] > 0)), "rendered_event_overlap_fraction_of_musical_section": float(np.mean(count[:musical_frames] > 1)), "low_minus45dbfs_intervals_inside_rendered_lead_coverage": intervals(low & active, .01), "event_start_end_coverage_is_not_pitch_or_style_proof": True}

def baseline_report() -> dict:
    before = protection()
    directory = ROOT / "assets/processed/audio/wuxia_original_trial_v2_20261009"
    metadata = json.loads((directory / "original_exploration.processing.json").read_text(encoding="utf-8"))
    lead = continuity(directory / "original_exploration_stem_dizi.wav")
    mix = continuity(directory / "original_exploration_audition.wav")
    source_manifest = ROOT / "assets/raw/audio/wuxia_original_samples_20261009/dizi/manifest.json"
    source = json.loads(source_manifest.read_text(encoding="utf-8"))
    source_observations = [{"root_midi": row["root_midi"], "observation": continuity(Path(row["preview_path"]))} for row in source["samples"]]
    result = {"schema": 1, "scope": "V2_AND_SOURCE_ENVELOPE_DIAGNOSTIC_NOT_MUSICAL_APPROVAL", "user_v2_verdict": "USER_REJECTED_DISCONNECTED_INTERMITTENT_MUSIC", "source_manifest_sha256": sha(source_manifest), "original_ogg_source_observations": source_observations, "v2_exploration_lead": lead, "v2_exploration_mix": mix, "v2_lead_event_coverage": lead_coverage(metadata, lead), "protection_before": before, "protection_after": protection(), "model_invocations": 0, "godot_started": False, "no_claim_numbers_replace_listening": True}
    save("source_and_v2_baseline.json", result)
    return result

def musical_quiet(observed: dict, seconds: float) -> dict:
    rms = np.asarray(observed["rms_timeline"])
    rms = rms[np.arange(len(rms)) * .01 + .05 <= seconds]
    threshold = 10 ** (-45 / 20)
    ranges = intervals(rms < threshold, .01)
    return {"section_seconds": seconds, "minus45dbfs_low_window_fraction": float(np.mean(rms < threshold)), "low_intervals_at_least150ms": ranges, "longest_low_interval_seconds": max((r["duration_seconds"] for r in ranges), default=0)}


def verify() -> dict:
    before = protection()
    directory = ROOT / "assets/processed/audio/wuxia_original_continuous_v3_20261009"
    manifest_path = directory / "manifest.json"
    metadata = json.loads(manifest_path.read_text(encoding="utf-8"))
    body_path = ROOT / "assets/raw/audio/wuxia_original_body_analysis_v3_20261009/dizi_stable_body_analysis.json"
    body = json.loads(body_path.read_text(encoding="utf-8"))
    pitch_path = ROOT / "assets/processed/audio/wuxia_original_qa_20261009/dan_tranh_source_pitch19_map.json"
    pitch = {r["sample_id"]: r for r in json.loads(pitch_path.read_text(encoding="utf-8"))["records"]}
    files = []
    def check_file(row):
        path = Path(row["path"])
        path = path if path.is_absolute() else ROOT / path
        actual = record(path)
        assert actual["sha256"] == row["sha256"], str(path)
        if "size" in row:
            assert actual["bytes"] == row["size"], str(path)
        files.append(actual)
        return path
    for key in ("script", "frozen_io_helpers", "score", "midi", "source_map"):
        check_file(metadata[key])
    for row in metadata["outputs"]:
        check_file(row)
    sources = {r["id"]: r for r in metadata["source_records"]}
    for row in sources.values():
        check_file(row)
        if row["instrument"] == "dan_tranh":
            verified = pitch[row["id"]]
            assert row["sha256"] == verified["sha256"] and row["root_midi"] == verified["root_midi"]
            assert row["estimated_midi_float"] == verified["estimated_midi_float"]
    body_rows = {r["root_midi"]: r for r in body["samples"]}
    body_observations = []
    for row in metadata["stable_body_observations"]:
        source = sources[row["sample_id"]]
        evidence = body_rows[source["root_midi"]]
        assert row["source_sha256"] == source["sha256"] == evidence["source_ogg_sha256"]
        assert row["start_frame"] == evidence["body_start_frame"] == 35280
        assert row["end_frame"] == evidence["body_end_frame_exclusive"] == 145530
        assert abs(row["body_estimated_midi_float"] - evidence["estimated_midi_float"]) < 1e-7
        rate, audio = decode(ROOT / source["path"])
        section = audio[row["start_frame"]:row["end_frame"]]
        bins = section[:len(section) // 2205 * 2205].reshape(-1, 2205, audio.shape[1])
        rms = np.sqrt(np.mean(bins * bins, axis=(1, 2)))
        variation = float(20 * np.log10(rms.max() / rms.min()))
        # Independent mono decoder amplitude differs from stereo resampling; compare normalized envelope.
        assert abs(variation - row["variation_db"]) < 1e-4
        assert not np.any(rms < 1e-7) and row["internal_silent_bins"] == 0
        body_observations.append({"sample_id": source["id"], "frames": len(section), "sample_rate": rate, "variation_db_independent_decode": variation, "silent50ms_bins": int(np.count_nonzero(rms < 1e-7)), "amplitude_scale_not_compared_between_mono_and_stereo_decoders": True})
    for rendered in metadata["sample_render_events"]:
        source = sources[rendered["sample_id"]]
        event = metadata["track"]["events"][rendered["event_index"]]
        assert source["sha256"] == rendered["sample_sha256"]
        assert source["root_midi"] == rendered["root_midi"]
        assert source.get("estimated_midi_float", source.get("root_midi")) == rendered["estimated_midi_float"]
        if event["midi"] is not None:
            ratio = 2 ** ((event["midi"] - rendered["estimated_midi_float"]) / 12)
            assert event["midi"] == rendered["target_midi"] and abs(ratio - rendered["pitch_ratio"]) < 1e-12
            assert rendered["resample_up"] == 1000 and rendered["resample_down"] == round(1000 * ratio)
        if event["instrument"] == "dizi":
            assert rendered["stable_body_used"] and not rendered["body_repeated_or_looped"]
    stems = {}
    observations = {}
    for name in metadata["mixing"]["stem_order"]:
        path = directory / ("v3_stem_" + name + ".wav")
        rate, audio = wavfile.read(path)
        assert rate == 44100 and audio.dtype == np.float32 and audio.shape == (metadata["output_frames"], 2)
        assert np.isfinite(audio).all() and np.any(audio)
        stems[name] = audio
        observations[name] = continuity(path)
    dry = np.zeros_like(stems["dizi"])
    for name in ("dizi", "dan_tranh", "gong"):
        dry += stems[name]
    room = np.zeros_like(dry)
    for i, (seconds, gain) in enumerate(metadata["room"]["delay_seconds_gain"]):
        offset = round(seconds * 44100)
        source = dry[:, ::-1] if i % 2 else dry
        room[offset:] += source[:-offset] * np.float32(gain)
    assert np.array_equal(room, stems["room_return"])
    rate, raw = wavfile.read(ROOT / metadata["mixing"]["raw_mix"]["path"])
    assert np.array_equal(dry + room, raw)
    mixing = metadata["mixing"]
    raw_rms = float(np.sqrt(np.mean(raw.T.astype(np.float64) ** 2)))
    expected_gain = min(10 ** (mixing["target_rms_dbfs"] / 20) / raw_rms, 10 ** (mixing["peak_cap_dbfs"] / 20) / float(np.abs(raw).max()))
    assert abs(expected_gain - mixing["linear_gain"]) < 1e-12
    audition = raw * mixing["linear_gain"]
    edge = mixing["edge_fade_frames"]
    audition[:edge] *= np.linspace(0, 1, edge, dtype=np.float32)[:, None]
    audition[-edge:] *= np.linspace(1, 0, edge, dtype=np.float32)[:, None]
    full_path = directory / "v3_continuous_exploration_audition.wav"
    preview_path = directory / "v3_first20s_audition.wav"
    preview = audition[:metadata["preview"]["frames"]].copy()
    fade = metadata["preview"]["last_fade_frames"]
    preview[-fade:] *= np.linspace(1, 0, fade, dtype=np.float32)[:, None]
    pcm_results = []
    for path, expected in ((full_path, audition), (preview_path, preview)):
        rate, pcm = wavfile.read(path)
        reference = (expected * mixing["pcm_scale"]).astype(np.int16)
        assert np.array_equal(pcm, reference)
        count = int(np.count_nonzero((pcm == 32767) | (pcm == -32768)))
        assert count == 0 and np.max(np.abs(pcm.astype(np.int32))) / 32768 < 10 ** (-3 / 20)
        observed = continuity(path)
        pcm_results.append({"observation": observed, "full_scale_samples": count, "processing_pcm_max_difference_lsb": 0})
    mp3 = []
    for row in metadata["outputs"]:
        if row["path"].endswith(".mp3"):
            observed = continuity(ROOT / row["path"])
            frames = metadata["preview"]["frames"] if "first20s" in row["path"] else metadata["output_frames"]
            assert observed["frames"] == frames and observed["sample_rate_hz"] == 44100 and observed["channels"] == 2
            assert observed["finite"] and observed["nonzero"] and observed["peak"] < 1
            mp3.append(observed)
    baseline = json.loads((OUT / "source_and_v2_baseline.json").read_text(encoding="utf-8"))
    result = {"schema": 1, "scope": "FINAL_V3_MINIMAL_OFFLINE_QA", "technical_pass": True, "manifest": record(manifest_path), "checked_files": files, "body_analysis": record(body_path), "pitch_map": record(pitch_path), "source_body_observations": body_observations, "render_event_source_pitch_metadata_count": len(metadata["sample_render_events"]), "stems": observations, "mix_math": {"raw_float32_sum_exact": True, "declared_room_delays_exact": True, "gain": expected_gain, "full_and_preview_pcm_exact": True, "sampler_note_rendering_not_reimplemented": True}, "pcm": pcm_results, "mp3": mp3, "v3_lead_coverage": lead_coverage(metadata, observations["dizi"]), "comparison": {"v2_lead_coverage": baseline["v2_lead_event_coverage"], "v2_lead_musical_section": musical_quiet(baseline["v2_exploration_lead"], 48), "v2_mix_musical_section": musical_quiet(baseline["v2_exploration_mix"], 48), "v3_lead_musical_section": musical_quiet(observations["dizi"], metadata["musical_seconds"]), "v3_mix_musical_section": musical_quiet(pcm_results[0]["observation"], metadata["musical_seconds"])}, "protection_before": before, "protection_after": protection(), "v2_user_verdict": "USER_REJECTED", "v3_verdict": "LISTENING_PENDING", "loop_approval": False, "style_or_professional_ear_approval": False, "model_invocations": 0, "godot_started": False}
    assert before["unchanged"] and result["protection_after"]["unchanged"]
    save("v3_final_offline.json", result)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("snapshot", "observe", "baseline", "verify"))
    parser.add_argument("--path", type=Path)
    parser.add_argument("--report", default="observation.json")
    args = parser.parse_args()
    if args.mode == "verify":
        try:
            data = verify()
        except Exception as exc:
            save("v3_final_offline_failed.json", {"technical_pass": False, "exception": repr(exc), "protection_after": protection(), "v3_verdict": "LISTENING_PENDING"})
            raise
        print(json.dumps({"report": str(OUT / "v3_final_offline.json"), "sha256": sha(OUT / "v3_final_offline.json"), "technical_pass": data["technical_pass"], "protected_unchanged": data["protection_after"]["unchanged"], "comparison": data["comparison"], "v3_lead_coverage": data["v3_lead_coverage"]}))
    elif args.mode == "snapshot":
        data = snapshot()
        print(json.dumps({"protected_files": len(data["protected_files"]), "production_files": data["production_file_count"], "player_paths": data["player_path_count"], "snapshot": str(SNAPSHOT)}))
    elif args.mode == "baseline":
        data = baseline_report()
        print(json.dumps({"report": str(OUT / "source_and_v2_baseline.json"), "source_count": len(data["original_ogg_source_observations"]), "protected_unchanged": data["protection_after"]["unchanged"]}))
    else:
        assert args.path
        before = protection()
        data = {"observation": continuity(args.path), "protection_before": before, "protection_after": protection(), "user_v2_verdict": "USER_REJECTED_DISCONNECTED_INTERMITTENT_MUSIC", "v3_verdict": "LISTENING_PENDING", "model_invocations": 0, "godot_started": False}
        save(args.report, data)
        print(json.dumps({"report": str(OUT / args.report), "protected_unchanged": data["protection_after"]["unchanged"]}))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
