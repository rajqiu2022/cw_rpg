# 赤岩三处石阶通行显示修正 · 2026-10-28e

用户实机指出：主角走进主石阶后只剩鞋子露在下缘。当前画面确为28d六区城市地图，但上轮只验证中央开放和两侧阻挡，漏验了人在台阶上的显示；原10项成功不能充当阶面遮挡验收。

## 已完成

- 仅更新现役`game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn`，三处为LaneStairs、LookoutStairs、WestLaneStairs。
- 原楼梯Sprite整图按底脚排序，主角一旦向上就被整个楼梯盖住。现踏面降至z=-2，两侧护墙以同一原纹理、原UV、原变换绘制Polygon2D前景，不改原PNG或导入叶。
- 六个侧墙碰撞按同一源图多边形等比映射，替换原竖直矩形；中央保持真实可走。未修改共享Player、速度、镜头、Router或其他城市。
- 独立GPU进程113424自然退出0，stderr为空，41检查0失败。先重现旧场景主阶中段主角可见率0；新场景三阶的下/中/上九个位置均为1。357个真实W/S物理输入tick完成三阶上下往返，左右侧墙均实际命中。
- 已亲看主阶中段、顶部与西巷中段原生截图，主角站在踏面上。只复本次三阶，不重跑28d已通过路线/房间矩阵。
- 单Scene发布SHA：`9ba654e229194ff57dcb92de88460170bbc077e1bd3cf5791d526309baa3f6e7` → `c8b03a26021929fc065bfcafb4de21b880630a70419b63c916ce78d8fea1fd8d`。五个本批保护路径SHA/bytes/mtime精确不变；旧28d发布和原报告保留。

![修正后主角在台阶中段](../../assets/staging/redrock_desert_complete_20261028d/town_project/artifacts/stairs_20261028e/LaneStairs_middle.png)

[验证报告](../../assets/staging/redrock_desert_complete_20261028d/town_project/artifacts/stairs_20261028e/verification.json) · [单Scene发布记录](../../assets/staging/redrock_stair_surface_20261028e/publication.json) · [源图轮廓与变换](../../assets/staging/redrock_stair_surface_20261028e/geometry.json)

## 仍待

本次修正解决楼梯漏验，不扩大完成口径。六区和关外商路是可编辑地图版，正式江湖大地图入口、剧情/经济/战斗及原图A1留白验收仍未完成；不称整个沙漠正式流程完成。用户编辑器51856保留，本次启动修正后的28d专用场景供试玩。

实际交付启动：Godot run_project已启动现役28d；输出未见SCRIPT/Parse错误，但本机WASAPI输出设备初始化失败并退dummy，故不授本次音频正常。窗口清单发现“云影侠传 (DEBUG)”；激活因GetCursorPos AccessDenied失败，唯一重读capture也失败，停止CU，不称已成功切到前台或取得主工程截图。独立GPU原生截图与41项报告仍是本次阶面验证证据。
