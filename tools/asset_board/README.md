# 洛阳建筑素材板 · 本地试点

这是独立、离线、只读素材事实＋浏览器工作草稿的管理工具，不是 Godot 正式 UI，也不是生成服务。

## 打开与更新

需要 Node.js 18 或更新版本；不安装 npm 包，不启动服务器。

```powershell
node tools/asset_board/build.mjs check
node tools/asset_board/build.mjs build
```

然后直接打开 `docs/luoyang-asset-board.html`。相对图片指向本地仓库，移动 HTML 时必须保持仓库结构。工具只覆盖两个明确派生输出：

- `docs/luoyang-asset-board.html`
- `assets/catalog/catalog-report.json`

输入只读：`luoyang-assets.json`、`luoyang-board.json`、`sprite-contracts.json`。条目 ID 稳定，缺图保留 ID 并报告错误；合法但缺失文件仍能生成可诊断页面，CLI 返回非零。无效 schema、重复 ID、越界路径等直接拒绝构建。工具不写 game、存档、原始图片、任务或正式采用状态。

## 用法

左侧搜索/筛选素材，点击查看右侧来源；点「加入对照」查看多张完整图片。明暗底便于观察透明轮廓，缩放只改变显示；图片保持比例，不拉伸、不裁成新资源。加载失败明确显示路径错误。这里没有真正的透明像素检查或绘图功能。

选择、制作说明、每素材备注保存为浏览器工作草稿，最多 20 项。`file://` 下部分浏览器不支持 localStorage，页面会提示并保持当次内存操作，可导出草稿保存。导入失败不改变原有状态。草稿不允许路径/采用状态字段、未知 ID、prototype 键、嵌套过深或超过 1MiB。

参考包只能包含 1–14 张素材；超过 14 项仍可导出草稿，但参考包按钮禁用。包中保留素材事实、当前 SHA、路径、来源证据与关联精灵规范，附可编辑的简体中文制作说明。导出后若需要交给生成流程，先把下载文件放到仓库内明确目录，例如 `assets/catalog/luoyang-reference-package.json`，再核验：

```powershell
node tools/asset_board/build.mjs refs assets/catalog/luoyang-reference-package.json
```

`refs` 会重新读取当前索引和文件，严格比较 ID、路径、SHA、预览、来源及精灵合同；来源证据与现役引用另带实际文件 SHA/bytes，原路径下内容变化也会拒绝旧包。未选素材的缺失另列在输出诊断，不阻塞本包合法选图，也不授整目录 clean。输出人工准备资料到 stdout。它不会调用接口、提交付费任务或自动修改 `prompts/tasks.yaml`。人工将通过核验的参考路径配置到原有任务，再按现有流程先 `--dry-run`。

## 检查边界

- 已采用（adopted）只是索引登记的当前源码引用事实，不是工具自动决定的正式状态，也不是艺术质量或许可审核通过。工具检查引用文件存在/SHA，不解释整条 Godot 引用链语义。
- 18 张 PNG＋2 张 JPEG 使用真实文件头取得尺寸，完整文件以 SHA-256 绑定。只检查头结构，不验证 PNG CRC、解码、透明像素、动画朝向/脚底、Physics 或 Godot runtime。
- 来源为 unknown 的条目仍清楚显示待核，不自动变成授权资源。CC0 来源、项目派生、生成素材分别登记，许可证说明保留原文。
- 资源与证据必须是仓库相对路径。拒绝绝对路径、`..`、路径控制符及 symlink/junction 越界；固定派生输出也执行同样约束。索引内容通过 textContent 进入 DOM，内嵌 JSON 转义 `<`。
- 索引变化/图像重新生成后必须重新 build；旧页面导出的 SHA 包会被 `refs` 拒绝，避免使用旧素材事实。

## 测试接口

`build.mjs` 可以直接 import，不会自动启动 CLI 或写输出：

```js
import { inspectCatalog, validateDraft, validateReferencePackage, referenceFacts,
         resolveSafe, imageDimensions, embedJson } from './build.mjs';
const index = await inspectCatalog({ root: repoRoot });
validateDraft(draft, index);
validateReferencePackage(bundle, index);
```

`inspectCatalog` 可用 `{root,catalogPath,boardPath,contractsPath}` 指定临时夹具输入。`buildBoard(root)` 只写固定 HTML/report。浏览器 `window.assetBoard` 暴露只返回副本的 `getDraft()`/`getIndex()`、`validateDraft`、`referenceFacts`，用于独立有限交互 QA。

## 设计参考与许可

工具借鉴 [ohmygame 参考画布](https://github.com/WhiteTowerAI/ohmygame/blob/main/docs/canvas-agent.md) 的共享素材参考思路，以及 [素材目录](https://github.com/WhiteTowerAI/ohmygame/blob/main/src/daemon/canvas-assets.ts) 的目录管理思路。本实现独立编写，未复制上游源码或文档文字；未接入其 daemon、3D 供应商或 Web 自动试玩。上游 Apache-2.0 许可不等于本仓库图片全部拥有同一许可。
