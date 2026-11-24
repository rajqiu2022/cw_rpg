extends CharacterBody2D
@export var identity := "man"
@export var route := PackedVector2Array()
@export var walk_speed := 48.0
var enabled := true
var is_walking := false
var phase := 0
var direction_row := 0
var frame_clock := 0.0
var wait_time := 1.0
var destination := 1
var config: Dictionary
var town: Node
@onready var art: Sprite2D = $Art

func _ready() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://art/modules/miao_town_20261029f/atlases.json"))[identity]
	town=get_parent()
	while town!=null and not town.has_method("enter_hall"):town=town.get_parent()
	show_frame()

func show_frame() -> void:
	var f: Dictionary=config.side_walk[phase%4] if is_walking else config.idle[direction_row]
	art.texture=load("res://art/modules/miao_town_20261029f/"+str(f.texture)+".png")
	var region: Array=f.region
	art.region_rect=Rect2(region[0],region[1],region[2],region[3])
	art.scale=Vector2.ONE*float(f.scale)
	art.flip_h=is_walking and direction_row==1
	var pivot: Array=f.pivot
	var px:=float(region[2])-float(pivot[0]) if art.flip_h else float(pivot[0])
	art.position=-Vector2(px,float(pivot[1]))*float(f.scale)

func _physics_process(delta: float) -> void:
	z_as_relative=false
	z_index=clampi(roundi(global_position.y/4.0),-4000,4000)
	is_walking=false
	if not enabled or not is_visible_in_tree() or (town!=null and town.show_details):return
	if route.size()<2:show_frame();return
	if wait_time>0:
		wait_time-=delta;phase=0;show_frame();return
	var target:=route[destination]
	var offset:=target-global_position
	if offset.length()<4:
		destination=(destination+1)%route.size();wait_time=1.1;show_frame();return
	var hero: Node2D=town.actor if town!=null else null
	if hero!=null and global_position.distance_to(hero.global_position)<105:
		phase=0;show_frame();return
	var before:=global_position
	velocity=offset.normalized()*minf(walk_speed,offset.length()/delta)
	move_and_slide()
	is_walking=global_position.distance_squared_to(before)>.01
	direction_row=2 if offset.x>=0 else 1
	frame_clock+=delta
	if frame_clock>=.16:frame_clock=0;phase=(phase+1)%4
	show_frame()
	if not is_walking:wait_time=.6;destination=(destination+1)%route.size()
