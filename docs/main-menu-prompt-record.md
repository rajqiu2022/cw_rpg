# 主菜单 AI 生成 Prompt 记录

> 最后更新：2026-05-09

## ✅ 最终确认版本：v5

**生成文件**：`assets/raw/scene_background/ui_main_menu_full_v5.png`  
**生成脚本**：`scripts/gen_main_menu_v5.py`  
**模型**：gpt-image-2  
**API**：ALAPI（v3.alapi.cn）  
**尺寸**：1536x1024  
**耗时**：~44 秒  
**成本**：约 ¥1.2/张  

---

## 🎨 风格三要素（用户确认满意）

1. **金色书法标题** — "云影侠传" 金色描边书法字 + 横剑贯穿 + 翡翠坠子
2. **暗色金属按钮** — 暗色金属边框 + 宝石角饰 + 绿/青/红渐变底 + 金色文字
3. **蓝色仙侠山水背景** — 蓝调群山 + 云雾飞瀑 + 暮色 + 蓝衣剑客背影站悬崖边

---

## 📝 完整 Prompt（英文）

```
Chinese wuxia martial arts game main menu screen, 1536x1024 landscape format.

BACKGROUND: Misty blue-toned mountain landscape with floating clouds, distant waterfalls cascading down steep peaks, ancient pine trees silhouetted against twilight sky. Cool blue-green color palette with subtle warm highlights from a setting sun. Ethereal, painterly Chinese ink wash style with modern game art polish.

LEFT SIDE CHARACTER: A lone swordsman in flowing blue robes standing on a cliff edge, viewed from behind at 3/4 angle, long hair blowing in the wind, a sheathed sword on his back. He gazes into the vast mountain vista. Anime-influenced wuxia character design.

TOP CENTER TITLE: Large ornate Chinese calligraphy characters "云影侠传" (Cloud Shadow Swordsman) in brilliant gold with metallic sheen and dark stroke outlines. A decorative horizontal sword pierces through the title horizontally. Small jade/emerald pendants hang from the sword. The title has a subtle golden glow aura. Style: epic game logo with traditional calligraphy brush strokes.

RIGHT SIDE MENU BUTTONS (3 buttons stacked vertically, centered on right half):
1. "新游戏" (New Game) - Dark ornate metal frame button with emerald green gradient fill, small gem decorations on corners, gold Chinese text
2. "读取存档" (Load Game) - Same dark metal frame style with teal/cyan gradient fill, gem corner decorations, gold text
3. "离开" (Quit) - Same frame style with dark red/crimson gradient fill, gem corners, gold text

Button style: Each button has an elaborate dark metal border with rivets and small gemstones, slightly curved rectangular shape, the text is centered in gold calligraphy.

COMPOSITION: The swordsman occupies the left 40%, the title is at top center, buttons are on the right side vertically centered. The overall mood is epic, mysterious, and inviting. No UI chrome or modern elements outside the described components.

STYLE: High quality 2D game art, semi-realistic with anime influence, rich detail, professional game UI design, Chinese martial arts fantasy aesthetic.
```

---

## 🔧 API 调用参数

```python
# ALAPI gpt-image-2
headers = {
    "token": "<ALAPI_TOKEN>",
    "Content-Type": "application/json",
}
payload = {
    "model": "gpt-image-2",
    "prompt": PROMPT,
    "n": 1,
    "size": "1536x1024",
    "quality": "high",
}
url = "https://v3.alapi.cn/api/ai/images/generations"
```

---

## 📋 后续复用指南

- **微调构图**：修改 COMPOSITION 段落中的百分比和位置描述
- **换标题字**：修改 TOP CENTER TITLE 中的中文和翻译
- **换配色**：修改 BACKGROUND 的 color palette 描述
- **换人物**：修改 LEFT SIDE CHARACTER 的服装/姿态/位置
- **按钮数量/文字**：修改 MENU BUTTONS 列表
- **出其他场景**：保留 STYLE 段，替换前面各段即可

---

## 🗂️ 版本历史

| 版本 | 方案 | 结果 |
|------|------|------|
| v1~v4 | 分别生成部件再拼图 | ❌ 边缘/色调/光影不统一 |
| **v5** | 一次性完整 prompt 直出 | ✅ 完美，用户确认满意 |

**教训**：主菜单这种整体画面，一定要一次性生成，不要拼图。AI 在一次生成中能保持全局光影、色调、构图的一致性。
