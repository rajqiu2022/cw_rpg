# 2026-11-06 NPC 原生高清首批正式接入

## 交付边界

本批已有限正式采用 **12 个视觉族、15 张动作贴图：8 族新生成、4 族原生源复用**。不是全员高清完成，不是新增独立四方向。原农人高清映射保留，正式 adapter 合计 16 个贴图映射；Root 的 formal16_04 已确认 16 个真实 NPCNode 消费者采用正式资源，0 失败，无候选注入。没有逐真实地图重走。

| 视觉族 | 本批来源 | 正式动作范围 | 原生人体高度（px） |
| --- | --- | --- | --- |
| 店小二 | 新生成，普通脸修正版 | 下向待机 4 帧 | 678–681 |
| 卖菜大婶 | 新生成 | 下向待机 4 帧 | 664–668 |
| 年长男坐客 | 新生成 | 固定坐向待机 4 帧 | 700 |
| 女坐客 | 新生成 | 固定坐向待机 4 帧 | 701–703 |
| 竹尾门卫 | 新生成 | 下向待机 4 帧 | 767–771 |
| 林西武术教官 | 新生成 | 下向待机 4 帧 | 698–703 |
| 竹尾哭泣妇人 | 新生成 | 下向待机 4 帧 | 763–765 |
| 竹尾镖师 | 新生成 | 下向待机 4 帧 | 757–759 |
| 老僧 | 复用原生源 | 下向静待机 1 帧 | 1119 |
| 老兵 | 复用原生源 | 待机 1 帧、右向行走 4 帧 | 1043 / 587–591 |
| 年轻军士 | 复用原生源及已授权母条 | 待机 1 帧、右向行走 4 帧 | 1027 / 557–566 |
| 码头壮工 | 复用完整姿态母条 | 待机 1 帧、右向行走 4 帧 | 718 / 695–708 |

原业务已有的左右镜像继续沿用；没有把右向行走称为独立四向，没有把动态角色改成静态。竹尾镖师与共用黑衣护商镖师不是同一族，后者仍待下一批。

## 来源、处理和接线

- 新 RAW 保存在 `assets/raw/npc_hd_20261106/`，提示词在 `prompts/npc_hd_20261106/`，内置调用由 Root 执行。实际新 RAW 为 1774×887；未返回的模型、提供方或成本保留未知/null，不虚填。
- `game/build/npc_hd_20261106_candidate01/atlas_preparation_receipt.json`、`reuse_preparation_receipt.json`、`next_four_preparation_receipt.json` 保留每帧原图 SHA、保护框、原生人体、脚锚及整数平移。历史收据中的 candidate 状态保留原时点事实；本篇和 after receipt 是后继。
- 只清除保护框外 alpha=1 杂点及透明补白、完整帧整数平移/拼接。全部源 RGB 和保护范围 RGBA 精确保持，无拉伸、插值放大、锐化或重画。坐客 alpha>1 弱彩边未擅自抠除。年轻军士行走使用已授权 3300×825 母条；码头工按实际完整人物分区切分，不硬切五等格。
- 正式贴图为 `game/art/characters/pc_hd_20261102c/` 本日期 15 张 PNG；`source.json` 15 个精确源路径/SHA 映射，原两张小二/菜贩 PNG 字节冻结。
- 正式 `game/build/pc_sprite_view_20261102c_runtime01/pc_sprite_view_runtime.gd` 仅替换已匹配源的视觉子节点，原 NPC 贴图、动画帧、脚点、比例、碰撞、对白及任务逻辑保持。未知材质/未映射动作回退原显示，已知 outline 材质使用已有限验证的租约，避免原 outline 材质在透明旧 sprite 上残留重影。
- 安装范围 47 个目标，其中 45 写入：13 新 PNG、15 `.import`、15 ctex、adapter、manifest；2 旧 PNG 不写。8 个已有目标全文字节备份、39 原 absent。精确清单在 `formal_mipmap_install_plan.json` / `formal15_before_receipt.json`，最终 47 after SHA 与计划精同，见 `formal15_after_receipt.json`。

## 缩小采样纠偏，不是假高清

原生人体 557–1119 px 缩到约 128 world px 时，只有 LINEAR、无 mipmaps 会出现高频斑点。现仅本批 15 个高清导入启用 mipmaps，HD 子节点用 `LINEAR_WITH_MIPMAPS`；不对 PNG 像素模糊或降采样，不改原 NPC owner 的过滤或几何。

Root 隔离导入与 visual03 对全部 15 图核验 mipmap level0 RGBA 字节前缀精同原 PNG，尺寸不变且有完整 mip 链；原 PNG 与真实人体分辨率不受影响。原农人映射/源资源不变。

## 有限证据与保留失败

- lease01：Root actual130476，自然退出 0，34/0；包含范围进出、外部材质覆盖、未映射动作回退、原农人、脚点。未重复运行。
- visual01：formal 只有农人 1 个映射，因新两图缺隔离导入导致 ResourceLoader.exists 静默跳过，FAIL 保留；随后两图精导入，visual02 正式 3 映射确认。
- visual02：15/0 但底行裁切且缩小噪点，ART 拒绝保留，不将功能通过冒充视觉通过。
- sampling_ab01：fixture 未列入 source inventory，preengine FAIL 保留，未放松 guard。
- sampling_ab02：QA 错将完整 mip 链与 base 比较，FAIL 保留；ab03 修为 base 字节前缀/格式/尺寸/链长度比较，Root actual148364 自然 0，两族 failures0；10485760 base 字节精同。
- mipmap_import01：Root actual63932 自然 0，只隔离导入 15 图，不全项目导入。
- visual03：Root actual130952 自然 0，15 panels / failures0，15 base RGBA 精同；Root 亲看完整首帧、比例与缩小采样有限接受。标尺是 **128 world px，不是 128 截图像素**；viewport1920×1080、截图1334×750，实际查看又含外围缩放。没有逐全帧 ART 或逐真实场景旅行。
- 本批保留原 WASAPI、RID、RenderingServer null 等退出遗留；不冒 clean log。子 agent 无启动引擎、无真实存档内容读取、写入或恢复。但后续审计确认 **Root 使用的旧共享保护器曾对 15 个明确真实存档槽执行 Get-FileHash，确实读取了字节**；未反序列化、写入或恢复。因此不能将子 agent 的零读取表述推广到整次测试。历史日志/结果保留，batch02 改用仅元数据保护器，不重跑旧验证。
- formal16 首启动 Windows PowerShell 5 不支持保护脚本 `-AsHashtable`，预引擎 FAIL 保留；Root 改用 PS7，formal16_02 actual107320 自然 1，仅 QA fixture 的 Dictionary Variant `ok :=` 推断失败，尚未运行消费者。只将该局部声明改为显式 bool，不改正式源或保护脚本，失败不洗。
- formal16_03 actual110288 自然 1：16 consumer 原生 HD reason 全正确，但 QA 直接比较子帧 AtlasTexture 的空 resource_path 与整图路径，15 项误报，农人通过。仅修 oracle 为子帧 `.atlas` 与 mapping.atlas 对象身份、正式路径、底层 mipmaps 和所有 frame region 非空，并逐字段输出诊断；正式 adapter 不改，03 FAIL 保留。
- formal16_04：Root actual27964 自然退出 0，16 consumers / failures0，正式 manifest 15 映射加原农人，`candidate_injection=false`。逐消费者确认原业务源保留、HD 子节点、AtlasTexture 底层正式图身份/路径、有效帧区域与 mipmaps；source/player/executable changes 均空。此为真实 NPCNode 的有限采用证明，不是实际 Field 旅行或所有方向/动作终验。stderr 仍含既有 WASAPI/RID/null 退出错误，前述失败原样保留，不冒 clean log。正式安装后收据已更新为该有限接受状态，本批停止测试和新增制作。

## 资源图库有限登记

只追加本批 15 张正式 PNG 与 8 张新 RAW，共 23 记录/23 缩略图，图库 5272→5295；旧记录、非 resources 数据、旧缓存条目及 HTML 其它区域保持。没有全库扫描或引擎启动，没有重新处理源 PNG。精确记录及保护 SHA 在 `game/build/npc_hd_20261106_candidate01/gallery_formal15_receipt.json` 与 `gallery_formal15_records.json`。

## 仍待推进

静态引用盘点有 41 个视觉族、84 张源贴图，包含剧情/备用引用，不能冒充 41 个同时生成的现役 NPC。原农人、苗族男女侧向行走、赤岩女掌柜已有原生高清，本批不重复生成。

下一批精确候选见 [四族只读盘点](npc-next-four-readonly-20261106.md)：抱书书生、共用黑衣护商镖师（原生右向 8 帧可复用，待机需重制）、斗笠行商（待机及四向 32 帧仍需真正高清）、废宅守卫。主角完整四向和动作、其它低清角色、全员/所有方向动作终验尚未完成。本批完成后停止新增制作，不以本篇替代冷加载优化或历史场景修复的总报告。
