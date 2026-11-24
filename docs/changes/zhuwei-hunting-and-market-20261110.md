# 竹尾猎径、密林、废弃矿道与晨市

## 正式接入与局部验证（11月11日收尾）

- **猎径与密林**：原猎径超过旧的 255 深度上限，南部人物、竹木被夹到同一排序层。仅该图按统一 1024 深度带处理，移除八组重复林丛及其阻挡/测试点。地面采用在用林西草土碎石、连续世界坐标采样和软路肩，不再铺高饱和草叶底。密林移除两片悬浮飘草；猎径分支改为背景已有石阶，不再用卷轴代表入口。原 G 交互保留；洞窟出口与到达点放回实际道路。
- **废弃矿道**：原 ID 改用独立 v2 地形、岩壁、矿车及两处小炉暖光；保原走区、原两个出口、箱子和遇敌。四周岩壁使用两种形体，等比缩放与镜像，不拉伸。仍有岩组重复和地面均一，属于局部改造，不授全洞窟美术完成。
- **采集物**：矿物换暗灰岩体夹铁锈矿脉，药草换低饱和阔叶药株；正式普通采集点和冒险图补充点使用同源图。原物品 ID、采集动作、补充与奖励规则不改。这是透明 3D 渲染风格精灵，不是引擎内 3D 模型。
- **第二章晨市**：移出第一章原生村庄接管名单，正式原 ID 使用已有独立石板市集背景及 v3 布局。八位 NPC、客栈/演武室、北林/河滩、废宅返口与南驿道重新对齐；客栈返回使用安全门前脚而非默认村庄出生点。船夫纠正原女坐客图，身份和对白保。南驿道 Space 可到现役江湖大地图。
- **废宅与赵无忌**：村民仍在现场，但守卫未败只提醒危险，不能直接获营救线索/脱困。原胜利旗成立后切回原救人对白；这项用隔离状态验证前后两态，未重打守卫。赵无忌使用原生四帧高清待机，统一鞋底并调为 151px；不改头像、战斗图、数值或身份。
- **师徒、刀剑与床**：杜青衫只在自身对话时暂停，不因与师傅交谈停锤；交谈期间打铁声避让语音。师傅净高调为 144px。正面腰佩裁取实际柄段并贴腰，不显示整刀/整剑；断岳出鞘光与粒子保留。洞内床按斜向接地线决定前后遮挡，不再用整张图中心排序。

### 仅新增与高风险局部检查

隔离 AppData、暂停检查点；下面各次均正常退出 0，源文件检查零差、15 个真实槽仅元数据检查零差。编辑器 56568 保留；未读写或恢复真实档内容。

| 运行 | 实际范围 | 检查 |
| --- | --- | --- |
| `zhuwei_hunting_market_03` | 废宅 Space 到晨市、客栈进返门脚、南驿道 Space 到 World | 25 / 0 |
| `zhuwei_hunting_market_04` | 石阶 G 到猎径及 Space 原脚返、原洞口进矿道；营救前后两态、赵无忌四帧、第一章客栈门脚、床前后、师傅交谈期间真打铁、断岳正面仅柄及真实战斗备战刃光 | 71 / 0 |
| `zhuwei_hunting_market_05` | 新矿道末版、深窟 Space 双向原口返 | 15 / 0 |
| `zhuwei_hunting_market_06` | 只在船夫修正后复核晨市相关路线 | 25 / 0 |

证据均在 `game/build/loading_20261106_system02/` 对应运行目录。正常图：04 的 `zhuwei_hunt_south.png`、`linxi_waist_hilt.png`、`linxi_drawn_blade.png`、`zhuwei_zhao_hd.png`；05 的 `zhuwei_mine_final.png`；06 的 `zhuwei_market_alley.png`，位于隔离 `appdata/Godot/app_userdata/云影侠传/`。

首轮 01 的严格来源拒绝、02 的错误坐标/Space 时序断言失败全部保留。只更新具体变动叶子的 SHA 及它的 manifest pin，不跳过来源校验。既有退出 RID/Texture/RenderingServer 释放错误仍在，不称日志全净。不是从主菜单逐战重打两章，不是冷加载优化或发布包验收；晨市局部小地图、其余洞窟房间和全城市统一美术不在本轮完成范围。

资源图鉴已执行 `--sync-resources-only`，保留旧装备/任务/剧情数据；总资源 5761，新四图均可查且标记源码引用，不以静态引用授美术通过。首次同步遇既有 ledger 的 `stage_matte.tres` 被误当图片交给 Pillow，未改该材质；图库只把 raster/audio 媒体交给缩略器后重跑成功。当前 native 来源245叶全部SHA一致。

范围：使用原场景 ID 和原任务状态；不读写真实存档。猎径地表与树竹脚底分层、后山密林的石阶岔路与洞口、第一章废弃矿道、第二章独立晨市、废宅营救以及赵无忌场景动作。晨市不再由第一章村庄的原生街区接管，采用已有石板市集原图和单独重布的行走区域、NPC、店铺及门户。

## 新资源原图与提示词

均由内置 imagegen 生成，按原始 PNG 字节接入，未对主体重绘、拉伸或重采样。下列工程路径为正式使用路径。

- `game/art/modules/zhuwei_gather_20261110/mine_slate_rim.png`：原图 `exec-8aa70884-33f5-480b-9c62-5292b22664fd.png`；SHA256 `1F11F780FB27AD80AA8758EF06F294041D944DFB828F341706983108C1809DA1`。制作要求摘要：写实武侠 2.5D 废矿岩壁，完整不规则灰黑板岩层、破裂边缘和低处碎石，等距斜俯视、柔和顶左照明，透明背景，非方块台阶、无文字和其他道具。完整生成调用保留本聊天；正式 PNG 原字节复制，不做像素编辑。

- `game/art/modules/zhuwei_gather_20261110/iron_vein.png`：`exec-0c7bbe2d-9079-4972-abdd-33edd01a7ef8.png`。Use case: stylized-concept. Asset: isolated transparent PNG gameplay prop for a realistic 2.5D Chinese wuxia RPG. One low iron ore outcrop embedded in a single compact irregular cluster of dark grey fractured host stone, thin muted reddish brown hematite veins within it, hints of earth and very restrained olive moss hugging its base. Wide footprint, low profile, no piled red bricks, no crystals, no light effects. Perspective: orthographic steep 55-degree above ground, front of asset toward bottom of image; see the upper surfaces and modest front volume. Photorealistic game-quality 3D/PBR render, diffuse soft sunlight from upper left, weathered stone, restrained natural color and contact shadow immediately under the stone only. Centered complete object, margins, transparent background, no ground plane, text, border or other props.
- `game/art/modules/zhuwei_gather_20261110/woodland_herb.png`：`exec-7374ed5c-1fb3-4c34-8b6a-71382a3f7f83.png`。Use case: stylized-concept. Asset: isolated transparent PNG gameplay prop for a realistic 2.5D Chinese wuxia RPG. One small rooted woodland medicinal herb clump, real broad tapered ribbed plantain-style leaves, several staggered short stems with tiny muted cream seed spikes, natural irregular leaf angles, small intimate root tuft with a trace of brown soil and old litter at base. No dense grass ball, blue color, neon rim, pot, glow or label. Camera steep 55-degree above ground orthographic, front toward bottom of image; show grounded foliage volume. Photorealistic game-quality 3D/PBR plant rendering, olive and subdued green, soft upper-left forest daylight and a tiny contact shadow within footprint. Centered complete object with generous transparent margin and no ground plane.
- `game/art/characters/story_enemies_20261109/zhao_wuji/ready.png`：`exec-f33d656d-85ec-436f-bfc2-f6150d28bef4.png`。Use case: stylized-concept. Game sprite asset for Godot realistic Chinese historical wuxia RPG. One image containing exactly FOUR contiguous equal-width cells in a single horizontal row, no separators, four tiny breathing frames of SAME Zhao Wuji male bandit lieutenant, matching stance and identical boots planted on the same baseline. Full-body steep 2.5D orthographic view from 20–30 degrees above the horizontal, body turned slightly screen-left, head looking left. Rugged stern Chinese man age 38–45 with swept-back tied black hair and short black mustache and chin beard; weathered dark brown shoulder cape, dark crimson sleeves and layered split tunic over charcoal trousers, leather bracers and boots. Both hands hold a plain steel saber low across his body, tip angled screen-left down, restrained pose. Native high-res physically rendered fabric, leather and metal, subdued natural colors, coherent anatomy. Four frames barely vary shoulders and cloth, no pose breaks, no clothing changes, identical scale, angle and strict fixed ground contact. Leave generous transparent padding per frame, no touching cells, no cast shadow/background/title. Not a portrait, no extra weapons or people.
