# 武侠音乐与音效重制：首批试听候选

日期：2026-10-09。change-id：`wuxia-audio-model-trial-20261009`。

## 2026-10-11 用户批准替换，采用20主题与已认可3循环

用户最新明确“可以替换现有的音乐了”，批准本批20主题选曲（18原版＋密林ALT＋紧张ALT）实际采用；此前认可的探索、行旅ALT、默认战斗循环同时接入。用途仍为个人使用、暂不商用，不新增模型调用。本次入库23首PCM WAV，城市/村庄/郊外/剧情/战斗由运行时MusicCatalog选择，林西村原白日曲保留。当前接入和验证状态见 [正式接入记录](wuxia-music-integration-20261011.md)。

下文和旧封存manifest的待听审/未接入字样是制作时历史状态，保留原证据；本段记录后续明确采用授权。本轮不重做曲目或覆盖原试听档案。

## 2026-10-10 地域、剧情与战斗音乐扩展制作

**最终交付已完成：20主题主试听，档案24次实际生成。** 原20首与四独立对照及各循环候选均自然OS0，全部推理停止。主展示18原版＋密林ALT＋紧张ALT，汴州/夜村保原版，原始版本/全部对照保持。[完整曲目与四组串听](../assets/processed/audio/wuxia_regional_story_auditions_20261010/README.md)提供每首全曲/30秒/循环/真实边界试听，四组77/64/63/64秒，曲间人为1秒分隔。

最终独立QA实际OS0：[twenty_tracks_offline.json](../assets/processed/audio/wuxia_regional_story_bank_qa_20261010/twenty_tracks_offline.json)，SHA`931f466f53413c9786fb24aecc5159d861a148d56282374e46243d37a2224b66`，绑定原bank`055BE4E6…`与groups`E3EFDD8D…`。原20关系及四ALT单轨PCMexact，合计124WAV/100MP3完整解码、PCM满幅0，四组真实prefix＋1秒零分隔逐字节一致。1786旧文件/路径＋266封存原20的SHA/bytes/精确mtime与库存零差；24raw SHA不同仅证明字节不同，不授曲风差异。未改game/林西/玩家，未启Godot或正式接入。

选听依据与局限如实保留：汴州ALT由1.48秒/3.39%变2.81秒/11.29%，夜村由2.23秒/4.78%变1.87秒/13.46%，均保原版。密林6.69→2.10秒、低窗13.87→13.57%仅微降且仍两处约2.1秒弱段，root仅按最长空档缩短选ALT；紧张5.20→.73秒、低窗47.98→1.64%、body−29.41→−23.66dBFS明显改善选ALT。新20及循环均待用户真实试听，前批三首HUMAN_APPROVED不冒用。下文保留本轮制作阶段记录，RUNNING等历史状态以本段最终状态为准。

用户明确继续制作不同大城市、村庄、郊外，以及紧张/轻松/欢乐/危险剧情和战斗BGM。沿已认可三首本地Stable方向，本轮计划20首独立新曲：洛阳/汴州/金陵/襄州/清河镇/雁门关6主题、2村庄、3郊外、4剧情、5战斗。当前个人暂不商用用途与本地续作授权持续，不重复问许可或开云服务。

角色分工：system只读真实地区与场景语义；art单写NEW制作计划/薄runner与音频，沿原固定Small Music CPU/8steps6threads/floatwrapper逐曲串行；QA首保护与独立音频关系检查；producer记录范围/交付/未验事项。NEW目录`wuxia_regional_story_bank_20261010`，旧试听/已批准3整曲及loops全部固定。保护已实际OS0，1786旧文件/路径（现役279/15玩家真实6存在9absent）及前1762变化0，保护SHA`0ce7baf11dd744756f35beb3bb401cd70df5619c2df040ef654c80b12f57ee9c`。全曲/30秒预览/循环及真实边界试听另产；本轮不修改game/林西/玩家，不启动Godot或借城市测试批准音频。

实际20曲计划与薄runner SOURCE审通过（plan`711BF22A…`、runner`5569627A…`），原20首及20循环候选均实际自然OS0完成，bankmanifest`055be4e6b69de456c018cab7e7fd4421375e6c5f44988a0368decac43c43bd81`固定；原bank266文件已另seal，原1786保护当时零差。实际独立最终技术QA与组试听仍待，不授曲风/听感通过。[真实地区与20固定track ID应用建议](../assets/processed/audio/wuxia_regional_story_mapping_20261010/README.md)与最终JSON逐项一致；最初映射文档误写旧拟定ID已窄修，不更改最终制作plan。验收只核真实model/runtime/runner/promptseed、音频有限非静音/完整解码/处理PCM关系与旧文件保护；各曲地区特色、自然乐句、情绪及新循环耳审由实际试听判断。只每曲一次初始seed，失败保原日志，不自动无限重试。

逐曲40ms窗/10ms步长/−45dBFS检查只分析真实试听PCM的3秒至预定analysis_end，排除开场和尾衰减。已完成前6地域；汴州出现6.75–7.93秒与14.51–15.99秒的内部弱段（1.18/1.48秒，body低窗3.39%）。此非自动技术/曲风FAIL，但针对用户先前断续反馈，root仅批准一次NEW持续伴奏汴州ALT：seed20261010022、96秒，独立`wuxia_regional_bianzhou_alt_20261010`，原20批次/原汴州不覆盖。襄州.66秒/清河.81秒短段仅记录，不据此自动多轮重做；ALT技术/能量与最终选听另待。

随后真实统计显示夜村两1.81/2.23秒内部弱段；密林body低窗13.87%、最长6.69秒；紧张剧情body低窗47.98%、多次4.53–5.20秒且因峰值帽body仅−29.41dBFS。root据这些明确目标不足分别批准各一次NEW夜村/密林/紧张ALT，seed20261010082/20261010102/20261010122，时长96/96/72秒；合计仅四对照，与原20组成24次生成档案，主展示仍20主题。generic四白名单runner`353C3511…`及NEW串听helper`E21D7BCF…`已QA/review限定SOURCE_PASS，原20+266封存保持，四ALT串行实际进行。原boss固定body有62.54–67.97秒低5.43秒，接近结尾可能自然收束，原统计不排除/不改分析域，也不自动第5ALT；其他较短换句均原样记录。四ALT技术/真实body改善后才选入NEW组试听，不把量化改善授耳审。

## 最新听审与本次范围

**最新用户听审：“很好，这几首都可以”。** 当前探索96秒、持续伴奏行旅ALT96秒、战斗72秒三首记为`HUMAN_APPROVED`；不包含旧弱行旅，也不追认自主v2/v3。当前个人暂不商用事实与本地续作授权有效。旧制作manifest和报告保留其当时状态，由本段记录后续听审。

三个NEW游戏循环已实际完成：探索56.873288秒、行旅ALT74.265397秒、战斗49.527075秒；2/2/1秒互补交叠、增益和选区逐PCM独立核对一致，6WAV/6MP3完整、满幅0，1762项历史音频/现役/15玩家保护零差。[循环与真实尾5秒＋头5秒试听](../assets/processed/audio/wuxia_approved_local_loops_20261009/README.md)，[独立QA](../assets/processed/audio/wuxia_approved_local_loops_qa_20261009/three_approved_loops_offline.json) SHA`53c2357021abbb4f839d118a9e874e2dc8e45d3629e53588a33047d1fcc27b5a`绑定manifest`4d2a7123db1066c420b473e3eb16b43838b211bc68fd53c0efc3baf9107a2dd9`。整曲认可不冒充新循环接缝耳审或Godot运行通过。

接入范围先限山道、江湖行旅和battle_mountain对应战斗，林西及其他专用曲保留。当前另一个城市验收进程ROOT443正冻结真实工程来源，因此本轮仅准备接入清单，不修改其game资源/引用、不启动另一个引擎。可应用补丁/实际备份/恢复及新曲首播0尚未实施或审核，不授集成通过。待来源冻结释放再按当时真实before源码准备可恢复修改、应用并验证实际循环/切曲；不额外要求用户重复授权，不以未来商业登记阻塞当前个人用途。

| 后续最窄接入位置（尚未应用） | 已完成循环源 | 拟新增正式文件 |
| --- | --- | --- |
| canonical场景山道v4/v5音乐引用 | `approved_mountain_loop.wav` | `game/art/audio/bgm/bgm_mountain_wuxia_stable_approved_v10.wav` |
| canonical场景江湖journey_v4引用 | `approved_journey_alt_loop.wav` | `game/art/audio/bgm/bgm_journey_wuxia_stable_approved_v10.wav` |
| AudioManager.DEFAULT_BATTLE_BGM及战斗controller的battle_mountain对应项 | `approved_combat_loop.wav` | `game/art/audio/bgm/bgm_combat_wuxia_stable_approved_v10.wav` |

实际修改前重新核定当前canonical逐文件引用与beforeSHA，不改city候选/legacy副本/冻结地图。AudioManager.DEFAULT_FIELD_BGM计划改为已认可实际林西`res://art/audio/bgm/bgm_village_day_v4.wav`，不覆盖village文件或20个既有显式引用。仅上述三个新曲的首播入口取0，不沿用旧v4的1/4、1/2、3/4场景hash入口；同曲继续播放与既有crossfade/fullfile loop_end保持。森林/洞穴/集市/城市/门派与spar/river/village/boss音乐本轮不折叠成这三首，音效仍待实际动作语义接入。

| 当前主试听 | 完整MP3 | 30秒预览 |
| --- | --- | --- |
| 山间清游 · 探索96秒 | [完整试听](../assets/processed/audio/wuxia_stable_personal_continuation_20261009/mountain_continuous_96s_audition.mp3) | [预览](../assets/processed/audio/wuxia_stable_personal_continuation_20261009/mountain_continuous_96s_first30s.mp3) |
| 江湖行旅 · 持续伴奏对照96秒 | [完整试听](../assets/processed/audio/wuxia_stable_personal_journey_alt_20261009/jianghu_continuous_96s_audition.mp3) | [预览](../assets/processed/audio/wuxia_stable_personal_journey_alt_20261009/jianghu_continuous_96s_first30s.mp3) |
| 拔剑交锋 · 战斗72秒 | [完整试听](../assets/processed/audio/wuxia_stable_personal_continuation_20261009/combat_continuous_72s_audition.mp3) | [预览](../assets/processed/audio/wuxia_stable_personal_continuation_20261009/combat_continuous_72s_first30s.mp3) |

以下保留制作阶段历史记录；其中整曲`LISTENING_PENDING`已由上述最新用户听审取代，旧报告不回写成事后批准。唯一行旅对照实际自然OS0，完整96秒＋30秒预览；[独立单轨报告](../assets/processed/audio/wuxia_stable_personal_jianghu_alt_qa_20261009/one_journey_alt_offline.json) SHA`912116239c2b6c1ebfe7ae16903754903ccd37bbadaebc6d8a58c892dbebed37`绑定finalmanifest`3db037c8ea55780adc1cf3d0cbe3d72bf9966d0463e2cda74c040b9d9e1a0564`。真实runner/kernel/固定模型/命令和全产物SHA实审通过，raw浮点峰0.776574/超1样本0，PCM峰0.707916/满幅0，full/preview gainfade量化关系exact、MP3完整解码。597保护路径首末存在/SHA/bytes/精确mtime及库存保持，包括562旧保护＋封存三首33delivery＋原保护/报告。NEWmetadata从RUNNING/FAILED/COMPLETE均记录真实入口runner，原kernel保持，不另建制作框架。

相同−45dBFS门槛：旧行旅低能量窗12.84%→对照1.69%，旧内部1.99/2.39秒区间不再出现，对照无≥150ms内部低能量段，仅94.34–95.96秒尾1.62秒衰减；−60dBFS也只末尾1.14秒。此为实测能量观察，不授听感，原行旅及其局限/报告不冲销。全部推理已停止，不自动继续重试或扩13主题；待本批听审后按选定风格继续场景配乐、音乐循环及真实混音。第一批已认可音效保留，后续动作语义接入仍另做。

用户随后明确选择“好，那就继续用本地stable模型”。已授权恢复现有Small Music离线CPU实际推理，按当前个人暂不商用用途制作NEW三首完整乐段：探索96秒、行旅96秒、战斗72秒。沿首批认可的武侠乐器方向，修改为完整4/8小节主旋律与持续轻伴奏；不用云API、不新增下载、不覆盖旧v9中断或v2/v3。先完整试听、不自动剪loop或替换正式引用。本轮固定同runtime/权重revision及原未截幅float wrapper、8steps/6threads，NEW计划/制作/QA目录名`wuxia_stable_personal_continuation_20261009`。旧商业gate保持，不假传登记/收入旗。

这三首已实际自然OS0完成，全段96/96/72秒＋各30秒预览，原float32/完整日志/decoder/prompt/seed/许可均保存。[制作与试听说明](../assets/processed/audio/wuxia_stable_personal_continuation_20261009/README.md)。独立必要QA实际OS0：[three_tracks_offline.json](../assets/processed/audio/wuxia_stable_personal_continuation_qa_20261009/three_tracks_offline.json)，SHA`8eaf20baff08ed38644891b3449324ad318a57dd2cbfd36057bf58d5f4c16b78`绑定manifest`2b75cf877abefb4aa29bd432e4f417f01702095560e26bf70ce0ac6cc5a1d6ac`；3raw/6PCM/6MP3有限非静音、长度与完整解码通过，raw>1及PCM满幅0，gain/fade/预览量化逐样本exact，562保护路径存在/SHA/bytes/精确mtime与冻结库存保持。原9absent临时/备份路径依原不存在状态保护，不创建；最初QA误断言全部存在被拒后只修消费者，未动任何玩家档。

三曲试听RMS分别−22.0000/−24.3181/−23.5958dBFS；行旅/战斗因峰值帽−3dBFS较目标更低，如实保留，不压缩放大。真实CPU XNNPACK推理与全部source/metadata/日志实审通过；可选NPU/OpenVINO告警及其字面ERROR保全，不称clean日志。实际低−45dBFS能量观察：探索仅最后5.24秒衰减、战斗仅尾3.38秒，行旅存在1.99/2.39秒内部低能量段。技术通过不授连贯听感，三首仍`LISTENING_PENDING`。针对用户断续反馈，仅补一个同方向96秒行旅对照、seed20261009122、加强持续轻琵琶/二胡伴奏，NEW`wuxia_stable_personal_journey_alt_20261009`；旧三首封存不改，不扩更多主题或无限重试。该对照入口只内存包装原kernel输出metadata以保存真实runner身份，原kernel保持；独立source review通过后已本地启动。

2026-10-09最新用户听完v3评价“好一点点”，仍询问直接可调用接口或制作方法；记为`PARTIAL_IMPROVEMENT_NOT_ADOPTED`，不授采用批准，不再自动扩v4。已核官方接口：Stable Audio 3 Large云API支持text/audio/inpaint，文本生成端点`POST /v2beta/audio/stable-audio/text-to-audio`返回202/id，结果`GET /v2beta/audio/results/{id}`；官方当前26credits/成功次、1credit=$0.01，需API key与余额。已跑通本地Small与云Large不是同一模型，不能保证云端武侠质量。参考[正式平台文档](https://platform.stability.ai/docs/api-reference)、[价格](https://platform.stability.ai/pricing)、[官方模型与分轨说明](https://stability.ai/explainers/ai-music-stems-and-audio-inpainting-generating-parts-instead-of-finished-songs)。

另一正式接口为ElevenLabs `POST /v1/music`，Music v2.5支持composition plan/chunk上下文、局部重做与参考音频；`force_instrumental`只可随prompt使用，不能与composition_plan混用。其Music API需付费订阅/key，本轮未开通或调用；见[接口](https://elevenlabs.io/docs/api-reference/music/compose)、[编曲计划](https://elevenlabs.io/docs/eleven-api/guides/how-to/music/composition-plans)、[付费API条件](https://elevenlabs.io/docs/eleven-api/guides/cookbooks/music)。[ACE-Step 1.5官方](https://github.com/ace-step/ACE-Step-1.5)提供Python/自建REST、参考/cover/repaint，需另部署且本机未完成实际推理。推荐完整长乐句生成或“自主旋律/结构草稿→参考改编→局部修复→循环混音”，避免继续仅拼单音；三路线均尚无新的实际音频质量证据。本轮只查公开文档/现有源码，没有上传音乐、消耗API额度或修改正式引用。

用户已试听自主采样v2，明确评价“还是差一些，音乐不连贯，断断续续的声音”；v2当前状态为`USER_REJECTED`，旧技术通过不授音乐质量信用，原始报告与文件保留。用户授权再做一次自主制作，若仍不合适继续首批已认可的Stable Audio方向；最新用途说明为“目前还是个人使用，暂时不商用”。本次按该个人评估事实执行，不继续用此前商业未登记状态阻塞个人试作，也不据此授未来商业用途许可。

本次仅NEW一首连续探索v3：全新长乐句、语句内连音及短呼吸、持续低量筝伴奏和自然尾音。先实际制作独立试听，不扩全套。原12 Dizi标注OGG的共同稳定body为0.80–3.30秒，100ms RMS相对峰−20dB检查无内部长gap；v2谱29.5/64拍休止、每短音单独收尾和稀疏伴奏是当前断续的主要可见原因，不归咎音源内反复停吹。实际听感仍由用户试听判断。

## 目标与范围

用户明确否决后续新增音乐的武侠风格，并确认“现在林西村播放的曲子”符合要求。本次先实际制作独立配乐与动作音效供逐首试听，再按听审结论扩展场景。自主制作优先，保留模型、提示、随机种子、原始输出、处理步骤与文件 SHA。

读文件：音频管理器、战斗控制器、SceneScript 的音乐引用、历代音频生成器、音频专项文档和角色记忆。写文件仅为新 `scripts/audio/` 工具、`tools/audio/` 隔离运行时、`assets/raw/audio/` 候选、`assets/processed/audio/` 检查报告及本轮文档与进展记忆。当前正式音频、场景和存档不在本次写入范围。

验收：真实模型生成可播放候选；原始与试听文件可追溯；非静音、无 PCM 裁波、时长与声道准确；正式资产和存档保护复核。音乐风格、乐器可信度、是否有不需要的人声、旋律与循环听感由逐首试听决定，技术统计不代替审美批准。

## 当前真实运行引用

只读盘点发现，默认值与实际林西场景引用不同：

- 新游戏入口 `linxi_tutorial` 及 `ch1_s0_linxi_main_walkable` 显式播放 `bgm_village_day_v4.wav`：46 秒、22050Hz、PCM16 双声道，SHA256 前缀 `00842F32`。该曲由既有 RandomMind CC0《Medieval: The Bard's Tale》录音骨架加程序声部制作。
- `AudioManager.DEFAULT_FIELD_BGM` 指向 `bgm_linxi_village_v6.wav`：约37.895秒、正弦谐波合成，SHA256 前缀 `CA4188EF`。不能因文件名带林西，就断言这也是用户认可的实际播放曲。
- 最新仅盘点真实`game/data`：112个SceneScript，111显式BGM（108个v4、3个v5），其中99个canonical（98显式），另8个city候选与5个legacy副本。旧113个v4计数撤回，不把build或缓存计入当前。三个v5场景为`openworld_bianzhou_old_post`、`openworld_jinling_reed_marsh`、`openworld_xiangzhou_mine_valley`。
- 战斗控制器仍显式引用五类 v4 战斗音乐。仅改默认值不能完成全场景重制。
- 现有剑、刀、棍、掌、金属与身体受击音效主要由噪声、扫频和合成冲击生成，没有真实兵器采样。

用户的林西听感认可优先于旧文档中的文件名推断。首批试听保留实际入口 v4 与默认 v6 两个可播放对照，后续以用户听出的基准继续。

## 制作路线与一手依据

| 工具 | 本轮用途与限制 | 授权依据 |
| --- | --- | --- |
| ACE-Step 1.5 | BGM 主线候选工具，支持无声乐、参考音频及本地生成；本机可尝试低显存模式。实际基础 DiT/text/VAE 下载约6.34GB，不含语言模型；初次安装与现有 Torch 版本存在兼容成本。 | [官方代码](https://github.com/ace-step/ACE-Step-1.5)与[权重模型卡](https://huggingface.co/ACE-Step/Ace-Step1.5)标为 MIT。 |
| Stable Audio 3 optimized | 首批实际落地的官方 Windows CPU TFLite 路线，Small Music 与 Small SFX；用户曾要求停止其功能，最新授权自主再试一次、不合适则恢复个人非商用试作。 | [官方运行时](https://github.com/Stability-AI/stable-audio-3/tree/main/optimized/tflite)、[权重](https://huggingface.co/stabilityai/stable-audio-3-optimized)。代码 MIT；权重适用 Stability Community 与附带 Gemma 条款。此前商业未登记事实保留；最新个人暂不商用试作用途另按本地权重许可第2节评估，不授未来商业资格。[官方自托管说明](https://kb.stability.ai/knowledge-base/stable-audio-commerical-and-usage-licensing)。 |
| MOSS-SoundEffect v2.0 | 中文描述音效的后续路线；本轮不把未验证的 CUDA 显存需求说成轻量。 | [官方推理代码](https://github.com/OpenMOSS/MOSS-TTS/tree/main/moss_soundeffect_v2)、[Apache-2.0 模型卡](https://huggingface.co/OpenMOSS-Team/MOSS-SoundEffect-v2.0)。 |

不从网页复制未核实授权的曲目，不将提示词里的“古琴／箫”当作实际乐器质量证据。首批按山间探索、江湖行旅、交锋战斗设计三种独立方向，避免持续合成低音、厚铜管、规则钢琴琶音和现代流行鼓组。短动作音效强调干净单事件与可控尾音。

## 当前状态

本机真实模型制作与独立技术检查已完成。BGM 首次30秒验证及三首45秒候选均自然 OS0；Small-SFX 四次6秒原始推理均自然 OS0。CPU 推理，未启动 Godot。固定官方 runtime revision `3a82c807b69cf4b7c5c05270011a5d5e47abac18`，权重 revision `a0109036e3009e47ba7dcb8a2fec7ee6ac0d1ef8`；全部模型文件核对官方 LFS SHA。

### 试听入口

用户已明确评价“这批音乐音效质量很高，就照这个方向”，首批三首配乐与四类音效的听感方向获认可。新的循环版本、后续主题与实际游戏混音仍须分别验收，不能将首批认可扩大为全部正式接入批准。

| 候选 | 方向 | 试听 |
| --- | --- | --- |
| 山间清游 | 古琴／洞箫、疏朗探索；45秒 | [MP3](../assets/raw/audio/wuxia_ai_trial_20261009/mountain_xiao_guqin_45s_audition.mp3) |
| 江湖行旅 | 琵琶／笛子、江湖行旅；45秒 | [MP3](../assets/raw/audio/wuxia_ai_trial_20261009/jianghu_pipa_dizi_45s_audition.mp3) |
| 拔剑交锋 | 琵琶／堂鼓、武侠交锋；45秒 | [MP3](../assets/raw/audio/wuxia_ai_trial_20261009/combat_pipa_tanggu_45s_audition.mp3) |
| 动作音效合集 | 出鞘、挥剑、格挡、布衣掌击，各两次 | [MP3](../assets/raw/audio/wuxia_sfx_ai_trial_20261009/wuxia_sfx_ai_audition.mp3) |
| 林西实际场景对照 | 保留现役完整文件 | [WAV](../game/art/audio/bgm/bgm_village_day_v4.wav) |

原始模型 WAV 使用未截幅 IEEE float32，未混入旧曲。BGM 新试听版仅线性增益和首尾各662帧淡化，目标 RMS −22dBFS、峰值上限 −3dBFS；行旅因峰值上限实际 RMS −24.99dBFS，其他两首约−22dBFS。原始、第一版试听、首次验证及新音量对照版分别保留。MP3 192kbps 供方便试听，PCM 验证以 WAV 为准。

四类音效的完整6秒原始模型输出保留；自动选最高 RMS 事件的短裁剪分别为0.709／0.205／0.369／0.165秒，加首尾各88帧淡化。事件自动选取不是动作语义批准；完整原始音频可能包含多次事件，应结合试听审查。BGM 只有边缘淡化，尚未制作无缝乐句循环。

### 验证与追溯

[独立技术报告](../assets/processed/audio/wuxia_trial_20261009_technical_report.json)实际通过：20个 WAV 有限、非静音；整数 PCM 满幅采样0、原始浮点超1采样0；8个 MP3 完整解码；12条原始→派生处理关系及9份 decoder／source 记录一致。BGM 逐 PCM 差值0，SFX 量化差不超过1LSB。279项现役音频／场景／音频代码与15玩家路径，检查前后存在性、SHA、大小、精确mtime保持；首次验证音频亦保持。Python 新脚本编译通过。报告 SHA256 `d313c81a` 前缀；以当前完整报告为准。

首轮独立 BGM 检查因 RMS 行／声道累加顺序相差1个 Float64 ULP 而拒绝元数据；首报告保留，明确按实际声道优先排列独立重算后通过，未改任何音频或增大容差。LiteRT 可选 NPU／OpenVINO 插件缺失日志保留，不能称 stderr clean。

BGM 完整制作记录在 [README](../assets/raw/audio/wuxia_ai_trial_20261009/README.md)、[交付清单](../assets/raw/audio/wuxia_ai_trial_20261009/delivery_manifest.json)；SFX 在 [manifest](../assets/raw/audio/wuxia_sfx_ai_trial_20261009/manifest.json)。两目录保存 prompt、seed、模型与运行时 revision／SHA、许可原文、真实命令与日志。制作工具为 `scripts/audio/produce_wuxia_stable_trial.py`、`make_stable_wuxia_auditions.py`、`generate_stable_sfx_trial.py`；独立检查为 `verify_wuxia_audio_trial.py`。模型和隔离环境留在 `tools/audio/` 并忽略提交；未安装到全局环境，未调用付费 API。

首批听感方向已获用户认可；循环、商业模型使用资格及正式采用仍未完成。用户随后曾明确项目为商业用途且尚未向 Stability 登记，当时已停止新推理。许可第3节要求商业模型使用登记，超过其收入门槛须另取许可；输出权利条款不能代替模型使用许可。最新用户说明当前个人暂不商用，且授权自主再试一次、不合适则回该模型个人评估；历史停用事实与今后用途分别记录。

用户此前要求“现在不用它功能，你自己参考能做制作麽”，制作方向改为助手自主写旋律与编配、使用已核实许可的乐器单音采样进行离线演奏。参考仅为认可的风格，不从已认可曲目提取旋律或借另一模型替代 Stable。探索与战斗两个原创v2小样已制作并被用户否决连续性；最新唯一自主重试为文首说明的v3。

## 后续接入

当前先执行用户授权的最后一次自主连续探索v3；如果仍不合适，按用户最新个人暂不商用事实回到首批认可的Stable Audio方向。原13主题模型扩展计划仍归档，不自动展开。处理乐句循环、响度与场景交叉淡入时分别验收；后续逐项修改真实 SceneScript 与战斗引用，保留林西已认可曲。音效需按武器与动作语义替换，再检查真实战斗中重叠、音量与响应。发布及当前格式保存读档另做实际验收，不能用本轮离线 WAV 检查代替。

只读系统分析还发现：现役 `METAL_HIT_SFX` 是剑／刀成功判定前的通用 cue，不是格挡；`DEFAULT_DEFEND_SFX` 是进入防御状态的 cue。不能因为新的金属格挡音效质量获认可就替换这两个事件。出鞘与格挡暂须可靠动作 hook；剑挥可候选映射 sword cast，布衣掌击可候选映射明确的 palm impact，通用受击与其他武器不可盲套。

### 已保存输出的循环处理归档

在用户改为自主编曲前，已完成三首既有 raw 的循环处理：山间32.084535秒、行旅22.488889秒、交锋24.988209秒。没有用新模型输出制作这三loop。每首有循环WAV／MP3与10秒边界试听（上一循环末5秒＋下一循环首5秒）。[独立离线循环报告](../assets/processed/audio/wuxia_audio_loop_qa_20261009/three_existing_loops_offline.json)检查三选区、交叠和增益逐PCM差0，边界试听逐PCM差0，6MP3完整解码，无NaN／整数满幅；279现役＋15玩家＋79首批文件的SHA与精确mtime继续保持。普通WAV没有持久Godot loop flag，仍须运行时显式设置；未启动Godot、未授无可闻接缝或正式游戏信用。循环目录 `assets/processed/audio/wuxia_audio_bank_v9_20261009/` 现归档保留。

商业状态消息到达前，13主题计划中的首项 journey96秒推理曾启动，到DiT第2/8步；收到用户“商业项目，尚未完成登记”后立即中断，退出1、没有新raw WAV。原日志及 `assets/raw/audio/wuxia_audio_bank_v9_20261009/journey_v9.interruption.json` 保留，不记为完成，也不声称从未启动。当前自主作曲路线不调用该模型。

## 自主原创作曲小样（不调用音乐生成模型）

已实际写谱并离线演奏两首新曲，旋律不取自首批生成音乐或现成曲目。谱为 `scripts/audio/wuxia_original_trial_score_20261009.json`，原始SHA前缀 `c97613e1`；固定音高、起拍、时值、力度及奏法，提供480 PPQ标准MIDI。MIDI只交换乐谱，实际音频按记录的采样map演奏，并非自包含音源。探索《山径问云》16小节、80BPM，48秒乐谱＋2秒尾音；战斗《临风试锋》24小节、128BPM，45秒乐谱＋2.5秒尾音。两曲各四段变化，探索有呼吸留白，战斗发展相同新写动机与错位打击节奏。

| 历史v2候选（用户已否决连续性） | 实际时长 | 音高校准版归档试听 |
| --- | --- | --- |
| 山径问云 · 探索 | 50秒 | [MP3](../assets/processed/audio/wuxia_original_trial_v2_20261009/original_exploration_audition.mp3) |
| 临风试锋 · 战斗 | 47.5秒 | [MP3](../assets/processed/audio/wuxia_original_trial_v2_20261009/original_combat_audition.mp3) |

音源使用[官方 VCSL CC0库](https://github.com/sgossner/VCSL)，固定commit `c1ea7bcc3c7309650ab0da9d15c9cd1fbc4a4c7e`，逐文件官方Git blob与SHA256核验。拨弦实际是越南 đàn tranh 筝，为古筝近缘替代；大鼓、锣和木块是通用真实打击采样，不冒称古琴、琵琶或堂鼓。另使用[Hypnotriod的Dizi标注单音](https://freesound.org/people/Hypnotriod/packs/21613/)，12条逐页CC0许可／HTML／SHA留存，只取公开有损OGG预览；真人笛子录音来源未证实。实际基音为MIDI67–78，而非直接照抄标题八度。高位旋律MIDI83需由最高音移调约5半音，音色是否合适待试听。

制作首版曾按VCSL文件名推定筝的八度，独立QA实际14源多窗自相关与谐波比较证明其音名采用不同惯例：旧root低12半音。首版波形／MIDI／源码／源map及失败报告完整保留，不授正确音高信用。NEW v2仅读取原谱与冻结渲染核，采用独立实测19源根音／细调，补5个同commit低音区单音，重新渲染两曲；没有改变旋律或调用模型。首版原始目录 `assets/raw/audio/wuxia_original_trial_20261009/` 与处理目录同名保持；当前版为 `assets/raw/audio/wuxia_original_trial_v2_20261009/`、`assets/processed/audio/wuxia_original_trial_v2_20261009/`。

笛子便利PCM16副本曾在1文件的2个样本微量截幅，原件／失败保留；本次两版制作始终直接将原OGG解码为浮点，未使用该副本。另有NEW未截幅float32备份，仅供后续采样器使用；独立libav与libsndfile解码相差约3.58e−7至5.96e−7，如实记录，不称跨解码器逐位一致。该源问题不冒称整首新音乐失败，也不从归档中抹去。

每首提供5个float32分轨、未截幅float32原混音、PCM16试听WAV及192kbps MP3。最终仅线性增益，目标RMS−22dBFS、峰值上限−3dBFS、两端662帧淡化，不使用振荡器配乐、电子鼓或持续pad。首版真实渲染OS0约6.4秒，v2真实OS0约6.8秒；v2作者观测探索RMS−22.00024dBFS／峰值0.4123，战斗−22.00083／0.5907。示例有自然结尾，本轮不授无缝循环或正式游戏采用信用。制作工具 `compose_wuxia_original_trial.py` 与NEW `compose_wuxia_original_trial_v2.py`，完整出处与处理步骤见当前版README／manifest。

[最终独立离线报告](../assets/processed/audio/wuxia_original_qa_20261009/original_v2_two_tracks_offline.json)实际OS0、两曲技术通过，SHA256 `23dc8dd46644e8d197e45f84413f3c4718ed5a8f226f8eff2363851306d98c62`；绑定finalmanifest `e2375fd0b24e24c985605d8d117625eb6f6f0c3fb7f93a951f74ac8791a8fc78`。独立SMF解析61／194事件及tempo／48／45秒谱长，19筝源实测根音与每个事件的调音／重采样一致；10分轨、2rawmix、2PCM与2MP3完整检查，float32声部之和逐样本一致，gain／fade／量化逐PCM差0，整数满幅0、峰值0.412262／0.590698。探索bass_drum按谱0事件而全零，不声称所有声部非静音。279现役＋15玩家＋79首批与首版原创20文件的SHA／精确mtime保持，Python编译通过。

第一报告因Dizi行未承诺size而QA误按必填导致KeyError，原FAIL保留；NEW消费者只在该源行核SHA并另观察实际bytes，输出／谱／MIDI仍严格size＋SHA。原retry1只有字节混音通过，未含pitch gate，不能代替final v2。没有启动Godot、替换正式曲或调用模型；用户随后已否决这两曲的音乐连续性，首批认可不能自动转移到此路线。

## 最后一次自主连续版v3：云径长歌

NEW实际渲染自然OS0，全曲55.833333秒（16小节、72BPM、53.333333秒乐谱＋2.5秒尾音）。全新四段长乐句，32主奏音各1.5–2.5拍；三次段间各0.35拍呼吸，总谱休止1.05/64拍。语句内每音前后各延展60ms，120ms互补sin²/cos²包络真实交叠。音域66–78、只取实测稳定body且不足长度明确拒绝，不循环或重复拼接；持续真实筝轮指＋低量拨弦，以及单独保存的短房间反射声部。没有新增音乐模型调用，没有在旧谱上仅加回声冒新作。

[完整约56秒试听](../assets/processed/audio/wuxia_original_continuous_v3_20261009/v3_continuous_exploration_audition.mp3)，[前20秒预览](../assets/processed/audio/wuxia_original_continuous_v3_20261009/v3_first20s_audition.mp3)，[制作说明](../assets/processed/audio/wuxia_original_continuous_v3_20261009/README.md)。NEW脚本`compose_wuxia_original_continuous_v3.py`、独立新谱、MIDI、四分轨、原float混音、全曲/短预览PCM及MP3齐备。作者观测试听RMS−22.00002dBFS、峰值0.4683；音乐段533个100ms窗相对峰RMS低于−20dB窗为0，仅能量观察，不授听感。

[独立音源body报告](../assets/raw/audio/wuxia_original_body_analysis_v3_20261009/dizi_stable_body_analysis.json) SHA`914666e5832c0b580330dc5428d3d5ae4d475e184d4d2270e59018f6a30ca16e`绑定12原OGG SHA及实际多窗f0；只读源码复核确认body区间、8位小数center精度、120ms互补包络与不loop成立。当前v3状态为`LISTENING_PENDING`；这是用户授权的一次自主重试，不自动v4/v5。若听感仍不通过，后续执行用户已授权的Stable个人非商用试作方向。旧v2否决不冲销，现役林西曲与游戏引用保持。

[v3必要独立离线QA](../assets/processed/audio/wuxia_original_continuous_v3_qa_20261009/v3_final_offline.json)实际OS0，SHA`63f4713e843ab27251539c8604705f436c0a763ed3774c438713d27ba94be453`绑定finalmanifest`c212476536a264894123ac8abbe015972b8e83747d4f965074e10f696c5b7e21`。四分轨及raw mix有限/非静音；float声部和、声明room反射、增益/边缘fade及完整/预览量化PCM均exact，2MP3完整解码、2PCM满幅0。520保护文件存在/SHA/bytes/精确mtime与冻结库存保持，含279现役/15玩家/79首批/所有旧原创与v2及源map。

同一50ms RMS/10ms hop、−45dBFS门槛，分别限定音乐段：v2探索主奏低能量窗38.07%→v3 1.05%，混音11.93%→0；v2混音最长低能量间隔0.71秒，v3无≥150ms该类间隔。主奏事件覆盖60.07%→99.03%、交叠0→6.3%；v3主奏三次句间0.18–0.19秒低能量对应设计呼吸。能量与事件覆盖是本次连续性证据，不等于乐句自然、武侠音色或专业听审通过。原body单音演奏不由QA重写采样器，核源SHA/事件映射与独立实际波形即可；未扩游戏或模型测试。
