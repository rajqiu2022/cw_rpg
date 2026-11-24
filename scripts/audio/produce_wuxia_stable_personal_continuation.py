"""One authorized personal noncommercial three-track batch, entirely offline.

Uses the frozen unclipped official-inference wrapper and installed CPU runtime.
Only writes NEW personal-continuation directories. No registration or revenue
flags and no claim of commercial eligibility. Existing candidates are preserved.
"""
from pathlib import Path
import argparse
import json
import math
import os
import shutil
import subprocess
import time
import wave
import numpy as np
from produce_wuxia_stable_trial import ROOT, RUNTIME, decode, encode_mp3, sha256

RAW = ROOT / "assets/raw/audio/wuxia_stable_personal_continuation_20261009"
PROCESSED = ROOT / "assets/processed/audio/wuxia_stable_personal_continuation_20261009"
PLAN = Path(__file__).with_name("wuxia_stable_personal_continuation_plan_20261009.json")
WRAPPER = Path(__file__).with_name("run_stable_wuxia_inference.py")


def record(path):
    return {"path": path.relative_to(ROOT).as_posix(), "size": path.stat().st_size,
            "sha256": sha256(path)}


def write_json(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def pcm_export(path, audio):
    pcm = (audio.T * 32767).astype("<i2")
    if np.any(np.abs(pcm.astype(np.int32)) >= 32767):
        raise ValueError("Unsafe full-scale PCM")
    with wave.open(str(path), "wb") as output:
        output.setparams((2, 2, 44100, 0, "NONE", "not compressed"))
        output.writeframes(pcm.tobytes())
    encode_mp3(path.with_suffix(".mp3"), audio)
    return [record(path), record(path.with_suffix(".mp3"))]


def audition(raw, stem):
    audio = decode(raw).astype(np.float32)
    rms = float(np.sqrt(np.mean(audio.astype(np.float64) ** 2)))
    peak = float(np.abs(audio).max())
    if not np.isfinite(audio).all() or rms <= 1e-5:
        raise ValueError("Nonfinite or silent model output")
    rms_gain, peak_gain = 10 ** (-22 / 20) / rms, 10 ** (-3 / 20) / peak
    gain = min(rms_gain, peak_gain)
    processed = audio * gain
    n = min(662, processed.shape[1] // 2)
    processed[:, :n] *= np.linspace(0, 1, n, dtype=np.float32)
    processed[:, -n:] *= np.linspace(1, 0, n, dtype=np.float32)
    outputs = pcm_export(PROCESSED / (stem + "_audition.wav"), processed)
    preview = processed[:, :min(30 * 44100, processed.shape[1])].copy()
    pn = min(2205, preview.shape[1] // 2)
    preview[:, -pn:] *= np.linspace(1, 0, pn, dtype=np.float32)
    outputs += pcm_export(PROCESSED / (stem + "_first30s.wav"), preview)
    actual_rms = float(np.sqrt(np.mean(processed.astype(np.float64) ** 2)))
    return {"source": record(raw), "source_peak": peak, "source_rms": rms,
            "source_rms_dbfs": 20 * math.log10(rms), "target_rms_dbfs": -22,
            "peak_cap_dbfs": -3, "linear_gain": gain, "gain_db": 20 * math.log10(gain),
            "peak_cap_limited": peak_gain < rms_gain,
            "actual_rms_dbfs": 20 * math.log10(actual_rms),
            "actual_peak": float(np.abs(processed).max()), "sample_rate": 44100,
            "channels": 2, "frames": processed.shape[1], "seconds": processed.shape[1] / 44100,
            "edge_fade_frames": n, "edge_fade_seconds": n / 44100,
            "pcm_scale": 32767, "quantization": "trunc_int16", "clipped_pcm_samples": 0,
            "preview_source": "First frames of full post-gain/post-edge-fade float audition",
            "preview_frames": preview.shape[1], "preview_end_fade_frames": pn,
            "preview_end_fade_seconds": pn / 44100, "outputs": outputs,
            "loop_processing": "NONE", "review": "LISTENING_PENDING"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--track", choices=["all", "mountain_continuous_96s", "jianghu_continuous_96s", "combat_continuous_72s"], default="all")
    args = ap.parse_args()
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    if plan["purpose"] != "PERSONAL_NONCOMMERCIAL_EVALUATION" or plan["steps"] != 8 or plan["threads"] != 6:
        raise SystemExit("Fixed personal batch plan mismatch")
    prepared = ROOT / "tools/audio/stable-audio-3/trial_runtime_manifest.json"
    runtime_manifest = json.loads(prepared.read_text(encoding="utf-8"))
    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=RUNTIME, text=True).strip()
    if revision != plan["runtime_revision"] or runtime_manifest["weights_revision"] != plan["model_revision"]:
        raise SystemExit("Pinned model/runtime revision mismatch")
    models = []
    required = {"tflite/t5gemma/encoder_fp16.tflite", "tflite/same-s/dec_w8a8.tflite", "tflite/sa3-sm-music/dit_fp32.tflite"}
    for item in runtime_manifest["files"]:
        if item["file"] not in required:
            continue
        path = Path(item["path"])
        actual = record(path)
        if actual["sha256"] != item["sha256"] or actual["size"] != item["size"]:
            raise SystemExit("Pinned weight integrity mismatch: " + item["file"])
        models.append(actual)
    if len(models) != 3:
        raise SystemExit("Incomplete pinned model set")
    RAW.mkdir(parents=True, exist_ok=True)
    PROCESSED.mkdir(parents=True, exist_ok=True)
    licenses = RAW / "licenses"
    licenses.mkdir(exist_ok=True)
    for source in [ROOT / "tools/audio/stable-audio-3/trial-licenses/LICENSE.md", ROOT / "tools/audio/stable-audio-3/trial-licenses/LICENSE_GEMMA.md", ROOT / "tools/audio/stable-audio-3/LICENSE"]:
        target = licenses / ("CODE_MIT.txt" if source.name == "LICENSE" else source.name)
        if target.exists() and sha256(target) != sha256(source):
            raise SystemExit("Preserving differing existing license: " + str(target))
        if not target.exists():
            shutil.copyfile(source, target)
    selected = [t for t in plan["tracks"] if args.track in ("all", t["id"])]
    for track in selected:
        stem = track["id"]
        raw = RAW / (stem + "_raw.wav")
        meta_path = RAW / (stem + ".meta.json")
        log_path = RAW / (stem + ".inference.log")
        if any(p.exists() for p in [raw, meta_path, log_path]) or list(PROCESSED.glob(stem + "*")):
            raise SystemExit("Existing attempt preserved: " + stem)
        if not 0 < track["seconds"] <= 120:
            raise SystemExit("Small Music duration exceeded")
        command = [str(RUNTIME / ".venv/Scripts/python.exe"), str(WRAPPER), "--dit", "sm-music", "--decoder", "same-s", "--dit-precision", "fp32", "--decoder-precision", "w8a8", "--prompt", track["prompt"], "--seconds", str(track["seconds"]), "--steps", "8", "--seed", str(track["seed"]), "--threads", "6", "--out", str(raw)]
        meta = {**{k: v for k, v in plan.items() if k != "tracks"}, **track,
                "generation_status": "RUNNING", "generation_method": "Original text2music; no reference audio; installed official local CPU model",
                "command": command, "model_files": models, "runtime_preparation": record(prepared),
                "production_script": record(Path(__file__)), "frozen_float_wrapper": record(WRAPPER),
                "frozen_io_helper": record(Path(__file__).with_name("produce_wuxia_stable_trial.py")),
                "plan_file": record(PLAN), "licenses": [record(p) for p in sorted(licenses.iterdir())],
                "network": "HF_HUB_OFFLINE=1; no downloads or API calls", "game_integration": "NONE"}
        write_json(meta_path, meta)
        print("INFERENCE_START", stem, flush=True)
        started = time.time()
        with log_path.open("x", encoding="utf-8") as log:
            result = subprocess.run(command, cwd=RUNTIME, stdout=log, stderr=subprocess.STDOUT,
                                    env={**os.environ, "HF_HUB_OFFLINE": "1", "HF_HUB_DISABLE_IMPLICIT_TOKEN": "1"})
        meta.update({"inference_exit_code": result.returncode, "wall_seconds": time.time() - started, "inference_log": record(log_path)})
        meta["generation_status"] = "FAILED" if result.returncode else "COMPLETE"
        write_json(meta_path, meta)
        if result.returncode:
            raise SystemExit("Actual inference failed; preserved log, no automatic retry: " + stem)
        meta["processing"] = audition(raw, stem)
        decoder = raw.with_suffix(".decoder.json")
        meta["raw_outputs"] = [record(raw), record(decoder)]
        write_json(meta_path, meta)
        print("CANDIDATE_READY", stem, meta["processing"]["seconds"], meta["processing"]["actual_rms_dbfs"], flush=True)
        manifest = {"purpose": plan["purpose"], "status": "LISTENING_PENDING", "plan": record(PLAN),
                    "production_script": record(Path(__file__)), "loop_processing": "NONE", "game_integration": "NONE",
                    "tracks": [json.loads(p.read_text(encoding="utf-8")) for p in sorted(RAW.glob("*.meta.json"))]}
        write_json(PROCESSED / "manifest.json", manifest)


if __name__ == "__main__":
    main()
