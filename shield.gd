extends Area2D

signal collected(orb_node)

@onready var orb_sound = $OrbSound

var start_y: float = 0.0
var time_passed: float = 0.0
@onready var player = get_tree().get_nodes_in_group("Player")[0] as RigidBody2D

func _ready():
	# Remember the starting center point
	start_y = position.y 

func _physics_process(delta):
	# 1. Play the flying animation
	# Optimization: Only tell it to play if it isn't already. 
	# This prevents the animation from resetting to frame 0 constantly.
	if $OrbAnimation.current_animation != "flashing":
		$OrbAnimation.play("flashing")

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
	if orb_sound.stream:
		# Get the exact length of the sound file in seconds
		delay_time = orb_sound.stream.get_length()
	
	# Just call the function on the player!
	if player.has_method("activate_shield"):
		player.activate_shield(10, delay_time)
	
	# 3. SOUND LOGIC
	orb_sound.play()
	
	# Wait for the sound to finish (so we don't cut it off)
	# If no sound is assigned, wait a split second to prevent errors
	if orb_sound.stream and orb_sound.playing:
		await orb_sound.finished
	else:
		await get_tree().create_timer(0.1).timeout
		
	# 4. RECYCLE
	collected.emit(self)

# New function called by Main to reset this bomb
func respawn(new_position):
	global_position = new_position
	
	# IMPORTANT: Reset the sine wave anchor to the NEW location
	start_y = new_position.y
	visible = true
	set_deferred("monitoring", true)
	$OrbAnimation.play("flashing")
