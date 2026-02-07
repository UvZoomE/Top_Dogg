extends Parallax2D

@onready var sky_sprite_1 = $SkyAbove1
@onready var sky_sprite_2 = $SkyAbove2
@onready var sky_sprite_3 = $SkyAbove3
@onready var sky_sprite_4 = $SkyAbove4
@onready var sky_above_pic_1 = "res://sky_above/sky_above1.png"
@onready var sky_above_pic_2 = "res://sky_above/sky_above2.png"
@onready var sky_above_pic_3 = "res://sky_above/sky_above3.png"
@onready var sky_above_pic_4 = "res://sky_above/sky_above4.png"
@onready var sky_above_pic_5 = "res://sky_above/sky_above5.png"
@onready var sky_pictures: Array[String] = [sky_above_pic_1, sky_above_pic_2, sky_above_pic_3
, sky_above_pic_4, sky_above_pic_5]
@onready var player = get_tree().get_first_node_in_group("Player") as RigidBody2D
var playerPosY
var time_passed = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	playerPosY = player.position.y
	var temp_list = pick_unique_four()
	sky_sprite_1.texture = load(temp_list[0])
	sky_sprite_2.texture = load(temp_list[1])
	sky_sprite_3.texture = load(temp_list[2])
	sky_sprite_4.texture = load(temp_list[3])
	pass # Replace with function body.

func pick_unique_four():
	# 1. Duplicate the array so you don't mess up the original list order
	var temp_list = sky_pictures.duplicate()
	
	# 2. Shuffle the temporary list
	temp_list.shuffle()
	
	# 3. Slice the first 4 items (indices 0 to 4)
	var result = temp_list.slice(0, 4)
	
	return result

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_passed += delta
	if (player.position.x > 1000.0 && abs(player.position.y) <= abs(playerPosY) && time_passed > 10.0
	&& player.freeze == false):
		sky_sprite_1.texture = load("res://sky_above.png")
		sky_sprite_2.texture = load("res://sky_above.png")
		sky_sprite_3.texture = load("res://sky_above.png")
		sky_sprite_4.texture = load("res://sky_above.png")
	pass
