from pathlib import Path
import hashlib,json
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
items=[
('east_residence','game/art/maps/luoyang_city_rebuild_20261027d/east_shop_residence_v1_padded.png',.5),
('west_residence','game/art/maps/luoyang_city_rebuild_20261027d/west_shop_residence_v1_padded.png',.5),
('bookshop','game/art/modules/luoyang_market_space_20261024b/bookshop_complete_v2.png',.42),
('apothecary','game/art/modules/luoyang_market_space_20261024b/apothecary_complete_v2.png',.42),
('street_row','game/art/maps/luoyang_modular_v3/source/street_row_v3.png',.5),
('inn','game/art/maps/luoyang_modular_v3/source/inn_v1.png',.5),
('old_shop','game/art/maps/luoyang_modular_v3/source/shop_v1.png',.5),
('warehouse','game/art/maps/luoyang_modular_v3/source/canal_warehouse_v3.png',.6),
('goods_stall','game/art/maps/luoyang_modular_v3/source/goods_stall_v2.png',.35),
('notice_pavilion','game/art/maps/luoyang_modular_v3/source/notice_pavilion_v2.png',.35),
('raw_posthouse','assets/raw/other_city_modules_20261022/bianzhou/maps/other_city_20261022_bianzhou_posthouse_front_v1.png',.5),
('raw_merchant_store','assets/raw/world_expansion_100_20261022/maps/bianzhou/world100_20261022_bianzhou_merchant_store_front_v1.png',.5),
('raw_courtyard_corner','assets/raw/world_expansion_100_20261022/maps/bianzhou/world100_20261022_bianzhou_courtyard_corner_v1.png',.5),
('cottage','game/art/modules/prop/prop_zhuwei_cottage_25d_v2.png',.6),
('smith_front','game/art/modules/building/build_linxi_smithy_front.png',.5),
('raw_military_store','assets/raw/world_expansion_100_20261022/maps/xiangzhou/world100_20261022_xiangzhou_military_store_v1.png',.5),
('raw_silk_shop','assets/raw/other_city_modules_20261022/jinling/maps/other_city_20261022_jinling_silk_shop_front_v1.png',.5),
('raw_waterside_store','assets/raw/world_expansion_100_20261022/maps/jinling/world100_20261022_jinling_waterside_warehouse_v1.png',.5),
]
rows=[]
for page in range(2):
    board=Image.new('RGB',(1500,1500),(96,103,94)); draw=ImageDraw.Draw(board)
    for j,(name,rel,scale) in enumerate(items[page*9:page*9+9]):
        path=ROOT/rel; im=Image.open(path).convert('RGBA'); alpha=im.getchannel('A'); a1=alpha.getbbox(); d8=alpha.point(lambda a:255 if a>=8 else 0).getbbox()
        rows.append({'id':name,'path':rel,'canvas':im.size,'complete_A1':a1,
                     'alpha8_subject_diagnostic_NOT_MARGIN':d8,
                     'illustrative_uniform_scale_NOT_DOOR_CERTIFIED':scale,
                     'subject_draw_size_at_scale':[(d8[2]-d8[0])*scale,(d8[3]-d8[1])*scale],
                     'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                     'is_formal_game_path':rel.startswith('game/'),'source_modified':False})
        im.thumbnail((480,455));x=j%3*500+(500-im.width)//2;y=j//3*500+35+(455-im.height)//2
        board.paste(im,(x,y),im);draw.text((j%3*500+8,j//3*500+8),name,fill='white')
    board.save(HERE/f'reuse_true_alpha_contact_{page+1}.jpg',quality=92)
(HERE/'reuse_resources.json').write_text(json.dumps({'status':'READONLY_ART_REUSE_AUDIT_NOT_SCALE_ACCEPTANCE','assets':rows},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(rows,ensure_ascii=False,indent=2))
