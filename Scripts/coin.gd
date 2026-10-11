extends Area2D

signal collected(coin_node)

@onready var coin_sound = $CoinSound

var start_x: float = 0.0
@onready var player = get_tree().get_nodes_in_group("Player")[0] as RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	start_x = position.x
	$CoinAnimation.play("coin_animation")
	
func _on_body_entered(body):
	if body is Player: 
		collect()
	
func collect():	
	# 1. HIDE IMMEDIATELY
	# Since the coin animation loops, we don't want to watch it finish.
	# We want it gone the moment we touch it.
	visible = false 
	set_deferred("monitoring", false) # Stop collisions
	
	# 2. Calculate Audio Length
	var delay_time = 0.0
	if coin_sound.stream:
		# Get the exact length of the sound file in seconds
		delay_time = coin_sound.stream.get_length()
	
	# Just call the function on the player!
	if player.has_method("activate_moon_gravity"):
		player.activate_moon_gravity(10.0, delay_time)
		
		player.linear_velocity.x = abs(player.linear_velocity.x)
	
	# 3. SOUND LOGIC
	coin_sound.play()
	
	# Wait for the sound to finish (so we don't cut it off)
	# If no sound is assigned, wait a split second to prevent errors
	if coin_sound.stream and coin_sound.playing:
		await coin_sound.finished
	else:
		await get_tree().create_timer(0.1).timeout
		
	# 4. RECYCLE
	collected.emit(self)
	
func respawn(new_position):
	global_position = new_position
	start_x = new_position.x 
	
	# Reset State
	set_deferred("monitoring", true)
	visible = true
