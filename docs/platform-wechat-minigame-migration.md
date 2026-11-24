# 微信小游戏迁移方案 v0.2

> 决策日期：2026-07-14
> 状态：当前源码的前三章 staging 已完成 Web 导出与官方转换，等待分章 CDN、真实 AppID 与微信开发者工具真机验收。

## 1. 平台决策

项目发布形态定为 **微信小游戏**，不是普通业务型微信小程序。

原因：当前项目是 Godot 4.6 的 WASM/WebGL 游戏形态，包含自由移动、战斗、音频、存档和大量纹理资源。微信官方的小游戏通用引擎适配方案可将 WASM + WebGL 的 H5 游戏包转换为小游戏；普通小程序页面体系不适合直接承载现有引擎运行时。

技术链路：

```text
Godot 4.6 项目
  -> Godot Web 导出（WASM + WebGL）
  -> 微信小游戏通用转换工具
  -> 微信开发者工具
  -> Android / iOS 真机测试
  -> 提审
```

官方依据：

- [微信小游戏开发指南](https://developers.weixin.qq.com/minigame/dev/guide/)
- [微信小游戏引擎适配概述](https://developers.weixin.qq.com/minigame/dev/guide/game-engine/engine-overview.html)
- [通用引擎适配方案](https://developers.weixin.qq.com/minigame/dev/guide/game-engine/common-adaptation.html)

Godot 未列入官方已验证引擎，属于“其他原生引擎，需评估”。因此保留 Godot 技术栈，但必须先通过技术样片门禁。

## 2. 技术样片门禁（WX-P0）

样片只带第一章最短链路，不带第二至第四章正式资源。

验收标准：

- 微信开发者工具可启动，不出现 WASM、WebGL、音频初始化错误。
- 1920x1080 逻辑画布在常见横屏手机上完整适配安全区。
- 触屏可完成移动、交互、战斗选招、打开/关闭背包与任务界面。
- 新游戏 -> 对话 -> 战斗 -> 胜利 -> 保存 -> 重启读取可闭环。
- 首包之外的场景/角色资源可以按需下载并显示加载进度。
- 中档 Android 真机连续运行 15 分钟无崩溃、无持续内存上涨。

未通过 WX-P0 前，不把后三章资源全部打进发布包。

### 2.1 已验证的官方转换链（2026-08-25）

- 官方微信小游戏通用引擎转换工具：`v1.0.33`。
- 官方能力SDK当前版本：`v1.0.3`；Godot自定义引擎的文件系统能力仍需在微信开发者工具/真机确认，不能用桌面`user://`测试代替。
- 当前源码的完整工程PCK为430.49MB；通过前三章资源闭包、未来章节阻断、零字节语音清理和候选UI/VFX裁剪后，试玩 staging PCK降为253.56MB。
- 当前 staging 已成功转换为微信小游戏目录，生成`game.json`、`project.config.json`、`framework.js`、`wasmcode`和远程`webgl/*.data.bin`。
- 转换后WASM Brotli包为6.30MB；不把PCK放入本地数据分包时，主包0.98MB、代码总包7.29MB，满足主包4MB/总包30MB的代码门禁。
- PCK Brotli后仍有240.77MB（仅压缩5%），证明纹理已接近压缩态；后续必须落实公共包+第一/二/三章按章CDN，不能把单一PCK当作最终上线形态。

可复现命令：

```powershell
# 自动下载并校验微信官方转换工具
.\scripts\setup_wechat_transformer.ps1

# 导出当前Godot Web包并转换；真实体验版必须替换AppID与HTTPS CDN
.\scripts\build_wechat_trial.ps1 `
  -AppId "wx_your_app_id" `
  -CdnUrl "https://cdn.example.com/yunying/trial-v1/"
```

本地只验证转换时可使用：

```powershell
.\scripts\build_wechat_trial.ps1 -SkipGodotExport -CdnUrl "http://127.0.0.1:8000/"
```

构建脚本默认先运行`scripts/prepare_wechat_trial_stage.py`生成前三章干净工程，再导出和转换；`-FullProject`仅用于诊断。脚本会生成`game/build/wechat_trial/wechat-package-report.json`并强制检查4MB主包和30MB代码总包；`game/build/`与官方工具二进制均不提交仓库。

转换器模板中的`project.config.json`可能保留示例AppID，因此构建脚本在转换完成后会再次回写本次`-AppId`、项目名和游客标记。导入或上传前执行：

```powershell
# 本地游客构建完整性检查
python scripts/validate_wechat_trial_release.py

# 正式构建检查：额外要求真实wx AppID和非本机HTTPS CDN
python scripts/validate_wechat_trial_release.py --require-real-credentials

# 预检通过后打开微信开发者工具；正式包添加-RequireRealCredentials
.\scripts\open_wechat_trial.ps1
```

Godot 4.6的Emscripten模板会生成简写`glViewport`箭头函数，而微信通用转换器1.0.33会向其中注入多条语句，直接转换会产生非法的`()=>if (...) return;`。`prepare_wechat_framework.py`会在转换前生成不覆盖原文件的`index.wechat.js`，把该函数改成花括号函数体；构建完成后再用`node --input-type=module --check`校验整份`framework.js`。

微信开发者工具运行不能使用`touristappid`：当前工程声明官方`WXGameKit`插件`wxe5a48f1ed5f544b7`，游客模式会报插件模块不存在。`open_wechat_trial.ps1`固定启用`--require-devtools-plugin`，只有测试号或真实`wx...` AppID才能进入模拟器验收。

### 2.2 实际分章PCK（2026-08-25）

- `ContentPackManager`只在`web + wechat_trial`构建启用；桌面版和普通Web版继续直接使用完整资源，不改变内容制作流程。
- 公共工程保留主菜单、存档、autoload、通用UI和轻量数据定义；章节大图、NPC、语音、战斗动画和特效由独立PCK提供。
- `SceneRouter.go_field/go_field_smart/go_field_walkable`在进入场景前统一检查章节包。未缓存时下载到`user://wechat_content_packs/*.part`，完成后校验SHA-256、原子改名并用`ProjectSettings.load_resource_pack(path, false)`挂载。
- 下载期间显示阻塞式进度层；失败显示重试按钮。公共文件禁止被章节包覆盖。
- 当前实测：公共PCK 69.94MiB（转换后`data.bin` 68.58MiB）；第一章拆为林西启动段103.48MiB与竹尾后山段46.92MiB；第二章18.51MiB；第三章14.72MiB。新游戏首次章节下载相较旧第一章整包减少约30.7%。
- 微信最终工程位于`game/build/wechat_trial/minigame`；需要上传CDN的文件为`game/build/wechat_trial/webgl/*.data.bin`和`game/build/wechat_trial/packs/*.pck`。
- 真实CDN必须使用HTTPS并允许小游戏来源跨域访问；构建时传入的`-CdnUrl`会同步写入公共包和四个阶段包的运行清单。
- 独立公共工程挂载烟测18项通过：阶段资源挂载前不存在，挂载相应PCK后可立即由`ResourceLoader`读取。

### 2.3 本地Web/CDN端到端验收（2026-08-25）

- `scripts/serve_wechat_smoke.py`把公共Web产物和最终`packs/`映射到同一测试源，并明确返回CORS响应头；用于在提交微信开发者工具前发现浏览器运行问题。
- 应用内浏览器已完成首次链路：主菜单→点击新游戏→林西启动段103.48MiB HTTP下载→中文进度层→SHA-256校验→PCK挂载→进入林西师徒院落；未提前请求后山、第二章或第三章包。
- 刷新页面后再次点击新游戏不再请求`chapter1_start.pck`，证明浏览器`user://`缓存命中并可直接重新挂载。
- Web没有可靠中文系统字体；`PlatformBridge._init()`设置文楷fallback，并对后续动态Control节点注入同一字体。加载提示、HUD、任务文字、地图标题和NPC名均已浏览器目检正常。
- Web端不再执行`AudioStreamGenerator`静音预热；首次手势继续由`PlatformBridge`解锁WebAudio，本轮重载到进入场景期间新增警告/错误为0。
- 以上只能证明标准Web环境闭环；微信小游戏文件系统适配、HTTPS合法域名、前后台切换和真机内存仍必须在开发者工具/真机验证。
- 本机微信开发者工具已定位并打开到转换工程导入页；游客AppID不能继续正式创建，下一步需由账号持有人选择测试号或提供已认证小游戏AppID。

## 3. 需要新增的适配层

| 模块 | 当前状态 | 微信版要求 |
|---|---|---|
| 导出 | 仅桌面工程 | 增加 Web preset，并转换为小游戏工程 |
| 输入 | 键盘 + 鼠标为主 | 虚拟摇杆/点击移动、触屏交互键、战斗触控 |
| UI | 1920x1080 固定逻辑分辨率 | 横屏安全区、刘海/圆角避让、最小触控热区 |
| 存档 | `user://` 多槽 JSON | 本地文件可用；后续增加微信账号云存档同步层 |
| 音频 | Godot AudioStream | 验证 WebAudio/小游戏音频适配及首次交互解锁 |
| 资源 | 大量 PNG 随包 | 首包只放启动与第一场景，其余按章节资源包加载 |
| 平台能力 | 无 | 登录、分享、隐私、生命周期、前后台暂停 |

当前已落地：

- `PlatformBridge`统一首次用户手势、横屏安全区查询、前后台暂停/恢复与暂停检查点存档。
- Web首次手势前BGM进入待播队列，手势到达后立即播放；暂停时冻结BGM并停止对白，恢复时续播。
- 存档改为临时文件写入、原文件备份、原子提交；主存档损坏时可从`.bak`恢复。
- 触摸转鼠标、鼠标模拟触摸和横屏方向已写入项目设置；微信官方转换工具继续负责底层触摸与screen-adapter。
- 第一至三章机器可读资源分层见`config/wechat-content-pack-plan-v1.json`。
- staging闭包会阻断第4章以后数据和终局绝学，跳过零字节语音与旧`.import`，并仅收集已选招式的独立特效；干净导出不再出现缺失语音错误。

尚未落地：

- 真实AppID下的微信工程导入与设备启动。
- HTTPS CDN与真实域名部署；公共包和四个阶段PCK已生成并完成本地Web挂载，但尚未进行微信真机下载验收。
- 微信文件系统能力SDK或等价Godot适配的真机存档验证。
- 安全区、输入、音频、后台恢复、15分钟内存和完整三章真机验收。

## 4. 发布阶段

1. **WX-P0 技术样片**：第一章最短闭环，验证 Godot 转换可行性。
2. **WX-P1 可玩版**：第一章完整、正式触屏 HUD、正式基础 UI、资源分包。
3. **WX-P2 内容版**：第二章上线，建立逐章下载和版本迁移。
4. **WX-P3 扩展版**：第三、第四章上线，完成五门派分支与云存档。

## 5. 用户侧准备

- 注册并认证微信小游戏开发账号，取得 AppID。
- 安装最新版微信开发者工具。
- 建立小游戏类目与基础资料；名称、图标、简介先使用“云影侠传”。
- AppID 到位后写入本地转换工程配置，不提交密钥或私密配置。

## 6. 风险与回退

- 若 Godot Web 包无法通过通用转换工具或真机性能不达标，回退方案是保留数据与资产，客户端迁移到 Cocos Creator；不在 WX-P0 结论前启动该重写。
- 正式资源必须经过压缩与分包，不能以当前 100MB+ 原图目录直接发布。
- PC 版继续保留为开发和内容验收基线，微信适配不得破坏桌面运行。
