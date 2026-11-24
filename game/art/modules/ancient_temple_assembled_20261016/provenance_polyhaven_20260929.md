# 新版大地图外部授权素材登记 · 2026-09-29

核验依据：Poly Haven 官方[许可页](https://polyhaven.com/license)与下列各资产页面均标为 CC0。CC0 只适用于这些具体外部文件及其加工件，不应推断本仓库其他图片同样授权；发布前应复核打包清单。公共API仅用于下述定向资产文件清单，不抓取整个素材库，也不供游戏运行时联网。

## 2026-10-02 · 第六局部地表候选

第九 v8b 候选（构建源 `11D1A583…DBEF3B1C`）撤下六个裁切 Rock Face proxy 运行实例，改为已登记 [Boulder 01](https://polyhaven.com/a/boulder_01) 的18块独立三维岩体，逐实例输出透明原body、完整XZ阻挡、实际脚底Y和真实caster。原始五文件逐SHA仍与登记表一致，没有新下载或重新生图；六处旧碰撞包络不扩大，源与投影包络独立检查。Rock Face 文件只作历史来源证据保留，不代表仍渲染到地图。北部局部实渲及严格重复通过，当前正在完整地图／Field验收，**尚未正式激活**。其他城池与桥梁仍属项目既有原创加工件，不随外部素材改标CC0。

第九源另定向取得 [Grass Ground](https://polyhaven.com/a/grass_ground) 三张2K JPG diffuse／OpenGL normal／ARM；作者Charlotte Baglioni、[CC0许可](https://polyhaven.com/license)，官方info API实际宽高约2510毫米，按2.51m使用。三图13,605,640字节官方MD5及size全部一致，逐SHA和颜色空间见 `game/art/external/polyhaven/world_terrain_v14_ninth/grass_ground/SOURCE.json`；脚本 `scripts/fetch_world_v14_ninth_pbr.ps1` actualexit0。主控读取原diffuse为绿棕短草，不宣称青翠森林；候选未生产批准、无账号或费用。

第九独立岩体候选另从已登记本地raw精确复制Rock Face 01的五份文件至 `game/art/external/polyhaven/world_native_v14_ninth/rock_face_01/`，两边逐SHA相同；glTF SHA `96c332c01d173a2431115f3bac29be101fba341e5500e2a08e384f4edd17299e`。这是既有 `rock_face_section_1_proxy`，11,106 positions／20,174 triangles，不冒称新下载的官方完整岩壁或新建terrain mesh。来源记录明确本地精确copy、无新的official MD5断言，原raw保留。每个实例仍须独立alpha／实际脚底阻挡／Y前后层级／caster验收；九版尚未视觉批准，旧Rock Face试样的拒绝记录不改。

重新核验官方许可与[API条款](https://github.com/Poly-Haven/Public-API/blob/master/ToS.md)，使用项目标识`CloudShadowRPG-AssetPipeline/1.0 (+https://github.com/rajqiu2022/cw_rpg)`定向下载四种真实可重复地表。每种仅2K JPG diffuse／OpenGL normal／ARM三通道，全部12文件的官方MD5和大小校验通过，共42,038,318字节；执行脚本`scripts/fetch_world_v14_sixth_pbr.ps1`实际exit 0。逐文件SHA、官方URL、颜色空间及物理宽度登记在`game/art/external/polyhaven/world_terrain_v14_sixth/<id>/SOURCE.json`。

| 官方资产 | 米制纹理宽度 | 三通道总字节 |
|---|---:|---:|
| [Rock 01](https://polyhaven.com/a/rock_01) | 1.5m | 6,935,032 |
| [Leafy Grass](https://polyhaven.com/a/leafy_grass) | 2.0m | 14,930,066 |
| [Forest Ground 04](https://polyhaven.com/a/forest_ground_04) | 3.2m | 13,236,896 |
| [Brown Mud 03](https://polyhaven.com/a/brown_mud_03) | 1.3m | 6,936,224 |

ARM的R／G／B分别为AO／roughness／metallic；diffuse是sRGB，normal和ARM为线性数据。主控已读取四张实际diffuse，Forest Ground 04实际偏碎石林土，不宣称满落叶地表。素材只进入隔离局部候选，`approved_for_production=false`，下载及许可通过不替代视觉、导航和正式运行验收。第五误用于地形的Boulder模型UV图集应撤出地表用途，模型自身合法贴图用途不受影响。未使用网页预览截图作为纹理，没有登录、付费或生图费用；原创城市图不会因此转为CC0。

## 2026-10-02 · 九区新版补充小松树来源

第八整图源另定向下载[Aerial Grass Rock](https://polyhaven.com/a/aerial_grass_rock)真实15m×15m扫描的2K diffuse、OpenGL normal和ARM，总7,368,961字节；官方files API逐MD5与size、下载后SHA全部一致。作者Rob Tuytel，官方[CC0许可](https://polyhaven.com/license)复核；实际米制宽度来自官方info API dimensions `[15000,15000]`毫米。工作副本与生成来源在`game/art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock/`，独立获取脚本`scripts/fetch_world_v14_eighth_pbr.ps1`。这是真正中尺度PBR，不能把原1.5m岩纹放大冒称15m，也不是模型UV图集。尚为候选、未正式激活，没有账户、付款或生图费用；运行时不联网。

同日另定向取得官方 [Tree Small 02](https://polyhaven.com/a/tree_small_02) 的1K glTF和十份依赖，作者Rico Cilliers；十一份文件的官方MD5和大小全部吻合，逐文件SHA及来源登记在`game/art/external/polyhaven/tree_small_02/SOURCE.json`。模型SHA为`3062a709614c05b80fdc1e56583998bc3cb1027b0d52f956c8ecfb882ff8ca6d`，总下载100,974,143字节。该CC0资产只有一个`tree_small_02_LOD0`节点，并无可直接采用的低模LOD：实际2,062,487三角形、1,777,278顶点，树高约4.56m。因此仅作为同镜头独立树木派生候选，不能宣称是游戏用轻量模型或已经进正式地图；若生成派生LOD，应另记实际处理、文件哈希和轮廓验收。

定向取得官方 [Pine Sapling Small](https://polyhaven.com/a/pine_sapling_small) 的1K glTF及其七个依赖文件，用于新版v14独立植被候选。作者为Rico Cilliers（建模）、Rob Tuytel（摄影）；当天复核官方许可页明确资产为CC0。八份文件全部匹配官方MD5，逐文件SHA、大小和来源保存在`game/art/external/polyhaven/pine_sapling_small/SOURCE.json`，模型SHA为`f358c01926861dd082f32dba60f7c9fba232b585a985cf38c0d2229eecf4bc48`。

下载通过官方资产页提供的单资产files API，使用项目专属`YunyingXiazhuan-RPG_GAME-AssetPipeline/1.0`标识。已复核[官方API条款](https://github.com/Poly-Haven/Public-API/blob/master/ToS.md)；这次是定向获取一个资产，不是批量抓库，也不会在游戏运行时调用该服务。没有购买素材、登录账号或新增生图费用。

模型包含a/b/c三株独立变体，不是三个LOD；原生单株约1～1.3m高，不能按成熟大树比例乱放大，也不能把全组的并排位移当单株脚底。独立alpha、树干脚底阻挡、树冠Y深度与实际接地仍需新版真实Field验收。取材完成不代表美术通过或正式接入。原有原创城池、桥、渡口和灌木不因混合制作而成为CC0。

| 原资产与作者 | 目前用途 / 视觉状态 | 官方来源 |
|---|---|---|
| Boulder 01 · Rico Cilliers · 1K glTF | `game/art/external/polyhaven/boulder_01/` 保存 Godot 工作副本；固定正交渲染为 `game/art/modules/world_map_v13/boulder_01_cc0_southwest_v1.png`；另有无内置地影的 `boulder_01_cc0_southwest_v2.png`，仅用于双区 Field 隔离试摆。碰撞、脚底 Y 深度通过，**接地与画风仍未通过正式视觉验收** | [Boulder 01](https://polyhaven.com/a/boulder_01) |
| Rock Face 01 · Dario Barresi · 1K glTF | 第一轮岩面试样，比例/地貌不合，拒绝放入正式图；运行目录中的临时副本移到本地 `assets/raw/external/polyhaven/render_tests_20260929/`，不再参与 Godot 导入 | [Rock Face 01](https://polyhaven.com/a/rock_face_01) |
| Rock Path · Amal Kumar · 4K diffuse | 仅地面纹理候选；未接入道路，不能直接重复平铺 | [Rock Path](https://polyhaven.com/a/rock_path) |
| Aerial Grass Rock · Rob Tuytel · 4K diffuse | 与巨石置于同一正交 3D 小样，光影接触改善；整面仍偏平、过亮且像纹理地毯，未作为可玩底座 | [Aerial Grass Rock](https://polyhaven.com/a/aerial_grass_rock) |
| Coastal Cliff 01 · Rico Cilliers / Rob Tuytel · 1K glTF | v2 原生海岸局部构图试验；`game/art/external/polyhaven/coastal_cliff_01/` 是 Godot 工作副本，**未接正式图** | [Coastal Cliff 01](https://polyhaven.com/a/coastal_cliff_01) |
| Shrub 03 · Rico Cilliers · 1K glTF | v2 原生海岸局部植被试验；`game/art/external/polyhaven/shrub_03/` 是 Godot 工作副本，**未接正式图** | [Shrub 03](https://polyhaven.com/a/shrub_03) |

源下载保存在本地 `assets/raw/external/polyhaven/`（`assets/raw/` 按仓库规则默认忽略）；可复现的 Boulder 01 glTF 工作副本及其纹理在 `game/art/external/polyhaven/boulder_01/`。派生脚本 `game/scripts/dev/render_polyhaven_boulder_v1.gd`，隔离测试场景 `game/data/scenes/world_map_layered_cc0_candidate_20260929.tres`，截图 `game/screenshots/world_map_layered_cc0_sample_20260929.png`。正式 v12 与原分层试样未引用授权巨石。

关键原文件 SHA-256：

2026-10-01 v11增量：已有Boulder01／Shrub03原生模型用于两石／八株低草同镜头候选管线，局部岩肩height真实改变，沿用已有授权扫描材质，无新增联网下载／生图。Shrub03是真实0.25～0.40m地被，不能放大冒充成熟灌木或树；旧建筑／水及原有材质仍不属于CC0。实际cast捕获两次均为空，当前首轮实体partial不可试玩，技术FAIL、正式未切；见 `docs/world-map-native-pair-native-props-relief-v11-20261001.md`。

2026-10-01 v10增量：沿用登记的CC0草地／Rock Path工作图调整中细节和灰石铺地；新增程序破碎边缘、15处接触土／窄暗核，移除旧宽圆影，仅两轮材质渲染。没有新联网下载／生图费用，地理／导航／物理和五柱alpha冻结。城池／渡口／灌木和项目原有岩面／水材质不因此属于CC0。headless1582/GPU1602项0失败，整体视觉仍FAIL，正式未切；见 `docs/world-map-native-pair-material-contact-v10-20261001.md`。

2026-10-01 v9增量：沿用已核验草地／道路／巨石工作副本，新增程序岩肩、城外石铺／耕作地、曲河与港湾；渡口亭／近栏为现有自生成图的同画布alpha隔离，不是CC0素材。没有联网下载或新增生图费用，仅两区开发候选，视觉仍FAIL，未切正式v12/v13 staging，见 `docs/world-map-native-pair-authored-bay-v9-20261001.md`。

2026-10-01 v8增量：继续使用已核验草地／道路工作副本，草地diffuse去低频航拍旋纹后保留细节，混合草土／碎石并按15处脚底地基生成接触土。没有下载新素材或新增生图；独立建筑和自生成岩土材质不属于CC0。只用于双区开发候选，地表/接地仍视觉FAIL，见 `docs/world-map-native-pair-ground-contact-v8-20261001.md`。

2026-10-01 v7 增量：`render_polyhaven_shrub_v7.gd` 隔离已有 Shrub 03 glTF 的 `shrub_03_a` 单株，剔除另外三株并排扫描变体后再计算边界及脚底。同正交方向、camera size 0.7、yaw 22°，输出 `shrub_03_cc0_ortho_v7.png` / `.json`，229×338，foot_uv约 `[0.484716,0.944495]`。仅透明候选，未摆入v7路线、未正式采用；不能将小型地被放大冒充树木。

v7路线草地、道路和巨石仍使用上述已核验外部工作副本。城池、渡口、石桥沿用自生成候选，来源记录在 `assets/raw/scene_background/world_map_v13_layered_art_manifest.json`；`bridge_stone_eastwest_front_rail_v7.png` 是原桥图同画布alpha隔离加工，**不是外部CC0素材**。见 `docs/world-map-native-pair-landmark-route-v7-20261001.md`。

2026-10-01 v6 增量：同一 Boulder 01 源新增低伏 v4／v4b 两个正交派生视角，Y 缩放 0.60、方位 35°／-55°、albedo 色乘 `[0.72,0.77,0.73]`。`render_polyhaven_boulder_v4.gd`／`...v4b.gd` 及对应 PNG/JSON 保存可复现处理与脚底坐标；仅 `world_native_pair_prop_contract_v6.gd` 隔离样板使用。仍未获正式视觉验收，详见 `docs/world-map-native-pair-groves-v6-20261001.md`。混合灌木仍是自生成资产，不能随巨石误标 CC0。

2026-09-30 v5 增量：Rock Path 与 Aerial Grass Rock 的原始 diffuse 工作副本已放入 `game/art/external/polyhaven/terrain/`，哈希与下表一致，供隔离地形渲染可复现使用。Boulder 01 新增 `boulder_01_cc0_ortho_v3.png` / `.json`，脚本 `render_polyhaven_boulder_v3.gd` 与地形采用同一正交视角并记录模型底面投影脚底；仅 v5 物件合同引用。以上均未进正式 v12／v13 staging，视觉不合格原因及实验结果见 `docs/world-map-native-pair-relief-v5-20260930.md`。

| 文件 | SHA-256 |
|---|---|
| `boulder_01_1k.gltf` | `51487934DB898B4C24072780A451E34ECA5C02E3ADA24A62BBC600BBC4019E92` |
| `boulder_01.bin` | `7F5B06503D62BD95BFE9C6B8A354A5CC8FF04A4D271A8CF87A3E3125DB4232D7` |
| `boulder_01_diff_1k.jpg` | `C38F0E918F6DC16B8D386BA3CDD89805C78320C119A1CEEC85856F82B09A65B8` |
| `rock_face_01_1k.gltf` | `96C332C01D173A2431115F3BAC29BE101FBA341E5500E2A08E384F4EDD17299E` |
| `rock_path_diff_4k.jpg` | `44483A4CC96A57C8B7CE628C7205AE826C301D15560B682576DFD69936CE7206` |
| `aerial_grass_rock_diff_4k.jpg` | `84BF24B80D097C1A38D0FBE5C84584B1EDE3E2AB06B4AF2721FD184A9F94D5A3` |
| `coastal_cliff_01_1k.gltf` | `2E6BB1F77965B314208B309AC89B94B8148C6A08EE6C9808CD71455E5475602D` |
| `coastal_cliff_01.bin` | `6833DFAF75E0D039E64BC09AD642C4BE3361739F20048AF32AD50FD8E6471A65` |
| `coastal_cliff_01_diff_1k.jpg` | `6C9626FDB5550BA260B195638C8C89053FAEDC22005F4CA94D3BE5DF72AE525A` |
| `shrub_03_1k.gltf` | `B76D7C14BC027E834E82D3F984C32B5D060E62908AA90FF9420A637CA253A8EA` |
| `shrub_03.bin` | `BF4DF21E6D2A2BC5F00B4C9142F776171FE7DA00CF960001825748067AF542B6` |
| `shrub_03_diff_1k.jpg` | `3CADC7ABA46D3AABBD7D6D2B1D04AA32E2A7DA0BC87C2D38EF3CB1EE42CB03EC` |

候选不得晋级的原因：把摄影测量巨石贴在旧烘焙草地上，即便比例、变暗与接地阴影调整后，实机仍显悬浮/拼贴。`game/scripts/dev/render_world_ground_cc0_lab_v1.gd` 把巨石与 Aerial Grass Rock 放在同一正交 3D 场景后，接触阴影有改善，但单一平面纹理仍缺地形体积、道路和可辨地貌，也过亮；该图只留在本地 `game/build/` 作负例，未进游戏场景。下一轮需要作者明确的地形几何、同源道路/水陆 mask 和实体布置；每个分区、入口与接缝再逐图通过实机验收。

2026-09-29 进一步用 `game/scripts/dev/render_world_map_native_coast_slice_v1.gd` 试验原生高度网格，而非平面：Aerial Grass Rock 用于地形表面、Rock Path 用于道路、Boulder 01 为独立物件。海岸禁走图与地形共用轮廓，巨石脚底也同步阻挡；23项定点行为通过。输出 `game/build/world_map_v13_native_coast_slice_v1.png` 和 `game/build/world_map_v13_native_coast_walk_v1.png` 是本地技术样板。画面审查仍不通过：重复草纹、直条道路和纯色水面均不能做正式游戏地图，且原始纹理在被忽略的 `assets/raw/` 中，脚本只用于本机试验。正式世界地图未使用这些素材。

随后 v2 原生渲染加入上述崖壁和灌木，仍因重复纹理不通过；内置生图编辑保留其构图、换成更自然的地貌作为底座。该自生成底座**不属于 Poly Haven CC0 文件**，授权巨石才是独立外部物件；两者在隔离场景中混合的验收与剩余视觉问题见 `docs/world-map-native-coast-gen-v2-20260929.md`。
