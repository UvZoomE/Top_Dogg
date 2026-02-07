extends RigidBody2D

class_name Player

var powerup_timer: SceneTreeTimer
var default_damp: float = 1.0 
var default_gravity: float = 1.0
var is_super_mode: bool = false

# New variable to track the previous frame's state
var was_on_ground: bool = false 

@onready var torpedo = $Torpedo
@onready var flame = $Flame
@onready var player_sprite = $PlayerSprite
@onready var boost_sound = $BoostSound
@onready var slingshot_sound = $SlingshotSound
@onready var dust = $Dust 

# Marker References (You can also use @onready if you prefer)
@onready var bottom_marker = $BottomOfPlayer
@onready var top_marker = $TopOfPlayer
@onready var left_marker = $LeftOfPlayer
@onready var right_marker = $RightOfPlayer

var world_boundary: CollisionShape2D

func _ready():
	freeze = true
	freeze_mode = FREEZE_MODE_KINEMATIC
	
	world_boundary = get_tree().get_first_node_in_group("WorldBoundary") as CollisionShape2D

	dust.visible = false
	dust.animation_finished.connect(_on_dust_finished)

func _on_dust_finished():
	dust.visible = false
	dust.stop()

func _process(delta):
	# 1. Get the global Y position of the floor
	var floor_y = world_boundary.global_position.y
	var buffer = 1.0 # Tolerance for collision
	
	# 2. Check each marker individually
	# Note: We use global_position.y for all of them
	var hit_bottom = bottom_marker.global_position.y > floor_y - buffer
	var hit_left   = left_marker.global_position.y   > floor_y - buffer
	var hit_right  = right_marker.global_position.y  > floor_y - buffer
	var hit_top    = top_marker.global_position.y    > floor_y - buffer
	
	# 3. Determine if ANY part of the player is touching the ground
	var is_touching_now = hit_bottom or hit_left or hit_right or hit_top

	# 4. THE IMPACT CHECK
	# Only play if we are touching NOW, but we WEREN'T touching last frame
	if is_touching_now and not was_on_ground:
		
		# Reset visuals to default before applying new rotation
		dust.rotation_degrees = 0
		dust.flip_v = false
		dust.visible = true
		dust.frame = 0 
		
		# Apply rotation based on which side hit
		# Priority: Bottom -> Left/Right -> Top
		if hit_bottom:
			# Normal landing, do nothing special
			pass
		elif hit_left:
			dust.rotation_degrees = 90
		elif hit_right:
			dust.rotation_degrees = 270
		elif hit_top:
			dust.flip_v = true
			
		dust.play("default")
		$DirtSound.play()
	
	# 5. Save state for next frame
	was_on_ground = is_touching_now

func _integrate_forces(state):
	if state.linear_velocity.x < 0:
		state.linear_velocity.x = 0
		state.angular_velocity = 0

func _physics_process(delta):
	if is_super_mode:
		if linear_velocity.x < 6000.0:
			linear_velocity.x = move_toward(linear_velocity.x, 6000.0, 10.0)

func ThrowPlayer():
	freeze = false
	slingshot_sound.play()
	
func activate_moon_gravity(duration: float, sound_delay: float):
	player_sprite.visible = false
	torpedo.visible = true
	torpedo.play("default")
	is_super_mode = true
	
	gravity_scale = 0.0
	self.linear_damp = 0.0
	self.physics_material_override.bounce = 1.0
	
	linear_velocity.y = 0 
	linear_velocity.x = abs(linear_velocity.x)
	apply_central_impulse(Vector2.RIGHT * 6000.0)
	
	if sound_delay > 0.0:
		await get_tree().create_timer(sound_delay).timeout
	
	if boost_sound:
		flame.visible = true
		flame.play("default")
		boost_sound.play()
	
	var my_timer = get_tree().create_timer(duration)
	powerup_timer = my_timer
	
	await my_timer.timeout
	
	# SAFETY CHECK: Stop if the player died during the wait
	if not is_instance_valid(self): return
	
	if powerup_timer == my_timer:
		player_sprite.visible = true
	
	# --- 1. DIRECTION ---
	# Determine which way to kick based on current movement or sprite facing.
	# If moving left, kick left (-1). Otherwise, kick right (1).
	var direction_x = 1.0
	
	# --- 2. VECTOR ---
	# Vector2(1, -1) creates a perfect 45-degree angle.
	# We use direction_x to flip the X axis if needed.
	var launch_vector = Vector2(direction_x, -1.0).normalized()
	
	# --- 3. POWER ---
	var explosion_force = 2000 
	
	# --- 4. APPLY FORCE ---
	# OPTION A: Additive (Good for physics-heavy games)
	self.apply_central_impulse(launch_vector * explosion_force)

	# --- 5. CLEANUP ---
	torpedo.visible = false
	torpedo.stop()
	flame.visible = false
	flame.stop()
	is_super_mode = false
	
	gravity_scale = default_gravity
	self.linear_damp = default_damp 
	self.physics_material_override.bounce = 0.5
