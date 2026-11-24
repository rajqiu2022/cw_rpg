# Windows x64 Release 实测 · 2026-11-22

安装包使用 Godot 4.6.2 官方 Windows x86_64 Release 模板。完整解压后运行 `YunYing.exe`，将 `YunYing.pck` 留在同一目录。玩家进度仍写在 `%APPDATA%\Godot\app_userdata\云影侠传`。本次测试使用独立用户数据目录。

[Windows x64 ZIP，18.42 GB](../../dist/YunYing-Windows-x64-Release-20261122.zip) · [本机已解压的 EXE](../../dist/YunYing-Windows-x64/YunYing.exe)。完整解压占用 23.27 GB。

## 正常入口与存档

| 步骤 | 实际结果 |
|---|---|
| 新游戏 | 主菜单点「新游戏」，进入林西师傅院落。新角色从 (1450, 2140) 向北步行。 |
| 第三章旧档 | 从主菜单读入先前试玩留下的 v14、9 级封禁石窟存档。密探胜旗尚未设置。走到石窟交互点，完成对白、战斗和货箱调查，升到 10 级，进入第三章结算。 |
| 进洛阳 | 在结算页选「进入第 4 章」，到洛阳城门 (1536, 1860)。通过地图原有出口进入府衙，触发入衙对白和案情榜调查。 |
| 城内存档 | 在系统菜单选「存档」并写入界面上的「存档二」。磁盘文件为 `save_1.json`，第四章、10 级、府衙和调查线索均在档内。退出进程。 |
| 冷启动续玩 | 从新进程的主菜单选择「存档二」，恢复到府衙 (1300.422, 1693.525)，与保存位置相差 0。洛阳调查任务已完成，古寺、码头目击者任务仍在进行。按方向键移动后走正式出口抵达运河码头 (260, 790)。 |

[第三章原始旧档](../../reports/tomb_docks_20261122/late_campaign_trials/profile/roaming/Godot/app_userdata/云影侠传/save_0.json) · [本轮府衙存档副本](../../reports/windows_release_20261122/luoyang-slot-2.json) · [旧档到城内存档日志](../../reports/windows_release_20261122/story05.log) · [重启日志](../../reports/windows_release_20261122/restart05.log)

[新游戏进林西](../../reports/windows_release_20261122/zip-clean-linxi.jpg) · [第三章结算](../../reports/windows_release_20261122/02-chapter3.jpg) · [洛阳城门](../../reports/windows_release_20261122/03-luoyang.jpg) · [府衙保存成功](../../reports/windows_release_20261122/04-city-save.jpg) · [重启落点](../../reports/windows_release_20261122/05-restart.jpg) · [步行续至码头](../../reports/windows_release_20261122/06-docks.jpg)

## 导出修复

- 游戏运行时会按原始字节验证地图脚本、资源和来源清单。Windows 构建使用独立 PCK，同时收录原始文件、Godot 导入映射和编译资源。发行包的全局脚本注册表将旧备份中的背景分块类指回正式实现。
- 早期候选包在石窟对白报错。原 MP3 已打入，中文文件名对应的导入产物缺失。构建现在读取导入配置中的完整路径，补齐 886 个语音产物。最终清单逐条核对 10,454 个导入引用，全部有目标文件。[首次复现](../../reports/windows_release_20261122/story02.log)
- 另一个候选包能读入旧档并打完石窟，到洛阳城门时缺少来源数据，地图校验拒绝交接。构建改为从游戏的城门、府衙、码头和市街校验器直接枚举 4,102 个不同的依赖文件，补回 838 项。地图和旧档继续使用原有校验。[拒载记录](../../reports/windows_release_20261122/gateprobe.log) · [修复后的交接记录](../../reports/windows_release_20261122/gateprobe04.log) · [最终构建记录](../../reports/windows_release_20261122/build5.log)

## 测试环境与范围

在同一台 Windows 主机上用 AppContainer 隔离运行。发行进程实测不能打开开发目录里的 `F:\Code\RPG_GAME\game\project.godot`。桌面 OpenGL，NVIDIA GeForce RTX 4080，Release 模式。旧档按字节复制，原档 SHA-256 为 `d5d2d113efc23a60dfe229ac0749b4d8ee436975e109b1b704dce4babf52265d`。

剧情验收在独立测试目录给相同 EXE 和 PCK 加载外置操作脚本，用正式主菜单、走路、交互、招式和存读档界面推进。战斗及行走部分加速，存档和剧情标记由游戏自己写入。另把最终 ZIP 解压到空目录，用窗口消息点击新游戏。首次 Windows 窗口抓取为灰屏，改用引擎自带的录像输出，在第 228 帧确认已到林西，同次运行也写出了第一章林西存档。玩家包包括 EXE、PCK、引擎许可文件三项。[发行版新档日志](../../reports/windows_release_20261122/fresh05.log) · [原包窗口测试](../../reports/windows_release_20261122/zip-plain-check.log) · [解压校验](../../reports/windows_release_20261122/archive-extraction.log) · [发行文件 SHA-256](../../reports/windows_release_20261122/release-SHA256.txt) · [ZIP SHA-256](../../reports/windows_release_20261122/archive-SHA256.txt)

开发工程和发行客户端都仍记录洛阳装饰、NPC 步态、城市导航三个旧模块的来源校验报错，退出时也有纹理释放告警。本轮验收覆盖林西至新档可操作、第三章末至洛阳府衙，以及冷启动后续至码头。其余章节、Steam 客户端和其他显卡兼容性待单独验证。

## 重建

安装 Godot 4.6.2 及其对应的 Windows x86_64 Release 模板，使用已经完成资源导入的游戏工程。从仓库根目录运行下列命令。工作目录使用独立的临时目录。

```powershell
python scripts/build_windows_release.py --editor "<Godot 4.6.2 console.exe 路径>" --template "$env:APPDATA/Godot/export_templates/4.6.2.stable/windows_release_x86_64.exe" --work "$env:TEMP/YunYing-Windows-build" --output "dist/YunYing-Windows-x64"
```
