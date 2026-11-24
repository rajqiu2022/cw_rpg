# 采药、采矿角色动作与同步音效 · 2026-10-30l

状态：已正式接入，交用户试玩。原F/近脚点击入口不变；20个普通采集点共用，不改原任务专属采集。编辑器无需关闭，重新启动游戏读取新资源。

## 当前效果

- 采药1.2秒：站定→俯身→低蹲采摘→起身。第2号帧（0-based）约0.6秒播放草叶摩擦/纤维拔取声。
- 采矿1.5秒：持镐→举镐→落镐→收势。第2号帧约0.75秒播放短促矿石裂击、轻铁共振与碎屑声。
- 两类均是真四帧新图，不是把待机上下移动。主角身份/服装/成人站高128.52px沿当前原版；右向原帧，左向只在运行时围绕脚锚镜像，不冒独立四方向图。
- 动作中原角色身体/碰撞/脚点/移动约束不改，只隐藏原精灵、显示同脚锚动作层；完成恢复原精灵和自己的移动锁。按Esc或移动可取消，取消不发材料。连续按F/点击不会重开或重复给料。
- 先校验可采/空间/距离/真实射线及完整脚体，完成后再验证一次并调用原采集事务；动作开始不是“已获得材料”。满包、已采集、隔实体或超82px不启动成功动作；对话、外部面板、过场、换图/根重建会中断，不解开别人的modal。

## 正式文件与提示词

| 内容 | 保存位置 |
|---|---|
| 采药四帧原图 | [gather_herb_right_4f.png](../../assets/raw/gather_actions_20261030l/gather_herb_right_4f.png) |
| 采矿四帧原图 | [mine_ore_right_4f.png](../../assets/raw/gather_actions_20261030l/mine_ore_right_4f.png) |
| 正式采药贴图 | [gather_herb_right_4f_padded.png](../../game/art/sprites/life_skills_20261030l/gather_herb_right_4f_padded.png) |
| 正式采矿贴图 | [mine_ore_right_4f_padded.png](../../game/art/sprites/life_skills_20261030l/mine_ore_right_4f_padded.png) |
| 采药专用音效 | [herb_rustle_pluck.wav](../../game/art/audio/life_skills_20261030l/herb_rustle_pluck.wav) |
| 采矿专用音效 | [pickaxe_stone_hit.wav](../../game/art/audio/life_skills_20261030l/pickaxe_stone_hit.wav) |
| 动作矩形/脚锚/比例/音频cue | [gathering_actions_20261030l.json](../../game/scripts/life_skills/gathering_actions_20261030l.json) |
| 动作宿主 | [gather_action.gd](../../game/build/gather_actions_20261030l_system01/gather_action.gd) |
| 提示词与任务登记 | [tasks.yaml](../../assets/staging/gather_actions_20261030l/production/prompts/tasks.yaml) / [模板](../../assets/staging/gather_actions_20261030l/production/templates/gather_action_4f.yaml) |
| 实际完整提示词 | [采药prompt](../../game/build/gather_actions_20261030l_root01/gather_herb_right_4f_prompt_READY.txt) / [采矿prompt](../../game/build/gather_actions_20261030l_root01/mine_ore_right_4f_prompt_READY.txt) |

两张由内置`image_gen`分别各调用1次，无CLI/API fallback或自动重试。真实现役右/下idle strip为身份/衣着/相机参考，先读取显示；不拿旧待机冒新动作。真实画幅2172×724，不把登记请求1536×512当实际输出。工具未披露具体model/provider/cost，meta留null，不伪造gpt-image-2证明。原图及meta均保留。

用户已有通用许可内仅清主体保护框外alpha=1点，194/623个；每个原cell四边加32px RGBA0留白，2172×724→2428×788，四格各607×788。所有原RGB与保护框内RGBA精同，无重画/改色/缩放/裁主体。工程同目录两张未补白图只是原图字节副本，未被动作配置消费。两[原生脚锚预览](../../assets/previews/sprite/gather_actions_20261030l/herb_runtime_anchor_preview.gif)、[采矿预览](../../assets/previews/sprite/gather_actions_20261030l/ore_runtime_anchor_preview.gif)只供诊断，不替代正式图。

音效为本轮新增的离线程序合成48kHz单声道PCM16，时长0.52/0.55秒，非真实录音、非AI音频，不用旧UI确认/格挡音冒专用采集声。源码和来源参数在`prepare_assets.py`与`assets_prepared_ACTUAL.json`；运行时SFX音量控制、帧2播放，时长短于剩余动作，不截尾。Root验证真实AudioStreamPlayer.playing和播放位置推进，未声称完成录音级听审，听感交用户试玩。

## 变更与保护边界

只有原`LifeSkills.gd`修改，正式5687BBB7、helper5812B078、配置bc399551；原GATHER事务、配方、Inventory、Player、Router、project、事件总线、任务及存档schema不改。系统候选8组上下文替换整逆回原ED26E665，原制作入口只在采集忙时防重开。

Root正常图发现深矿矿01动作被旧岩壁遮住，唯一矿点X1040→925，Y1680/ID/产物/次数等全保；采集站脚875,1730，距70.71px，完整35×25脚/射线/扫掠净空，动作全部真实alpha与既有物件AABB无交，和岩壁保守相隔100.38px。不是抬角色z让人穿墙。只追加这一个点位变化的权限，未修改岩壁/碰撞/NAV/地图路线，旧30k几何/来源证据作为历史保留。

新2PNG/2WAV只在隔离空工程导入，12个精确新叶推广，没有全工程import。RAW、原角色参考图、其它场景和所有旧媒体均保留。

## 有限验证

- 出图前项目原renderer预检2任务/2齐套参考，0API；独立素材静核67/0：实际尺寸/透明留白、原RGB/保护RGBA、四格脚锚、两WAV头/PCM非零/时长/来源。不是实际播放或全采集点逐一实测。
- 首QA稿117c…及02正规化inactive debug观测稿均在执行前分开保留；实际只运行02。Root完整读最终冻结helper/LifeSkills变更及QA，未改生产迎合测试字段。
- 自有实际138384自然0、384检查0、30输入、18.284秒：新猎径一草/深矿一矿，真实F/鼠标启动、四真实Sprite.frame及专用AudioPlayer播放位置递增；满包不启动、Esc零物料、真实短D取消后可走、90px范围阴性、动作期间不入包、重复输入无重、完成各2、已采点无重复、恢复原sprite/body/脚/控制。私有30格背包fixture只在该进程内，0真实SaveManager API。两正常图Root亲看；旧754/146/11门/全城未复。
- 因矿01旧岩壁遮挡，Root只移单X后，130760自然0、6检查0、1正常落镐图，实际F/帧2无提前入包/原脚完成矿+2/控制恢复。逻辑384成功继承，不重整个矩阵。
- 两轮只Root自有进程自然退出，用户自己停止原游戏133212，editor51856保持。旧7个退出RID/纹理/RenderingServer ERROR及ObjectDB warning保留，非clean stderr。
- 首250事实guard`1F086676`整体FAIL保留：仅save_0.json与.bak在用户旧游戏仍运行时由5159→6497字节，mtime11:02:31/11:02:27 UTC，早于Root首runtime11:14:49；不覆盖用户新进度。首次时间审计误把ConvertFrom-Json已解析UTC DateTime再次Parse成本地时间，原FAIL保留。新03按DateTime/DateTimeOffset真实类型核，scoped audit`1E624E9E`通过：其余169save事实同，两更新精保且末无再变、旧非save源无外差、两授权源分别整逆同。不能写“171save全部精同”；本轮0真实档反序列化/写入/恢复。

动作站高与正常截图已看，可交本轮首版；没有新采集技能、工具耐久/装备门槛、品质掉率、新主线/奖励。左向为运行镜像，未逐个20点重做实机；真实四方向独立劳动动作和更细音效听感可后续按试玩意见迭代，不冒已完成这些范围。

图鉴已增8条（RAW2/正式补白2/未消费副本2/音效2）、6个新缩略，5226→5234；所有旧记录及非resources正文/数据精同，既有放大/音频handler未改，链接与缩略静核可解码，未冒真实浏览器点击。[图鉴最终精核](../../game/build/gather_actions_20261030l_catalog01/final_exact_PROOF.json) SHA`CB7F8C11`。
