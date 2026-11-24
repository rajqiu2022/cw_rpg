"""Replace projected ribbon walls with complete, uniformly scaled native moss banks."""
from lanxi_revision_20261030l import *
from PIL import Image
def vector(v):return 'Vector2('+', '.join(f'{x:.5f}' for x in v)+')'
source=(STAGE/'backup'/OLD).read_text('utf-8');terrain=json.loads((GAME/'art/modules/miao_terrain_20261029i/terrain.json').read_text('utf-8'))
source=source.replace('res://scripts/drafts/miao_terrain_20261029i/town_controller.gd','res://build/'+NAME+'/controller.gd')
source=source.replace('[sub_resource type="ShaderMaterial" id="ground_mat"]','[ext_resource type="Texture2D" path="res://art/modules/miao_recompose_20261029g/rock_bank.png" id="native_bank"]\n\n[sub_resource type="ShaderMaterial" id="ground_mat"]')
blocks=re.split(r'(?=\[node )',source);out=[blocks[0]];removed=[]
# Keep physical terraces and all four ramps; delete only the stretched side/front facade quads.
for block in blocks[1:]:
 head=block.splitlines()[0]
 if 'type="Polygon2D" parent="Terrain"' in head and 'texture = ExtResource("terrace")' in block:
  removed.append(head);continue
 out.append(block)
source=''.join(out)
source=re.sub(r'^\[ext_resource type="Texture2D" path="res://art/modules/miao_town_20261029f/terrace.png" id="terrace"\]\n','',source,flags=re.M)
# Retreat cramped homes from the bank, preserving their original floor.
moves={'PocketHome1':[2550,670],'PocketHome6':[2480,1250],'DyeWorkshop':[2780,1540],'PocketInfill1':[3450,1420],'PocketHome8':[4500,2260],'Table1':[1680,2120],'WaterJars':[2620,2050],'Dry2':[2460,2290]}
old_positions={row['name']:row['position'] for row in json.loads((STAGE/'objects-before.json').read_text('utf-8'))}
save(QA/'moved_objects.json',{name:{'old':old_positions[name],'new':p,'return_foot':[p[0],p[1]+65]} for name,p in moves.items()})
for name,p in moves.items():
 pattern=r'(\[node name="'+name+r'" type="Node2D" parent="Town"[^\n]*\]\n[^\[]*?position = )Vector2\([^)]+\)'
 source,n=re.subn(pattern,lambda m:m[1]+vector(p),source);assert n==1,name
bank=GAME/'art/modules/miao_recompose_20261029g/rock_bank.png';im=Image.open(bank).convert('RGBA');bbox=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();anchor=[(bbox[0]+bbox[2])/2,bbox[3]]
native=[];idx=0
for row in terrain['platforms']:
 level=row['level'];points=row['polygon'];low=terrain['heights'][level-1]
 for i,a in enumerate(points):
  b=points[(i+1)%len(points)];dx=b[0]-a[0];dy=b[1]-a[1];length=math.hypot(dx,dy)
  # Rear edges face away from camera; a low natural rim, never a front wall through the hill.
  rear=dx>0;steep=abs(dy)>length*.7;scale=.16 if steep else (.20 if rear else .245)
  width=(bbox[2]-bbox[0])*scale;height=(bbox[3]-bbox[1])*scale
  step=1/max(abs(dx/length)/(width*.68),abs(dy/length)/(height*.58))
  count=max(1,math.ceil(length/step))
  for j in range(count):
   t=(j+.5)/count;x=a[0]+dx*t;y=a[1]+dy*t
   # Preserve a clear, deliberately wide mouth around each real stair.
   if any(r['high']==level and abs(y-r['top'][1])<95 and abs(x-r['top'][0])<width*.5+170 for r in terrain['ramps']):continue
   # Hide the rear rim behind the raised surface; front/native rocks overlap in whole-image proportions.
   baseline=y-(terrain['heights'][level]+15 if rear else low-10)
   if steep:x+=math.copysign(width*.10,dy)
   z=-10 if rear else round(y/4)-2
   name='NativeBank'+str(idx);idx+=1
   source+='\n[node name="'+name+'" type="Sprite2D" parent="Terrain"]\nz_as_relative = false\nz_index = '+str(z)+'\nposition = '+vector([x,baseline])+'\nscale = '+vector([scale,scale])+'\ntexture = ExtResource("native_bank")\ncentered = false\noffset = '+vector([-anchor[0],-anchor[1]])+'\nmetadata/native_full_image = true\n'
   native.append({'name':name,'level':level,'position':[x,baseline],'scale':scale,'rear':rear})
(QA/'candidate.tscn').write_text(source.rstrip()+'\n','utf-8')
save(STAGE/'layout-change.json',{'removed_facade_quads':removed,'native_banks':native,'building_moves':moves,'physical_geometry_unchanged':True,'png_changed':False})
print('removed',len(removed),'whole banks',len(native),'moves',moves)
