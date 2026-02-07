extends Node2D

@onready var player = $Player
@export var bomb_scene: PackedScene # Drag bomb.tscn here in Inspector!
@export var trampoline_scene: PackedScene # Drag trampoline.tscn here in Inspector!
@export var pot_scene: PackedScene # Drag pot.tscn here in Inspector!
@export var coin_scene: PackedScene # Drag coin.tscn here in Inspector!
@export var balloon_scene: PackedScene

# Bomb Pool Settings
var bomb_pool: Array = []
var next_bomb_spawn_x: float = randf_range(1000, 2000) # Where the first bomb spawns
var dist_between_bombs: float = randf_range(1000, 3000) # Distance between bombs

# Trampoline Pool Settings
var trampoline_pool: Array = []
var next_trampoline_spawn_x: float = randf_range(1000, 2000) # Where the first trampoline spawns
var dist_between_trampolines: float = randf_range(2000, 6000) # Distance between trampolines

# Pot Pool Settings
var pot_pool: Array = []
var next_pot_spawn_x: float = randf_range(1000, 2000) # Where the first pots spawns
var dist_between_pots: float = randf_range(2000, 6000) # Distance between pots

# Coin Pool Settings
var coin_pool: Array = []
var next_coin_spawn_x: float = randf_range(1000, 2000) # Where the first pots spawns
var dist_between_coins: float = randf_range(2000, 6000) # Distance between pots

# Bomb Pool Settings
var balloon_pool: Array = []
var next_balloon_spawn_x: float = randf_range(1000, 2000) # Where the first bomb spawns
var dist_between_balloon: float = randf_range(1000, 3000) # Distance between bombs

func _ready():
	# Create 5 bombs and add them to the scene immediately
	for i in range(30):
		var b = bomb_scene.instantiate()
		add_child(b)
		bomb_pool.append(b)
		
		# Connect the signal from the bomb to our function
		b.collected.connect(_on_bomb_collected)
		
		# Place it on the map
		spawn_bomb_at_next_location(b)
		
	# Create 5 trampolines and add them to the scene immediately
	for j in range(10):
		var t = trampoline_scene.instantiate()
		add_child(t)
		trampoline_pool.append(t)
		
		# Connect the signal from the bomb to our function
		t.collected.connect(_on_trampoline_collected)
		
		# Place it on the map
		spawn_trampoline_at_next_location(t)
		
	# Create 5 pots and add them to the scene immediately
	for k in range(10):
		var p = pot_scene.instantiate()
		add_child(p)
		pot_pool.append(p)
		
		# Connect the signal from the bomb to our function
		p.collected.connect(_on_pot_collected)
		
		# Place it on the map
		spawn_pot_at_next_location(p)
		
	# Create 5 pots and add them to the scene immediately
	for l in range(10):
		var c = coin_scene.instantiate()
		add_child(c)
		coin_pool.append(c)
		
		# Connect the signal from the bomb to our function
		c.collected.connect(_on_coin_collected)
		
		# Place it on the map
		spawn_coin_at_next_location(c)
		
	# Create 5 bombs and add them to the scene immediately
	for i in range(30):
		var bal = balloon_scene.instantiate()
		add_child(bal)
		bomb_pool.append(bal)
		
		# Connect the signal from the bomb to our function
		bal.collected.connect(_on_balloon_collected)
		
		# Place it on the map
		spawn_balloon_at_next_location(bal)

func _process(_delta):
	# --- Optional: Recycle Missed Bombs ---
	# If a bomb is waaaay behind the player, move it forward seamlessly
	for b in bomb_pool:
		if b.position.x < player.position.x - 1000 and b.visible:
			spawn_bomb_at_next_location(b)
			
	# --- Optional: Recycle Missed Trampolines ---
	# If a trampoline is waaaay behind the player, move it forward seamlessly
	for t in trampoline_pool:
		if t.position.x < player.position.x - 1000 and t.visible:
			spawn_trampoline_at_next_location(t)
			
	# --- Optional: Recycle Missed Pots ---
	# If a pot is waaaay behind the player, move it forward seamlessly
	for p in pot_pool:
		if p.position.x < player.position.x - 1000 and p.visible:
			spawn_pot_at_next_location(p)
			
	# --- Optional: Recycle Missed Pots ---
	# If a pot is waaaay behind the player, move it forward seamlessly
	for c in coin_pool:
		if c.position.x < player.position.x - 1000 and c.visible:
			spawn_coin_at_next_location(c)
			
	for bal in balloon_pool:
		if bal.position.x < player.position.x - 1000 and bal.visible:
			spawn_bomb_at_next_location(bal)

func spawn_bomb_at_next_location(bomb_node):
	# Calculate new position
	var new_x = next_bomb_spawn_x
	var new_y = randf_range(-500, -15000) # Random height
	
	# Move the bomb
	bomb_node.respawn(Vector2(new_x, new_y))
	
	# Increment the frontier so the next bomb spawns further ahead
	next_bomb_spawn_x += dist_between_bombs
	
func spawn_trampoline_at_next_location(trampoline_node):
	# Calculate new position
	var new_x = next_trampoline_spawn_x
	
	# Move the bomb
	trampoline_node.respawn(Vector2(new_x, 200))
	
	# Increment the frontier so the next bomb spawns further ahead
	next_trampoline_spawn_x += dist_between_trampolines
	
func spawn_pot_at_next_location(pot_node):
	# Calculate new position
	var new_x = next_pot_spawn_x
	
	# Move the pot
	pot_node.respawn(Vector2(new_x, 200))
	
	# Increment the frontier so the next bomb spawns further ahead
	next_pot_spawn_x += dist_between_pots
	
func spawn_coin_at_next_location(coin_node):
	# Calculate new position
	var new_x = next_coin_spawn_x
	var new_y = randf_range(-500, -15000) # Random height
	
	# Move the pot
	coin_node.respawn(Vector2(new_x, new_y))
	
	# Increment the frontier so the next bomb spawns further ahead
	next_coin_spawn_x += dist_between_coins
	
func spawn_balloon_at_next_location(balloon_node):
	# Calculate new position
	var new_x = next_balloon_spawn_x
	var new_y = randf_range(-500, -15000) # Random height
	
	# Move the bomb
	balloon_node.respawn(Vector2(new_x, new_y))
	
	# Increment the frontier so the next bomb spawns further ahead
	next_balloon_spawn_x += dist_between_balloon

# This runs when the bomb finishes exploding
func _on_bomb_collected(bomb_node):
	spawn_bomb_at_next_location(bomb_node)
	
# This runs when the trampoline finishes bouncing
func _on_trampoline_collected(trampoline_node):
	spawn_trampoline_at_next_location(trampoline_node)
	
# This runs when the pot finishes bouncing
func _on_pot_collected(pot_node):
	spawn_pot_at_next_location(pot_node)
	
# This runs when the pot finishes bouncing
func _on_coin_collected(coin_node):
	spawn_coin_at_next_location(coin_node)
	
func _on_balloon_collected(balloon_node):
	spawn_balloon_at_next_location(balloon_node)
