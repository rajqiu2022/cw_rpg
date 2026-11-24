# change-id: luoyang-soldier-diversity-20261019y

目标：解决洛阳军士共用黑衣同脸，按年龄、军职、衣甲、武器轮廓制作差异，包含将领；保持城市当前写实2.5D尺度和固定脚锚。

分工：ART核现存标准/素材并登记六身份生成任务；Root读imagegen技能后用默认内置工具执行、检查图并存项目原始文件；SYSTEM只读定位映射/动画/头像实际消费链后提交窄接入方案；QA只写NEW资产/代表场景检查，不改被测代码。

首批范围：青年门卒、壮年巡兵、老卒、弓手、什长、将领六类，每类最多一次builtin尝试，不自动付费fallback、不将模型未知填作gpt-image-2。正式生成前任务必须登记并dry-run。原始失败、尺寸与alpha如实保存；单帧/idle不能冒真实walk，不把旧黑衣行走图接到新身份上。

保护：本轮新鲜923旧路径含15保存首事实在y_root01/guard_before.json；保NPC ID、任务/文化话题、脚位、巡逻路线、碰撞与旧x证据。普通修改不要求退出编辑器。源与图未准备好前不提前覆盖严格运行清单或正式NPC资源。

验收：肉眼区分年龄/脸/服装材质/头盔和武器；同身份动画和头像一致，透明/脚锚/帧数真实通过后才允许接入；只做必要代表场景，不复全城/十室内/完整文化任务链。本记录会区分素材完成、动画完成与正式采用，不能只凭文件生成称已换进游戏。

## 第二阶段：定点武器修订与静态范围收缩

初六次 builtin 实际输出均保留。RAW 初检63项/10失败原报告不改：两图集1774×887不满足直接整数等格，若干外缘有非零 alpha。整图2×NEAREST、精确回采原RGBA再整格归一化仅是机械后继，不将原RAW失败改为通过。Root及QA实看两套行走帧存在同脚在前/近重复姿势，拒收真实八相位与接地帧待机，不把八个不同文件SHA当动画质量证明。

Root另外明确授权且已执行仅两次 builtin EDIT：青年长枪改短兵器、老卒去长枪改腰刀；保留原身份服装，只解决兵器超人体包络的问题。新v2文件/提示词/spec/元数据独立，v1失败不覆盖；无第三次尝试、无CLI fallback、未知模型/费用继续为null。

本轮拟正式范围明确缩为四种静态身份/五个原有NPC：门吏（什长外观）、验货军士（青年）、老漕卒（老卒）、都头（将领外观）、府衙候值军士（青年）。其余七人含五个移动军士和两个驻留巡捕保留原图与原动画。四静态是一帧，不冒称呼吸或全向动画；六身份全量草稿仍NOTREADY。头像沿用原正式资源，不宣新对话立绘/配音完成。

发现用户编辑器51856及其游戏102796仍在运行；不代停。已非阻塞询问只退出游戏用于最后一次代表场景检查，编辑器可以保留。源审、派生素材和NEW候选准备继续进行，未提前覆盖正式三runtime与四城区来源清单。

## 本轮停点与准确交接

四静态结构63/0；Root隔离import和114104验证自然OS0/19ms，四组raw/import/direct ctex全RGBA一致、23params/mip0，四个Image原图解码warning不称clean。仅四新.import/ctex晋升；原始军士资源与正式NPC绑定未改。ART导入handoff8DFAA4有prepared hash一处多e笔误，System不改原证据，manifest采用114104原report的实际64位226F38A3，明确记录来源。权威四别名是successor2E5E1，错误commander SMALL前缀alias保UNBOUND不用。

静态模块67FAA883、manifest306C0132、false index7C6FD8，22叶false闭包DD758426。CPU首次READY仅proper String推断错误保留；NEW retry1 F78B3只显式String，一次actual95736自然OS0/178检查0/161ms，42来源和15保存首末同，1ObjectDB退出warning非clean。五目标Gate2/Yamen2/Docks1/Market0视觉变更正确，七旧军士完整保留；非Field证明。

System stager仅写NEWstaged，Root独立Node254/0检查10旧/候选目标、4完整manifest语义逆、12原artifact及原x115872 source-only加有限delta的四全集733/1058/1470/1263。原整体超时FAIL不改、不复collector。最小6代码patchDBD2DA88及四metadata候选未部署；唯一Gate键5787EBEC/wrapperEC298589 proper0、90/60，固定733来源、32px正常INPUT、2新2旧/三本地nativepair/一图，不是其它区实走。

用户已退出game、editor51856保留。当前空闲显存约1.9GB；Windows GPU计数器实际读到Ollama74364约3.2GiB、editor约4.9GiB。已询问是否允许暂卸Ollama模型（不删除文件），尚无授权，未私停。`candidate_end_guard.json`对fresh predeploy923路径零差，含15保存；22叶false闭包零漂移。玩家游戏阶段save0/bak变化保留，原守卫缺席文件空SHA与新ABSENT标记只是表示差异，不冒实际文件变化。

下一步仅：用户授权释放显存或资源自然足够→Root最小部署六代码/四metadata并逐SHA→唯一Gate实际→最终守卫与试玩交付。未做到之前不称已正式显示、巡逻兵换装完成、肖像配音完成或全城美术完成。
