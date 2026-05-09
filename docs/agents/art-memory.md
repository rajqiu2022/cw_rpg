# Art Memory

> Role: `art` / 美术管线 agent.
> Scope: prompt templates, asset tasks, image generation, sprite sheet specs, post-processing, previews, art validation.
> Canonical docs: `docs/sprite-prompt-playbook.md`, `docs/sprite-cost-optimization-plan.md`, `docs/style-bible-prompts.md`, `docs/acceptance-checklists/art.md`.

## Pipeline Snapshot

- Batch generation is controlled by `scripts/gen_assets.py`.
- Tasks live in `prompts/tasks.yaml`.
- Prompt templates live in `prompts/templates/*.yaml`.
- Raw outputs live in `assets/raw/**`.
- Processed outputs live in `assets/processed/**`.
- Visual previews live in `assets/previews/**`.

## Model / Budget Rules

- Use `gpt-image-2` for current sprite work unless producer approves otherwise.
- To disable fallback to image 1.5, pass `--fallback-model gpt-image-2`.
- Run dry-run before paid generation.
- Dry-run metadata belongs in `logs/dry_run/`; do not overwrite real `assets/raw/**/*.meta.json` cost records.
- Keep small experiments under producer-approved budget.
- Record actual cost from `.meta.json` when summarizing results.

## Current Sprite Direction

- Field character sprites should be side-view / orthogonal / slightly top-down, not 45-degree isometric tile walking.
- Background scene illustrations may still use 45-degree or cinematic perspective.
- Current protagonist appearance lock:
  - cold grey cloth robe
  - white inner garment
  - dark belt
  - cyan-grey-green wine gourd
  - waist sword
  - dark short boots
  - black hair tied behind with simple dark hair band
  - no headscarf, forehead band, red hair tie, or top cloth strip

## Character / Scene Style Lessons

- Stage 2 v2 validation passed because images felt like "same artist, different people": varied faces and social roles, but consistent ink weight, thick painting, and wuxia atmosphere.
- Female NPCs must stay wuxia / Hong Kong comic, not anime-cute, Korean webtoon, Disney, or influencer-face.
- Armor and metal should stay hand-painted with ink outlines and chunky highlights, not 3D model render texture.
- Dark story scenes can shift cooler, but should keep saturated, readable color; do not make everything muddy or grey.
- Scene backgrounds may add contextual details like lanterns, wet stone, city gates, shop signs, and angled light, but those details must support the narrative and not become UI/text clutter.
- `docs/style-bible-prompts.md` still contains older IP-style examples; do not use it blindly for new generation until it is rewritten for 冷孤云 / 林西村 / 茗雾山庄.

## Sprite Sheet Lessons

- Individual large portrait-like sprites are not enough for in-game animation.
- Prefer sheet / strip generation for consistency.
- For 8-frame loops, include a 9th loop-check frame that repeats frame 1.
- Do not judge animation only from the raw sheet. Build GIF previews.
- Use fixed canvas and bottom-center anchoring to avoid preview jumps.
- `scripts/build_sprite_preview.py` can segment non-white columns and normalize frames.
- `scripts/qa/check_sprite_strip.py` can quantify detected cells, baseline spread, and height spread.
- `check_sprite_strip.py --expected` must match the source: 8 for pure animation strips, 9 for loop-check strips.
- The 9th loop-check frame is for validation only; import the first 8 frames into the game.
- Templates with external reference images should use `require_reference_images: true`; missing references must fail before paid API calls.
- Avoid relying on one user's `workspaceStorage` absolute reference path. Move important references into the repo before treating a template as reusable.

## Cost Control Rules For Unsolved Sprites

- Before any paid sprite generation, follow `docs/sprite-cost-optimization-plan.md`.
- Do zero-API diagnosis first: QA script, fixed-anchor GIF, prompt dry-run with `--force`.
- If the failure is crop/anchor/preview, fix post-processing, not prompt.
- If the failure is 8->1 loop seam, use 9-grid loop-check, not another ordinary 8-frame prompt.
- If the failure is identity drift, verify reference images exist before any generation.
- Paid generation should be one task at a time; do not batch four directions until the right-facing prototype passes.

## Known Good / Bad Evidence

- `sprite_lengguyun_walk_right_8f_strip.png`: detects 8/8, baseline spread 13 px, fails current 12 px tolerance.
- `sprite_lengguyun_walk_right_8f_loop_strip.png`: detects 9/9, baseline spread 7 px, passes current tolerance.
- `sprite_lengguyun_walk_down_8f_loop_strip.png` (front-facing): detects 9/9, baseline spread 5 px, height spread 5 px, PASS. Cost ¥0.1522.
- `sprite_lengguyun_walk_up_8f_loop_strip.png` (back-facing): detects 9/9, baseline spread 3 px, height spread 3 px, PASS. Cost ¥0.1526.
- `sprite_lengguyun_walk_left_8f_loop_strip_mirror.png`: per-cell horizontal mirror of right-walk baseline; preserves frame order; QA matches right-walk exactly. Cost 0 API.
- `sprite_lengguyun_walk_right_8f_stable_from_4f.png`: current right-walk 8f baseline from 4f interpolation; QA 8/8, baseline spread 4 px, height spread 4 px. Prefer over later polish because motion rhythm reads better.
- `sprite_lengguyun_walk_left_8f_stable_from_4f_mirror_play.png`: current left-walk 8f baseline, mirrored from right; QA 8/8, baseline spread 1 px, height spread 1 px. Cost 0 API.
- `sprite_lengguyun_walk_down_8f_stable_from_4f.png`: QA 8/8, baseline spread 1 px, height spread 1 px, but visual acceptance failed. The 4f reference has weak leg silhouettes, so the 8f result reads like subtle in-place stepping rather than walking. Do not treat as current baseline.
- `sprite_lengguyun_walk_up_8f_stable_from_4f.png`: QA 8/8, baseline spread 0 px, height spread 0 px, but visual acceptance failed for the same reason. Do not treat as current baseline.
- `sprite_lengguyun_walk_down_4f_strong_keypose.png`: QA 4/4, baseline spread 11 px, height spread 11 px, bbox width rhythm 180 / 128 / 187 / 133, but visual acceptance failed: left-right sway and 120ms preview too fast. Slow 180ms preview exists, but do not expand to 8f.
- `sprite_lengguyun_walk_up_4f_strong_keypose.png`: QA 4/4, baseline spread 5 px, height spread 5 px, bbox width rhythm 162 / 135 / 162 / 141, but visual acceptance failed: left-right sway and 120ms preview too fast. Slow 180ms preview exists, but do not expand to 8f.
- `sprite_lengguyun_walk_down_4f_locked_axis.png`: reduced sway but became too weak; raw QA baseline spread 21 px FAIL and processed width rhythm only 42 / 41 / 40 / 38. Failed comparison, do not use.
- `sprite_lengguyun_walk_down_4f_balanced.png`: current down 4f baseline for MVP. Raw QA baseline spread 17 px FAIL, but processed slow preview has stable center/height and width rhythm 47 / 39 / 49 / 40. Use processed sheet `sprite_lengguyun_walk_down_4f_balanced_slow.png`, not raw.
- `sprite_lengguyun_walk_up_4f_balanced.png`: current up 4f baseline for MVP. Raw QA PASS, processed slow preview stable center/height and width rhythm 47 / 38 / 43 / 37. Use processed sheet `sprite_lengguyun_walk_up_4f_balanced_slow.png`.
- `sprite_lengguyun_walk_down_8f_balanced_from_4f.png`: QA 8/8, baseline spread 1 px, height spread 1 px, but user reports feet still slightly uncoordinated. Keep as comparison, not final baseline.
- `sprite_lengguyun_walk_up_8f_balanced_from_4f.png`: QA 8/8, baseline spread 6 px, height spread 6 px, but user reports feet still slightly uncoordinated. Keep as comparison, not final baseline.
- `sprite_lengguyun_walk_down_8f_strict_phase.png`: QA 8/8, baseline spread 6 px, height spread 6 px, but strict natural-language foot phase did not improve the down-walk foot coordination. Width rhythm 44 / 43 / 38 / 38 / 45 / 40 / 43 / 42 is too flat. Do not generate up strict_phase unless user explicitly wants more API risk.

## Four-Direction Walk Strategy

- Current preferred side movement baseline is 8-frame `stable_from_4f`: right generated from 4f interpolation, left mirrored from right.
- Up/down `stable_from_4f` from the existing 4f candidates is not good enough visually; 4f `strong_keypose` also failed due to lateral sway. Next attempt must lock head/torso/waist centerline and reduce cloak sway; foot depth and knee pose should carry the motion.
- Use 160-180ms/frame for reviewing 4f up/down walk previews; 120ms/frame reads too fast and amplifies sway.
- For up/down 4f, a good target is processed center_x stable within ~0.5 px, center_y stable, and contact/passing width difference around 8-12 px. Larger silhouette swings read as sway; near-zero changes read as standing.
- For up/down 8f balanced expansion, reference the processed 4f slow sheet and map frames 1/2/3/4 to 1/3/5/7; keep 2/4/6/8 as small transitions. Always output both 120ms and 140ms GIFs.
- Up/down 8f interpolation can pass QA yet fail foot-phase review. If final quality matters, prefer the accepted 4f balanced slow loop until a stronger per-frame foot-phase strategy is used.
- MVP mixed-frame implementation is acceptable: right/left use 8f `stable_from_4f`; up/down use 4f `balanced_slow`. Player animation code must allow per-direction frame counts and slower vertical frame timing.
- Natural-language strict foot phase is not enough for front/back 8f. If revisiting, consider per-frame/manual/intermediate-frame workflows instead of one full 8f sheet generation.
- Older 9-grid loop-check assets remain useful as historical PASS references, but do not use the 9th frame for playback.
- Left is always derived from right by `scripts/mirror_sprite_strip.py`; never spend API on left if right has passed.
- Run paid generations one direction at a time. Always run `check_sprite_strip.py` and `build_sprite_preview.py` before deciding to generate the next direction.
- Up/down templates require `require_reference_images: true` and must explicitly forbid headscarf/forehead band, side-walk pose, and tile isometric perspective.
- If DMXAPI startup ping times out but recent dry-run is clean, one controlled `--skip-ping` paid attempt can be valid; document the reason and do not batch multiple directions.

## Current Sprite Import Lesson

- Protagonist movement is good enough to pause for now: right/left 8f, up/down 4f mixed-frame strategy can be reused by NPCs later.
- Current Godot-imported sprite strips originally showed a white background because source strips were RGB/opaque; `scripts/make_sprite_bg_transparent.py` now removes only edge-connected white background and preserves interior white clothing.
- Future character/NPC strips must deliver transparent PNGs or run this edge-connected white-background-to-alpha postprocess before `game/art/**` handoff.
- Do not simply key out all white pixels globally: 冷孤云 has white inner clothing. Transparency cleanup must target the edge-connected white background or use rembg/manual mask, otherwise costume details will be erased.
- NPC movement should reuse the same system contract as Player: per-direction texture, per-direction frame count, fixed 160x160-ish canvas, bottom-center anchor, and slower vertical timing when needed.

## Modular Scene Art Direction

- Stop treating whole-screen AI backgrounds as final gameplay maps; current backgrounds read more like loading/splash images than interactive spaces.
- Next scene art direction should use a modular 2D RPG environment kit: roads/ground tiles, building facade modules, roofs, trees/bamboo, rocks, signs, lanterns, crates, fences, bridges, and foreground occluders.
- Prefer reusable modules with palette/material variants over generating every scene as one unique illustration. Buildings can reuse silhouettes with changed color, scale, roof trim, signboard, and decoration density.
- For Godot handoff, art should provide module atlases / tilesheets plus placement references, not only cinematic full-background PNGs.

## UI Style Direction

- Main UI reference is `images/游戏主界面UI.png` for composition only: large Chinese title plaque, ornate wooden menu plaques, protagonist/role cards, vertical role tags, mountain-and-pavilion atmosphere, ribbon/cloud ornaments. Never use this reference image directly as the runtime background.
- Equipment UI reference is `images/装备界面UI.png`: left character display, center equipment slot grid, right parchment detail card, bottom attributes, top party portraits.
- Current UI direction is cold and gloomy: mountains, mist, pavilions, dark iron plaques, blue-grey borders, cloud patterns, cold parchment, frost-blue highlights, jade accents. Avoid orange/yellow warm-gold palettes, festive red silk, foreign mythology, demons, skulls, western runes, monster ornaments.
- UI art assets should be real game sprites/atlases, not only HTML/CSS mockups. Use `docs/art-ui-asset-kit-v1.md` and templates `ui_cold_wuxia_kit` / `ui_cold_wuxia_icon_atlas`.
- User accepted the generated UI style in `assets/raw/ui/cold_wuxia/v1/ui_cold_wuxia_common_kit_v1.png`; use it as the canonical visual reference for future UI assets.

- UI asset images must contain no English, no Latin letters, no fake text, and preferably no baked text at all. Render Chinese labels in Godot instead.
- Core attribute labels are: 筋骨、机敏、内劲、悟性、生命、内力、防御. Attribute icons should be textless but mapped to these names in metadata/docs.


- UI quality comes from whole-screen composition, not just prettier buttons. Menus need title plaque + framed content zones + role cards + bottom motto/version strip.

## Acceptance Before Handing to System

- No forbidden elements: headscarf, forehead band, red hair tie, spider/web, text, watermark.
- Baseline and height tolerance pass in QA script.
- GIF preview exists.
- Metadata exists beside raw image.
- If a texture path should be used by Godot, coordinate with `system` before moving final PNGs into `game/art/**`.

_Last updated: 2026-05-04（MVP 接入采用右/左 8f stable_from_4f + 上/下 4f balanced_slow 混合帧数方案）_
