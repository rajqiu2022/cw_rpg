"""Bounded candidate dialogue TTS; never edits game resources or existing audio.

Input schema: {"status": "CANDIDATE", "lines": [{"id", "speaker", "text",
"dialog_path", "node_id", "voice", "emotion", "character_params": {...}}]}.
Uses the project's existing Edge TTS rendering function, with explicit voices.
Audio is a review candidate, not a claim of voice acting quality or deployment.
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
VOICE_IDS = {"zh-CN-YunjianNeural", "zh-CN-YunxiNeural", "zh-CN-YunyangNeural",
             "zh-CN-XiaoyiNeural", "zh-CN-XiaoxiaoNeural"}
EMOTIONS = {"normal", "concerned", "solemn", "weary", "fear", "happy", "sad", "angry", "threat"}


def bind_dialogue(row: dict) -> str:
    value = row.get("dialog_path")
    if not isinstance(value, str):
        raise ValueError("A source dialogue path is required")
    path = (ROOT / value).resolve()
    if not path.is_relative_to(ROOT / "game/data/dialogs") or path.suffix != ".tres":
        raise ValueError("Source must be a dialogue resource in this project")
    raw = path.read_bytes()
    blocks = re.findall(r"\[sub_resource[^\]]*\](.*?)(?=\n\[sub_resource|\n\[resource\])", raw.decode("utf-8"), re.S)
    matches = []
    for block in blocks:
        fields = {}
        for key in ("node_id", "speaker", "text", "voice_emotion"):
            field = re.search(r'^' + key + r'\s*=\s*&?("(?:[^"\\]|\\.)*")\s*$', block, re.M)
            if field:
                fields[key] = json.loads(field.group(1))
        if fields.get("node_id") == row.get("node_id"):
            matches.append(fields)
    if len(matches) != 1:
        raise ValueError("Missing or ambiguous source dialogue node")
    source = matches[0]
    if any(source.get(key) != row.get(key) for key in ("speaker", "text")) or source.get("voice_emotion") != row.get("emotion"):
        raise ValueError("Voice text, speaker or emotion differs from authored dialogue")
    return hashlib.sha256(raw).hexdigest()


def load_manifest(path: Path) -> tuple[list[dict], str]:
    raw = path.read_bytes()
    doc = json.loads(raw)
    if doc.get("status") != "CANDIDATE" or not isinstance(doc.get("lines"), list):
        raise ValueError("Only explicit CANDIDATE line manifests are accepted")
    seen = set()
    lines = doc["lines"]
    if not 1 <= len(lines) <= 32:
        raise ValueError("One bounded batch requires 1..32 lines")
    for row in lines:
        if not isinstance(row, dict):
            raise ValueError("A speech line must be an object")
        if not re.fullmatch(r"[a-z0-9_]{1,100}", row.get("id", "")) or row["id"] in seen:
            raise ValueError("Unsafe or duplicate line id")
        seen.add(row["id"])
        if row.get("voice") not in VOICE_IDS or row.get("emotion") not in EMOTIONS:
            raise ValueError("An explicit supported voice and emotion are required")
        if not isinstance(row.get("speaker"), str) or not row["speaker"].strip():
            raise ValueError("Missing speaker")
        if not isinstance(row.get("text"), str) or not 1 <= len(row["text"]) <= 300:
            raise ValueError("Missing or oversized spoken text")
        params = row.get("character_params", {})
        if not isinstance(params, dict) or set(params) - {"rate", "pitch", "volume"}:
            raise ValueError("Unsupported character parameter")
        for key, value in params.items():
            unit = "Hz" if key == "pitch" else "%"
            if not isinstance(value, str) or not re.fullmatch(r"[+-]\d+" + unit, value):
                raise ValueError("Unsafe character parameter value")
            if abs(int(value.removesuffix(unit))) > 20:
                raise ValueError("Excessive voice distortion is not allowed")
        row["dialog_source_sha256"] = bind_dialogue(row)
    return lines, hashlib.sha256(raw).hexdigest()


def row_digest(row: dict, renderer_sha: str) -> str:
    spec = {"line": row, "renderer_sha256": renderer_sha}
    return hashlib.sha256(json.dumps(spec, ensure_ascii=False, sort_keys=True).encode()).hexdigest()


async def render(args: argparse.Namespace) -> int:
    lines, manifest_sha = load_manifest(args.manifest.resolve())
    renderer = ROOT / "scripts/gen_dialog_voices.py"
    renderer_sha = hashlib.sha256(renderer.read_bytes()).hexdigest()
    if args.dry_run:
        print(json.dumps({"dry_run": True, "lines": len(lines), "parallel": args.parallel,
                          "manifest_sha256": manifest_sha, "renderer_sha256": renderer_sha,
                          "network_calls": 0}, ensure_ascii=False))
        return 0
    output = args.out_dir.resolve()
    # This producer deliberately cannot write to the production game tree.
    if not output.is_relative_to(ROOT / "assets"):
        raise ValueError("Candidate audio must remain beneath this project's assets directory")
    output.mkdir(parents=True, exist_ok=True)
    # Refuse an entire conflicting batch before opening any network connection.
    for row in lines:
        final = output / (row["id"] + ".mp3")
        receipt = output / (row["id"] + ".meta.json")
        if final.exists() or receipt.exists():
            if not final.is_file() or not receipt.is_file():
                raise FileExistsError("Incomplete existing output: " + row["id"])
            previous = json.loads(receipt.read_text(encoding="utf-8"))
            if previous.get("input_sha256") != row_digest(row, renderer_sha) or previous.get("audio_sha256") != hashlib.sha256(final.read_bytes()).hexdigest():
                raise FileExistsError("Existing candidate differs; choose a versioned directory: " + row["id"])
    spec = importlib.util.spec_from_file_location("resident_existing_voice_renderer", renderer)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    semaphore = asyncio.Semaphore(args.parallel)

    async def one(row: dict) -> dict:
        async with semaphore:
            final = output / (row["id"] + ".mp3")
            receipt = output / (row["id"] + ".meta.json")
            if final.exists():
                return {"id": row["id"], "status": "REUSED_EXACT_INPUT_AND_AUDIO"}
            partial = output / (row["id"] + ".partial.mp3")
            if partial.exists():
                return {"id": row["id"], "status": "FAILED", "error": "Prior partial preserved; use a new versioned output directory"}
            try:
                ok = await asyncio.wait_for(module.gen_voice(row["voice"], row["text"], row["emotion"], partial, row.get("character_params", {})), timeout=35)
                if not ok or partial.stat().st_size < 128:
                    raise ValueError("Empty or incomplete audio")
                partial.rename(final)
                meta = {"status": "SYNTHETIC_VOICE_CANDIDATE_NOT_LISTENED_OR_FORMAL", "provider": "edge_tts",
                        "input_sha256": row_digest(row, renderer_sha), "manifest_sha256": manifest_sha,
                        "renderer_sha256": renderer_sha, "audio_sha256": hashlib.sha256(final.read_bytes()).hexdigest(),
                        "line": row, "fallback_used": False, "attempts": 1}
                receipt.write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")
                return {"id": row["id"], "status": "GENERATED", "bytes": final.stat().st_size}
            except Exception as exc:
                # Preserve any partial artifact for diagnosis. Do not retry silently.
                return {"id": row["id"], "status": "FAILED", "error": type(exc).__name__, "http_status": getattr(exc, "status", None)}

    rows = await asyncio.gather(*(one(row) for row in lines))
    failures = sum(row["status"] == "FAILED" for row in rows)
    report = {"complete": failures == 0, "failures": failures, "rows": rows,
              "manifest_sha256": manifest_sha, "concurrency": args.parallel, "automatic_retries": 0}
    print(json.dumps(report, ensure_ascii=False))
    return 1 if failures else 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    parser.add_argument("--parallel", type=int, choices=(1, 2), default=2)
    parser.add_argument("--dry-run", action="store_true")
    return asyncio.run(render(parser.parse_args()))


if __name__ == "__main__":
    sys.exit(main())
