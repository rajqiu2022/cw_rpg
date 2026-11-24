"""13 original Stable Audio compositions with transparent phrase-feature loop selection.

Offline CPU inference uses the frozen first-trial float-WAV wrapper unchanged.
Actual source intervals are selected by low transient energy plus chroma/timbre/
envelope matching, then joined by complementary linear overlap; no silence fades.
Musical phrase and listening approval are still human review, not a numeric claim.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import os
import shutil
import subprocess
import sys
import time
import wave
import numpy as np
import av
from scipy import signal

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "assets/raw/audio/wuxia_audio_bank_v9_20261009"
PROCESSED = ROOT / "assets/processed/audio/wuxia_audio_bank_v9_20261009"
RUNTIME = ROOT / "tools/audio/stable-audio-3/optimized/tflite"
PLAN = Path(__file__).with_name("wuxia_audio_bank_v9_plan_20261009.json")
WRAPPER = Path(__file__).with_name("run_stable_wuxia_inference.py")
SR = 44100


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while block := f.read(1024 * 1024):
            h.update(block)
    return h.hexdigest()


def relative(path):
    return str(path.relative_to(ROOT)).replace("\\", "/")


def record(path):
    return {"path": relative(path), "size": path.stat().st_size, "sha256": sha(path)}


def load(path):
    with av.open(str(path)) as container:
        resampler = av.AudioResampler(format="fltp", layout="stereo", rate=SR)
        arrays = [f.to_ndarray() for decoded in container.decode(audio=0)
                  for f in resampler.resample(decoded)]
        arrays.extend(f.to_ndarray() for f in resampler.resample(None))
    return np.concatenate(arrays, axis=1).astype(np.float32)


def save_pcm(path, audio):
    pcm = (audio.T * 32767).astype("<i2")
    if np.max(np.abs(audio)) >= 1 or not np.isfinite(audio).all():
        raise ValueError("Unsafe PCM export")
    with wave.open(str(path), "wb") as out:
        out.setparams((2, 2, SR, 0, "NONE", "not compressed"))
        out.writeframes(pcm.tobytes())


def save_mp3(path, audio):
    with av.open(str(path), "w") as out:
        stream = out.add_stream("libmp3lame", rate=SR)
        stream.bit_rate = 192000
        stream.layout = "stereo"
        for offset in range(0, audio.shape[1], 1152):
            frame = av.AudioFrame.from_ndarray(np.ascontiguousarray(audio[:, offset:offset + 1152]),
                                              format="fltp", layout="stereo")
            frame.sample_rate = SR
            for packet in stream.encode(frame):
                out.mux(packet)
        for packet in stream.encode(None):
            out.mux(packet)


def rms(audio):
    return float(np.sqrt(np.mean(audio.astype(np.float64) ** 2)))


def features(audio):
    """20 Hz energy/transient/centroid/chroma summaries from actual raw samples."""
    mono = audio.mean(axis=0)
    down = signal.resample_poly(mono, 1, 4)
    f, t, z = signal.stft(down, fs=SR / 4, nperseg=2048, noverlap=1497,
                          boundary=None, padded=False)
    power = np.abs(z) ** 2
    valid = (f >= 65) & (f <= 5000)
    chroma = np.zeros((12, len(t)), dtype=np.float64)
    notes = np.rint(69 + 12 * np.log2(f[valid] / 440)).astype(int) % 12
    for key in range(12):
        chroma[key] = power[valid][notes == key].sum(axis=0)
    chroma /= np.linalg.norm(chroma, axis=0, keepdims=True) + 1e-12
    energy = np.sqrt(power.sum(axis=0))
    energy /= max(float(np.quantile(energy, 0.8)), 1e-12)
    centroid = (f[:, None] * power).sum(axis=0) / (power.sum(axis=0) + 1e-12) / 5000
    flux = np.maximum(0, np.diff(np.log(power + 1e-10), axis=1)).mean(axis=0)
    flux = np.r_[flux[0], flux]
    flux /= max(float(np.quantile(flux, 0.8)), 1e-12)
    return {"times": t, "chroma": chroma, "energy": energy, "centroid": centroid, "flux": flux}


def window(feature, at, seconds):
    indexes = np.searchsorted(feature["times"], [at, at + seconds])
    return slice(indexes[0], max(indexes[0] + 1, indexes[1]))


def candidates(feature, lo, hi):
    """Choose local low-transient phase points, never run-start/end fades."""
    indexes = np.flatnonzero((feature["times"] >= lo) & (feature["times"] <= hi))
    if len(indexes) < 3:
        raise ValueError("Too few actual phrase candidates")
    cost = 0.45 * feature["energy"] + 0.55 * feature["flux"]
    order = indexes[np.argsort(cost[indexes])]
    selected = []
    for index in order:
        at = float(feature["times"][index])
        if all(abs(at - x) >= 0.8 for x in selected):
            selected.append(at)
        if len(selected) == 16:
            break
    return sorted(selected)


def select_loop(audio, track):
    feat = features(audio)
    duration = audio.shape[1] / SR
    fade_seconds = track["crossfade_seconds"]
    minimum_seconds = (56 if track["family"] == "exploration" else 36) if duration > 50 else 22
    starts = candidates(feat, 5 if duration > 50 else 3, 22 if duration > 80 else (14 if duration > 50 else 12))
    ends = candidates(feat, duration - (22 if duration > 50 else 15), duration - 3)
    scored = []
    for start in starts:
        for end in ends:
            length = end - start - fade_seconds
            if length < minimum_seconds:
                continue
            head = window(feat, start, fade_seconds)
            tail = window(feat, end - fade_seconds, fade_seconds)
            hc, tc = feat["chroma"][:, head].mean(axis=1), feat["chroma"][:, tail].mean(axis=1)
            chroma_distance = 1 - float(np.dot(hc, tc) / (np.linalg.norm(hc) * np.linalg.norm(tc) + 1e-12))
            energy_distance = abs(math.log((float(feat["energy"][head].mean()) + 1e-5) /
                                          (float(feat["energy"][tail].mean()) + 1e-5)))
            centroid_distance = abs(float(feat["centroid"][head].mean() - feat["centroid"][tail].mean()))
            a, b = np.linspace(0, 1, 20), np.linspace(0, 1, feat["energy"][head].size)
            head_env = np.interp(a, b, feat["energy"][head])
            tail_env = np.interp(a, np.linspace(0, 1, feat["energy"][tail].size), feat["energy"][tail])
            envelope_distance = float(np.mean(np.abs(head_env - tail_env)))
            silence_penalty = max(0, 0.12 - float(feat["energy"][head].mean())) + max(0, 0.12 - float(feat["energy"][tail].mean()))
            score = 2.8 * chroma_distance + 0.6 * energy_distance + 0.8 * centroid_distance + 0.7 * envelope_distance + 4 * silence_penalty
            scored.append({"start_frame": round(start * SR), "end_frame": round(end * SR),
                           "crossfade_frames": round(fade_seconds * SR), "score": score,
                           "chroma_distance": chroma_distance, "log_energy_distance": energy_distance,
                           "centroid_distance": centroid_distance, "envelope_distance": envelope_distance,
                           "silence_penalty": silence_penalty})
    if not scored:
        raise ValueError("No valid actual phrase interval")
    scored.sort(key=lambda x: (x["score"], -(x["end_frame"] - x["start_frame"])))
    chosen = scored[0]
    start, end, n = (chosen[x] for x in ("start_frame", "end_frame", "crossfade_frames"))
    weight = np.linspace(0, 1, n, dtype=np.float32)
    blend = audio[:, end - n:end] * (1 - weight) + audio[:, start:start + n] * weight
    loop = np.concatenate([audio[:, start + n:end - n], blend], axis=1)
    # Last -> first is an existing adjacent source pair, not forced equality/silence.
    boundary_difference = loop[:, 0] - loop[:, -1]
    original_difference = audio[:, start + n] - audio[:, start + n - 1]
    assert np.array_equal(boundary_difference, original_difference)
    return loop, {"selected": chosen, "top_candidates": scored[:12],
                  "candidate_pairs": len(scored), "minimum_loop_seconds": minimum_seconds,
                  "selection": "low energy/transient phase candidates; chroma, energy envelope and spectral centroid agreement",
                  "formula": "concat(raw[S+N:E-N], raw[E-N:E]*(1-w)+raw[S:S+N]*w), w=linspace(0,1,N,float32)",
                  "loop_frames": loop.shape[1], "loop_seconds": loop.shape[1] / SR,
                  "boundary_raw_adjacent_pair_preserved": True,
                  "source_first_frame": start + n, "source_last_frame": start + n - 1,
                  "musical_phrase_listening_review": "PENDING"}


def process(raw_path, track):
    audio = load(raw_path)
    if not np.isfinite(audio).all() or rms(audio) < 1e-5:
        raise ValueError("Invalid source model output")
    loop, loop_meta = select_loop(audio, track)
    source_loop_rms, source_loop_peak = rms(loop), float(np.abs(loop).max())
    target_rms, cap = 10 ** (-22 / 20), 10 ** (-3 / 20)
    gain = min(target_rms / source_loop_rms, cap / source_loop_peak)
    loop = loop * gain
    base = PROCESSED / (track["id"] + "_v9_loop")
    wav, mp3 = base.with_suffix(".wav"), base.with_suffix(".mp3")
    save_pcm(wav, loop)
    save_mp3(mp3, loop)
    # Last five seconds of cycle 1 + first five of cycle 2, no fade at join.
    seam = np.concatenate([loop[:, -5 * SR:], loop[:, :5 * SR]], axis=1)
    seam_wav = PROCESSED / (track["id"] + "_v9_two_cycle_seam10.wav")
    seam_mp3 = seam_wav.with_suffix(".mp3")
    save_pcm(seam_wav, seam)
    save_mp3(seam_mp3, seam)
    differences = np.abs(np.diff(loop, axis=1))
    jump = np.abs(loop[:, 0] - loop[:, -1])
    q999 = np.quantile(differences, 0.999, axis=1)
    result = {"status": "LOOP_LISTENING_PENDING", "license_status": "Existing output post-processing; no new model invocation. Commercial model use paused pending registration/eligibility.",
              "source": record(raw_path), "track": track, "sample_rate": SR, "channels": 2,
              "loop": loop_meta, "processing": {"linear_gain": gain, "gain_db": 20 * math.log10(gain),
                  "target_rms_dbfs": -22, "peak_cap_dbfs": -3, "peak_cap_limited": cap / source_loop_peak < target_rms / source_loop_rms,
                  "pre_gain_loop_rms": source_loop_rms, "pre_gain_loop_peak": source_loop_peak,
                  "actual_rms_dbfs": 20 * math.log10(rms(loop)), "actual_peak": float(np.abs(loop).max()),
                  "quantization": "trunc_int16", "pcm_scale": 32767, "edge_silence_fade": False},
              "boundary": {"jump_by_channel": jump.tolist(), "internal_step_q999_by_channel": q999.tolist(),
                  "jump_below_internal_q999": bool(np.all(jump <= q999)),
                  "preserved_original_adjacent_source_pair": True,
                  "note": "Numeric continuity only; phrase/rhythm/no audible seam still requires listening."},
              "seam_audition": {"seconds": 10, "join_frame": 5 * SR,
                  "construction": "last5s(cycle1)+first5s(cycle2), direct concatenate, no edge fading"},
              "outputs": [record(p) for p in (wav, mp3, seam_wav, seam_mp3)],
              "reference_or_old_music_used": False, "formal_runtime_adopted": False}
    (PROCESSED / (track["id"] + "_v9.processing.json")).write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
    return result


def verify_models(plan):
    manifest_path = ROOT / "tools/audio/stable-audio-3/trial_runtime_manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest["weights_revision"] != plan["weights_revision"] or manifest["runtime_git_revision"] != plan["runtime_revision"]:
        raise ValueError("Fixed runtime/model identity mismatch")
    required = {"tflite/t5gemma/encoder_fp16.tflite", "tflite/same-s/dec_w8a8.tflite", "tflite/sa3-sm-music/dit_fp32.tflite"}
    for item in manifest["files"]:
        if item["file"] in required:
            path = Path(item["path"])
            if path.stat().st_size != item["size"] or sha(path) != item["sha256"]:
                raise ValueError("Pinned model byte mismatch")
            required.remove(item["file"])
    if required:
        raise ValueError("Missing pinned model records")
    return manifest


def write_bank_manifest(plan, runtime):
    metadata = [json.loads(p.read_text(encoding="utf-8")) for p in sorted(PROCESSED.glob("*_v9.processing.json"))]
    manifest = {"status": "COMMERCIAL_MODEL_USE_PAUSED_EXISTING_OUTPUT_PROCESSING", "new_track_listening_review": "PENDING",
                "formal_adoption": False, "plan": record(PLAN), "script": record(Path(__file__)),
                "frozen_inference_wrapper": record(WRAPPER), "runtime": runtime,
                "completed_tracks": len(metadata), "tracks": metadata,
                "completed_new_model_bank_tracks": len(list(RAW.glob("*_v9_raw.wav"))),
                "existing_accepted_output_loop_count": sum(x["track"]["id"].startswith("approved_") for x in metadata),
                "commercial_license_gate": "Registered with Stability AND using entity/affiliates annual revenue below USD1m; OR valid Enterprise license. Both registration and revenue facts currently unconfirmed.",
                "interrupted_attempt": record(RAW / "journey_v9.interruption.json") if (RAW / "journey_v9.interruption.json").exists() else None,
                "raw_files": [record(p) for p in sorted(RAW.iterdir()) if p.is_file() and p.name != "manifest.json"],
                "processed_files": [record(p) for p in sorted(PROCESSED.iterdir()) if p.is_file() and p.name != "manifest.json"]}
    (PROCESSED / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=13)
    ap.add_argument("--process-only", action="store_true")
    ap.add_argument("--resume", action="store_true")
    ap.add_argument("--manifest-only", action="store_true", help="Refresh metadata inventory; does not load or invoke a model")
    ap.add_argument("--approved-clips-only", action="store_true",
                    help="Process only the three existing accepted 45s outputs, with no model invocation")
    ap.add_argument("--registration-confirmed", action="store_true",
                    help="Human has explicitly confirmed commercial registration with Stability")
    ap.add_argument("--entity-revenue-under-1m-confirmed", action="store_true",
                    help="Human has explicitly confirmed using entity/affiliates annual revenue below USD1m")
    ap.add_argument("--enterprise-license-confirmed", action="store_true",
                    help="Human has explicitly confirmed valid Enterprise license for this use")
    args = ap.parse_args()
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    if args.manifest_only:
        runtime_record = json.loads((ROOT / "tools/audio/stable-audio-3/trial_runtime_manifest.json").read_text(encoding="utf-8"))
        write_bank_manifest(plan, runtime_record)
        print("MANIFEST_ONLY: no model loaded or invoked.")
        return
    licensed = args.enterprise_license_confirmed or (args.registration_confirmed and args.entity_revenue_under_1m_confirmed)
    if not args.approved_clips_only and not args.process_only and not licensed:
        print("PLAN_ONLY: commercial project has not registered with Stability; no model invoked.")
        print("Use --approved-clips-only for existing-output processing. New generation requires human-confirmed registration AND entity/affiliate revenue below USD1m, OR valid Enterprise license.")
        return
    if args.approved_clips_only:
        RAW.mkdir(parents=True, exist_ok=True)
        PROCESSED.mkdir(parents=True, exist_ok=True)
        approved = [
            {"id": "approved_mountain", "title_zh": "山间清游循环", "family": "exploration", "seconds": 45, "crossfade_seconds": 2.0,
             "source": "mountain_xiao_guqin_45s_raw.wav"},
            {"id": "approved_journey", "title_zh": "江湖行旅循环", "family": "exploration", "seconds": 45, "crossfade_seconds": 2.0,
             "source": "jianghu_pipa_dizi_45s_raw.wav"},
            {"id": "approved_combat", "title_zh": "拔剑交锋循环", "family": "battle", "seconds": 45, "crossfade_seconds": 1.0,
             "source": "combat_pipa_tanggu_45s_raw.wav"},
        ]
        for track in approved:
            metadata = PROCESSED / (track["id"] + "_v9.processing.json")
            if metadata.exists():
                raise SystemExit("Existing processed loop preserved: " + track["id"])
            source = ROOT / "assets/raw/audio/wuxia_ai_trial_20261009" / track["source"]
            result = process(source, track)
            print("EXISTING_OUTPUT_LOOP_READY", track["id"], result["loop"]["loop_seconds"], result["boundary"], flush=True)
        runtime_record = json.loads((ROOT / "tools/audio/stable-audio-3/trial_runtime_manifest.json").read_text(encoding="utf-8"))
        write_bank_manifest(plan, runtime_record)
        return
    runtime = verify_models(plan)
    RAW.mkdir(parents=True, exist_ok=True)
    PROCESSED.mkdir(parents=True, exist_ok=True)
    for name in ("LICENSE.md", "LICENSE_GEMMA.md"):
        target = RAW / name
        if not target.exists():
            shutil.copy2(ROOT / "tools/audio/stable-audio-3/trial-licenses" / name, target)
    for index, track in enumerate(plan["tracks"][:args.limit]):
        raw = RAW / (track["id"] + "_v9_raw.wav")
        processed_meta = PROCESSED / (track["id"] + "_v9.processing.json")
        if args.resume and processed_meta.exists():
            previous = json.loads(processed_meta.read_text(encoding="utf-8"))
            if previous["source"]["sha256"] != sha(raw) or previous["track"] != track:
                raise ValueError("Resume source/plan changed")
            print("PRESERVED_COMPLETED", track["id"], flush=True)
            continue
        if processed_meta.exists():
            raise SystemExit("Preserving existing processed candidate: " + track["id"])
        if not args.process_only:
            if raw.exists():
                raise SystemExit("Preserving existing raw output; use --process-only: " + track["id"])
            command = [str(RUNTIME / ".venv/Scripts/python.exe"), str(WRAPPER), "--dit", "sm-music",
                       "--decoder", "same-s", "--dit-precision", "fp32", "--decoder-precision", "w8a8",
                       "--seconds", str(track["seconds"]), "--steps", "8", "--seed", str(track["seed"]),
                       "--threads", "6", "--prompt", track["prompt"], "--out", str(raw)]
            print(f"INFERENCE_START {index + 1}/13 {track['id']} {track['seconds']}s", flush=True)
            start = time.time()
            with (RAW / (track["id"] + "_v9.inference.log")).open("w", encoding="utf-8") as log:
                execution = subprocess.run(command, cwd=RUNTIME, stdout=log, stderr=subprocess.STDOUT,
                                          env={**os.environ, "HF_HUB_OFFLINE": "1", "HF_HUB_DISABLE_IMPLICIT_TOKEN": "1"})
            meta = {"track": track, "inference_exit_code": execution.returncode,
                    "wall_seconds": time.time() - start, "runtime_flags": command[2:],
                    "model_revision": plan["weights_revision"], "source_audio": None, "reference_audio": None,
                    "status": "LISTENING_PENDING", "license_status": "NONCOMMERCIAL_EVALUATION_ONLY"}
            if raw.exists():
                meta["raw"] = record(raw)
            (RAW / (track["id"] + "_v9.meta.json")).write_text(json.dumps(meta, indent=2, ensure_ascii=False), encoding="utf-8")
            if execution.returncode:
                raise SystemExit("Actual inference failed; raw log retained: " + track["id"])
        result = process(raw, track)
        write_bank_manifest(plan, runtime)
        print("LOOP_CANDIDATE_READY", track["id"], result["loop"]["loop_seconds"],
              result["boundary"], flush=True)
        if (index + 1) % 3 == 0:
            print(f"MILESTONE {index + 1}/13", flush=True)
    write_bank_manifest(plan, runtime)


if __name__ == "__main__":
    main()
