"""Offline audio inventory and honest fresh guard; never starts an engine/API."""
from __future__ import annotations
import argparse
import ctypes
from ctypes import wintypes
import hashlib
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/processed/audio/wuxia_expansion_qa_20261022'
AUDIO_EXTS = {'.wav', '.mp3', '.ogg', '.flac', '.aac', '.m4a'}
SOURCES = [
    'game/project.godot', 'game/scripts/audio/music_catalog.gd',
    'game/scripts/autoload/audio_manager.gd', 'game/scripts/autoload/dialog_player.gd',
    'game/scripts/battle/battle_controller.gd', 'game/scripts/battle/battle_actor.gd',
    'game/scripts/battle/battle_combatant.gd', 'game/scripts/domain/skill.gd',
    'game/scripts/domain/dialog_script.gd', 'game/scripts/domain/dialog_node.gd',
    'game/scripts/domain/enemy_def.gd', 'game/scripts/domain/equipment.gd',
    'scripts/gen_dialog_voices.py',
]

def sha(path: Path) -> str:
    with path.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()

class FileAttributeData(ctypes.Structure):
    _fields_ = [('attributes', wintypes.DWORD), ('creation', wintypes.FILETIME),
                ('access', wintypes.FILETIME), ('write', wintypes.FILETIME),
                ('size_high', wintypes.DWORD), ('size_low', wintypes.DWORD)]

def windows_ticks(path: Path) -> str:
    data = FileAttributeData()
    api = ctypes.windll.kernel32.GetFileAttributesExW
    api.argtypes = (wintypes.LPCWSTR, ctypes.c_int, ctypes.c_void_p)
    api.restype = wintypes.BOOL
    if not api(str(path.resolve()), 0, ctypes.byref(data)):
        raise ctypes.WinError()
    # Win32 FILETIME starts in1601; use .NET UTC ticks (year1), matching the
    # project's PowerShell LastWriteTimeUtc.Ticks convention, without rounding.
    native = (data.write.dwHighDateTime << 32) | data.write.dwLowDateTime
    return str(native + 504911232000000000)

def record(path: Path) -> dict:
    r = {'path': str(path.resolve()), 'exists': path.is_file()}
    if r['exists']:
        a = path.stat()
        r.update(bytes=a.st_size, mtime_ns=str(a.st_mtime_ns), sha256=sha(path), mtime_utc_ticks=windows_ticks(path))
        b = path.stat()
        assert (a.st_size, a.st_mtime_ns) == (b.st_size, b.st_mtime_ns), f'Concurrent change while reading {path}'
        assert int(r['mtime_utc_ticks']) == a.st_mtime_ns // 100 + 621355968000000000, path
    return r

def save(name: str, obj: dict) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    assert path.resolve().is_relative_to(OUT) and path.suffix == '.json' and not path.exists(), path
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def field(text: str, key: str, default: str = '') -> str:
    match = re.search(r'^' + re.escape(key) + r'\s*=\s*&?"((?:\\.|[^"\\])*)"', text, re.M)
    return match.group(1).replace('\\"', '"').replace('\\n', '\n').replace('\\\\', '\\') if match else default

def snapshot() -> dict:
    start = datetime.now(timezone.utc).isoformat()
    # Use the established exact fifteen locations, but read ALL values freshly.
    old = json.loads((ROOT / 'assets/processed/audio/wuxia_audio_install_qa_20261011/before.json').read_text(encoding='utf-8'))
    audio = sorted(p for p in (ROOT / 'game/art/audio').rglob('*') if p.is_file())
    data = sorted(p for folder in ('dialogs', 'skills', 'enemies', 'equipment') for p in (ROOT / 'game/data' / folder).glob('*.tres'))
    projection = []
    for p in sorted((ROOT / 'game/data/scenes').glob('*.tres')):
        t = p.read_text(encoding='utf-8-sig')
        projection.append({'path': str(p.relative_to(ROOT)), 'scene_id': field(t, 'scene_id', p.stem), 'bgm_path': field(t, 'bgm_path')})
    r = {'scope': 'FRESH_AUDIO_AND_DIALOG_SKILL_SOURCE_ONLY_NOT_CITY_GUARD', 'started_utc': start,
         'audio_files': [record(p) for p in audio], 'audio_sources': [record(ROOT / p) for p in SOURCES],
         'skill_dialog_enemy_equipment_data': [record(p) for p in data],
         'player_files': [record(Path(p['path'])) for p in old['player_files']],
         'scene_audio_projection_only': projection,
         'concurrent_processes_not_controlled': [99472, 51856, 100140],
         'no_engine_import_game_write': True,
         'concurrency_condition': 'NEW staging only. Formal source/data/import writes require AP target coordination and fresh before; this is observed baseline, not retroactive authorization.'}
    r['finished_utc'] = datetime.now(timezone.utc).isoformat()
    save('before.json', r)
    return r

def gd_map(text: str, name: str) -> dict:
    m = re.search(r'const ' + name + r'\s*:?=\s*\{(.*?)\n\}', text, re.S)
    return dict(re.findall(r'&?"([^"\n]+)"\s*:\s*&?"([^"\n]+)"', m.group(1))) if m else {}

def flags(text: str, name: str) -> bool:
    return bool(re.search(r'^' + name + r'\s*=\s*true\b', text, re.M))

def segments(text: str, speaker: str) -> list[str]:
    if speaker == '旁白': return ['narr']
    kinds, cursor = [], 0
    while cursor < len(text):
        starts = [i for i in (text.find('（', cursor), text.find('(', cursor)) if i >= 0]
        if not starts:
            if text[cursor:].strip(): kinds.append('dialog')
            break
        start = min(starts)
        if text[cursor:start].strip(): kinds.append('dialog')
        ends = [i for i in (text.find('）', start + 1), text.find(')', start + 1)) if i >= 0]
        if not ends: kinds.append('dialog'); break
        kinds.append('narr'); cursor = min(ends) + 1
    return kinds

def inventory(report_name: str = 'inventory_retry1.json') -> dict:
    before = json.loads((OUT / 'before.json').read_text(encoding='utf-8'))
    observed = {Path(r['path']).resolve(): r for r in before['audio_files']}
    game_audio = sorted(p for p in observed if p.suffix.lower() in AUDIO_EXTS)
    hashes = defaultdict(list)
    for p in game_audio: hashes[observed[p]['sha256']].append(str(p.relative_to(ROOT)))
    am = (ROOT / SOURCES[2]).read_text(encoding='utf-8-sig')
    constants = dict(re.findall(r'^const (\w+)\s*:?=\s*"([^"\n]+)"', am, re.M))
    catalog = (ROOT / SOURCES[1]).read_text(encoding='utf-8-sig')
    maps = {name: gd_map(catalog, name) for name in ('SCENE_TRACKS', 'LEGACY_EXPLORATION_TRACKS', 'DIALOG_TRACKS', 'DIALOG_NODE_TRACKS')}
    linxi = re.search(r'const LINXI_DAY_SCENES := \[(.*?)\n\]', catalog, re.S)
    linxi_ids = set(re.findall(r'&"([^"]+)"', linxi.group(1)))
    base = constants.get('DEFAULT_FIELD_BGM')
    newdir = field(catalog, 'DIRECTORY') or 'res://art/audio/bgm/wuxia_20261011/'
    def exists(resource: str) -> bool: return bool(resource) and (ROOT / 'game' / resource.removeprefix('res://')).is_file()
    scenes = []
    for row in before['scene_audio_projection_only']:
        sid, old = row['scene_id'], row['bgm_path']
        track = maps['SCENE_TRACKS'].get(sid)
        resolved = newdir + track + '.wav' if track else constants.get('DEFAULT_FIELD_BGM') if sid in linxi_ids else newdir + maps['LEGACY_EXPLORATION_TRACKS'][old] + '.wav' if old in maps['LEGACY_EXPLORATION_TRACKS'] else old
        if not exists(resolved): resolved = base
        scenes.append(dict(**row, resolved=resolved, exists=exists(resolved), explicit_scene_override=bool(track)))
    # Current runtime emotion rules, not generator's broader keyword table.
    dp = (ROOT / SOURCES[3]).read_text(encoding='utf-8-sig')
    detect = dp.split('func _detect_emotion(', 1)[1].split('\nfunc ', 1)[0]
    emotion_rules = [(re.findall(r'text.contains\("([^"]+)"\)', x), y) for x, y in re.findall(r'\n\tif (.*?):\n\t\treturn "([^"]+)"', detect)]
    nodes, referenced_voice = [], set()
    dialog_files = sorted((ROOT / 'game/data/dialogs').rglob('*.tres'))
    for p in dialog_files:
        text = p.read_text(encoding='utf-8-sig'); footer = text.rsplit('[resource]', 1)[-1]
        did = field(footer, 'dialog_id', p.stem)
        node_list = re.search(r'^nodes\s*=\s*(.*)', footer, re.M)
        ids = set(re.findall(r'SubResource\("([^"]+)"\)', node_list.group(1))) if node_list else set()
        for header, block in re.findall(r'(\[sub_resource[^\]]*\])(.*?)(?=\n\[sub_resource|\n\[resource\])', text, re.S):
            rid = re.search(r'\bid="([^"]+)"', header)
            if ids and rid and rid.group(1) not in ids: continue
            nid = field(block, 'node_id')
            if not nid: continue
            spoken = field(block, 'text'); speaker = field(block, 'speaker')
            explicit = field(block, 'voice_emotion', 'auto')
            emotion = explicit if explicit not in ('', 'auto') else next((e for keywords, e in emotion_rules if any(k in spoken for k in keywords)), 'normal')
            who = speaker or '旁白'; safe = who.replace('/', '_').replace('\\', '_')
            root = ROOT / 'game/art/audio/voices' / did[:3] / did
            prefix = f'{safe}_{nid}'
            kinds = segments(spoken, who)
            expected_seg = [root / f'{prefix}_seg{i+1:02d}_{kind}.mp3' for i, kind in enumerate(kinds)]
            emotion_path, legacy_path, narr_path = root / f'{prefix}_e{emotion}.mp3', root / f'{prefix}.mp3', root / f'{prefix}_narr.mp3'
            selected = []
            if expected_seg and expected_seg[0].is_file():
                selected = [x for x in expected_seg if x.is_file()]
                state = 'complete_segments' if len(selected) == len(expected_seg) else 'partial_segments_fallback_suppressed'
            else:
                voice = emotion_path if emotion_path.is_file() else legacy_path if legacy_path.is_file() else None
                if voice: selected.append(voice)
                inline = bool(re.search(r'[（(].*?[）)]', spoken, re.S)) and who != '旁白'
                if inline and narr_path.is_file(): selected.append(narr_path)
                state = 'complete_legacy' if voice and (not inline or narr_path.is_file()) else 'partial_legacy_narration_missing' if voice else 'narration_only' if selected else 'missing'
            referenced_voice.update(x.resolve() for x in selected)
            prefix_candidates = [x for x in root.glob('*.mp3') if x.stem == prefix or x.stem.startswith(prefix + '_')]
            nodes.append({'file': str(p.relative_to(ROOT)), 'dialog_id': did, 'node_id': nid, 'speaker': speaker, 'text': spoken, 'runtime_emotion': emotion, 'speaker_context_dependent': not bool(speaker), 'has_speech_text': bool(spoken.strip()), 'resolution_without_default_speaker': state, 'selected_disk_files': [str(x.relative_to(ROOT)) for x in selected], 'expected_primary': str(emotion_path.relative_to(ROOT)), 'expected_segments': [str(x.relative_to(ROOT)) for x in expected_seg], 'other_prefix_files_not_selected': [str(x.relative_to(ROOT)) for x in prefix_candidates if x not in selected], 'missing_segments_when_segment_branch_active': [str(x.relative_to(ROOT)) for x in expected_seg if not x.is_file()] if state.startswith(('complete_segments', 'partial_segments')) else []})
    skill_rows = []
    for p in sorted((ROOT / 'game/data/skills').glob('*.tres')):
        t = p.read_text(encoding='utf-8-sig'); weapon = field(t, 'required_weapon_type')
        cast, impact = field(t, 'cast_sfx_path'), field(t, 'impact_sfx_path')
        cast_fallback = constants.get({'sword':'SWORD_ATTACK_SFX', 'blade':'BLADE_ATTACK_SFX', 'staff':'STAFF_ATTACK_SFX'}.get(weapon, 'PALM_ATTACK_SFX'))
        impact_fallback = constants.get('METAL_HIT_SFX' if weapon in ('sword', 'blade') else 'DEFAULT_HIT_SFX')
        skill_rows.append({'file':str(p.relative_to(ROOT)), 'id':field(t,'skill_id',p.stem),'name':field(t,'display_name'), 'weapon':weapon,'martial_category':field(t,'martial_category'), 'passive':flags(t,'is_passive'), 'internal_art':flags(t,'is_internal_art'), 'cast_explicit':cast,'impact_explicit':impact,'cast_resolved':cast or cast_fallback,'impact_resolved':impact or impact_fallback,'cast_exists':exists(cast or cast_fallback),'impact_exists':exists(impact or impact_fallback)})
    enemy_rows = []
    for p in sorted((ROOT / 'game/data/enemies').glob('*.tres')):
        t = p.read_text(encoding='utf-8-sig')
        enemy_rows.append({'file':str(p.relative_to(ROOT)),'id':field(t,'enemy_id',p.stem), 'cues':{k:field(t,k+'_sfx_path') for k in ('ready','attack','hit','defeat')}})
    explicit_nodes = [n for n in nodes if n['speaker'] and n['has_speech_text']]
    all_voice = {p for p in game_audio if 'voices' in p.parts}
    summary = {'game_playable_files':len(game_audio),'game_audio_by_directory':dict(Counter(p.relative_to(ROOT/'game/art/audio').parts[0] for p in game_audio)), 'unique_encoded_file_hashes':len(hashes),'same_byte_hash_groups':sum(len(ps)>1 for ps in hashes.values()), 'scene_resources':len(scenes),'unique_resolved_scene_bgm_paths':len({r['resolved'] for r in scenes}), 'dialog_files':len(dialog_files),'parsed_nodes':len(nodes),'nodes_with_text':sum(n['has_speech_text'] for n in nodes),'explicit_speaker_text_nodes':len(explicit_nodes),'explicit_speaker_resolution':dict(Counter(n['resolution_without_default_speaker'] for n in explicit_nodes)),'context_dependent_empty_speaker_nodes':sum(not n['speaker'] for n in nodes), 'explicit_missing_with_other_prefix_files':sum(n['resolution_without_default_speaker']=='missing' and bool(n['other_prefix_files_not_selected']) for n in explicit_nodes),'existing_voice_files':len(all_voice),'statically_selected_voice_files':len(referenced_voice),'voice_files_not_selected_by_static_nodes':len(all_voice-referenced_voice),'skills':len(skill_rows),'nonpassive_skills':sum(not r['passive'] for r in skill_rows),'skill_explicit_cast':sum(bool(r['cast_explicit']) for r in skill_rows),'skill_explicit_impact':sum(bool(r['impact_explicit']) for r in skill_rows),'skill_resolved_cast_paths':len({r['cast_resolved'] for r in skill_rows}),'skill_resolved_impact_paths':len({r['impact_resolved'] for r in skill_rows}), 'enemy_defs':len(enemy_rows)}
    result = {'scope':'OFFLINE_CURRENT_FILES_AND_SOURCE_RESOLUTION_NOT_RUNTIME_OR_SOUNDSTYLE_APPROVAL','before_sha256':sha(OUT/'before.json'),'summary':summary,'scenes':scenes,'dialog_nodes':nodes,'skills':skill_rows,'enemies':enemy_rows,'game_audio_records':[observed[p] for p in game_audio],'byte_duplicate_groups':[ps for ps in hashes.values() if len(ps)>1],'voice_files_not_statically_selected':[str(p.relative_to(ROOT)) for p in sorted(all_voice-referenced_voice)],'limitations':['File/hash counts do not establish distinct timbres or melodies.','Empty speaker nodes may use Field-provided default speaker; this disk audit cannot resolve every context.','Generated runtime DialogScript/DialogNode content in Field/city helpers is outside authored TRES node totals.','A resource in the production data tree is not proof of current story reachability.','No engine/import/playback/model/network; imported availability not revalidated.']}
    save(report_name, result)
    return result

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['snapshot', 'inventory'])
    args = parser.parse_args()
    r = snapshot() if args.mode == 'snapshot' else inventory()
    print(json.dumps({'mode': args.mode, 'summary':r.get('summary'), 'report_sha256':sha(OUT / ('before.json' if args.mode == 'snapshot' else 'inventory_retry1.json'))}, ensure_ascii=False))

if __name__ == '__main__':
    main()
