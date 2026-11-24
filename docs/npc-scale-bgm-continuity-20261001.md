# 成人 NPC 有效身高校准与同曲跨场景续播 · 2026-10-01

## 本轮结果

- 修正林西南坊药铺学徒、巡村老兵及复用同一素材的守卫／店小二大小不一致。不是统一把所有 NPC 放大：仅校准 `npc_zhuwei_gate_guard_*`、`npc_zhuwei_inn_waiter_*`、`npc_escort_guard_*` 三个已审查成人素材家族。
- 同一 BGM 经过 SceneRouter、Loading 和 Field 的重复进场请求后，保留原 AudioStreamPlayer、AudioStream 与播放位置；不同曲目仍使用双播放器交叉淡化。
- 205 项专项 0 失败；28 条场景 NPC 记录覆盖共享家族。旧 NPC 对话／巡逻专项、BGM 换曲专项和严格导入均 exit 0。
- 本轮没有制作或替换音乐，不代表已有曲目的武侠风格已获听觉认可。未改存档 schema、NPC 对白、战斗数值、正式地图或 Web／微信导出包。

## 根因与实现

### NPC

原素材画布同为 640×160 四帧条带，但第一帧非透明可见身高不同：店小二／持枪守卫 120px，护商镖师新版 127px，普通村民和旧镖师 140px。原代码只乘场景 scale，忽略人物在透明画布中的大小。

`NPCNode` 对三个已审查家族按首帧可见 alpha 高度校准到 140px 的素材基准，再乘既有 NPC scale 与场景 `npc_visual_scale`。透明边缘测量每个 Texture 实例缓存一次，非逐帧读图；不适用于坐姿人物，也不盲目扩大其余成人、老人或儿童。切换 idle、walk、对话方向及 Field 运行纹理时都从原比例重算，不累乘。

校准后的视觉使用 alpha 下沿脚底定位。脚底坐标模式仍保持原世界脚点，旧中心坐标模式保持原作者声明的深度脚平面；身体 StaticBody 碰撞宽高继续用原 `sprite_scale`，不随美术扩大。名字根据有效头顶而非透明画布顶边定位。Field 删除再次直接设置 Sprite.scale 的语句，所有最终缩放由 NPCNode 单一管理。

真实 Field 测得的世界像素高度（镜头缩放前）：

| 场景人物 | 原身高 | 修后身高 |
| --- | ---: | ---: |
| 南坊药铺学徒 | 70.656 | 82.432 |
| 南坊巡村老兵 | 69.120 | 80.640 |
| 南坊归田村民（对照，未改） | 86.016 | 86.016 |
| 金陵水巡 | 123.600 | 144.200 |

实机查看 1920×1080 南坊及金陵两张截图：学徒／老兵已接近同场村民；金陵持枪守卫与主角接近，不再明显矮小。南坊人物 scale 0.92／0.90 与对照村民 0.96 的轻微差异保留。

### BGM

原 `play_bgm` 判同曲需要 `path == current_path` **且** `context == current_context`。context 为 scene_id，进入同曲的另一地图时条件必不成立，触发播放器交换并重新 seek 到该场景的四分之一乐句。

现判同曲不再比较场景 context。规范路径支持空白去除、斜线、`.`／`..` 和 ResourceUID；不同请求地址也复核有效 AudioStream 身份／规范资源路径。同曲请求只更新 context 元数据，不 stop、play、seek、不重新发 `bgm_changed`。context 乐句选择仍只用于真正换曲的首次播放。

另外保护显式 stop 尚在淡出期间又请求同曲的竞态：取消旧停止请求并恢复音量，不重启 playhead。平台暂停的 `stream_paused=true` 也作为有效当前播放识别，因为暂停时 Godot 的 `playing` 可为 false；恢复只解除暂停，不错误重开同曲。明确等待完成的 stop 仍生效。

真实 SceneRouter 从 `linxi_village_center` 切到 `linxi_village_scrollmap`，两地图都声明 village_day_v4：同播放器 ID 87694509758，播放位置 17.099→18.213 秒，曲目变更事件 0。OpenGL + Dummy 重测同样保持播放器，17.099→18.120 秒、变更事件 0。LoadingManager 与 Field 退出路径未发现自动 `stop_bgm`；Field 的 EventBus 和显式 ensure 双调用现在均幂等。

## 本轮改动范围（不是从 Git HEAD 起的整份脏 diff）

- `game/scripts/autoload/audio_manager.gd`：新增 `_bgm_stop_pending`、`_normalized_audio_path`、`_cancel_pending_bgm_stop`；仅改 `play_bgm` 判同曲、换曲清理标记、`stop_bgm` 标记与暂停态识别，以及 `resume_after_platform` 暂停识别。
- `game/scripts/field/npc_node.gd`：新增三个成人素材家族白名单、140px 基准、Texture alpha bounds 缓存；现有纹理切换调用缩放校准；视觉脚底、名字、碰撞分别保持各自合同。
- `game/scripts/field/field_walkable_controller.gd`：仅删除 `_spawn_npcs` 中 `npc.sprite.scale = Vector2.ONE * npc.sprite_scale`，保留 `apply_runtime_idle_texture` 入口。
- 新增 `game/tests/probe_npc_body_heights_20261001.gd` 和 `game/tests/test_npc_scale_bgm_continuity_20261001.gd`。

## 验证命令与证据

在 `F:\Code\RPG_GAME` 的 PowerShell 中，Godot 可执行文件为 `F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe`。

```powershell
$taskGodot = 'F:\文件下载\编程工具\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
& $taskGodot --headless --path game --script res://tests/probe_npc_body_heights_20261001.gd
& $taskGodot --headless --path game --script res://tests/test_npc_scale_bgm_continuity_20261001.gd
& $taskGodot --path game --rendering-driver opengl3 --audio-driver Dummy --script res://tests/test_npc_scale_bgm_continuity_20261001.gd
& $taskGodot --headless --path game --script res://tests/test_bgm_runtime_switch_20260823.gd
& $taskGodot --headless --path game res://tests/test_npc_conversation_state.tscn
& $taskGodot --headless --path game --editor --import --quit
git diff --check -- game/scripts/autoload/audio_manager.gd game/scripts/field/npc_node.gd game/scripts/field/field_walkable_controller.gd
```

全部 exit 0。最终 headless 专项为 205 checks / 0 failures；带保存文件 SHA 断言前的 OpenGL 专项为 204 / 0，额外最终 SHA 断言也在 headless 验证通过。五个用户存档槽及对应备份的存在性／SHA 在测试前后完全相同，无持久化写入。测试没有调用 save/load 或奖励结算，进场变量只存在该测试进程。

截图：

- `game/build/npc_scale_linxi_village_scrollmap_20261001.png`
- `game/build/npc_scale_openworld_jinling_city_20261001.png`

已知验证限制／退出告警：本机自动默认 WASAPI 打开输出设备失败并回退 Dummy；因此之后显式使用 Dummy，证据是播放时序与实例身份，不能证明可听音质或音乐风格。OpenGL 退出仍有既有 3 texture RID、CompressedTexture2D singleton null、ObjectDB 和 1 Resource 在用提示；headless 有 ObjectDB／Resource 退出提示。严格导入仅有既有 `build/wechat_stage` 嵌套 project 提醒，无脚本解析错误。本专项不声称全套历史回归全绿。

## 余项

- 新增不同画布或不同构图的 NPC 需要独立审查后纳入家族，不能把所有资源一律按 alpha 外框规范化（武器、坐姿等会影响外框）。
- 音乐题材、器乐听感和用户否决曲目的重制仍是独立工作，本次只修续播逻辑。
- 重新导出 Web／微信包未执行；当前修复在 Godot 源工程生效。
