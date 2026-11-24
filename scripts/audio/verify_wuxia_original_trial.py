"""Offline, independent QA for newly authored score/MIDI and recorded-sample mixes.

No model calls, score re-composition, playback, Godot, game or save writes.
Run with python -B to avoid bytecode-cache writes for the shared QA helpers.
"""
from __future__ import annotations
import argparse
import json
import struct
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
import numpy as np
from scipy.io import wavfile
from scipy.signal import correlate, find_peaks
import av
from verify_wuxia_audio_loops import ROOT, record, sha, preservation, wav_observation, SNAPSHOT, changes

OUT = ROOT / "assets/processed/audio/wuxia_original_qa_20261009"
RAW = ROOT / "assets/raw/audio/wuxia_original_trial_20261009"
PROCESSED = ROOT / "assets/processed/audio/wuxia_original_trial_20261009"

def save(name: str, value: dict) -> None:
    path = OUT / name
    assert path.resolve().is_relative_to(OUT.resolve()) and path.suffix == ".json"
    OUT.mkdir(parents=True, exist_ok=True)
    if path.exists():
        raise RuntimeError("Original QA reports are preserved; use a NEW report filename")
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

def variable(data: bytes, position: int) -> tuple[int, int]:
    value = 0
    for _ in range(4):
        part = data[position]
        position += 1
        value = (value << 7) | (part & 127)
        if not part & 128:
            return value, position
    raise ValueError("MIDI variable-length quantity exceeded four bytes")

def midi_event_stats(path: Path) -> dict:
    data = path.read_bytes()
    assert data[:4] == b"MThd"
    length = struct.unpack_from(">I", data, 4)[0]
    fmt, track_count, division = struct.unpack_from(">HHH", data, 8)
    assert length == 6 and fmt in (0, 1) and 0 < division < 32768
    position = 8 + length
    tempos, tracks, all_notes = [], [], []
    for index in range(track_count):
        assert data[position:position + 4] == b"MTrk"
        length = struct.unpack_from(">I", data, position + 4)[0]
        chunk = data[position + 8:position + 8 + length]
        assert len(chunk) == length
        position += 8 + length
        cursor, tick, status, ended = 0, 0, None, False
        active, notes, programs, name = {}, [], [], ""
        while cursor < len(chunk):
            delta, cursor = variable(chunk, cursor)
            tick += delta
            if chunk[cursor] >= 128:
                status = chunk[cursor]
                cursor += 1
            assert status is not None
            if status == 255:
                kind = chunk[cursor]
                cursor += 1
                count, cursor = variable(chunk, cursor)
                body = chunk[cursor:cursor + count]
                cursor += count
                assert len(body) == count
                if kind == 81:
                    assert count == 3
                    tempos.append((tick, int.from_bytes(body, "big")))
                elif kind == 3:
                    name = body.decode("utf-8", errors="replace")
                elif kind == 47:
                    assert count == 0 and cursor == len(chunk)
                    ended = True
                status = None
            elif status in (240, 247):
                count, cursor = variable(chunk, cursor)
                cursor += count
                status = None
            else:
                kind, channel = status >> 4, status & 15
                count = 1 if kind in (12, 13) else 2
                body = chunk[cursor:cursor + count]
                cursor += count
                assert len(body) == count and all(b < 128 for b in body)
                if kind == 12:
                    programs.append({"channel": channel, "program": body[0]})
                elif kind == 9 and body[1] > 0:
                    active.setdefault((channel, body[0]), []).append((tick, body[1]))
                elif kind == 8 or (kind == 9 and body[1] == 0):
                    queue = active.get((channel, body[0]), [])
                    assert queue, "MIDI note-off without a note-on"
                    start, velocity = queue.pop(0)
                    assert tick > start
                    notes.append({"channel": channel, "pitch": body[0], "velocity": velocity, "start_tick": start, "end_tick": tick, "duration_ticks": tick - start})
        assert ended and not any(active.values())
        tracks.append({"index": index, "name": name, "end_tick": tick, "programs": programs, "note_count": len(notes), "notes": notes})
        all_notes.extend(notes)
    assert position == len(data) and all_notes
    unique_tempos = sorted(set(tempos)) or [(0, 500000)]
    assert len({t for t, _ in unique_tempos}) == len(unique_tempos)
    def seconds(at: int) -> float:
        elapsed, previous, tempo = 0.0, 0, 500000
        for change_tick, next_tempo in unique_tempos:
            if change_tick > at:
                break
            elapsed += (change_tick - previous) * tempo / division / 1000000
            previous, tempo = change_tick, next_tempo
        return elapsed + (at - previous) * tempo / division / 1000000
    final_tick = max(t["end_tick"] for t in tracks)
    return {**record(path), "format": fmt, "ppq": division, "track_count": track_count, "tempo_changes": [{"tick": tick, "microseconds_per_quarter": value} for tick, value in unique_tempos], "end_tick": final_tick, "duration_seconds": seconds(final_tick), "note_count": len(all_notes), "first_note_seconds": seconds(min(n["start_tick"] for n in all_notes)), "last_note_end_seconds": seconds(max(n["end_tick"] for n in all_notes)), "tracks": tracks, "note_pairing_valid": True}

def mp3_observation(path: Path) -> dict:
    with av.open(str(path)) as container:
        frames = list(container.decode(audio=0))
        assert frames
        samples = np.concatenate([f.to_ndarray() for f in frames], axis=1).astype(np.float64)
        assert np.isfinite(samples).all() and np.any(samples)
    rate = frames[0].sample_rate
    return {**record(path), "sample_rate_hz": rate, "channels": len(frames[0].layout.channels), "decoded_frames": sum(f.samples for f in frames), "duration_seconds": sum(f.samples for f in frames) / rate, "peak": float(np.abs(samples).max()), "rms": float(np.sqrt(np.mean(samples * samples))), "finite_nonzero": True, "above_unity_sample_count": int(np.count_nonzero(np.abs(samples) > 1)), "lossy_decode_peak_not_original_pcm_clipping": True}

def readiness(name: str) -> dict:
    result = {"schema": 1, "created_utc": datetime.now(timezone.utc).isoformat(), "scope": "ORIGINAL_TRIAL_QA_PREPARED_NOT_OUTPUT_APPROVAL", "verifier_source_sha256": sha(Path(__file__)), "continued_protection_snapshot": str(SNAPSHOT), "continued_protection_snapshot_sha256": sha(SNAPSHOT), "protection": preservation(), "raw_directory_exists": RAW.is_dir(), "processed_directory_exists": PROCESSED.is_dir(), "manifest_exists": (PROCESSED / "manifest.json").is_file(), "model_invocations": 0, "godot_started": False, "audible_approval": False}
    save(name, result)
    return result

def checked_record(row: dict, require_size: bool = True) -> dict:
    path = ROOT / row["path"]
    actual = record(path)
    assert actual["exists"] and actual["sha256"] == row["sha256"]
    if require_size or "size" in row:
        assert actual["bytes"] == row["size"]
    return actual

def dan_pitch_report(name: str, additional_manifest: Path | None = None) -> dict:
    before = preservation()
    source_path = RAW / "sample_sources.json"
    source = json.loads(source_path.read_text(encoding="utf-8"))
    source_rows = list(source["records"])
    if additional_manifest is not None:
        additional = json.loads(additional_manifest.read_text(encoding="utf-8"))
        source_rows.extend(additional["records"])
    observations = []
    for row in source_rows:
        if row["instrument"] != "dan_tranh" or row["style"] not in ("pluck", "tremolo"):
            continue
        checked_record(row)
        rate, samples = wavfile.read(ROOT / row["path"])
        mono = samples.astype(np.float64).mean(axis=1) if samples.ndim == 2 else samples.astype(np.float64)
        windows = []
        for start in (.10, .25, .40):
            signal = mono[round(start * rate):round((start + .35) * rate)].copy()
            signal -= signal.mean()
            correlation = correlate(signal, signal, mode="full", method="fft")[len(signal) - 1:]
            correlation /= correlation[0]
            low, high = round(rate / 1800), round(rate / 70)
            peaks, _ = find_peaks(correlation[low:high])
            assert len(peaks)
            lag = int(peaks[np.argmax(correlation[peaks + low])]) + low
            denominator = correlation[lag - 1] - 2 * correlation[lag] + correlation[lag + 1]
            offset = .5 * (correlation[lag - 1] - correlation[lag + 1]) / denominator if denominator else 0
            fundamental = rate / (lag + offset)
            frequency = np.fft.rfftfreq(262144, 1 / rate)
            spectrum = np.abs(np.fft.rfft(signal * np.hanning(len(signal)), 262144))
            def magnitude(center):
                return float(spectrum[np.abs(frequency - center) < center * .025].max())
            root_midi = float(69 + 12 * np.log2(fundamental / 440))
            windows.append({"start_seconds": start, "window_seconds": .35, "f0_hz": float(fundamental), "estimated_midi": root_midi, "autocorrelation_at_fundamental": float(correlation[lag]), "fundamental_band_magnitude": magnitude(fundamental), "suboctave_band_magnitude": magnitude(fundamental / 2), "second_harmonic_band_magnitude": magnitude(fundamental * 2)})
        measured = float(np.median([w["estimated_midi"] for w in windows]))
        declared = row.get("root_midi")
        cents = (measured - declared) * 100 if declared is not None else None
        observations.append({"id": row["id"], "style": row["style"], "path": row["path"], "sha256": row["sha256"], "declared_root_midi": declared, "root_declaration_pending": declared is None, "independent_median_midi": measured, "measured_root_midi_float": measured, "measured_root_midi": round(measured), "nearest_measured_midi": round(measured), "cents_from_declared_root": cents, "windows": windows, "declared_pitch_matches_within_50_cents": abs(cents) <= 50 if cents is not None else False, "pitch_tolerance_cents": 50, "max_suboctave_to_fundamental_magnitude_ratio": max(w["suboctave_band_magnitude"] / w["fundamental_band_magnitude"] for w in windows), "root_estimation_method": "Highest local autocorrelation peak with parabolic lag interpolation; independent spectral checks at fundamental/suboctave/second harmonic, three windows"})
    after = preservation()
    result = {"schema": 1, "scope": "NEW_INDEPENDENT_DAN_TRANH_NORMAL_AND_TREMOLO_SAMPLE_PITCH_AUDIT", "source_manifest_sha256": sha(source_path), "sample_count": len(observations), "samples": observations, "all_declared_roots_match": all(r["declared_pitch_matches_within_50_cents"] for r in observations), "protection_before": before, "protection_after": after, "no_composition_or_source_changes": True, "no_model_or_godot": True, "professional_ear_approval": False}
    save(name, result)
    if additional_manifest is not None:
        map_name = name.removesuffix(".json") + "_map.json"
        save(map_name, {"source_pitch_report": str(OUT / name), "source_pitch_report_sha256": sha(OUT / name), "records": [{"sample_id": r["id"], "path": r["path"], "sha256": r["sha256"], "source_sha256": r["sha256"], "root_midi": r["measured_root_midi"], "estimated_midi_float": r["measured_root_midi_float"], "max_suboctave_to_fundamental_magnitude_ratio": r["max_suboctave_to_fundamental_magnitude_ratio"]} for r in observations]})
    return result

def source_evidence(manifest: dict) -> dict:
    vcsl, dizi = manifest["sources"], manifest["dizi_sources"]
    license_files = [checked_record(r) for r in vcsl["license_files"]]
    license_text = "\n".join(Path(r["path"]).read_text(encoding="utf-8") for r in license_files)
    assert "CC0" in license_text and vcsl["license"] == dizi["license"] == "CC0-1.0"
    records = [checked_record(r) for r in vcsl["records"]]
    assert all(r["license"] == "CC0-1.0" and vcsl["revision"] in r["url"] for r in vcsl["records"])
    dizi_rows = []
    for row in dizi["samples"]:
        evidence = {}
        for key, expected in (("wav_path", "wav_sha256"), ("preview_path", "preview_sha256"), ("source_html_path", "source_html_sha256")):
            path = Path(row[key])
            assert path.is_file() and sha(path) == row[expected]
            evidence[key] = record(path)
        html = Path(row["source_html_path"]).read_text(encoding="utf-8")
        assert "creativecommons.org/publicdomain/zero/1.0" in html and row["license"] == "CC0-1.0"
        evidence.update(root_midi=row["root_midi"], source_url=row["source_url"], license="CC0-1.0", source_label_not_live_recording_proof=True)
        dizi_rows.append(evidence)
    float_path = ROOT / "assets/raw/audio/wuxia_original_samples_20261009/dizi/float_manifest.json"
    float_manifest = json.loads(float_path.read_text(encoding="utf-8"))
    float_checks = []
    for row in float_manifest["samples"]:
        path, preview = Path(row["wav_path"]), Path(row["preview_path"])
        assert sha(path) == row["wav_sha256"] and sha(preview) == row["preview_sha256"]
        rate, raw = wavfile.read(path)
        assert raw.dtype == np.float32 and np.isfinite(raw).all() and np.any(raw)
        with av.open(str(preview)) as container:
            frames = list(container.decode(audio=0))
            decoded = np.concatenate([f.to_ndarray() for f in frames], axis=1).T.squeeze()
        assert decoded.shape == raw.shape
        difference = float(np.max(np.abs(decoded - raw)))
        # Independent libav Vorbis and libsndfile Vorbis may differ by float rounding.
        float_checks.append({"path": str(path), "sha256": sha(path), "preview_sha256": sha(preview), "sample_rate_hz": rate, "samples_above_unity": int(np.count_nonzero(np.abs(raw) > 1)), "max_independent_decoder_difference": difference, "libav_vs_source_decoder_exact": bool(np.array_equal(decoded, raw)), "prior_pcm_clipped_input_samples": row["prior_pcm_clipped_input_samples"], "prior_pcm_kept_sha_verified": sha(Path(row["prior_pcm_path"])) == row["prior_pcm_sha256"], "no_float_headroom_based_source_rejection": True})
    return {"vcsl_revision": vcsl["revision"], "vcsl_sample_count": len(records), "vcsl_sample_records": records, "license_file_records": license_files, "dizi_sample_count": len(dizi_rows), "dizi_source_evidence": dizi_rows, "dizi_provenance_limitation": dizi.get("instrument_claim"), "dizi_unclipped_float_source_checks": float_checks, "dizi_float_source_manifest_sha256": sha(float_path), "dizi_prior_convenience_pcm_clipped_input_samples": sum(r["prior_pcm_clipped_input_samples"] for r in float_checks), "dan_tranh_instrument": "Vietnamese đàn tranh; not mislabeled guqin/koto", "source_files_and_cc0_evidence_verified": True, "license_statement_verification_is_not_new_legal_advice": True}

def verify(name: str, manifest_path: Path | None = None, pitch_map_path: Path | None = None) -> dict:
    before = preservation()
    manifest_path = manifest_path or PROCESSED / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    script = checked_record(manifest["script"])
    score_record = checked_record(manifest["score"])
    score = json.loads(Path(score_record["path"]).read_text(encoding="utf-8"))
    assert manifest["no_music_generation_model"] is True
    sources = source_evidence(manifest)
    pitch_map = json.loads(pitch_map_path.read_text(encoding="utf-8")) if pitch_map_path else None
    pitch_by_sha = {r["sha256"]: r for r in pitch_map["records"]} if pitch_map else {}
    if pitch_map:
        assert checked_record(manifest["independent_sample_pitch_map"])["sha256"] == sha(pitch_map_path)
        assert sha(Path(pitch_map["source_pitch_report"])) == pitch_map["source_pitch_report_sha256"]
        checked_record(manifest["production_script_v2"])
        checked_record(manifest["frozen_render_kernel"])
    tracks = []
    for meta in manifest["tracks"]:
        track = meta["track"]
        result = {"id": track["id"], "technical_pass": False}
        try:
            assert meta["model_called"] is False and meta["runtime_adopted"] is False
            assert checked_record(meta["score"])["sha256"] == score_record["sha256"]
            assert track == next(t for t in score["tracks"] if t["id"] == track["id"])
            midi = midi_event_stats(Path(checked_record(meta["midi"])["path"]))
            duration = track["bars"] * 4 * 60 / track["bpm"]
            assert abs(midi["duration_seconds"] - duration) <= track["bars"] * 4 / 1000000
            assert midi["end_tick"] == track["bars"] * 4 * midi["ppq"]
            expected_tempo = round(60000000 / track["bpm"])
            assert midi["tempo_changes"] == [{"tick": 0, "microseconds_per_quarter": expected_tempo}]
            assert midi["note_count"] == len(track["events"])
            midi_summary = []
            for midi_track in midi["tracks"]:
                if not midi_track["notes"]:
                    continue
                events = [e for e in track["events"] if e["instrument"] == midi_track["name"]]
                notes = midi_track["notes"]
                assert len(events) == len(notes)
                assert Counter(e["velocity"] for e in events) == Counter(n["velocity"] for n in notes)
                assert Counter(round((e["beat"] + e["duration_beats"]) * midi["ppq"]) - round(e["beat"] * midi["ppq"]) for e in events) == Counter(n["duration_ticks"] for n in notes)
                pitched = [e for e in events if e["midi"] is not None]
                if pitched:
                    assert Counter(e["midi"] for e in pitched) == Counter(n["pitch"] for n in notes)
                expected_windows = sorted((round(e["beat"] * midi["ppq"]), round((e["beat"] + e["duration_beats"]) * midi["ppq"]), e["velocity"]) for e in events)
                actual_windows = sorted((n["start_tick"], n["end_tick"], n["velocity"]) for n in notes)
                selected = sorted(set([0, len(events) // 2, len(events) - 1]))
                assert all(expected_windows[i] == actual_windows[i] for i in selected)
                midi_summary.append({"instrument": midi_track["name"], "count": len(notes), "selected_event_indices": selected, "score_count_velocity_duration_pitch_statistics_match": True, "first_middle_last_event_timing_match": True})
            source_map = {r["id"]: r for r in meta["sample_records"]}
            mapping_checks = []
            for row in meta["sample_records"]:
                if row["instrument"] == "dan_tranh" and pitch_map:
                    measured = pitch_by_sha[row["sha256"]]
                    root = row["root_midi"]
                    matches = abs(root - measured["estimated_midi_float"]) <= .5
                    assert matches, "Actual Dan Tranh root differs from independent source pitch"
                    mapping_checks.append({"id": row["id"], "source_sha256": row["sha256"], "render_root_midi": root, "independent_measured_midi": measured["estimated_midi_float"], "root_match_within_50_cents": matches})
            assert len(meta["sample_render_events"]) == len(track["events"])
            selected_log_checks = []
            for i, event in enumerate(meta["sample_render_events"]):
                assert event["event_index"] == i
                row = source_map[event["sample_id"]]
                checked_record(row, require_size=False)
                assert event["sample_sha256"] == row["sha256"]
                source_root = row.get("estimated_midi_float", row["root_midi"])
                expected_transpose = 0 if event["target_midi"] is None else event["target_midi"] - source_root
                assert event["semitones"] == expected_transpose
                assert event["pitch_ratio"] == 2 ** (expected_transpose / 12)
                assert event["resample_up"] == 1000 and event["resample_down"] == round(1000 * event["pitch_ratio"])
                if row["instrument"] == "dizi":
                    original = next(r for r in manifest["dizi_sources"]["samples"] if r["root_midi"] == row["root_midi"])
                    assert Path(ROOT / row["path"]).resolve() == Path(original["preview_path"]).resolve() and row["sha256"] == original["preview_sha256"]
                assert np.isfinite(event["sample_gain"]) and event["sample_gain"] > 0
                assert event["rendered_frames"] > 0 and event["attack_frames"] >= 0 and event["release_frames"] >= 0
                if i in (0, len(track["events"]) // 2, len(track["events"]) - 1):
                    event_score = track["events"][i]
                    assert event["target_midi"] == event_score["midi"]
                    assert event["start_frame"] == round(event_score["beat"] * 60 / track["bpm"] * meta["sample_rate"])
                    assert abs(event["pitch_ratio"] - 2 ** (event["semitones"] / 12)) < 1e-12
                    selected_log_checks.append({"index": i, "sample_id": event["sample_id"], "timing_pitch_fields_match": True})
            output_records = [checked_record(r) for r in meta["outputs"]]
            mixing = meta["mixing"]
            observations = [wav_observation(Path(r["path"])) for r in output_records if Path(r["path"]).suffix == ".wav"]
            mp3s = [mp3_observation(Path(r["path"])) for r in output_records if Path(r["path"]).suffix == ".mp3"]
            for observation in observations:
                basename = Path(observation["path"]).name
                voice = next((v for v in mixing["stem_order"] if basename.endswith("_stem_" + v + ".wav")), None)
                expected_active = voice is None or any(e["instrument"] == voice for e in track["events"])
                assert observation["finite_nonzero"] == expected_active and not observation["integer_full_scale_samples"]
                observation["zero_stem_expected_from_score"] = not expected_active
            assert all(r["frames"] == meta["output_frames"] and r["sample_rate_hz"] == 44100 and r["channels"] == 2 for r in observations)
            assert meta["output_frames"] == round((duration + track["tail_seconds"]) * 44100)
            raw_path = Path(checked_record(mixing["raw_mix"])["path"])
            rate, raw = wavfile.read(raw_path)
            assert raw.dtype == np.float32 and rate == 44100
            summed = np.zeros_like(raw)
            for voice in mixing["stem_order"]:
                stem = next(Path(r["path"]) for r in output_records if Path(r["path"]).name.endswith("_stem_" + voice + ".wav"))
                stem_rate, array = wavfile.read(stem)
                assert stem_rate == rate and array.shape == raw.shape and array.dtype == np.float32
                summed += array
            assert np.array_equal(raw, summed)
            rms = float(np.sqrt(np.mean(np.ascontiguousarray(raw.T).astype(np.float64) ** 2)))
            peak = float(np.abs(raw).max())
            gain = min(10 ** (-22 / 20) / rms, 10 ** (-3 / 20) / peak)
            assert mixing["linear_gain"] == gain and mixing["pcm_scale"] == 32767 and mixing["quantization"] == "trunc_int16"
            expected = raw * gain
            edge = min(round(.015 * rate), len(raw) // 2)
            assert mixing["edge_fade_frames"] == edge
            expected[:edge] *= np.linspace(0, 1, edge, dtype=np.float32)[:, None]
            expected[-edge:] *= np.linspace(1, 0, edge, dtype=np.float32)[:, None]
            audition = next(Path(r["path"]) for r in output_records if Path(r["path"]).name.endswith("_audition.wav"))
            listen_rate, pcm = wavfile.read(audition)
            expected_pcm = (expected * 32767).astype("<i2")
            assert listen_rate == rate and pcm.dtype == np.int16 and np.array_equal(pcm, expected_pcm)
            assert len(mp3s) == 1 and abs(mp3s[0]["duration_seconds"] - len(raw) / rate) < .03
            result.update(technical_pass=True, dan_root_mapping_checks=mapping_checks, dan_root_mapping_verified=bool(mapping_checks) if pitch_map else False, musical_seconds=duration, output_seconds=len(raw) / rate, score_midi_event_statistics=midi_summary, midi_observation=midi, midi_is_score_interchange_requires_sample_map=True, midi_embeds_original_samples=False, percussion_shared_channel_9_is_valid=True, missing_gm_program_is_not_self_contained_mix_reproduction=True, selected_sample_render_log_checks=selected_log_checks, source_sample_log_sha_verified=True, wav_observations=observations, raw_mix_observation=wav_observation(raw_path), mp3_observations=mp3s, stem_sum_exact_float32_match=True, mix_gain_and_edge_fade_exact_pcm_match=True, max_pcm_difference=0, loop_status=meta["loop_review"], actual_instruments="Dizi-labelled single-note previews (live/acoustic provenance unverified); Vietnamese dan tranh and VCSL percussion", musical_quality_or_wuxia_approval=False)
        except Exception as error:
            result["error"] = f"{type(error).__name__}: {error}"
        tracks.append(result)
    after = preservation()
    prior_path = OUT / "original_two_tracks_offline_retry1.json"
    old_preservation = {}
    if pitch_map and prior_path.is_file():
        previous = json.loads(prior_path.read_text(encoding="utf-8"))
        old_rows = [previous["composition_script"], previous["score_record"]]
        for track_row in previous["tracks"]:
            old_rows.extend(track_row["wav_observations"])
            old_rows.extend(track_row["mp3_observations"])
            old_rows.append(track_row["raw_mix_observation"])
            old_rows.append(track_row["midi_observation"])
        old_changes = changes(old_rows)
        old_preservation = {"source_report": str(prior_path), "source_report_sha256": sha(prior_path), "file_count": len(old_rows), "sha_bytes_mtime_changes": old_changes, "unchanged": not old_changes}
    result = {"schema": 1, "created_utc": datetime.now(timezone.utc).isoformat(), "scope": "TWO_ORIGINAL_SCORE_SAMPLE_RENDER_OFFLINE_QA_ONLY", "verifier_source_sha256": sha(Path(__file__)), "qa_helper_source_sha256": sha(ROOT / "scripts/audio/verify_wuxia_audio_loops.py"), "manifest_sha256": sha(manifest_path), "composition_script": script, "score_record": score_record, "source_evidence": sources, "protection_before": before, "protection_after": after, "first_original_attempt_preservation": old_preservation, "independent_source_pitch_mapping_checked": bool(pitch_map), "independent_source_pitch_map_sha256": sha(pitch_map_path) if pitch_map else None, "tracks": tracks, "all_two_offline_technical_pass": len(tracks) == 2 and all(r["technical_pass"] for r in tracks) and before["unchanged"] and after["unchanged"] and (not old_preservation or old_preservation["unchanged"]), "composition_algorithm_reimplemented": False, "sample_note_renderer_reimplemented": False, "model_invocations": 0, "godot_started": False, "formal_adoption": False, "musical_quality_or_wuxia_approval": False}
    save(name, result)
    return result

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("readiness", "verify", "pitch"))
    parser.add_argument("--report", default="readiness.json")
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--additional-samples", type=Path)
    parser.add_argument("--pitch-map", type=Path)
    args = parser.parse_args()
    if args.mode == "pitch":
        name = args.report if args.report != "readiness.json" else "dan_tranh_source_pitch.json"
        result = dan_pitch_report(name, args.additional_samples)
        print(json.dumps({"report": str(OUT / name), "sample_count": result["sample_count"], "all_declared_roots_match": result["all_declared_roots_match"]}))
        return 0 if result["all_declared_roots_match"] else 1
    if args.mode == "verify":
        name = args.report if args.report != "readiness.json" else "original_two_tracks_offline.json"
        result = verify(name, args.manifest, args.pitch_map)
        print(json.dumps({"report": str(OUT / name), "all_two_offline_technical_pass": result["all_two_offline_technical_pass"], "musical_approval": False}))
        return 0 if result["all_two_offline_technical_pass"] else 1
    result = readiness(args.report)
    print(json.dumps({"report": str(OUT / args.report), "protected_unchanged": result["protection"]["unchanged"], "manifest_exists": result["manifest_exists"], "outputs_approved": False}))
    return 0 if result["protection"]["unchanged"] else 1

if __name__ == "__main__":
    raise SystemExit(main())
