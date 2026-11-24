"""Reproducible original text-to-music candidates; isolated model inference.

Usage: python scripts/audio/produce_wuxia_stable_trial.py --probe
       python scripts/audio/produce_wuxia_stable_trial.py --track all
The first command makes a separate 30-second proof; second makes 3 x 45 seconds.
Requires downloaded pinned weights and the isolated official LiteRT runtime.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import os
import subprocess
import sys
import time
import wave
import numpy as np
import av

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "assets/raw/audio/wuxia_ai_trial_20261009"
RUNTIME = ROOT / "tools/audio/stable-audio-3/optimized/tflite"
PLAN_PATH = Path(__file__).with_name("wuxia_stable_trial_plan_20261009.json")


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def decode(path):
    with av.open(str(path)) as container:
        resampler = av.AudioResampler(format="fltp", layout="stereo", rate=44100)
        frames = [f.to_ndarray() for decoded in container.decode(audio=0)
                  for f in resampler.resample(decoded)]
        frames.extend(f.to_ndarray() for f in resampler.resample(None))
    return np.concatenate(frames, axis=1)


def encode_mp3(path, samples, rate=44100):
    with av.open(str(path), "w") as output:
        stream = output.add_stream("libmp3lame", rate=rate)
        stream.bit_rate = 192000
        stream.layout = "stereo"
        for offset in range(0, samples.shape[1], 1152):
            frame = av.AudioFrame.from_ndarray(np.ascontiguousarray(samples[:, offset:offset + 1152]),
                                              format="fltp", layout="stereo")
            frame.sample_rate = rate
            for packet in stream.encode(frame):
                output.mux(packet)
        for packet in stream.encode(None):
            output.mux(packet)


def export_preview(raw_path):
    raw = decode(raw_path).astype(np.float32)
    peak = float(np.abs(raw).max())
    if not np.isfinite(raw).all() or peak == 0:
        raise ValueError("Non-finite or silent model output")
    gain = min(1.0, 10 ** (-3 / 20) / peak)
    listen = raw * gain
    # Tiny edge fades prevent file-boundary clicks; no loop/crossfade approval claimed.
    n = min(662, listen.shape[1] // 2)
    listen[:, :n] *= np.linspace(0, 1, n, dtype=np.float32)
    listen[:, -n:] *= np.linspace(1, 0, n, dtype=np.float32)
    pcm = (listen.T * 32767).astype("<i2")
    preview = raw_path.with_name(raw_path.stem.removesuffix("_raw") + "_listen.wav")
    with wave.open(str(preview), "wb") as output:
        output.setparams((2, 2, 44100, 0, "NONE", "not compressed"))
        output.writeframes(pcm.tobytes())
    mp3 = preview.with_suffix(".mp3")
    encode_mp3(mp3, listen)
    rms = float(np.sqrt(np.mean(listen.astype(np.float64) ** 2)))
    report = {"raw_peak": peak, "preview_peak": float(np.abs(listen).max()),
              "preview_rms": rms, "preview_rms_dbfs": 20 * math.log10(max(rms, 1e-12)),
              "preview_gain_db": 20 * math.log10(gain), "sample_rate": 44100,
              "linear_gain": gain, "edge_fade_frames": n, "edge_fade_seconds": n / 44100,
              "quantization": "trunc_int16", "pcm_scale": 32767,
              "channels": 2, "seconds": raw.shape[1] / 44100,
              "finite": True, "non_silent": rms > 0.00001,
              "clipped_pcm_samples": int(np.count_nonzero(np.abs(pcm.astype(np.int32)) >= 32767)),
              "processing": "Gain only if peak exceeds -3 dBFS; 15 ms preview edge fades; MP3 192 kbps.",
              "loop_review": "PENDING", "musical_style_review": "LISTENING_PENDING"}
    assert report["non_silent"] and report["clipped_pcm_samples"] == 0
    return preview, mp3, report


def main():
    global DEST
    ap = argparse.ArgumentParser()
    ap.add_argument("--probe", action="store_true")
    ap.add_argument("--track", default="all")
    ap.add_argument("--threads", type=int, default=6)
    ap.add_argument("--output-dir", default=str(DEST))
    args = ap.parse_args()
    DEST = Path(args.output_dir).resolve()
    if not DEST.is_relative_to(ROOT / "assets/raw/audio/wuxia_ai_trial_20261009"):
        raise SystemExit("Output must stay under the isolated wuxia trial directory")
    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    required = ["sa3-sm-music/dit_fp32.tflite", "t5gemma/encoder_fp16.tflite", "same-s/dec_w8a8.tflite"]
    models = [RUNTIME / "models/tflite" / x for x in required]
    missing = [str(x) for x in models if not x.is_file()]
    if missing:
        raise SystemExit("Pinned runtime files missing; download first: " + ", ".join(missing))
    DEST.mkdir(parents=True, exist_ok=True)
    model_files = {str(x.relative_to(ROOT)): {"size": x.stat().st_size, "sha256": sha256(x)} for x in models}
    runtime_manifest_path = ROOT / "tools/audio/stable-audio-3/trial_runtime_manifest.json"
    runtime_manifest = json.loads(runtime_manifest_path.read_text(encoding="utf-8"))
    if runtime_manifest["weights_revision"] != plan["model_revision"]:
        raise SystemExit("Pinned model revision does not match the preparation manifest")
    expected_files = {x["file"]: x for x in runtime_manifest["files"]}
    for model in models:
        name = "tflite/" + str(model.relative_to(RUNTIME / "models/tflite")).replace("\\", "/")
        actual = model_files[str(model.relative_to(ROOT))]
        expected = expected_files[name]
        if actual["sha256"] != expected["sha256"] or actual["size"] != expected["size"]:
            raise SystemExit("Model integrity does not match the pinned official download: " + name)
    tracks = plan["tracks"][:1] if args.probe else [x for x in plan["tracks"] if args.track in ("all", x["id"])]
    if not tracks:
        raise SystemExit("Unknown track")
    for track in tracks:
        seconds = 30 if args.probe else track["seconds"]
        stem = track["id"] + ("_probe30" if args.probe else "_45s")
        raw = DEST / (stem + "_raw.wav")
        if raw.exists():
            raise SystemExit(f"Preserving existing output: {raw}")
        command = [str(RUNTIME / ".venv/Scripts/python.exe"),
                   str(Path(__file__).with_name("run_stable_wuxia_inference.py")),
                   "--dit", "sm-music", "--decoder", "same-s", "--dit-precision", "fp32",
                   "--decoder-precision", "w8a8", "--prompt", track["prompt"],
                   "--seconds", str(seconds), "--steps", "8", "--seed", str(track["seed"]),
                   "--threads", str(args.threads), "--out", str(raw)]
        metadata = {**{k: v for k, v in plan.items() if k != "tracks"}, **track,
                    "seconds": seconds, "kind": "probe" if args.probe else "candidate",
                    "runtime_flags": command[2:], "model_files": model_files,
                    "runtime_preparation_manifest": runtime_manifest,
                    "generation_method": "Original text2music; no reference or source audio.",
                    "review": "LISTENING_PENDING"}
        meta_path = DEST / (stem + ".meta.json")
        meta_path.write_text(json.dumps(metadata, indent=2, ensure_ascii=False), encoding="utf-8")
        started = time.time()
        print(f"INFERENCE_START {stem}", flush=True)
        with (DEST / (stem + ".inference.log")).open("w", encoding="utf-8") as log:
            result = subprocess.run(command, cwd=RUNTIME, stdout=log, stderr=subprocess.STDOUT,
                                    env={**os.environ, "HF_HUB_OFFLINE": "1", "HF_HUB_DISABLE_IMPLICIT_TOKEN": "1"})
        metadata.update({"inference_exit_code": result.returncode, "wall_seconds": time.time() - started})
        if result.returncode:
            meta_path.write_text(json.dumps(metadata, indent=2, ensure_ascii=False), encoding="utf-8")
            raise SystemExit(f"Inference failed; inspect {stem}.inference.log")
        preview, mp3, report = export_preview(raw)
        metadata["technical_validation"] = report
        metadata["outputs"] = {str(x.relative_to(ROOT)): {"size": x.stat().st_size, "sha256": sha256(x)}
                               for x in (raw, preview, mp3)}
        meta_path.write_text(json.dumps(metadata, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"CANDIDATE_READY {stem} {report}", flush=True)
    manifest = {"status": "LISTENING_PENDING", "plan": str(PLAN_PATH.relative_to(ROOT)),
                "files": {str(p.relative_to(ROOT)): {"size": p.stat().st_size, "sha256": sha256(p)}
                          for p in sorted(DEST.iterdir()) if p.is_file() and p.name != "manifest.json"}}
    (DEST / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
