"""Minimal offline checks of three loops from human-approved full recordings.

Reuses prior loop observations/decoders. No game, inference or asset writes.
Full-recording acceptance does not grant audible seam approval.
"""
import json
from pathlib import Path
import numpy as np
from scipy.io import wavfile
from verify_wuxia_audio_loops import ROOT, record, sha, changes, wav_observation
from verify_wuxia_audio_trial import inspect_mp3

OUT = ROOT / "assets/processed/audio/wuxia_approved_local_loops_qa_20261009"
SNAPSHOT = OUT / "protection.json"
MANIFEST = ROOT / "assets/processed/audio/wuxia_approved_local_loops_20261009/manifest.json"

def save(name, data):
    path = OUT / name
    assert not path.exists() and path.resolve().is_relative_to(OUT.resolve())
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def protection():
    baseline = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    changed = changes(baseline["protected_files"])
    roots = [Path(p) for p in baseline["frozen_roots"]]
    actual = {str(p.resolve()) for root in roots for p in root.rglob("*") if p.is_file()}
    expected = {r["path"] for r in baseline["protected_files"] if any(Path(r["path"]).is_relative_to(root) for root in roots)}
    return {"protected_file_count": len(baseline["protected_files"]), "sha_bytes_mtime_changes": changed, "added_frozen_paths": sorted(actual - expected), "removed_frozen_paths": sorted(expected - actual), "unchanged": not changed and actual == expected}

def verify():
    before = protection()
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    baseline = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    protected = {r["path"]: r["sha256"] for r in baseline["protected_files"] if r["exists"]}
    accepted = {str((ROOT / p).resolve()) for p in (
        "assets/raw/audio/wuxia_stable_personal_continuation_20261009/mountain_continuous_96s_raw.wav",
        "assets/raw/audio/wuxia_stable_personal_journey_alt_20261009/jianghu_continuous_96s_raw.wav",
        "assets/raw/audio/wuxia_stable_personal_continuation_20261009/combat_continuous_72s_raw.wav")}
    def check(row):
        p = ROOT / row["path"]
        assert sha(p) == row["sha256"] and p.stat().st_size == row["size"]
        return p
    provenance = [record(check(manifest[key])) for key in ("plan", "script", "selection_io_kernel")]
    assert manifest["model_invocation"] == "NONE" and manifest["game_integration"] == "NONE"
    results = []
    assert len(manifest["tracks"]) == 3
    for meta in manifest["tracks"]:
        source = check(meta["source"])
        assert str(source.resolve()) in accepted
        assert meta["source"]["sha256"] == protected[str(source.resolve())]
        rate, raw = wavfile.read(source)
        assert rate == 44100 and raw.dtype == np.float32 and raw.ndim == 2 and raw.shape[1] == 2 and np.isfinite(raw).all()
        selected = meta["loop"]["selected"]
        start, end, overlap = [selected[k] for k in ("start_frame", "end_frame", "crossfade_frames")]
        assert 0 <= start < start + overlap < end - overlap < end <= len(raw)
        assert end <= meta["analysis_source_end_frame_exclusive"] == round(meta["track"]["analysis_end_seconds"] * rate)
        metadata_path = MANIFEST.parent / (meta["track"]["id"] + ".processing.json")
        assert json.loads(metadata_path.read_text(encoding="utf-8")) == meta
        weight = np.linspace(0, 1, overlap, dtype=np.float32)[:, None]
        joined = np.concatenate([raw[start + overlap:end - overlap], raw[end - overlap:end] * (1 - weight) + raw[start:start + overlap] * weight])
        rms = float(np.sqrt(np.mean(np.ascontiguousarray(joined.T).astype(np.float64) ** 2)))
        peak = float(np.abs(joined).max())
        gain = min(10 ** (-22 / 20) / rms, 10 ** (-3 / 20) / peak)
        reference = (joined * gain * 32767).astype(np.int16)
        processing = meta["processing"]
        assert meta["loop"]["loop_frames"] == len(joined)
        assert len(joined) / rate >= meta["track"]["minimum_loop_seconds"]
        assert processing["linear_gain"] == gain and processing["pre_gain_loop_rms"] == rms and processing["pre_gain_loop_peak"] == peak
        assert processing["edge_silence_fade"] is False and processing["quantization"] == "trunc_int16" and processing["pcm_scale"] == 32767
        files = [check(row) for row in meta["outputs"]]
        loop_path = next(p for p in files if p.name.endswith("_loop.wav"))
        seam_path = next(p for p in files if p.name.endswith("_seam10.wav"))
        loop_rate, actual = wavfile.read(loop_path)
        seam_rate, seam = wavfile.read(seam_path)
        assert loop_rate == seam_rate == rate and actual.dtype == seam.dtype == np.int16
        assert np.array_equal(actual, reference)
        assert np.array_equal(seam, np.concatenate([actual[-5 * rate:], actual[:5 * rate]]))
        assert np.array_equal(joined[0] - joined[-1], raw[start + overlap] - raw[start + overlap - 1])
        observations = [wav_observation(loop_path), wav_observation(seam_path)]
        assert all(r["finite_nonzero"] and r["integer_full_scale_samples"] == 0 and max(r["peak_per_channel"]) < 10 ** (-3 / 20) for r in observations)
        decoded = [inspect_mp3(p) for p in files if p.suffix == ".mp3"]
        assert len(decoded) == 2 and all(r["technical_decode_pass"] and r["channels"] == 2 and r["sample_rate_hz"] == rate for r in decoded)
        for r in decoded:
            expected_frames = 10 * rate if "seam10" in r["path"] else len(joined)
            assert r["decoded_frames"] == expected_frames
        results.append({"id": meta["track"]["id"], "source": record(source), "processing_metadata": record(metadata_path), "selected_source_frames": [start, end], "analysis_prefix_end_frame": meta["analysis_source_end_frame_exclusive"], "crossfade_frames": overlap, "source_pcm_relationship_exact": True, "max_pcm_difference_lsb": 0, "seam_last5_plus_first5_exact": True, "original_adjacent_boundary_pair_preserved": True, "gain": gain, "wav": observations, "mp3": decoded, "persistent_godot_loop_flag_present": False, "audible_loop_approval": False})
    assert {r["source"]["path"] for r in results} == accepted
    after = protection()
    assert before["unchanged"] and after["unchanged"]
    report = {"scope": "THREE_APPROVED_FULL_TRACKS_LOOP_STAGING_OFFLINE_ONLY", "technical_pass": True, "manifest": record(MANIFEST), "production_provenance": provenance, "tracks": results, "protection_before": before, "protection_after": after, "full_track_listening_approved_by_user": True, "audible_loop_approval": False, "loop_review": "LISTENING_PENDING", "godot_started": False, "formal_adopted": False, "model_invocations": 0, "runtime_loop_flag_required": "AudioStreamWAV.LOOP_FORWARD; loop_begin=0; loop_end=actual_frames; not tested"}
    save("three_approved_loops_offline.json", report)
    return report

if __name__ == "__main__":
    try:
        result = verify()
    except Exception as error:
        save("three_approved_loops_failed.json", {"technical_pass": False, "error": repr(error), "protection_after": protection(), "audible_loop_approval": False})
        raise
    path = OUT / "three_approved_loops_offline.json"
    print(json.dumps({"technical_pass": result["technical_pass"], "report": str(path), "sha256": sha(path), "protected_unchanged": result["protection_after"]["unchanged"]}))
