---
name: producing-ui-button-states
description: Use when creating or fixing UI button assets with normal, hover, pressed, click, selected, or disabled states, especially when matching an approved sample button, reusing a base frame, separating icon/text layers, deploying PNGs to Godot, or debugging size, alpha, mask, font, and visual-jump issues.
---

# Producing UI Button States

## Core Rule

同一组按钮必须按“底框层 + 图标层 + 文字层 + 三态派生”生产。不要把每个按钮整枚独立生成、独立抠图、独立归一化；那会导致底框、图标、字号、字重、透明边界和 hover/pressed 动画全部漂移。

## Required Context

Before editing assets or scripts, read:

- The approved sample button or style reference.
- The current production script for that UI family.
- The Godot consumer script or scene that loads the button textures.
- `docs/experience-log.md` recent UI entries.
- `producing-godot-ui-assets` if broader Godot integration decisions are needed.

## Standard Pipeline

1. Pick one approved specimen.
   - Treat it as the only geometry reference for the group.
   - Record canvas size, visible bounds, icon slot, text center, and transparent padding.

2. Produce or adopt one reusable base frame.
   - Preferred: generate a textless/iconless base frame from the specimen.
   - Acceptable: crop a clean frame if the source already has no text/icon.
   - Avoid: algorithmically inpainting large icon/text areas on a finished button; it creates visible patches.

3. Create separate icon layers.
   - Every icon uses the same target center and maximum size.
   - Use per-icon crop boxes if needed, but the final layer must land in the same slot.
   - Save intermediate `icon_<key>.png` files for visual inspection.

4. Create separate text layers.
   - Use one font, one size, one center point, one fill/stroke/shadow recipe for the whole group.
   - For Chinese text, prefer a local verified font and render programmatically when AI text is unreliable.
   - Save intermediate `text_<key>.png` files.

5. Compose normal state.
   - `normal = base_frame + icon_layer + text_layer`.
   - Save all intermediate layers under `tools/` and final adopted PNGs under `game/art/ui/<type>/`.

6. Derive hover and pressed from normal.
   - Use brightness, color, glow, offset, or shadow changes programmatically.
   - Preserve the exact alpha mask across states.
   - Never independently generate hover/pressed images from the image API.

7. Generate preview evidence.
   - Show every button in normal / hover / pressed columns.
   - Include the real or close stand-in background when placement matters.

## Verification

Run the production script and compile it:

```bash
python scripts/<button_pipeline>.py
python -m py_compile scripts/<button_pipeline>.py
```

Then verify:

- Every expected `normal`, `hover`, and `pressed` PNG exists.
- All states use the same canvas size.
- Each button's state alpha masks are identical.
- Buttons in the group share the same base-frame visible bounds.
- Preview image clearly shows no size jump, font drift, icon drift, or old-frame residue.
- `ReadLints` has no new issues for edited scripts/templates.

Useful alpha-mask check:

```python
from pathlib import Path
from PIL import Image
import numpy as np

root = Path("game/art/ui/field_hud/v1")
keys = ["inventory", "equipment", "skill", "quest", "system"]
for key in keys:
    masks = []
    for state in ["normal", "hover", "pressed"]:
        img = Image.open(root / f"hud_btn_{key}_{state}.png").convert("RGBA")
        masks.append(np.array(img)[:, :, 3] > 0)
        print(key, state, img.size, Image.fromarray((masks[-1] * 255).astype("uint8")).getbbox())
    print(key, "mask_equal", bool((masks[0] == masks[1]).all()), bool((masks[0] == masks[2]).all()))
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Generate each full button separately | Generate/adopt one base frame and compose layers |
| Normalize by each asset's alpha bbox | Use one specimen canvas, one icon slot, one text center |
| AI writes Chinese text | Use AI for art texture; render verified text as a separate layer |
| Inpaint finished button into a blank frame | Generate a textless base frame instead |
| Icon layer carries old button texture | Tighten crop/mask and inspect `icon_<key>.png` |
| Hover/pressed generated independently | Derive states from normal and preserve alpha mask |
| PNG looks fine alone but jumps in game | Test preview and Godot texture button states |

## Project Example

For the current field HUD right-side buttons:

- Specimen: `game/art/ui/field_hud/v1/hud_btn_skill_normal.png`.
- Current standardized script: `scripts/adjust_hud_button_feedback.py`.
- Layer preview output: `tools/ui_field_hud_v1/skill_frame_recomposed_buttons/`.
- Adopted output: `game/art/ui/field_hud/v1/hud_btn_<key>_<state>.png`.

When fixing these buttons again, keep the standardized layered pipeline. Do not return to full-button candidate selection unless the whole group is being redesigned from scratch.
