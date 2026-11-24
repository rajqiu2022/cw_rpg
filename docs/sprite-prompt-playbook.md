# 主角 Sprite 提示词手记（v0.3）

## 2026-10-30m 五方向World桥图

独立promptset在assets/staging/world_bridges_20261030m/production；旧原93组件合成仅reference_only几何，不登记为生成美术。分别为5原方向生成完整原生桥，素材/朝向参照分开，不能把长石桥style图的长宽比误带到短宽桥；04前三稿拒，V4真实踏面与rail/立面分量另测才采用。所有图仅单一等比和微转，不拉伸；原RGB/主体RGBA保，框外A1+RGBA0补白按通用许可。看见灰halo须先查A0隐藏RGB，不以预览器颜色当不透明证；多余V5编辑明确弃用，9调用如实登记。当前五图和完整prompt见docs/changes/world-bridges-sect-adoption-20261030m.md。

## 2026-10-30l 采药与采矿劳动动作

独立登记`assets/staging/gather_actions_20261030l/production/prompts/tasks.yaml`及`templates/gather_action_4f.yaml`，原根tasks不改；项目renderer预检2组齐套真实v7右/下待机参考，内置各1次/无CLI或fallback。四帧明确准备/俯身或举镐/采摘或落镐/收势，锁七头身、蓝灰长袍/高马尾/酒葫芦/腰间鞘剑，同一右向微俯视而非方向turnaround。实际2172×724每格543；每格保护框外A1仅194/623点→0并各边32透明留白成607×788，不缩放或重画原RGB。按真实站姿128.52px定同一动作内scale，蹲下不能逐帧等高放大；每帧另设源脚，保持物理脚不变。左向运行镜像并公开说明。两GIF为按runtime配置脚锚的诊断图，不替代正式sheet。model/provider/cost工具未披露null；完整prompt/原图/当前消费者/处理证据见[本轮记录](changes/gather-actions-audio-20261030l.md)。

## 2026-10-28b 赤岩院界/前厅/普通掌柜配对

独立`assets/staging/redrock_luoyang_standard_20261028b/production/prompts/tasks.yaml`登记4ID与本地templates；内置各1次/无fallback、原PNG保持。女掌柜约48岁圆脸略壮、灰蓝工作衫与赭色围裙、低髻，非美颜年轻模板；portrait派发前真实renderer补已成sprite身份锚，另存portrait-reference-preflight，不能只沿建筑风格参考凭空重画脸。院界是整体U图，但工程按三个原生region脚层渲染，未本地裁片；A1仍全FAIL，只布局候选。详docs/redrock-luoyang-standard-20261028b.md。

## 2026-10-28a 赤岩六区装配补图

独立`assets/staging/redrock_town_20261028a/production/prompts/tasks.yaml`及`templates/redrock_town_module_20261028a.yaml`登记民居、牲口棚、层台岩坎3ID，各内置一次/无fallback或CLI；真实renderer先预检，根tasks保持。参考已选总规与25a驿舍锁平顶/红砂岩/上左光，不把概念裁成背景。3原图A1失败原样供布局草案，不清弱alpha/扩画布，也不将工程中有副本说成正式美术准入；大岩台实际比例必须按成图足体检查，提示词5:1不替代测量。工程路径与证据详`docs/redrock-town-20261028a.md`。

## 2026-10-25a 赤岩场景组件独立队列

`assets/staging/redrock_desert_life_20261025a/production/prompts/tasks.yaml`与`templates/redrock_desert_placeable_20261025a.yaml`登记8条，一图一ID，内置各一次，无CLI/fallback/重试；项目renderer仅本进程切模板目录，预检8项。参考已选总规（生活用途）和连体核心（相机材质），明确平顶/赤砂岩/小木构/透明场景实体，不把物件做背包图标。原图留白仍全FAIL，不能按提示词写了20%就声称满足。井棚和工作台alpha最大254，只报告实际值，不为满足测试改为255；诊断alpha128范围不替代A>0准入。详`docs/redrock-desert-life-20261025a.md`。

## 2026-10-25 NPC外貌：普通人优先，避免全员俊美

用户明确要求NPC不全部帅气漂亮。居民、店主、工匠和军士默认普通、自然、有生活经历的面容，不套主角式俊美脸/精修妆容。每名先确定年龄段、体型、脸型、肤色与衣着/职业特点，适度保留皱纹、晒痕、胡茬、发量差异；不是给同一张脸只换衣服。俊美只作少数角色特征，不擅改主角或已有关键角色辨识设计。

提示词描述具体人而非抽象“丑”：例如“中年圆脸、略胖、短胡茬、神情和气、干净旧布衫的掌柜”“年长瘦脸、额纹、略有晒痕、整洁围裙的手艺人”。禁止把普通人一律画成邋遢、滑稽或凶恶，也不将年长/贫穷等同反派。保持港漫厚涂与同一光照画法；精灵、头像和立绘应是同一个年龄、脸型与服装身份。验收看是否摆脱模板脸且职业可辨，不能仅凭新增文件宣称已替换。此节是后续制作规则，不代表已有NPC资源已更新。

## 2026-10-23b 并行制作使用独立art任务工作区

赤岩地表/坡道/护栏/脚锚修订5条任务位于`assets/staging/redrock_gate_20261023b/production/prompts/tasks.yaml`与其`templates/`；每条真实参考存在后调用同一项目renderer，在本进程指向独立模板目录，既有生成器源码与根tasks首末SHA保持。各ID内置一次，无CLI自动重试；新PNG在`assets/raw/redrock_ground_resources_20261023b/`。这是独立登记，不宣称工程根任务已合并。图像与运行限制见`docs/redrock-ground-parallel-20261023b.md`，后续批次需保单写权。

## 2026-10-23 赤岩关口组件与关卒首批模板

`redrock_cutout_20261023a.yaml`用于本批13条skip任务：6地图组件＋关卒idle，再引用idle做4下行帧和同人portrait，另登记一次关门净口修正版。按阶段真实reference存在后render_template预检，每ID内置1次，无CLI/fallback/自动重试。模板size/quality是登记请求，工具实际画幅不同照实记录，不冒尺寸或具体模型已固定。13完整A>0边距均失败；walk显著轮廓高/脚底差26/27px，非运行atlas；关门修正版门底仍不足320。原图不处理，细节见`docs/redrock-gate-resources-20261023a.md`。

## 2026-10-22 补充：门派与西域总规模板（非精灵）

`prompts/templates/sect_western_masterplan_20261022d.yaml`对应4个`*_plan_20261022d_overview_v1`任务：武当/茗雾/绿洲/赤岩，均skip、内置各1次、无CLI/自动重试，render_template预检通过。完整提示词在`prompts/sect_western_map_designs_20261022d/`；这是不透明整体设计，不继承本文精灵镜头/切格/alpha规则，也不代表NPC待机行走完成。设计来源/限制见`docs/sect-western-map-designs-20261022d.md`。模型工具未披露留空，不将模板size/quality宣称为内置可控参数或具体模型证明。概念小人包头造型不延用正式角色资源。

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

### 2.0.1 角色比例总控图（2026-07-28）

当 field 待机、行走和战斗资源出现身高或身材漂移时，禁止继续直接生成多方向图集。先用
`sprite_protagonist_body_standard_v1.yaml` 生成单一全身中性站姿候选，绑定主角立绘与已采用战斗攻击帧作为参考。

- 单图只验收：脸、发型、袍服、剑、单个灰绿酒葫芦及七头身中等体型。
- 该图获目视通过后，必须作为右走、上下走和四向待机的共同参考图。
- 不通过不得复制到 `game/art/**`，也不得用旧待机图拉伸或复用来补方向。
- ALAPI 偶尔会返回与 prompt 无关的文档/信息图；即使 PNG 与 meta 已落盘，仍必须人工审图后再采用。

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
