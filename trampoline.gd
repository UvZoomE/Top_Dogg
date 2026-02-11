extends Area2D

signal collected(trampoline_node)

@onready var bouncing_sound = $BounceSound

var start_x: float = 0.0
var is_bouncing: bool = false
@onready var anim = $BounceAnimation # Use a var for cleaner access
@onready var player = get_tree().get_nodes_in_group("Player")[0] as RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	start_x = position.x
	# FIX: Reset to the start of the animation immediately
	# This ensures the trampoline looks "flat" (un-bounced) when the game starts
	anim.play("bounce")
	anim.seek(0, true) 
	anim.stop()
	
func _on_body_entered(body):
	if body is Player and not is_bouncing: 
		if body.has_method("take_shield_damage"):
			body.take_shield_damage()
		bounce()
	
func bounce():
	var location = position
	is_bouncing = true
	set_deferred("monitoring", false) # Stop collisions
	
	if player is RigidBody2D:
		# 1. SANITIZE: Flip any backward momentum to forward momentum
		# This ensures we don't fight against the player's existing speed.
		player.linear_velocity.x = abs(player.linear_velocity.x)
		
		# 2. DIRECTION: Create a fixed "Launch Vector"
		# X = 1.0 (Right), Y = -0.7 (Up). 
		# This creates a roughly 35-degree launch angle, ideal for distance.
		var bounce_dir = Vector2(1.0, -1.0).normalized()
		
		# 3. POWER: Define a massive impulse strength
		# Increase this number until the explosion feels "Big" enough
		var bounce_force = 4000.0
		
		# 4. LAUNCH: Apply the impulse
		player.apply_central_impulse(bounce_dir * bounce_force)
	
	# --- 2. ANIMATION & SOUND ---
	bouncing_sound.play()
	anim.play("bounce")
	
	# --- 3. WAIT LOGIC ---
	# Wait for the animation to visually complete first
	await anim.animation_finished
	
	# Then wait for the sound (OR wait 0.5s if sound is missing/too short)
	if bouncing_sound.stream and bouncing_sound.playing:
		await bouncing_sound.finished
	else:
		await get_tree().create_timer(0.5).timeout
		
	visible = false
	# 4. recycle process
	collected.emit(self)
	
func respawn(new_position):
	global_position = new_position
	start_x = new_position.x 
	
	# Reset State
	is_bouncing = false
	set_deferred("monitoring", true)
	visible = true
	
	# FIX: Rewind the AnimationPlayer to the start
	anim.stop()               # Stop playing
	anim.play("bounce")       # Queue the correct animation
	anim.seek(0, true)        # Jump instantly to time 0.0 (the first frame)
	anim.stop()               # Pause it there
