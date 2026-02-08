extends Node2D

@onready var player = $Player
@export var bomb_scene: PackedScene 
@export var trampoline_scene: PackedScene 
@export var pot_scene: PackedScene 
@export var coin_scene: PackedScene 
@export var balloon_scene: PackedScene

# --- Distance Settings ---
# The minimum distance required between a coin, bomb, and balloon
var min_safe_dist: float = 2000.0 

# Bomb Pool Settings
var bomb_pool: Array = []
var next_bomb_spawn_x: float = randf_range(1000, 2000)
var dist_between_bombs: float = randf_range(1000, 3000)

# Trampoline Pool Settings
var trampoline_pool: Array = []
var next_trampoline_spawn_x: float = randf_range(1000, 2000)
var dist_between_trampolines: float = randf_range(2000, 6000)

# Pot Pool Settings
var pot_pool: Array = []
var next_pot_spawn_x: float = randf_range(1000, 2000)
var dist_between_pots: float = randf_range(2000, 6000)

# Coin Pool Settings
var coin_pool: Array = []
var next_coin_spawn_x: float = randf_range(1000, 2000)
var dist_between_coins: float = randf_range(2000, 6000)

# Balloon Pool Settings
var balloon_pool: Array = []
var next_balloon_spawn_x: float = randf_range(1000, 2000)
var dist_between_balloon: float = randf_range(1000, 3000)

func _ready():
	randomize() # Ensure randomness works on export
	
	# Create Bombs
	for i in range(30):
		var b = bomb_scene.instantiate()
		add_child(b)
		bomb_pool.append(b)
		b.collected.connect(_on_bomb_collected)
		spawn_bomb_at_next_location(b)
		
	# Create Trampolines
	for j in range(10):
		var t = trampoline_scene.instantiate()
		add_child(t)
		trampoline_pool.append(t)
		t.collected.connect(_on_trampoline_collected)
		spawn_trampoline_at_next_location(t)
		
	# Create Pots
	for k in range(10):
		var p = pot_scene.instantiate()
		add_child(p)
		pot_pool.append(p)
		p.collected.connect(_on_pot_collected)
		spawn_pot_at_next_location(p)
		
	# Create Coins
	for l in range(10):
		var c = coin_scene.instantiate()
		add_child(c)
		coin_pool.append(c)
		c.collected.connect(_on_coin_collected)
		spawn_coin_at_next_location(c)
		
	# Create Balloons 
	# FIX: Renamed loop var to 'm' and ensured it adds to balloon_pool, not bomb_pool
	for m in range(30):
		var bal = balloon_scene.instantiate()
		add_child(bal)
		balloon_pool.append(bal) 
		bal.collected.connect(_on_balloon_collected)
		spawn_balloon_at_next_location(bal)

func _process(_delta):
	check_recycle(bomb_pool, "bomb")
	check_recycle(trampoline_pool, "trampoline")
	check_recycle(pot_pool, "pot")
	check_recycle(coin_pool, "coin")
	check_recycle(balloon_pool, "balloon")

# Helper function to clean up the _process loop
func check_recycle(pool: Array, type: String):
	for item in pool:
		if item.position.x < player.position.x - 1000 and item.visible:
			match type:
				"bomb": spawn_bomb_at_next_location(item)
				"trampoline": spawn_trampoline_at_next_location(item)
				"pot": spawn_pot_at_next_location(item)
				"coin": spawn_coin_at_next_location(item)
				"balloon": spawn_balloon_at_next_location(item)

# --- SPATIAL CHECK LOGIC ---
# Checks if the proposed position is too close to any active object in the target pools
func is_position_unsafe(proposed_pos: Vector2, pools_to_check: Array) -> bool:
	for pool in pools_to_check:
		for item in pool:
			# Only check against items that are currently active/visible on the map
			if item.visible:
				var dist = proposed_pos.distance_to(item.global_position)
				if dist < min_safe_dist:
					return true # Too close!
	return false

func spawn_bomb_at_next_location(bomb_node):
	var new_pos = Vector2()
	var attempts = 0
	
	# Try to find a safe spot up to 10 times
	while attempts < 10:
		new_pos = Vector2(next_bomb_spawn_x, randf_range(-500, -15000))
		
		# Check against Coins and Balloons (don't want to hide a bomb inside a coin)
		if not is_position_unsafe(new_pos, [coin_pool, balloon_pool]):
			break # Position is safe, exit loop
		
		# If unsafe, push the spawn X further and try again
		next_bomb_spawn_x += 500
		attempts += 1

	bomb_node.respawn(new_pos)
	next_bomb_spawn_x += dist_between_bombs

func spawn_coin_at_next_location(coin_node):
	var new_pos = Vector2()
	var attempts = 0
	
	while attempts < 10:
		new_pos = Vector2(next_coin_spawn_x, randf_range(-500, -15000))
		
		# Check against Bombs and Balloons
		if not is_position_unsafe(new_pos, [bomb_pool, balloon_pool]):
			break 
		
		next_coin_spawn_x += 500
		attempts += 1
	
	coin_node.respawn(new_pos)
	next_coin_spawn_x += dist_between_coins

func spawn_balloon_at_next_location(balloon_node):
	var new_pos = Vector2()
	var attempts = 0
	
	while attempts < 10:
		new_pos = Vector2(next_balloon_spawn_x, randf_range(-500, -15000))
		
		# Check against Bombs and Coins
		if not is_position_unsafe(new_pos, [bomb_pool, coin_pool]):
			break
			
		next_balloon_spawn_x += 500
		attempts += 1
	
	balloon_node.respawn(new_pos)
	next_balloon_spawn_x += dist_between_balloon

# Trampolines and Pots usually sit on the ground (fixed Y), 
# so we might not need to check them against flying objects, 
# but you can add the logic here if you want.
func spawn_trampoline_at_next_location(trampoline_node):
	var new_x = next_trampoline_spawn_x
	trampoline_node.respawn(Vector2(new_x, 200))
	next_trampoline_spawn_x += dist_between_trampolines
	
func spawn_pot_at_next_location(pot_node):
	var new_x = next_pot_spawn_x
	pot_node.respawn(Vector2(new_x, 200))
	next_pot_spawn_x += dist_between_pots

# --- Signals ---

func _on_bomb_collected(bomb_node):
	spawn_bomb_at_next_location(bomb_node)
	
func _on_trampoline_collected(trampoline_node):
	spawn_trampoline_at_next_location(trampoline_node)
	
func _on_pot_collected(pot_node):
	spawn_pot_at_next_location(pot_node)
	
func _on_coin_collected(coin_node):
	spawn_coin_at_next_location(coin_node)
	
func _on_balloon_collected(balloon_node):
	spawn_balloon_at_next_location(balloon_node)
