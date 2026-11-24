# 菜单按钮贴图与刀剑附魔光晕

系统左栏的设置、保存游戏、读取存档使用同一套冷钢和寒玉的四态贴图，当前页显示按下态。地图右侧的角色、武学、任务、生活技能、系统使用另一套同色系贴图。文字和快捷键由游戏排版。存读档确认与返回、交易确认与数量、行囊使用与丢弃采用另外两套尺寸匹配的贴图。四套都提供普通、悬停、按下、禁用状态。

四张 PNG 由内置 imagegen 生成。原图与运行 PNG 逐字节相同，Godot 从图集取框并生成 mipmap。图片路径、使用位置和放大查看都已登记在图鉴的「界面按钮」分类。系统左栏使用加高后的版本，最终素材和精确提示词均可追溯。

- [图鉴](../equipment-skill-catalog.html) · [正式图集目录](../../game/art/ui/menu_buttons_20261109/) · [原图与生成元数据](../../assets/raw/ui/menu_buttons_20261109/)
- [系统左栏提示词](../../prompts/menu_buttons_20261109/system.txt) · [右侧菜单提示词](../../prompts/menu_buttons_20261109/hud.txt) · [确认按钮提示词](../../prompts/menu_buttons_20261109/compact.txt) · [方形按钮提示词](../../prompts/menu_buttons_20261109/action.txt)
- [正式菜单独立复测](../../game/build/menu_buttons_20261109/07_system_final.png) · [右侧菜单实机](../../game/build/menu_buttons_20261109/01_hud.png) · [存档页实机](../../game/build/menu_buttons_20261109/03_save.png)

七星龙泉剑、烬河断岳刀、渊冥古剑、虎啸刀和越纹州句剑由兵器原纹理的透明轮廓计算柔光。出鞘时覆盖刃身，腰佩时覆盖鞘身，刃尖和护手附近渐隐。少量微粒沿整段分散，色调随兵器。绘制继续跟随武器所在层和原握点。

- [烬河断岳刀腰佩](../../game/build/blade_glow_20261109/field_jinhe_duanyue_blade.png) · [烬河断岳刀备战](../../game/build/blade_glow_20261109/battle_jinhe_duanyue_blade.png) · [七星龙泉剑备战](../../game/build/blade_glow_20261109/battle_seven_star_sword.png)

Godot 桌面测试中，菜单整流程 38 项、加高后正式菜单独立复测 11 项、光效 183 项均通过。菜单整流程覆盖设置、存档、读档切换、生活技能入口、行囊快捷键和取消交易，使用隔离数据。最后一轮整流程启动遇到共享地图校验拒绝竹尾村资源 zhuwei.json，改用正式菜单场景独立验证加高版的显示和切换。光效实测覆盖五把刀剑的收鞘与备战状态，在每种状态采样刃身或鞘身的五段双侧光晕，并执行一次断岳刀普通攻击。发布包未验。

