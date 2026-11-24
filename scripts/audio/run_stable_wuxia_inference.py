"""Invoke official CPU Stable Audio CLI, preserving unclipped raw model samples.

Run with the isolated LiteRT interpreter, followed by the official CLI flags.
No network, playback, source/reference audio, or changes to the upstream clone.
"""
from pathlib import Path
import json
import os
import runpy
import struct
import sys
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "tools/audio/stable-audio-3/optimized/tflite"
os.environ["HF_HUB_OFFLINE"] = "1"
os.environ["HF_HUB_DISABLE_IMPLICIT_TOKEN"] = "1"
sys.path.insert(0, str(RUNTIME))
sys.path.insert(0, str(RUNTIME / "scripts"))
from models.defs import tflite_pipeline as pipeline


def save_unclipped(path, samples):
    """32-bit IEEE float WAV preserves actual decoder values without hard clipping."""
    audio = np.asarray(samples, dtype=np.float32)
    if audio.ndim != 2 or audio.shape[0] != 2 or not np.isfinite(audio).all():
        raise ValueError("Decoder returned invalid stereo samples")
    payload = audio.T.astype("<f4").tobytes()
    header = struct.pack("<4sI4s4sIHHIIHH4sI", b"RIFF", 36 + len(payload), b"WAVE",
                         b"fmt ", 16, 3, 2, 44100, 44100 * 8, 8, 32, b"data", len(payload))
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(header + payload)
    peak = float(np.max(np.abs(audio)))
    rms = float(np.sqrt(np.mean(audio.astype(np.float64) ** 2)))
    target.with_suffix(".decoder.json").write_text(json.dumps({
        "raw_format": "IEEE_FLOAT32_STEREO", "sample_rate": 44100,
        "frames": audio.shape[1], "seconds": audio.shape[1] / 44100,
        "raw_peak": peak, "raw_rms": rms, "finite": True,
        "samples_above_unity": int(np.count_nonzero(np.abs(audio) > 1)),
        "export_clipping": False,
        "note": "Official inference samples preserved; standard CLI hard-clipping export replaced only in memory."
    }, indent=2), encoding="utf-8")


pipeline.save_wav = save_unclipped
runpy.run_path(str(RUNTIME / "scripts/sa3_tflite.py"), run_name="__main__")
