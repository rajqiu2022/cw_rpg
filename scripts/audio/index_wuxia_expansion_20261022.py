"""Read completed expansion outputs, perform small author checks, write NEW index.

No models, rendering, playback, game/import writes or mutation of production
audio/metadata. The energy observations do not approve musical style or loops.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import os
import wave
import numpy as np
import produce_wuxia_stable_personal_continuation as io

ROOT = io.ROOT
OUT = ROOT / "assets/processed/audio/wuxia_expansion_20261022"
PLAN = ROOT / "scripts/audio/wuxia_expansion_plan_20261022.json"


def pcm_observation(path):
    with wave.open(str(path), "rb") as wav:
        channels, width, rate, frames = wav.getnchannels(), wav.getsampwidth(), wav.getframerate(), wav.getnframes()
        data = wav.readframes(frames)
    if (channels, width, rate) != (2, 2, 44100) or len(data) != frames * 4:
        raise ValueError("Unexpected PCM export: " + str(path))
    pcm = np.frombuffer(data, dtype="<i2").reshape(-1, 2)
    peak_i = int(np.abs(pcm.astype(np.int32)).max())
    rms = float(np.sqrt(np.mean((pcm.astype(np.float64) / 32768) ** 2)))
    if peak_i >= 32767 or peak_i == 0 or rms <= 1e-5:
        raise ValueError("Silent or unsafe PCM: " + str(path))
    return {"frames": frames, "seconds": frames / rate, "channels": channels,
            "sample_rate": rate, "format": "PCM16", "pcm_peak": peak_i / 32768,
            "rms_dbfs": 20 * math.log10(rms), "fullscale_samples": 0}


def body_energy(path, end_seconds):
    with wave.open(str(path), "rb") as wav:
        rate = wav.getframerate()
        pcm = np.frombuffer(wav.readframes(wav.getnframes()), dtype="<i2").reshape(-1, 2)
    # Exact full audition PCM; 40ms window / 10ms hop, start >= 3s,
    # ending before the plan's fixed analysis endpoint, excluding raw tail.
    energy = np.mean((pcm.astype(np.float64) / 32768) ** 2, axis=1)
    cumulative = np.concatenate(([0.0], np.cumsum(energy)))
    win, hop = round(.04 * rate), round(.01 * rate)
    starts = np.arange(3 * rate, min(round(end_seconds * rate), len(pcm)) - win + 1, hop, dtype=np.int64)
    values = np.sqrt((cumulative[starts + win] - cumulative[starts]) / win)
    low = values < 10 ** (-45 / 20)
    segments = []
    for group in np.split(np.flatnonzero(low), np.flatnonzero(np.diff(np.flatnonzero(low)) > 1) + 1):
        if not len(group):
            continue
        start, end = int(starts[group[0]]), int(starts[group[-1]] + win)
        if (end - start) / rate >= .15:
            segments.append({"start_seconds": start / rate, "end_seconds": end / rate,
                             "duration_seconds": (end - start) / rate})
    return {"source": io.record(path), "window_ms": 40, "hop_ms": 10,
            "threshold_dbfs": -45, "analysis_start_seconds": 3, "analysis_end_seconds": end_seconds,
            "low_window_percent": float(np.mean(low) * 100), "segments_at_least_150ms": segments,
            "maximum_internal_low_seconds": max((x["duration_seconds"] for x in segments), default=0),
            "note": "Numerical observation only; quiet phrasing is not automatically a failure or a reason to regenerate."}


def make_groups(rows):
    groups = [
        ("cities", "城市昼夜", rows[:4]),
        ("village_field", "村庄客栈与野外", rows[4:10]),
        ("story", "剧情情绪", rows[10:15]),
        ("battle", "战斗", rows[15:20]),
    ]
    group_paths = [OUT / ("group_" + name + ext) for name, _, _ in groups for ext in (".wav", ".mp3")]
    manifest_path = OUT / "group_audition_manifest_20261022.json"
    if any(p.exists() for p in group_paths + [manifest_path]):
        raise ValueError("Existing group audition preserved")
    records = []
    prefix, gap = 12 * 44100, round(.8 * 44100)
    for name, title, tracks in groups:
        parts, timeline, cursor = [], [], 0
        for i, row in enumerate(tracks):
            source = ROOT / row["full_audition_wav"]["path"]
            with wave.open(str(source), "rb") as wav:
                if (wav.getnchannels(), wav.getsampwidth(), wav.getframerate()) != (2, 2, 44100):
                    raise ValueError("Unexpected group source PCM")
                payload = wav.readframes(prefix)
            if len(payload) != prefix * 4:
                raise ValueError("Insufficient group source")
            parts.append(payload)
            timeline.append({"id": row["id"], "title_zh": row["title_zh"], "source": io.record(source),
                             "source_start_frame": 0, "source_end_frame_exclusive": prefix,
                             "destination_start_frame": cursor, "destination_end_frame_exclusive": cursor + prefix,
                             "start_seconds": cursor / 44100, "end_seconds": (cursor + prefix) / 44100})
            cursor += prefix
            if i < len(tracks) - 1:
                parts.append(bytes(gap * 4))
                cursor += gap
        pcm_bytes = b"".join(parts)
        path = OUT / ("group_" + name + ".wav")
        with wave.open(str(path), "wb") as output:
            output.setparams((2, 2, 44100, 0, "NONE", "not compressed"))
            output.writeframes(pcm_bytes)
        # WAV prefixes are copied byte-for-byte; MP3 encodes their PCM once.
        audio = np.frombuffer(pcm_bytes, dtype="<i2").reshape(-1, 2).T.astype(np.float32) / 32768
        io.encode_mp3(path.with_suffix(".mp3"), audio)
        records.append({"id": name, "title_zh": title, "frames": cursor, "seconds": cursor / 44100,
                        "track_prefix_frames": prefix, "gap_frames": gap, "gap_seconds": .8,
                        "construction": "Exact first12s PCM bytes of each full audition; 0.8s all-zero manual separators; no final separator, no requantization or new gain",
                        "game_loop": False, "timeline": timeline,
                        "outputs": [io.record(path), io.record(path.with_suffix(".mp3"))]})
    manifest_path.write_text(json.dumps({"status": "GROUP_AUDITIONS_ONLY_NOT_GAME_LOOPS", "groups": records,
                                       "index_script": io.record(Path(__file__))}, ensure_ascii=False, indent=2), encoding="utf-8")
    return records


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--investigation-alt", action="store_true")
    parser.add_argument("--alt-qa-report", type=Path)
    args = parser.parse_args()
    if args.investigation_alt and (not args.alt_qa_report or not args.alt_qa_report.exists()):
        raise SystemExit("An independently completed ALT QA report is required before selected-alt groups")
    index_path = OUT / "listening_index_20261022.json"
    readme_path = OUT / "README.md"
    delivery_path = OUT / "delivery_manifest_20261022.json"
    selected_path = OUT / "selected20_manifest_20261022.json"
    if any(p.exists() for p in (index_path, readme_path, delivery_path, selected_path)):
        raise SystemExit("Existing index/delivery preserved")
    plan = json.loads(PLAN.read_text(encoding="utf-8"))
    manifest_path = OUT / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if len(manifest["tracks"]) != 20 or len(manifest["loops"]) != 20:
        raise ValueError("Incomplete bank")
    tracks = {t["id"]: t for t in manifest["tracks"]}
    loops = {t["track"]["id"]: t for t in manifest["loops"]}
    rows = []
    for track in plan["tracks"]:
        tid = track["id"]
        meta, loop = tracks[tid], loops[tid]
        if meta["generation_status"] != "COMPLETE" or meta["inference_exit_code"] != 0 or loop["status"] != "LOOP_LISTENING_PENDING":
            raise ValueError("Incomplete model or loop output: " + tid)
        outputs = meta["processing"]["outputs"] + loop["outputs"]
        observations = []
        for item in outputs:
            path = ROOT / item["path"]
            if io.record(path) != item:
                raise ValueError("Changed output: " + str(path))
            if path.suffix == ".wav":
                observations.append({"file": item, **pcm_observation(path)})
        if len(observations) != 4:
            raise ValueError("Expected full/preview/loop/seam PCM")
        full = OUT / (tid + "_audition.wav")
        rows.append({"id": tid, "title_zh": track["title_zh"], "category": track["category"],
                     "seed": track["seed"], "full_seconds": meta["processing"]["seconds"],
                     "loop_seconds": loop["loop"]["loop_seconds"], "outputs": outputs,
                     "full_audition_wav": io.record(full), "source_manifest": io.record(manifest_path), "selection": "ORIGINAL",
                     "author_pcm_checks": observations, "full_pcm_body_energy": body_energy(full, track["analysis_end_seconds"]),
                     "listening": "PENDING", "loop_listening": "PENDING", "formal_game_adopted": False})
    index = {"scope": "20 new independent local CPU BGM candidates", "purpose": plan["purpose"],
             "plan": io.record(PLAN), "production_manifest": io.record(manifest_path),
             "author_index_script": io.record(Path(__file__)), "author_pcm_checks": "80 WAV exports passed",
             "tracks": rows, "model_retries": 0, "game_integration": "NONE"}
    index_path.write_text(json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8")
    selected_rows = list(rows)
    alt_dir = ROOT / "assets/processed/audio/wuxia_expansion_investigation_alt_20261022"
    alt_manifest_path = alt_dir / "manifest.json"
    alt_comparison = None
    if alt_manifest_path.exists():
        alt_manifest = json.loads(alt_manifest_path.read_text(encoding="utf-8"))
        alt_meta, alt_loop = alt_manifest["tracks"][0], alt_manifest["loops"][0]
        if alt_meta["id"] != "story_investigation_threads" or alt_meta["seed"] != 2026102251 or alt_meta["seconds"] != 96 or alt_meta["inference_exit_code"] != 0:
            raise ValueError("Unexpected investigation ALT provenance")
        alt_outputs = alt_meta["processing"]["outputs"] + alt_loop["outputs"]
        alt_observations = []
        for item in alt_outputs:
            path = ROOT / item["path"]
            if io.record(path) != item:
                raise ValueError("Changed ALT export")
            if path.suffix == ".wav":
                alt_observations.append({"file": item, **pcm_observation(path)})
        alt_full = alt_dir / "story_investigation_threads_audition.wav"
        alt_energy = body_energy(alt_full, 90)
        original_row = next(r for r in rows if r["id"] == "story_investigation_threads")
        alt_comparison = {"original_source": original_row["source_manifest"],
                          "original_energy": original_row["full_pcm_body_energy"],
                          "alt_source": io.record(alt_manifest_path), "alt_energy": alt_energy,
                          "independent_qa_report": io.record(args.alt_qa_report.resolve()) if args.alt_qa_report else None,
                          "selected": args.investigation_alt, "listening": "PENDING"}
        if args.investigation_alt:
            if not (alt_energy["low_window_percent"] < original_row["full_pcm_body_energy"]["low_window_percent"] and alt_energy["maximum_internal_low_seconds"] < original_row["full_pcm_body_energy"]["maximum_internal_low_seconds"]):
                raise ValueError("Selected ALT must improve both documented body-energy observations")
            alt_row = {**original_row, "title_zh": alt_meta["title_zh"], "seed": alt_meta["seed"],
                       "full_seconds": 96, "loop_seconds": alt_loop["loop"]["loop_seconds"],
                       "outputs": alt_outputs, "full_audition_wav": io.record(alt_full),
                       "source_manifest": io.record(alt_manifest_path), "selection": "INVESTIGATION_ALT",
                       "author_pcm_checks": alt_observations, "full_pcm_body_energy": alt_energy}
            selected_rows = [alt_row if r["id"] == original_row["id"] else r for r in rows]
    elif args.investigation_alt:
        raise ValueError("Requested ALT is absent")
    selected_path.write_text(json.dumps({"status": "TWENTY_LISTENING_CANDIDATES_NOT_GAME_ADOPTED", "selected_count": 20,
                                        "archive_independent_generations": 21 if alt_comparison else 20,
                                        "selection_basis": "Producer authorized the sole ALT; independent QA receipt and objective body comparison recorded; listening remains pending",
                                        "tracks": selected_rows, "investigation_comparison": alt_comparison}, ensure_ascii=False, indent=2), encoding="utf-8")
    groups = make_groups(selected_rows)
    lines = ["# 新增武侠音乐试听 · 2026-10-22", "",
             "固定原批20首独立本地 Stable Audio Small Music 候选：城市昼夜4、村庄/客栈2、野外4、剧情5、战斗5。原20为10首96秒、10首72秒，共28分钟原母带；每首一个固定seed实际推理一次。", "",
             "沿已认可配器方向制作，但本批20首与循环接缝尚待逐首试听。配器提示不等于实际乐器身份验证；当前仅个人暂不商用制作，未修改现役游戏音乐、场景或玩家存档。", "",
             "四组串听使用各曲完整试听前12秒，片间0.8秒人工静音分隔、最后无额外静音；这些分曲空档不是母带或游戏循环的一部分。", ""]
    for group in groups:
        lines.append(f'- [{group["title_zh"]}串听 · {group["seconds"]:.1f}s](group_{group["id"]}.mp3)')
        lines.append("  顺序：" + "；".join(f'{x["start_seconds"]:.1f}–{x["end_seconds"]:.1f}s {x["title_zh"]}' for x in group["timeline"]))
    lines += ["", "| 主题 | 全曲 | 前30秒 | 长循环 | 尾→头10秒 | 内部低能量观察 |",
              "|---|---|---|---|---|---|"]
    for row in selected_rows:
        tid = row["id"]
        stem = Path(row["full_audition_wav"]["path"]).parent / tid
        link_stem = os.path.relpath(ROOT / stem, OUT).replace("\\", "/")
        energy = row["full_pcm_body_energy"]
        low = f'最长{energy["maximum_internal_low_seconds"]:.2f}s；低窗{energy["low_window_percent"]:.2f}%'
        lines.append(f'| {row["title_zh"]} | [{row["full_seconds"]:.0f}s]({link_stem}_audition.mp3) | [30s]({link_stem}_first30s.mp3) | [{row["loop_seconds"]:.2f}s]({link_stem}_loop.mp3) | [边界试听]({link_stem}_two_cycle_seam10.mp3) | {low} |')
    if alt_comparison:
        old_energy = alt_comparison["original_energy"]
        new_energy = alt_comparison["alt_energy"]
        selection = "采用ALT作为本轮试听来源，19原＋1ALT" if args.investigation_alt else "保留原版作为本轮试听来源，ALT仅附录对照"
        lines += ["", f'调查曲有且只有一次Root明确授权的96秒新seed对照，档案共21次独立生成、主展示20主题；{selection}。旧20制作manifest/音频均原样保留。',
                  f'原72秒调查：低窗{old_energy["low_window_percent"]:.2f}%、最大弱段{old_energy["maximum_internal_low_seconds"]:.2f}s；ALT96秒：{new_energy["low_window_percent"]:.2f}%、{new_energy["maximum_internal_low_seconds"]:.2f}s。数字改善不等于武侠/乐句/接缝耳审。',
                  '[调查原版完整试听](story_investigation_threads_audition.mp3) · [唯一ALT完整试听](../wuxia_expansion_investigation_alt_20261022/story_investigation_threads_audition.mp3) · [20主题实际来源与QA证据](selected20_manifest_20261022.json)']
    lines += ["", "每个MP3均有同名PCM16 WAV。原始IEEE Float32 WAV、decoder统计、prompt/seed/模型SHA/许可和实际完整推理日志保存在 [raw目录](../../../raw/audio/wuxia_expansion_20261022/)。", "",
              "完整试听：固定线性增益，目标RMS −22dBFS、峰值帽 −3dBFS；受峰值限制时如实保留较低RMS，不压缩。首尾各662帧淡变；30秒预览额外末尾2205帧淡出。PCM为×32767后trunc_int16。raw不做gain或裁幅。", "",
              "长循环：固定排除6秒或4秒尾段，在真实区间中按chroma、能量/包络、谱质心与瞬态数值匹配选点；2秒（战斗1秒）互补尾→头交叠，无两头淡到静音。选区/交叠帧/gain和边界保存于每首loop.processing.json，边界试听为循环末5秒＋下一循环首5秒。数值连续不授音乐句法或无缝听审。", "",
              "[完整制作manifest](manifest.json) · [试听索引及80个PCM作者安全检查](listening_index_20261022.json) · [实际速度/退出码](batch_execution_20261022.json)", "",
              "低能量观察采用真实完整试听PCM：40ms窗口/10ms步长、−45dBFS、只统计3秒到固定分析终点，排除原始尾衰减；≥150ms段如实记入索引，不自动当作质量FAIL或触发重试。作者区间到最后低窗的40ms末端；独立QA按10ms步格划段时最大区间通常短30ms（例如本ALT作者1.42s、独立QA1.39s），两者低窗比例一致，不混称完全相同统计。", "",
              "代码MIT与权重Stability Community/Gemma许可分别记录；未声明未来商业资格。CPU XNNPACK固定8步/6线程，无云、下载、付费或GPU推理。旧版本可选NPU/OpenVINO插件日志原样保存，进程退出码与具体告警需分别阅读，不称日志clean。"]
    readme_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    files = sorted(p for p in OUT.rglob("*") if p.is_file() and p != delivery_path)
    raw = ROOT / "assets/raw/audio/wuxia_expansion_20261022"
    files += sorted(p for p in raw.rglob("*") if p.is_file())
    files += [PLAN, ROOT / "scripts/audio/produce_wuxia_expansion_20261022.py", Path(__file__)]
    if alt_comparison:
        files += sorted(p for p in alt_dir.rglob("*") if p.is_file())
        files += sorted(p for p in (ROOT / "assets/raw/audio/wuxia_expansion_investigation_alt_20261022").rglob("*") if p.is_file())
        files += [ROOT / "scripts/audio/wuxia_expansion_investigation_alt_plan_20261022.json", ROOT / "scripts/audio/produce_wuxia_expansion_investigation_alt_20261022.py"]
    delivery = {"status": "AUTHOR_CHECKS_COMPLETE_INDEPENDENT_QA_AND_LISTENING_PENDING", "files": [io.record(p) for p in files],
                "track_count": 20, "raw_unique_sha_count": len({t["raw_outputs"][0]["sha256"] for t in manifest["tracks"]}),
                "game_integration": "NONE", "automatic_model_retries": 0,
                "explicit_independent_alt_count": 1 if alt_comparison else 0,
                "selected_investigation_alt": args.investigation_alt}
    delivery_path.write_text(json.dumps(delivery, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"status": delivery["status"], "tracks": 20, "files": len(files),
                      "delivery_manifest": io.record(delivery_path)}, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    main()
