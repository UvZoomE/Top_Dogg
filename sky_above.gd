extends Parallax2D

# --- Nodes ---
# Base Layers
@onready var sky_1 = $SkyAbove1
@onready var sky_2 = $SkyAbove2
@onready var sky_3 = $SkyAbove3
@onready var sky_4 = $SkyAbove4

# Fade Layers
@onready var fade_1 = $SkyAbove1/SkyFade1
@onready var fade_2 = $SkyAbove2/SkyFade2
@onready var fade_3 = $SkyAbove3/SkyFade3
@onready var fade_4 = $SkyAbove4/SkyFade4

@onready var player = get_tree().get_first_node_in_group("Player") as RigidBody2D

# --- Resources ---
const TEX_TRANSITION_1 = preload("res://SkyTransition_1.png")
const TEX_TRANSITION_2 = preload("res://SkyTransition_2.png")
const TEX_SPACE = preload("res://night_background.png")

# Texture Paths for random selection
var sky_pictures: Array[String] = [
    "res://sky_above/sky_above1.png",
    "res://sky_above/sky_above2.png",
    "res://sky_above/sky_above3.png",
    "res://sky_above/sky_above4.png",
    "res://sky_above/sky_above5.png"
]

# --- Settings ---
var transition_height_start = -5000.0
var space_height_start = -7000.0 
var fade_duration = 1.5 

enum Zone { SKY, TRANSITION, SPACE }
var current_zone = Zone.SKY

# Storage variables
var initial_textures: Array[Texture2D] = []
var original_texture_size: Vector2
var player_start_y
var active_tween: Tween

func _ready():
    # FIX 1: Removed 'var' so we save to the class variable, not a temp one
    player_start_y = player.position.y
    
    # 1. Get the list of 4 random image PATHS
    var paths = pick_unique_four()
    
    # 2. Load and save them
    initial_textures.clear() 
    for p in paths:
        initial_textures.append(load(p))

    # 3. Apply them (FIX 2: Used correct variable names 'sky_1' etc.)
    sky_1.texture = initial_textures[0]
    sky_2.texture = initial_textures[1]
    sky_3.texture = initial_textures[2]
    sky_4.texture = initial_textures[3]

    # 4. Setup Faders (Ensure invisible)
    fade_1.modulate.a = 0
    fade_2.modulate.a = 0
    fade_3.modulate.a = 0
    fade_4.modulate.a = 0

    # 5. Store original size
    if sky_1.texture:
        original_texture_size = sky_1.texture.get_size()

func _process(_delta):
    var current_y = player.global_position.y
    
    # ZONE LOGIC
    if current_y < space_height_start:
        if current_zone != Zone.SPACE:
            transition_to_space()
            
    elif current_y < transition_height_start:
        if current_zone != Zone.TRANSITION:
            transition_to_transition()
            
    else:
        if current_zone != Zone.SKY:
            transition_to_sky()

# --- SMOOTH TRANSITION FUNCTION ---
func perform_crossfade(target_tex_1, target_tex_2, target_tex_3, target_tex_4, target_scale):
    if active_tween: active_tween.kill()
    active_tween = create_tween()
    active_tween.set_parallel(true)
    
    var fades = [fade_1, fade_2, fade_3, fade_4]
    var targets = [target_tex_1, target_tex_2, target_tex_3, target_tex_4]
    
    for i in range(4):
        fades[i].texture = targets[i]
        fades[i].scale = target_scale 
        active_tween.tween_property(fades[i], "modulate:a", 1.0, fade_duration)

    active_tween.chain().tween_callback(func():
        sky_1.texture = target_tex_1
        sky_2.texture = target_tex_2
        sky_3.texture = target_tex_3
        sky_4.texture = target_tex_4
        
        sky_1.scale = target_scale
        sky_2.scale = target_scale
        sky_3.scale = target_scale
        sky_4.scale = target_scale
        
        fade_1.modulate.a = 0.0
        fade_2.modulate.a = 0.0
        fade_3.modulate.a = 0.0
        fade_4.modulate.a = 0.0
    )

# --- ZONE HANDLERS ---
func transition_to_sky():
    # SAFETY CHECK: If ready() hasn't finished yet, don't run this
    if initial_textures.size() < 4: return

    current_zone = Zone.SKY
    print("Fading to Sky...")
    perform_crossfade(initial_textures[0], initial_textures[1], initial_textures[2], initial_textures[3], Vector2.ONE)

func transition_to_transition():
    if initial_textures.size() < 4: return

    current_zone = Zone.TRANSITION
    print("Fading to Transition...")
    perform_crossfade(initial_textures[0], TEX_TRANSITION_1, TEX_TRANSITION_2, initial_textures[3], Vector2.ONE)

func transition_to_space():
    current_zone = Zone.SPACE
    print("Fading to Space...")
    
    var new_size = TEX_SPACE.get_size()
    if original_texture_size == Vector2.ZERO: original_texture_size = Vector2(1920, 1080) 
    var space_scale = original_texture_size / new_size
    
    perform_crossfade(TEX_SPACE, TEX_SPACE, TEX_SPACE, TEX_SPACE, space_scale)

# --- HELPER ---
func pick_unique_four():
    var temp_list = sky_pictures.duplicate()
    temp_list.shuffle()
    return temp_list.slice(0, 4)
