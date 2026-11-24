"""Independent QA for loops derived from approved first-batch raw recordings.

No model inference, audio/game/save editing, playback, or Godot startup.
The human accepted the first-batch direction; new loop listening is separate.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path
import numpy as np
from scipy.io import wavfile
import av

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/processed/audio/wuxia_audio_loop_qa_20261009"
SNAPSHOT = OUT / "protection.json"
FIRST_SNAPSHOT = ROOT / "assets/processed/audio/wuxia_trial_20261009_protection.json"
FIRST_REPORT = ROOT / "assets/processed/audio/wuxia_trial_20261009_technical_report.json"
FIRST_ROOTS = [ROOT / "assets/raw/audio/wuxia_ai_trial_20261009", ROOT / "assets/raw/audio/wuxia_sfx_ai_trial_20261009"]
FIRST_SCRIPTS = ["generate_stable_sfx_trial.py", "make_stable_wuxia_auditions.py", "produce_wuxia_stable_trial.py", "run_stable_wuxia_inference.py", "verify_wuxia_audio_trial.py", "wuxia_stable_trial_plan_20261009.json"]

def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1048576), b""):
            h.update(block)
    return h.hexdigest()

def record(path: Path) -> dict:
    row = {"path": str(path.resolve()), "exists": path.is_file()}
    if row["exists"]:
        before = path.stat()
        row.update(bytes=before.st_size, mtime_ns=str(before.st_mtime_ns), sha256=sha(path))
        after = path.stat()
        if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
            raise RuntimeError("File changed while being read")
    return row

def changes(rows: list[dict]) -> list[dict]:
    result = []
    for old in rows:
        current = record(Path(old["path"]))
        fields = [key for key in ("exists", "bytes", "mtime_ns", "sha256") if old.get(key) != current.get(key)]
        if fields:
            result.append({"path": old["path"], "changed_fields": fields})
    return result

def save(name: str, value: dict) -> None:
    path = OUT / name
    if not path.resolve().is_relative_to(OUT.resolve()) or path.suffix != ".json":
        raise RuntimeError("Reports must stay in the new QA directory")
    OUT.mkdir(parents=True, exist_ok=True)
    if path.exists():
        raise RuntimeError("Existing reports are preserved; choose a NEW report name")
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def snapshot() -> dict:
    old = json.loads(FIRST_SNAPSHOT.read_text(encoding="utf-8"))
    report = json.loads(FIRST_REPORT.read_text(encoding="utf-8"))
    assert len(old["production_files"]) == 279 and len(old["player_files"]) == 15
    original_changes = changes(old["production_files"]) + changes(old["player_files"])
    assert not original_changes, "First-batch protected game/player files have changed"
    assert report["production_and_player_unchanged"]
    first_paths = {p for root in FIRST_ROOTS for p in root.rglob("*") if p.is_file()}
    first_paths.update(ROOT / "scripts/audio" / name for name in FIRST_SCRIPTS)
    first_paths.update([FIRST_SNAPSHOT, FIRST_REPORT])
    result = {"schema": 1, "created_utc": datetime.now(timezone.utc).isoformat(), "scope": "NEW_EXISTING_AUDIO_LOOP_PREPARATION_PROTECTION", "prior_protection_sha256": sha(FIRST_SNAPSHOT), "prior_report_sha256": sha(FIRST_REPORT), "production_files": [record(Path(r["path"])) for r in old["production_files"]], "player_files": [record(Path(r["path"])) for r in old["player_files"]], "first_batch_files": [record(p) for p in sorted(first_paths)], "first_batch_roots": [str(p) for p in FIRST_ROOTS], "model_inference_authorized": False, "player_contents_disclosed": False}
    save("protection.json", result)
    return result

def preservation() -> dict:
    baseline = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    result = {key + "_changes": changes(baseline[key]) for key in ("production_files", "player_files", "first_batch_files")}
    current = {str(p.resolve()) for root in FIRST_ROOTS for p in root.rglob("*") if p.is_file()}
    expected = {r["path"] for r in baseline["first_batch_files"] if any(Path(r["path"]).is_relative_to(root) for root in FIRST_ROOTS)}
    result["first_batch_added_paths"] = sorted(current - expected)
    result["first_batch_removed_paths"] = sorted(expected - current)
    result["unchanged"] = not any(result.values())
    return result

def wav_observation(path: Path) -> dict:
    row = record(path)
    rate, pcm = wavfile.read(path)
    raw = pcm.astype(np.float64)
    if np.issubdtype(pcm.dtype, np.integer):
        raw /= float(max(abs(np.iinfo(pcm.dtype).min), np.iinfo(pcm.dtype).max))
    if raw.ndim == 1:
        raw = raw[:, None]
    assert len(raw) and np.isfinite(raw).all()
    jump = np.abs(raw[-1] - raw[0])
    differences = np.abs(np.diff(raw, axis=0))
    row.update(sample_rate_hz=rate, channels=raw.shape[1], sample_dtype=str(pcm.dtype), frames=len(raw), duration_seconds=len(raw) / rate, finite_nonzero=bool(np.any(raw)), peak_per_channel=np.max(np.abs(raw), axis=0).tolist(), rms_per_channel=np.sqrt(np.mean(raw ** 2, axis=0)).tolist(), dc_per_channel=np.mean(raw, axis=0).tolist(), samples_above_unity=int(np.count_nonzero(np.abs(raw) > 1)), integer_full_scale_samples=int(np.count_nonzero((pcm == -32768) | (pcm == 32767))) if pcm.dtype == np.int16 else None, boundary_jump_per_channel=jump.tolist(), interior_max_jump_per_channel=np.max(differences, axis=0).tolist(), interior_99_9_percentile_jump_per_channel=np.quantile(differences, .999, axis=0).tolist(), boundary_jump_is_numeric_not_audible_approval=True)
    return row

def verify_existing_loops(manifest_path: Path) -> dict:
    before = preservation()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    tracks = manifest["tracks"]
    assert len(tracks) == 3 and all(t["track"]["id"].startswith("approved_") for t in tracks)
    baseline = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    source_sha = {r["path"]: r["sha256"] for r in baseline["first_batch_files"] if r["exists"]}
    results = []
    for meta in tracks:
        row = {"id": meta["track"]["id"], "technical_pass": False}
        try:
            path = ROOT / meta["source"]["path"]
            assert sha(path) == meta["source"]["sha256"] == source_sha[str(path.resolve())]
            rate, audio = wavfile.read(path)
            assert rate == 44100 and audio.dtype == np.float32 and audio.ndim == 2 and audio.shape[1] == 2
            selected = meta["loop"]["selected"]
            start, end, overlap = [selected[k] for k in ("start_frame", "end_frame", "crossfade_frames")]
            assert 0 <= start < start + overlap < end - overlap < end <= len(audio)
            weight = np.linspace(0, 1, overlap, dtype=np.float32)[:, None]
            joined = np.concatenate([audio[start + overlap:end - overlap], audio[end - overlap:end] * (1 - weight) + audio[start:start + overlap] * weight])
            rms = float(np.sqrt(np.mean(np.ascontiguousarray(joined.T).astype(np.float64) ** 2)))
            peak = float(np.abs(joined).max())
            gain = min(10 ** (-22 / 20) / rms, 10 ** (-3 / 20) / peak)
            processed = joined * gain
            expected_pcm = (processed * 32767).astype("<i2")
            outputs = meta["outputs"]
            assert all(sha(ROOT / r["path"]) == r["sha256"] and (ROOT / r["path"]).stat().st_size == r["size"] for r in outputs)
            loop_path = ROOT / next(r["path"] for r in outputs if r["path"].endswith("_loop.wav"))
            seam_path = ROOT / next(r["path"] for r in outputs if r["path"].endswith("_seam10.wav"))
            loop_rate, actual = wavfile.read(loop_path)
            seam_rate, seam = wavfile.read(seam_path)
            assert loop_rate == seam_rate == rate and actual.dtype == seam.dtype == np.int16
            assert actual.shape == expected_pcm.shape
            expected_seam = np.concatenate([actual[-5 * rate:], actual[:5 * rate]])
            pcm_match, seam_match = np.array_equal(actual, expected_pcm), np.array_equal(seam, expected_seam)
            adjacent = np.array_equal(joined[0] - joined[-1], audio[start + overlap] - audio[start + overlap - 1])
            fields = meta["loop"]["loop_frames"] == len(joined) and meta["processing"]["linear_gain"] == gain and meta["processing"]["pre_gain_loop_rms"] == rms and meta["processing"]["pre_gain_loop_peak"] == peak and meta["processing"]["edge_silence_fade"] is False and meta["processing"]["quantization"] == "trunc_int16" and meta["processing"]["pcm_scale"] == 32767
            decoded = []
            for output in outputs:
                mp3_path = ROOT / output["path"]
                if mp3_path.suffix != ".mp3":
                    continue
                with av.open(str(mp3_path)) as container:
                    frames = list(container.decode(audio=0))
                    samples = np.concatenate([f.to_ndarray() for f in frames], axis=1)
                    assert samples.size and np.isfinite(samples).all() and np.any(samples)
                    decoded.append({"path": str(mp3_path), "sample_rate_hz": frames[0].sample_rate, "channels": len(frames[0].layout.channels), "decoded_duration_seconds": sum(f.samples for f in frames) / frames[0].sample_rate, "peak": float(np.abs(samples).max()), "rms": float(np.sqrt(np.mean(samples.astype(np.float64) ** 2))), "decode_pass": True})
            observation, seam_observation = wav_observation(loop_path), wav_observation(seam_path)
            row.update(source_path=str(path), source_sha256=sha(path), source_selection=[start, end], overlap_frames=overlap, reconstructed_frames=len(joined), independent_gain=gain, selected_source_math_verified=bool(pcm_match and fields), exact_pcm_match=pcm_match, max_pcm_difference=int(np.max(np.abs(actual.astype(np.int32) - expected_pcm.astype(np.int32)))), original_adjacent_boundary_pair_preserved=adjacent, seam_excerpt_exact_pcm_match=seam_match, loop_observation=observation, seam_observation=seam_observation, mp3_decodes=decoded, persistent_godot_loop_flag_present=False, persistent_loop_flag_note="PCM WAV output carries no declared Godot import/resource loop setting; runtime must set LOOP_FORWARD and full-frame range", technical_pass=bool(pcm_match and fields and adjacent and seam_match and observation["finite_nonzero"] and not observation["integer_full_scale_samples"] and seam_observation["finite_nonzero"] and not seam_observation["integer_full_scale_samples"]), audible_loop_or_style_approval=False)
        except Exception as error:
            row["error"] = f"{type(error).__name__}: {error}"
        results.append(row)
    after = preservation()
    result = {"schema": 1, "scope": "EXISTING_THREE_LOOP_OFFLINE_QA_ONLY_FROZEN_AFTER_USER_CHANGED_DIRECTION", "created_utc": datetime.now(timezone.utc).isoformat(), "verifier_source_sha256": sha(Path(__file__)), "manifest_path": str(manifest_path), "manifest_sha256": sha(manifest_path), "protection_before": before, "protection_after": after, "tracks": results, "all_three_offline_technical_pass": all(r["technical_pass"] for r in results) and before["unchanged"] and after["unchanged"], "loop_flag_runtime_not_verified": True, "godot_started": False, "model_invocations": 0, "formal_adoption": False, "audible_loop_approval": False, "future_stable_generation_authorized": False}
    save("three_existing_loops_offline.json", result)
    return result

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("snapshot", "preservation", "verify"))
    parser.add_argument("--report", default="preservation.json")
    args = parser.parse_args()
    if args.mode == "snapshot":
        data = snapshot()
        print(json.dumps({"production_files": len(data["production_files"]), "player_paths": len(data["player_files"]), "first_batch_files": len(data["first_batch_files"]), "snapshot": str(SNAPSHOT)}))
    elif args.mode == "verify":
        data = verify_existing_loops(ROOT / "assets/processed/audio/wuxia_audio_bank_v9_20261009/manifest.json")
        print(json.dumps({"tracks": len(data["tracks"]), "all_three_offline_technical_pass": data["all_three_offline_technical_pass"], "report": str(OUT / "three_existing_loops_offline.json")}))
        return 0 if data["all_three_offline_technical_pass"] else 1
    else:
        data = preservation()
        save(args.report, data)
        print(json.dumps({"unchanged": data["unchanged"], "report": str(OUT / args.report)}))
        return 0 if data["unchanged"] else 1
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
