# 2026-11-06 下一批四族 NPC：只读制作候选

排除原已正式农人，以及本轮2正式+10候选共12族后选取。继承 `source_reference_inventory.json`、`action_coverage.json` 及finish8动态补表，不启动引擎、不重跑全量parse、不改任何素材或adapter。本表是候选，不是已接入。

计数是静态引用覆盖上界，包含剧情或fallback，不冒充每一活跃spawn。路径均相对仓库；`res://`相对game。原主角高度、脚点、碰撞、身份/任务保持，绝不通过放大旧160格冒高清。

## 1. 抱书书生：优先复用

- Family：`npc_luoyang_paper_scholar`，普通抱书文人，现有范围仅下向1静帧。
- 当前：`res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png`，160×160，alpha24主体116。
- 原RAW：`assets/staging/luoyang_scholar_20261024a/scholar_idle_v2_raw.png`，SHA `36d5a7614ef617854677092bbce1b3f46c02e8881a34f504158403f796b5537e`。
- 可复用授权母图：同目录`scholar_idle_v2_clean_padded1440.png`，RGBA1440×1440；alpha24 bbox `(538,235,912,1273)`，真实主体1038px。`authorized_cleanup_actual.json`记录仅56个外围alpha1清除、93px补白、全RGB/保护RGBA精同；非放大产物。
- 正式映射：`game/scripts/field/field_walkable_controller.gd`精确`ch4_s3_luoyang_market/luoyang_paper_scholar`，以及`luoyang_environment_layer_20261022ap.gd`；汴州/金陵field和author、清河author/settlement_field亦引用（共8静态消费者）。
- 只替精sprite source，保专用头像、纸贵任务、adult calibration/脚点；不新增或宣称walk/四向。

## 2. 护商镖师：右向walk可复用，idle尚需重制

- Family：`npc_escort_guard`，黑衣佩刀护商镖师/巡捕/守山弟子；**不是**已列本轮的`npc_zhuwei_escort`。
- 当前idle：`res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png`，640×160、4下向idle、主体126px。
- 当前walk：`res://art/characters/street_expansion_v2/npc_escort_guard_walk_right_8f_v1_runtime.png`，1280×160、8右向walk、主体140px；左向沿既有镜像映射，不能冒独立左向母条。
- 原RAW及透明母条：`assets/raw/sprite/npc/escort_guard_walk_codex_builtin_v1/npc_escort_guard_walk_right_8f_v1.png`及`npc_escort_guard_walk_right_8f_v1_alpha.png`。同目录manifest记录已采用来源、身份与动作及旧抠底流程；原SHA `d27b488f3ae52f117dc1b612d7109669af1a76193c498189932895e9fc8bbe34`。
- alpha母条RGBA1983×793，8等分格alpha24主体依次415/412/416/412/414/415/411/416px；须审真实分格、边缘和脚点后无损整数平移/等格拼接，不能直接将非整除8画布按等宽截断。旧抠底母条是否接受由Root看原图决定。
- idle仅找到共享`assets/raw/character/expansion_20260805/npc_street_archetypes_idle_4x4_v1_alpha.png`，1536×1024行高256，不能冒320原生body；不拿walk静置冒idle重制完成。
- 正式source map：`game/data/npcs/npc_catalog.tres`的`patrol_scout/ch1_s2_qingfeng`；`openworld_wudang_gate.tres`的`wudang_gate_disciple`；两`luoyang_*life_crowd*.gd`及现汴州author。总19静态idle引用，walk3引用，旧洛阳gate/yamen等原始声明可能已被专用军士覆盖，不能按19现役实例计。

## 3. 行商：高覆盖，原RAW不达高清门槛

- Family：`npc_street_merchant`，普通斗笠商贩/货郎，保普通人的面貌与衣物，不做俊美主角。
- 当前：`res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png`（4下向idle、主体140px）；同目录`npc_street_merchant_{down,up,left,right}_walk_8f_v3_runtime.png`，既有4向各8walk。
- 原RAW：`assets/raw/character/expansion_20260805/npc_street_merchant_walk_8x4_v1.png`及`..._alpha.png`；idle共享`npc_street_archetypes_idle_4x4_v1_alpha.png`。继承`ten_source_pixels.json`：walk1536×1024，32格主体218–230px，不可直接升级为320HD，不重测/不放大。
- source map：catalog`merchant/ch1_s2_qingfeng`；现汴州/金陵/清河/襄州author、两洛阳life crowd；另白鹿渡、东海埠、林西和剧情场景原始行。26静态引用中2是本轮candidate，排除后24；不冒24个活跃NPC。
- 需按现身份重制所用idle与4向walk，保原conversation解析方向；不能仅按文件left/right名称纠正后又造成倒走。

## 4. 废宅守卫：剧情覆盖，RGB源不能直接接入

- Family：`npc_west_ruin_guard`，废宅/矿场/营地看守；当前`res://art/characters/npc_west_ruin_guard_idle_down_25d_4f.png`，640×160、4下向idle、主体140px。
- 原RAW：`assets/raw/sprite_sheet/npc_west_ruin_guard_idle_source_v1.png`，1774×887 **RGB无透明通道**。全画布alpha255的887px不能当真实人物高度；本次不做本地品红抠底，需imagegen透明重制或找到另已授权透明源后再判。
- 10 authored消费者：`ch1_s3_west_ruin`（`ruin_outer_guard`，保`defeated_zhuwei_bandit`隐藏旗）、`ch2_s5_mine_command`、`ch2_s5_mine_workshop`、`ch6_s3_underground_archive`、`ch6_s4_baishui_convoy_route`、`ch7_s3_lieyun_outpost_outer_ward`、`ch7_s9_mingwu_seal_audit_room`、`ch8_s2_mistwood_blockade`、`ch8_s4_alliance_mechanism_gallery`、`ch8_s5_alliance_ceremonial_platform`，位于`game/data/scenes/`。
- 只有现有down4idle范围，不擅造四向动作完成量；不改变剧情出现/隐藏、敌我或战斗身份。

## 动态与剩余边界

finish8当前8payload的`new_NPCs`继承先前只读补表：7包0条、Estate2条，只有农人与小二，均已在处理集合，不增加漏族。本表不重读payload、不扩大成原parent NPC全人口统计。以上2项存在高清复用机会，其中护商镖师仅walk；另2项需要真正重制。四族都未由本表安装或验收。
