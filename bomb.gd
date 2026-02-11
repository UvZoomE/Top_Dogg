extends Area2D

signal collected(bomb_node)

# EXPORT VARIABLES: Change these in the Inspector sidebar!
@export var patrol_distance: float = 150.0  # How far it moves (in pixels)
@export var patrol_speed: float = 2.0       # How fast it moves
@onready var explosion_sound = $ExplosionSound

var start_y: float = 0.0
var time_passed: float = 0.0
var is_exploding: bool = false
@onready var player = get_tree().get_nodes_in_group("Player")[0] as RigidBody2D

func _ready():
	$KaboomText.visible = false
	# Remember the starting center point
	start_y = position.y 

func _physics_process(delta):
	# Stop everything if we are exploding
	if is_exploding:
		return

	# 1. Play the flying animation
	# Optimization: Only tell it to play if it isn't already. 
	# This prevents the animation from resetting to frame 0 constantly.
	if $BombAnimation.current_animation != "flying":
		$BombAnimation.play("flying")
	
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
	explosion_sound.play()
	if player is RigidBody2D:
		# 1. SANITIZE: Flip any backward momentum to forward momentum
		# This ensures we don't fight against the player's existing speed.
		player.linear_velocity.x = abs(player.linear_velocity.x)
		
		# 2. DIRECTION: Create a fixed "Launch Vector"
		# X = 1.0 (Right), Y = -0.7 (Up). 
		# This creates a roughly 35-degree launch angle, ideal for distance.
		var explosion_dir = Vector2(1.0, -1.0).normalized()
		
		# 3. POWER: Define a massive impulse strength
		# Increase this number until the explosion feels "Big" enough
		var explosion_force = 5000 
		
		# 4. LAUNCH: Apply the impulse
		player.apply_central_impulse(explosion_dir * explosion_force)
	
	trigger_kaboom_effect()
	$BombAnimation.play("explosion")
	
	# 1. Wait for the visual explosion animation to finish
	await $BombAnimation.animation_finished
	
	# 2. Hide the ENTIRE bomb object (Sprite, CollisionShape, etc.)
	# This works because 'visible' is a property of the Area2D (self)
	visible = false 
	
	# 3. Wait for the sound to finish
	if explosion_sound.playing:
		await explosion_sound.finished
		
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
	$BombAnimation.play("flying")

func trigger_kaboom_effect():
	var txt = $KaboomText.duplicate()
	get_parent().add_child(txt)
	txt.show()
	txt.global_position = global_position + Vector2(0, -50)
	animate_text(txt)

func animate_text(label_node):
	label_node.pivot_offset = label_node.size / 2
	label_node.scale = Vector2.ZERO
	
	var tween = label_node.create_tween()
	tween.tween_property(label_node, "scale", Vector2(1.5, 1.5), 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.3)
	tween.set_parallel(true)
	tween.tween_property(label_node, "modulate:a", 0.0, 0.5)
	tween.tween_property(label_node, "position:y", label_node.position.y - 100, 0.5)
	tween.tween_property(label_node, "scale", Vector2.ZERO, 0.5)
	tween.chain().tween_callback(label_node.queue_free)
