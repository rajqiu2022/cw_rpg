"""Make separate RMS-matched audition exports from actual unclipped model WAVs.

Preserves raw, _listen exports, and original generation metadata byte for byte.
Only linear gain and the same 662-frame file-edge fades; no dynamics processing.
"""
from pathlib import Path
import argparse
import json
import math
import wave
import numpy as np
from produce_wuxia_stable_trial import ROOT, DEST, decode, encode_mp3, sha256

TARGET_RMS = 10 ** (-22 / 20)
PEAK_CAP = 10 ** (-3 / 20)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--output-dir", default=str(DEST))
    args = ap.parse_args()
    dest = Path(args.output_dir).resolve()
    if not dest.is_relative_to(ROOT / "assets/raw/audio/wuxia_ai_trial_20261009"):
        raise SystemExit("Output must stay under the isolated wuxia trial directory")
    records = []
    for raw in sorted(dest.glob("*_45s_raw.wav")):
        stem = raw.stem.removesuffix("_raw")
        wav = dest / (stem + "_audition.wav")
        mp3 = wav.with_suffix(".mp3")
        meta = wav.with_suffix(".processing.json")
        if any(path.exists() for path in (wav, mp3, meta)):
            raise SystemExit("Existing audition preserved: " + stem)
        audio = decode(raw).astype(np.float32)
        peak = float(np.max(np.abs(audio)))
        rms = float(np.sqrt(np.mean(audio.astype(np.float64) ** 2)))
        if not np.isfinite(audio).all() or rms <= 0.00001:
            raise ValueError("Invalid/silent actual model audio")
        gain = min(TARGET_RMS / rms, PEAK_CAP / peak)
        processed = audio * gain
        n = min(662, processed.shape[1] // 2)
        processed[:, :n] *= np.linspace(0, 1, n, dtype=np.float32)
        processed[:, -n:] *= np.linspace(1, 0, n, dtype=np.float32)
        pcm = (processed.T * 32767).astype("<i2")
        with wave.open(str(wav), "wb") as output:
            output.setparams((2, 2, 44100, 0, "NONE", "not compressed"))
            output.writeframes(pcm.tobytes())
        encode_mp3(mp3, processed)
        actual_rms = float(np.sqrt(np.mean(processed.astype(np.float64) ** 2)))
        record = {
            "status": "LISTENING_PENDING", "purpose": "Comparable listening level; no style approval.",
            "source": str(raw.relative_to(ROOT)), "source_sha256": sha256(raw),
            "source_rms": rms, "source_rms_dbfs": 20 * math.log10(rms), "source_peak": peak,
            "target_rms_dbfs": -22, "peak_cap_dbfs": -3, "linear_gain": gain,
            "gain_db": 20 * math.log10(gain), "peak_cap_limited": PEAK_CAP / peak < TARGET_RMS / rms,
            "actual_rms_dbfs": 20 * math.log10(actual_rms), "actual_peak": float(np.max(np.abs(processed))),
            "edge_fade_frames": n, "edge_fade_seconds": n / 44100,
            "quantization": "trunc_int16", "pcm_scale": 32767,
            "sample_rate": 44100, "channels": 2, "frames": processed.shape[1],
            "seconds": processed.shape[1] / 44100,
            "clipped_pcm_samples": int(np.count_nonzero(np.abs(pcm.astype(np.int32)) >= 32767)),
            "processing": "Fixed linear gain, then 662-frame linear edge fades; no compression/EQ/remixing.",
            "files": {str(path.relative_to(ROOT)): {"sha256": sha256(path), "size": path.stat().st_size}
                      for path in (wav, mp3)}
        }
        assert record["clipped_pcm_samples"] == 0
        meta.write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding="utf-8")
        records.append(record)
        print("AUDITION_READY", stem, record["gain_db"], record["actual_rms_dbfs"], flush=True)
    if len(records) != 3:
        raise SystemExit("Expected the three actual 45-second candidates")
    (dest / "audition_manifest.json").write_text(json.dumps({
        "status": "LISTENING_PENDING", "level_matching": "target RMS -22dBFS / peak cap -3dBFS",
        "tracks": records
    }, indent=2, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    main()
