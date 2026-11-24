"""Decode/hash checks only. Does not listen or certify acting/naturalness."""
from array import array
import hashlib
import json
from pathlib import Path
import sys
import wave

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / "assets/processed/luoyang_resident_life_20261019v/voice_trial02_offline"
batch = json.loads((FOLDER / "result.json").read_text(encoding="utf-8-sig"))
rows = []
for entry in batch["rows"]:
    path = FOLDER / (entry["id"] + ".wav")
    meta = json.loads(path.with_suffix(".meta.json").read_text(encoding="utf-8-sig"))
    with wave.open(str(path), "rb") as source:
        rate, channels, width, frames = source.getframerate(), source.getnchannels(), source.getsampwidth(), source.getnframes()
        data = source.readframes(frames)
    samples = array("h", data)
    if sys.byteorder == "big":
        samples.byteswap()
    duration = frames / rate
    peak = max(abs(value) for value in samples) if samples else 0
    sha = hashlib.sha256(path.read_bytes()).hexdigest()
    passed = (rate == 24000 and channels == 1 and width == 2 and len(data) == frames * 2
              and 0.5 < duration < 30 and peak > 100
              and sha == entry["sha256"].lower() == meta["audio_sha256"].lower()
              and hashlib.sha256((ROOT / meta["dialog_path"]).read_bytes()).hexdigest().upper() == meta["dialog_sha256"])
    rows.append({"id": entry["id"], "passed": passed, "duration_seconds": duration, "peak_pcm16": peak, "sha256": sha})
report = {"complete": len(rows) == 8 and all(row["passed"] for row in rows), "scope": "EIGHT_OFFLINE_WAV_DECODE_AND_SOURCE_HASH_ONLY",
          "rows": rows, "listening_or_acting_quality_granted": False, "runtime_mp3_admission": False}
(FOLDER / "decode_review_retry1.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(report, ensure_ascii=False))
sys.exit(0 if report["complete"] else 1)
