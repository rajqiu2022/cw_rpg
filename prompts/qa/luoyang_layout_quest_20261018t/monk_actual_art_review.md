# 守僧真实首稿／160表示转换审查

有限结论：ART独立view原图与160图，成年/中年剃发僧身份明确，朴素灰褐袍、布鞋、无武器，手足完整，可以作为两个静驻守僧的身份素材候选。Root另实看认可。只单帧，不授四向/走路动画或已正式；实际偏正面略俯视，不能从图像证明精确30°相机。

Root唯一builtin调用1次；未披露model/provider/usage/cost，meta均null，未沿用旧API元数据。原tool路径与workspace raw逐SHA同49A326BA8636B47ADF51041DEACCC9659F5AB1AC5C920940FAC1211AFCC99955，835772字节，**实际1254×1254 RGBA**，不是prompt1024或预览显示1280。尺寸不符作为原失败保留，不补生。

raw A>0 bbox[0,20,1240,1228]；A>=8 [425,65,845,1184]；A>=64 [426,65,844,1184]。左边有12个A1软尾点，其余三边全A0；strict10%及强主体上下10%均FAIL，不擦alpha或阈值裁图。真实alpha统计完整见actual_measurement.json与raw旁meta。

经Root明确授权，ART只执行一次原完整canvas LANCZOS→160×160派生，不裁、不调色、不擦alpha、不重绘、不生成重复帧。新game/art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png为16832字节，SHA6268061EAB18D2BF8C1EA0C13873F0D718FEB82A119F00A67EDF7C52BCB077AD；原raw未动。脚本只对absent目标执行一次，脚本启动后的一次终端JSON封装因Pillow弃用warning前缀解析失败不影响PNG生成；随后只解析已捕获stdout保存统计，**没有重跑resize脚本**。Pillow getdata弃用warning保留，非运行时图片失败。

160四边全A0，A>0 bbox[52,6,110,154]高148；A>=8 [54,8,108,152]；A>=64 [54,8,108,151]。目标140px视觉比例140/148=0.9459459459459459；现NPCNode非cal名义脚线.45×160与真实used_rect.end.y的偏差乘该比例为1.8918918919px，≤12。此为当前源码与像素算术，非引擎实际脚点验收。普通非cal碰撞随此比例为21.189189×27.243243；显式校准且sprite_scale1则保持22.4×28.8，二者不可混称同身体。

Root已指定MONK_PORTRAIT=MONK_SPRITE，即正确身份全身图作为非空对话图，避免genericfallback；不是最终头像，不再crop/生图/拷新肖像。TaskAgent收到真实路径/SHA/比例。不能使用会关闭交互的harbour/district环境NPC标记偷借校准。保持原任务、NPCid、对话、出口语义由Task/SYSTEM负责。

prompts/tasks.yaml本项已attempts_used1，状态为GENERATED_SOURCE_ART_IDENTITY_ACCEPTED_CANDIDATE_RUNTIME_IMPORT_PENDING；所有历史任务前182977字节不变，旧preflight_v1失败/preflight_v2原输出/spec/prompt保持，未在生成后改成预检PASS。

ART未运行Godot/import/改任何livecode或用户进程。下步仅Root隔离导入与SYSTEM真实节点/对话薄验收，不授完整sprite规范、最终头像或正式接入。
