"""Godot .tres 文件读写模块。

支持解析和生成 Item / Equipment / EnemyDef / Skill / QuestDef / ShopDef
六种资源类型。供 agent_hub Web 编辑器使用。
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# ---------------------------------------------------------------------------
# 资源类型定义
# ---------------------------------------------------------------------------

RESOURCE_TYPES = {
    "Item": {
        "script": "res://scripts/domain/item.gd",
        "script_class": "Item",
        "fields": [
            ("item_id", "StringName"),
            ("display_name", "String"),
            ("description", "String"),
            ("icon_path", "String"),
            ("category", "int"),
            ("stackable", "bool"),
            ("max_stack", "int"),
            ("sell_price", "int"),
            ("buy_price", "int"),
            ("usable_in_battle", "bool"),
            ("usable_in_field", "bool"),
            ("heal_hp", "int"),
            ("heal_mp", "int"),
        ],
    },
    "Equipment": {
        "script": "res://scripts/domain/equipment.gd",
        "script_class": "Equipment",
        "fields": [
            ("item_id", "StringName"),
            ("display_name", "String"),
            ("description", "String"),
            ("icon_path", "String"),
            ("category", "int"),
            ("stackable", "bool"),
            ("max_stack", "int"),
            ("sell_price", "int"),
            ("buy_price", "int"),
            ("usable_in_battle", "bool"),
            ("usable_in_field", "bool"),
            ("heal_hp", "int"),
            ("heal_mp", "int"),
            ("slot", "int"),
            ("quality", "int"),
            ("atk_bonus", "int"),
            ("def_bonus", "int"),
            ("hp_bonus", "int"),
            ("mp_bonus", "int"),
            ("speed_bonus", "int"),
            ("str_bonus", "int"),
            ("agi_bonus", "int"),
            ("inner_bonus", "int"),
            ("insight_bonus", "int"),
            ("vitality_bonus", "int"),
            ("inner_pool_bonus", "int"),
            ("guard_bonus", "int"),
        ],
    },
    "EnemyDef": {
        "script": "res://scripts/domain/enemy_def.gd",
        "script_class": "EnemyDef",
        "fields": [
            ("enemy_id", "StringName"),
            ("display_name", "String"),
            ("portrait_path", "String"),
            ("level", "int"),
            ("max_hp", "int"),
            ("max_mp", "int"),
            ("attack", "int"),
            ("defense", "int"),
            ("speed", "int"),
            ("skill_ids", "Array[StringName]"),
            ("aggression", "float"),
            ("drop_gold_min", "int"),
            ("drop_gold_max", "int"),
            ("drop_exp", "int"),
            ("drop_items", "Array[StringName]"),
            ("drop_random", "Array[Dictionary]"),
        ],
    },
    "Skill": {
        "script": "res://scripts/domain/skill.gd",
        "script_class": "Skill",
        "fields": [
            ("skill_id", "StringName"),
            ("display_name", "String"),
            ("icon_path", "String"),
            ("description", "String"),
            ("kind", "int"),
            ("target", "int"),
            ("mp_cost", "int"),
            ("power", "int"),
            ("hit_count", "int"),
            ("animation_id", "StringName"),
        ],
    },
    "QuestDef": {
        "script": "res://scripts/domain/quest_def.gd",
        "script_class": "QuestDef",
        "fields": [
            ("quest_id", "StringName"),
            ("title", "String"),
            ("kind", "int"),
            ("desc_not_started", "String"),
            ("desc_in_progress", "String"),
            ("desc_completed", "String"),
            ("completion_triggers", "Array[String]"),
            ("reward_gold", "int"),
            ("reward_exp", "int"),
            ("reward_items", "Array[Dictionary]"),
        ],
    },
    "ShopDef": {
        "script": "res://scripts/domain/shop_def.gd",
        "script_class": "ShopDef",
        "fields": [
            ("shop_id", "StringName"),
            ("display_name", "String"),
            ("greeting", "String"),
            ("stock", "Array[StringName]"),
            ("sell_back_ratio", "float"),
        ],
    },
}

# ---------------------------------------------------------------------------
# .tres 解析
# ---------------------------------------------------------------------------

_RE_SECTION = re.compile(r"^\[(.+)\]$")
_RE_KEY_VALUE = re.compile(r'^(\w+)\s*=\s*(.+)$')
_RE_STRINGNAME = re.compile(r'^&"(.+)"$')
_RE_EXT_RESOURCE = re.compile(r'^ExtResource\("(.+)"\)$')


def _parse_godot_value(raw: str, field_type: str) -> Any:
    """将 .tres 中的一行值字符串转为 Python 对象。"""
    raw = raw.strip()

    # Array 必须在 StringName 之前检查
    if field_type.startswith("Array"):
        return _parse_array(raw, field_type)

    # StringName: &"something"
    if "StringName" in field_type:
        m = _RE_STRINGNAME.match(raw)
        if m:
            return m.group(1)
        if raw == '""' or raw == "":
            return ""
        return raw.strip('"')

    # String: "something" or just something
    if field_type == "String":
        if raw.startswith('"') and raw.endswith('"'):
            return raw[1:-1]
        return raw

    # bool
    if field_type == "bool":
        return raw.lower() == "true"

    # int
    if field_type == "int":
        try:
            return int(raw)
        except ValueError:
            return 0

    # float
    if field_type == "float":
        try:
            return float(raw)
        except ValueError:
            return 0.0

    return raw


def _parse_array(raw: str, field_type: str) -> list:
    """解析 Godot Array 字符串。"""
    raw = raw.strip()
    if raw == "[]":
        return []

    inner_type = field_type.replace("Array[", "").rstrip("]")

    # Array[StringName]([&"a", &"b"])
    # Array[String](["a", "b"])
    # Array[Dictionary]([{...}, {...}])

    # 找到 (...) 或 [...] 内的内容
    bracket_start = raw.find("(")
    if bracket_start == -1:
        bracket_start = raw.find("[")
    if bracket_start == -1:
        return []

    inner = raw[bracket_start + 1 : -1]  # 去掉外层括号

    if inner_type == "Dictionary":
        return _parse_dict_array(raw)
    if inner_type == "StringName":
        return _parse_string_array(inner, "StringName")
    if inner_type == "String":
        return _parse_string_array(inner, "String")
    return []


def _parse_string_array(inner: str, field_type: str) -> list:
    """解析 Array[StringName] 或 Array[String] 的内容。"""
    result = []
    # 匹配 &"xxx" 或 "xxx"
    if field_type == "StringName":
        matches = re.findall(r'&"([^"]*)"', inner)
    else:
        matches = re.findall(r'"([^"]*)"', inner)
    return matches


def _parse_dict_array(raw: str) -> list:
    """解析 Array[Dictionary] —— [{key: value, ...}, ...]"""
    result = []
    # 匹配每个 {...} 块
    dict_blocks = re.findall(r'\{([^}]*)\}', raw)
    for block in dict_blocks:
        d = {}
        # 匹配 "key": value 对（value 可以是数字、字符串、bool）
        pairs = re.findall(r'"(\w+)"\s*:\s*([^,}]+)', block)
        for k, v in pairs:
            v = v.strip()
            if v.startswith('"') and v.endswith('"'):
                d[k] = v[1:-1]
            elif v in ("true", "false"):
                d[k] = v == "true"
            else:
                try:
                    d[k] = float(v) if "." in v else int(v)
                except ValueError:
                    d[k] = v
        result.append(d)
    return result


def parse_tres(filepath: Path) -> dict:
    """解析单个 .tres 文件，返回 {'meta': {...}, 'data': {...}}"""
    if not filepath.exists():
        raise FileNotFoundError(f"File not found: {filepath}")

    text = filepath.read_text(encoding="utf-8", errors="replace")
    lines = text.split("\n")

    meta = {"script_class": "", "load_steps": 2}
    ext_resources = {}
    data: dict[str, Any] = {}
    in_resource = False

    for line in lines:
        line = line.rstrip()

        # 跳过空行和注释
        if not line or line.startswith(";"):
            continue

        # 头部: [gd_resource ...]
        m = re.match(r'\[gd_resource.*script_class="(\w+)".*load_steps=(\d+)', line)
        if m:
            meta["script_class"] = m.group(1)
            meta["load_steps"] = int(m.group(2))
            continue

        # ext_resource: [ext_resource type="Script" path="..." id="..."]
        m = re.match(r'\[ext_resource.*path="([^"]+)".*id="([^"]+)"', line)
        if m:
            ext_resources[m.group(2)] = m.group(1)
            continue

        # [resource] 段开始
        if line.strip() == "[resource]":
            in_resource = True
            continue

        # 其他 [...]
        if line.startswith("[") and line.endswith("]"):
            in_resource = False
            continue

        if not in_resource:
            continue

        # key = value
        m = _RE_KEY_VALUE.match(line)
        if m:
            key = m.group(1)
            raw_value = m.group(2).strip()

            # 跳过 script = ExtResource(...)
            if key == "script":
                continue

            data[key] = raw_value

    # 将原始字符串值转换类型
    typed_data = _convert_data_types(data, meta.get("script_class", ""))

    return {"meta": meta, "ext_resources": ext_resources, "data": typed_data, "raw_data": data}


def _convert_data_types(raw_data: dict, script_class: str) -> dict:
    """将原始字符串值按资源类型定义转换为 Python 类型。"""
    type_def = RESOURCE_TYPES.get(script_class)
    if not type_def:
        # 未知类型，保持字符串
        return {k: v for k, v in raw_data.items()}

    fields = {f[0]: f[1] for f in type_def["fields"]}
    result = {}
    for key, raw_value in raw_data.items():
        field_type = fields.get(key, "String")
        result[key] = _parse_godot_value(raw_value, field_type)
    return result


# ---------------------------------------------------------------------------
# .tres 生成
# ---------------------------------------------------------------------------

def _format_godot_value(value: Any, field_type: str) -> str:
    """将 Python 对象转为 .tres 值字符串。"""
    # Array 必须在 StringName 之前检查，因为 Array[StringName] 包含 "StringName"
    if field_type.startswith("Array"):
        return _format_array(value, field_type)

    if "StringName" in field_type:
        if isinstance(value, str) and value:
            return f'&"{value}"'
        return '""'

    if field_type == "String":
        if isinstance(value, str):
            if "\n" in value:
                return f'"{value}"'
            return f'"{value}"'
        return f'"{value}"'

    if field_type == "bool":
        return "true" if value else "false"

    if field_type == "int":
        return str(int(value))

    if field_type == "float":
        return str(float(value))

    return str(value)


def _format_array(value: list, field_type: str) -> str:
    """将 Python list 转为 Godot Array 字符串。"""
    inner_type = field_type.replace("Array[", "").rstrip("]")
    if not value:
        return f"Array[{inner_type}]([])"

    inner_type = field_type.replace("Array[", "").rstrip("]")

    if inner_type == "StringName":
        items = [f'&"{v}"' for v in value]
        return f"Array[StringName]([{', '.join(items)}])"

    if inner_type == "String":
        items = [f'"{v}"' for v in value]
        return f'Array[String]([{', '.join(items)}])'

    if inner_type == "Dictionary":
        dict_items = []
        for d in value:
            pairs = []
            for k, v in d.items():
                if isinstance(v, str):
                    pairs.append(f'"{k}": "{v}"')
                elif isinstance(v, bool):
                    pairs.append(f'"{k}": {str(v).lower()}')
                elif isinstance(v, float):
                    pairs.append(f'"{k}": {v}')
                else:
                    pairs.append(f'"{k}": {v}')
            dict_items.append("{ " + ", ".join(pairs) + " }")
        return f"Array[Dictionary]([{', '.join(dict_items)}])"

    return "[]"


def generate_tres_content(script_class: str, data: dict) -> str:
    """根据资源类型和数据生成 .tres 文件内容。"""
    type_def = RESOURCE_TYPES.get(script_class)
    if not type_def:
        raise ValueError(f"Unknown resource type: {script_class}")

    script_path = type_def["script"]
    fields = type_def["fields"]

    # ext_resource id 保持与原始格式一致
    ext_id_map = {
        "Item": "1_item",
        "Equipment": "1_eq",
        "EnemyDef": "1_enemy",
        "Skill": "1_skill",
        "QuestDef": "1_qdef",
        "ShopDef": "1_shop",
    }
    ext_id = ext_id_map.get(script_class, "1_res")

    load_steps = 2

    lines = [
        f'[gd_resource type="Resource" script_class="{script_class}" load_steps={load_steps} format=3]',
        "",
        f'[ext_resource type="Script" path="{script_path}" id="{ext_id}"]',
        "",
        "[resource]",
        f'script = ExtResource("{ext_id}")',
    ]

    for field_name, field_type in fields:
        if field_name not in data:
            # 使用默认值
            data[field_name] = _default_value(field_type)
        formatted = _format_godot_value(data[field_name], field_type)
        lines.append(f"{field_name} = {formatted}")

    lines.append("")
    return "\n".join(lines)


def _default_value(field_type: str) -> Any:
    """返回字段类型的默认值。"""
    if "StringName" in field_type or field_type == "String":
        return ""
    if field_type == "bool":
        return False
    if field_type == "int":
        return 0
    if field_type == "float":
        return 0.0
    if field_type.startswith("Array"):
        return []
    return ""


# ---------------------------------------------------------------------------
# 数据目录映射
# ---------------------------------------------------------------------------

TYPE_TO_DIR = {
    "Item": "data/items",
    "Equipment": "data/equipment",
    "EnemyDef": "data/enemies",
    "Skill": "data/skills",
    "QuestDef": "data/quests",
    "ShopDef": "data/shops",
}

TYPE_TO_ID_FIELD = {
    "Item": "item_id",
    "Equipment": "item_id",
    "EnemyDef": "enemy_id",
    "Skill": "skill_id",
    "QuestDef": "quest_id",
    "ShopDef": "shop_id",
}

TYPE_LABELS = {
    "Item": "道具",
    "Equipment": "装备",
    "EnemyDef": "敌人",
    "Skill": "技能",
    "QuestDef": "任务",
    "ShopDef": "商店",
}


def list_resources(root: Path, script_class: str) -> list[dict]:
    """列出某类型的所有资源。"""
    subdir = TYPE_TO_DIR.get(script_class, "")
    target_dir = root / "game" / subdir
    if not target_dir.exists():
        return []

    id_field = TYPE_TO_ID_FIELD.get(script_class, "id")
    results = []
    for f in sorted(target_dir.glob("*.tres")):
        try:
            parsed = parse_tres(f)
            results.append({
                "filename": f.name,
                "id": parsed["data"].get(id_field, f.stem),
                "data": parsed["data"],
                "script_class": script_class,
            })
        except Exception:
            continue
    return results


def save_resource(root: Path, script_class: str, data: dict) -> bool:
    """保存资源到对应 .tres 文件。自动选择目录和文件名。"""
    subdir = TYPE_TO_DIR.get(script_class, "")
    target_dir = root / "game" / subdir
    target_dir.mkdir(parents=True, exist_ok=True)

    id_field = TYPE_TO_ID_FIELD.get(script_class, "id")
    resource_id = data.get(id_field, "")
    if not resource_id:
        return False

    filename = f"{resource_id}.tres"
    filepath = target_dir / filename

    content = generate_tres_content(script_class, data)
    filepath.write_text(content, encoding="utf-8")
    return True


def delete_resource(root: Path, script_class: str, resource_id: str) -> bool:
    """删除指定资源文件。"""
    subdir = TYPE_TO_DIR.get(script_class, "")
    filepath = root / "game" / subdir / f"{resource_id}.tres"
    if filepath.exists():
        filepath.unlink()
        return True
    return False
