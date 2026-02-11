extends Area2D

signal collected(balloon_node)

# EXPORT VARIABLES: Change these in the Inspector sidebar!
@export var patrol_distance: float = 150.0  # How far it moves (in pixels)
@export var patrol_speed: float = 2.0       # How fast it moves
@onready var pop_noise = $PopNoise

var start_y: float = 0.0
var time_passed: float = 0.0
var is_exploding: bool = false
@onready var player = get_tree().get_nodes_in_group("Player")[0] as RigidBody2D

func _ready():
	# Remember the starting center point
	start_y = position.y 

func _physics_process(delta):
	# Stop everything if we are exploding
	if is_exploding:
		return
	
	# 2. Guard Movement Logic
	time_passed += delta
	
	# "sin" goes from -1 to 1. We multiply by distance to stretch it out.
	var offset = sin(time_passed * patrol_speed) * patrol_distance
	
	# Apply the new position
	# Since this runs on the physics tick, collision detection is more reliable here
	position.y = start_y + offset

func _on_body_entered(body):
	if body is Player and not is_exploding: 
		if body.has_method("take_shield_damage"):
			body.take_shield_damage()
		detonate()

func detonate():
	var location = position
	is_exploding = true
	set_deferred("monitoring", false) # Stop collisions
	
	# Trigger effects
	pop_noise.play()
	if player is RigidBody2D:
		# 1. SANITIZE: Flip any backward momentum to forward momentum
		# This ensures we don't fight against the player's existing speed.
		player.linear_velocity.x = abs(player.linear_velocity.x)
		
		player.linear_velocity = player.linear_velocity * 0.7 # Slow down
	
	$BalloonExplosionAnimation.visible = true
	$BalloonExplosionAnimation.play("default")
	$SpikeySprite.visible = false
	$WeightSprite.visible = true
	
	# 1. Wait for the visual explosion animation to finish
	await $BalloonExplosionAnimation.animation_finished
	
	# 2. Hide the ENTIRE bomb object (Sprite, CollisionShape, etc.)
	# This works because 'visible' is a property of the Area2D (self)
	$WeightSprite.visible = false
	$BalloonExplosionAnimation.visible = false
	
	# 3. Wait for the sound to finish
	if pop_noise.playing:
		await pop_noise.finished
		
	# 4. recycle process
	collected.emit(self)

# New function called by Main to reset this bomb
func respawn(new_position):
	global_position = new_position
	
	# IMPORTANT: Reset the sine wave anchor to the NEW location
	start_y = new_position.y 
	time_passed = 0.0 # Reset sine wave cycle (optional)
	
	# Reset State
	is_exploding = false
	visible = true
	set_deferred("monitoring", true)
