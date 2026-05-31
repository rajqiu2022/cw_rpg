---
name: ui-button-text-engraved-technique
description: Proven PIL-based technique for replacing AI-generated light/muddy button text with engraved-metal-look text on dark metallic frames
type: reference
---

# UI Button Text: Engraved Metal Technique

## Problem
AI-generated text (gpt-image-2) on dark metallic buttons often comes out too light, muddy, or lacking contrast. The separate text PNGs have poor color (~RGB 170-190) against dark frames (~RGB 37-51).

## Solution
Use PIL to re-render Chinese text with an **engraved/incised metal** effect (not embossed/raised). The fix script is at `scripts/fix_single_frame_v3_text.py`.

### Layer stack (bottom to top):
1. **Cavity shadow** — offset (-2, -2), dark fill `(10,16,20,210)`, GaussianBlur 0.7
2. **Main metal fill** — center position, warm metallic `(198,190,172,255)`, dark stroke `(24,30,34,220)`
3. **Rim light** — offset (+1, +2), light tone `(228,220,202,85)` clipped to text alpha
4. **Noise grain** — deterministic per-key noise, ~0-18 intensity, masked to text alpha

### Key technical details:
- Use **inner shadow** (dark at top-left) + **bottom highlight** for recessed/engraved look — NOT drop shadow (which creates raised/floating look)
- Text fill should be a metallic mid-tone, not pure white
- Add subtle noise to match the frame's gritty metal texture
- Font: STXINGKA (华文行楷) ~36px for 241×93 buttons
- Button size: 241×93, text center ~(155, 49), icon center ~(62, 47)

## Style Alignment
Matches the game's "寒山玄铁 · 雾蓝侠影风" style guide. The engraved text feels like it belongs in the same physical world as the dark metal frame, unlike AI-generated text which looks "pasted on."

## Files
- Script: `scripts/fix_single_frame_v3_text.py`
- Output: `game/art/ui/field_hud/v1/hud_btn_{inventory,equipment,skill,quest,system}_{normal,hover,pressed}.png`
