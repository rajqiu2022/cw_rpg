#!/usr/bin/env python3
"""RPG_GAME 本地数据编辑器 —— 交互式命令行工具。

支持道具/装备/敌人/技能/任务/商店六大类型的浏览和编辑。
直接修改 game/data/ 下的 .tres 文件。

用法: python tools/data_editor.py

依赖: 仅 Python 标准库 (cmd + pathlib)
"""

from __future__ import annotations

import cmd
import os
import sys
import textwrap
from pathlib import Path

# 确保能找到 agent_hub 下的 tres_io 模块
_THIS_DIR = Path(__file__).resolve().parent
_AGENT_HUB = _THIS_DIR / "agent_hub"
if str(_AGENT_HUB) not in sys.path:
    sys.path.insert(0, str(_AGENT_HUB))

from tres_io import (  # noqa: E402
    TYPE_LABELS,
    TYPE_TO_DIR,
    TYPE_TO_ID_FIELD,
    RESOURCE_TYPES,
    delete_resource,
    generate_tres_content,
    list_resources,
    parse_tres,
    save_resource,
)

ROOT = _THIS_DIR.parent.resolve()

# ---------------------------------------------------------------------------
# ANSI 颜色
# ---------------------------------------------------------------------------
C = {
    "reset": "\033[0m",
    "bold": "\033[1m",
    "dim": "\033[2m",
    "red": "\033[91m",
    "green": "\033[92m",
    "yellow": "\033[93m",
    "blue": "\033[94m",
    "cyan": "\033[96m",
    "white": "\033[97m",
}


def _c(text: str, *styles: str) -> str:
    prefix = "".join(C.get(s, "") for s in styles)
    return f"{prefix}{text}{C['reset']}"


# ---------------------------------------------------------------------------
# 别名映射
# ---------------------------------------------------------------------------
_TYPE_ALIASES = {
    "item": "Item", "items": "Item", "道具": "Item",
    "equipment": "Equipment", "equip": "Equipment", "装备": "Equipment",
    "enemy": "EnemyDef", "enemies": "EnemyDef", "敌人": "EnemyDef",
    "skill": "Skill", "skills": "Skill", "技能": "Skill",
    "quest": "QuestDef", "quests": "QuestDef", "任务": "QuestDef",
    "shop": "ShopDef", "shops": "ShopDef", "商店": "ShopDef",
}


def _resolve_type(name: str) -> str:
    return _TYPE_ALIASES.get(name.lower(), name)


# ---------------------------------------------------------------------------
# 交互式 Shell
# ---------------------------------------------------------------------------
class DataEditorShell(cmd.Cmd):
    intro = _c("""
+==============================================+
|      RPG_GAME 本地数据编辑器 v1.0           |
|  道具 · 装备 · 敌人 · 技能 · 任务 · 商店    |
+==============================================+
输入 help 查看命令，quit 退出
""", "cyan")
    prompt = _c("data> ", "green")

    def __init__(self):
        super().__init__()
        self._dirty: set[tuple[str, str]] = set()  # (script_class, resource_id)

    # ---- 列表 ----
    def do_list(self, arg: str) -> None:
        """list <类型>  —  列出所有资源。类型: items/equipment/enemies/skills/quests/shops"""
        cls = _resolve_type(arg.strip())
        if cls not in RESOURCE_TYPES:
            self._print_types()
            return

        resources = list_resources(ROOT, cls)
        type_label = TYPE_LABELS.get(cls, cls)
        id_field = TYPE_TO_ID_FIELD.get(cls, "id")
        fields = RESOURCE_TYPES[cls]["fields"]

        if not resources:
            print(_c(f"\n  暂无{type_label}数据。\n", "dim"))
            return

        print(_c(f"\n  [{type_label}] 共 {len(resources)} 条\n", "bold"))

        # 关键展示字段
        key_fields = self._key_display_fields(cls)

        # 表头
        header = f"  {'ID':<30} {'名称':<16}"
        for kf in key_fields:
            header += f" {kf:<10}"
        print(_c(header, "yellow"))
        print(_c("  " + "-" * (len(header) - 2), "dim"))

        for res in resources:
            rid = str(res["id"])[:28]
            name = str(res["data"].get("display_name", res["data"].get("title", "-")))[:14]
            line = f"  {rid:<30} {name:<16}"
            for kf in key_fields:
                val = res["data"].get(kf, "-")
                if isinstance(val, float):
                    val = f"{val:.1f}"
                elif isinstance(val, list):
                    val = str(len(val))
                line += f" {str(val):<10}"
            print(line)
        print()

    def _key_display_fields(self, cls: str) -> list[str]:
        """不同类型展示的关键列。"""
        mapping = {
            "Item": ["heal_hp", "heal_mp", "buy_price"],
            "Equipment": ["slot", "atk_bonus", "def_bonus"],
            "EnemyDef": ["level", "max_hp", "attack", "defense"],
            "Skill": ["kind", "mp_cost", "power"],
            "QuestDef": ["kind", "reward_gold", "reward_exp"],
            "ShopDef": ["sell_back_ratio", "stock"],
        }
        return mapping.get(cls, [])

    # ---- 查看详情 ----
    def do_view(self, arg: str) -> None:
        """view <类型> <ID>  —  查看资源全部字段"""
        parts = arg.strip().split(maxsplit=1)
        if len(parts) < 2:
            print(_c("用法: view <类型> <ID>", "red"))
            return
        cls = _resolve_type(parts[0])
        rid = parts[1]
        if cls not in RESOURCE_TYPES:
            self._print_types()
            return

        parsed = self._load_one(cls, rid)
        if parsed is None:
            return

        fields = RESOURCE_TYPES[cls]["fields"]
        print(_c(f"\n  [{TYPE_LABELS.get(cls, cls)}] {rid}", "bold"))
        print(_c("  " + "-" * 60, "dim"))

        for fname, ftype in fields:
            val = parsed["data"].get(fname, "-")
            if isinstance(val, list):
                val = ", ".join(str(v) for v in val) if val else "(空)"
            elif isinstance(val, bool):
                val = "true" if val else "false"
            print(f"  {fname:<24} {_c(str(val)[:55], 'cyan')}   ({ftype})")
        print()

    # ---- 编辑 ----
    def do_edit(self, arg: str) -> None:
        """edit <类型> <ID> <字段> <值>  —  修改单个字段"""
        parts = arg.strip().split(maxsplit=3)
        if len(parts) < 4:
            print(_c("用法: edit <类型> <ID> <字段> <值>", "red"))
            print(_c("提示: 先用 view 查看字段名，或用 fields <类型> 列出字段", "dim"))
            return
        cls = _resolve_type(parts[0])
        rid = parts[1]
        field = parts[2]
        value = parts[3]

        if cls not in RESOURCE_TYPES:
            self._print_types()
            return

        parsed = self._load_one(cls, rid)
        if parsed is None:
            return

        # 查找字段类型
        fields_dict = {f[0]: f[1] for f in RESOURCE_TYPES[cls]["fields"]}
        if field not in fields_dict:
            print(_c(f"未知字段 '{field}'。可用字段: {', '.join(fields_dict.keys())}", "red"))
            return

        ftype = fields_dict[field]

        # 转换值
        try:
            if ftype == "bool":
                typed_val = value.lower() in ("true", "1", "yes", "on")
            elif ftype == "int":
                typed_val = int(value)
            elif ftype == "float":
                typed_val = float(value)
            elif ftype.startswith("Array"):
                typed_val = [v.strip() for v in value.split(",") if v.strip()]
            else:
                typed_val = value
        except (ValueError, TypeError) as e:
            print(_c(f"值转换失败 ({ftype}): {e}", "red"))
            return

        # 更新内存中的数据
        parsed["data"][field] = typed_val
        ok = save_resource(ROOT, cls, parsed["data"])
        if ok:
            self._dirty.discard((cls, rid))
            print(_c(f"  {rid}.{field} = {typed_val}  [OK] 已保存到 .tres", "green"))
        else:
            print(_c("保存失败", "red"))

    # ---- 新建 ----
    def do_new(self, arg: str) -> None:
        """new <类型> <ID>  —  创建新资源（使用默认值）"""
        parts = arg.strip().split(maxsplit=1)
        if len(parts) < 2:
            print(_c("用法: new <类型> <ID>", "red"))
            return
        cls = _resolve_type(parts[0])
        rid = parts[1]

        if cls not in RESOURCE_TYPES:
            self._print_types()
            return

        # 检查是否已存在
        subdir = TYPE_TO_DIR.get(cls, "")
        filepath = ROOT / "game" / subdir / f"{rid}.tres"
        if filepath.exists():
            print(_c(f"  {rid}.tres 已存在！用 view {parts[0]} {rid} 查看", "red"))
            return

        # 构建默认数据
        id_field = TYPE_TO_ID_FIELD.get(cls, "id")
        data = {id_field: rid}
        # 设置 display_name 为 ID
        if cls in ("Item", "Equipment"):
            data["display_name"] = rid
        elif cls == "EnemyDef":
            data["display_name"] = rid
        elif cls == "QuestDef":
            data["title"] = rid
        elif cls == "ShopDef":
            data["display_name"] = rid

        ok = save_resource(ROOT, cls, data)
        if ok:
            print(_c(f"  已创建 {TYPE_LABELS.get(cls, cls)}: {rid}", "green"))
            print(_c(f"  文件: game/{subdir}/{rid}.tres", "dim"))
            print(_c("  用 edit 命令逐步设置字段值", "dim"))
        else:
            print(_c("创建失败", "red"))

    # ---- 删除 ----
    def do_delete(self, arg: str) -> None:
        """delete <类型> <ID>  —  删除资源文件"""
        parts = arg.strip().split(maxsplit=1)
        if len(parts) < 2:
            print(_c("用法: delete <类型> <ID>", "red"))
            return
        cls = _resolve_type(parts[0])
        rid = parts[1]

        if cls not in RESOURCE_TYPES:
            self._print_types()
            return

        subdir = TYPE_TO_DIR.get(cls, "")
        filepath = ROOT / "game" / subdir / f"{rid}.tres"
        if not filepath.exists():
            print(_c(f"  {rid}.tres 不存在", "red"))
            return

        confirm = input(_c(f"  确认删除 {subdir}/{rid}.tres? [y/N] ", "yellow"))
        if confirm.lower() != "y":
            print(_c("  已取消", "dim"))
            return

        ok = delete_resource(ROOT, cls, rid)
        if ok:
            print(_c(f"  已删除 {rid}", "green"))
        else:
            print(_c("删除失败", "red"))

    # ---- 字段列表 ----
    def do_fields(self, arg: str) -> None:
        """fields <类型>  —  列出某类型所有可编辑字段"""
        cls = _resolve_type(arg.strip())
        if cls not in RESOURCE_TYPES:
            self._print_types()
            return
        fields = RESOURCE_TYPES[cls]["fields"]
        print(_c(f"\n  [{TYPE_LABELS.get(cls, cls)}] 字段列表", "bold"))
        print(_c("  " + "-" * 50, "dim"))
        for fname, ftype in fields:
            mark = " *" if fname == TYPE_TO_ID_FIELD.get(cls, "id") else ""
            print(f"  {fname:<24} {ftype:<20}{mark}")
        print(_c("  * = ID 字段（创建后不可修改）", "dim"))
        print()

    # ---- 批量预览生成内容 ----
    def do_preview(self, arg: str) -> None:
        """preview <类型> <ID>  —  预览 .tres 文件内容"""
        parts = arg.strip().split(maxsplit=1)
        if len(parts) < 2:
            print(_c("用法: preview <类型> <ID>", "red"))
            return
        cls = _resolve_type(parts[0])
        rid = parts[1]

        parsed = self._load_one(cls, rid)
        if parsed is None:
            return

        content = generate_tres_content(cls, parsed["data"])
        print(_c(f"\n  --- {rid}.tres ---", "dim"))
        for line in content.split("\n"):
            print(f"  {line}")
        print(_c("  --- EOF ---\n", "dim"))

    # ---- 类型列表 ----
    def do_types(self, arg: str) -> None:
        """types  —  列出可编辑的数据类型"""
        self._print_types()

    # ---- 帮助 ----
    def do_help(self, arg: str) -> None:
        """help [命令]  —  显示帮助"""
        if arg:
            super().do_help(arg)
            return
        print(_c("""
  命令:
    list    <类型>                    列出所有资源
    view    <类型> <ID>               查看资源详情
    edit    <类型> <ID> <字段> <值>   修改字段
    new     <类型> <ID>               创建新资源
    delete  <类型> <ID>               删除资源
    fields  <类型>                    列出可编辑字段
    preview <类型> <ID>               预览 .tres 文件内容
    types                             列出所有数据类型

  类型别名: items/道具 → Item, enemies/敌人 → EnemyDef, skills/技能 → Skill, ...

  示例:
    list items              # 列出所有道具
    view items linxi_jiu    # 查看林西酒详情
    edit items linxi_jiu heal_hp 0     # 修改林西酒的 heal_hp 为 0
    new items my_new_pill   # 创建新道具 my_new_pill
    fields enemies          # 查看敌人有哪些字段
    quit                    # 退出
""", "cyan"))

    def do_quit(self, arg: str) -> bool:
        """quit  —  退出编辑器"""
        print(_c("  再见。", "dim"))
        return True

    def do_exit(self, arg: str) -> bool:
        return self.do_quit(arg)

    def do_EOF(self, arg: str) -> bool:
        print()
        return True

    def emptyline(self) -> None:
        pass

    # ---- 内部方法 ----
    def _print_types(self) -> None:
        print(_c("\n  可用类型:", "bold"))
        for cls, label in TYPE_LABELS.items():
            alias = [k for k, v in _TYPE_ALIASES.items() if v == cls and k != cls]
            alias_str = f" ({', '.join(alias[:3])})" if alias else ""
            count = len(list_resources(ROOT, cls))
            print(f"    {cls:<12} {label:<6} {count} 条{alias_str}")
        print()

    def _load_one(self, cls: str, rid: str) -> dict | None:
        subdir = TYPE_TO_DIR.get(cls, "")
        filepath = ROOT / "game" / subdir / f"{rid}.tres"
        if not filepath.exists():
            print(_c(f"  文件不存在: game/{subdir}/{rid}.tres", "red"))
            return None
        try:
            return parse_tres(filepath)
        except Exception as e:
            print(_c(f"  解析失败: {e}", "red"))
            return None


# ---------------------------------------------------------------------------
# 入口
# ---------------------------------------------------------------------------
def main() -> None:
    os.chdir(ROOT)
    try:
        DataEditorShell().cmdloop()
    except KeyboardInterrupt:
        print(_c("\n  已中断。", "dim"))


if __name__ == "__main__":
    main()
