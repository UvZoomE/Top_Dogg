extends Area2D

signal collected(ufo_node)

# --- EXPORT VARIABLES ---
# Adjust these in the Inspector sidebar
@export_group("Patrol Settings")
@export var patrol_distance: float = 150.0  # How far it moves up/down
@export var patrol_speed: float = 2.0       # How fast the sine wave moves

@export_group("Tractor Beam Settings")
@export var beam_reach: float = 1000.0      # How far down the beam detects
@export var beam_width: float = 500.0       # Horizontal width of the beam
@export var beam_force: float = 2000.0      # Strength of the pull
@export var break_free_speed: float = 900.0 # Speed required to ignore the beam

@export_group("Gamble Settings")
@export var teleport_chance: float = 0.5      # 0.5 = 50% chance
@export var teleport_distance: float = 3000.0 # Distance to jump forward (pixels)
@export var teleport_boost: float = 1500.0    # Speed boost after teleport
@export var drop_punishment: float = 500.0    # Downward force if gamble fails

# --- NODES ---
@onready var hover_sound = $HoverSound
@onready var explosion_sound = $UfoExplosionSound
@onready var anim_player = $UfoExplosionAnimation
@onready var ship_sprite = $Ship
@onready var glow_sprite = $Glow

# --- STATE VARIABLES ---
var start_y: float = 0.0
var time_passed: float = 0.0
var is_active: bool = true       # If false, UFO is dead/processing
var is_capturing: bool = false   # True ONLY when beam is actively pulling player

# Get the first player found in the "Player" group
@onready var player = get_tree().get_nodes_in_group("Player")[0] as RigidBody2D

func _ready():
	start_y = position.y 
	hover_sound.play()

func _physics_process(delta):
	# If we are exploding or holding the player, stop moving/beaming
	if not is_active:
		return
		
	# 1. Patrol Movement (Sine Wave)
	time_passed += delta
	var offset = sin(time_passed * patrol_speed) * patrol_distance
	position.y = start_y + offset

	# 2. Reset Capture Flag
	# We assume false every frame, unless the beam logic sets it to true below
	is_capturing = false

	# 3. Beam Logic
	if player:
		_handle_tractor_beam(delta)

func _handle_tractor_beam(delta):
	var vector_to_ufo = global_position - player.global_position
	
	# Check Bounds (Cone Shape)
	var is_below = vector_to_ufo.y < 0 
	var in_vertical_range = abs(vector_to_ufo.y) <= beam_reach
	var in_horizontal_range = abs(vector_to_ufo.x) <= beam_width

	if is_below and in_vertical_range and in_horizontal_range:
		var current_speed = player.linear_velocity.length()
		
		# --- SCENARIO A: PLAYER IS TOO FAST (Break Free) ---
		if current_speed > break_free_speed:
			# Apply a weak drag so they feel the beam, but don't capture
			var resistance = vector_to_ufo.normalized() * (beam_force * 0.2)
			player.apply_central_force(resistance)
			
		# --- SCENARIO B: PLAYER IS SLOW (Capture Mode) ---
		else:
			is_capturing = true # Mark that we are officially pulling them
			
			# 1. Cancel Gravity (Hover)
			var gravity_force = player.mass * player.get_gravity().y
			player.apply_central_force(Vector2.UP * gravity_force)
			
			# 2. Pull to Center
			# Dampening prevents them from orbiting endlessly
			var dampening = -player.linear_velocity * 5.0
			var pull = (vector_to_ufo.normalized() * beam_force) + dampening
			player.apply_central_force(pull)

func _on_body_entered(body):
	# Only react if the UFO is still active
	if body is Player and is_active:
		if is_capturing:
			# Player arrived via the beam -> Start the Gamble Sequence
			_start_abduction_sequence()
		else:
			# Player crashed into us (too fast or from above) -> Just Explode
			_detonate_crash()

# --- SEQUENCE 1: ABDUCTION (The Gamble) ---
func _start_abduction_sequence():
	print("Abduction Started: Holding Player...")
	is_active = false
	set_deferred("monitoring", false) # Stop collisions
	
	if player is RigidBody2D:
		# 1. Snap to center and Freeze
		player.global_position = global_position
		player.linear_velocity = Vector2.ZERO
		player.angular_velocity = 0.0
		player.freeze = true 
	
	# 2. Wait 1 Second (The suspense!)
	# You could play a "charging" sound effect here
	await get_tree().create_timer(1.0).timeout
	
	# 3. Execute the Gamble
	if player is RigidBody2D:
		player.freeze = false # Unfreeze physics
		
		if randf() < teleport_chance:
			_outcome_teleport()
		else:
			_outcome_drop()

# --- SEQUENCE 2: CRASH (Hazard) ---
func _detonate_crash():
	print("UFO Crashed!")
	is_active = false
	set_deferred("monitoring", false)
	
	_play_cleanup_effects()
	
	# Simple Punishment Knockback
	if player is RigidBody2D:
		player.linear_velocity = Vector2.ZERO
		# Push them away from the center
		var launch_dir = (player.global_position - global_position).normalized()
		player.apply_central_impulse(launch_dir * 3000.0)

func _outcome_teleport():
	print("GAMBLE WON: Teleporting...")
	
	$HoverSound.stop()
	$UfoTeleportSound.play()
	
	# Create a Tween for the "Disappear" phase
	var t_out = create_tween().set_parallel(true)
	
	# 1. FADE OUT (Transparency 1.0 -> 0.0)
	t_out.tween_property(self, "modulate:a", 0.0, 1.0)
	t_out.tween_property(player, "modulate:a", 0.0, 1.0)
	
	# 2. BEAM STRETCH (Stretch Y up, Squish X down)
	# This gives the "Star Trek" beam vibe
	t_out.tween_property(self, "scale", Vector2(0.1, 2.0), 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t_out.tween_property(player, "scale", Vector2(0.1, 2.0), 1.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	# Wait for fade out to finish
	await t_out.finished
	
	# --- INVISIBLE MOVEMENT ---
	player.global_position.x += teleport_distance
	self.global_position = player.global_position # Bring UFO with us for the reappear effect
	
	# Brief pause while "in transit"
	await get_tree().create_timer(0.2).timeout
	
	# --- REAPPEAR PHASE ---
	var t_in = create_tween().set_parallel(true)
	
	# 1. FADE IN (Transparency 0.0 -> 1.0)
	t_in.tween_property(self, "modulate:a", 1.0, 0.5)
	t_in.tween_property(player, "modulate:a", 1.0, 0.5)
	
	# 2. RESTORE SCALE (Back to normal)
	t_in.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t_in.tween_property(player, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	await t_in.finished
	
	# --- RELEASE ---
	player.freeze = false
	player.linear_velocity = Vector2.ZERO
	
	var boost_dir = Vector2(1.0, -0.2).normalized()
	player.apply_central_impulse(boost_dir * teleport_boost)

func _outcome_drop():
	print("GAMBLE LOST: Dropping!")
	# Stop them dead
	player.linear_velocity = Vector2.ZERO
	
	# Push straight down
	player.apply_central_impulse(Vector2.DOWN * drop_punishment)

# --- SHARED VISUALS ---
func _play_cleanup_effects():
	explosion_sound.play()
	ship_sprite.visible = false
	glow_sprite.visible = false
	
	anim_player.visible = true
	anim_player.play("default")
	hover_sound.stop()
	
	# Wait for animation to finish before hiding parent
	await anim_player.animation_finished
	visible = false 
	
	if explosion_sound.playing:
		await explosion_sound.finished
		
	collected.emit(self)

# --- RESPAWN LOGIC ---
func respawn(new_position):
	global_position = new_position
	start_y = new_position.y 
	time_passed = 0.0 
	
	# Reset State
	is_active = true
	is_capturing = false
	visible = true
	set_deferred("monitoring", true)
	
	# Reset Visuals
	ship_sprite.visible = true
	glow_sprite.visible = true
	anim_player.visible = false
