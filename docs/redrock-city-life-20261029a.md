# 赤岩关镇 · 街坊生活续改

本轮已写回同一[redrock_town.tscn](../game/scenes/drafts/redrock_desert_complete_20261028d/redrock_town.tscn)，Godot打开后F6。默认冷孤云跟随；WASD移动、Shift快走、Tab全景/跟随、1—6分区观察、7关外商路，空格查看/进屋，Esc关闭说明。

|区域|当前变化|
|---|---|
|阶街民巷|北排两住户重排，新增北巷/东巷两间民居，门前陶罐、长凳、小桌与货包成组；主街/后巷以砂岩小石板连接|
|蓄水小院|储罐靠井棚侧放置，中央取水口开放，增加歇脚凳和候水商旅巡行|
|驿舍马院|候行桌凳、储水与驮包分开布置；原驿舍前厅入口保留|
|石作修坊|砂岩材料、工作台、周转货及帮工分工布置，原街道和院口开放|
|关门与望台|候关货包/长凳离开主路，东巷新住户与望台街相连；原连体关楼和三阶分层保持|

新增2间民居、22组生活陈设、4名复用已存精灵/同人肖像的巡行人物；只制作1张新砂岩铺地原图，没有新增剧情身份或收费服务。两间原室内和关外商路继续沿原路径。

![修坊实景](../assets/staging/redrock_city_life_20261029a/town_project/artifacts/work_final_native.png)

## 可复用资源

|资源|路径|当前使用|
|---|---|---|
|砂岩街巷铺地原图|[原PNG](../assets/raw/redrock_city_life_20261029a/ground/redrock_city_life_20261029a_sandstone_paving_v1.png)|内置imagegen 1次，1254² RGB，原像素保留|
|工程材质|[sandstone_paving.png](../game/art/modules/redrock_city_life_20261029a/sandstone_paving.png)|街巷及四处院内，512周期采样；隔离导入RGBA精确|
|铺地实现|[ground.gdshader](../game/art/modules/redrock_city_life_20261029a/ground.gdshader)|路面与院内四边形羽化衔接；旧地表原图保留|
|新增摆放/路线|[life-layout.json](../assets/staging/redrock_city_life_20261029a/town_project/life-layout.json)|28对象的真实源脚、碰撞和4巡行路线|

[分类图鉴与点击放大](equipment-skill-catalog.html#resources) · [完整复用索引](resource-reuse-index.md) · [设计、首轮失败及增量验证](changes/redrock-city-life-20261029a.md) · [提示词与内置生成记录](../assets/raw/redrock_city_life_20261029a/manifest.json)

本次街坊生活改造已完成，正式江湖大地图入口、剧情/经济/战斗及旧原图A1仍待；整体空间尚未达到概念图密度，不称整个沙漠正式流程或整城最终美术完成。
