# 老纸匠两张候选生成提示交接

只新增两份模板与本目录；未调用生成、图片 CLI、网络、Godot 或写入正式数据。`model` / `provider` 均为 `null`，不能据旧手册伪写成某个模型、许可或成本。每张仅允许一次内置生成，不自动重试。

## 身份依据

- 当前 `game/data/luoyang_city_tasks_20261016/overlay.json` 的真实 ID 为 `luoyang_paper_artisan_20261016`，显示名“老纸匠”。现用的是戴斗笠商人精灵和 generic older-man 头像，不是专用纸匠形象。
- 原任务和对白称其为老纸匠，未找到明确年龄或衣着定案。约58岁、灰白鬓短须、旧木簪、褪靛蓝短衫＋米灰围裳为本批候选视觉设计，不新增姓名、籍贯、家世或奖励设定。
- 不能把年轻伙计、客栈小二、武人或戴斗笠背包商人冒作本次专用资产。

## 顺序与内置工具参数

1. 读取 `luoyang_resident_paperworker_20261019v_portrait.yaml` 中 `prompt_template` 的完整字符串。先实际查看其 `reference_images[0]`，以内置 `image_gen` 调用，`transparent_background=true`，该参考仅锁绘画质量。原始返回图存为 NEW 候选，保留完整原字节与提示、真实工具来源；独立半身立绘必须肉眼认可后才继续。
2. 查看已保存的真实立绘，读取 `luoyang_resident_paperworker_20261019v_idle4f.yaml` 的完整 `prompt_template`。将模板计划参考路径换成 Root 实际保存并看过的立绘路径，作为唯一身份参考；`transparent_background=true`。不要在参考缺失时退回无参考生成，也不要以场景精灵放大当立绘。不得同时使用 recent-images 和本地参考机制。
3. 模板的 `size` 为构图目标，不是内置工具独立参数或实际输出尺寸承诺。返回后记录实测尺寸、模式、透明度、SHA 和真实生成调用；模型、provider、成本未披露就保留未知。

## 原图与运行资产分离

建议 NEW raw 名：

- `assets/raw/luoyang_resident_life_20261019v/luoyang_resident_paperworker_portrait_20261019v_candidate.png`
- `assets/raw/luoyang_resident_life_20261019v/luoyang_resident_paperworker_idle4f_20261019v_candidate.png`

以上文件当前尚不存在，本交接不是已生成或可用证明。最终文件路径由 Root 根据真实工具返回确定。头像只可从认可的独立立绘机械裁切；立绘不是精灵的放大图。

运行条带必须另做确定性后处理与验收：640×160 RGBA、4个160×160等格、统一全条比例、目标人物高140px、共同脚底边距8px；逐帧实测 alpha 脚点，不沿用旧 NPC 或主角脚点假定。不得各帧分别 fit，不能用复制／平移／缩放四个静态人物制造假动画。完整头脚、足底稳定、衣褶/呼吸实际相位变化与1→4→1循环都要实看；不合格保留原候选和失败，需 Root 另作决定，不自动追加生成。

当前未获得美术、导入、正式绑定或任务/NPC运行验收。立绘/精灵同人性和服色也必须待产物实看，提示文本通过不等于结果通过。
