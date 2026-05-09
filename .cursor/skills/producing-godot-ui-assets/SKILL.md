---
name: producing-godot-ui-assets
description: Use when creating, regenerating, polishing, or deploying Godot RPG UI assets from reference images, especially buttons, panels, normal hover pressed states, alpha cleanup, size matching, or game/art/ui integration.
---

# Producing Godot UI Assets

## Core Rule

Treat UI art as a pipeline, not a one-off image. A finished UI asset set must have consistent geometry, stable alpha, deployable Godot paths, runtime integration, preview evidence, and an experience-log entry for any new pitfall.

## Required Context

Before editing, read the current production and integration files:

- Existing asset script for the same UI family, if present, for example `scripts/process_main_menu_button_layers.py`
- Target Godot consumer script and scene, for example `game/scripts/ui/main_menu.gd`, `game/scripts/ui/inventory_panel.gd`, or `game/scenes/ui/*.tscn`
- Shared UI helpers that may restyle buttons, for example `game/scripts/ui/wuxia_theme.gd`
- Recent lessons: `docs/experience-log.md`
- Project rules: `AGENTS.md`

Prefer extending the existing asset script over hand-editing generated PNGs.

If no script exists for the target UI family, create a narrowly scoped script in `scripts/` with the target UI name, for example `process_inventory_panel_buttons.py`. Do not keep using a main-menu script for unrelated panels.

## Workflow

1. Identify source, target, and ownership.
   - Source reference images live under `assets/raw/`.
   - Game-ready UI PNGs live under `game/art/ui/<type>/`.
   - Previews and temporary diagnostics live under `tools/`.
   - Do not overwrite unrelated user assets.

2. Choose the production mode.
   - If the reference already contains high-quality UI, crop and reuse it first.
   - If text and frame need separate control, generate `frame` and `text` layers.
   - If the reference text, shadow, and frame are fused well, keep full buttons with embedded text and add a layered fallback only if useful.

3. Normalize geometry before deriving states.
   - Choose and record one canvas size for the target control group from the reference and the Godot layout.
   - Example: main menu buttons currently use `512x128`.
   - Use one crop size and one scale rule for all buttons in the same group.
   - Never use each image's post-matting alpha bbox to decide final scale for a grouped UI set.
   - Keep anchor, padding, visible bounds, and transparent margins stable.

4. Clean alpha deliberately.
   - Use `rembg` or a purpose-built mask for complex screenshot backgrounds.
   - Clear low-alpha RGB residue after matting.
   - For colored text, do not remove white by brightness alone; preserve chroma-rich gold highlights.
   - Harden text body alpha while keeping only edge anti-aliasing semi-transparent.

5. Derive interaction states from one base.
   - Produce or crop only the normal/base shape first.
   - Create `hover` and `pressed` programmatically with tint, brightness, glow, or shadow changes.
   - Preserve the exact same alpha mask across states for each control.
   - Do not ask image generation to freely redraw every state; it causes outline jitter.

6. Deploy to Godot.
   - Save adopted assets under `game/art/ui/<type>/` with stable names such as `btn_menu_v5_new_game_normal.png`.
   - In Godot `Button`, use `StyleBoxTexture` overrides for `normal`, `hover`, and `pressed`.
   - Keep `btn.flat = false`; `flat = true` hides `StyleBoxTexture` backgrounds.
   - Hide native button text when using texture text or embedded-text button PNGs.
   - Add fallback styling for missing textures.
   - If replacing buttons previously styled by `UI_THEME.style_button()`, either remove that style call for the texture-backed button or apply the texture overrides after the final style call. Re-check that `flat` remains `false`.

7. Generate a preview.
   - Composite the assets on the intended background or a close stand-in.
   - Use the preview to check size, placement, text opacity, hover/pressed readability, and visual jump.

## Verification

Run the available checks before saying the asset set is done. Replace script names with the target UI's actual production script:

```bash
python scripts/<target_ui_asset_script>.py
python -m py_compile scripts/<target_ui_asset_script>.py
```

For button sets, also verify:

- Every state PNG exists under the intended `game/art/ui/<type>/` folder.
- Each button's `normal`, `hover`, and `pressed` alpha masks match.
- Buttons in the same group have consistent canvas size and visual bounds.
- The preview image in `tools/` looks correct.
- `ReadLints` reports no new issues for edited scripts.
- If Godot code changed, inspect or run the target scene or panel when practical and test every hover/pressed transition.

Useful mask-check pattern:

```python
from pathlib import Path
from PIL import Image
import numpy as np

root = Path(".")
button_keys = ["filter_all", "filter_items", "close"]  # Replace with this UI's actual keys.
states = ["normal", "hover", "pressed"]
pattern = "game/art/ui/button/<prefix>_{key}_{state}.png"  # Replace <prefix>.

for key in button_keys:
    masks = []
    for state in states:
        img = Image.open(root / pattern.format(key=key, state=state)).convert("RGBA")
        mask = np.array(img)[:, :, 3] > 0
        masks.append(mask)
        print(key, state, Image.fromarray((mask * 255).astype("uint8")).getbbox(), int(mask.sum()))
    print(key, "state_masks_equal", bool((masks[0] == masks[1]).all()), bool((masks[0] == masks[2]).all()))
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Three states generated independently | Derive hover/pressed from one base image |
| Button group scales by each alpha bbox | Scale by the same source crop geometry |
| Gold text becomes translucent | Use chroma-aware white removal and alpha hardening |
| Background residue remains after matting | Clean transparent pixels and inspect on the real background |
| Button texture does not appear in Godot | Ensure `Button.flat` is `false` and `StyleBoxTexture` paths exist |
| PNG looks fine but runtime jumps | Test the actual `normal`/`hover`/`pressed` overrides in Godot |
| Problem fixed but forgotten | Append a concise entry to `docs/experience-log.md` |

## Experience Logging

After fixing any UI asset production issue, append `docs/experience-log.md` with:

- symptom
- cause
- fix
- verification
- reusable lesson

Use this especially for API quirks, background removal, alpha cleanup, Godot import/rendering behavior, sizing mismatches, or deployment path mistakes.
