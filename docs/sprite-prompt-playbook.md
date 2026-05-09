# 主角 Sprite 提示词手记（v0.3）

> 2026-04-28：参考 [《游戏元素拆分 gpt-image2》](https://mp.weixin.qq.com/s/eLTx7bCpckLHfefR2M9l4Q) 的**分段结构化**写法，适配本项目 **港漫厚涂 2.5D**（非像素块），并与 `prompts/templates/_shared.yaml` 的 `style_anchor` 一致。
> 2026-04-30：sprite 仍未最终解决前，先按 `docs/sprite-cost-optimization-plan.md` 做零成本 QA / GIF / dry-run，再决定是否付费出图。

**镜头（v0.3）**：Field 里角色是 `Sprite2D` + **`flip_h` 左右镜像**（见 `game/scripts/field/player.gd`），贴图更像 **AVG 缩小侧向立绘**，不是斜 45° 地砖等距行走图。模板已统一为 **正交侧向、略俯视**；任务 id 里仍写 `_south_` 仅为历史命名，**不代表**场景地砖「南向」透视。

## 1. 仓库内对应文件

| 用途 | 模板 | `tasks.yaml` 任务 id |
|------|------|----------------------|
| 待机单帧（侧向 Field、白底、无参考图） | `sprite_protagonist_idle.yaml` | `sprite_lengguyun_idle_south` |
| 待机呼吸 **2 帧** | `sprite_protagonist_idle_anim.yaml` | `sprite_lengguyun_idle_anim_south_f01` / `f02` |
| 行走 **4 帧** | `sprite_protagonist_walk.yaml`（**f01**）+ `sprite_protagonist_walk_ref.yaml`（**f02～f04**，以 f01 为参考走 edits） | `sprite_lengguyun_walk_south_f01` … `f04` |
| 四向行走 **4×4 sheet** | `sprite_protagonist_walk_4dir_sheet.yaml` | `sprite_lengguyun_walk_4dir_sheet` |
| 向右行走 **8 帧 strip** | `sprite_protagonist_walk_right_8f_strip.yaml` | `sprite_lengguyun_walk_right_8f_strip` |
| 向右行走 **8+1 loop-check strip** | `sprite_protagonist_walk_right_8f_loop_strip.yaml` | `sprite_lengguyun_walk_right_8f_loop_strip` |
| 向下（朝镜头）行走 **8+1 loop-check strip** | `sprite_protagonist_walk_down_8f_loop_strip.yaml` | `sprite_lengguyun_walk_down_8f_loop_strip` |
| 向上（背镜头）行走 **8+1 loop-check strip** | `sprite_protagonist_walk_up_8f_loop_strip.yaml` | `sprite_lengguyun_walk_up_8f_loop_strip` |
| 向左行走（**右走镜像**，零 API） | `scripts/mirror_sprite_strip.py` | （后处理产物） |
| 林西基础剑法纵斩 **3 帧** | `sprite_protagonist_attack.yaml` | `sprite_lengguyun_attack_slash_south_f01` … `f03` |
| 拆件总图实验（默认不跑） | `sprite_protagonist_parts_sheet.yaml` | `sprite_lengguyun_parts_sheet`（`skip: true`） |

身份描述复用 `character_anchors.lengguyun`（与立绘一致）。**每张图一个 task id**，输出各自独立 PNG，便于 Godot `AnimatedSprite2D` / `SpriteFrames` 逐帧导入。

**行走一致性**：纯文多帧时模型容易每帧重画衣裤肤色酒壶鞋。当前约定 **f01 纯文出图**，**f02～f04** 固定引用 `assets/raw/sprite/v2/sprite_lengguyun_walk_south_f01.png` 走 `images.edit`，并在模板中设 `require_reference_images: true`，避免参考缺失时静默退回 `generations` 再次漂移。批量命令里 **务必将 `walk_south_f01` 排在 f02 之前**（见 §2.1）。换主角时需复制 `sprite_protagonist_walk_ref.yaml` 或改其中路径。

**外衣明度**：`walk_ref` 含 **色阶/明度/色温** 段；`color_stability_hint` 可按帧补强。行走 **下肢**：`tasks.yaml` 的 `leg_phase` 须写成「哪只脚在前、离地多高」等可读描述，避免 edits 把脚钉死在参考位置（详见 `experience-log` §15.7）。

**v3 方向**：新 Field 动画优先从 v3 sheet / strip 路线继续，不要再把 896×896 单帧大图当最终 sprite。v2 逐帧图保留为参考或备份；真正接入 Godot 前，应先有固定画布 GIF、QA 报告和明确的裁切规格。

**参考图防烧钱**：凡是依赖用户上传参考图的 sheet / strip 模板，必须设置 `require_reference_images: true`。如果参考图丢失，宁可 dry-run 报错，也不要静默无参考出图。

## 2. 如何跑图

```powershell
Set-Location F:\Code\RPG_GAME
# 只渲染 prompt，不花钱
python scripts/gen_assets.py --task sprite_lengguyun_idle_south --dry-run
# 若 assets/raw/... 下已有同名 PNG，dry-run 会整 task 跳过不写 meta；要看新 prompt 请加 --force
# 仅走 gpt-image-2、不要自动降级 gpt-image-1.5 时：`--fallback-model gpt-image-2`（与主模型同名则不会切 fallback）
# 正式出图（需 .env 里 API；DMXAPI 不稳时可加 --skip-ping）
python scripts/gen_assets.py --task sprite_lengguyun_idle_south
```

### 2.0 付费前零成本检查

sprite 未解决前，所有出图先过这三步：

```powershell
# 1) 渲染 prompt，不花钱；加 --force 避免已有旧图时看不到新 prompt
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_8f_loop_strip --dry-run --force
# dry-run meta 输出到 logs/dry_run/<task_id>.meta.json，不覆盖真实出图 meta

# 2) 对已有 strip 做量化 QA；9 格 loop-check 必须 expected=9
python scripts/qa/check_sprite_strip.py `
  --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png `
  --expected 9 --baseline-tolerance 12 --height-tolerance 24 `
  --report logs/qa/sprite_walk_right_8f_loop_strip.json

# 3) 生成固定锚点预览；不要直接用自动裁白边帧拼 GIF
python scripts/build_sprite_preview.py `
  --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png `
  --cols 9 --segment-columns `
  --sprite-height 96 --canvas-width 160 --canvas-height 160 `
  --duration-ms 90 `
  --output-gif assets/previews/sprite/sprite_lengguyun_walk_right_9f_check.gif `
  --output-sheet assets/processed/sprite/sprite_lengguyun_walk_right_9f_check.png
```

规则：

- 8 帧纯动画 strip：`--expected 8`。
- 9 格 loop-check strip：`--expected 9`，第 9 格只用于校验，导入游戏只用前 8 格。
- QA / GIF 都看完再决定是否重跑；如果只是裁切或锚点问题，不要消耗 API。

### 2.1 一次跑满「待机 2 + 行走 4 + 攻击 3」共 9 张

```powershell
python scripts/gen_assets.py --skip-ping `
  --task sprite_lengguyun_idle_anim_south_f01 `
  --task sprite_lengguyun_idle_anim_south_f02 `
  --task sprite_lengguyun_walk_south_f01 `
  --task sprite_lengguyun_walk_south_f02 `
  --task sprite_lengguyun_walk_south_f03 `
  --task sprite_lengguyun_walk_south_f04 `
  --task sprite_lengguyun_attack_slash_south_f01 `
  --task sprite_lengguyun_attack_slash_south_f02 `
  --task sprite_lengguyun_attack_slash_south_f03
```

输出目录：`assets/raw/sprite/v2/<task_id>.png`。

### 2.2 若连续 `APIConnectionError`

与 `docs/experience-log.md` §13.3 一致：渠道瞬时故障时，可**隔一段时间**再跑，或**一次只跑 1～2 个 task** 降低失败率；仍失败则检查本机网络 / VPN / DMX 侧状态。

拆件实验：在 `prompts/tasks.yaml` 里把 `sprite_lengguyun_parts_sheet` 的 `skip: true` 改为 `false` 后再跑；单张 **896²**（主角 sprite 模板统一画幅）**部件不宜过多**，通过后需人工裁切与描边修补。

**画幅**：`sprite_protagonist_*` 默认 **896×896**（小于 1024，仍满足 gpt-image-2 总像素下限；DMX 若报 `size` 不支持再改回 1024）。行走 f02～f04 依赖 f01 参考图，跑批时请 **`GEN_CONCURRENCY=1`**（或默认 1），避免并发写参考与读参考竞态。

### 2.3 8 帧循环的当前推荐

- 普通 8 帧 strip 容易第 8 帧接第 1 帧跳。
- 推荐生成 **9 格**：第 1～8 格为动画，第 9 格复制第 1 格作 loop check。
- 先让向右方向稳定，再复制到左 / 上 / 下；不要四方向同时盲跑。
- 已知对比：`sprite_lengguyun_walk_right_8f_strip.png` 基线极差 13px（FAIL），`sprite_lengguyun_walk_right_8f_loop_strip.png` 基线极差 7px（PASS）。

### 2.4 主角四方向（已 PASS，2026-05-01）

| 方向 | 来源 | raw / processed | QA JSON | 基线 / 高度极差 | 成本 |
|------|------|-----------------|---------|-----------------|------|
| 右（east） | gpt-image-2 付费基准 | `assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png` | `logs/qa/sprite_walk_right_8f_loop_strip.json` | 7 / 7 px | 已支付 |
| 下（south） | gpt-image-2 付费 | `assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_loop_strip.png` | `logs/qa/sprite_walk_down_8f_loop_strip.json` | 5 / 5 px | ¥0.1522 |
| 上（north） | gpt-image-2 付费 | `assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_loop_strip.png` | `logs/qa/sprite_walk_up_8f_loop_strip.json` | 3 / 3 px | ¥0.1526 |
| 左（west） | 右走镜像（零 API） | `assets/processed/sprite/sprite_lengguyun_walk_left_8f_loop_strip_mirror.png` | `logs/qa/sprite_walk_left_8f_loop_strip.json` | 7 / 7 px | 0 |

固定锚点 GIF / processed sheet 全部走 `--cols 9 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90`，输出到 `assets/previews/sprite/sprite_lengguyun_walk_<dir>_9f_check.gif` 与 `assets/processed/sprite/sprite_lengguyun_walk_<dir>_9f_check.png`。

`_9f_check.gif` 只能用于闭环校验，不要当最终播放效果看：第 9 帧刻意复制第 1 帧，循环播放时会多停一拍。实际预览 / Godot 导入使用前 8 帧：

```powershell
python scripts/build_sprite_preview.py `
  --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_loop_strip.png `
  --cols 9 --segment-columns --frame-count 8 `
  --sprite-height 96 --canvas-width 160 --canvas-height 160 `
  --duration-ms 80 `
  --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_8f_play.gif `
  --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_8f_play.png
```

四方向播放版文件：

- `assets/previews/sprite/sprite_lengguyun_walk_right_8f_play.gif`
- `assets/previews/sprite/sprite_lengguyun_walk_left_8f_play.gif`
- `assets/previews/sprite/sprite_lengguyun_walk_down_8f_play.gif`
- `assets/previews/sprite/sprite_lengguyun_walk_up_8f_play.gif`

如果 `_8f_play.gif` 仍显得两脚卡顿，根因通常不是锚点，而是模型生成的原始步态相位不均匀：某几帧姿态太接近，某几帧跨度过大。下一轮应改为“关键帧 + 过渡帧”生成纪律：先锁 4 个关键姿态（contact A / passing A / contact B / passing B），再用 edits 或参考图补 4 个中间帧；不要一次让模型自由生成 8 个阶段。

### 2.5 4 帧稳定候选（2026-05-01）

用户确认 8 帧版仍有明显抖动后，生产策略改为经典 RPG 4 帧：少帧数、强稳定、先可用。

新增右走重做模板：

| 用途 | 模板 | task id | 状态 |
|------|------|---------|------|
| 右走 4 帧稳定 strip | `sprite_protagonist_walk_right_4f_stable_strip.yaml` | `sprite_lengguyun_walk_right_4f_stable_strip` | 已通过 `.com` 域名生成，QA PASS |

新生成稳定版：

| 方向 | GIF | fixed sheet | QA | 成本 |
|------|-----|-------------|----|------|
| 右 | `assets/previews/sprite/sprite_lengguyun_walk_right_4f_stable_play.gif` | `assets/processed/sprite/sprite_lengguyun_walk_right_4f_stable_play.png` | `logs/qa/sprite_walk_right_4f_stable_strip.json` | ¥0.3241 |
| 左（右走镜像） | `assets/previews/sprite/sprite_lengguyun_walk_left_4f_stable_mirror_play.gif` | `assets/processed/sprite/sprite_lengguyun_walk_left_4f_stable_mirror_play.png` | `logs/qa/sprite_walk_left_4f_stable_mirror.json` | 0 |

QA：右走检出 4/4，基线极差 1px，高度极差 1px；左走镜像检出 4/4，基线极差 0px，高度极差 0px。

8 帧扩展试验：

| 用途 | 模板 | task id | 状态 |
|------|------|---------|------|
| 右走 8 帧（由 4 帧稳定版插补） | `sprite_protagonist_walk_right_8f_stable_from_4f.yaml` | `sprite_lengguyun_walk_right_8f_stable_from_4f` | 已生成，QA PASS |
| 下走 8 帧（由 4 帧正面候选插补） | `sprite_protagonist_walk_down_8f_stable_from_4f.yaml` | `sprite_lengguyun_walk_down_8f_stable_from_4f` | QA PASS，但视觉验收失败 |
| 上走 8 帧（由 4 帧背面候选插补） | `sprite_protagonist_walk_up_8f_stable_from_4f.yaml` | `sprite_lengguyun_walk_up_8f_stable_from_4f` | QA PASS，但视觉验收失败 |

| 方向 | GIF | fixed sheet | QA | 成本 |
|------|-----|-------------|----|------|
| 右 | `assets/previews/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.gif` | `assets/processed/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.png` | `logs/qa/sprite_walk_right_8f_stable_from_4f.json` | ¥0.2483 |
| 左（右走镜像） | `assets/previews/sprite/sprite_lengguyun_walk_left_8f_stable_from_4f_mirror.gif` | `assets/processed/sprite/sprite_lengguyun_walk_left_8f_stable_from_4f_mirror_play.png` | `logs/qa/sprite_walk_left_8f_stable_from_4f_mirror.json` | 0 |
| 下 | `assets/previews/sprite/sprite_lengguyun_walk_down_8f_stable_from_4f.gif` | `assets/processed/sprite/sprite_lengguyun_walk_down_8f_stable_from_4f.png` | `logs/qa/sprite_walk_down_8f_stable_from_4f.json` | ¥0.2496 |
| 上 | `assets/previews/sprite/sprite_lengguyun_walk_up_8f_stable_from_4f.gif` | `assets/processed/sprite/sprite_lengguyun_walk_up_8f_stable_from_4f.png` | `logs/qa/sprite_walk_up_8f_stable_from_4f.json` | ¥0.2494 |

QA：右走检出 8/8，基线极差 4px，高度极差 4px；左走镜像检出 8/8，基线极差 1px，高度极差 1px；下走检出 8/8，基线极差 1px，高度极差 1px；上走检出 8/8，基线极差 0px，高度极差 0px。

复核（2026-05-03）：上 / 下 `stable_from_4f` 虽然数值稳定，但视觉不如左右方向。原因是上 / 下 4 帧参考本身步幅轮廓很弱，扩展到 8 帧后各帧更接近，观感像“原地抖动 / 轻微踏步”，不作为当前推荐基准。右 / 左 `stable_from_4f` 仍是推荐基准；上 / 下需要先重做更明确的 4 帧关键姿态，再考虑扩展 8 帧。

上 / 下 4 帧强关键姿态候选（待用户目视确认）：

| 方向 | 模板 | task id | GIF | QA | 成本 | 状态 |
|------|------|---------|-----|----|------|------|
| 下 | `sprite_protagonist_walk_down_4f_strong_keypose.yaml` | `sprite_lengguyun_walk_down_4f_strong_keypose` | `assets/previews/sprite/sprite_lengguyun_walk_down_4f_strong_keypose.gif` | `logs/qa/sprite_walk_down_4f_strong_keypose.json` | ¥0.3118 | QA PASS，但左右晃动，视觉失败 |
| 上 | `sprite_protagonist_walk_up_4f_strong_keypose.yaml` | `sprite_lengguyun_walk_up_4f_strong_keypose` | `assets/previews/sprite/sprite_lengguyun_walk_up_4f_strong_keypose.gif` | `logs/qa/sprite_walk_up_4f_strong_keypose.json` | ¥0.3121 | QA PASS，但左右晃动，视觉失败 |

QA：下走检出 4/4，基线极差 11px，高度极差 11px；上走检出 4/4，基线极差 5px，高度极差 5px。两者相比失败 8 帧有更明显的 contact / passing 轮廓差，但用户反馈左右晃动且速度偏快。已生成 180ms/帧慢速预览：`assets/previews/sprite/sprite_lengguyun_walk_down_4f_strong_keypose_slow.gif`、`assets/previews/sprite/sprite_lengguyun_walk_up_4f_strong_keypose_slow.gif`。慢速只解决播放节奏，不解决素材内部躯干 / 袍摆左右摆动；该组不作为推荐基准。

上 / 下 4 帧 balanced 候选（2026-05-03，待用户目视确认）：

| 方向 | 模板 | task id | 慢速 GIF | QA | 成本 | 状态 |
|------|------|---------|----------|----|------|------|
| 下 | `sprite_protagonist_walk_down_4f_balanced.yaml` | `sprite_lengguyun_walk_down_4f_balanced` | `assets/previews/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.gif` | `logs/qa/sprite_walk_down_4f_balanced.json` | ¥0.3103 | raw QA baseline FAIL，但 processed 预览中心稳定，待目视确认 |
| 上 | `sprite_protagonist_walk_up_4f_balanced.yaml` | `sprite_lengguyun_walk_up_4f_balanced` | `assets/previews/sprite/sprite_lengguyun_walk_up_4f_balanced_slow.gif` | `logs/qa/sprite_walk_up_4f_balanced.json` | ¥0.3104 | QA PASS，待目视确认 |

processed 慢速预览量化：

- 下走：center_x 79.5 / 79.5 / 79.5 / 80.0，center_y 全 104.0，宽度 47 / 39 / 49 / 40。
- 上走：center_x 79.5 / 80.0 / 79.5 / 79.5，center_y 全 104.0，宽度 47 / 38 / 43 / 37。

这组比 `strong_keypose` 少左右晃，比 `locked_axis` 更有 contact / passing 差异。用户确认前不要扩 8 帧。

上 / 下 8 帧 balanced_from_4f（2026-05-04）：

| 方向 | 模板 | task id | GIF 120ms | GIF 140ms | fixed sheet | QA | 成本 | 状态 |
|------|------|---------|-----------|-----------|-------------|----|------|------|
| 下 | `sprite_protagonist_walk_down_8f_balanced_from_4f.yaml` | `sprite_lengguyun_walk_down_8f_balanced_from_4f` | `assets/previews/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_120ms.gif` | `assets/previews/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_140ms.gif` | `assets/processed/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f.png` | `logs/qa/sprite_walk_down_8f_balanced_from_4f.json` | ¥0.2476 | QA PASS，待最终目视确认 |
| 上 | `sprite_protagonist_walk_up_8f_balanced_from_4f.yaml` | `sprite_lengguyun_walk_up_8f_balanced_from_4f` | `assets/previews/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_120ms.gif` | `assets/previews/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_140ms.gif` | `assets/processed/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f.png` | `logs/qa/sprite_walk_up_8f_balanced_from_4f.json` | ¥0.2478 | QA PASS，待最终目视确认 |

QA：下走检出 8/8，基线极差 1px，高度极差 1px；上走检出 8/8，基线极差 6px，高度极差 6px。建议优先看 140ms 版，速度比 120ms 更接近当前审片反馈。

复核（2026-05-04）：用户指出上 / 下 8 帧 `balanced_from_4f` 两只脚仍有点不协调。量化看整体锚点稳定，但问题在脚步相位：8 帧插补把 4 帧中清楚的 contact / passing 关系抹平，部分中间帧像同一只脚在小范围变化，而不是左右脚自然交替。因此该组暂不作为最终基准；若不继续付费试错，上 / 下方向优先保留 4 帧 `balanced` 慢速版作为可用基准。

下走 8 帧 strict_phase 尝试（2026-05-04）：

| 方向 | 模板 | task id | GIF | fixed sheet | QA | 成本 | 状态 |
|------|------|---------|-----|-------------|----|------|------|
| 下 | `sprite_protagonist_walk_down_8f_strict_phase.yaml` | `sprite_lengguyun_walk_down_8f_strict_phase` | `assets/previews/sprite/sprite_lengguyun_walk_down_8f_strict_phase_140ms.gif` | `assets/processed/sprite/sprite_lengguyun_walk_down_8f_strict_phase.png` | `logs/qa/sprite_walk_down_8f_strict_phase.json` | ¥0.2501 | QA PASS，但脚步相位仍未改善 |

strict_phase 虽逐帧写明左 / 右脚状态，但模型仍把中间帧画得过于相似。下半身宽度节奏为 44 / 43 / 38 / 38 / 45 / 40 / 43 / 42，甚至比 `balanced_from_4f` 更平。结论：继续用整张 8 帧提示词强压脚相位收益很低，暂不生成上走 strict_phase。

**当前 MVP 推荐基准（2026-05-04 复核）：采用混合帧数方案。**  
右 / 左继续使用 `stable_from_4f` 8 帧；上 / 下使用已目视认可的 `balanced_slow` 4 帧。原因：上 / 下所有 8 帧扩展（`stable_from_4f`、`balanced_from_4f`、`strict_phase`）都出现脚步相位不自然，反而不如 4 帧 balanced 清楚；Seedance 视频方案因通道/成本问题暂停。

Godot MVP 接入文件：

| 方向 | 游戏内 PNG | 来源 | 帧数 | 建议播放 |
|------|------------|------|------|----------|
| 右 | `game/art/characters/lengguyun_walk_right_8f.png` | `assets/processed/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.png` | 8 | 0.10s/帧 |
| 左 | `game/art/characters/lengguyun_walk_left_8f.png` | `assets/processed/sprite/sprite_lengguyun_walk_left_8f_stable_from_4f_mirror_play.png` | 8 | 0.10s/帧 |
| 下 | `game/art/characters/lengguyun_walk_down_4f.png` | `assets/processed/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.png` | 4 | 0.18s/帧 |
| 上 | `game/art/characters/lengguyun_walk_up_4f.png` | `assets/processed/sprite/sprite_lengguyun_walk_up_4f_balanced_slow.png` | 4 | 0.18s/帧 |

注意：这四张 PNG 新接入 Godot 后，首次用编辑器打开项目会生成对应 `.import` 文件；若要提交游戏资源，连同 `.import` 一起检查。

右 / 左 8 帧 polish 对照仍保留，但不作为当前推荐：

8 帧 polish 版：

| 用途 | 模板 | task id | 状态 |
|------|------|---------|------|
| 右走 8 帧 polish（由 8 帧稳定版微调） | `sprite_protagonist_walk_right_8f_polish_from_8f.yaml` | `sprite_lengguyun_walk_right_8f_polish_from_8f` | 已生成，QA PASS |

| 方向 | GIF | fixed sheet | QA | 成本 |
|------|-----|-------------|----|------|
| 右 | `assets/previews/sprite/sprite_lengguyun_walk_right_8f_polish_from_8f.gif` | `assets/processed/sprite/sprite_lengguyun_walk_right_8f_polish_from_8f.png` | `logs/qa/sprite_walk_right_8f_polish_from_8f.json` | ¥0.2506 |
| 左（右走镜像） | `assets/previews/sprite/sprite_lengguyun_walk_left_8f_polish_from_8f_mirror.gif` | `assets/processed/sprite/sprite_lengguyun_walk_left_8f_polish_from_8f_mirror_play.png` | `logs/qa/sprite_walk_left_8f_polish_from_8f_mirror.json` | 0 |

QA：右走检出 8/8，基线极差 3px，高度极差 3px；左走镜像检出 8/8，基线极差 0px，高度极差 0px。该版量化对齐略好，但复核后发现动作轮廓被过度平滑，部分帧相似度更高，不作为当前推荐基准；只保留为实验对照。

当前临时可用候选来自已有 `assets/raw/sprite/v3/sprite_lengguyun_walk_4dir_sheet.png`，按行导出到固定 160×160 / 96px 画布：

| 方向 | GIF | fixed sheet | QA |
|------|-----|-------------|----|
| 右 | `assets/previews/sprite/sprite_lengguyun_walk_right_4f_sheet_play.gif` | `assets/processed/sprite/sprite_lengguyun_walk_right_4f_sheet_play.png` | `logs/qa/sprite_walk_right_4f_sheet_play.json` |
| 左（由右镜像） | `assets/previews/sprite/sprite_lengguyun_walk_left_4f_sheet_mirror_play.gif` | `assets/processed/sprite/sprite_lengguyun_walk_left_4f_sheet_mirror_play.png` | `logs/qa/sprite_walk_left_4f_sheet_mirror.json` |
| 下 | `assets/previews/sprite/sprite_lengguyun_walk_down_4f_sheet_play.gif` | `assets/processed/sprite/sprite_lengguyun_walk_down_4f_sheet_play.png` | `logs/qa/sprite_walk_down_4f_sheet_play.json` |
| 上 | `assets/previews/sprite/sprite_lengguyun_walk_up_4f_sheet_play.gif` | `assets/processed/sprite/sprite_lengguyun_walk_up_4f_sheet_play.png` | `logs/qa/sprite_walk_up_4f_sheet_play.json` |

QA 结果：右 / 左基线极差 1px，高度极差 1px；上 / 下基线极差 0px，高度极差 0px。

导出命令示例：

```powershell
python scripts/build_sprite_preview.py `
  --source assets/raw/sprite/v3/sprite_lengguyun_walk_4dir_sheet.png `
  --cols 4 --rows 4 --row 2 `
  --sprite-height 96 --canvas-width 160 --canvas-height 160 `
  --duration-ms 140 `
  --output-gif assets/previews/sprite/sprite_lengguyun_walk_right_4f_sheet_play.gif `
  --output-sheet assets/processed/sprite/sprite_lengguyun_walk_right_4f_sheet_play.png
```

注意：原 4dir sheet 的左走行顶部带有上一行残留，导出时可用 `--cell-top-inset 24` 裁掉跨行残留；最终推荐左走直接由右走镜像，避免左右节奏不一致。

#### 左走镜像

```powershell
python scripts/mirror_sprite_strip.py `
  --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png `
  --output assets/processed/sprite/sprite_lengguyun_walk_left_8f_loop_strip_mirror.png `
  --expected 9
```

镜像走逐格水平翻转（保留帧顺序），不做缩放，因此 QA 数据与右走完全一致。镜像产物只放在 `assets/processed/sprite/`，**不要**进入 `assets/raw/sprite/v3/`，便于回溯它来自后处理而非 API。

## 3. 与原文章差异（避免预期错位）

| 原文侧重 | 本项目 |
|----------|--------|
| 像素 sprite + 极细五官分层 | 港漫风、单帧相对「整」；拆件模板刻意减少块数，避免糊成一团 |
| 深色或透明底 | 与现有管线一致：**纯白底** `#FFFFFF`，便于 `rembg`（见 `docs/art-pipeline.md`） |

## 4. 接入 Godot（后续）

- 当前战斗/场景若引用 `res://art/characters/...`，出图通过后请将 PNG 从 `assets/raw/sprite/v2/` 拷到版本跟踪目录（与 `art_validation_v2` 流程一致），再在编辑器里绑定 Sprite / TextureRect。
- v3 sheet / strip 接入前，先由 `art` 提供：raw、processed sheet、GIF、QA JSON、裁切参数；再交 `system` 绑定 `AnimatedSprite2D` 或 `SpriteFrames`。
