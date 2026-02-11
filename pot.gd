extends Area2D

signal collected(pot_node)

var start_x: float = 0.0
var is_broken: bool = false
var is_barrel_active: bool = false # Tracks if we are currently a barrel or a pot

@onready var player = get_tree().get_nodes_in_group("Player")[0] as RigidBody2D

# Nodes
@onready var pot_sprite = $PotSprite
@onready var barrel_sprite = $BarrelSprite
@onready var broken_sound = $BrokenVase
@onready var broken_barrel_sound = $BrokenBarrel

# Textures
@export var broken_pot: Texture2D
@export var broken_barrel: Texture2D

# Store the clean textures automatically in _ready
var clean_pot_texture: Texture2D
var clean_barrel_texture: Texture2D

func _ready():
	start_x = position.x
	
	# 1. SAVE CLEAN TEXTURES
	# We save these now so we can "repair" the object when it respawns
	clean_pot_texture = pot_sprite.texture
	clean_barrel_texture = barrel_sprite.texture
	
	# 2. PICK INITIAL TYPE
	randomize_visuals()

func _on_body_entered(body):
	# We only care if the player hits us and we aren't already broken
	if body is Player and not is_broken: 
		if body.has_method("take_shield_damage"):
			body.take_shield_damage()
		break_object()

func randomize_visuals():
	# Randomly decide: True (Barrel) or False (Pot)
	is_barrel_active = [true, false].pick_random()
	
	if is_barrel_active:
		barrel_sprite.visible = true
		pot_sprite.visible = false
		barrel_sprite.texture = clean_barrel_texture # Ensure it looks new
	else:
		barrel_sprite.visible = false
		pot_sprite.visible = true
		pot_sprite.texture = clean_pot_texture # Ensure it looks new

func break_object():
	is_broken = true
	set_deferred("monitoring", false) # Stop collisions immediately

	# 1. VISUAL SWAP
	# We check 'is_barrel_active' to know WHICH sprite to update.
	if is_barrel_active:
		# We are a barrel
		broken_barrel_sound.play()
		if broken_barrel: # Check if the export has a texture
			barrel_sprite.texture = broken_barrel
	else:
		# We are a pot
		broken_sound.play()
		if broken_pot: # Check if the export has a texture
			pot_sprite.texture = broken_pot

	# 2. PHYSICS IMPACT (Optional: Stop the player slightly)
	if player is RigidBody2D:
		player.linear_velocity.x = abs(player.linear_velocity.x) # Force forward direction
		player.linear_velocity = player.linear_velocity * 0.7 # Slow down

	# 3. THE FIX: FORCE A VISUAL WAIT
	# Don't wait for the sound. The sound might be too short (0.1s) or fail.
	# We force the game to wait 0.5 seconds so the player SEES the broken image.
	await get_tree().create_timer(0.5).timeout

	# 4. CLEANUP
	visible = false
	collected.emit(self)

# Called by Main to reset this object
func respawn(new_position):
	global_position = new_position
	start_x = new_position.x 
	
	# Reset State
	is_broken = false
	set_deferred("monitoring", true)
	visible = true
	
	# Pick a new random look for this respawn
	randomize_visuals()
