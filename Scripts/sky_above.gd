extends Parallax2D

# --- Nodes ---
# Base Layers (the cloud sky tiles)
@onready var sky_1 = $SkyAbove1
@onready var sky_2 = $SkyAbove2
@onready var sky_3 = $SkyAbove3
@onready var sky_4 = $SkyAbove4

# Space Layers (one per tile, sitting exactly on top of each sky tile)
@onready var fade_1 = $SkyAbove1/SkyFade1
@onready var fade_2 = $SkyAbove2/SkyFade2
@onready var fade_3 = $SkyAbove3/SkyFade3
@onready var fade_4 = $SkyAbove4/SkyFade4

@onready var player = get_tree().get_first_node_in_group("Player") as RigidBody2D

# --- Resources ---
const TEX_SPACE = preload("res://Assets/night_background.png")

# Texture Paths for random selection
var sky_pictures: Array[String] = [
	"res://Assets/sky_above/sky_above1.png",
	"res://Assets/sky_above/sky_above2.png",
	"res://Assets/sky_above/sky_above3.png",
	"res://Assets/sky_above/sky_above4.png",
	"res://Assets/sky_above/sky_above5.png"
]

# --- Settings ---
# Altitudes are world Y values (negative = higher).
# Above transition_height_start the sky starts melting into space,
# and by space_height_start it is fully space.
var transition_height_start = -10000.0
var space_height_start = -12000.0

var space_layers: Array = []

func _ready():
	if sky_pictures.size() < 4:
		push_error("You need at least 4 sky images in the array!")
		return

	# 1. Pick 4 random sky images and put them on the base tiles
	var paths = pick_unique_four()
	sky_1.texture = load(paths[0])
	sky_2.texture = load(paths[1])
	sky_3.texture = load(paths[2])
	sky_4.texture = load(paths[3])

	# 2. The fade nodes are now permanent space layers. They never change texture
	# (so nothing can pop or shift); only their opacity changes with altitude.
	space_layers = [fade_1, fade_2, fade_3, fade_4]
	for layer in space_layers:
		layer.texture = TEX_SPACE
		layer.scale = Vector2.ONE
		layer.modulate.a = 0.0

func _process(_delta):
	if space_layers.is_empty() or not is_instance_valid(player):
		return

	# 0.0 at transition_height_start -> 1.0 at space_height_start.
	# Driven directly by the player's height, so going up and coming back down
	# play out exactly the same way, with no timers or tweens to fall out of sync.
	var t = inverse_lerp(transition_height_start, space_height_start, player.global_position.y)
	var alpha = smoothstep(0.0, 1.0, clampf(t, 0.0, 1.0))

	for layer in space_layers:
		layer.modulate.a = alpha

# --- HELPER ---
func pick_unique_four():
	var temp_list = sky_pictures.duplicate()
	temp_list.shuffle()
	return temp_list.slice(0, 4)
