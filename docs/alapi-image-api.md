# ALAPI 图像生成接口（项目当前批量管线）

> **用途**：说明本仓库批量出图（`scripts/gen_assets.py`）使用的 **ALAPI** 协议，避免与 DMXAPI / OpenAI 直连混淆。  
> **踩坑与退避策略**：见 `docs/experience-log.md` §19.49。

---

## 1. 与 DMXAPI 的区别

| 项 | DMXAPI | ALAPI（本项目） |
|---|--------|----------------|
| 典型 `OPENAI_BASE_URL` | `https://www.dmxapi.cn/v1` | `https://v3.alapi.cn/api/ai` 或完整到 `.../images/generations` |
| 认证 | `Authorization: Bearer <sk-...>`（OpenAI SDK） | HTTP 头 **`token: <你的 ALAPI token>`**，**不是** Bearer |
| `gen_assets.py` 调用路径 | `AsyncOpenAI.images.generate` | `httpx` 直连 `POST .../images/generations` |
| 参考图 | OpenAI `edits` 或多模态 | JSON 里 `image: [{ type, data: base64 }]`，**建议先压缩 JPEG**（见 §19.49） |

配置 `OPENAI_BASE_URL` 含 `alapi.cn` 时，`gen_assets.py` 内 `detect_backend()` 返回 `alapi`，预算币种按 CNY 估算。

---

## 2. 端点

- **推荐配置根路径**（脚本会自动补全 `/images/generations`）  
  `https://v3.alapi.cn/api/ai`
- **也可配置完整路径**（与根路径等价）  
  `https://v3.alapi.cn/api/ai/images/generations`

实现见 `scripts/gen_assets.py` 中 `_alapi_generations_url()`。

---

## 3. 环境变量（`.env`）

复制 `.env.example` 后启用 **选项 D**，例如：

```env
OPENAI_API_KEY=<你的 ALAPI token，写入 token 头>
OPENAI_BASE_URL=https://v3.alapi.cn/api/ai
OPENAI_IMAGE_MODEL=gpt-image-2
BUDGET_LIMIT_CNY=50.0
```

- `OPENAI_API_KEY` 在 ALAPI 分支下表示 **ALAPI 的 token**，由 `gen_assets` 传入 `headers["token"]`。
- 并发建议保持较低（见 `.env.example` 中 `GEN_CONCURRENCY`）。

---

## 4. 请求体（与脚本一致）

`gen_assets` 组装的 JSON 大致包含：

- `model`：如 `gpt-image-2`
- `prompt`、`n`、`size`、`quality`
- 若有参考图：`image` 为 base64 对象列表（参考图会先被压缩为 JPEG 以减小 payload）

响应解析支持 `code`、`data` 嵌套列表、以及首条的 `b64_json` / `url`。细节以 `scripts/gen_assets.py` 中 `_call_alapi_generation` 为准。

---

## 5. 其它脚本

部分一次性脚本可能**硬编码** ALAPI URL（例如 `scripts/gen_main_menu_bright.py`）。新增工具时请优先复用 `gen_assets.py` 或同一套 `token` 头约定，避免混用 Bearer。

---

## 6. 相关文件

- `scripts/gen_assets.py` — ALAPI 分支、探活、错误退避
- `.env.example` — 选项 D 说明
- `docs/experience-log.md` — §19.49 ALAPI 与参考图压缩、短退避
- `docs/dmxapi-setup.md` — 仍适用于**选用 DMXAPI** 时的接入；与 ALAPI 二选一或分场景使用
