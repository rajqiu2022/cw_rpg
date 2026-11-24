# 洛阳居民运行时审计 · 2026-10-19v

范围：只读审计现行 Gate／Market／Yamen／Docks／Temple，并新增独立候选 selector；未改正式 C／Field／Router／存档／catalog，未启动 Godot，未重跑 u 四原子，也未发起配音或图片生成。以下为定义与路径覆盖统计，不是新一轮实机或艺术验收。

## 结论

1. 新增的 36 个生活 NPC 不是点击系统坏了：两个 crowd `project()` 明确写入空 `dialog_id` 和空 `interaction_action`，所以 `NPCNode.try_interact()` 最后返回 false。
2. 不能直接把这 36 个 ID 加进 `npc_catalog.tres`：`Field._spawn_npcs()` 对带 `harbour_life_ground_anchored`／`district_life_ground_anchored` 且已有 profile 的行直接设置 `_field_loading_failed` 并拒绝。这是身份保护，不得去掉；否则会再次 Loading 后回大地图。
3. 现有资源不是一人一套：36 人主要复用商人／军士／农人／小二／菜贩；码头两岗位已换专用单帧，古寺两僧共用单帧僧人。专用半身头像仍少，很多仅由 ID 猜年龄和性别。
4. 配音目前是预生成 MP3 + 路径约定，不是运行时本地 TTS。扫描本次有限 40 个可达对白 family，39 个没有 MP3；只有 `ch4_canal_result` 存在 2 个 MP3，不能据此授整段完整语音。现行 20 个 task overlay 和 15 个 t successor family 共 35 个全部无 MP3。

## 1. 五场景定义盘点

“槽位”按原 Scene + 已正式投影定义统计，条件 NPC 也计入；两个脚夫互斥、封砚秋／都头／终局吏有剧情门槛，因此不是新游戏同屏人数。动作 NPC 可交互不等于可家常聊天。

| 场景 | 原 canonical 槽位 | 后继任务／真人增量 | 生活投影 | 合计 | dialog 入口 | spar／shop 动作 | 空聊生活 NPC |
|---|---:|---:|---:|---:|---:|---:|---:|
| 南城门 | 1 | 0 | 10 | 11 | 1 | 0 | 10 |
| 南市 | 8 | 1 老纸匠 | 10 | 19 | 4 | 5 | 10 |
| 府衙 | 3 | 0 | 6 | 9 | 1 | 2 | 6 |
| 漕渠码头 | 3 | 1 漕工头领 | 10 | 14 | 4 | 0 | 10 |
| 城外古寺 | 0 | 2 僧人 | 0 | 2 | 2 | 0 | 0 |
| 总计 | 15 | 4 | 36 | 55 | 12 | 7 | 36 |

旧 15 槽位均有 sprite；原始字段仅封砚秋显式指定 portrait，门吏经 catalog 补专用头像，其余 13 使用通用默认（对白 speaker 不匹配时仍可能不显示）。后继新增 4 人均有 sprite，老纸匠显式通用年长男头像、两僧显式同一全身 sprite 作临时 portrait，漕工头领仍通用；36 生活投影全部有 sprite、无显式独立 portrait、无对白、无语音。全 55 槽位的字段层面 explicit portrait 为 5（门吏／封砚秋／纸匠／两僧），其中真正专用 portrait 仅前两项；不把路径存在算身份艺术通过。

### 南城门 ID

- 原：`luoyang_gate_sergeant` → `openworld_luoyang_gate_sergeant`，军士 sprite；catalog 仅补成熟门吏 portrait。
- `harbour_life_` 前缀十人：`gate_waiting_merchant_a`、`gate_pack_carrier_a`、`gate_patrol_west`、`gate_waiting_merchant_b`、`gate_patrol_east`、`gate_pack_carrier_b`、`gate_waiting_traveller_a`、`gate_waiting_traveller_b`、`gate_supply_attendant`、`gate_check_assistant`。全部空聊，6 人有真实 walk strip，4 驻留。

### 南市 ID

- 原：`spar_luoyang_shen_guard`、`spar_luoyang_examiner`、`spar_luoyang_blademaster`、`spar_luoyang_patrol`（4 个 spar）；`luoyang_armorer`（shop）；`feng_yanqiu_ch4`（`ch4_guyun_sword_notches`）；`luoyang_paper_scholar`（现由 task projection 选择 paper offer／progress／report／after）；`luoyang_poetry_host`（现由 t projection 选择 peony 五阶段）。
- 新任务人：`luoyang_paper_artisan_20261016`（artisan daily／paper hint／ready／after，不能被新日常入口覆盖）。
- `district_life_` 前缀十人：`market_courier`、`market_patrol`、`market_broker`、`market_guest`、`market_buyer`、`market_herb_buyer`、`market_shop_attendant`、`market_farmer`、`market_tea_guest`、`market_traveller`。全部空聊，4 真巡游／6 驻留。

### 府衙 ID

- 原：`spar_yamen_patrol`、`spar_yamen_captain`（spar）；`ch8_luoyang_final_clerk`（`ch8_aftermath_luoyang`，终局任务门槛）。
- `district_life_` 前缀六人：`yamen_west_patrol`、`yamen_south_runner`、`yamen_guard`、`yamen_clerk`、`yamen_petitioner`、`yamen_guest`。全部空聊，2 真巡游／4 驻留。

### 码头 ID

- 原：`canal_endangered_porter`（`ch4_canal_battle`）、`canal_saved_porter`（`ch4_canal_result`）、`canal_old_soldier`（现 task hanjia／canal witness）；后继 `canal_work_chief`（现 task canal offer／progress／report／after）。
- `harbour_life_` 前缀十人：`docks_rope_carrier`、`docks_goods_broker`、`docks_quay_patrol`、`docks_southern_carrier`、`docks_west_carrier`、`docks_departing_merchant`、`docks_store_attendant`、`docks_loading_attendant`、`docks_rope_seller`、`docks_booking_attendant`。全部空聊，6 真巡游／4 驻留。loading／booking 两 exact ID 经 office helper 仅换专用单帧 sprite，没有顺带新增对白。

### 古寺 ID

- `temple_cave_keeper_20261018t`（守窟僧 longmen）；`temple_bell_keeper_20261018t`（守钟僧 baima）。实际 source-bound NPC，不是旧无形 hotspot；共享 `npc_temple_gate_monk_idle_down_1f_v1.png`，`portrait_path` 也等于此 160×160 全身图。代码明确承认临时身份图而非 final portrait-art。

## 2. 头像／对话／声线实际接入点

| 真实文件／函数 | 当前规则与扩充注意 |
|---|---|
| `game/scripts/domain/npc_profile.gd`、`npc_catalog.gd::find` | profile 键为 exact npc_id + scene_id；有 sprite／portrait／walk／scale／default_dialog，无 voice_id。 |
| `game/scripts/field/field_walkable_controller.gd::_spawn_npcs`（1701 起） | 场景字典→默认头像→catalog override→身份冲突保护→脚位／巡游／动画。原地生成前必须先设 position，不能动巡游原点或成人校准。 |
| 同文件 `_generic_npc_portrait`（3756 起） | 猜 ID，不看人物姓名：含 `guest` 一律年轻女性；`market_buyer` 无 woman/vendor 标记而落年轻男性；`old/keeper`→年长男性。`market_guest` 男商人／`yamen_guest` 百姓因此可能借女性头像。这是候选逐角色显式绑定要解决的缺口，不应全局改猜词回归其它城市。 |
| `game/scripts/field/npc_node.gd::try_interact`（427 起） | 118px 距离兜底；action 优先，再 `_resolve_dialog_id`；均空就 false。 |
| `_resolve_dialog_id`（450 起） | variants first-match：require_flags 全 true、hide_flags 全 false；支持 require_quest_active／completed、hide_quest_active，然后 base dialog。可用于阶段变化，无需改 save schema。 |
| `Field::_on_npc_interacted`（3567 起） | 先 task allow → 确认 `res://data/dialogs/<id>.tres` → 记安全脚位 → 保持同一 NPC 交谈朝向 → default portrait／speaker → DialogPlayer。现有纸匠 task primary 必须保持。 |
| `game/scripts/autoload/dialog_player.gd::_show_node` | `node.portrait_path` 第一；点击 NPC 默认图只用于空 speaker 或 speaker==NPC 名字；然后少数 SPEAKER_PORTRAITS。不会自动替所有不同姓名猜图。 |
| `game/scripts/ui/dialog_box.gd::_on_text_displayed` | 直接加载传入 portrait_path 显示于现有 TextureRect；当前无独立全身立绘与圆头像双字段，不声称已有双图 UI。 |
| `game/scripts/domain/dialog_node.gd` | `voice_emotion` 有显式枚举；无 voice_path／voice_id 字段。常驻闲聊使用零 give_items／gold／accept／complete 等副作用。 |
| `DialogPlayer::_play_node_voice`（387 起）／`_prewarm_voices` | 根据实际 DialogScript.dialog_id、effective speaker、node_id、emotion 组成路径；首 segment 存在优先整套 segment，其次情绪文件，再旧普通文件。改 speaker 或声线不能只重做普通 fallback，旧 segment 仍会抢播。 |

另有三个明确的 speaker/身份错配：`luoyang_paper_scholar` 显示“南市书生”，task 台词 speaker 为“左明远”；`luoyang_poetry_host` 显示“牡丹诗会主持”，台词为“诗会执事”；`canal_saved_porter` 显示“获救脚夫”，自己的若干台词仍为“失踪脚夫”。这些节点无自己的 portrait，默认图不能跨名字兜底；后续逐身份明示 portrait 或统一正确角色称谓，不能仅把 NPC catalog 填满就算头像覆盖。

## 3. 配音生产、检查与范围

当前可用生成器 `scripts/gen_dialog_voices.py`：Edge TTS `edge_tts.Communicate`，`VOICE_MAP[speaker]` + `CHARACTER_PARAMS` + 情绪参数。2026-10-19 仅离线 `importlib.util.find_spec` 确认本机 Python312 已安装 edge_tts，没有发起网络请求。未发现仓库现成“本地对白 TTS HTTP 服务”；`tools/audio/ace_venv`／ACE-Step／Stable Audio 是音乐／音效路线，不能当已接配音服务。

- 非联网检查：`python scripts/gen_dialog_voices.py --dialog ch4_resident_v_market_buyer_daily --dry-run`。它只解析与列出，不输出音频；import 包存在不等于云服务可用。
- 本轮新 12 个对白是 flat ch4 ID，可被现行生成器 glob 捕获；旧 `luoyang_city_tasks_20261016/` 和 t 子目录不被该生成器的 `DIALOG_DIR.glob("*.tres")` 扫到，`--dialog 子目录/id` 也会被 flat 列表过滤成零条。后续应 NEW 生成适配器显式白名单输入，不能为配音搬移正式 Dialog ID。
- 生成命令（后续单句、经授权才跑）：`python scripts/gen_dialog_voices.py --dialog ch4_resident_v_market_buyer_daily --speaker "采买妇人" --node start`。现脚本会直接写正式 `game/art/audio/voices/ch4/...` 并覆盖同名文件，无 staging 参数／重试台账／来源 manifest；因此本次不执行。先做隔离输出 manifest：text SHA、speaker、voice、rate/pitch/volume、emotion、生成器 SHA、输出 SHA／大小／时长，再 root 晋升。
- 目前女性“采买妇人”不在 VOICE_MAP，会落默认男声；不能拿 dry-run 的行数当女声已接。新声线映射应由对白生成候选控制，人物与 portrait／sprite 身份一致。
- 若将来确有本地 TTS，健康检查应依据实际服务脚本确定 endpoint，先只读进程／监听端口，再无生成的 health/model-status；本次不猜 URL，不启动服务，不打印凭据。Edge 云连接是否可用在本次未测。
- 音频验收分开记：文件完整性与路径命中、实际播放、说话人／情绪试听、推进取消旧语音；原 WASAPI fallback 与退出纹理告警不能冒 clean audio。

有限 voice family 盘点由 5 legacy（门吏、封砚秋、终局吏、两脚夫）+20 task overlay+15 t successor 构成，共40；未递归整个 voices／build 树。`ch4_canal_result` 的 2 文件不是所有 node 或 segment coverage，其余39零文件。此统计不包括尚未正式的 v 新12对白，也不借旧同名 ch4 offer 的语音给新命名空间记覆盖。

## 4. 不触正式加载链的首批候选

NEW `game/scripts/city/luoyang_resident_life_candidate_20261019v.gd`：`FORMAL_ENABLED=false`，没有任何生产调用点；默认游戏不会加载它。manifest `game/data/luoyang_residents_20261019v/manifest.json`（E0B4BCE63AD9B628EAA6D63C57A918DD026705DA181D90F4E9C0801E40601BAF），四居民／12新对白由 Lore 供给。

- `readiness()`：manifest SHA、4 exact npc_id／scene、12完整对白 SHA、每个 DialogScript.dialog_id 与 basename 完全相同；缺文件／额外键／变源显拒。
- `source_paths()`：仅成功才返回 SELF+manifest+12对白共14叶；不把根目录递归扩成全工程。
- `stage`／`dialog_for`：只读 flags／quest-state 字典；bool flag + int 0..3；completed-state 2 且 completed_flags 全真优先 after，active-state1 且 active_flags全真→uncertain，其余daily；旧 solved flag 单独不算通关。不发奖／置旗／接受任务。
- `choices_for`：给一条当前阶段“聊聊近日城中生活”的独立计划；不是已实现的通用菜单。
- `project_copy`：先 deep copy 已有 NPC Array，限定 exact四人；三生活 NPC 原 dialog/action/variants 必须全空才只增 dialog_id；原位置、scale、sprite、portrait、body／巡游保持。纸匠的 `luoyang_city_tasks_20261016/` primary 全保，日常只返独立 choice plan，避免抢 hint／报告；Field 目前不消费该 plan，不能说纸匠新日常已接。

四人：老纸匠、南市采买妇人、码头装卸伙计、城门货担主人。新对白均零任务副作用，情节语境取已核 paper/canal 状态；跨章节更长生活弧线需要后续逐章 authored 状态，不能把一次换台词宣传成贯穿全故事。

本模块只完成 source-ready 候选，Godot proper／实际 selector／UI预览由 ROOT 新薄键一次执行；本审计没有冒称已运行。

## 5. 正式发布的最小闭包（不得直接改旧冻结 source）

1. 新白名单候选：selector、4居民manifest、12dialogs、具体 sprite／portrait／avatar（含导入 .import 与 compiled .ctex）、显式voice manifest／每条被选MP3与import/compiled依赖；原资产若复用须 exact ID 与 SHA。图像 proof 要全 RGBA／实际 cell／脚锚；不能拿 portrait 兼 sprite。
2. 选择正规投影层：现 `CITY_TASKS.project` 后、Harbour/District追加 NPC 后的运行字典才含四 exact ID。新增 layer 必须把实际源集合接进完整 collector；不能改 catalog 偷绕冲突、不能在检验之后偷偷改 Scene／加载旧缓存。
3. 现四区 `luoyang_precomputed_bundle_20261018r.gd::source_paths/describe`、当前 index与4 manifest 使用完整来源映射，C `_transition_sources` 首末核全；任何实际生产调用方字节变化都需显式 previous→successor 迁移，保历史 publication proof、几何 artifacts和原 current-source keyset，不允许只更新一条SHA或忽略字段。未改的区也可能共享该脚本，因此必须按真实依赖求传播闭包，而不是口头只改一城。
4. Temple 是独立 source owner，`luoyang_temple_assembly` 的 binding、source_paths、首末hash与Field/Router/C等有显式依赖。若正式调用方改了这些共享源，要 NEW Temple binding 明示 successor，不篡改旧 parent first/final；不需要重做 Temple几何。
5. Loading驻留缓存若需消费居民进度，先复用原 dirty refresh和 exact source owner；保 task primary、安全返脚、强Field/Player/Scene身份。候选 proof不能冒正式当前source信用。
6. 验收限四居民：一代表正式入城、每人一条正常 Space／头像／语音、状态daily→uncertain→after且任务主入口不受损、离开返场常驻；只检查改动闭包，禁止再全城／十室内整夜重复。保存只用隔离内存／测试user目录，不写玩家槽位。

完成：有限现状盘点、真实接口与风险定位、NEW selector source-ready。待办：ROOT 薄键 proper/候选实际、素材与语音单样件、逐人预览，随后再授权正式接线；当前正式 u 地图保持。
