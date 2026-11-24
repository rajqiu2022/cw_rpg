"""Independent WAV observations and read-only production/player preservation.

Only this script's JSON reports are written. No playback, Godot, asset conversion,
loop editing, musical/style approval, or license approval is performed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import struct
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
from scipy.io import wavfile
import av

ROOT = Path(__file__).resolve().parents[2]
REPORT_DIR = ROOT / "assets/processed/audio"
PROTECTION = REPORT_DIR / "wuxia_trial_20261009_protection.json"
DEFAULT_PLAYER_BASELINE = ROOT / "game/build/joint_world_luoyang_20261003_qa/411_luoyang_exact_rgba_four_publish_20261009/before.json"
DEFAULT_INPUTS = [ROOT / "assets/raw/audio/wuxia_ai_trial_20261009", ROOT / "assets/raw/audio/wuxia_sfx_ai_trial_20261009"]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def record(path: Path) -> dict:
    result = {"path": str(path.resolve()), "exists": path.is_file()}
    if result["exists"]:
        before = path.stat()
        result.update(bytes=before.st_size, mtime_ns=str(before.st_mtime_ns), sha256=sha(path))
        after = path.stat()
        if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
            raise RuntimeError("Protected file changed during read")
    return result


def production_paths() -> list[Path]:
    paths = set()
    for directory in (ROOT / "game/art/audio/bgm", ROOT / "game/art/audio/free"):
        paths.update(p for p in directory.rglob("*") if p.is_file())
    paths.update((ROOT / "game/data/scenes").rglob("*.tres"))
    paths.update([ROOT / "game/scripts/autoload/audio_manager.gd", ROOT / "game/scripts/battle/battle_controller.gd"])
    return sorted(paths)


def write_json(path: Path, value: dict) -> None:
    if not path.resolve().is_relative_to(REPORT_DIR.resolve()) or path.suffix.lower() != ".json":
        raise RuntimeError("QA writes must be JSON inside assets/processed/audio")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def snapshot(player_baseline: Path) -> dict:
    if PROTECTION.exists():
        raise RuntimeError("Refusing to replace the existing protection snapshot")
    source = json.loads(player_baseline.read_text(encoding="utf-8-sig"))
    player_rows = source.get("player_files")
    if not isinstance(player_rows, list) or len(player_rows) != 15:
        raise RuntimeError("Expected the existing baseline's exact 15 player paths")
    player_paths = [Path(row["path"]) for row in player_rows]
    if len(set(player_paths)) != 15:
        raise RuntimeError("Player baseline contains duplicate paths")
    result = {
        "schema": 1,
        "scope": "AUDIO_TRIAL_PROTECTION_ONLY_NOT_MUSICAL_OR_FIELD_APPROVAL",
        "created_utc": now(),
        "player_path_source": str(player_baseline.resolve()),
        "player_path_source_sha256": sha(player_baseline),
        "production_files": [record(p) for p in production_paths()],
        "player_files": [record(p) for p in player_paths],
        "player_contents_disclosed": False,
    }
    write_json(PROTECTION, result)
    return result


def compare(rows: list[dict]) -> list[dict]:
    changed = []
    for expected in rows:
        current = record(Path(expected["path"]))
        keys = ("exists", "bytes", "mtime_ns", "sha256")
        fields = [key for key in keys if current.get(key) != expected.get(key)]
        if fields:
            changed.append({"path": expected["path"], "changed_fields": fields})
    return changed


def inspect_wav(path: Path) -> dict:
    result = record(path)
    result.update(loop_preparation_verified=False, seamless_loop_claimed=False, audible_review="NOT_PERFORMED", wuxia_style_approval=False)
    try:
        rate, samples = wavfile.read(path)
        if samples.ndim not in (1, 2):
            raise ValueError("Unexpected WAV sample shape")
        channels = 1 if samples.ndim == 1 else samples.shape[1]
        dtype = samples.dtype
        floating = np.issubdtype(dtype, np.floating)
        if np.issubdtype(dtype, np.integer):
            info = np.iinfo(dtype)
            # scipy left-aligns 24-bit PCM in int32; normalize by int32 range.
            scale = float(max(abs(info.min), info.max))
            decoded = samples.astype(np.float64)
            if dtype == np.dtype("uint8"):
                decoded = (decoded - 128.0) / 128.0
            else:
                decoded /= scale
        elif np.issubdtype(dtype, np.floating):
            decoded = samples.astype(np.float64)
        else:
            raise ValueError("Unsupported PCM sample dtype")
        if decoded.ndim == 1:
            decoded = decoded[:, None]
        frames = len(decoded)
        finite = bool(np.all(np.isfinite(decoded)))
        if not frames or not rate or not channels or not finite:
            raise ValueError("WAV has empty or non-finite samples")
        peak = np.max(np.abs(decoded), axis=0)
        rms = np.sqrt(np.mean(decoded * decoded, axis=0))
        silence = np.max(np.abs(decoded), axis=1) < 10.0 ** (-60 / 20)
        # Diagnostic threshold, not a perceptual clipping or quality oracle.
        near_full_scale = np.abs(decoded) >= 0.9999
        integer_full_scale = np.zeros(samples.shape, dtype=bool)
        if np.issubdtype(dtype, np.integer):
            # RIFF fmt keeps the encoded bit depth (24-bit is returned as int32).
            bits = dtype.itemsize * 8
            with path.open("rb") as source:
                header = source.read(12)
                if header[:4] == b"RIFF" and header[8:12] == b"WAVE":
                    while chunk_header := source.read(8):
                        if len(chunk_header) != 8:
                            break
                        tag, length = struct.unpack("<4sI", chunk_header)
                        chunk = source.read(length) if tag == b"fmt " else None
                        if tag == b"fmt " and len(chunk) >= 16:
                            bits = struct.unpack_from("<H", chunk, 14)[0]
                            break
                        if chunk is None:
                            source.seek(length, 1)
                        if length % 2:
                            source.seek(1, 1)
            if dtype == np.dtype("uint8"):
                integer_full_scale = (samples == 0) | (samples == 255)
            else:
                shift = dtype.itemsize * 8 - bits
                positive_limit = ((1 << (bits - 1)) - 1) << shift
                negative_limit = -(1 << (dtype.itemsize * 8 - 1))
                integer_full_scale = (samples >= positive_limit) | (samples <= negative_limit)
        edge_frames = max(1, min(frames, int(rate * 0.05)))
        result.update(
            sample_rate_hz=int(rate), channels=int(channels), sample_dtype=str(dtype),
            frames=int(frames), duration_seconds=frames / rate, finite_samples=finite,
            peak_per_channel=peak.tolist(), peak_dbfs_per_channel=[float(20 * np.log10(p)) if p else None for p in peak],
            rms_per_channel=rms.tolist(), rms_dbfs_per_channel=[float(20 * np.log10(r)) if r else None for r in rms],
            dc_per_channel=np.mean(decoded, axis=0).tolist(),
            near_full_scale_sample_count=int(np.count_nonzero(near_full_scale)),
            near_full_scale_threshold=0.9999,
            outside_unit_range_sample_count=int(np.count_nonzero(np.abs(decoded) > 1.0)),
            encoding_kind="IEEE_FLOAT" if floating else "PCM_INTEGER",
            integer_full_scale_sample_count=None if floating else int(np.count_nonzero(integer_full_scale)),
            above_unity_is_not_float_hard_clipping=floating,
            actual_hard_clipping_claimed=False,
            silence_threshold_dbfs=-60, silence_frame_fraction=float(np.mean(silence)),
            all_zero=bool(np.all(decoded == 0)),
            first_50ms_rms=np.sqrt(np.mean(decoded[:edge_frames] ** 2, axis=0)).tolist(),
            last_50ms_rms=np.sqrt(np.mean(decoded[-edge_frames:] ** 2, axis=0)).tolist(),
            first_last_sample_difference=(decoded[-1] - decoded[0]).tolist(),
            technical_parse_pass=True,
            finite_nonzero_pass=bool(np.max(peak) > 0),
            playback_headroom_pass=bool(not np.any(np.abs(decoded) >= 1.0)) if floating else bool(not np.any(integer_full_scale)),
            basic_signal_pass=bool(np.max(peak) > 0),
            loop_status="NOT_VERIFIED_OR_EDITED_BY_QA; ORIGINAL_MODEL_OUTPUT_MAY_NOT_LOOP",
        )
    except Exception as error:
        result.update(technical_parse_pass=False, finite_nonzero_pass=False, playback_headroom_pass=False, basic_signal_pass=False, error=f"{type(error).__name__}: {error}")
    # Guard against checking a file while a model is still writing it.
    after = record(path)
    result["stable_during_inspection"] = after == {key: result[key] for key in after}
    return result


def processing_relationships(inputs: list[Path]) -> list[dict]:
    results = []
    for root in inputs:
        if not root.is_dir():
            continue
        for meta_path in sorted(root.glob("*.meta.json")):
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
            row = {"metadata_path": str(meta_path.resolve()), "metadata_sha256": sha(meta_path), "kind": "BGM_GAIN_AND_EDGE_FADE", "relationship_verified": False}
            try:
                technical = meta["technical_validation"]
                outputs = meta["outputs"]
                raw_path = ROOT / next(p for p in outputs if p.endswith("_raw.wav"))
                listen_path = ROOT / next(p for p in outputs if p.endswith("_listen.wav"))
                raw_rate, raw = wavfile.read(raw_path)
                listen_rate, listen = wavfile.read(listen_path)
                assert raw.dtype == np.float32 and listen.dtype == np.int16
                assert raw_rate == listen_rate == 44100 and raw.shape == listen.shape
                assert raw.ndim == 2 and raw.shape[1] == 2 and np.isfinite(raw).all()
                peak = float(np.abs(raw).max())
                assert peak > 0
                gain = min(1.0, 10 ** (-3 / 20) / peak)
                edge = min(662, len(raw) // 2)
                expected = raw * gain
                if edge:
                    expected[:edge] *= np.linspace(0, 1, edge, dtype=np.float32)[:, None]
                    expected[-edge:] *= np.linspace(1, 0, edge, dtype=np.float32)[:, None]
                pcm = (expected * 32767).astype("<i2")
                difference = np.abs(pcm.astype(np.int32) - listen.astype(np.int32))
                hashes_match = all(sha(ROOT / name) == value["sha256"] for name, value in outputs.items())
                fields_match = technical["raw_peak"] == peak and technical["linear_gain"] == gain and technical["edge_fade_frames"] == edge and technical["pcm_scale"] == 32767 and technical["quantization"] == "trunc_int16"
                row.update(raw_path=str(raw_path), listen_path=str(listen_path), measured_raw_peak=peak, independently_computed_gain=gain, independently_computed_edge_fade_frames=edge, outputs_hashes_match=hashes_match, declared_processing_fields_match=fields_match, max_pcm_difference=int(difference.max()), differing_pcm_samples=int(np.count_nonzero(difference)), relationship_verified=bool(hashes_match and fields_match and not np.any(difference)), loop_status="GAIN_AND_15MS_EDGE_FADES_ONLY; NO_SEAMLESS_LOOP_APPROVAL")
            except Exception as error:
                row["error"] = f"{type(error).__name__}: {error}"
            results.append(row)
        for processing_path in sorted(root.glob("*_audition.processing.json")):
            meta = json.loads(processing_path.read_text(encoding="utf-8"))
            row = {"metadata_path": str(processing_path.resolve()), "metadata_sha256": sha(processing_path), "kind": "BGM_AUDITION_LINEAR_RMS_GAIN_PEAK_CAP_AND_EDGE_FADE", "relationship_verified": False}
            try:
                raw_path = ROOT / meta["source"]
                audition_path = ROOT / next(p for p in meta["files"] if p.endswith("_audition.wav"))
                rate, raw = wavfile.read(raw_path)
                audition_rate, audition = wavfile.read(audition_path)
                assert raw.dtype == np.float32 and audition.dtype == np.int16
                assert rate == audition_rate == 44100 and raw.shape == audition.shape
                assert raw.ndim == 2 and raw.shape[1] == 2 and np.isfinite(raw).all()
                peak = float(np.abs(raw).max())
                # Metadata computes RMS on planar decoded channels. Preserve that
                # summation order independently; PCM WAV samples remain unchanged.
                rms = float(np.sqrt(np.mean(np.ascontiguousarray(raw.T).astype(np.float64) ** 2)))
                gain = min(10 ** (-22 / 20) / rms, 10 ** (-3 / 20) / peak)
                edge = min(662, len(raw) // 2)
                expected = raw * gain
                if edge:
                    expected[:edge] *= np.linspace(0, 1, edge, dtype=np.float32)[:, None]
                    expected[-edge:] *= np.linspace(1, 0, edge, dtype=np.float32)[:, None]
                pcm = (expected * 32767).astype("<i2")
                difference = np.abs(pcm.astype(np.int32) - audition.astype(np.int32))
                hashes_match = sha(raw_path) == meta["source_sha256"] and all(sha(ROOT / name) == value["sha256"] for name, value in meta["files"].items())
                fields_match = meta["source_peak"] == peak and meta["source_rms"] == rms and meta["linear_gain"] == gain and meta["edge_fade_frames"] == edge and meta["target_rms_dbfs"] == -22 and meta["peak_cap_dbfs"] == -3 and meta["pcm_scale"] == 32767 and meta["quantization"] == "trunc_int16"
                row.update(raw_path=str(raw_path), audition_path=str(audition_path), measured_raw_peak=peak, measured_raw_rms=rms, rms_summation_layout="PLANAR_CHANNEL_MAJOR", independently_computed_gain=gain, amplification_applied=gain > 1, independently_computed_edge_fade_frames=edge, outputs_hashes_match=hashes_match, declared_processing_fields_match=fields_match, max_pcm_difference=int(difference.max()), differing_pcm_samples=int(np.count_nonzero(difference)), relationship_verified=bool(hashes_match and fields_match and not np.any(difference)), loop_status="LINEAR_GAIN_AND_15MS_EDGE_FADES_ONLY; NO_SEAMLESS_LOOP_APPROVAL")
            except Exception as error:
                row["error"] = f"{type(error).__name__}: {error}"
            results.append(row)
        manifest_path = root / "manifest.json"
        if not manifest_path.is_file():
            continue
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        audition_parts = []
        audition_rate_expected = None
        for case in manifest.get("cases", []):
            row = {"metadata_path": str(manifest_path.resolve()), "metadata_sha256": sha(manifest_path), "kind": "SFX_DECLARED_CROP_GAIN_AND_EDGE_FADE", "id": case.get("id"), "relationship_verified": False, "event_selection_or_semantics_approval": False}
            try:
                raw_path, trim_path = ROOT / case["raw_path"], ROOT / case["trim_path"]
                rate, raw = wavfile.read(raw_path)
                trim_rate, trim = wavfile.read(trim_path)
                assert trim.dtype == np.int16 and rate == trim_rate == case["sample_rate"]
                raw_float = raw.astype(np.float32)
                if np.issubdtype(raw.dtype, np.integer):
                    raw_float /= float(max(abs(np.iinfo(raw.dtype).min), np.iinfo(raw.dtype).max))
                assert np.isfinite(raw_float).all()
                start, end = [round(seconds * rate) for seconds in case["source_range_seconds"]]
                assert 0 <= start < end <= len(raw_float) and end - start == len(trim)
                expected = raw_float[start:end].copy()
                edge = min(round(.002 * rate), len(expected) // 4)
                if edge:
                    expected[:edge] *= np.linspace(0, 1, edge)[:, None]
                    expected[-edge:] *= np.linspace(1, 0, edge)[:, None]
                gain = min(1.0, .82 / max(float(np.abs(expected).max()), 1e-9))
                expected *= gain
                audition_parts.extend([expected, np.zeros((int(.65 * rate), raw.shape[1]), dtype=np.float32), expected, np.zeros((int(1.1 * rate), raw.shape[1]), dtype=np.float32)])
                audition_rate_expected = rate
                difference = np.abs(expected.astype(np.float64) - trim.astype(np.float64) / 32768)
                hashes_match = sha(raw_path) == case["raw_sha256"] and sha(trim_path) == case["trim_sha256"]
                fields_match = case["gain"] == gain and case["channels"] == raw.shape[1]
                row.update(raw_path=str(raw_path), trim_path=str(trim_path), raw_encoding="IEEE_FLOAT" if np.issubdtype(raw.dtype, np.floating) else "PCM_INTEGER", measured_raw_peak=float(np.abs(raw_float).max()), crop_frame_range=[start, end], independently_computed_gain=gain, independently_computed_edge_fade_frames=edge, outputs_hashes_match=hashes_match, declared_processing_fields_match=fields_match, max_normalized_pcm_difference=float(difference.max()), quantization_tolerance=1 / 32768 + 2e-7, relationship_verified=bool(hashes_match and fields_match and float(difference.max()) <= 1 / 32768 + 2e-7), loop_status="ISOLATED_ONE_SHOT_EVENT; NO_LOOP_APPROVAL")
            except Exception as error:
                row["error"] = f"{type(error).__name__}: {error}"
            results.append(row)
        if manifest.get("cases") and "audition" in manifest:
            row = {"metadata_path": str(manifest_path.resolve()), "metadata_sha256": sha(manifest_path), "kind": "SFX_AUDITION_DECLARED_ORDER_TWICE_AND_SILENT_GAPS", "relationship_verified": False, "event_selection_or_semantics_approval": False}
            try:
                declared = manifest["audition"]
                audition_path = ROOT / declared["path"]
                audition_rate, samples = wavfile.read(audition_path)
                assert len(audition_parts) == 4 * len(manifest["cases"])
                assert samples.dtype == np.int16 and audition_rate == audition_rate_expected
                expected = np.concatenate(audition_parts)
                assert samples.shape == expected.shape
                difference = np.abs(samples.astype(np.float64) / 32768 - expected.astype(np.float64))
                order_match = declared["order"] == [case["id"] for case in manifest["cases"]]
                hashes_match = sha(audition_path) == declared["sha256"] and sha(ROOT / declared["mp3_path"]) == declared["mp3_sha256"]
                row.update(audition_path=str(audition_path), observed_frames=len(samples), expected_frames=len(expected), declared_order_matches=order_match, outputs_hashes_match=hashes_match, max_normalized_pcm_difference=float(difference.max()), quantization_tolerance=1 / 32768 + 2e-7, relationship_verified=bool(order_match and hashes_match and float(difference.max()) <= 1 / 32768 + 2e-7), loop_status="ONE_SHOT_AUDITION_SEQUENCE; NO_LOOP_APPROVAL")
            except Exception as error:
                row["error"] = f"{type(error).__name__}: {error}"
            results.append(row)
    return results


def inspect_mp3(path: Path) -> dict:
    result = record(path)
    try:
        with av.open(str(path)) as container:
            frames = list(container.decode(audio=0))
            assert frames
            rate = frames[0].sample_rate
            channels = len(frames[0].layout.channels)
            assert all(f.sample_rate == rate and len(f.layout.channels) == channels for f in frames)
            decoded = np.concatenate([f.to_ndarray() for f in frames], axis=1).astype(np.float64)
        finite = bool(np.isfinite(decoded).all())
        result.update(sample_rate_hz=rate, channels=channels, decoded_frames=sum(f.samples for f in frames), decoded_duration_seconds=sum(f.samples for f in frames) / rate, decoded_finite=finite, decoded_peak=float(np.abs(decoded).max()), decoded_rms=float(np.sqrt(np.mean(decoded ** 2))), decoded_samples_above_unity=int(np.count_nonzero(np.abs(decoded) > 1)), lossy_decode_peak_is_not_original_clipping=True, technical_decode_pass=finite and bool(np.any(decoded)), musical_or_wuxia_approval=False)
    except Exception as error:
        result.update(technical_decode_pass=False, error=f"{type(error).__name__}: {error}")
    after = record(path)
    result["stable_during_inspection"] = after == {key: result[key] for key in after}
    return result


def decoder_sidecar_checks(inputs: list[Path]) -> list[dict]:
    checks = []
    for root in inputs:
        if not root.is_dir():
            continue
        for path in sorted(root.rglob("*.decoder.json")):
            meta = json.loads(path.read_text(encoding="utf-8"))
            row = {"sidecar_path": str(path), "sidecar_sha256": sha(path), "fields_verified": False}
            try:
                raw_path = path.with_name(path.name.removesuffix(".decoder.json") + ".wav")
                rate, raw = wavfile.read(raw_path)
                assert raw.dtype == np.float32 and raw.ndim == 2 and raw.shape[1] == 2 and np.isfinite(raw).all()
                peak = float(np.abs(raw).max())
                rms = float(np.sqrt(np.mean(np.ascontiguousarray(raw.T).astype(np.float64) ** 2)))
                above = int(np.count_nonzero(np.abs(raw) > 1))
                matched = meta["raw_format"] == "IEEE_FLOAT32_STEREO" and meta["sample_rate"] == rate and meta["frames"] == len(raw) and meta["raw_peak"] == peak and meta["raw_rms"] == rms and meta["samples_above_unity"] == above and meta["export_clipping"] is False and meta["finite"] is True
                row.update(raw_path=str(raw_path), raw_sha256=sha(raw_path), measured_raw_peak=peak, measured_raw_rms=rms, samples_above_unity=above, rms_summation_layout="PLANAR_CHANNEL_MAJOR", fields_verified=bool(matched), float_above_unity_is_not_hard_clipping=True)
            except Exception as error:
                row["error"] = f"{type(error).__name__}: {error}"
            checks.append(row)
        manifest_path = root / "manifest.json"
        if manifest_path.is_file():
            meta = json.loads(manifest_path.read_text(encoding="utf-8"))
            reproduction = meta.get("reproduction")
            if reproduction:
                row = {"sidecar_path": str(manifest_path), "kind": "SFX_SOURCE_HELPER_AND_RUNTIME_REQUIREMENTS", "fields_verified": False}
                try:
                    row["fields_verified"] = sha(ROOT / reproduction["script"]) == reproduction["script_sha256"] and sha(ROOT / reproduction["float_export_wrapper"]) == reproduction["wrapper_sha256"] and sha(root / "runtime-requirements.txt") == reproduction["runtime_requirements_sha256"]
                except Exception as error:
                    row["error"] = f"{type(error).__name__}: {error}"
                checks.append(row)
    return checks


def verify(inputs: list[Path], report_path: Path) -> dict:
    baseline = json.loads(PROTECTION.read_text(encoding="utf-8"))
    old_paths = {row["path"] for row in baseline["production_files"]}
    current_paths = {str(p.resolve()) for p in production_paths()}
    production_changes = compare(baseline["production_files"])
    player_changes = compare(baseline["player_files"])
    waves = sorted({p for root in inputs if root.exists() for p in root.rglob("*") if p.is_file() and p.suffix.lower() == ".wav"})
    observations = [inspect_wav(path) for path in waves]
    relationships = processing_relationships(inputs)
    mp3_paths = sorted({p for root in inputs if root.exists() for p in root.rglob("*.mp3") if p.is_file()})
    mp3_observations = [inspect_mp3(path) for path in mp3_paths]
    sidecar_checks = decoder_sidecar_checks(inputs)
    after_production_changes = compare(baseline["production_files"])
    after_player_changes = compare(baseline["player_files"])
    end_paths = {str(p.resolve()) for p in production_paths()}
    protected_unchanged = not production_changes and not player_changes and not after_production_changes and not after_player_changes and old_paths == current_paths == end_paths
    expected_relationship_count = sum(p.name.endswith("_listen.wav") or p.name.endswith("_audition.wav") or p.parent.name == "trim" for p in waves)
    previous_probe_report = REPORT_DIR / "wuxia_trial_20261009_bgm_probe_report.json"
    prior_probe = {}
    if previous_probe_report.exists() and previous_probe_report.resolve() != report_path.resolve():
        old_probe = json.loads(previous_probe_report.read_text(encoding="utf-8"))
        prior_probe = {"baseline_report": str(previous_probe_report), "baseline_report_sha256": sha(previous_probe_report), "wave_changes": compare(old_probe["wav_observations"])}
    result = {
        "schema": 1, "created_utc": now(),
        "scope": "INDEPENDENT_AUDIO_TECHNICAL_OBSERVATIONS_NOT_MUSICAL_LICENSE_OR_FIELD_APPROVAL",
        "verifier_source": str(Path(__file__).resolve()), "verifier_source_sha256": sha(Path(__file__)),
        "protection_path": str(PROTECTION.resolve()), "protection_sha256": sha(PROTECTION),
        "protected_production_file_count": len(old_paths), "protected_player_path_count": len(baseline["player_files"]),
        "production_changes": production_changes, "player_changes": player_changes,
        "production_added_paths": sorted(current_paths - old_paths),
        "production_removed_paths": sorted(old_paths - current_paths),
        "production_changes_at_end": after_production_changes, "player_changes_at_end": after_player_changes,
        "production_and_player_unchanged": protected_unchanged,
        "input_directories": [{"path": str(p.resolve()), "exists": p.is_dir()} for p in inputs],
        "wav_count": len(waves), "wav_observations": observations,
        "mp3_count": len(mp3_paths), "mp3_observations": mp3_observations,
        "all_mp3_decode_pass": bool(mp3_observations) and all(r["technical_decode_pass"] and r["stable_during_inspection"] for r in mp3_observations),
        "decoder_and_source_sidecar_checks": sidecar_checks,
        "all_decoder_and_source_sidecars_verified": bool(sidecar_checks) and all(r["fields_verified"] for r in sidecar_checks),
        "all_wavs_basic_signal_pass": bool(waves) and all(row["basic_signal_pass"] and row["stable_during_inspection"] for row in observations),
        "all_wavs_finite_nonzero_pass": bool(waves) and all(row["finite_nonzero_pass"] and row["stable_during_inspection"] for row in observations),
        "all_wavs_playback_headroom_pass": bool(waves) and all(row["playback_headroom_pass"] for row in observations),
        "all_integer_wavs_playback_headroom_pass": bool(waves) and all(row["playback_headroom_pass"] for row in observations if row.get("encoding_kind") == "PCM_INTEGER"),
        "float_original_above_unity_is_not_model_invalidity": True,
        "processing_relationships": relationships,
        "expected_processing_relationship_count": expected_relationship_count,
        "all_available_processing_relationships_verified": bool(relationships) and len(relationships) == expected_relationship_count and all(r["relationship_verified"] for r in relationships),
        "historical_probe_preservation": prior_probe,
        "original_model_wavs_included": "All recursive .wav files, including originals and postprocessed candidates, are inspected",
        "loop_preparation_verified": False, "musical_or_wuxia_approval": False,
        "playback_performed": False, "godot_started": False, "protected_content_written": False,
    }
    write_json(report_path, result)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("snapshot", "verify"))
    parser.add_argument("--player-baseline", type=Path, default=DEFAULT_PLAYER_BASELINE)
    parser.add_argument("--input", type=Path, action="append")
    parser.add_argument("--report", type=Path, default=REPORT_DIR / "wuxia_trial_20261009_technical_report.json")
    args = parser.parse_args()
    if args.mode == "snapshot":
        result = snapshot(args.player_baseline)
        print(json.dumps({"snapshot": str(PROTECTION), "production_files": len(result["production_files"]), "player_paths": len(result["player_files"])}))
        return 0
    result = verify(args.input or DEFAULT_INPUTS, args.report)
    print(json.dumps({"report": str(args.report), "wav_count": result["wav_count"], "production_and_player_unchanged": result["production_and_player_unchanged"], "all_wavs_basic_signal_pass": result["all_wavs_basic_signal_pass"], "musical_approval": False}))
    return 0 if result["production_and_player_unchanged"] and result["all_wavs_basic_signal_pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
