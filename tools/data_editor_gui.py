#!/usr/bin/env python3
"""RPG_GAME 本地数据编辑器 — 桌面 GUI 工具。

基于 tkinter + ttkbootstrap，直接编辑 game/data/ 下的 .tres 文件。
支持: 道具 / 装备 / 敌人 / 技能 / 任务 / 商店 六大类型。

用法: python tools/data_editor_gui.py
打包: pyinstaller --onefile --windowed --name RPG数据编辑器 tools/data_editor_gui.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path
from tkinter import messagebox, StringVar

# 路径解析：向上搜索直到找到包含 game/data/ 的项目根目录
def _find_project_root(start_dir: Path) -> Path:
    """从 start_dir 向上逐级查找，返回包含 game/data/ 的目录。"""
    d = start_dir.resolve()
    for _ in range(6):
        if (d / "game" / "data" / "items").exists():
            return d
        parent = d.parent
        if parent == d:
            break
        d = parent
    # 回退：假设 EXE 在项目根下的 tools/ 子目录中
    return start_dir.resolve().parent.parent

_SCRIPT_DIR = Path(sys.executable).resolve().parent if getattr(sys, "frozen", False) else Path(__file__).resolve().parent
ROOT = _find_project_root(_SCRIPT_DIR)

# tres_io 模块路径
_AGENT_HUB = ROOT / "tools" / "agent_hub"
if not _AGENT_HUB.exists() and getattr(sys, "_MEIPASS", ""):
    _AGENT_HUB = Path(sys._MEIPASS) / "agent_hub"
if str(_AGENT_HUB) not in sys.path:
    sys.path.insert(0, str(_AGENT_HUB))

os.chdir(str(ROOT))

import ttkbootstrap as ttk
from ttkbootstrap.constants import *

from tres_io import (
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

# ── 类型配置 ──────────────────────────────────────────────
ALL_TYPES = ["Item", "Equipment", "EnemyDef", "Skill", "QuestDef", "ShopDef"]

# 表格中显示的列（每种类型不同）
LIST_COLUMNS = {
    "Item":         ("display_name", "icon_path", "quality", "heal_hp", "heal_mp", "buy_price", "sell_price"),
    "Equipment":    ("display_name", "icon_path", "quality", "slot", "atk_bonus", "def_bonus"),
    "EnemyDef":     ("display_name", "portrait_path", "level", "max_hp", "attack", "defense"),
    "Skill":        ("display_name", "icon_path", "kind", "mp_cost", "power"),
    "QuestDef":     ("title", "kind", "reward_gold", "reward_exp"),
    "ShopDef":      ("display_name", "sell_back_ratio", "stock"),
}

# 列标题中文
COL_HEADERS = {
    "display_name": "名称", "title": "名称", "icon_path": "图标", "portrait_path": "立绘", "quality": "品质",
    "heal_hp": "回复HP", "heal_mp": "回复MP", "buy_price": "买价", "sell_price": "卖价",
    "slot": "槽位", "atk_bonus": "攻击", "def_bonus": "防御", "speed_bonus": "速度",
    "level": "等级", "max_hp": "HP", "attack": "攻击", "defense": "防御",
    "kind": "类型", "mp_cost": "MP消耗", "power": "威力",
    "reward_gold": "金币", "reward_exp": "经验",
    "sell_back_ratio": "回购率", "stock": "在售数",
}

# 全部字段中文名映射
FIELD_CN = {
    "item_id": "道具ID", "enemy_id": "敌人ID", "skill_id": "技能ID",
    "quest_id": "任务ID", "shop_id": "商店ID",
    "display_name": "名称", "title": "名称", "icon_path": "图标", "portrait_path": "立绘", "quality": "品质",
    "description": "描述", "icon_path": "图标路径",
    "portrait_path": "立绘路径",
    "category": "类别", "stackable": "可堆叠", "max_stack": "最大堆叠",
    "sell_price": "卖价", "buy_price": "买价",
    "usable_in_battle": "战斗可用", "usable_in_field": "场景可用",
    "heal_hp": "回复HP", "heal_mp": "回复MP",
    "quality": "品质", "slot": "装备槽位",
    "atk_bonus": "攻击加成", "def_bonus": "防御加成",
    "hp_bonus": "生命加成", "mp_bonus": "内力加成", "speed_bonus": "速度加成",
    "str_bonus": "筋骨加成", "agi_bonus": "机敏加成",
    "inner_bonus": "内劲加成", "insight_bonus": "悟性加成",
    "vitality_bonus": "生命属性加成", "inner_pool_bonus": "内力属性加成", "guard_bonus": "防御属性加成",
    "level": "等级", "max_hp": "最大HP", "max_mp": "最大MP",
    "attack": "攻击", "defense": "防御", "speed": "速度",
    "skill_ids": "技能列表", "aggression": "激进度",
    "drop_gold_min": "金币下限", "drop_gold_max": "金币上限",
    "drop_exp": "经验", "drop_items": "必掉物品", "drop_random": "概率掉落",
    "kind": "类型", "target": "目标",
    "mp_cost": "MP消耗", "power": "威力", "hit_count": "攻击段数",
    "animation_id": "动画ID",
    "desc_not_started": "未接受描述", "desc_in_progress": "进行中描述", "desc_completed": "已完成描述",
    "completion_triggers": "完成条件",
    "reward_gold": "金币奖励", "reward_exp": "经验奖励", "reward_items": "物品奖励",
    "greeting": "欢迎语", "stock": "在售物品", "sell_back_ratio": "回购率",
}

SLOT_NAMES = ["武器", "头盔", "衣甲", "手套", "鞋子", "饰品"]
QUALITY_NAMES = ["凡品", "优质", "高品", "稀有", "尚品"]
QUALITY_COLORS = ["#cccccc", "#44cc44", "#4488ff", "#cc44ff", "#ff8822"]
KIND_NAMES_QUEST = ["主线", "支线"]
KIND_NAMES_SKILL = ["攻击", "治疗", "增益", "减益"]


def _fmt(val) -> str:
    """格式化表格显示值。"""
    if val is None: return "-"
    if isinstance(val, float): return f"{val:.2f}"
    if isinstance(val, bool): return "是" if val else "否"
    if isinstance(val, list): return str(len(val)) if val else "0"
    return str(val)


class DataEditorApp:
    """主应用窗口。"""

    def __init__(self):
        self.root = ttk.Window(themename="darkly")
        self.root.title("RPG 数据编辑器 — 冷孤云 · 江湖行")
        self.root.geometry("1280x800")
        self.root.minsize(960, 600)

        # 数据缓存（懒加载：首次切到某标签时才加载）
        self._cache: dict[str, list[dict]] = {}
        self._current: dict[str, dict | None] = {}
        self._loaded: set = set()
        self._current_type: str = ""

        self._build_ui()
        # 启动时只构建 UI，不加载数据 —— 点击标签才加载
        self._status_var.set("就绪 — 点击上方标签加载数据")

        self.root.mainloop()

    # ── UI 构建 ──────────────────────────────────────────

    def _build_ui(self):
        """构建主界面骨架。"""
        # 顶部工具栏
        toolbar = ttk.Frame(self.root, padding=(12, 8))
        toolbar.pack(fill=X)

        ttk.Label(toolbar, text="RPG 数据编辑器", font=("Microsoft YaHei", 14, "bold")).pack(side=LEFT)
        ttk.Label(toolbar, text="直接编辑 game/data/*.tres", font=("Microsoft YaHei", 9)).pack(side=LEFT, padx=12)

        self._status_var = StringVar(value="就绪")
        ttk.Label(toolbar, textvariable=self._status_var, font=("Microsoft YaHei", 9)).pack(side=RIGHT, padx=(0, 10))
        refresh_btn = ttk.Button(toolbar, text="⟳ 刷新全部", bootstyle="secondary", command=self._do_full_refresh)
        refresh_btn.pack(side=RIGHT)
        self.root.bind("<F5>", lambda e: self._do_full_refresh())

        ttk.Separator(self.root, orient=HORIZONTAL).pack(fill=X, padx=12)

        # 类型标签栏
        self._tab_frame = ttk.Frame(self.root, padding=(12, 6))
        self._tab_frame.pack(fill=X)
        self._tab_btns: dict[str, ttk.Button] = {}
        for i, cls in enumerate(ALL_TYPES):
            label = TYPE_LABELS.get(cls, cls)
            btn = ttk.Button(
                self._tab_frame, text=label,
                command=lambda c=cls: self._switch_tab(c),
                style="TButton",
            )
            btn.pack(side=LEFT, padx=(0, 4))
            self._tab_btns[cls] = btn

        ttk.Separator(self.root, orient=HORIZONTAL).pack(fill=X, padx=12)

        # 主内容区：左侧表格 + 右侧编辑面板
        paned = ttk.Panedwindow(self.root, orient=HORIZONTAL)
        paned.pack(fill=BOTH, expand=True, padx=12, pady=6)

        # 左侧 — 表格 + 搜索
        left_frame = ttk.Frame(paned)
        paned.add(left_frame, weight=3)

        search_frame = ttk.Frame(left_frame, padding=(0, 0, 0, 6))
        search_frame.pack(fill=X)
        ttk.Label(search_frame, text="搜索:", font=("Microsoft YaHei", 10)).pack(side=LEFT)
        self._search_var = StringVar()
        self._search_var.trace_add("write", lambda *_: self._apply_filter())
        search_entry = ttk.Entry(search_frame, textvariable=self._search_var, width=30)
        search_entry.pack(side=LEFT, padx=6)
        ttk.Button(search_frame, text="X", width=3, command=self._clear_search).pack(side=LEFT)

        # Treeview 表格
        tree_frame = ttk.Frame(left_frame)
        tree_frame.pack(fill=BOTH, expand=True)
        self._tree = ttk.Treeview(tree_frame, show="headings", bootstyle="primary")
        self._tree.pack(side=LEFT, fill=BOTH, expand=True)

        tree_scroll = ttk.Scrollbar(tree_frame, orient=VERTICAL, command=self._tree.yview)
        tree_scroll.pack(side=RIGHT, fill=Y)
        self._tree.configure(yscrollcommand=tree_scroll.set)
        self._tree.bind("<<TreeviewSelect>>", self._on_row_selected)
        self._tree.bind("<Double-1>", lambda e: self._on_row_double_click())

        # 右侧 — 编辑面板
        right_frame = ttk.Frame(paned, padding=(12, 0, 0, 0))
        paned.add(right_frame, weight=2)

        ttk.Label(right_frame, text="字段编辑", font=("Microsoft YaHei", 12, "bold")).pack(anchor=W, pady=(0, 8))

        edit_container = ttk.Frame(right_frame)
        edit_container.pack(fill=BOTH, expand=True)

        self._edit_canvas = ttk.Canvas(edit_container, highlightthickness=0)
        edit_scroll = ttk.Scrollbar(edit_container, orient=VERTICAL, command=self._edit_canvas.yview)
        self._edit_inner = ttk.Frame(self._edit_canvas)

        self._edit_inner.bind("<Configure>", lambda e: self._edit_canvas.configure(
            scrollregion=self._edit_canvas.bbox("all")))
        self._edit_canvas.create_window((0, 0), window=self._edit_inner, anchor="nw")
        self._edit_canvas.configure(yscrollcommand=edit_scroll.set)

        self._edit_canvas.pack(side=LEFT, fill=BOTH, expand=True)
        edit_scroll.pack(side=RIGHT, fill=Y)

        # 鼠标滚轮支持
        def _on_mousewheel(event):
            self._edit_canvas.yview_scroll(int(-1 * (event.delta / 120)), "units")
        self._edit_canvas.bind_all("<MouseWheel>", _on_mousewheel)

        # 编辑面板内的字段控件（动态生成）
        self._edit_widgets: dict[str, ttk.Widget] = {}
        self._edit_type: str = ""

        # 底部操作栏
        action_frame = ttk.Frame(right_frame, padding=(0, 10, 0, 0))
        action_frame.pack(fill=X, side=BOTTOM)

        self._selected_id_var = StringVar(value="")
        ttk.Label(action_frame, textvariable=self._selected_id_var,
                  font=("Consolas", 10), bootstyle="secondary").pack(anchor=W, pady=(0, 6))

        btn_frame = ttk.Frame(action_frame)
        btn_frame.pack(fill=X)
        ttk.Button(btn_frame, text="新 建", bootstyle="success", command=self._do_new).pack(side=LEFT, padx=(0, 6))
        ttk.Button(btn_frame, text="保 存", bootstyle="primary", command=self._do_save).pack(side=LEFT, padx=(0, 6))
        ttk.Button(btn_frame, text="删 除", bootstyle="danger", command=self._do_delete).pack(side=LEFT, padx=(0, 6))
        ttk.Button(btn_frame, text="刷 新", bootstyle="secondary", command=self._do_refresh).pack(side=LEFT)

        # 右键菜单
        self._context_menu = ttk.Menu(self.root, tearoff=0)
        self._context_menu.add_command(label="编辑", command=self._on_row_double_click)
        self._context_menu.add_command(label="删除", command=self._do_delete)
        self._context_menu.add_separator()
        self._context_menu.add_command(label="复制 ID", command=self._copy_id)
        self._tree.bind("<Button-3>", self._show_context_menu)

    # ── 标签切换 ────────────────────────────────────────

    def _switch_tab(self, cls: str):
        """切换到指定类型标签（懒加载）。"""
        self._current_type = cls
        self._selected_id_var.set("")
        self._edit_type = cls
        for w in self._edit_inner.winfo_children():
            w.destroy()
        self._edit_widgets.clear()
        for c, btn in self._tab_btns.items():
            btn.configure(bootstyle="primary" if c == cls else "secondary")
        # 懒加载：只有第一次切到此标签时才解析 .tres
        if cls not in self._loaded:
            self._status_var.set(f"加载中: {TYPE_LABELS.get(cls, cls)} ...")
            self.root.update_idletasks()
            self._cache[cls] = list_resources(ROOT, cls)
            self._loaded.add(cls)
        self._populate_tree()

    def _load_data(self):
        """重新加载当前类型数据（刷新/保存后调用）。"""
        cls = self._current_type
        self._status_var.set(f"刷新中: {TYPE_LABELS.get(cls, cls)} ...")
        self.root.update_idletasks()
        resources = list_resources(ROOT, cls)
        self._cache[cls] = resources
        self._current[cls] = None
        self._populate_tree()

    def _populate_tree(self):
        """填充 Treeview 表格。"""
        cls = self._current_type
        resources = self._cache.get(cls, [])

        # 清空
        self._tree.delete(*self._tree.get_children())

        # 设置列
        columns = LIST_COLUMNS.get(cls, [])
        id_field = TYPE_TO_ID_FIELD.get(cls, "id")
        all_cols = [id_field] + list(columns)
        self._tree["columns"] = all_cols

        # 表头
        for col in all_cols:
            header = COL_HEADERS.get(col, col)
            self._tree.heading(col, text=header)
            width = 160 if col == id_field else 100
            self._tree.column(col, width=width, minwidth=60)

        # 数据行
        search_text = self._search_var.get().lower()
        for res in resources:
            data = res["data"]
            rid = res["id"]
            # 搜索过滤
            if search_text and search_text not in str(rid).lower() and search_text not in str(data.get("display_name", data.get("title", ""))).lower():
                continue
            values = [rid]
            for col in columns:
                val = data.get(col, "")
                if col == "quality" and cls in ("Item", "Equipment"):
                    q = int(val) if val else 0
                    val = QUALITY_NAMES[q] if 0 <= q < 5 else str(val)
                if col in ("icon_path", "portrait_path") and val:
                    # Show just the filename
                    val = val.split("/")[-1].replace(".png", "") if val else "-"
                if col in ("icon_path", "portrait_path") and not val:
                    val = "-"
                values.append(_fmt(val))
            self._tree.insert("", END, values=values, iid=rid,
                tags=(str(data.get("quality", 0)),) if cls in ("Item", "Equipment") else ())
        # 品质着色
        if cls in ("Item", "Equipment"):
            for q_idx in range(5):
                self._tree.tag_configure(str(q_idx), foreground=QUALITY_COLORS[q_idx])

        self._status_var.set(f"{TYPE_LABELS.get(cls, cls)}: {len(resources)} 条")

    def _apply_filter(self):
        self._populate_tree()

    def _clear_search(self):
        self._search_var.set("")

    # ── 行选择 ──────────────────────────────────────────

    def _on_row_selected(self, event):
        sel = self._tree.selection()
        if not sel: return
        rid = sel[0]
        cls = self._current_type
        resources = self._cache.get(cls, [])
        for res in resources:
            if res["id"] == rid:
                self._current[cls] = res
                self._selected_id_var.set(rid)
                self._build_edit_form(res)
                return

    def _on_row_double_click(self):
        """双击打开编辑面板（已通过 _on_row_selected 加载了表单）。"""
        pass  # _on_row_selected 已处理

    def _show_context_menu(self, event):
        item = self._tree.identify_row(event.y)
        if item:
            self._tree.selection_set(item)
            self._on_row_selected(None)
            self._context_menu.post(event.x_root, event.y_root)

    def _copy_id(self):
        rid = self._selected_id_var.get()
        if rid:
            self.root.clipboard_clear()
            self.root.clipboard_append(rid)

    # ── 编辑表单 ────────────────────────────────────────

    def _build_edit_form(self, res: dict):
        """根据资源数据动态生成编辑表单。"""
        cls = self._current_type
        for w in self._edit_inner.winfo_children():
            w.destroy()
        self._edit_widgets.clear()

        data = res["data"]
        fields = RESOURCE_TYPES.get(cls, {}).get("fields", [])
        id_field = TYPE_TO_ID_FIELD.get(cls, "id")

        row = 0
        for fname, ftype in fields:
            is_id = fname == id_field

            # 标签：中文名
            cn_name = FIELD_CN.get(fname, fname)
            lbl = ttk.Label(self._edit_inner, text=cn_name, font=("Microsoft YaHei", 10, "bold"))
            lbl.grid(row=row, column=0, sticky=W, pady=(6, 1), padx=(0, 8))

            val = data.get(fname, "")

            if is_id:
                # ID 字段只读
                display_val = val if val else "(新建)"
                widget = ttk.Label(self._edit_inner, text=display_val,
                                   font=("Consolas", 10, "bold"), bootstyle="secondary")
                widget.grid(row=row, column=1, sticky=EW, pady=(6, 1))
            elif fname in ("icon_path", "portrait_path") and val:
                # 图标预览
                img_file = val.split("/")[-1]
                if not img_file.endswith(".png"):
                    img_file += ".png"
                full_path = ROOT / "game" / "art" / "ui" / "inventory" / "icons" / img_file
                if full_path.exists():
                    try:
                        from PIL import Image as PILImage, ImageTk
                        img = PILImage.open(full_path).resize((64, 64), PILImage.LANCZOS)
                        photo = ImageTk.PhotoImage(img)
                        widget = ttk.Label(self._edit_inner, image=photo)
                        widget.image = photo
                        widget.grid(row=row, column=1, sticky=W, pady=(6, 1))
                        row += 1
                        continue
                    except Exception as e:
                        print(f"icon preview err: {e}")
                # Fallback
                var = ttk.StringVar(value=img_file)
                widget = ttk.Entry(self._edit_inner, textvariable=var)
                widget.grid(row=row, column=1, sticky=EW, pady=(6, 1))
                widget._var = var
            elif ftype == "bool":
                var = ttk.BooleanVar(value=bool(val))
                widget = ttk.Checkbutton(self._edit_inner, variable=var,
                                         text="", bootstyle="round-toggle")
                widget.grid(row=row, column=1, sticky=W, pady=(6, 1))
                widget._var = var
            elif ftype == "int" and fname == "quality":
                var = ttk.StringVar(value=str(val))
                widget = ttk.Combobox(self._edit_inner, textvariable=var,
                                       values=[str(i) for i in range(5)], width=6)
                widget.grid(row=row, column=1, sticky=W, pady=(6, 1))
                widget._var = var
                hint = QUALITY_NAMES[int(val)] if val in (0,1,2,3,4) else ""
                ttk.Label(self._edit_inner, text=hint, font=("Microsoft YaHei", 8),
                          bootstyle="secondary").grid(row=row, column=2, sticky=W)
            elif ftype == "int" and fname == "slot":
                var = ttk.StringVar(value=str(val))
                widget = ttk.Combobox(self._edit_inner, textvariable=var,
                                       values=[str(i) for i in range(6)], width=6)
                widget.grid(row=row, column=1, sticky=W, pady=(6, 1))
                widget._var = var
                # 显示槽位名称
                try:
                    idx = int(val)
                    hint = SLOT_NAMES[idx] if 0 <= idx < 6 else ""
                    ttk.Label(self._edit_inner, text=hint, font=("Microsoft YaHei", 8),
                              bootstyle="secondary").grid(row=row, column=2, sticky=W)
                except (ValueError, TypeError):
                    pass
            elif ftype == "int" and fname == "kind" and cls == "QuestDef":
                var = ttk.StringVar(value=str(val))
                widget = ttk.Combobox(self._edit_inner, textvariable=var,
                                       values=["0", "1"], width=4)
                widget.grid(row=row, column=1, sticky=W, pady=(6, 1))
                widget._var = var
                hint = KIND_NAMES_QUEST[int(val)] if val in (0, 1) else ""
                ttk.Label(self._edit_inner, text=hint, font=("Microsoft YaHei", 8),
                          bootstyle="secondary").grid(row=row, column=2, sticky=W)
            elif ftype == "int" and fname == "kind" and cls == "Skill":
                var = ttk.StringVar(value=str(val))
                widget = ttk.Combobox(self._edit_inner, textvariable=var,
                                       values=["0", "1", "2", "3"], width=4)
                widget.grid(row=row, column=1, sticky=W, pady=(6, 1))
                widget._var = var
            elif ftype == "int" and fname == "category":
                var = ttk.StringVar(value=str(val))
                widget = ttk.Combobox(self._edit_inner, textvariable=var,
                                       values=["0", "1", "2", "3"], width=4)
                widget.grid(row=row, column=1, sticky=W, pady=(6, 1))
                widget._var = var
            elif ftype.startswith("Array"):
                text_val = ", ".join(str(v) for v in val) if isinstance(val, list) and val else ""
                var = ttk.StringVar(value=text_val)
                widget = ttk.Entry(self._edit_inner, textvariable=var)
                widget.grid(row=row, column=1, sticky=EW, pady=(6, 1))
                widget._var = var
                ttk.Label(self._edit_inner, text="(逗号分隔)", font=("Microsoft YaHei", 7),
                          bootstyle="secondary").grid(row=row, column=2, sticky=W)
            elif ftype == "String" and ("\n" in str(val) or len(str(val)) > 40):
                widget = ttk.Text(self._edit_inner, height=3, width=40)
                widget.insert("1.0", str(val) if val else "")
                widget.grid(row=row, column=1, columnspan=2, sticky=EW, pady=(6, 1))
                widget._is_text = True
            else:
                var = ttk.StringVar(value=str(val) if val is not None else "")
                widget = ttk.Entry(self._edit_inner, textvariable=var)
                widget.grid(row=row, column=1, sticky=EW, pady=(6, 1))
                widget._var = var

            self._edit_widgets[fname] = widget
            row += 1

        self._edit_inner.columnconfigure(1, weight=1)

    # ── 操作：新建 / 保存 / 删除 ────────────────────────

    def _do_new(self):
        """创建新资源。"""
        cls = self._current_type
        type_label = TYPE_LABELS.get(cls, cls)
        id_field = TYPE_TO_ID_FIELD.get(cls, "id")

        # 弹出对话框输入 ID
        dialog = ttk.Toplevel(self.root)
        dialog.title(f"新建{type_label}")
        dialog.geometry("400x150")
        dialog.transient(self.root)
        dialog.grab_set()

        ttk.Label(dialog, text=f"请输入 {type_label} ID（英文，蛇形命名）:",
                  font=("Microsoft YaHei", 10)).pack(pady=(20, 10))
        id_var = ttk.StringVar()
        entry = ttk.Entry(dialog, textvariable=id_var, width=30, font=("Consolas", 11))
        entry.pack(pady=(0, 10))
        entry.focus()

        result = [False]

        def _ok():
            rid = id_var.get().strip()
            if not rid:
                messagebox.showwarning("警告", "ID 不能为空")
                return
            # 检查是否已存在
            subdir = TYPE_TO_DIR.get(cls, "")
            if (ROOT / "game" / subdir / f"{rid}.tres").exists():
                messagebox.showwarning("警告", f"{rid}.tres 已存在！")
                return
            # 创建默认数据
            data = {id_field: rid}
            if cls in ("Item", "Equipment", "ShopDef"):
                data["display_name"] = rid
            elif cls == "EnemyDef":
                data["display_name"] = rid
            elif cls == "QuestDef":
                data["title"] = rid
            ok = save_resource(ROOT, cls, data)
            if ok:
                result[0] = True
                self._status_var.set(f"已创建: {rid}")
            else:
                messagebox.showerror("错误", "创建失败")
            dialog.destroy()

        ttk.Button(dialog, text="创建", bootstyle="success", command=_ok).pack(side=LEFT, padx=(80, 10))
        ttk.Button(dialog, text="取消", command=dialog.destroy).pack(side=LEFT)
        dialog.wait_window()

        if result[0]:
            self._load_data()

    def _do_save(self):
        """保存当前编辑的资源。"""
        cls = self._current_type
        current = self._current.get(cls)
        if current is None:
            messagebox.showwarning("提示", "请先在左侧表格中选择一条数据。")
            return

        # 从编辑控件收集数据
        fields = RESOURCE_TYPES.get(cls, {}).get("fields", [])
        data = {}
        for fname, ftype in fields:
            widget = self._edit_widgets.get(fname)
            if widget is None:
                continue
            raw_val = self._get_widget_value(widget, ftype)
            data[fname] = self._convert_value(raw_val, ftype)

        ok = save_resource(ROOT, cls, data)
        if ok:
            rid = data.get(TYPE_TO_ID_FIELD.get(cls, "id"), "")
            self._status_var.set(f"已保存: {rid}")
            self._load_data()
        else:
            messagebox.showerror("错误", "保存失败")

    def _do_delete(self):
        """删除选中的资源。"""
        cls = self._current_type
        rid = self._selected_id_var.get()
        if not rid:
            messagebox.showwarning("提示", "请先选择一条数据。")
            return

        if not messagebox.askyesno("确认删除", f"确定要删除 {rid} 吗？\n此操作不可撤销。"):
            return

        ok = delete_resource(ROOT, cls, rid)
        if ok:
            self._status_var.set(f"已删除: {rid}")
            self._current[cls] = None
            self._selected_id_var.set("")
            for w in self._edit_inner.winfo_children():
                w.destroy()
            self._edit_widgets.clear()
            self._load_data()
        else:
            messagebox.showerror("错误", "删除失败")

    def _do_refresh(self):
        """刷新当前标签数据。"""
        cls = self._current_type
        self._loaded.discard(cls)
        self._cache.pop(cls, None)
        self._current[cls] = None
        for w in self._edit_inner.winfo_children():
            w.destroy()
        self._edit_widgets.clear()
        self._selected_id_var.set("")
        self._load_data()
        self._status_var.set("已刷新")

    def _do_full_refresh(self):
        """刷新全部数据（清空所有缓存重新加载）。"""
        self._loaded.clear()
        self._cache.clear()
        self._current.clear()
        for w in self._edit_inner.winfo_children():
            w.destroy()
        self._edit_widgets.clear()
        self._selected_id_var.set("")
        self._status_var.set("刷新全部数据...")
        self.root.update_idletasks()
        # 重新加载当前标签
        cls = self._current_type
        if cls:
            self._cache[cls] = list_resources(ROOT, cls)
            self._loaded.add(cls)
            self._populate_tree()
        self._status_var.set("全部数据已刷新")

    # ── 辅助 ────────────────────────────────────────────

    def _get_widget_value(self, widget, ftype: str):
        """从控件读取原始值。"""
        if hasattr(widget, "_is_text"):
            return widget.get("1.0", "end-1c")
        if hasattr(widget, "_var"):
            return widget._var.get()
        if isinstance(widget, ttk.Checkbutton):
            return widget._var.get()
        return ""

    def _convert_value(self, raw, ftype: str):
        """将控件原始字符串转为 Python 类型。"""
        if ftype == "bool":
            if isinstance(raw, bool): return raw
            return str(raw).lower() in ("true", "1", "yes", "on")
        elif ftype == "int":
            try: return int(raw)
            except: return 0
        elif ftype == "float":
            try: return float(raw)
            except: return 0.0
        elif ftype.startswith("Array"):
            if isinstance(raw, str) and raw.strip():
                return [v.strip().strip('"').strip("'") for v in raw.split(",") if v.strip()]
            return []
        else:
            return str(raw) if raw is not None else ""


# ── 入口 ──────────────────────────────────────────────────

def main():
    try:
        app = DataEditorApp()
    except Exception as e:
        import traceback
        from tkinter import messagebox
        messagebox.showerror("启动错误", f"数据编辑器启动失败:\n\n{traceback.format_exc()}")
        raise


if __name__ == "__main__":
    main()
