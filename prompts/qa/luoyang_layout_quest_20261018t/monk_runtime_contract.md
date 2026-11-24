# 守僧素材／单帧接入合同 · 2026-10-18t

状态：模板及单task已登记，离线builtin preflight_v2实际exit0；未调用生图、SDK、网络或Godot。主控唯一一次builtin调用后，实际原图/alpha/身份/尺寸才可审核。来源未披露model/provider/usage/cost时写null，不沿旧gpt-image-2 API meta。生成不是CC0。

## 生成与留存

唯一asset npc_temple_gate_monk_idle_down_1f_v1；1024×1024为意图尺寸，不冒工具实际返回尺寸。一个成年/中年剃发守僧、灰褐粗布袍、布鞋，无武器，固定30°略俯视偏正面、单站立全身；可以两守僧复用，不强造四向/四帧。原图在assets/raw/luoyang_layout_quest_20261018t新路径保原字节。不得拿刑樊天或其它非僧身份当已完成。

原图边缘要真实透明，目标四边10%、身高约78%。输出后测实际mode/宽高、所有边A0/A1/max、A>0/A>=8/A>=64 bbox及数量，目视完整头足/衣袍/手/非卡通/无地影。目标脚[512,约910]只是构图，不是sourceanchor；必须按实际脚底测量。严格留边若失败如实记，不阈值抹alpha、不暗自抠图/补生。

## 已核当前运行规范

- NPCNode现源码SHA67C0F3DEAFEF65445918B5815F4ACDCB4CC577206248F20CD67A998930D00BEA，hframes默认1；仅纹理宽>高才自动宽/高切帧，_hframes<=1不轮动画。因此square独立cutout正常支持单帧，不需要伪四帧strip。
- Root已准机械完整canvas一次LANCZOS到160×160（不裁、不擦alpha、不重绘），由SYSTEM落实真实派生meta/import/RGBA证明；raw原样保持。不得把1024或其它高分raw在scale1直接挂入。
- 现NPCNode CALIBRATED_ADULT_HEIGHT=140。显式_calibrate_adult_body=true且sprite_scale=1后，sprite.scale按首cell Image.get_used_rect()的A>0高度乘140/height，视觉精确140px；不是A>=64/主角8px底边标准。A1尾迹可能影响真实可见比例，必须一并记录，不能擦掉后称原图通过。
- 160单cell与sprite_scale1给原物理22.4×28.8（.14×宽/.18×高）；校准只放大美术，不扩大身体。set_ground_anchored(true)按真实bounds.end.y落脚，并将body collider原offset补偿到真实脚平面。不得再减旧42px或用名义y910代替。
- 新filename不在SMALL_ADULT_FAMILIES，因此单靠path不自动校准；由Task/SYSTEM明确独立数据flag或新afterhook，Root统一审冻结。当前Field34081BD7无需由ART修改。
- **禁止借harbour_life_ground_anchored或district_life_ground_anchored**：当前Field1767/1818一支虽校准，但随后关闭interact_area monitoring/monitorable/拾取，适用于无对白ambient，会使任务守僧不可交互。必须保真实dialog/action/任务门槛。
- movement_mode=idle，walk_sprite_path空，conversation_base_facing=front；只证明一张偏正面静态姿态，不冒四方向对话转身。conversation方向图若无，不伪造四向素材。

## 离线dry-run边界

本轮preflight_builtin_v2.py只本地解析YAML/JSON、比prompt与模板、核1append/旧182977bytes exactprefix与输出absent；无API代码、网络、engine。preflight_v2.json F72DB763AEA015DE40188D9F0C39D3CBD915F07C6F1BB5A384AEE618CBA0D8A0已冻结，不在生成后回填为预检成功。

旧gen_assets.py process_task会选default_model并走API，不识别builtin task execution_backend，故此task始终skip:true，**不执行旧CLI --dry-run、不声称它支持builtin或制造gpt-image-2 meta**。模板供Root builtin prompt审阅，不授权API调用。历史portrait_duqingshan_steady重复2原留；v1全库唯一性FAIL完整保存，v2仅精确证明此次新ID不冲突和所有旧任务/重复数量不变。

待办：Root生成→ART独立目视/alpha/尺寸与实际tool来源meta→SYSTEM160表示转换/import→明确校准但不关交互的任务投影→少量真实NPC/脚点/对话验收。任何前置步骤不授正式可玩。
