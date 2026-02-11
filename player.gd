extends RigidBody2D

class_name Player

var powerup_timer: SceneTreeTimer
var default_damp: float = 0.0
var default_gravity: float = 1.0
var default_collision_mask: int
var is_super_mode: bool = false

# New variable to track the previous frame's state
var was_on_ground: bool = false 

@onready var torpedo = $Torpedo
@onready var flame = $Flame
@onready var player_sprite = $PlayerSprite
@onready var boost_sound = $BoostSound
@onready var slingshot_sound = $SlingshotSound
@onready var dust = $Dust 

@onready var bottom_marker = $BottomOfPlayer
@onready var top_marker = $TopOfPlayer
@onready var left_marker = $LeftOfPlayer
@onready var right_marker = $RightOfPlayer

var world_boundary: CollisionShape2D

# --- NEW SHIELD VARIABLES ---
var shield_health: int = 0
var can_take_shield_hit: bool = true # Prevents instant draining
@onready var shield_sprite: AnimatedSprite2D = $ShieldSprite

func _ready():
	freeze = true
	freeze_mode = FREEZE_MODE_KINEMATIC
	
	# We only need to save the mask. 
	# We will NOT touch the layer, so other objects can still see us.
	default_collision_mask = collision_mask
	
	world_boundary = get_tree().get_first_node_in_group("WorldBoundary") as CollisionShape2D

	dust.visible = false
	dust.animation_finished.connect(_on_dust_finished)
	
	# --- SHIELD SETUP ---
	# RigidBodies need these enabled to detect hits!
	contact_monitor = true
	max_contacts_reported = 4
	
	# --- CONNECT SIGNALS ---
	# Detect solid objects (Walls, Ground, Barrels)
	if not body_entered.is_connected(_on_body_collision):
		body_entered.connect(_on_body_collision)

func _on_dust_finished():
	dust.visible = false
	dust.stop()

func _process(delta):
	var floor_y = world_boundary.global_position.y
	var buffer = 1.0 
	
	var hit_bottom = bottom_marker.global_position.y > floor_y - buffer
	var hit_left   = left_marker.global_position.y   > floor_y - buffer
	var hit_right  = right_marker.global_position.y  > floor_y - buffer
	var hit_top    = top_marker.global_position.y    > floor_y - buffer
	
	var is_touching_now = hit_bottom or hit_left or hit_right or hit_top

	if is_touching_now and not was_on_ground:
		dust.rotation_degrees = 0
		dust.flip_v = false
		dust.visible = true
		dust.frame = 0 
		
		if hit_bottom:
			pass
		elif hit_left:
			dust.rotation_degrees = 90
		elif hit_right:
			dust.rotation_degrees = 270
		elif hit_top:
			dust.flip_v = true
			
		dust.play("default")
		$DirtSound.play()
	
	was_on_ground = is_touching_now

# This function allows safe modification of physics state
func _integrate_forces(state):
	# Normal behavior for left wall handling
	if not is_super_mode and state.linear_velocity.x < 0:
		state.linear_velocity.x = 0
		state.angular_velocity = 0
		
	# --- JUGGERNAUT LOGIC ---
	# This overrides any friction, damping, or collisions calculated by the engine.
	if is_super_mode:
		# Force velocity to exactly 6000 (or whatever speed you want)
		state.linear_velocity = Vector2(6000.0, 0)
		# Force rotation to stop
		state.angular_velocity = 0

func _physics_process(delta):
	print("SUPER MODE SPEED: ", linear_velocity.x)
	pass

func ThrowPlayer():
	freeze = false
	slingshot_sound.play()
	
func activate_moon_gravity(duration: float, sound_delay: float):
	# 1. VISUAL SETUP
	player_sprite.visible = false
	torpedo.visible = true
	torpedo.play("default")
	is_super_mode = true
	
	# 2. PHYSICS SETUP
	# Disable collisions (mask only)
	collision_mask = 0 
	
	gravity_scale = 0.0
	self.linear_damp = 0.0
	self.physics_material_override.bounce = 1.0
	
	# Reset vertical movement and boost horizontal
	linear_velocity.y = 0 
	linear_velocity.x = abs(linear_velocity.x)
	
	# Note: Since _integrate_forces sets velocity to 6000, this impulse 
	# is mostly for the initial "kick" feel or if you aren't using the clamping.
	apply_central_impulse(Vector2.RIGHT * 6000.0)
	
	# 3. SOUNDS
	if sound_delay > 0.0:
		await get_tree().create_timer(sound_delay).timeout
	
	if boost_sound:
		flame.visible = true
		flame.play("default")
		boost_sound.play()
	
	# 4. TIMER LOGIC
	var my_timer = get_tree().create_timer(duration)
	powerup_timer = my_timer
	
	await my_timer.timeout
	
	# --- THE FIX STARTS HERE ---
	
	# Safety check: if player died, stop.
	if not is_instance_valid(self): return
	
	# CRITICAL CHECK:
	# If 'powerup_timer' is no longer 'my_timer', it means a NEW coin was 
	# picked up and a NEW timer is currently running.
	# We must STOP here and do absolutely NOTHING. Let the new timer handle cleanup.
	if powerup_timer != my_timer:
		return 

	# --- CLEANUP (Only runs if this is the FINAL timer) ---
	
	player_sprite.visible = true

	torpedo.visible = false
	torpedo.stop()
	flame.visible = false
	flame.stop()
	is_super_mode = false
	
	collision_mask = default_collision_mask
	
	gravity_scale = default_gravity
	self.linear_damp = default_damp 
	self.physics_material_override.bounce = 0.5
	
func activate_shield(hits_allowed: int, sound_delay: float):
	# Wait for the orb sound if needed
	if sound_delay > 0.0:
		await get_tree().create_timer(sound_delay).timeout
	
	# Reset Health
	shield_health = hits_allowed
	can_take_shield_hit = true
	
	# Reset Visuals
	if shield_sprite:
		shield_sprite.visible = true
		shield_sprite.pause() # Don't loop the animation automatically!
		shield_sprite.frame = 0 # Start at "Full Shield"
		
	print("Shield Activated! HP: ", shield_health)


# --- 2. COLLISION LOGIC (The new part) ---
func _on_body_collision(body):
	# Only run if shield is active AND we aren't in cooldown
	if shield_health > 0 and can_take_shield_hit:
		take_shield_damage()

func take_shield_damage():
	# 1. Reduce Health
	shield_health -= 1
	print("Shield Hit! Remaining: ", shield_health)
	
	# 2. Update Visuals
	if shield_health > 0:
		# MATH: If Max is 10 and we have 9 left... 10 - 9 = Frame 1.
		# If we have 1 left... 10 - 1 = Frame 9.
		var max_hp = 10
		var frame_index = max_hp - shield_health
		
		# Clamp just in case to prevent errors
		if shield_sprite:
			shield_sprite.frame = clamp(frame_index, 0, 9)
			
		# 3. Add a tiny cooldown (invincibility frames)
		# This prevents a scraping wall from hitting you 60 times a second
		can_take_shield_hit = false
		await get_tree().create_timer(0.2).timeout
		can_take_shield_hit = true
		
	else:
		# 4. Shield Broken
		deactivate_shield()

func deactivate_shield():
	shield_health = 0
	if shield_sprite:
		shield_sprite.visible = false
		$PowerDown.play()
		
# Triggered by Areas (Flying enemies, hazards)
func _on_area_entered(area):
	# Optional: Check if the area is actually "dangerous" 
	# (e.g., ignore coins or checkpoints)
	take_shield_damage()
